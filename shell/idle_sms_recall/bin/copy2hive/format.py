#/usr/bin/env python
# coding:utf8

import sys
import os
import json

reload(sys)
sys.setdefaultencoding('utf-8')

if __name__ == '__main__':
    #从文件中提取相关信息，重新组合
    if len(sys.argv) < 6:
        print >> sys.stderr,'输入有误:python %s dir date send_file done_file error_file\n\t python %s . 20170724 ../../data/20170724/output_500w3day.txt ../../data/20170724/doneUser_500w3day.txt ../../data/20170724/errorUser_500w3day.txt'%(sys.argv[0],sys.argv[0])
        #print >> sys.stderr,'输入有误:python %s date send_file done_file\n\t python %s 20170724 ../../../20170724/output_500w3day_telecom.txt ../../../20170724/doneUser_500w3day_telecom.txt ../../../20170724/errorUser_500w3day_telecom.txt'%(sys.argv[0],sys.argv[0])
        #python format.py 20170624 data_20170624.txt 
        sys.exit(1)
    root_dir = sys.argv[1]
    date = sys.argv[2]
    send_file = sys.argv[3]
    done_file = sys.argv[4]
    error_file = sys.argv[5]
    if send_file.find(date) == -1:
        print >> sys.stderr,'输入参数不当,date(%s)与file(%s)不匹配!'%(date,send_file)
        sys.exit(1)
    #发送格式
    #========实发格式============
    send_format = []
    for line in file('%s/../../conf/all_format_send.ini'%(root_dir)):
        if line.startswith('#'):
            continue
        arr = [i.strip() for i in line.strip().split()]
        if len(arr) < 2:
            #print >> sys.stderr,'字段不足:%s'%(line.strip())
            continue
        #print arr
        cur_format_send = [i.strip() for i in arr[1].split(',')]
        send_format.append([arr[0],cur_format_send,len(cur_format_send)])
    #print json.dumps(send_format)    
    #找到对应的格式说明
    idx = 200
    send_len = len(send_format)
    for i in range(send_len):
        if i == send_len - 1:#最后一行
            idx = i
            continue
        if date >= send_format[i][0] and date < send_format[i+1][0]:
            idx = i
            break
    if idx == 200:
        print >> sys.stderr,'send: 未找到对应的格式:date=%s,file=%s'%(date,send_file)
        sys.exit(1)
    cur_format_send = send_format[idx] # ['20170701',['user_id','name'],2]
    print >> sys.stderr,'send: 对应的格式说明:%s'%(json.dumps(cur_format_send))
    #==========done文件===========
    #output_key = ['user_id','date_time','phone','operator','provider','name','group','gender','cwname','cwcontent']
    done_format = []
    for line in file('%s/../../conf/all_format_done.ini'%(root_dir)):
        if line.startswith('#'):
            continue
        arr = [i.strip() for i in line.strip().split()]
        if len(arr) < 2:
            #print >> sys.stderr,'字段不足:%s'%(line.strip())
            continue
        #print arr
        cur_format_done = [i.strip() for i in arr[1].split(',')]
        done_format.append([arr[0],cur_format_done,len(cur_format_done)])
    #找到对应的格式说明
    idx = 200
    done_len = len(done_format)
    for i in range(done_len):
        if i == done_len - 1:#最后一行
            idx = i
            continue
        if date >= done_format[i][0] and date < done_format[i+1][0]:
            idx = i
            break
    if idx == 200:
        print >> sys.stderr,'done: 未找到对应的格式:date=%s,file=%s'%(date,done_file)
        sys.exit(1)
    cur_format_done = done_format[idx] # ['20170701',['user_id','name'],2]
    print >> sys.stderr,'done: 对应的格式说明:%s'%(json.dumps(cur_format_done))
    #读入done文件
    done_count = 0
    done_dict = {}
    if not os.path.isfile(done_file):
        print >> sys.stderr,'done: 文件(%s)不存在,退出'%(done_file)
        sys.exit(1)
    for line in file(done_file):
        arr = [i.strip() for i in line.strip().split('\t')]
        if len(arr) != cur_format_done[2]:
            print >> sys.stderr,'done: 输入数据字段数不符合格式说明:%s'%(json.dumps(arr))
            continue
        in_dict = dict(zip(cur_format_done[1],arr))
        #部分日期数据矫正:date+time->date_time
        if in_dict.get('send_time','-') == '-':
            in_dict['send_time'] = '%s %s'%(in_dict.get('date',date),in_dict['time'])
        done_dict[in_dict['user_id']] = in_dict 
    done_count = len(done_dict)
    print >> sys.stderr,'done文件(%s)加载完毕,共%s行'%(done_file,done_count)
    #读入error文件--格式同done文件
    error_count = 0
    error_dict = {}
    if os.path.isfile(error_file):
	    for line in file(error_file):
	        arr = [i.strip() for i in line.strip().split('\t')]
	        if len(arr) != cur_format_done[2]:
	            print >> sys.stderr,'error: 输入数据字段数不符合格式说明:%s'%(json.dumps(arr))
	            continue
	        in_dict = dict(zip(cur_format_done[1],arr))
	        #provider矫正
	        if in_dict.get('provider','-') in ('','-'):
	            in_dict['provider'] = '-'
	        #部分日期数据矫正:date+time->date_time
	        if in_dict.get('send_time','-') == '-':
	            in_dict['send_time'] = '%s %s'%(in_dict.get('date',date),in_dict['time'])
	        error_dict[in_dict['user_id']] = in_dict 
    error_count = len(error_dict)
    print >> sys.stderr,'error文件(%s)加载完毕,共%s行'%(error_file,error_count)

    #============开始合并两份数据===========
    #（1）待发送文件
    #output_key = ['user_id','phone','operator','name','gender','group','dt']
    #（2）实发格式,待校正,date+time=>date_time
    #output_key = ['user_id','date_time','phone','operator','provider','name','group','gender','cwname','cwcontent']
    #合并后的格式: [user_id name gender mobile_number operator group_id send_time provider status copywrite_name sms_parameters copywrite_content]
    output_key = ['user_id','name','gender','mobile_number','operator','group_id','send_time','provider','status','copywrite_name','sms_parameters','copywrite_content']
    send_count = 0
    if not os.path.isfile(send_file):
        print >> sys.stderr,'send: 文件(%s)不存在,退出'%(send_file)
        sys.exit(1)
    for line in file(send_file):
        send_count += 1
        arr = [i.strip() for i in line.strip().split('\t')]
        if len(arr) != cur_format_send[2]:
            print >> sys.stderr,'merge: 输入数据字段数不符合格式说明:%s'%(json.dumps(arr))
            continue
        in_dict = dict(zip(cur_format_send[1],arr))
        other_dict = {}
        #for k,v in enumerate(in_dict):
        for k,v in in_dict.items():
            if k in output_key:
                continue
            other_dict.update({k:v})
        output_list = []
        done_info = done_dict.get(in_dict['user_id'],{})
        error_info = error_dict.get(in_dict['user_id'],{})
        status = 'send'
        #print >> sys.stderr,'group_id=[%s]'%(in_dict['group_id'])
        if done_info: #发送完成
            #print >> sys.stderr,'已发送done'
            status = 'done'
        elif error_info: #发送失败
            #print >> sys.stderr,'失败error'
            status = 'error'
        else:
            #print >> sys.stderr,'未发送send'
            status = 'send' #未发送
            if in_dict['group_id'].startswith('0'):
                status = 'control' #对照组
        #输出
        for k in output_key:
            v = in_dict.get(k,'-')
            if k in in_dict:
                pass
            elif k == 'sms_parameters':
                v = json.dumps(other_dict)
            elif k in done_info:#从done补充的信息(provider,send_time,copywrite_content)
                v = done_info[k]
                #print >> sys.stderr,'doneInfo,%s=%s'%(k,v)
            elif k == 'status':
                #记录发送状态
                v = status
            elif k == 'send_time' and v == '-':
                v = '%s 00:00:00'%(other_dict.get('date','%s-%s-%s'%(date[0:4],date[4:6],date[6:8])))
            else:
                if status != 'done':
                    v = '-'
                else:
                    print >> sys.stderr,'merge: send和done都不存在的key(%s,%s)'%(k,in_dict['user_id'])
            output_list.append(v)
        #output_list = [in_dict.get(i,'-') for i in output_key]
        #if output_list[-1] == '-':
        #    output_list[-1] = date
        #output_list.append(json.dumps(other_dict))
        print '\t'.join(output_list)
    print >> sys.stderr,'[完毕]日期: %s\tdone文件: %s 行\tsend文件: %s 行\terror文件: %s 行\t(done=%s,send=%s,error=%s)'%(date,done_count,send_count,error_count,done_file,send_file,error_file)


# */* vim: set expandtab ts=4 sw=4 sts=4 tw=400: */
