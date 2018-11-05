#!/usr/bin/env python
# -*- coding:utf-8 _*_

#-----------------------------
# svn路径: svn co https://10.2.161.10/svn/plana/home/warren/session/bin
#-----------------------------
#  根据sp和aos日志建设query-click表,2014-6-21
#（1）日志源：sp(name或sug有效)和sug
#（2）原则：
#（3）输入：聚合相同uid、sessionid的数据，按照uid、sessionid、source（降序，保证sp日志在前面）、stepid、time排序。如sort by uid,sessionid,source desc,cast(stepid as int),time
#（4）策略：key=uid、sessionid
#-----------------------------
# 2014-6-25 增加重复点击区分:搜索主页历史点击
# 扩充历史点击范围:
#   type='sug'    1.sug检索时弹出的历史点击(含request['sug']) 
#   type=!'sug'   2.搜索主页历史点击(无request['sug'],但有request['name']),分成2类: 
#                 type='his_sug' sug检索时弹出,最近点击,匹配上sug展现;
#                 type='his_sp' 搜索主页历史记录,较远点击(sessionid不同),未找到sug展现

import os
import sys
import re
sys.path.append('.')
import func
import json

def parse(out_list=None):
    if not out_list:
        out_list = []
    # 输出:[uid,sessionid,stepid,time,input,sug,click,request,response,sp_request,sp_response,position,cellphone]
    arr_len = len(out_list)
    if len(out_list) < 11:
        return ''
    out_list[5] = out_list[5]['list']
    for i in xrange(arr_len):
        tmp_type = type(out_list[i])
        if tmp_type == type({}):
            out_list[i] = func.dict2str(out_list[i])
        elif tmp_type == type([]):
            out_list[i] = '|'.join(out_list[i])
        elif tmp_type == type(100):
            out_list[i] = str(out_list[i])
        else:
            pass
    return '\t'.join(out_list)


def main( input_console = sys.stdin , output_console = sys.stdout ):
    format_list = ['uid','sessionid','stepid','time','position','source','action','request','response','cellphone','other','dt']
    #out_dict = {'uid':'-','sessionid':'-','stepid':'-','time':'-','position':'-','input':'-','sug':'-','click':'-','cellphone':'-'}
    #out_list = ['uid','sessionid','stepid','time','position','query','result','click','cellphone']
    pattern_uid = re.compile(r'^[\w-]+$',re.I)
    last_key = '-'
    sug_format = ['order','name','district','adcode','category','rank','poiid','address','x','y','type','distance']
    # 2014-9-13,log_sug产出格式升级,增加2个字段,可能包含子级别(7字段)
    sug_father_format = ['order','name','district','adcode','category','rank','poiid','address','x','y','type','distance','display_info','column','null'] # 增加null
    sug_son_format = ['order','name','shortname','adcode','poiid','x','y']
    len1 = len(sug_format)
    len_father = len(sug_father_format)
    len_son = len(sug_son_format)
    session_list = []
    sp_request_str = '-'
    sp_response_str = '-'
    position_str = '-'
    cellphone_str = '-'

    for line in input_console:
        # in: [uid sessionid stepid time position source action request response cellphone other]
        input = '-' # 记录输入的前缀
        sug_dict = {} # 记录当前sug对应的展现结果
        click_dict = {} # 记录当前sug的点击信息
        arr = [ i.strip() for i in line.strip().split('\t') ]
        if len(arr) != len(format_list):
            print len(arr)
            continue
        line_dict = dict(zip(format_list,arr))
        for i in ('position','request','response','cellphone','other'):
            try:
                line_dict[i] = json.loads(line_dict[i])
            except Exception,err:
                print >>sys.stderr,'json decode error(%s) ! (%s)'%(err,line_dict[i])
                continue
        uid = line_dict['uid']
        sessionid = line_dict['sessionid']
        # 获取stepid
        try:
            stepid = int(line_dict['stepid'])
        except Exception,err:
            stepid = -1
        # 获取time
        time = line_dict['time']
        source = line_dict['source']
        action = line_dict['action']
        if source == 'SUG':
            # 提取信息: input,sug,click
            input = func.get_value(line_dict['request'],'keyword')
            if input == '-':
                # request['keyword']不存在
                continue
            # 获取检索结果列表
            if 'result' not in line_dict['response']:
                # response['result']不存在
                continue
            if line_dict['response']['count'] != line_dict['response']['num']:
                # sug中问题数据,num=0,但count为汉字,830/18407380=0.0045%
                continue
            sug_dict = {'list':[],'dict':{}}
            if 'num' in line_dict['response']:
                sug_dict['num'] = line_dict['response']['num']
            result_str = line_dict['response']['result'] # sug按顺序出现
            version = line_dict['response']['version'] if 'version' in line_dict['response'] else '-' # 日志版本
            if result_str != '-' and version in ('-','1_0','1_1'):
                # 旧版有展现日志
                for item in result_str.split('&'):
                    # 2014-6-25 sug展现list中包含不规范项
                    tmp_item_list = item.split('|')
                    cur_len = len(tmp_item_list)
                    if cur_len in (len1,len1-1):
                        if cur_len == len1 -1:
                            tmp_item_list.insert(-2,'-') # 2014-6-29 旧版格式,少了type,为了保持sug-click格式一致,临时增加type字段(取值为-)
                    else:
                        # 2014-6-26 跳过问题数据
                        print >>sys.stderr,'item len(%s) in result_str error! (result_str=%s,item=%s) '%(cur_len,result_str,item)
                        continue
                    item_dict = dict(zip(sug_format,item.split('|')))
                    # 2014-6-24 应jeff要求,增加展现字段poiid
                    sug_dict['list'].append(':'.join([item_dict['order'],item_dict['poiid'],item_dict['name']]))
                    sug_dict['dict'][item_dict['name']] = [item_dict['order'],item_dict['poiid']]
            elif result_str != '-' and version == '2_0':
                # 新版有展现日志
                for item in result_str.split('&'):
                    tmp_item_list = item.split('|')
                    cur_len = len(tmp_item_list)
                    # 2014-9-13 增加子层级
                    if cur_len == len_father:
                        # 新版父级别格式(2.0)
                        item_dict = dict(zip(sug_father_format,item.split('|')))
                        pass
                    elif cur_len == len_son:
                        item_dict = dict(zip(sug_son_format,item.split('|')))
                        pass
                    else:
                        print >>sys.stderr,'item len(%s) in result_str error! (result_str=%s,item=%s) '%(cur_len,result_str,item)
                        continue
                    # 提取相关展现字段poiid
                    sug_dict['list'].append(':'.join([item_dict['order'],item_dict['poiid'],item_dict['name']]))
                    sug_dict['dict'][item_dict['name']] = [item_dict['order'],item_dict['poiid']]
            #print repr(sug_dict)
            #print '|'.join(sug_dict['list'])
            # 冗余信息
            request_str = func.dict2str(line_dict['request'])
            response_str = func.dict2str(line_dict['response'])
            position_str = func.dict2str(line_dict['position'])
            cellphone_str = func.dict2str(line_dict['cellphone'])
        elif source == 'SP':
            if 'name' not in line_dict['request'] and 'sug' not in line_dict['request']:
                # 过滤非sug转化的检索请求
                continue
            # 冗余信息
            sp_request_str = func.dict2str(line_dict['request'])
            sp_response_str = func.dict2str(line_dict['response'])
        else:# 异常类别,直接过滤
            continue
            pass
        uid_pass = 0
        len_sp = len(session_list)
        # 过滤异常用户 freq > 1w ,防止数据倾斜
        if len_sp > 10000:
            session_list = []
            uid_pass = 1 
        # 输出:[uid,sessionid,stepid,time,input,sug,click,request,response,sp_request,sp_response,position,cellphone]
        # uid+sessionid 作为key
        cur_key = uid+'\t'+sessionid
        if cur_key == last_key:
            if source == 'SUG':
                if uid_pass:
                    continue
                # key相同,追加记录到session_list中
                session_list.append([uid,sessionid,stepid,time,input,sug_dict,click_dict,request_str,response_str,'-','-',position_str,cellphone_str])
            elif source == 'SP':
                # 根据stepid,time降序排序
                # session_list.sort(key=lambda x:(x[2],x[3]),reverse=True)
                # 获取name
                name = line_dict['request']['name'] if 'name' in line_dict['request'] else '-'
                # 2014-6-26 特殊字符转义,与log_sug配套
                new_name = name.replace('|','$').replace('&','#') 
                # 获取sug
                #sug = line_dict['request']['sug'] if 'sug' in line_dict['request'] else '-'
                # 匹配sug点击,sug不同于query,不存在多次、重复点击(返回后,input变化且sug列表消失)
                for j in xrange(len_sp): # session_list按照stepid倒序查找
                    i = - (j+1)
                    item = session_list[i]
                    if stepid != -1 and stepid <= item[2]:
                        # stepid有效时,需要限制查找范围
                        continue
                    """
                    # [2014-9-3] sug字段记录了前缀,非历史信息,不再作为历史类别的区分依据
                    if 'sug' in line_dict['request']:
                        # 1.sug有效,历史点击(不同于主图页历史记录),各种类别都有(tquery,idq,rqbxy)
                        # 从session_list中的input找sug
                        if sug == item[4]:
                            # 命中,记录点击信息click_dict
                            item[6]['type'] = 'his_sug'
                            item[6]['stepid'] = stepid
                            item[6]['time'] = time
                            item[6]['query_type'] = action
                            item[6]['data_type'] = line_dict['request']['data_type']
                            item[9] = sp_request_str
                            item[10] = sp_response_str
                            break
                    """
                    if 'name' in line_dict['request']:
                        # 2.sug无效但name有效,最新点击
                        # 从session_list中的展现列表(sug_dict['dict'])中挨个查找
                        if new_name in item[5]['dict']:
                            # 命中,记录点击信息click_dict
                            if 'type' in item[6]:
                                # 重复点击,搜索页历史点击
                                id = line_dict['request']['id'].upper() if 'id' in line_dict['request'] else '-'
                                if 'his_sp' in item[6]:
                                    # 累加多次点击,记录次数, 2014-6-27 分隔符:->$,数据未清洗
                                    item[6]['his_sp'] += '|' + '$'.join([sessionid,str(stepid),time,id,name])
                                    item[6]['his_num'] = str(int(item[6]['his_num']) + 1)
                                else:
                                    item[6]['his_sp'] = ':'.join([sessionid,str(stepid),id,name])
                                    item[6]['his_num'] = '1'
                            else:
                                # 首次匹配
                                item[6]['type'] = 'sug'
                                item[6]['stepid'] = stepid
                                item[6]['time'] = time
                                item[6]['query_type'] = action
                                item[6]['data_type'] = line_dict['request']['data_type']
                                item[6]['name'] = name
                                item[6]['order'] = item[5]['dict'][new_name][0] # order
                                item[6]['poiid'] = item[5]['dict'][new_name][1] # poiid
                                # 2014-6-26 新增区分泛需求点击的字段
                                if item[6]['poiid'] == '-':
                                    item[6]['is_general'] = '1'
                                item[9] = sp_request_str
                                item[10] = sp_response_str
                        else: # 匹配失败 2014-6-25
                            tmp_click_dict = {'type':'his_sp','name':name}
                            tmp_str = func.dict2str(tmp_click_dict)
                            #[uid,sessionid,stepid,time,input,sug_dict,click_dict,request_str,response_str,'-','-',position_str,cellphone_str]
                            print '\t'.join([uid,sessionid,str(stepid),time,'-','-',tmp_str,'-','-',sp_request_str,sp_response_str,position_str,cellphone_str])
        else: # key变化,清空当前query-list,初始化
            #session_list.sort(key=lambda x:(x[2],x[3]),reverse=True)
            for item in session_list:
                print parse(item)
                uid_pass = 0
            session_list = []
            if source == 'SUG': 
                session_list.append([uid,sessionid,stepid,time,input,sug_dict,click_dict,request_str,response_str,'-','-',position_str,cellphone_str])
                last_key = cur_key
            elif source == 'SP':
                # 匹配失败:独立点击 
                tmp_click_dict = {'type':'his_sp'}
                tmp_str = func.dict2str(tmp_click_dict)
                print '\t'.join([uid,sessionid,str(stepid),time,'-','-',tmp_str,'-','-',sp_request_str,sp_response_str,position_str,cellphone_str])
                #print >>sys.stderr,'only in AOS (%s)'%(cur_key)
            else:
                pass
    #print json.dumps(tmp_dict,ensure_ascii=False,encoding='utf-8',indent=4)
    #session_list.sort(key=lambda x:(x[2],x[3]),reverse=True)
    for item in session_list:
        print parse(item)

if __name__ == '__main__':
    main()
