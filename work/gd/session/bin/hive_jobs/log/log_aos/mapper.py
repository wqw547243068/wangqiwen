#!/usr/bin/env python
# -*- coding:utf-8 _*_
#========================================
#   warren@autonavi.com
#   2014-6-11 11:53 将aos log中冗余信息保留下来，放入request中,方便张磊统计sp检索响应时间
#   2014-6-13 6.11增加冗余字段失效,导致aos格式偏移,连续两天query-click点击量为0,原因是正则错误，包含了tab和分区字段
#========================================

import os
import sys
sys.path.append('.')
import time
import json
import re
import urllib
import func
import xy2ccode

reload(sys)
sys.setdefaultencoding( "utf-8" )

def main( input = sys.stdin , output = sys.stdout ):
    # input: diu    date    time    path    para
    # output: uid   time    position  source action request response other; partition: dt
    # 359188049115769   2014-01-07  00:00:00    /ASS    t=traf
    out_list = ['uid','sessionid','stepid','time','position','source','action','request','response','cellphone','other']
    #format_str = ('date','time','method','path','para','code','size','os','resp_time')
    # 2014.6.13 只保留部分有用字段
    format_str = ('date','time','path','para','os','resp_time')
    # 2014.6.13 修改正则,兼容分区字段dt,解决query-click点击量为0的问题
    pattern_apache = re.compile(r"^.*?\s+.*?\s+.*?\[(.*?)\s+(.*?)\..*?\]\s+\".*?\s+(.*?)\?(.*?)\s+HTTP.*\"\s+.*?\s+.*?\s+\".*?\"\s+\"(.*?)\"\s+(.*?)\t.*?$",re.I)
    #pattern_apache = re.compile(r"^.*?\s+.*?\s+.*?\[(.*?)\s+(.*?)\..*?\]\s+\"(.*?)\s+(.*?)\?(.*?)\s+HTTP.*\"\s+(.*?)\s+(.*?)\s+\".*?\"\s+\"(.*?)\"\s+(.*?)$",re.I)
    pattern_uid = re.compile(r'^[\w-]+$',re.I)
    # 2014-5-16 cifa信息移动至cellphone
    #para_dict = {'uid':'diu','sessionid':'session','stepid':'stepid','position':['user_loc','geoobj'],'cellphone':['div'],'other':['diu2','diu3','tid']} #2014-09-02 add tid
    para_dict = {'uid':'diu','sessionid':'session','stepid':'stepid','cellphone':['div'],'other':['diu2','diu3','tid']} #2014-09-02 add tid
    position_key = ('user_loc','geoobj')

    # 加载adcode转citycode表
    adcodeDict = func.adcode2citycode()
    # 加载aos url映射表
    aos_dict = {}
    #aos_file = '../../../tool/aos.txt'
    aos_file = 'aos.txt'
    for line in file(aos_file):
        arr = [i.strip() for i in line.strip().split('\t')]
        key,value = arr[0:2]
        if len(arr) != 3:
            #20141112,garnett
            #print >>sys.stderr,'aos dict line error !(%s)'%(line)
            continue
        aos_dict[key.rstrip('/')] = value

    in_dict = {}
    for line in input:
        #line = line.replace("%0A","").replace("%0D","")
        p = pattern_apache.match(line)
        if not p:
            #20141112,garnett
            #func.counter('Count','line pattern miss',1)
            continue
        out_dict = {}
        in_dict = dict(zip(format_str,p.groups()))
        # 2014-09-05  del test data
        if in_dict['os'] == 'autonavi-ssl-scanner':
            continue
        #out_dict['time'] = in_dict['time']
        out_dict['time'] = func.get_value(in_dict,'time') # 2014-6-11
        para = urllib.unquote(func.get_value(in_dict,'para'))
        tmp_para = func.str2dict(para,'&','=')
        if 'diu' not in tmp_para or not pattern_uid.match(tmp_para['diu']) or tmp_para['diu'] == 'null' :
            # diu missed  [2014-3-17]
            #20141112,garnett
            #print >>sys.stderr,'diu missed ! (%s)'%(repr(tmp_para))
            #func.counter('Count','diu miss|match',1)
            continue
		#2014-09-02 解析searchhomepage中参数
        for k in tmp_para.keys():
            if k.startswith('shp_'):
                if k[4:] not in tmp_para:
                    tmp_para[k[4:]] = tmp_para[k].strip()
                    del tmp_para[k]
                else:
                    tmpkey = k[4:] + "newest"
                    tmp_para[tmpkey] = tmp_para[k].strip()
                    tmp_para[k[4:]] = tmp_para[k].strip()
                    del tmp_para[k]

            else:
                tmp_para[k] = tmp_para[k].strip()
        for k in para_dict:
            v = para_dict[k]
            if type(v) == type('str'):
                if v not in tmp_para:
                    if v == 'stepid':
                        # 2014-7-21 step -> stepid
                        out_dict[k] = func.get_value(tmp_para,'step')
                    elif v=='session':
                        #2014-09-02 sessionid-> sessionid
                        out_dict[k] = func.get_value(tmp_para,'sessionid')
                    else:
                        out_dict[k] = '-'
                else: # 2014-5-16 para参数取出
                    out_dict[k] = func.get_value(tmp_para,v)
            elif type(v) == type([]):
                out_dict[k] = {}
                for i in v:
                    if i in tmp_para:
                        out_dict[k][i] = func.get_value(tmp_para,i)
            else:
                #20141112,garnett 
                #print >>sys.stderr,'Illegal key(%s) found !'%(k)
                #func.counter('Count','illegal key',1)
                continue
        # 获取位置信息
        x, y = '-','-'
        for i  in ('x','lon','longitude'):
            if i in tmp_para and tmp_para[i] not in ('','-'):
                x = func.get_value(tmp_para,i)
                break
        for i  in ('y','lat','latitude'):
            if i in tmp_para and tmp_para[i] not in ('','-'):
                y = func.get_value(tmp_para,i)
                break
        # 2014-5-16,挪动cifa信息到other中,与sp保持一致
        # cifa里的经纬度赋给position,manufacture,model等赋给cellphone
        cifa_str = func.get_value(tmp_para,'cifa')
        cifa_dict = func.str2dict(cifa_str,';','=') #2014-09-02 把字符串cifa_dict转化成dict
        if x == '-' and 'lon' in cifa_dict:
            lon = func.get_value(cifa_dict,'lon')
            try:
                x = str(float(lon)/10**6)
            except Exception,err:
                pass
        if y == '-' and 'lat' in cifa_dict:
            lat = func.get_value(cifa_dict,'lat')
            try:
                y = str(float(lat)/10**6)
            except Exception,err:
                pass

        out_dict['position'] = {}
        out_dict['position']['x'] = x
        out_dict['position']['y'] = y
        # user_loc:114.398544,30.501300
        try:
            adcode = xy2ccode.xy2ccode(float(x),float(y))
        except Exception:
            adcode = "-"
        out_dict['position']['citycode'] = adcodeDict.get('adcode').get(adcode,adcode)

        for i in ('device','model','manufacture'):
            out_dict['cellphone'][i] = func.get_value(cifa_dict,i)
        out_dict['cellphone']['cifa'] = cifa_str #2014-09-02

        for k in position_key:
            if not tmp_para.has_key(k):
                #20141112,garnett
                #func.counter('Count','position key miss',1)
                continue
            if k == 'geoobj':
                out_dict['position'][k] = func.get_value(tmp_para,k).replace('|',';')

            else:
                out_dict['position'][k] = func.get_value(tmp_para,k)


        out_dict['source'] = "AOS" # source
        action = func.get_value(in_dict,'path').rstrip('/') # action,去掉右侧/
        out_dict['action'] = action
        # /ws/valueadded/deepinfo/search --- poi详情页点击
        #if action == '/ASS':
            # 姜顺平:/ASS开头的是老版本，5.0之前，被动行为，记录了实时交通和定位信息，可以去掉
            # ws开头的最新的版本，记录用户的主动行为
            #func.counter('Count','ASS pass',1)
            #continue
        #[2014-5-6] 将action翻译成中文解释
        try:
            action_name = aos_dict[action]
        except Exception,err:
            action_name = '-'
            #20141112,garnett
            #print >>sys.stderr,'%s not in aos_dict !'%(action)
            pass
        #out_dict['action'] = in_dict['path'].rstrip('/') # action,去掉右侧/
        out_dict['request'] = tmp_para # request
        out_dict['request'].update(in_dict) # 2014-6-13 6.11增加冗余字段失效,导致aos格式偏移,原因是正则错误，包含了tab和分区字段
        #out_dict['other'] = {} # info  #2014-09-02 不要重置字典，会把已有内容清空
        # [2014-5-16] 将中文解释添加进去
        out_dict['other']['action_name'] = action_name
        #out_dict['other']['diu2'] = func.get_value(tmp_para,'diu2') #2014-09-02前面已取ine68-83
        #out_dict['other']['diu3'] = func.get_value(tmp_para,'diu3') #2014-09-02前面已取ine68-83
        out_dict['response'] = {} # response,aos不记录返回信息
        # pack result:
        out_str = '-'
        for i in out_list:
            if i not in out_dict:
                #20141112,garnett
                #print >>sys.stderr,'key(%s) not in out_dict!'%(i)
                #func.counter('Count','out_dict miss',1)
                continue
            v = out_dict[i]
            if type(v) == type({}):
                if out_str == '-':
                    out_str = func.dict2str(v)
                else:
                    out_str += '\t' + func.dict2str(v)
            else:
                out_str += '\t' + v
        print >>output,out_str.lstrip('-\t')

if __name__ == '__main__':
    main()

