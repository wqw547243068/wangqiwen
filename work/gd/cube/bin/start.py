#/***************************************************************************
# * 
# * Copyright (c) 2014 autonavi.com, Inc. All Rights Reserved
# * 
# **************************************************************************/
 
#/**
# * @file start.py
# * @author warren@autonavi.com
# * @date 2014-08-27 15:32
# * detect if data is ready
# * process data use codes defined in conf
# * output data to path in conf
# * multi thread , multi job commit
# * log is added
# **/

#import packages:
import ConfigParser
import string
import os
import sys
import threading
import time 
import datetime 
import logging
import urllib, re
import commands
import json
import re

sys.path.append('.')

from optparse import OptionParser

#define class:
#job spec conf
class JobSpecConf:
    def __init__(self): 
        self.job_name = None
        self.input_ready = []
        self.output_ready = None
        self.must_input = []
        self.code_path = None
        self.detect_start_time = 0
        self.detect_end_time = 0
        self.delay_before_start = 0
        # [2014-5-21]
        self.diff_min_size = 0

#load jon conf
def loadJobConf(conf_file,date):
    config = ConfigParser.ConfigParser()
    config.read(conf_file)
    global_conf.map_dict['${date}'] = date
    global_conf.map_dict['${date1}'] = date[0:4]+'/'+date[4:6]+'/'+date[6:8]
    global_conf.map_dict['${date2}'] = date[0:4]+'-'+date[4:6]+'-'+date[6:8]
    global_conf.map_dict['${output_path}'] = global_conf.output_path
    global_conf.map_dict['${database}'] = global_conf.database
    global_conf.map_dict['${date_pre}'] = getPreDate(date=date)
    # tranform job conf info
    job_conf_list = []
    try:
        for section in config.sections():
            # all job session name starts with 'job' in configre file
            if not section.startswith('job'):
                continue
            # new job conf object
            job_spec_conf = JobSpecConf()
            job_spec_conf.job_name = config.get(section,"job_name")
            # update job_name in map_dict
            global_conf.map_dict['${job_name}'] = job_spec_conf.job_name
            # get input path & ready 
            item_list = config.options(section)
            ready_list = [multiReplace(config.get(section,i),global_conf.map_dict) for i in item_list if i.startswith('input_ready_')]
    	    job_spec_conf.output_ready = multiReplace(config.get(section,"output_ready"),global_conf.map_dict)
            job_spec_conf.input_number = len(ready_list)
            job_spec_conf.input_ready = ready_list
            if 'must_input' in item_list:
                job_spec_conf.must_input = [multiReplace(config.get(section,'input_ready_%s'%(i)),global_conf.map_dict) for i in config.get(section,"must_input").split('&')]
                logger.info('[%s] must_input = %s'%(job_spec_conf.job_name,repr(job_spec_conf.must_input))) 
            # 2014-8-30
            if 'job_type' in item_list:
                # local mode
                job_spec_conf.job_type = config.get(section,"job_type")
            else:
                # hdfs mode
                job_spec_conf.job_type = 'hdfs'
            # get other info
    	    job_spec_conf.code_path = multiReplace(config.get(section,"code_path"),global_conf.map_dict)
    	    job_spec_conf.detect_start_time = config.get(section,"detect_start_time")
    	    job_spec_conf.detect_end_time = config.get(section,"detect_end_time")
    	    job_spec_conf.delay_before_start = config.getint(section,"delay_before_start")
            # [2014-5-21] diff_min_size
            if 'diff_min_size' in item_list:
    	        job_spec_conf.diff_min_size = config.getfloat(section,'diff_min_size')
            # append job spec info
            job_conf_list.append(job_spec_conf)
        logger.info("job conf info: %s" %(repr(job_conf_list)))
    except Exception,err:
        logger.error("error:(%s) when loading configure file(file:%s,section:%s)" %(err,conf_file,section))
    return job_conf_list

def multiReplace(str,dict):
    rx = re.compile('|'.join(map(re.escape,dict)))
    def one_xlat(match):
        return dict[match.group(0)]
    return rx.sub(one_xlat,str)
 

#init logger
def initlog(date,job_type):
    logger = logging.getLogger('%s.py' % job_type)
    hdlr = logging.FileHandler('../log/%s/%s_%s.txt' % (now,job_type,date),mode="wb")
    formatter = logging.Formatter('[%(levelname)s] [%(asctime)s]: %(message)s')
    hdlr.setFormatter(formatter)
    logger.addHandler(hdlr)
    logger.setLevel(logging.DEBUG)
    return logger

def send_mail(mail_alarm='on',title='mail title',content='mail content',receiver=None):
    """
        usage: send_email(title,content,receiver)
        shell: echo -e "hello" | mail -s "title" receivers
    """
    if mail_alarm != 'on':
        logger.info('alarm mail is off ...')
        return 0
    if receiver == None:
        logger.info('Mail receiver address (%s) is null !' %(receiver))
        exit(-1)
    code = os.system("echo -e \"%s\" | mail -s \"%s\" \"%s\"" %(content,title,receiver))
    if 0 == code:
        logger.info('Success to send mail (%s:%s) to %s' %(title,content,receiver))
        return 0
    else:   
        logger.error('Fail to send mail (%s:%s) to %s, error code (%s) ,program exit ...' %(title,content,receiver,code))
        exit(-1)

def send_msg(receiver,msg,name='session',ip='10.19.2.192',msg_alarm='on'):
    # send_alarm_msg "18600428712,18500191878" "baidu_monitor" "0.0.0.0"  "$smsinfo"
    if msg_alarm != 'on':
        logger.info('alarm mail is off ...')
        return 0
    if receiver == None:
        logger.info('Mail receiver address (%s) is null !' %(receiver))
        exit(-1)
    file = 'tool/send_msg.sh'
    cmd = "sh %s %s %s %s %s" %(file,receiver,name,ip,msg)
    logger.info('Send alarm msg(%s) to %s [%s]'%(msg,receiver,cmd))
    code = os.system(cmd)
    if 0 == code:
        logger.info('Success to send message (%s) to %s' %(msg,receiver))
        return 0
    else:   
        logger.error('Fail to send message (%s) to %s, error code (%s) ,program exit ...' %(msg,receiver,code))
        exit(-1)


    
#define class:
#global conf
class GlobalConf:
    def __init__(self):
        self.retry_interval = 0
        self.output_path = ''
        self.root_code_path = ''
        self.hadoop_client = ''
        self.hive_client = ''
        self.database = ''
        self.re_run_number = 0
        self.jobtracker = ''
        self.map_dict = {'${output_path}':'-','${date_pre}':'-','${date}':'-','${job_name}':'-','${database}':'-'}
        self.mail_receiver_in = None
        self.msg_receiver = None
        self.msg_alarm = None
        self.mail_alarm = None
        self.mail_receiver_out = None
        self.diff_on = 'on' # 2014-5-21
        self.source_list = [] # 2014-5-21
        self.path_pattern = re.compile(r"^(.*)\/(\d{4}\/?\d{2}\/?\d{2})\/?.*$",re.I)

#define functions:
#load global config
def globalConfLoad(config_file):
    #load conf
    config = ConfigParser.ConfigParser()
    config.read(config_file)
    #init conf
    global_conf = GlobalConf()
    global_conf.retry_interval = config.getint("global","retry_interval")
    global_conf.root_code_path = config.get("global","root_code_path")
    global_conf.output_path = config.get("global","output_path")
    global_conf.hadoop_client = config.get("global","hadoop_client")
    global_conf.database = config.get("global","database")
    global_conf.hive_client = config.get("global","hive_client")
    global_conf.re_run_number = config.getint("global","re_run_number")
    global_conf.mail_receiver_in = config.get("global","mail_receiver_in")
    global_conf.mail_receiver_out = config.get("global","mail_receiver_out")
    global_conf.mail_alarm = config.get("global","mail_alarm")
    global_conf.msg_alarm = config.get("global","msg_alarm")
    global_conf.msg_receiver = config.get("global","msg_receiver")
    global_conf.diff_on = config.get("global","diff_on") # 2014-5-21
    return global_conf

#test path exist 
def checkHadoopFile(path,date,global_conf):
    path_after_parse = multiReplace(path,global_conf.map_dict)
    cmd = '%s fs -test -e %s' % (global_conf.hadoop_client,path_after_parse)
    code, msg = commands.getstatusoutput(cmd)
    if code == 0:
        return True
    elif msg:
        logger.warning('hadoop file (%s) not found , error_id : %s' %(path_after_parse,msg))
        return False
    return False

def getPreDate(n = 1 , date = 'today'):
    '''
        get string of date before n days
        date format: 20130521,2014/05/21,2014-05-21
        2014-5-21: upgrade function
    '''
    #date_pre = (datetime.datetime.strptime(date,'%Y%m%d')+datetime.timedelta(days=1)).strftime('%Y%m%d')
    seg = ''
    if date == 'today':
        date_object = datetime.date.today()
    elif len(date) == 10:
        seg = date[4]
        date = date.replace(seg,'')
        date_object = datetime.datetime.strptime(date,'%Y%m%d')
    elif len(date) == 8:
        date_object = datetime.datetime.strptime(date,'%Y%m%d')
    else: # date format error !
        #logger.error('function(getPreDate) input arg date(%s) error !'%(date))
        sys.exit(-1)
    #logger.info("date=%s\tdate_object=%s" %(date,repr(date_object)))
    date_pre = (date_object + datetime.timedelta(days=-n)).strftime('%Y%m%d')
    if seg != '':
        date_pre = date_pre[0:4]+seg+date_pre[4:6]+seg+date_pre[6:8]
    return date_pre

def cleanData(job_spec_conf, date):
    # 2014-8-30
    if job_spec_conf.job_type == 'local':
        return True
    ready_path = job_spec_conf.output_ready
    if 0 == os.system('%s fs -test -e %s' %(global_conf.hadoop_client,ready_path)):
        os.system('%s fs -rm %s' %(global_conf.hadoop_client,ready_path))
        logger.info("[%s] clean data (%s)" %(job_spec_conf.job_name,ready_path))
def getFileSize(job_spec_conf,hadoop,path,date):
    # 2014-5-21 get size(GB) of hadoop file
    hadoop_cmd = "%s fs -ls %s | awk '{a+=$5}END{print a/(1024.**3)}'"%(hadoop,path)
    logger.info('[%s]: start to get size of hadoop file (%s)' %(job_spec_conf.job_name,path))
    code, msg = commands.getstatusoutput(hadoop_cmd)
    if code != 0:
        logger.error('[%s]: fail to get size of hadoop file (%s) , error_code = %s(%s)' %(job_spec_conf.job_name,path,code,msg))
        if global_conf.diff_on == 'on':
            title = '[cube][ERROR] [%s] : fail to get size of hadoop file (%s)  !'%(job_spec_conf.job_name)
            content = '[ERROR] [%s]: fail to get size of hadoop file (%s) , error_code = %s(%s)' %(job_spec_conf.job_name,path,code,msg)
            logger.error('mail_receiver_in=%s'%(global_conf.mail_receiver_in))
            send_mail(global_conf.mail_alarm,title,content,global_conf.mail_receiver_in)
        return '0'
    else:
        return msg
 
def dataDiff(job_spec_conf):
    # [2014-5-21] source monitor
    if global_conf.diff_on != 'on':
        logger.info('dataDiff: global_conf.diff_on(%s) off,continue ...'%(global_conf.diff_on))
        print 'dataDiff: global_conf.diff_on(%s) off,continue ...'%(global_conf.diff_on)
        return []
    try: # get diff_min_size
        diff_min_size = job_spec_conf.diff_min_size
    except:
        logger.error('dataDiff: fail to get job_spec_conf.diff_min_size (%s)'%(job_spec_conf.job_name))
        print 'dataDiff: fail to get job_spec_conf.diff_min_size (%s)'%(job_spec_conf.job_name)
        return []
    # 2014-6-6 diff_min_size=0 --> off
    if diff_min_size == 0:
        #logger.info('dataDiff: job_spec_conf.diff_min_size=0,pass ...'
        #print 'dataDiff: job_spec_conf.diff_min_size=0,pass ...'
        return []

    # get now time
    now_time = datetime.datetime.now()
    time = now_time.time().isoformat() # 20140522
    #time = '%2s:%2s:%2s'%(now_time.hour,now_time.minute,now_time.second)

    path_ready = job_spec_conf.input_ready
    logger.info('path_ready=%s'%(repr(path_ready)))
    tmp_list = []
    all_list = []
    all_list.append(['source_name','time','yesterday','today','percent','result','path'])
    for i in path_ready:
        path_list = global_conf.path_pattern.match(i)
        if not path_list:
            continue
        main_path,date = path_list.groups()
        cur_path = main_path + '/' + date
        logger.info('date=%s'%(date))
        pre_date = getPreDate(1,date)
        logger.info('pre_date=%s'%(pre_date))
        pre_path = main_path + '/' + pre_date
        # get size of cur_path
        cur_size = float(getFileSize(job_spec_conf,global_conf.hadoop_client,cur_path,date))
        # get size of pre_path
        pre_size = float(getFileSize(job_spec_conf,global_conf.hadoop_client,pre_path,pre_date))
        # caculate diff percentage
        if pre_size != 0:
            percent = (cur_size-pre_size)/pre_size
        else:
            percent = 1
        warning = 'YES'
        if abs(percent) >= float(job_spec_conf.diff_min_size):
            warning = 'NO'
        #                  source_name     time   yesterday     today        percent      result  path
        # 2014-8-16
        tmp_list = [job_spec_conf.job_name,time,'%.2f GB'%(pre_size),'%.2f GB'%(cur_size),'%.2f %%'%(percent*100),warning,cur_path]
        #tmp_list = [job_spec_conf.job_name,time,str(pre_size)+'GB',str(cur_size)+'GB',str(percent*100)+'%',warning,cur_path]
        all_list.append(tmp_list)
        logger.info('tmp_list=%s'%(repr(tmp_list)))
        global_conf.source_list.append(tmp_list)
    logger.info('source_list=%s'%(repr(global_conf.source_list)))
    return all_list

def startMultiThead(date, tasks, options):
    logger.info('============> Begin to run the whole job of day: %s <===============' % date)
    # reset hadoop file size info  2014-5-21
    global_conf.source_list = [['source_name','time','yesterday','today','percent','result','path']]
    all_job_list = []
    all_job_list = loadJobConf(options.config_file,date)
    all_job_dict = {}
    for job in all_job_list:
        all_job_dict[job.job_name] = job
    logger.info('all jobs in conf : %s' % json.dumps([i.job_name for i in all_job_list]))
    # select some jobs 
    if tasks:
        job_conf_list = []
        for jobname in tasks:
            if jobname in all_job_dict:
                job_conf_list.append(all_job_dict[jobname])
            else:
                logger.error('job name (%s) error ! please check with configure file(%s),all job names:%s'%(jobname,options.config_file,repr(all_job_dict.keys())))
                return False
    else:
        job_conf_list = all_job_list
    # check whether each job need to run or not 
    job_conf_list = [c for c in job_conf_list if checkTask(c, date, options)]
    logger.info('jobs need to run : %s' % repr([i.job_name for i in job_conf_list]))
    if len(job_conf_list) <= 0:
        logger.info('no job in list , exit ...')
        return False
    # clean old data
    for c in job_conf_list:
        cleanData(c, date)
    # start multithread 
    if options.parallel:
        # run all jobs at the same time
        threads = [threading.Thread(target = tryRunTask, args = (c, date, options)) for c in job_conf_list]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
    else:
        # run one by one
        for c in job_conf_list:
            tryRunTask(c, date, options)
    logger.info('-----------------------check source file size (%s)---------------' % date)
    logger.info(' [%s] hadoop file size check result :\n%s' % (date,'\n'.join(['\t'.join(i) for i in global_conf.source_list])))
    #logger.info(' [%s] hadoop file size check result :\n\t%s' % (date,json.dumps(global_conf.source_list,ensure_ascii=False,encoding='utf-8',indent=4)))
    logger.info('============> End of day: %s <===============' % date)
   
def runOneTask(job_spec_conf, date, options):
    start_time = datetime.datetime.strptime(getPreDate(n=0)+job_spec_conf.detect_start_time,'%Y%m%d%H:%M')
    end_time = datetime.datetime.strptime(getPreDate(n=0)+job_spec_conf.detect_end_time,'%Y%m%d%H:%M')
    # wait some time until start
    if job_spec_conf.delay_before_start > 0:
        logger.info('[%s] sleep %s mins before start to detect ...'%(job_spec_conf.job_name,job_spec_conf.delay_before_start))
        time.sleep(job_spec_conf.delay_before_start*60)
    # Initialize input path 
    input_ready_number = 0
    detect_input_dict = {}
    for k in job_spec_conf.input_ready:
        detect_input_dict[k] = 1
    input_ready_list = []
    # waiting
    while True:
        now_time = datetime.datetime.now()
        time_info = '[now %s,start %s,end %s]' %(str(now_time),str(start_time),str(end_time))
        #count ready input file
        tmp_key_list = detect_input_dict.keys()
        for tmp_input_ready in tmp_key_list:
            if checkHadoopFile(tmp_input_ready,date,global_conf):
                logger.info('[%s] detect input file (%s): ready ...' % (job_spec_conf.job_name,tmp_input_ready))
                input_ready_list.append(tmp_input_ready)
                del detect_input_dict[tmp_input_ready]
            else:
                logger.warning('[%s] detect input file (%s): not ready... %s' % (job_spec_conf.job_name,tmp_input_ready,time_info))
        input_ready_number = len(input_ready_list)
        logger.info('[%s] detect result : ready num => %d, must input num => %d, all input num => %d...' % (job_spec_conf.job_name,input_ready_number,len(job_spec_conf.must_input),job_spec_conf.input_number))
        # check whether match min input
        match = 0
        if input_ready_number > 0:
            match = 1
        for i in job_spec_conf.must_input:
            if i not in input_ready_list:
                match = 0
                break
        if options.run_force and match :
            logger.warning("[%s] run forcely... input data ready info : %s/%s " %(job_spec_conf.job_name,input_ready_number,job_spec_conf.input_number))
            break
        #too early 
        if now_time < start_time:
            logger.info('[%s] time too early , wait until start time ... %s' %(job_spec_conf.job_name,time_info))
            logger.info('[%s] sleep %d minutes (retry_interval)' % (job_spec_conf.job_name,global_conf.retry_interval))
            time.sleep(global_conf.retry_interval*60)
            continue
        #all ready
        if input_ready_number == job_spec_conf.input_number :
            logger.info('[%s] detect_start_time %s , detect_end_time %s , all inputs are ready ...' %(job_spec_conf.job_name,job_spec_conf.detect_start_time,job_spec_conf.detect_end_time))
            break
        # too late
        if options.enable_timeout and now_time >= end_time:
            if match:
                logger.warning('[%s] input ready before time over, ... input data ready info : %s/%s ' %(job_spec_conf.job_name,input_ready_number,job_spec_conf.input_number))
                break
            else:
                title = 'cube-%s: Data missed (%s)'%(job_spec_conf.job_name,job_spec_conf.input_ready)
                content = '[%s] time over , but input files (%s) not enough , exit now'%(job_spec_conf.job_name,job_spec_conf.input_ready)
                logger.warning('%s ... input data ready info : %s/%s ' %(title,input_ready_number,job_spec_conf.input_number))
                send_mail(global_conf.mail_alarm,title,content,global_conf.mail_receiver_in)
                send_msg(global_conf.msg_receiver,msg='%s:data_missed'%(job_spec_conf.job_name),msg_alarm=global_conf.msg_alarm)
                exit(-1)
        logger.info('[%s] sleep %d minutes (retry_interval)' % (job_spec_conf.job_name,global_conf.retry_interval))
        time.sleep(global_conf.retry_interval*60)
    # check hadoop file size -- 2014.5.21
    all_list = dataDiff(job_spec_conf)
    if len(all_list) > 1:  # global_conf.source_list
        logger.info('[%s] hadoop file size check : OK\n\t%s' % (job_spec_conf.job_name,json.dumps(all_list,ensure_ascii=False,encoding='utf-8')))
    else:
        logger.error('[%s] hadoop file size check : ERROR!\n\t%s' % (job_spec_conf.job_name,json.dumps(all_list,ensure_ascii=False,encoding='utf-8')))
    size_diff = 0
    for i in all_list:
        if i[-2] == 'NO':
            size_diff = 1
            break
    if size_diff:
        title = '[cube][%s][%s] source file size diff too much !'%(job_spec_conf.job_name,date)
        content = '[%s][%s] source file size check result:\n%s'%(job_spec_conf.job_name,date,'\n'.join(['\t'.join(i) for i in global_conf.source_list]))
        logger.warning('%s'%(content))
        send_mail(global_conf.mail_alarm,title,content,global_conf.mail_receiver_in)

    # run
    hadoop_job_cmd = 'sh %s%s %s %s %s %s %s %s %s %s&>../log/%s/%s_%s.txt' % (
                global_conf.root_code_path,
                job_spec_conf.code_path,
                global_conf.hadoop_client,
                global_conf.hive_client,
                '"%s"' % (';'.join(input_ready_list)),
                job_spec_conf.job_name,
                global_conf.root_code_path,
                date,
                "%s_%s_%s" % (options.pipeline, date, job_spec_conf.job_name),
                now,
                now,
                job_spec_conf.job_name,
                date)
    logger.info('[%s] hadoop job command: %s' % (job_spec_conf.job_name, hadoop_job_cmd))
    code, msg = commands.getstatusoutput(hadoop_job_cmd)
    if code != 0:
        logger.error('[%s]: job Failled when running, error_code = %s(%s)' %(job_spec_conf.job_name,code,msg))
        title = '[cube[ERROR] [%s] Job failed when running !'%(job_spec_conf.job_name)
        content = '[ERROR] [%s] Job failed when running , error_code = %s(%s)'%(job_spec_conf.job_name,code,msg)
        logger.error('mail_receiver_in=%s'%(global_conf.mail_receiver_in))
        send_mail(global_conf.mail_alarm,title,content,global_conf.mail_receiver_in)
        return False
    # result info : all input,ready input,miss input
    result_dict = {'ready_list':[],'ready_num':0,'miss_list':[],'miss_num':0}
    for i in job_spec_conf.input_ready:
        if i in input_ready_list:
            result_dict['ready_list'].append(i) 
        else:
            result_dict['miss_list'].append(i)  
    result_dict['ready_num'] = len(result_dict['ready_list'])
    result_dict['miss_num'] = len(result_dict['miss_list'])
    logger.info('[%s] result_dict : %s' %(job_spec_conf.job_name,repr(result_dict)))
    # 2014-8-30
    if job_spec_conf.job_type == 'local':
        logger.info('[%s] job finish.' % (job_spec_conf.job_name))
        return True
    # create ready file
    output_ready = job_spec_conf.output_ready
    hadoop_ready_cmd = 'echo %s | %s fs -put - %s' %(json.dumps(result_dict),global_conf.hadoop_client,output_ready)
    logger.info('create ready file : %s' %(hadoop_ready_cmd))
    code, msg = commands.getstatusoutput(hadoop_ready_cmd)
    if code != 0:
        logger.error('[%s] fail to create ready file (%s) , error_code = %s(%s)'%(job_spec_conf.job_name,output_ready,code,msg))
        title = '[cube][ERROR][%s] Failed to create ready file !'%(job_spec_conf.job_name)
        content = '[ERROR] [%s] Failed to create ready file (%s),error_code = %s(%s)'%(job_spec_conf.job_name,output_ready,code,msg)
        send_mail(global_conf.mail_alarm,title,content,global_conf.mail_receiver_in)
        return False
    if result_dict['miss_num'] > 0:
        miss_source_info = ','.join([i.strip().split('/')[-3] for i in result_dict['miss_list']])
        logger.info('[%s] job finished at the end without sources(%s)' %(job_spec_conf.job_name,miss_source_info))
        title = '[cube][WARNING][%s] Job finished at the end without sources(%s)' %(job_spec_conf.job_name,miss_source_info)
        content = '[WARNING][%s] Job finished at the end without sources(%s)\n\nmiss_info = %s\n\nready_info = %s' %(job_spec_conf.job_name,miss_source_info,repr(result_dict['miss_list']),repr(result_dict['ready_list']))
        send_mail(global_conf.mail_alarm,title,content,global_conf.mail_receiver_out)
    # 2014-10-20 warren cube register
    # http://10.17.128.82:8200/index.php/logdata/dataAPI/SearchCube/cube/log_sp
    #hostname='10.17.128.82:8200';
    hostname='logdata.amap.com';cubename=job_spec_conf.job_name
    cube_flush_cmd = 'curl --connect-timeout 10 -m 20 http://%s/index.php/logdata/dataAPI/SearchCube/cube/%s'%(hostname,cubename)
    code, msg = commands.getstatusoutput(cube_flush_cmd)
    logger.info('[%s] job finish.' % (job_spec_conf.job_name))
    return True

def checkTask(job_spec_conf, date, options):
    # check whether job needs to run or not
    output_ready = job_spec_conf.output_ready
    if options.rerun or options.run_force:
        return True
    #if options.fix_data and checkMissTask(job_spec_conf, date):
    #    return True
    if job_spec_conf.job_type != 'local' and checkHadoopFile(output_ready, date, global_conf):
        # 2014-8-30 job_type != 'local' ---> hdfs mode
        logger.info('check task %s : exist, %s' %(output_ready,job_spec_conf.job_name))
        return False
    else:
        logger.info('check task %s : not exist, %s' %(output_ready,job_spec_conf.job_name))
        return True

def tryRunTask(job_spec_conf, date, options):
    logger.info('try to run task %s of %s' % (job_spec_conf.job_name, date))
    for i in range(options.retry):
        if runOneTask(job_spec_conf, date, options):
            return
        if i == (options.retry - 1):
            break
        logger.error('Task %s on %s failed, try again ...' % (job_spec_conf.job_name, date))
        time.sleep(options.retry_sleep)
        cleanData(job_spec_conf, date, False)
    logger.error('Task %s on %s failed ...' % (job_spec_conf.job_name, date))
    
#main define here:
def main():
    global options
    global logger
    global global_conf

    usage = "usage: %start.py [options] [tasks]"
    parser = OptionParser(usage=usage)
    parser.add_option("-o", "--disable_timeout",
                      action = "store_false", dest = "enable_timeout", default = True,
                      help = "disable job timeout")
    parser.add_option("-d", "--date", dest = "date", default = getPreDate(), help = "last day for job")
    parser.add_option("-n", "--total_day", type = "int", dest = "total_day", default = 1, help = "total day for job")
    parser.add_option("-s", "--sequence_run", action = "store_false", dest = "parallel", default = True, help = "run task one by one")
    parser.add_option("-x", "--fix_data", action = "store_true", dest = "fix_data", default = False, help = "fix data")
    parser.add_option("-p", "--pipeline", dest = "pipeline", default = "start", help = "pipeline name")
    parser.add_option("-t", "--retry", type = "int", dest = "retry", default = 1, help = "job retry times")
    parser.add_option("-r", "--rerun", action = "store_true", dest = "rerun", default = False, help = "rerun tasks")
    parser.add_option("-w", "--retry_sleep", type = "int", dest = "retry_sleep", default = 300, help = "job retry sleep time, in seconds")
    parser.add_option("-f", "--run_force", action = "store_true", dest = "run_force", default = False, help = "run job no matter the job has run already or data are not all ready")
    parser.add_option("-c", "--config_file", dest = "config_file", default = "conf/job_conf.ini", help = "configure file path")

    (options, tasks) = parser.parse_args()
    logger = initlog(options.date, options.pipeline)
    global_conf = globalConfLoad(options.config_file)
    logger.info('=================================================')
    logger.info('options=%s tasks=%s' %(repr(options),repr(tasks)))
    #logger.info('options=%s tasks=%s' %(repr(options),repr(tasks)))
    # get previous n days list before date, then start it
    flag = 1 # before
    if options.total_day < 0:
        # after
        flag = -1
    for i in xrange(abs(options.total_day)):
        date_i = getPreDate(n=i*flag,date=options.date) 
        startMultiThead(date_i, tasks, options)
    logger.info('Finish. Time to quit soon ...')
#main start:
if __name__ == '__main__':
    # call build.sh to update local directory
    os.system('sh build.sh')
    now = getPreDate( n = 0 )
    main()


# */* vim: set expandtab ts=4 sw=4 sts=4 tw=400: */
