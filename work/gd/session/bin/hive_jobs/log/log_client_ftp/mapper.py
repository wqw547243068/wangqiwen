#!/usr/bin/env python
# -*- coding:utf-8 -*-

#----------------------------------------------
# 2014-5-14: 绝处逢生,慎用rm -rf!，坚持用svn
# 恢复:svn up -r33 https://10.2.161.10/svn/cpr/trunck/dw/
# 新svn路径: svn co https://10.2.161.10/svn/plana/home/warren/session/bin
#
# 2014-5-13: 更改客户端码表匹配方法（按照不同版本匹配不同码表）;字段重组时,挪动原值位置,不再复制;action恢复为page-button值,中文解释放到other中;引入通用函数文件func
#----------------------------------------------

import os
import sys
sys.path.append('.')
import re
import time
import json
import func

reload(sys)
sys.setdefaultencoding( "utf-8" )

def main( input = sys.stdin , output = sys.stdout ):
    # 非法diu
    # 加载码表
    #pb_dict = json.loads(open('../../page-button/json.txt','r').read())
    pb_dict = json.loads(open('page-button.json','r').read())
    pb_key_list = pb_dict.keys()
    # out ---> 【uid（用户标识,string） time（时间,string） position（地点,map） source（数据源,string） action（动作类别,string） request（请求信息,map） response（响应信息,map） other（其他信息,map）】
    format_str = 'id||diu||div||aid||source||service||page||button||action||time||session||x||y||para||protocol_version||diu2||diu3||dic||model||device||manufacture||stepid'
    format_list = format_str.split('||')
    cellphone_list = ['div','model','device','manufacture']
    out_dict = {'uid':'-','sessionid':'-','stepid':'-','time':'-','position':'-','source':'CLIENT','action':'-','request':'-','response':'-','cellphone':'-','other':'-'}
    out_list = ['uid','sessionid','stepid','time','position','source','action','request','response','cellphone','other']
    #para_seg = 'download_rate,ip,start_time,method,url,version,result,start_receive_time,data_size,end_time' # ip,start_receive_time不一定有
    pattern_uid = re.compile(r'^[\w-]+$',re.I)
    #print format_list
    for line in input:
        position_dict = {}
        request_dict = {}
        response_dict = {}
        cellphone_dict = {}
        other_dict = {}
        arr = [ i.strip() for i in line.strip().split('||') ]
        # 2014-5-23 add dt
        dt = arr[-1].split('\t')[-1]
        arr[-1] = arr[-1].split('\t')[0]

        if len(arr) != len(format_list):
            print >>sys.stderr,'line length error ! %s!=%s \n\t(%s)'%(len(arr),len(format_list),line)
            func.counter('Count','line length error',1)
            continue
        line_dict = dict(zip(format_list,arr))
        out_dict['uid'] = func.get_value(line_dict,'diu') if 'diu' in line_dict else '-'
        if not pattern_uid.match(out_dict['uid']):
            print >>sys.stderr,'diu(%s) illegal ! pass ...' %(out_dict['uid'])
            func.counter('Count','uid miss match',1)
            continue
        if 'page' not in line_dict or 'button' not in line_dict:
            func.counter('Count','page button miss',1)
            print >>sys.stderr,'miss page or button ! pass ...(%s)' %(line)
            continue
        page = func.get_value(line_dict,'page')
        button = func.get_value(line_dict,'button')
        out_dict['sessionid'] = func.get_value(line_dict,'session') if 'session' in line_dict else '-'
        if 'step' in line_dict:
            out_dict['stepid'] = func.get_value(line_dict,'step')
        elif 'stepid' in line_dict:
            out_dict['stepid'] = func.get_value(line_dict,'stepid')
        else:
            out_dict['stepid'] = '-'
        other_dict['diu2'] = func.get_value(line_dict,'diu2')
        other_dict['diu3'] = func.get_value(line_dict,'diu3')
        position_dict['x'] = func.get_value(line_dict,'x')
        position_dict['y'] = func.get_value(line_dict,'y')

        explain = '-' # 动作解释
        devi = '-'
        # 根据ver(div)区分系统,IOSH060100,ANDH060000 --[新]
        div = line_dict['div'].upper() # os类别
        if len(div) < 10:
            print >>sys.stderr,'div error ! div=(%s) pass'%(div)
            func.counter('Count','div error',1)
            continue
        ver = div[-5:]
        # div对应地图不同硬件版本:IOS(H,P),WIN(H,P),ANDH,BLBH
        if div.startswith('IOS'):
            os = 'ios'
        elif div.startswith('AND'):
            os = 'android'
        else:
            pass
        line_dict['os'] = os
        explain = '-'
        out_dict['action'] = 'page=%s|button=%s'%(page,button)
        other_dict['action_name'] = '-'
        try:
            # 不同app版本的时间戳解析方法不同. [2014-3-12]garnett反馈,客户端时间解析存在8h误差，经瑞娟确认，修改解析方法
            if ver < '60200':
                t_list = time.strftime('%Y-%m-%d %H:%M:%S',time.gmtime(int(line_dict['time'])+1293811200+8*3600)).split()
                # 2014-5-13 620以下的版本直接查620码表
                new_div = div[0:4] + '060200'
            else:
                t_list = time.strftime('%Y-%m-%d %H:%M:%S',time.gmtime(int(line_dict['time'])/1000+1293811200+8*3600)).split()
                # 2014-5-13 620以上的数据才查码表 (不同版本码表不同)
                if div in pb_key_list:
                    new_div = div
                else:
                    # 中间版本,往上一个二位版本聚合
                    new_div = div[:-2] + '00'
        except Exception:
            print >>sys.stderr,'time.strtime error ! (%s)'%(line_dict['time'])
            t_list = ['-','-']
            
        try:
            explain = pb_dict[new_div][page][button]['explain']
        except Exception,err:
            print >>sys.stderr,'码表查找失败!div=%s,page=%s,button=%s'%(div,page,button)
        if explain in ('网页日志 ','联网日志','网络事件->网络事件'):
            #           android:1000,0  2000,0   IOS:2000,0
            func.counter('Count','pass action',1)
            continue
        other_dict['action_name'] = explain
        out_dict['time'] = t_list[1]
        other_dict['date'] = t_list[0].replace('-','') # [2014-3-17] 2014-03-17 --> 20140317
        if line_dict['para'] != '':
            try:
                #para_dict = json.loads(arr[13])
                para_dict = json.loads(func.get_value(line_dict,'para'))
            except Exception,err:
                #print >>sys.stderr,'[error] json data:para=[%s]'%(arr[13])
                func.counter('Count','para miss',1)
                continue
        else:
            #print >>sys.stderr,'para empty!(%s)'%(line)
            para_dict = {}
            pass
        # 手机相关信息
        for i in cellphone_list:
            cellphone_dict[i] = func.get_value(line_dict,i)
        # 请求信息
        request_dict = line_dict
        out_dict['position'] = func.dict2str(position_dict)
        out_dict['request'] = func.dict2str(request_dict)
        out_dict['response'] = func.dict2str(para_dict)
        out_dict['cellphone'] = func.dict2str(cellphone_dict)
        out_dict['other'] = func.dict2str(other_dict)
        print >>output,'\t'.join([out_dict[i] for i in out_list])
    #print json.dumps(tmp_dict,ensure_ascii=False,encoding='utf-8',indent=4)

if __name__ == '__main__':
    main()
