#!/usr/bin/env python
# -*- coding:utf-8 _*_
#----------------------------------
# 2014-6-19 1.分离出，离线sug日志处理程序old_mapper.py; 2.增加字段num,记录sug实际展现条数; 3.修复sug展现条目及顺序bug,字典改成list
# 2014-6-21 1.uid强制大写(否则与其他数据源匹配不上) 2.迁移old_mapper.py的编码转换代码
# 2014-6-22 异常情形统计(2014-6-19):不合理 count!=num：830/18407380=0.0045%,sug无结果 num=0：4058585/18407380=22%
# 2014-6-26 sug展现list中category可能包含|,&,提前处理,避免与分隔符混淆
# 2014-9-13 sug展现日志功能升级(2014.9.11,type=hivenew),兼容新旧两版日志:①首条记录可能是包含父子关系的多层关系②增加sug日志版本字段response['version']③每个展现项增加3个字段:pos(顺序),display_info(附加信息),column(第几列)④空值校正(-)
# 2014-10-28 sug编码混乱:9.10-9.24,全部gb2312;9.25,gb2312,utf8混杂;9.26-10.27,utf8为主,首条父子关系数据是gb2312编码
#----------------------------------


import sys
#sys.path.append('../chardet')
import re
import func
import os
#import chardet
import zipimport

# local test
#importer = zipimport.zipimporter('chardet.zip')
# hadoop
importer = zipimport.zipimporter('lib/chardet.zip')
chardet = importer.load_module('chardet')

reload(sys)
sys.setdefaultencoding( "utf-8" )



#if __name__ == '__main__':
def main(input):
    # 一级字段分隔符\t type=hive|hivenew
    format_list = ['time','log_server','tid','type','sysinfo','req1','req2','resp','dt']
    # 注：hive后面为空时，是测试数据。orlando，2014-5-20
    format_len = len(format_list)
    # 二级字段分隔符\001(后4个字段)
    sub_list = ('sysinfo','req1','req2','resp')
    sysinfo_list = ['aos_version','spend_time']
    req1_list = ['adcode','keyword','keyword_py','keyword_en','query_src','query_type','data_type','geoobj','clientpage','clientfield','category']
    req2_list = ['user_info','diu','user_loc','user_city','language','sessionid','stepid','div','platform']
    # resp 行首以count开头,各个sug结果均展示如下字段
    resp_list_1_0 = ['name','district','adcode','category','rank','poiid','address','x','y','distance'] 
    # 2014-6-26 阚小峰:Sug的返回结果中新增了一个checked属性字段type，该字段的值（1,2,3,4,5）表示poi的置信度，3,4,5表示poi数据质量不高,0表示未知的置信度, 在6.6日上线的
    resp_list_1_1 = ['name','district','adcode','category','rank','poiid','address','x','y','type','distance'] 
    # 2014-9-12 邢永涛:增加父子关系 新增字段：pos(点击位置),display_info(附加信息),column(子poi显示列数)
    resp_list_2_0_father = ['pos','name','district','adcode','category','rank','poiid','address','x','y','type','distance','terminals','ignore_district','display_info','column'] 
    resp_list_2_0_son = ['pos','poiid','shortname','name','x','y','adcode'] # 子级别poi信息展示格式 
    resp_list_2_0_son_new = ['pos','name','shortname','adcode','poiid','x','y'] # 校正后的子级别格式
    #高铁西站(公交站)(公交站)|河北省沧州市沧县|130921|150700|0.327211|BV13D01412|16路;31路;402路|116.769901|38.305694|7667.79
    #resp_list = ['name','district','adcode','category','rank','poiid','address','x','y','x_entr','y_entr','distance']
    resp_len_old = len(resp_list_1_0)
    resp_len_new = len(resp_list_1_1)
    resp_len_father = len(resp_list_2_0_father)
    resp_len_son = len(resp_list_2_0_son)

    out_dict = {'uid':'-','sessionid':'-','stepid':'-','time':'-','position':'-','source':'SUG','action':'-','request':'-','response':'-','cellphone':'-','other':'-'}
    out_list = ['uid','sessionid','stepid','time','position','source','action','request','response','cellphone','other']
    pattern_uid = re.compile(r'^[\w-]+$',re.I)
    pattern_gb = re.compile(r'gb',re.I)
    for line in input:
        # 初始化输出结构 
        position_dict = {}
        request_dict = {}
        response_dict = {}
        cellphone_dict = {}
        other_dict = {}

        arr = [i.strip() for i in line.strip().split('\t')]
        line_len = len(arr)
        if line_len not in (format_len,format_len -1):
            continue
        # chardet 
        new_line = line
        # 2014-10-28 
        coding_result = {}
        coding_name = '-'
        try:
            coding_result = chardet.detect(line)
            coding_name = coding_result['encoding']
            #if coding_name not in ('ascii','utf-8'):
            if pattern_gb.match(coding_name):
                print >>sys.stderr,'coding_name='+coding_name  # GB2312
                new_line = line.decode(coding_name).encode('utf-8')
        except Exception,err:
            print >>sys.stderr,"coding transform error ! (%s => %s) continue" %(str(coding_name),'utf-8')
            coding_name = '-'
            #continue
        # 处理当前记录
        '''
        # old_mapper.py中打开
        try:
            line = line.decode('gbk').encode('utf8')
        except Exception,err:
            print >>sys.stderr,'line encoding error(%s) !'%(err)
            continue
        '''
        #arr = [i.strip() for i in line.strip().split('\t')]
        arr = [i.strip() for i in new_line.strip().split('\t')]
        line_len = len(arr)
        # 过滤冗余日志
        if line_len not in (format_len,format_len -1):
            #func.counter('Count','line length pass',1)
            #print >>sys.stderr,'element number(%s) of line != format_len(%s)\nline=%s'%(line_len,format_len,line)
            continue
        # sug日志合法性验证:8个字段且第4个是'hive',或者hivenew  2014-9-12
        if arr[3] not in ( 'hive', 'hivenew'):
            print >>sys.stderr,'%s not hive or hivenew !\n\t%s'%(arr[3],line)
            continue
        in_dict = dict(zip(format_list,arr))
        version = '-'
        for k in sub_list:
            tmp_list = in_dict[k].split('\001')
            # 统一空值'-'
            for i,v in enumerate(tmp_list):
                if v == '':
                    tmp_list[i] = '-'
            tmp_len = len(tmp_list)
            if k == 'resp':
                if in_dict['type'] == 'hive':
	                # 2014-6-26 兼容新旧两版sug日志(6.7,阚小峰增加了type字段,每个展现属性从10个增加到11个)
	                resp_len = 0
	                if tmp_len % resp_len_new == 1:
	                    version = '1_0' # 2014.5 第一版规范化的sug日志 1.0
	                    resp_len = resp_len_new # 新版sug日志 
	                elif tmp_len % resp_len_old == 1:
	                    version = '1_1' # 2014.6 第二版sug日志(增加字段) 1.1
	                    resp_len = resp_len_old # 旧版sug日志 
	                else: # 问题日志
	                    print >>sys.stderr,'resp len error ! tmp_len=%s\tin_dict[resp]=%s'%(tmp_len,in_dict['resp'])
	                    func.counter('Count','resp length pass',1)
	                    continue
	                tmp_num = tmp_len / resp_len;
	                response_dict['count'] = tmp_list[0]  # 第一个字段是sug结果数
	                response_dict['num'] = tmp_num # 2014-6-19 sug实际展现条数,数据中存在count!=num的情形:num=0,count非数字
                        response_dict['version'] = version
	                if tmp_num == 0:
	                    # 2014-6-26 处理无结果情形
	                    response_dict['result'] = '-'
	                else:
	                    result_list = []
	                    for j in range(1,tmp_len,resp_len):
	                        tmp_seg_list = tmp_list[j:j+resp_len]
	                        # 2014-6-26 sug展现list中category可能包含|,&,提前处理,避免与分隔符混淆
	                        for i,v in enumerate(tmp_seg_list):
                                    if v == '': # 2014.9.13 控制校正
                                        tmp_seg_list[i] = '-'
                                    else:
	                                tmp_seg_list[i] = v.replace('|','$').replace('&','#') 
	                        tmp_seg_list.insert(0,str(j/resp_len+1))
	                        result_list.append('|'.join(tmp_seg_list))
	                        #result_list.append('\003'.join(tmp_seg_list))
	                    response_dict['result'] = '&'.join(result_list)
	                    #response_dict['result'] = '\002'.join(result_list)
	                in_dict[k] = dict(zip(eval(k+'_list'+'_'+version),tmp_list))
                elif in_dict['type'] == 'hivenew':
                    # 2014-9-12 邢永涛,type=hivenew 9.11 上线的新日志格式(包含父子关系)
                    response_len = len(tmp_list)
                    response_dict['count'] = tmp_list[0]
                    response_dict['num'] = response_len - 1 # 实际展现条目(不含子节点)
                    response_dict['version'] = '2_0'
                    if response_len < 2: # sug无结果
                        #print >>sys.stderr,'resp string length(%s) error ! --> as no result\n\t%s'%(response_len,repr(in_dict))
                        response_dict['result'] = '-'
                    else: # sug有结果
                        result_list = []
                        # ----------- 第一条展现记录特殊处理(可能包含父子关系):T1=F[^BS1^CS2^C…^CSm],F可能是-
                        tmp_f_list = tmp_list[1].split('\002')
			# 兼容新的父子关系错误字段数，因永涛父子关系中字段数多1 add by hm.z 20141118
			tmp_clm_list = tmp_f_list[0].split('\004')
			if len(tmp_clm_list)==17:
			    #tmp_clm_list = (tmp_f_list[0].split('\004')[0:12] + tmp_f_list[0].split('\004')[15:2])
			    tmp_clm_list = tmp_clm_list[0:16] 
			    result_list.append('\004'.join(tmp_clm_list))
#			elif len(tmp_clm_list)==16:
#			    tmp_clm_list = tmp_clm_list[0:15]
#			    result_list.append('\004'.join(tmp_clm_list))
			else:
                            result_list.append(tmp_f_list[0])
                        len_tmp_f = len(tmp_f_list)
                        if len_tmp_f == 1:
                            # 非父子关系结构,T1=F,正常处理
                            pass
                        elif len_tmp_f == 2:
                            # 父子关系结构,T1=F^BS1^CS2^C…^CSm
                            if tmp_f_list[0] == '-':
                                # 父节点为空(F='-'),子节点非空,需要修正,字段填充，统一字段数
                                result_list[0] = '\004'.join(['-' for i in xrange(len(resp_list_2_0_father))])
                            # chardet
                            # 2014-10-28 
                            coding_result_1 = {}
                            if not coding_name.startswith('gb'):
                                son_line = tmp_f_list[1]
                                # 整行编码没问题,局部转码(sug首条父子关系展现)
                                coding_name_1 = '-'
                                try:
                                    coding_result_1 = chardet.detect(son_line)
                                    coding_name_1 = coding_result_1['encoding']
                                    if pattern_gb.match(coding_name_1):
                                        tmp_f_list[1] = son_line.decode(coding_name_1).encode('utf-8')
                                except Exception,err:
                                    print >>sys.stderr,'son coding_name_1='+str(coding_name_1)
                                    coding_name_1 = '-'
                            # 追加子节点:S1,S2,S3---子级别编号以小数点显示,字段个数不同于父级别
                            tmp_s_list = tmp_f_list[1].split('\003')
                            len_tmp_s = len(tmp_s_list)
                            response_dict['son_num'] = len_tmp_s # 子级别展现个数
                            for i in tmp_s_list:
                                j_tmp_list = i.split('\004')
                                j_tmp_list_len = len(j_tmp_list)
                                if j_tmp_list_len != resp_len_son:
                                    print >>sys.stderr,'illegal son sug item:len(%s)!=%s'%(j_tmp_list_len,resp_len_son)
                                    continue
                                # 调整子级别poi字段顺序,与父级别字段保持基本一致
                                # old: ['pos','poiid','shortname','name','x','y','adcode'] 
                                # new: ['pos','name','shortname','adcode','poiid','x','y']
                                result_list.append('\004'.join([j_tmp_list[0],j_tmp_list[3],j_tmp_list[2],j_tmp_list[6],j_tmp_list[1],j_tmp_list[4],j_tmp_list[5]]))
                            #result_list.extend(tmp_f_list[1].split('\003'))
                        else:
                            print >>sys.stderr,'illegal first sug item:len(%s)!=2'%(len_tmp_f)
                            continue
                        # ------------ 其他一级展现条目
                        result_list.extend(tmp_list[2:])
                        # 字段分隔符重组,特殊符号规避处理
                        for i,vi in enumerate(result_list):
                            i_tmp_list = vi.split('\004')
	                    for j,vj in enumerate(i_tmp_list):
                                if vj == '': # 空值校正'-'
                                    i_tmp_list[j] = '-'
                                else:
	                            i_tmp_list[j] = vj.replace('|','$').replace('&','#') 
                            result_list[i] = '|'.join(i_tmp_list)
                        response_dict['result'] = '&'.join(result_list)
                else:
                    print >>sys.stderr,'type parse error ! not hive or hivenew !\n%s'%(line)
                    continue
            else:
                in_dict[k] = dict(zip(eval(k+'_list'),tmp_list))
        #print in_dict
        # 字段重组
        request_dict.update(in_dict['req1'])
        # 2014-6-19 去掉sug测试日志
        if 'query_src' in in_dict['req1'] and  in_dict['req1']['query_src'] == 'test':
            continue
        request_dict.update(in_dict['req2'])
        request_dict['tid'] = in_dict['tid']
        request_dict['aos_verion'] = in_dict['sysinfo']['aos_version'] if 'aos_version' in in_dict['sysinfo'] else '-'
        response_dict['spend_time'] = in_dict['sysinfo']['spend_time'] if 'spend_time' in in_dict['sysinfo'] else '-'
        #print response_dict
        # uid
        out_dict['uid'] = '-'
        for i in ('user_info','diu'):
            if i in request_dict and request_dict[i] != '-':
                out_dict['uid'] = func.get_value(request_dict,i).upper() # 2014-6-21 sug的uid都转大写,同sp
                break
        if not pattern_uid.match(out_dict['uid']) and out_dict['uid'] != '-':
            func.counter('Count','uid illegal pass',1)
            continue
        # sessionid,stepid
        for i in ('sessionid','stepid'):
            out_dict[i] = func.get_value(request_dict,i)
        # time
        if len(in_dict['time']) == 14:
            date = in_dict['time'][:8]
            time = in_dict['time'][8:10]+':'+in_dict['time'][10:12]+':'+in_dict['time'][12:]
        else:
            date,time = '-','-'
        out_dict['time'] = time
        other_dict['date'] = date
        # position
        for i in ('geoobj','user_loc','user_city'):
            if i == 'geoobj': # [2014-5-21]geoobj分隔符替换: | --> ;
                position_dict[i] = func.get_value(request_dict,i).replace('|',';')
            else:
                position_dict[i] = func.get_value(request_dict,i)
        out_dict['action'] = func.get_value(request_dict,'query_type')
        # cellphone
        for i in ('div','platform'):
            if i == 'div': # [2014-5-21] div大写
                cellphone_dict[i] = func.get_value(request_dict,i).upper() 
            else:
                cellphone_dict[i] = func.get_value(request_dict,i)

        for i in ('position','request','response','cellphone','other'):
            out_dict[i] = func.dict2str(eval("%s_dict"%(i)))
        print '\t'.join([out_dict[i] for i in out_list])

if __name__ == '__main__':
    main()
