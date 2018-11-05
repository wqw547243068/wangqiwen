#!/usr/bin/env python
# -*- coding:utf-8 _*_

#-----------------------------
# 2014-5-14: 绝处逢生,慎用rm -rf!，坚持用svn
# 恢复:svn up -r33 https://10.2.161.10/svn/cpr/trunck/dw/
# 新svn路径: svn co https://10.2.161.10/svn/plana/home/warren/session/bin
# 2014-6-17: 开启rgeo服务,修复city中文转数字的bug,增加泛需求区分字段is_general
#-----------------------------

import os
import sys
import re
import urllib
sys.path.append('.')
import func
import cifa
import json

reload(sys)
sys.setdefaultencoding("utf-8")

def main( input = sys.stdin , output = sys.stdout ):
    '''
    235702000010    addr_poi_merge:true+aos_version:2.12+app:sp_app+auto_cluster:false+cifa:800270049e7fd106ae72d101000000cc010300000000000000000000000000000000000000000000000000070000000500372e302e3409006950686f6e65362c3105004150504c450000000000000000000000000500+citysuggestion:true+data_type:poi+dic:c3320+dip:10920+diu:ac9b6b64-959e-4046-8b4b-615198ba06c1+diu2:63a8c5d9-93f2-4f6b-bad4-292e40e665a8+diu3:3908e66368f8407d6db29e833fd06abf82486d2b+div:iosh060400+expand_range:false+group_by_category:false+group_by_click:true+group_by_find_good_around_bus_station:true+group_by_name_component_result:true+group_by_parent:true+group_by_pos_standrand_order:true+group_by_whole_match:true+group_by_xy:true+group_by_xy_and_field:true+keywords:�ư�+location:true+name_replace:true+need_expand_range:true+noseg:parent;pguid;nid;brand_id;brand+page:1+page_num:10+qii:true+qii_server_port:14001+query_busline:true+query_channel:true+query_road:true+query_scene:category+query_src:amap6+query_type:rqbxy+range:5000.0+route_plan:true+search_operate:2+server_port:13333+session:104715881+show_fields:all+sort_filter:true+stepid:151+use_log:true+user_info:ac9b6b64-959e-4046-8b4b-615198ba06c1+user_loc:114.398544,30.501300+x:114.397759+y:30.500967+queryid=22263ea2-1b23-4617-bbdf-54b14df85c30 from:10.25.71.209+poi_ids:B001B0J0GS&B001B1ITO9&B0FFF0EGIZ&B0FFF0DQSJ&B001B16VTB&B0FFF0DQSI&B0FFF0EGWP&B0FFF0EWB2&B001B18O79&B001B1GZOU+qii_querytype:5+count:67+searchtime:81+totaltime:156
    '''
    # out ---> 【uid（用户标识,string） time（时间,string） position（地点,map） source（数据源,string） action（动作类别,string） request（请求信息,map） response（响应信息,map） other（其他信息,map）】
    format_list = ['tm','request','response','dt']
    cellphone_list = ['div','model','device','manufacture']
    out_dict = {'uid':'-','sessionid':'-','stepid':'-','time':'-','position':'-','source':'SP','action':'-','request':'-','response':'-','cellphone':'-','other':'-'}
    out_list = ['uid','sessionid','stepid','time','position','source','action','request','response','cellphone','other']
    pattern_uid = re.compile(r'^[\w-]+$',re.I)
    #illegal_uid = ('NULL','unknown','0','aos') # 2014.5.22 无效uid
    #illegal_uid = ('NULL','unknown','353021051343571','0','000000000000000','111111111111111','aos') # 2014.5.22 无效uid
    illegal_uid = ('NULL','unknown','aos')
    # 加载邮政编码映射字典
    city_dict = func.adcode2citycode()
    #print city_dict['adname'].keys()
    #print '|'.join(city_dict['adname'].keys())
    # 2014-6-17 加载泛需求字典
    general_dict = func.loadGeneralDict()
    #print '|'.join(general_dict.keys())
    #print format_list
    for line in input:
        position_dict = {}
        request_dict = {}
        response_dict = {}
        cellphone_dict = {}
        other_dict = {}
        '''
        # 2014.5.22 原始日志utf8编码,停止转换,否则造成部分数据乱码
        # [2014-5-8] 5月8日以后的日志才是flume utf-8编码，之前是ftp方式直接上传原始日志（gbk）
        # 编码转换: gbk -> utf8
        try:
            line = line.decode('gbk').encode('utf8')
        except Exception,err:
            pass
        # 2014-5-23
        if line.find('\t') != -1:
            arr = [ i.strip() for i in line.strip().split('\t') ]
        else: # 兼容2014-5-8转码后异常数据,空格分隔
            arr = [ i.strip() for i in line.strip().split(' ') ]
        '''
        arr = [ i.strip() for i in line.strip().split('\t') ]

        if len(arr) != len(format_list):
            func.counter('Count','line length error',1)
            #print >>sys.stderr,'line length error ! %s!=%s \nline=(%s)'%(len(arr),len(format_list),line)
            continue
        line_dict = dict(zip(format_list,arr))
        line_dict['request'] = json.loads(arr[1])
        line_dict['response'] = json.loads(arr[2])
        tm = line_dict['tm']
        if len(tm) > 6:
            out_dict['time'] = tm[0:2]+':'+tm[2:4]+':'+tm[4:6]
        request_dict = line_dict['request']
        response_dict = line_dict['response']
        if not request_dict or 'query_type' not in request_dict:
            func.counter('Count','query_type miss',1)
            continue
	#2014-11-19 过滤抓取日志
	if request_dict.get('user_info','-') == 'test' and request_dict.get('query_src','-') == 'test':
	    continue
        if 'user_info' in request_dict and pattern_uid.match(request_dict['user_info']):
            uid = func.get_value(request_dict,'user_info')
        elif 'diu' in request_dict and pattern_uid.match(request_dict['diu']):
            uid = func.get_value(request_dict,'diu')
        else: # 2014-6-17 用户标识缺失时,直接跳过
            continue
        # 2014-6-17,过滤码点日志,占全量日志的1/3
        if request_dict['query_type'] == 'indoor_slayer':
            continue
        # 2014.5.22
        if uid in illegal_uid:
            func.counter('Count','uid error',1)
            continue
        out_dict['uid'] = uid  #2014-09-05 不强制转大写
	#2014-11-14 add sessionid
	if 'session' in request_dict: 
            out_dict['sessionid'] = func.get_value(request_dict,'session')
	elif 'sessionid' in request_dict:
	    out_dict['sessionid'] = func.get_value(request_dict,'sessionid')
	else:
	    out_dict['sessionid'] = '-'
        if 'step' in request_dict:
            out_dict['stepid'] = func.get_value(request_dict,'step')
        elif 'stepid' in request_dict:
            out_dict['stepid'] = func.get_value(request_dict,'stepid')
        else:
            out_dict['stepid'] = '-'
        out_dict['action'] = func.get_value(request_dict,'query_type').upper()
        if 'data_type' in request_dict:
            request_dict['data_type'] = request_dict['data_type'].upper()
            other_dict['data_type'] = request_dict['data_type'].upper() # 2014-09-05 add data_type to other
        # cifa解析  2014-5-5
        cifa_dict = {}
        if 'cifa' in request_dict:
            cifa_str = func.get_value(request_dict,'cifa')
            cifa_dict = cifa.parse_cifa(cifa_str) # 解密cifa

        for i in ('diu','diu2','diu3'):
            other_dict[i] = func.get_value(request_dict,i)
        for i in ('x','y','user_loc','geoobj'):
            position_dict[i] = func.get_value(request_dict,i)
            # 用cifa中的lon,lat填充user_loc值
            if i == 'user_loc' and position_dict[i] == '-' and 'lon' in cifa_dict and 'lat' in cifa_dict:
                position_dict[i] = str(float(cifa_dict['lon'])/10**6)+','+str(float(cifa_dict['lat'])/10**6)
        # RGEOCODE  2014-5-7
        geo_list = []
        citycode = '-'
        if request_dict.has_key('city'):
            # 请求数据中自带city时,做相应转换后,赋给citycode
            city = func.get_value(request_dict,'city').strip() # city中文后有空格,去掉  2014-5-15
            # 根据不同情形做相应转换
            len_city = len(city)
            if len_city <= 1: # 2014-6-17 '==' -> '<=',校正city为空的情形
                city = '-'
            elif city.isdigit():
                if len_city == 2 or ( len_city == 3 and not city.startswith('0') ):
                    city = '0' + city
                elif len_city == 6:
                    # 邮政编码转城市编码
                    try:
                        city = city_dict['adcode'][city]
                    except Exception,err:
                        print >>sys.stderr,'adcode -> citycode error! (%s)'%(err)
                        pass
            else: # 中文转城市编码,2014-6-17,增加市前先判断是否存在
                if not city.endswith('市') and city not in city_dict['adname']:
                    city += '市'
                try:
                    city = city_dict['adname'][city]
                    #city = city_dict['adname'][city.decode('utf8').encode('gbk')]
                except Exception,err:
                    print >>sys.stderr,'adname -> citycode error! (%s,%s)'%(city,err)
                    pass
            citycode = city
        elif position_dict['x'] != '-' and  position_dict['y'] != '-' :
            # 若周边搜中心点坐标(x,y)有效,则提取
            geo_list.append(position_dict['x'])
            geo_list.append(position_dict['y'])
        elif position_dict['geoobj'] != '-':
            # 若框搜屏幕范围有效,则提取中心点,125.66938474774362;42.52542902867981;125.68344756960867;42.510687821378596
            geoobj_list = position_dict['geoobj'].split(';')
            if len(geoobj_list) == 4:
                # 计算屏幕中心点坐标
                try:
                    geo_list.append(str((float(geoobj_list[0]) + float(geoobj_list[2]))/2))
                    geo_list.append(str((float(geoobj_list[1]) + float(geoobj_list[3]))/2))
                except Exception,err:
                    # 数据里存在异常值: 109,106313586235
                    pass
        if citycode == '-' and len(geo_list) == 2:
            # 数据中不含city且x,y或geoobj有效时,调用RGEOCODE服务获取citycode
            try:
                tmp_citycode = func.get_citycode(geo_list)
            except Exception,err:
                print >>sys.stderr,'Regeo ERROR ! (%s)'%(repr(geo_list))
                tmp_citycode = []
            if tmp_citycode:
                citycode = tmp_citycode[0]
        geo_list = []
        position_dict['citycode'] = citycode if citycode != '' else '-' # 2014-6-18 校正citycode=''为'-'
        # 获取用户实际位置对应的城市
        user_loc_city = '-'
        if position_dict['user_loc'] != '-':
            # user_loc:114.398544,30.501300
            user_loc_list = position_dict['user_loc'].split(',')
            if len(user_loc_list) == 2:
                try:
                    tmp_citycode = func.get_citycode(user_loc_list)
                except Exception,err:
                    print >>sys.stderr,'Regeo ERROR ! (%s)'%(repr(user_loc_list))
                    tmp_citycode = []
                if tmp_citycode:
                    user_loc_city = tmp_citycode[0]
        position_dict['user_loc_city'] = user_loc_city
        # 手机相关信息
        for i in cellphone_list:
            if i in cifa_dict:
                if i == 'div':  # [2014-5-21] div 大写
                    cellphone_dict[i] = func.get_value(cifa_dict,i).upper()
                else:
                    cellphone_dict[i] = func.get_value(cifa_dict,i)
            else:
                if i == 'div':
                    cellphone_dict[i] = func.get_value(request_dict,i).upper()
                else:
                    cellphone_dict[i] = func.get_value(request_dict,i)  #2014-09-05  cifa_dict->request_dict
        # 2014-6-17  新增字段is_general标记是否泛需求
        if 'keywords' in request_dict:
            if request_dict['keywords'] in general_dict:
                request_dict['is_general'] = '1'

        request_dict['cifa'] = func.dict2str(cifa_dict,';','=')
        for i in ('position','request','response','cellphone','other'):
            out_dict[i] = func.dict2str(eval("%s_dict"%(i)))
        try:
            return '\t'.join([out_dict[i] for i in out_list])
        except Exception,err:
            print >>sys.stderr,'out_dict print error! (%s)'%(repr(out_dict))
            pass
    #print json.dumps(tmp_dict,ensure_ascii=False,encoding='utf-8',indent=4)

if __name__ == '__main__':
    main()
