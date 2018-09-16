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
import datetime

reload(sys)
sys.setdefaultencoding('utf-8')

def loadUser(user_file):
    #读取推送文件
    input_format_list = info["input_str"].split(',')
    input_format_len = len(input_format_list)
    output_format_list = info["output_str"].split(',')
    phone_dict = {}
    user_list = []
    user_set = set()
    bad_data_count = 0 #数据质量问题
    same_count = 0 #重复用户数
    black_count = 0#命中黑名单(投诉)用户数
    quit_count = 0 # 命中退订用户数
    user_count = 0
    all_count = 0
    net_count = 0
    yesterday_count = 0 #昨日重复用户数
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
            bad_data_count += 1
            continue
        user_dict = dict(zip(input_format_list,arr))
        phone = user_dict[info["map"]["phone"]]
        #[user_id,phone,name,gender,group,type,other]
        #过滤：字段格式不对,id格式不对,手机号非11位
        if not pattern_cellphone.match(phone):
            illegal_phone_count += 1
            bad_data_count += 1
            continue
        flag_pass = 0
        #字段取值过滤
        for e in input_format_list:
            t = info['input_check'].get(e,'-')
            if t == '-':
                continue
            elif type(t) == type(dict({})):
                #t={'value':'number','max':10000,'action':'cut'} #pass
                if t['value'] == 'number':
                    if not pattern_number.match(user_dict[e]) or ( len(user_dict[e]) > 1 and user_dict[e].startswith('0')):
                        print >> sys.stderr,'字段取值不当!(key=%s,value=%s)忽略'%(e,user_dict[e])
                        bad_data_count += 1
                        #break;continue
                        flag_pass = 1;break
                    if t.get('max',0) != 0:
                        if int(user_dict[e]) > int(t['max']):
                            action = t.get('action','-')
                            if action == 'cut':
                                print >> sys.stderr,'字段取值较大,截断(%s>%s)'%(user_dict[e],t['max'])
                                user_dict[e] = str(t['max'])
                            elif action == 'pass':
                                print >> sys.stderr,'字段%s取值异常（过大,%s>1000000）,过滤'%(e,user_dict[e])
                                bad_data_count += 1
                                flag_pass = 1;break
                    else:#按照默认上限过滤
                        """
                        if int(user_dict[e]) > 1000000:
                            print >> sys.stderr,'字段%s取值异常（过大,%s>1000000）,过滤'%(e,user_dict[e])
                            bad_data_count += 1
                            flag_pass = 1;break
                        """
            elif type(t) == type([]):
                if not user_dict[e] in t:
                    print >> sys.stderr,'字段取值不当!不在指定列表中(key=%s,value=%s,list=%s)忽略'%(e,user_dict[e],json.dumps(t))
                    bad_data_count += 1
                    flag_pass = 1;break
            else:
                print >> sys.stderr,'字段取值不在可控范围内,[k=%s,v=%s]'%(e,t) #[k=mobile_number,v=number]
                bad_data_count += 1
                pass
        if flag_pass:
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
            black_count += 1
            continue
        #[2017-6-30]过滤退订用户
        if phone in quit_dict:
            quit_count += 1
            continue
        #去重
        if user_dict["user_id"] in user_set:
            same_count += 1
            continue
        else:
            user_set.add(user_dict["user_id"])
        #过滤昨日重复用户[2017-07-11] 7.7改成真实消息数+like数后存在数据损坏，导致id重复
        if user_dict["user_id"] in yesterday_dict:
            yesterday_count += 1
            continue
        #用户数限制
        user_count += 1
        if user_count > max_count:
            #print >> sys.stderr,'用户数超限：%s > [%s] '%(user_count,max_count)
            continue
        #"map":{"phone":"mobile_number","name":"-","gender":"gender","group":1,"newNum":"rand"}
        #统计手机运营商信息
        phoneType = phoneDetection(phone)
        if phoneType == 'other': # [2017-07-09]过滤非法号码(防止sms service挂掉)
            continue
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
                try:
                    rand_range = info["rand_%s"%(k)][user_dict["gender"]]
                except Exception,err:
                    print >> sys.stderr,'数据异常(k=%s,v=%s)，忽略'%(k,user_dict["gender"])
                    break
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
            elif value == 'multi':
                #[2017-07-08]组合取值: {"default":1,"key_list":["new_msg","new_like"]}
                multi_dict = info['multi_%s'%(k)]
                new_value = multi_dict['default']
                #从多个字段按优先级赋值
                key_list_len = len(multi_dict['key_dict'])
                for k,v in multi_dict['key_dict'].items():
                    tmp_value = user_dict.get(k,'-')
                    #if pattern_number.match(tmp_value) and int(tmp_value) > 0:
                    if pattern_number.match(tmp_value) and int(tmp_value) > 3: #[2017-7-21]最低值2,解决文案他们/她们问题---临时,请及时撤销
                        new_value = tmp_value
                        cw_type = v
                        break
                #print cw_type,user_dict['msg_num'],user_dict['like_num']
                cur_list.append(new_value)
            elif value == '-':
                #未定义字段,去输入格式中查找同名key
                if info["input_str"].find(k) != -1:
                    value = user_dict.get(k,'-')
                elif k == 'net':
                    value = phoneType
                else:
                    pass
                    #print >> sys.stderr,'key=%s未找到'%(k)
                cur_list.append(value)
                #print >> sys.stderr,'未定义字段:%s->%s'%(k,value)
            else: #其他,map中设置了默认值
                if k == "cwType":
                    value = cw_type
                cur_list.append(value)
        #用户分桶
        if info.get('partition',{}):
            #[2017-07-12]格式升级,支持小流量,{"key":"user_id","num":20,"control":[0,1],"experiment":{1:{"max":100000,"ratio":0.1,"cwType":"exp_msg"}}}
            partition_id = int(user_dict[info['partition']['key']]) % info['partition']['num']
            if partition_id in info['partition']['control']:
                #命中基准组,发送kafka
                group_id = 0
                pass
            else:
                group_id = partition_id
            #对照组
            idx = output_format_list.index("group")
            cur_list[idx] = str(group_id)
            #[2017-7-19]按性别、年龄分组
            age_dict = info['partition'].get('other_age',{})
            group_range = age_dict.get('range',{})
            if age_dict and group_id in group_range:
                age = user_dict.get('age',0)
                gender = user_dict.get('gender','-')
                if age > 0 and gender in ('male','female'):
                    age = int(age)
                    find_flag = 0
                    for age_range in age_dict[gender]:
                        if age >= age_range[0] and age <= age_range[1]:
                            find_flag = 1
                            break
                    if find_flag:
                        #cur_list[idx] = '%s_%s_%s_%s'%(cur_list[idx],gender[0],age_range[0],age_range[1])
                        idx1 = output_format_list.index("cwType")
                        cur_list[idx1] = '%s_%s_%s_%s'%('age',gender[0],age_range[0],age_range[1])
                        #print >>sys.stderr,'%s命中年龄区间:[%s,%s],%s'%(age,gender,age_dict[gender],cur_list[idx1])
                    else:
                        #print >>sys.stderr,'%s未命中年龄区间:[%s,%s]'%(age,gender,age_dict[gender])
                        pass
                else:
                    print >> sys.stderr,'age(%s)或gender(%s)非法'%(age,gender)
            else:
                #print >> sys.stderr,'groupid(%s)不在年龄分组范围内'%(group_id)
                pass
            #实验组
            if info['partition'].get('experiment',{}):
                if str(group_id) in info['partition']['experiment']:
                    #命中实验组
                    experiment_dict = info['partition']['experiment'][str(group_id)]
                    #限制总数,设置cwType取值
                    idx = output_format_list.index("cwType")
                    #real_* -> exp_*
                    cur_list[idx] = cur_list[idx].replace('real','exp')
                    #default -> exp_like
                    cur_list[idx] = cur_list[idx].replace('default','exp_like')
                pass
        user_list.append(cur_list)
    print '%s[数据样例]%s'%('-'*10,'-'*10)
    send_count = len(user_list)
    if send_count == 0:
        print '最终数据为空...'
        sys.exit(0)
    print '%s'%('\t'.join(user_list[0]))
    print '='*50
    print '一共从%s导入有效用户%s个(%.3f%%),源文件中共有%s个候选用户,共过滤%s个用户[%.3f%%，电信用户%s个(%.3f%%),非11位号码%s个(%.3f%%)]'%(user_file,send_count,send_count*100./all_count,all_count,net_count+illegal_phone_count,(net_count+illegal_phone_count)*100./all_count,net_count,net_count*100./all_count,illegal_phone_count,100*illegal_phone_count/float(all_count))
    print '过滤问题数据%s条(%.3f%%)'%(bad_data_count,bad_data_count*100./all_count)
    print '重复用户数:今天候选集内部重复%s个,与昨天候选集相比重复%s个'%(same_count,yesterday_count)
    print '命中黑名单(投诉)用户数:%s'%(black_count)
    print '命中退订(只要回复过短信都算)用户数:%s'%(quit_count)
    if yesterday_count > 10000:
        print >> sys.stderr,'候选集重复用户数过多(%s>100),退出...请马上追查重复原因!'%(yesterday_count)
        #sys.exit(1) #[2017-7-14]临时注释
    print '='*50
    print json.dumps(phone_dict)
    net_dict = {}
    real_count = 0
    group_idx = output_format_list.index('group')
    net_idx = output_format_list.index('net')
    for item in user_list:
        cur_value = net_dict.get(item[net_idx],[0,0])
        cur_value[0] += 1
        if item[group_idx] != '0':
            cur_value[1] += 1
            real_count += 1
        net_dict[item[net_idx]] = cur_value
    #[2017-7-5]统计运营商比例
    print '用户的运营商分布:\n\t运营商\t总发量\t总发占比\t实发量\t实发占比'
    for k,v in net_dict.items():
        #防止分母为零,强制平滑
        send_count_tmp = send_count
        real_count_tmp = real_count
        if send_count == 0:
            send_count_tmp = 1
        if real_count == 0:
            real_count_tmp = 1
        print '\t%s\t%s\t%.3f%%\t%s\t%.3f%%'%(k,v[0],v[0]*100./send_count_tmp,v[1],v[1]*100./real_count_tmp)
    print '\t总量\t%s\t-\t%s\t-'%(send_count,real_count)
    #数值分布,check_key
    print '='*50
    print '开始统计取值分布:[%s]'%(info.get('check_key',''))
    check_list = [i.strip() for i in info.get('check_key','').split(',')]
    for k in check_list:
        print '[%s]取值分布:'%(k)
        if not k in output_format_list :
            print '[%s]不存在于[%s],跳过'%(k,info["input_str"])
            continue
        idx = output_format_list.index(k)
        value_dict = {}
        for item in user_list:
            value_dict[item[idx]] = value_dict.get(item[idx],0) + 1
        #value_list = sorted(value_dict)
        #优先按照数字排序
        value_list = sorted([ int(v) if pattern_number.match(v) else v for v in value_dict.keys()])
        cur_cnt = 0
        for item in value_list:
            item = str(item)
            cur_cnt += value_dict[item]
            #print '\t%s\t%s\t%.3f%%'%(item,value_dict[item],value_dict[item]*100./send_count)
            print '\t%s\t%s\t%.3f%%\t%s\t%.3f%%'%(item,value_dict[item],value_dict[item]*100./send_count,cur_cnt,cur_cnt*100./send_count)
        print '-'*50
    print '='*50
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
     * 电信号段: 133,149,153,170,173,177,180,181,189   [2017-07-10]非法号码导致sms service服务挂掉[17109186595]
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
    curDir = '.'
    dataFile = 'input.txt'
    sendFile = 'output.txt'
    teleFile = 'telecom.txt'
    conf_file = 'data_conf.json'
    if len(sys.argv) == 1:
        pass
    elif len(sys.argv) in ( 5,6 ):
        curDir = sys.argv[1]
        dataFile = sys.argv[2]
        sendFile = sys.argv[3]
        teleFile = sys.argv[4]
        if len(sys.argv)== 6:
            conf_file = sys.argv[5]
    else:
        print >> sys.stderr,'输入参数格式不对！请参考:python format.py [curDir dataFile sendFile]\n\tpython format.py . input_20170712.txt output.txt telecom.txt '
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
    #info = json.load(open("%s/data_conf_new.json"%(curDir)))
    if len(sys.argv) >= 6:
        info = json.load(open("%s"%(conf_file)))
    else:
        info = json.load(open("%s/%s"%(curDir,conf_file)))
    #黑名单-投诉用户
    black_dict = {}
    black_file = '%s/%s'%(curDir,info["black_file"])
    for line in file(black_file):
        arr = [i.strip() for i in line.strip().split('\t')]
        if len(arr) < 1:
            continue
        black_dict[arr[0]] = 1
    #[2017-6-30]退订用户
    quit_dict = {}
    quit_file = '%s/%s'%(curDir,info["quit_file"])
    for line in file(quit_file):
        arr = [i.strip() for i in line.strip().split('\t')]
        if len(arr) < 1:
            continue
        quit_dict[arr[0]] = 1
    today = datetime.date.today().strftime('%Y%m%d')
    yesterday = (datetime.date.today()-datetime.timedelta(days=1)).strftime('%Y%m%d')
    yesterdayFile = dataFile.replace(today,yesterday)
    #根据星期几选择适当的参数
    week_dict = {1:'一',2:'二',3:'三',4:'四',5:'五',6:'六',0:'日'}
    week_number=int(time.strftime("%w"))
    #tm = time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time()))
    dt = time.strftime('%Y-%m-%d',time.localtime(time.time()))
    #anyday=datetime.datetime(2012,04,23).strftime("%w")
    if week_number in (1,2,3,4):
        max_count = info['max_workday']
    elif week_number == 5:
        max_count = info['max_friday']
    else:
        max_count = info['max_weekend']
    print '星期%s,最大用户数:%s,实际发送数目:%s'%(week_dict[week_number],max_count,max_count*0.95)
    #计算与昨天重复数
    yesterday_dict = {}
    if dataFile != yesterdayFile and os.path.isfile(yesterdayFile):
        for line in file(yesterdayFile):
            arr = [i.strip() for i in line.strip().split('\t')]
            if len(arr) < 1:
                continue
            yesterday_dict[arr[0]] = 1
        print '昨日待发送文件共%s行(今天文件:%s,昨天文件:%s)'%(len(yesterday_dict),dataFile,yesterdayFile)
    else:
        print '昨日待发送文件不存在,跳过..%s'%(yesterdayFile)
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
        i[6] = dt
        #i.insert(6,dt)
        #value = ','.join(i)
        value = '\t'.join(i)
        if info["net_pass"] and i[1][:7] in pass_net_dict:
            print >> f_telecom,value
        else:
            print >>f,value
        
        #print >>sys.stdout,value
    print >> sys.stderr,'导入完毕'


# */* vim: set expandtab ts=4 sw=4 sts=4 tw=400: */
