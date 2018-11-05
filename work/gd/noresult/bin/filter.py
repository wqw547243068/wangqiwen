#encoding=utf8
import re
import sys
import urllib
import os
import urllib2
import re
import json
import zipfile
from threading import Timer
from time import sleep
from time import time


def catch(url):
    try:
        headers = {'User-Agent':'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.95 Safari/537.36'}
        req = urllib2.Request(url=url, headers=headers)
        response = urllib2.urlopen(req, timeout=5.0)
        html = response.read()
        return html.decode('utf8').encode('utf8')
    except Exception as e:
        #print 'timeout when find url = %s' % (url)
        #print e
        return ''

def load_city(city_file='conf/city.txt'):
    # 加载高德、百度城市编码字典
    out_dict = {}
    for line in file(city_file, 'rb'):
        # [gaode_name gaode_code baidu_name baidu_code]
        arr = line.strip().split('\t')
        if len(arr) != 4:
            continue
        out_dict[arr[1]] = arr[2:4]
    return out_dict

def load_equal_words(equal_file='conf/equalFilterWord.txt'):
    # 加载严格匹配字典
    out_dict = {}
    for line in file(equal_file,'rb'):
        word = line.strip()
        if len(word) == 0:
            continue
        out_dict[word] = 1
    return out_dict

def load_contain_words(contain_file='conf/containFilterWord.txt'):
    # 加载模糊匹配字典
    out_list = []
    for line in file(contain_file,'rb'):
        word = line.strip()
        if len(word) == 0:
            continue
        out_list.append(word)
        #out_list.append(word.replace('|','\|'))
    return out_list
    #return '|'.join(out_list)


if __name__ == '__main__':
    pattern_null = re.compile(r"^(null|none|)$",re.I)
    # 城市编码字典
    city_file = 'conf/city.txt'
    # 严格黑名单：城市名称
    equal_file = 'conf/equalFilterWord.txt'
    # 模糊黑名单：特殊词汇，如“我的位置”
    contain_file = 'conf/containFilterWord.txt'
    if len(sys.argv) == 3:
        #print >>sys.stderr,"[%s][error] 参数不足3个!(city_file equal_file contain_file)使用默认参数"%(sys.argv[0])
        city_file = sys.argv[1]
        equal_file = sys.argv[2]
        contain_file = sys.argv[3]
    city_dict = load_city(city_file)
    equal_dict = load_equal_words(equal_file)
    # 模糊黑名单：特殊词汇，如“我的位置”
    contain_list = load_contain_words(contain_file)
    for line in sys.stdin:
        # 解析无结果初级数据
        # [ query query_type citycode geo user_freq count_freq]
        arr = line.strip().split('\t')
        if len(arr) != 6:
            continue
        # 空值规范化
        for i,v in enumerate(arr):
            if pattern_null.match(v):
                arr[i] = '-'
        query,query_type,citycode,geo,user_freq,count_freq = arr
        # 获取城市名,百度code
        try:
            cityname,baiducode = city_dict[citycode]
        except Exception,err:
            #print >>sys.stderr,'citycode (%s) error!'%(citycode)
            cityname,baiducode = '-','-'
        # 百度链接
        baidu = '-'
        # 对一框搜和周边搜进行加工
        # 过滤词表——模糊黑名单
        pass_over = 0
        for i in contain_list:
            if query.find(i) != -1:
                pass_over = 1
                break
        if pass_over == 1:
            continue
        # 过滤词表——严格黑名单
        if query in equal_dict:
            continue
        # 获取百度链接 
        baidu = '-'
        try:
            s = 'http://api.map.baidu.com/place/v2/search?ak=9bec284e78dce791a2bd69bb399489ab&output=json&query=%s&page_size=10&page_num=0&scope=1&region=%s' % (query,cityname)
            if int(user_freq) >= 3:
                html = catch(url=s)
                if html != '':
                    j = json.loads(html)
                    try:
                        baidu = 'http://map.baidu.com/?newmap=1&s=con%26wd%3D'+query+'%26c%3D'+baiducode+'&fr=alae0&ext=1&from=alamap'
                    except:
                        pass
        except Exception as e:
            pass
        # 输入:[ query query_type citycode geo user_freq count_freq]
        # 输出:[ query query_type citycode cityname geo user_freq count_freq baidu]
        print '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' % (query,query_type,citycode,cityname,geo,user_freq,count_freq,baidu)
