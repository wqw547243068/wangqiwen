#!/usr/bin/env python
# -*- coding:utf-8 _*_

#-----------------------------
# 2014-5-14: 绝处逢生,慎用rm -rf!，坚持用svn
# 恢复:svn up -r33 https://10.2.161.10/svn/cpr/trunck/dw/
# 新svn路径: svn co https://10.2.161.10/svn/plana/home/warren/session/bin
# ----------------------------
# 2014-6-4 修复bug,点击poi不再展现list中,占比27%(25w/93w)
# 2014-6-13 (1)修复bug:无结果时,点击位置为1,因为poi_ids_list=['-'],,poiid='-'时误打误撞匹配上
#           (2) mapper.py更名为reducer.py
# 2014-6-22 query_list更名为session_list
#-----------------------------
#  根据sp和aos日志建设query-click表,2014-5-28
#（1）日志源：sp（仅限TQUERY和RQBXY）和aos（仅限/ws/valueadded/deepinfo/search）
#（2）原则：
#  一条检索请求可能对应多次aos点击
#  一次aos点击最多只对应一次检索
#  session内aos重复点击去重
#（3）输入：聚合相同uid、sessionid的数据，按照uid、sessionid、source（降序，保证sp日志在前面）、stepid、time排序。如sort by uid,sessionid,source desc,cast(stepid as int),time
#（4）策略：key=uid、sessionid
#sp日志：
#      若key相同，缓存sp日志；
#      否则，输出当前缓存的sp数据
# aos日志：
#      若key相同，去sp检索字典中展现list寻找点击poi，并记录位置
#         字典按stepid、time升序排列
#         从后往前查找，若stepid无效，则查找整个字典，否则在0-s（aos的stepid）范围内查找
#     否则，输出当前缓存sp数据
#-----------------------------

import os
import sys
import re
sys.path.append('.')
import func
import json

def parse(out_list=[]):
    # 输出结果
    # [uid,sessionid,stepid,time,query,result,click,request,response,position,cellphone]
    arr_len = len(out_list)
    if len(out_list) < 6:
        return ''
    if 'poi_ids_list' in out_list[5]:
        del out_list[5]['poi_ids_list']
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


def main( input = sys.stdin , output = sys.stdout ):
    format_list = ['uid','sessionid','stepid','time','position','source','action','request','response','cellphone','other','dt']
    out_dict = {'uid':'-','sessionid':'-','stepid':'-','time':'-','position':'-','query':'-','result':'-','click':'-','cellphone':'-'}
    out_list = ['uid','sessionid','stepid','time','position','query','result','click','cellphone']
    pattern_uid = re.compile(r'^[\w-]+$',re.I)
    last_key = '-'
    session_list = []

    for line in input:
        # in: [uid sessionid stepid time position source action request response cellphone other]
        query_dict = {}
        result_dict = {}
        click_dict = {}

        arr = [ i.strip() for i in line.strip().split('\t') ]
        if len(arr) != len(format_list):
            #print >>sys.stderr,'line length error ! %s!=%s \nline=(%s)'%(len(arr),len(format_list),line)
            continue
        line_dict = dict(zip(format_list,arr))
        for i in ('position','request','response','cellphone','other'):
            line_dict[i] = json.loads(line_dict[i])
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
        # 获取query_type
        query_dict['query_type'] = line_dict['action']
        # 获取citycode
        #citycode = line_dict['position']['citycode'] if 'citycode' in line_dict['position'] else '-'
        if source == 'SP':
            # 提取信息: query(keywords,category),count,poi_ids
            # 获取检索query(keywords,category)
            for i in ('keywords','category'):# keywords,category可能都存在
                if i in line_dict['request']:
                    query_dict[i] = func.get_value(line_dict['request'],i)
            if len(query_dict) < 2:
                # keywords,category均不存在时,跳过这条记录
                continue
            # 获取检索结果列表
            for i in ('count','poi_ids'):
                result_dict[i] = func.get_value(line_dict['response'],i) if i in line_dict['response'] else '-'
            # 2014-6-13 修复bug:无结果时,点击位置为1,因为poi_ids_list=['-'],,poiid='-'时误打误撞匹配上
            if result_dict['poi_ids'] == '-':
                poi_ids_list = []
            else:
                poi_ids_list = result_dict['poi_ids'].split('&')
            result_dict['poi_ids_list'] = poi_ids_list
            # 冗余信息
            request_str = func.dict2str(line_dict['request'])
            response_str = func.dict2str(line_dict['response'])
            position_str = func.dict2str(line_dict['position'])
            cellphone_str = func.dict2str(line_dict['cellphone'])

        elif source == 'AOS':
            # 提取信息: poiid
            if not 'poiid' in line_dict['request']: # poiid不存在时,直接跳过
                continue
            poiid = func.get_value(line_dict['request'],'poiid')
            click_dict['poiid'] = poiid
            # 冗余信息,补充到request中
            click_dict['time'] = time
            click_dict['stepid'] = stepid

        else:# 异常类别,直接过滤
            continue
            pass
        uid_pass = 0
        len_sp = len(session_list)
        # 过滤异常用户 freq > 1w ,防止数据倾斜
        if len_sp > 10000:
            session_list = []
            uid_pass = 1 
        # 输出:[uid,sessionid,stepid,time,query,result,click,request,response,position,cellphone]
        # uid+sessionid 作为key
        cur_key = uid+'\t'+sessionid
        if cur_key == last_key:
            if line_dict['source'] == 'SP':
                if uid_pass:
                    continue
                # key相同,追加记录到query-list中
                session_list.append([uid,sessionid,stepid,time,query_dict,result_dict,{'num':0},request_str,response_str,position_str,cellphone_str])
            elif line_dict['source'] == 'AOS':
                # 根据stepid,time降序排序
                #session_list.sort(key=lambda x:(x[2],x[3]),reverse=True)
                # 拿poiid去query-list查找展现信息: stepid=-1,去整个list中查;stepid!=-1,去前几步查
                #for i,item in enumerate(session_list[::-1]): # 2014-6-4 修复bug,点击poi不再展现list中,占比27%(25w/93w)
                for j in xrange(len_sp): # session_list按照stepid倒序查找
                    i = - (j+1)
                    item = session_list[i]
                    if stepid != -1 and stepid <= item[2]:
                        # stepid有效时,需要限制查找范围
                        continue
                    tmp_poi_list = item[5]['poi_ids_list']
                    if poiid in tmp_poi_list:
                        pos = tmp_poi_list.index(poiid) + 1
                        # 多点击、重复点击情形处理 2014-6-18 
                        order = session_list[i][6]['num'] + 1
                        session_list[i][6]['num'] = order
                        # 记录点击信息(含多次点击)：[order stepid time poiid pos] &&分隔展现项,||分隔展现元素
                        if order <= 1:
                            # 首次点击
                            session_list[i][6]['click_list'] = '|'.join([str(order),str(stepid),time,poiid,str(pos)])
                        else:
                            # 非首次点击
                            session_list[i][6]['click_list'] += '&' + '|'.join([str(order),str(stepid),time,poiid,str(pos)])
                        #session_list[i][6]['poiid'] = poiid
                        #session_list[i][6]['pos'] = str(pos)
                        break # 匹配成功后,停止查找---一个点击匹配最多一次检索行为
        else: # key变化,清空当前query-list,初始化
            #session_list.sort(key=lambda x:(x[2],x[3]),reverse=True)
            for item in session_list:
                print parse(item)
                uid_pass = 0
            session_list = [] # 2014-6-23 bug修复,原来置空仅限source=sp
            if source == 'SP': 
                session_list.append([uid,sessionid,stepid,time,query_dict,result_dict,{'num':0},request_str,response_str,position_str,cellphone_str])
                last_key = cur_key
            elif source == 'AOS':
               # AOS有点击,但SP无记录 
               print >>sys.stderr,'only in AOS (%s)'%(cur_key)
               pass
            else:
                continue
                pass
    #print json.dumps(tmp_dict,ensure_ascii=False,encoding='utf-8',indent=4)
    #session_list.sort(key=lambda x:(x[2],x[3]),reverse=True)
    for item in session_list:
        print parse(item)

if __name__ == '__main__':
    main()
