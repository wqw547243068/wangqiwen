#/usr/bin/env python
# coding:utf8
import sys
import os
import re
import json
import random
#import redis
import sys
import time

reload(sys)
sys.setdefaultencoding('utf-8')

def loadUser(user_file):
    #读取推送文件
    input_format_list = info["input_str"].split(',')
    input_format_len = len(input_format_list)
    output_format_list = info["output_str"].split(',')
    phone_dict = {}
    user_list = []
    user_count = 0
    all_count = 0
    net_count = 0
    illegal_phone_count = 0
    for line in file(user_file):
        #arr = [ i.strip() for i in line.strip().strip('"').split(',') ]
        arr = [ i.strip() for i in line.strip().strip('"').split('\t') ]
        all_count += 1
        len_arr = len(arr)
        if len_arr > input_format_len:
            #矫正超长字段(name中包含都好)
            end_idx = len_arr-input_format_len+2
            new = ','.join(arr[1:end_idx])
            for i in range(end_idx-2):
                del arr[1]
            #print >> sys.stderr,'矫正完毕:[%s]->[%s]'%(line.strip(),'|'.join(arr))
            print >> sys.stderr,'格式过长(%s>%s,多出%s个,name=%s),开始矫正'%(len_arr,input_format_len,len_arr-input_format_len,new)
            arr[1] = new
            len_arr = len(arr)
        if len_arr != input_format_len:
            print >> sys.stderr,'格式异常：%s != %s, [%s] '%(len_arr,input_format_len,line.strip())
            continue
        user_dict = dict(zip(input_format_list,arr))
        phone = user_dict[info["map"]["phone"]]
        #[user_id,phone,name,gender,group,type,other]
        #过滤：字段格式不对,id格式不对,手机号非11位
        if not pattern_cellphone.match(phone):
            illegal_phone_count += 1
            continue
        #过滤电信用户
        #if info["net_pass"] and phone[:7] in pass_net_dict:
        if phone[:7] in pass_net_dict:
            #print >> sys.stderr,'过滤电信用户：%s, [%s] '%(arr[1],line)
            net_count += 1
            #continue
        #过滤黑名单
        if phone in black_dict:
            print >> sys.stderr,'(%s)命中黑名单'%(phone)
            continue
        #用户数限制
        user_count += 1
        if user_count > max_count:
            #print >> sys.stderr,'用户数超限：%s > [%s] '%(user_count,max_count)
            continue
        #"map":{"phone":"mobile_number","name":"-","gender":"gender","group":1,"newNum":"rand"}
        #统计手机运营商信息
        phoneType = phoneDetection(phone)
        phone_dict[phoneType] = phone_dict.get(phoneType,0) + 1
        cur_list = []
        cw_type = 'default' # 文案类别
        #user_id,phone,name,gender,group,newNum,cwType,hourNum,distNum
        for k in output_format_list:
            value = info["map"].get(k,'-')
            #[2017-6-22]组内多文案功能,映射key名称特点,type:开头
            if isinstance(value, unicode) and  value.startswith("type:"):
                k1 = value.strip("type:")
                if user_dict.get("gender","-") == "male":
                    #男用户
                    value = 'rand'
                else:#女用户
	                try:
	                    v1 = int(user_dict[k1])
	                except Exception,err:
	                    print >> sys.stderr,'数据取值异常,非数字,%s,%s'%(user_dict[k1],err)
	                    sys.exit(1)
	                    #continue
	                if v1 <= 0: #数值不合法,矫正映射key 
	                    value = 'rand'
	                else:
	                    value = k1
	                    cw_type = 'real'
                #print >> sys.stderr,'value=%s,v1=%s,cw=%s'%(k1,v1,cw_type)
            if value in user_dict: #有明确的映射字段
                cur_list.append(user_dict[value])
            elif value == "rand": #随机数(制定范围)
                rand_range = info["rand_%s"%(k)][user_dict["gender"]]
                rand_v = '1'
                if type(rand_range[0]) == type(1):
                    rand_value = random.randint(rand_range[0],rand_range[1])
                    rand_v = '%s'%(rand_value)
                elif type(rand_range[0]) == type(1.0):
                    rand_value = random.uniform(rand_range[0],rand_range[1])
                    rand_v = '%.1f'%(rand_value)
                else:
                    print >> sys.stderr,'随机数类型异常！[%s]非int|float'%(rand_range[0])
                    sys.exit(1)
                cur_list.append(rand_v) 
            elif k == "group" and type(value) == type(1): # group随机生成
                group_id = random.randint(1,value)
                cur_list.append(str(group_id))
            elif value == '-':
                #未定义字段,去输入格式中查找同名key
                if info["input_str"].find(k) != -1:
                    value = user_dict.get(k,'-')
                cur_list.append(value)
                #print >> sys.stderr,'未定义字段:%s->%s'%(k,value)
            else: #其他,默认值
                if k == "cwType":
                    value = cw_type
                cur_list.append(value)
        #用户分桶
        if info.get('partition',[]):
            #['user_id',20,[0,1]]
            group_id = int(user_dict[info['partition'][0]]) % info['partition'][1]
            if group_id in info['partition'][2]:
                #命中基准组,发送kafka
                group_id = 0
                pass
            else:
                group_id = 1
            idx = output_format_list.index("group")
            cur_list[idx] = str(group_id)
        user_list.append(cur_list)
    print >> sys.stderr,'%s'%('\t'.join(user_list[0]))
    send_count = len(user_list)
    print >> sys.stderr,'='*50
    print >>sys.stderr,'一共从%s导入有效用户%s个(%.3f%%),源文件中共有%s个候选用户,共过滤%s个用户[%.3f%%，电信用户%s个(%.3f%%),非11位号码%s个(%.3f%%)]'%(user_file,send_count,send_count*100./all_count,all_count,net_count+illegal_phone_count,(net_count+illegal_phone_count)*100./all_count,net_count,net_count*100./all_count,illegal_phone_count,100*illegal_phone_count/float(all_count))
    print >> sys.stderr,'='*50
    print json.dumps(phone_dict)
    print >> sys.stderr,'用户的运营商分布:\n\t运营商\t频次\t占比'
    for k,v in phone_dict.items():
        #print >> sys.stderr,'\t%s\t%s\t%.3f%%'%(k,v,v*100./all_count)
        print >> sys.stderr,'\t%s\t%s\t%.3f%%'%(k,v,v*100./send_count)
    #数值分布,check_key
    print >> sys.stderr,'='*50
    print >> sys.stderr,'开始统计取值分布:[%s]'%(info.get('check_key',''))
    check_list = [i.strip() for i in info.get('check_key','').split(',')]
    for k in check_list:
        print >> sys.stderr,'[%s]取值分布:'%(k)
        if not k in output_format_list :
            print >> sys.stderr,'[%s]不存在于[%s],跳过'%(k,info["input_str"])
            continue
        idx = output_format_list.index(k)
        value_dict = {}
        for item in user_list:
            value_dict[item[idx]] = value_dict.get(item[idx],0) + 1
        value_list = sorted(value_dict)
        for item in value_list:
            #print >> sys.stderr,'\t%s\t%s\t%.3f%%'%(item,value_dict[item],value_dict[item]*100./all_count)
            print >> sys.stderr,'\t%s\t%s\t%.3f%%'%(item,value_dict[item],value_dict[item]*100./send_count)
        print >> sys.stderr,'-'*50
    print >> sys.stderr,'='*50
    return user_list

def loadNet(net_file):
    #加载电信号码前缀
    net_dict = {}
    for line in file(net_file):
        arr = line.strip()
        if not pattern_number.match(arr):
            continue
        if arr in net_dict:
            net_dict[arr] += 1
        else:
            net_dict[arr] = 1
    print >> sys.stderr,'一共导入%s个电信前缀'%(len(net_dict))
    return net_dict

def phoneDetection(number):
    #判断手机号的运营商类型：移动、联通和电信
    '''
     * 手机号码: 13[0-9], 14[5,7], 15[0, 1, 2, 3, 5, 6, 7, 8, 9], 17[0, 1, 6, 7, 8], 18[0-9]
     * 移动号段: 134,135,136,137,138,139,147,150,151,152,157,158,159,170,178,182,183,184,187,188
     * 联通号段: 130,131,132,145,155,156,170,171,175,176,185,186
     * 电信号段: 133,149,153,170,173,177,180,181,189
     * 虚拟运营商: 电信1700、1701、1702;联通1704、1707-1719；移动1705
    '''
    result = 'other'
    if not pattern_phone.match(number):
        return result
    if number.startswith('170'):
        return 'virtual' # 虚拟运营商(三家都有)
    if pattern_mobile.match(number):
        result = 'mobile' if result == 'other' else result + ',mobile'
    if pattern_unicom.match(number):
        result = 'unicom' if result == 'other' else result + ',unicom'
    if pattern_telecom.match(number):
        result = 'telecom' if result == 'other' else result + ',telecom'
    return result

def valueAdjust(num):
    #边界值矫正
    if type(num) != type(1):
        try:
            num = int(num)
        except Exception,err:
            print >> sys.stderr,'数值类型转换失败！(%s -> int)'%(num)
    if num <= 0:
        num =  random.randint(1,10)
    return num

if __name__ == '__main__':
    #python format.py curDir dataFile sendFile
    if len(sys.argv) == 1:
        curDir = '.'
        dataFile = 'input.txt'
        sendFile = 'output.txt'
        teleFile = 'telecom.txt'
    elif len(sys.argv) == 5:
        curDir = sys.argv[1]
        dataFile = sys.argv[2]
        sendFile = sys.argv[3]
        teleFile = sys.argv[4]
    else:
        print >> sys.stderr,'输入参数格式不对！请参考:python format.py [curDir dataFile sendFile]'
        sys.exit(1)
    #参考地址：http://www.jianshu.com/p/e8477fdccbe9 
    #大陆手机号：13[0-9], 14[5,7], 15[0, 1, 2, 3, 5, 6, 7, 8, 9], 17[0, 1, 6, 7, 8], 18[0-9]
    pattern_phone = re.compile(r'^1(3[0-9]|4[57]|5[0-35-9]|7[0135678]|8[0-9])\d{8}$')
    #中国移动：China Mobile：134,135,136,137,138,139,147,150,151,152,157,158,159,170,178,182,183,184,187,188
    pattern_mobile = re.compile(r'^1(3[4-9]|4[7]|5[0-27-9]|7[08]|8[2-478])\d{8}$')
    #中国联通：China Unicom：130,131,132,145,155,156,170,171,175,176,185,186
    pattern_unicom = re.compile(r'^1(3[0-2]|4[5]|5[56]|7[0156]|8[56])\d{8}$')
    #中国电信：China Telecom：133,149,153,170,173,177,180,181,189
    pattern_telecom = re.compile(r'^1(3[3]|4[9]|53|7[037]|8[019])\d{8}$')
    #===============
    pattern_number = re.compile(r'^\d+$')
    pattern_cellphone = re.compile(r'^1\d{10}$')
    #读取配置信息
    info = json.load(open("%s/data_conf_tmp.json"%(curDir)))
    #info = json.load(open("%s/data_conf.json"%(curDir)))
    #黑名单
    black_dict = {}
    black_file = '%s/%s'%(curDir,info["black_file"])
    for line in file(black_file):
        arr = [i.strip() for i in line.strip().split('\t')]
        if len(arr) < 1:
            continue
        black_dict[arr[0]] = 1
    #根据星期几选择适当的参数
    today=int(time.strftime("%w"))
    #anyday=datetime.datetime(2012,04,23).strftime("%w")
    if today in (1,2,3,4):
        max_count = info['max_workday']
    elif today == 5:
        max_count = info['max_friday']
    else:
        max_count = info['max_weekend']
    print >> sys.stderr,'星期%s,最大用户数:%s'%(today,max_count)
    #读取电信号码字典
    net_file = '%s/%s'%(curDir,info["net_file"])
    pass_net_dict = loadNet(net_file)
    f_telecom = open(teleFile,'w')
    #user_list = loadUser(info["input_file"])
    user_list = loadUser(dataFile)
    #sys.exit(0)
    #f = open(info["output_file"],'w')
    f = open(sendFile,'w')
    print >>sys.stderr,'开始产出格式化后的数据'
    for i in user_list:
        #value = ','.join(i)
        value = '\t'.join(i)
        if info["net_pass"] and i[1][:7] in pass_net_dict:
            print >> f_telecom,value
        else:
            print >>f,value
        
        #print >>sys.stdout,value
    print >> sys.stderr,'导入完毕'


# */* vim: set expandtab ts=4 sw=4 sts=4 tw=400: */
