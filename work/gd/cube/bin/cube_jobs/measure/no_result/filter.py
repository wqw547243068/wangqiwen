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
    # 严格黑名单：城市名称
    equal_file = 'conf/equalFilterWord.txt'
    # 模糊黑名单：特殊词汇，如“我的位置”
    contain_file = 'conf/containFilterWord.txt'
    print len(sys.argv)
    if len(sys.argv) == 2:
        #print >>sys.stderr,"[%s][error] 参数不足1个!(curl_dir)使用默认参数"%(sys.argv[0])
        equal_file = sys.argv[1] + "/"+equal_file
        contain_file = sys.argv[1] + "/"+contain_file
    equal_dict = load_equal_words(equal_file)
    # 模糊黑名单：特殊词汇，如“我的位置”
    contain_list = load_contain_words(contain_file)
    for line in sys.stdin:
        # 解析无结果初级数据
        # [ query query_type citycode geo user_freq count_freq]
        arr = line.strip().split('\t')
        if len(arr) != 10:
            continue
        # 空值规范化
        for i,v in enumerate(arr):
            if pattern_null.match(v):
                arr[i] = '-'
        query,citycode,div,query_type,query_src,old_pv,new_pv,jiucuo,no_res_num,no_res_geo = arr

        # 对一框搜和周边搜进行加工
        # 过滤词表——模糊黑名单
        pass_over = 0
        for i in contain_list:
            if query.find(i) != -1:
                pass_over = no_res_num
                break

        # 过滤词表——严格黑名单
        if pass_over == 0 and query in equal_dict:
            pass_over = no_res_num 
        
        # 输入:[  query,citycode,div,query_type,query_src,old_pv,new_pv,jiucuo,no_res_num,no_res_geo]
        # 输出:[ query,citycode,div,query_type,query_src,old_pv,new_pv,jiucuo,no_res_num,no_res_geo,pass_over ]
        print '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' % (query,citycode,div,query_type,query_src,old_pv,new_pv,jiucuo,no_res_num,no_res_geo,pass_over)
