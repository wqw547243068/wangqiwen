# !/usr/bin/env python
# -*- encoding:utf8 -*-

import urllib
import re
import sys

reload(sys)
sys.setdefaultencoding( "utf-8" )


pattern_empty = re.compile(r"^(\s*|null)$",re.I)


def str2dict(in_str,seg1='+',seg2=':'):
    ''' 将hive的map类别转成dict '''
    out_dict = {}
    if not isinstance('-',str):
        return {}
    for i in in_str.split(seg1):
        tmp_i = [j for j in i.split(seg2,1)] # 2014-5-16 split(seg2) -> split(seg2,1)
        if len(tmp_i) < 2:
            continue
        out_dict[tmp_i[0]] = tmp_i[1]
    return out_dict

def dict2str(tmp_dict,seg2='\002',seg3='\003'):
    ''' 将dict转成hive的map类别 str '''
    out_str = ''
    if not isinstance(tmp_dict,dict):
        return '-'
    for k,v in tmp_dict.items():
        out_str += k + seg3 + str(v) + seg2
    out_str = out_str.strip(seg2)
    if pattern_empty.match(out_str):
        out_str = '-'
    return out_str

def get_value(data_dict,key):
    # 从dict中提取指定的值，并将原值清空
    if type(data_dict) != type({}):
        return '-'
    if key not in data_dict:
        return '-'
    value = data_dict[key]
    if not value:
        value = '-'
    del data_dict[key]
    return value

def get_citycode(xy_list):
    # RGEOCODE:根据坐标获取citycode
    length = len(xy_list)
    if length == 0 or length % 2 != 0:
        # 坐标转换
        return []
    #pattern_citycode = re.compile(r".*?<spatialbean>.*?<citycode>(.*?)</citycode>.*?</spatialbean>",re.M)
    pattern_citycode = re.compile(r".*?<citycode>(.*?)</citycode>",re.M)
    # RGEO服务器地址  华凰提供的专用机,旧日志平台使用的机器,南京线上机群,    测试机(胡园园)
    #host_list = ['10.2.134.244',   '10.13.4.9',         'nlse.amap.com','10.2.135.57']
    host_list = ['10.13.2.30','10.2.134.244',   '10.13.4.9',         'nlse.amap.com','10.2.135.57']
    for host in host_list:
        if host == '10.13.2.30':
            # [2014-5-27] 户华凰单独在server217上搭建了rgeo引擎
            #url = 'http://10.13.2.30:8887/sisserver.php?query_type=RGEOCODE&x=116.3544845&y=39.98882653&poinum=10&range=200&roadlevel=0&pattern=0&ignorePoi=0&query_src=test&user_info=test&qii=false&rgeo_server_ip=127.0.0.1&rgeo_server_port=23337'
            url = 'http://%s:8887/sisserver.php?query_type=RGEOCODE&datasrc=%s&poinum=0&roadnum=0&crossnum=0&roadlevel=0&pattern=0&ignorePoi=0&query_src=test&user_info=test'%(host,';'.join(xy_list))
        else:
            url = 'http://%s/sisserver.php?query_type=RGEOCODE&datasrc=%s&poinum=0&roadnum=0&crossnum=0&roadlevel=0&pattern=0&ignorePoi=0&query_src=test&user_info=test'%(host,';'.join(xy_list))
        #[2014-5-19] rgeo速度慢,华凰提供精简版的接口  暂未测试
        #new_url = 'http://10.2.134.244/sisserver.php?query_type=RGEOCODE&x=116.3544845&y=39.98882653&poinum=10&range=200&roadlevel=0&pattern=0&ignorePoi=0&query_src=test&user_info=test&qii=false&rgeo_server_ip=127.0.0.1&rgeo_server_port=23337'
        try:
            page = urllib.urlopen(url).read()
        except Exception,err:
            # 本次请求失败,自动尝试下一台机器
            print >>sys.stderr,'RGEO request in host(%s) failed! next'%(host)
            continue
        # 本次请求成功,停止循环
        break
    out = pattern_citycode.findall(page)
    return out

def adcode2citycode(city_file='adcode.csv'):
    # 城市编码转换: 邮编(adcode),中文(adname)--> citycode 
    # 依赖文件提前转码: cat adcode.csv.bak | iconv -f gbk -t utf8 > adcode.csv
    out_dict = {}
    out_dict['adcode'] = {}
    out_dict['adname'] = {}
    for line in file(city_file): 
        #line = line.decode('gbk').encode('utf8')
        arr = [i.strip() for i in line.split(',')]
        if len(arr) < 8:
            continue
        # [adcode,adname,en_adname,,x,y,citycode,telcode]
        adcode,adname,citycode = arr[0],arr[1],arr[6]
        if len(arr) != 8 or adcode == 'adcode':
            continue
        out_dict['adcode'][adcode] = citycode
        # 2014-6-17 adname以unicode形式存储,非utf8,解决utf8汉字匹配失败问题
        out_dict['adname'][adname.decode('utf8')] = citycode
    return out_dict

def counter(group, counter_name, amount):
    # hadoop&hive mapreduce counter
    #sys.stderr.write("reporter:counter:" + group + "," + counter_name + "," + str(amount) + "\n");
    # 2014-5-26
    pass

def loadGeneralDict(general_file='fanquery.txt'):
    # 加载泛需求字典
    out_dict = {}
    for line in file(general_file,'rb'):
        word = line.strip()
        if len(word) == 0:
            continue
        out_dict[word.decode('utf8')] = 1 # 以unicode编码存储,非utf8
    return out_dict
