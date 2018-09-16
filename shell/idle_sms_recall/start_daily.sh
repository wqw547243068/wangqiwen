#!/bin/bash
# -*- coding: utf-8 -*-
#[2017-6-30] 快速彻底杀死程序：ps aux | grep wangqiwen | awk '{print $2}'| xargs sudo kill -9 
#[2017-7-13] 快速彻底杀死程序：ps aux | grep -E "start|wangqiwen" | awk '{print $2}'| xargs sudo kill -9 
#===============================================================================
#            File:  start.sh
#           Usage:  nohup sh start.sh -m online -n 500w3day -s 19:00 -l 180 &
#           Usage:  nohup sh start.sh -m online -n 500w3day -s 19:00 -e 21:00 &
#     Description:  Entrance of SMS recall program
#    LastModified:  
#         Created:  5/31/2017 16:33 PM CST
#          AUTHOR:  wangqiwen@p1.com)
#         COMPANY:  Tantan Inc
#         VERSION:  1.0
#            NOTE:  
#------------------------------------参数说明----------------------------------
# -m 程序运行模式:debug(测试),online(线上),continue(断点续发,自动过滤已发送号码)
# -n 任务名(目前必须是500w3day)
# -s 开始发送时间(如果晚于当前时间，就开始等待),参数可省略(即立即执行)
# -e 发送结束时间,程序自动计算开始时间到结束时间的时差（min）,此时-l不管用(免得每次都得计算时长,风险高)
# -l 持续推送时间(min)
# -c crontab模式,启动和结束时间固定(默认非crontab模式,时间可控)
# -d 发送日期(可忽略)
# 注：电信流程默认从startTime开始，执行2h(diff_time_telecom); 重启时请务必杀死已有程序.ps axu | grep -E "wangqiwen|start"
#测试模式(从真实数据中随机抽取，替换成测试人员号码)
# sudo nohup sh start_daily.sh -m debug -n 500w3day -s 18:37 -e 21:00 &>info.txt &
#正常例行命令
# contab :  sudo nohup sh start_daily.sh -m online -n 500w3day -c &>info.txt &
# 临时模式: sudo nohup sh start_daily.sh -m online -n 500w3day -s 18:37 -e 21:00 &>info.txt &
#断点续跑命令
# sudo nohup sh start_daily.sh -m continue -n 500w3day -s 18:37 -e 21:00 &>info.txt &
# sudo nohup sh start_daily.sh -m continue -n 500w3day -s 18:37 -l 180 &>info.txt &
#===============================================================================
#set -x
tag="m:n:s:l:d:e:c"
while getopts $tag opt
do
  case $opt in
    m) mode=$OPTARG;;
    n) jobName=$OPTARG;;
    s) startTime=$OPTARG;;
    e) endTime=$OPTARG;;
    l) pushDuration=$OPTARG;;
    c) crontab="yes";;
    d) date=$OPTARG;;
    *) echo -e "Argument: $OPTIND -> $OPTARG";;
    ?) echo "Input error ! (tag=$tag)";;
  esac
done
[ -z $crontab ]&& crontab="no"
[ -z $jobName ]&& { echo "[ERROR] 任务名jobName为空!请设置";exit 1; }
w=`date +%w`
#[2017-7-17]运行时间定制:周一-周四 17：30-21：30，周五17：00-21：30，周六-周日：11：00-21：00
[ $crontab == "yes" ]&&{
	if [[ $w =~ ^[1-4]$ ]];then
	  startTime="17:30";endTime="21:00"
	elif [[ $w =~ ^[5]$ ]];then
	  startTime="16:30";endTime="21:00"
	elif [[ $w =~ ^[06]$ ]];then
	  startTime="11:00";endTime="21:00"
	else
	  echo "[ERROR] 星期数($w)有误,退出";exit 1
	fi
  echo "[INFO] Crontab模式,按照计划设置任务执行时间,startTime=$startTime,endTime=$endTime"
  }||{
    echo "[INFO] 临时模式,按照传入的参数执行"
  }
#传参验证,[2017-7-21]发现bug,设置的启动时间早于当前时间时,发送起止时间还是设置时间，导致发送并未按时结束
date_now=`date "+%H:%M:%S"`
[ -z $startTime -o $startTime \< $date_now ]&& { echo "启动时间为空,默认立即执行";start=`date +%s`;startTime=`date -d @${start} "+%H:%M:%S"`; }|| { echo "启动时间已设置,而且还有空闲(startTime=$startTime>now=$date_now)";start=`date -d "${startTime}" +%s`; }
#[ -z $startTime ]&& { echo "启动时间为空,默认立即执行";start=`date +%s`;startTime=`date -d @${start} "+%H:%M:%S"`; }|| { start=`date -d "${startTime}" +%s`; }
[ ! -z $endTime ]&&{
  end=`date -d "${endTime}" +%s`
  diff_time=$(((end-start)/60))
  pushDuration=$diff_time
  echo "计算时间间隔：从${startTime}到${endTime}间隔${diff_time}分钟,pushDuration=$pushDuration"
  #echo "计算时间间隔：从`date -d @${start} \"+%H:%M:%S\"`到`date -d @${end} \"+%H:%M:%S\"`间隔${diff_time}分钟,pushDuration=$pushDuration"
}||{
  [ -z $pushDuration ]&&{ echo "推送时间为空!(pushDuration=$pushDuration),请设置参数-l或-e";exit; }|| { 
    end=$((start+pushDuration*60))
    endTime=`date -d @${end} "+%H:%M:%S"`; 
  }
}
diff_time_telecom=120 #[2017-8-4]电信发送时间
#echo "[INFO] 今天星期$w,任务启动时间:$startTime,结束时间:$endTime,持续${diff_time}分钟"
[ -z $pushDuration ]&&{ echo "推送时间为空!(pushDuration=$pushDuration),请设置参数-l或-e";exit; }
echo "[$0] 今天星期$w(例行:$crontab)：运行模式mode=$mode,任务名jobName=$jobName,启动时间startTime=$startTime,结束时间endTime=$endTime,推送时长pushDuration=$pushDuration,date=$date"
#shift $(($OPTIND-1))
#exit 1
:<<note
if [ $# -lt 1 ];then
  log "Default value : yesterday ...";
  date0=`date -d "1 days ago" +%Y-%m-%d`
else
  if [[ $1 =~ ^[0-9-]+$ ]]&&[ ${#1} -eq 8 -o ${#1} -eq 10 ];then
    [ ${#1} -eq 10 ]&& date0=$1 || date0=${1:0:4}-${1:4:2}-${1:6:2}
  else  
    echo "Something wrong with date format!(20130128,2013-01-28)"
    exit -1
  fi
fi
note
# Update local files and import global variables,BinDir,ConfDir,DataDir,LogDir,BakDir,RootDir and Now
#echo -e "[$0] [NOTE] [`date "+%Y-%m-%d %H:%M:%S"`] Start to Update local files"
source ./build.sh

# Load configure info of PostgreSQL
#source ${ConfDir}/pg_conf.sh

#date=${date0//-/}
yesterday=`date -d "1 days ago" +%Y%m%d`
log_file="$LogDir/log_${jobName}.txt" 
[ -e $log_file ]&& mv $log_file ${log_file}_${date_now}

#Redirection
exec 3<>$log_file
exec 1>&3 2>&1

#echo -e "[$0] [NOTE] [`date "+%Y-%m-%d %H:%M:%S"`] Start to run main program"
#======================================
#jobName="500w3day"
#mode="online"
#mode="debug"
#startTime='19:00' # Start time of sending job
#pushDuration=90 # Total time of sending job
#--------------------------------------
jobDir="${RootDir}/jobs/${jobName}"
[ ! -d $jobDir ]&& { log "[ERROR] 任务主目录($jobDir)不存在,请核实! 退出 ...";exit 1; }
cmdData="${jobDir}/get_data.sql" #获取用户候选集合(180天以内)
cmdData180="${jobDir}/get_180.sql" #获取用户候选集合(180天以外)
cmdDataResend="${jobDir}/get_send_stat.sql" #统计resend比例数值
cmdDataSms="${jobDir}/get_stat_sms.sql" #SMS发送的相关指标(钟文鑫)
cmdDataMsg="${jobDir}/get_msg.sql" #获取用户消息数
cmdDone="${RootDir}/bin/create_done.sql" #发送记录表
dataConf="${jobDir}/data_conf.json" 
dataFile="${DataDir}/input_${jobName}.txt" # Raw data from pg
num=8 # 8个进程并行取数
dataFileNew="${DataDir}/input_${jobName}_new.txt" # 从pg下载的待发送用户
yesterdayFile=${dataFileNew//$Now/$yesterday} #昨天的候选集合文件，用于去重
dataFileMsg="${DataDir}/input_${jobName}_msg.txt" # 获取待发送用户的消息数
dataFileLike="${DataDir}/input_${jobName}_like.txt" # 获取待发送用户的喜欢数
dataFileProfile="${DataDir}/input_${jobName}_profile.txt" # 获取待发送用户的基本信息
dataFileAll="${DataDir}/input_${jobName}_msg_like.txt" # 获取待发送用户的喜欢数
dataFileRest="${DataDir}/input_${jobName}_Rest.txt" # 周一到周四缓存一半用户
dataFileRestAll="${DataDir%/*}/input_${jobName}_rest_all.txt" # 本周全部缓存池
dataFileRestDone="${DataDir%/*}/input_${jobName}_rest_done.txt" # 本周已发送数据
dataFileRestSend="${DataDir}/input_${jobName}_rest_send.txt" # 当天消耗的缓存数据
dataFileLastActive="${DataDir}/input_${jobName}_last_active.txt" # 最近5天活跃用户集合
dataFileStat="${DataDir}/stat_${jobName}.txt" # 当天发送数据统计信息
#dataFile="${jobDir}/input.txt" # Raw data from pg
sendFile="${DataDir}/output_${jobName}.txt" # 移动联通用户集合
sendFileTmp="${DataDir}/output_${jobName}_tmp.txt" # 移动联通用户集合
sendFileTelecom="${DataDir}/output_${jobName}_telecom.txt" # 电信用户集合
sendFileTelecomTmp="${DataDir}/output_${jobName}_telecom_tmp.txt" # 电信用户集合
#sendFile="${jobDir}/output.txt" # Users to send
pushConf="${jobDir}/push_conf.ini"
#sendFile="${DataDir}/sendUser.txt" # Users to send
doneFile="${DataDir}/doneUser_${jobName}.txt" # 发送成功用户集合
errorFile="${DataDir}/errorUser_${jobName}.txt" # 发送出错的用户集合
doneFileTelecom="${DataDir}/doneUser_${jobName}_telecom.txt" # 发送成功的电信用户集合
errorFileTelecom="${DataDir}/errorUser_${jobName}_telecom.txt" # 发送出错的电信用户集合
dataFile180Raw="${DataDir}/data_180_raw.txt"
dataFile180="${DataDir%/*}/data_180_filter.txt"
doneFile180="${DataDir%/*}/data_180_done.txt"
sampleFile180="${DataDir}/input_sample.txt"
#======================================
suffix=`date "+%H-%M-%S"`
sendFile1="${DataDir}/output_${jobName}_${suffix}.txt" # Users to send
#sendFile1="${jobDir}/output_${suffix}.txt" # Users to send
doneFile1="${DataDir}/doneUser_${jobName}_${suffix}.txt" # Users already sended
format="${jobDir}/format.py"
#format="${jobDir}/format_tmp.py"
reformat="${jobDir}/reformat.py"
#=============Hadoop/Hive==============
#上传文件至Hadoop 
hadoop='/home/wangqiwen/bin/CDH-5.10.0-1.cdh5.10.0.p0.41/bin/hadoop'
hive='/home/wangqiwen/bin/CDH-5.10.0-1.cdh5.10.0.p0.41/bin/hive'
local_path="data"
save_path="merge_data"
hadoop_path="/user/wangqiwen/sms_recall/data"
copy_dir="bin/copy2hive"
hive_cmd="$copy_dir/create_daily_hive.sql"
send_name="data_send.txt"
done_name="data_done.txt"
error_name="data_error.txt"
output_name="data_merge.txt"
#===================get data=================
if [ ! -d $jobDir ];then
  log "[ERROR] 任务主目录$jobDir 不存在!"
  exit 1
fi
if [ -f $dataFile ];then
  log "[INFO] 原始用户集合文件已存在($dataFile) "
else
  log "[INFO] 开始从PG下载原始用户集合 (psql -f $cmdData > $dataFile)"
	psql -f $cmdData -v output=$dataFile
  psql -c "\copy ( select * from wqw.sms_recall_${jobName} ) to '$dataFile'"
	[ $? -eq 0 ] && log "[INFO] 下载完毕"|| { log "[ERROR] 下载失败,退出...";send_msg "[ERROR]" "原始用户集合PG下载失败";exit 1; }
fi
#max_count=4200000
#Store halt of data
#a=( 6 0 )
#echo ${a[1]}
#week=`date +%w --date=2017-06-14`
#w=`date +%w --date=$1`
flagRest=0 #[2017-07-11]修复bug,周五-周日缓存消耗开关
[ $w -eq 5 -o $w -eq 6 -o $w -eq 0 ] && flagRest=1 #[2017-7-15]缓存池
[ -f $sendFile ]&&{ log "[INFO] 处理后的发送数据已存在,跳过($sendFile)"; }||{
#:<<note
	#cp $dataFile ${dataFileNew}
  #[2017-7-17]去掉昨天发送重复用户
  less $dataFile | awk -F'\t' -v ready=$yesterdayFile 'BEGIN{while(getline<ready>0)d1[$1]=1;}{if($1 in d1)next;print}'>$dataFileNew
  log "[INFO] 过滤昨天用户完毕,开始替换$dataFile"
  cp $dataFileNew $dataFile
  log "去除昨天重复用户:\nless $dataFile | awk -F'\t' -v ready=$yesterdayFile 'BEGIN{while(getline<ready>0)d1[$1]=1;}{if($1 in d1)next;if(count<=max)print;count+=1}'>$dataFileNew"
	if [ $w -eq 5 -o $w -eq 6 -o $w -eq 0 ];then
	  log "[NOTE] 周末高峰期($w,$Now),开始消费缓存数据(工作日周一到周四缓存)"
    #flagRest=1
	  if [ $w -eq 5 ];then
	    #每周五开始消耗缓存数据
	    #all_date=`date -d "1 days ago" +%Y%m%d`
	    for((i=1;i<5;i++));
	    do
	      date_str=`date -d "$i days ago" +%Y%m%d`
	      cur_file="${DataDir%/*}/$date_str/input_${jobName}_Rest.txt"
	      [ ! -f $cur_file ]&& continue
	      if [ $i -eq 1 ];then
	        cat $cur_file > $dataFileRestAll 
	      else
	        cat $cur_file >> $dataFileRestAll 
	      fi
	      all_date="$all_date,$date_str"
	    done
      log "[INFO] 开始合并历史缓存数据($all_date)"
	    #cat "${DataDir%/*}/{$all_date}/input_${jobName}_Rest.txt" > $dataFileRestAll 
	    >$dataFileRestDone #初始化已发送集合
	  fi
	  cache_num=`wc -l $dataFileRestAll | awk '{print $1}'`
	  [ $cache_num -lt 100 ]&&{ content="[ERROR] 缓存数据总量过小($cache_num,$dataFileRestAll)";log "$content"; send_mail "[ERROR] 缓存数据量过小" "$content";exit 1;  } || log "[INFO] 合并本周缓存数据 ($cache_num rows,input_${jobName}_Rest.txt -> $dataFileRestAll)"
	  let get_count=cache_num/3
	  #取前5天活跃用户
	  if [ ! -f $dataFileLastActive ];then
	    log "[INFO] 获取最近5天活跃用户(方便过滤缓存池用户):$dataFileLastActive"
	    psql <<SQL 
	      \copy ( select user_id from wqw.last5day_users ) to '$dataFileLastActive'
SQL
	    [ $? -eq 0 ] && log "[INFO] 成功获取最近5天活跃用户" || { log "[ERROR] 获取最近5天活跃用户时失败";send_mail "[ERROR] 最近活跃用户获取失败" "获取最近5天活跃用户时失败,程序退出,请及时处理";send_msg "[ERROR]" "最近活跃用户获取失败";exit 1; }
	  else
	    log "[INFO] 最近活跃用户数据已存在,跳过 ($dataFileLastActive)"
	  fi
	  log "[INFO] 从缓存池中过滤最近活跃用户"
	  #less $dataFileRestAll | awk -F'\t' -v max=$get_count -v ready=$dataFileRestDone 'BEGIN{while(getline<ready>0)d[$1]=1}{if($1 in d)next;if(count<=max)print;count+=1}'>$dataFileRestSend
	  less $dataFileRestAll | awk -F'\t' -v max=$get_count -v ready1=$dataFileRestDone -v ready2=$dataFileLastActive 'BEGIN{while(getline<ready1>0)d1[$1]=1;while(getline<ready2>0)d2[$1]=1}{if($1 in d1 || $1 in d2)next;if(count<=max)print;count+=1}'>$dataFileRestSend
	  [ $? -eq 0 ]&&{ log "[INFO] 成功过滤最近活跃用户"; }||{ log "[ERROR] 过滤活跃用户时失败,退出" ;exit 1; }
	  cat $dataFileRestSend >> $dataFileNew
	  #Get the amount of users
	  if [ $w -eq 5 ];then
	    max_count=`less $dataConf | awk -F':' '{if($1!~/max_friday/)next;raw=$2;gsub(/,/,"",raw);print raw}'`
	  else
	    max_count=`less $dataConf | awk -F':' '{if($1!~/max_weekend/)next;raw=$2;gsub(/,/,"",raw);print raw}'`
	  fi
    >$dataFileStat #[20170713]置空,防止一天内多次运行，信息追加
	  [[ ! $max_count =~ ^[0-9]+$ ]] && { log "[ERROR] 配置文件中的发送量($max_count)不是数字!  $dataConf !";send_msg "[ERROR]" "配置文件发送量非数字";exit 1; } || { log "[INFO] 今日星期${w},总发送量(含5%对照组): $max_count" | tee -a $dataFileStat; }
	else
	  log "[NOTE] 工作日策略 ($w,$Now), 正常运行,每天缓存一半用户"
	  #less $dataFile | awk 'BEGIN{srand();}{if(int(2*rand())==1)print}' > ${dataFileNew}
	  less $dataFile | awk -F'\t' -v a=$dataFileRest -v b=$dataFileNew 'BEGIN{srand();}{if(int(2*rand())==1){print >a}else{print >b}}'
	  [ $? -eq 0 ]&&{ log "[INFO] 成功缓存一半用户($dataFile)"; }||{ log "[ERROR] 缓存一半用户失败($dataFile)";send_msg "[ERROR]" "缓存一半用户失败";exit 1; }
	  #Get the amount of users
	  max_count=`less $dataConf | awk -F':' '{if($1!~/max_workday/)next;raw=$2;gsub(/,/,"",raw);print raw}'`
	  [[ ! $max_count =~ ^[0-9]+$ ]] && { log "[ERROR] 非数字($max_count) from $dataConf !";exit 1; } || { log "[INFO] 今日待发送总量: $max_count"; }
	fi
	cnt1=`wc -l $dataFileNew | awk '{print $1}'`
	let diff_count=max_count-cnt1
	if [ $diff_count -gt 0 ];then
	  #180 sample
	  #day_diff=$(( ($(date +%s) - $(date +%s -d '2017-06-08')) / 86400 ))
	  #less $dataFile180 | awk -v max=$day_diff '{if(NR>1000000*(max-1)&&NR<=1000000*max)print}'> $sampleFile180
	  [ ! -f $dataFile180 ]&& { log "[ERROR] 180+池子文件不存在 ! ($dataFile180)";send_mail "[$Now][ERROR] 180+池子文件不存在!" "请尽快处理";exit 1; }
	  log "[INFO] 开始从180+池子中选取剩下的用户数 : $diff_count rows from $dataFile180,排除${doneFile180}和${yesterdayFile},$dataFileNew"
    #[2017-7-17]周一与周日存在27w重复用户,源自180+的池子
    #less $dataFile180 | awk -F'\t' -v max=$diff_count -v ready1=$doneFile180 -v ready2=$yesterdayFile 'BEGIN{while(getline<"ready1" > 0)d1[$1]=1;while(getline<"ready2">0)d2[$1]=1;}{if($1 in d1||$1 in d2)next;if(count<=max)print;count+=1}'>$sampleFile180
    less $dataFile180 | awk -F'\t' -v max=$diff_count -v ready1=$doneFile180 -v ready2=$yesterdayFile -v ready3=$dataFileNew 'BEGIN{while(getline<ready1> 0)d1[$1]=1;while(getline<ready2>0)d2[$1]=1;while(getline<ready3>0)d3[$1]=1;}{if($1 in d1||$1 in d2||$1 in d3)next;if(count<=max)print;count+=1}'>$sampleFile180
	  #less $dataFile180 | awk -F'\t' -v max=$diff_count -v ready=$doneFile180 'BEGIN{while(getline<ready>0)d[$1]=1}{if($1 in d)next;if(count<=max)print;count+=1}'>$sampleFile180
	  cnt=`wc -l $sampleFile180 | awk '{print $1}'`
	  [ $cnt -lt $diff_count ]&&{ 
	    content="[ERROR] 180+用户池子已耗尽,需要重新取数($cnt < $diff_count)";log "$content"
	    send_mail "[$Now][ERROR] 180+部分池子已耗尽" "$content";
	    psql -f $cmdData180 
	    psql << sql
	      \copy (select * from wqw.sms_daily_180_new) to '$dataFile180Raw';
sql
	    [ $? -eq 0 ]&&{ log "[INFO] 180+数据下载完毕,开始格式化..."; }||{ log "[ERROR] 180+数据下载失败!程序退出...";send_mail "[$Now][ERROR] 180+数据下载失败,请尽快处理";send_msg "[ERROR]" "180+数据下载失败,请尽快处理";exit 1; }
	    less $dataFile180Raw | awk '{sub(/_$/,"",$2);if($2!~/^1[0-9]{10}$/)next;print $1"\t"$2"\t"$3}' > $dataFile180
	    [ $? -eq 0 ]&&{ log "[INFO] 180+数据格式化完毕($dataFile180Raw->$dataFile180)..."; }||{ log "[ERROR] 180+数据格式化失败!程序退出...";send_mail "[$Now][ERROR] 180+数据格式化失败,请尽快处理";send_msg "[ERROR]" "180+数据格式化失败,请尽快处理";exit 1; }
	    >$doneFile180 #清空done文件
      log "[INFO] 重新从新180+池子中选取剩下的用户数 : $diff_count rows from $dataFile180,排除${doneFile180},${yesterdayFile}和$dataFileNew"
      #less $dataFile180 | awk -F'\t' -v max=$diff_count -v ready=$doneFile180 'BEGIN{while(getline<ready>0)d[$1]=1}{if($1 in d)next;if(count<=max)print;count+=1}'>$sampleFile180
      #[2017-7-17]周一与周日存在27w重复用户,源自180+的池子
      #less $dataFile180 | awk -F'\t' -v max=$diff_count -v ready1=$doneFile180 -v ready2=$yesterdayFile 'BEGIN{while(getline<ready1>0)d1[$1]=1;while(getline<ready2>0)d2[$1]=1;}{if($1 in d1||$1 in d2)next;if(count<=max)print;count+=1}'>$sampleFile180
      less $dataFile180 | awk -F'\t' -v max=$diff_count -v ready1=$doneFile180 -v ready2=$yesterdayFile -v ready3=$dataFileNew 'BEGIN{while(getline<ready1> 0)d1[$1]=1;while(getline<ready2>0)d2[$1]=1;while(getline<ready3>0)d3[$1]=1;}{if($1 in d1||$1 in d2||$1 in d3)next;if(count<=max)print;count+=1}'>$sampleFile180
      cnt=`wc -l $sampleFile180 | awk '{print $1}'`
      [ $cnt -lt $diff_count ]&&{ content="[ERROR] 重新取数后,180+池子数仍然不能满足要求($cnt < $diff_count)";log "$content";send_mail "[$Now][ERROR] 重新取数后,180+池子仍然不够,退出" "$content";send_msg "[ERROR]" "重新取数后,180+池子仍然不够,请尽快处理";exit 1; }
    }
    cat $sampleFile180 >> $dataFileNew
    log "[INFO] 从180+池子中选取 $cnt 个用户(>180,diff_count=$diff_count)到($cnt1 rows) $dataFileNew"
  else
    log "[INFO] 正常策略用户数以满足需求,不用从180+池子中取 ($cnt1>$max_count w)"
  fi
#note
  #[2017-7-13]文件重复比例判断
  same_num=`less $dataFileNew | awk -F'\t' -v ready=$yesterdayFile 'BEGIN{while(getline<ready>0)d[$1]=1}{if($1 in d)count+=1}END{print count}'`
  [ -z $same_num ]&&{ same_num=0; }
  log "今日原始候选集合与昨日重复数目$same_num),请留意（重点核实180+池子和缓存池）...(today=$dataFileNew,yesterday=$yesterdayFile)"
  #[ $same_num -gt 6000 ]&&{ log "[ERROR] 今日原始候选集合与昨日重复数目较多($same_num>6000),请立即跟进（重点核实180+池子和缓存池）...(today=$dataFileNew,yesterday=$yesterdayFile)";send_mail "[$Now][ERROR] 今日原始候选集合与昨日重复较多($same_num>6000)" "请立即跟进（重点核实180+池子和缓存池）...(today=$dataFileNew,yesterday=$yesterdayFile)";send_msg "[ERROR]" "今日原始候选集合与昨日重复较多($same_num>6000),请立即跟进（重点核实180+池子和缓存池）";exit 1; }
  [ $same_num -gt 0 ]&&{
    log "[INFO] 今日候选集合与昨日存在少量${same_num}重复用户,启动去重..." #[2017-7-14]过滤重复用户+空手机号
    less $dataFileNew | awk -F'\t' -v ready=$yesterdayFile 'BEGIN{while(getline<ready>0)d[$1]=1}{if($1 in d)next;if($2!~/[0-9]+/)next;print}' > ${dataFileNew}_tmp
    cp ${dataFileNew}_tmp $dataFileNew && rm ${dataFileNew}_tmp
  }
#:<<note
  log "[INFO] 从pg获取待发送用户的其他信息(消息数+like数)"
	[ -f $dataFileAll -a `wc -l $dataFileAll | awk '{print $1}'` -gt 0 ]&&{ log "[INFO] 其他信息数据(${dataFileAll})已就绪,跳过 ..."; } || 
	{
    cnt=`wc -l $dataFileNew | awk '{print $1}'`
    [ $cnt -lt 1000 ]&&{ log "[ERROR] 候选用户集合过小($cnt<1000),请核实数据量!";send_mail "[$Now][ERROR]候选用户集合过小" "请核实数据源是否正常";exit 1; }
		log "[INFO] 开始加载用户数据到pg($dataFileNew),取相关信息(用户消息数)"
		psql<< sql
		  create table if not exists wqw.sms_daily_${jobName}_raw
		    (
		      user_id integer,
		      phone character varying(50),
		      gender character varying(50)
		    ); --comment '当天待发送用户集合'
	    comment on table wqw.sms_daily_done_tmp is '存储当天的SMS Recall用户信息(每天清理一次)';
		  delete from wqw.sms_daily_${jobName}_raw; --先清除
		  \copy wqw.sms_daily_${jobName}_raw FROM '$dataFileNew';
	    --insert into wqw.sms_daily_${jobName}_send
	    --  select user_id,phone,gender,current_date  from wqw.sms_daily_${jobName}_send_tmp
	    --  on conflict do nothing;	
sql
    log "[INFO] raw数据上传完毕,开始取消息数"
	  #psql -f $cmdDataMsg
    >${dataFileMsg}
    echo `seq 0 $num` | xargs -d' '  -I{}  -P32 sh -c "psql -c \"\\\\copy ( SELECT s.user_id, s.phone, s.gender, COALESCE(SUM(messages_count) FILTER(WHERE m.date_time > date(ut.last_activity + '8 h'::interval)), 0) AS new_msg FROM wqw.sms_daily_500w3day_raw s LEFT JOIN    usersAndTokens ut USING(user_id)  LEFT JOIN    daily_messages_by_users m ON m.other_user_id = ut.user_id AND m.date_time > date(ut.last_activity + '8 h'::interval) WHERE s.user_id % $num = {}  GROUP BY 1,2,3) to stdout\"" >> ${dataFileMsg}
    >${dataFileLike}
	  [ $? -eq 0 ]&&{ log "[INFO] 消息数获取完毕(${dataFileMsg}),开始获取like数"; }||{ log "[ERROR] 消息数获取失败!退出...(${dataFileMsg})";exit 1; }
    echo `seq 0 $num` | xargs -d' '  -I{}  -P32 sh -c "psql -c \"\\\\copy ( SELECT s.user_id, s.phone, s.gender, COALESCE(SUM(received_likes) FILTER(WHERE sw.date_time > date(ut.last_activity + '8 h'::interval)), 0) AS new_like FROM wqw.sms_daily_500w3day_raw s  LEFT JOIN    usersAndTokens ut USING(user_id)  LEFT JOIN    daily_swipes_by_users sw ON sw.user_id = ut.user_id AND sw.date_time > date(ut.last_activity + '8 h'::interval) WHERE s.user_id % $num = {}  GROUP BY 1,2,3) to stdout\"" >> ${dataFileLike}
    [ $? -eq 0 ]&&{ log "[INFO] 喜欢数获取完毕(${dataFileMsg}),开始获取用户属性信息"; }||{ log "[ERROR] 喜欢数获取失败!退出...(${dataFileMsg})";exit 1; }
    psql -c '\copy (select s.user_id,age_calculator(a.birthdate) as age,a.name from wqw.sms_daily_500w3day_raw s LEFT JOIN stats.core_users a on s.user_id = a.user_id) to stdout' > ${dataFileProfile}
    [ $? -eq 0 ]&&{ log "[INFO] 属性信息获取完毕(${dataFileProfile}),开始融合(msg+like+profile)"; }||{ log "[ERROR] 属性信息获取失败!退出...(${dataFileProfile})";exit 1; }
    #less ${dataFileMsg} | awk -F'\t' -v like="${dataFileLike}" 'BEGIN{OFS="\t";while(getline<like>0)d[$1]=$4}{like=d[$1];if(like=="")like=0;print $1,$2,$3,$4,like}' > ${dataFileAll}
    less ${dataFileMsg} | awk -F'\t' -v like="${dataFileLike}" -v profile=${dataFileProfile} 'BEGIN{OFS="\t";while(getline<like>0)d[$1]=$4;while(getline<profile>0)p[$1]=$0}{like=d[$1];if(like=="")like=0;split(p[$1],pa,"\t");print $1,$2,$3,$4,like,pa[2],pa[3]}' > ${dataFileAll}
	  [ $? -eq 0 ]&&{ log "[INFO] 成功融合消息+喜欢+profile数据($dataFileAll)"; } || { log "[ERROR] 融合数据失败!($dataFileAll)";exit 1; }
	}
#note
  #cmdProcess="python $format $jobDir $dataFileMsg $sendFile $sendFileTelecom &> $dataFileStat"
  cmdProcess="python $format $jobDir $dataFileAll $sendFile $sendFileTelecom | tee -a $dataFileStat"
  #cmdProcess="python $format $jobDir $dataFileNew $sendFile $sendFileTelecom | tee -a $dataFileStat"
  log "[INFO] 数据预处理"
  [ -f $sendFile ]&& log "[INFO] 过滤后的文件已存在,跳过" || {
    log "[INFO] 开始执行预处理程序($cmdProcess)"
    #[ ! -f $sendFile ] && python $format $jobDir $dataFile $sendFile
    log "\n=====数据统计分析=======\n" | tee -a $dataFileStat
    eval $cmdProcess
  }
  [ $? -eq 0 ]&& { 
    log "[INFO] 数据预处理完毕 ($dataFileNew->$sendFile)";
    log "[INFO] 上传待发送文件(含5%的对照组,不发送,group=0)至pg表(wqw.sms_daily_${jobName}_send)"
    less $sendFile | awk -F'\t' 'BEGIN{OFS="\t"}{if(NF<7)next;print $1,$2,$3,$4,$5,$6,$7}' > $sendFileTmp
    less $sendFileTelecom | awk -F'\t' 'BEGIN{OFS="\t"}{if(NF<7)next;print $1,$2,$3,$4,$5,$6,$7}' > $sendFileTelecomTmp
    psql << sql
			--[2017-6-28]上传待发送文件至pg(含分组)
			--157 13810347287 mobile  user_name male  1 ...
      --user_id,phone,net,name,gender,group,dt,newNum,cwType,hourNum,distNum
			create table if not exists wqw.sms_daily_${jobName}_send
			  (
			    user_id integer,
			    phone character varying(50) not null,
			    net character varying(20),
			    name character varying(50),
			    gender character varying(50),
			    groupid character varying(50),
			    dt character varying(10),
			    --time timestamp without time zone
			    primary key (user_id,dt)
			  ); --comment '历史待发送用户集合'
			create table if not exists wqw.sms_daily_${jobName}_send_telecom ( like wqw.sms_daily_${jobName}_send);
			create table if not exists wqw.sms_daily_${jobName}_send_tmp ( like wqw.sms_daily_${jobName}_send);
			comment on table wqw.sms_daily_${jobName}_send_tmp is '存储当天的SMS Recall用户信息(每天清理一次)';
      --移动联通用户数据
			delete from wqw.sms_daily_${jobName}_send_tmp; --先清除
			\copy wqw.sms_daily_${jobName}_send_tmp FROM '$sendFileTmp';
			insert into wqw.sms_daily_${jobName}_send
			  select user_id,phone,net,name,gender,groupid,dt  from wqw.sms_daily_${jobName}_send_tmp
			  on conflict do nothing;
      --电信用户数据
			delete from wqw.sms_daily_${jobName}_send_tmp; --先清除
			\copy wqw.sms_daily_${jobName}_send_tmp FROM '$sendFileTelecomTmp';
			--insert into wqw.sms_daily_${jobName}_send_telecom --[2017-07-11]取消send_telecom表,融合成一张
			insert into wqw.sms_daily_${jobName}_send
			  select user_id,phone,net,name,gender,groupid,dt  from wqw.sms_daily_${jobName}_send_tmp
			  on conflict do nothing;
sql
    log "[INFO] 删除临时文件($sendFileTmp,$sendFileTelecomTmp)"
    rm $sendFileTmp $sendFileTelecomTmp
    log "[INFO] 开始统计resend数值"
    echo "========历史重复发送统计=========" | tee -a $dataFileStat
    psql -f $cmdDataResend | tee -a $dataFileStat #内容追加
    #psql -f $cmdDataResend | tee $dataFileStat
	  [ $? -eq 0 ]&&{ log "[INFO] 完成当天用户的历史发送次数的统计"; } || { log "[ERROR] 当天发送次数统计失败!";send_msg "[ERROR]" "当天发送次数统计失败";exit 1; }
    #send_mail "[Idle SMS Recall] Data info of users to send " "${dataFileStat}";  
    #[2017-7-5]钟文鑫统计代码
    psql -f $cmdDataSms | tee -a $dataFileStat
    [ $? -eq 0 ]&&{ log "[INFO] 完成SMS宏观统计统计"; } || { log "[ERROR] SMS宏观统计统计失败!";send_mail "[$Now]SMS宏观统计失败" "请跟进..."; }
    content=`cat $dataFileStat`;send_mail "[$Now]今日发送用户基本信息" "$content" "out";  
  }||{ log "[ERROR] 数据预处理失败 ($dateFileNew->$sendFile)";send_msg "[ERROR]" "数据预处理失败";exit 1; }
}
#[2017-07-11],连续两天重复数检测
yesterday_send=${sendFile//$Now/$yesterday}
[ ! -f ]&&{ log "[WARNING] 昨天的发送文件不存在,无法计算重复用户($yesterday_send)"; }||
{
  #比对昨日发送用户重复数
  same_count=`less $sendFile | awk -F'\t' -v ready=$yesterday_send 'BEGIN{while(getline<ready>0)d[$1]=1}{if($1 in d)print $1}'|wc -l`
  log "[INFO] 今日与昨日重复用户数$same_count"
  [ $same_count -gt 10 ]&&{ log "[ERROR] 今日发送用户与昨日重复数超过阈值($same_count>10),退出...";send_mail "[$Now]今日与昨日重复用户数超过阈值($same_count>10)" "请跟进...";send_msg "[ERROR]" "今日与昨日重复用户数超过阈>值($same_count>10)";exit 1; }  
  #[ $same_count -gt 10 ]&&{ log "[ERROR] 今日发送用户与昨日重复数超过阈值($same_count>10),退出...";exit 1; }  
}
#======================================
#计算推送qps
send_other_num=`wc -l $sendFile | awk '{print $1}'`
send_telecom_num=`wc -l $sendFileTelecom | awk '{print $1}'`
qps_other=`awk -v num=$send_other_num -v tm=$diff_time 'BEGIN{print num/(tm*60)}'`
qps_telecom=`awk -v num=$send_telecom_num -v tm=$diff_time_telecom 'BEGIN{print num/(tm*60)}'`
#let qps_other=send_other_num/diff_time/60
#let qps_telecom=send_telecom_num/diff_time_telecom/60
log "[NOTE] 今日发送qps数值:(1) 移动联通qps: ${qps_other}条/秒,${startTime}->${endTime},${diff_time}分钟. (1) 电信qps: ${qps_telecom}条/秒,${startTime}->min(${endTime}),${diff_time_telecom}分钟"
log "[INFO] 等待启动时间 "
[ $mode == "online" ]&&{
  log "[INFO] 线上模式($mode),启动等待机制..."
  waitTime $startTime 
  [ ! -f $sendFile ]&&{ log "[ERROR] 时间已到,但发送数据(${sendFile})不存在,退出 ...";send_msg "[ERROR]" "时间已到,但发送数据不存在";exit 1; }
  if [ $mode != "continue"  ];then
    [ ! -f $doneFile ]&&touch $doneFile
    [ ! -f $errorFile ]&&touch $errorFile
  fi
}|| { log "[INFO] 非线上模式($mode),停止等待,5s后往后执行(紧急停止请用sudo kill -9 pid)";sleep 5s; }
:<<note
for file in "$sendFile"
do
  [ ! -f $file ]&&{ log "[ERROR] 待发送文件不存在 (${file}), 退出 ...";exit 1; }
done
note
#====================================
#Three mode: (1) debug for test (2) online for real job (3) continue for continued online job
if [ $mode == "debug" ];then
  #Command of sending msg -- debug
  pushDuration=1 # Total time of sending job
  cmd="${BinDir}/putong-idle-user-sms-push -config=${ConfDir}/idle-sms-recall.json -pushMinutes=${pushDuration} -push=${pushConf} -send=${sendFile} -done=${doneFile} -error=${errorFile}"
elif [ $mode == "online" ];then
  #Command of sending msg -- online , start kafka log
  #电信用户
  telecom_num=`wc -l $sendFileTelecom | awk '{print $1}'`
  [ $telecom_num -lt 1 ]&&{ log "[INFO] 电信用户有${telecom_num}个,过小,忽略($sendFileTelecom)"; }||
  { #2h发完，失败不重发
    log "[INFO] 电信用户有${telecom_num}个,单独发送($sendFileTelecom)"
    touch ${doneFileTelecom} #[2017-6-28]提前创建文件,避免子进程无读写权限
    touch ${errorFileTelecom} #[2017-6-28]提前创建文件,避免子进程无读写权限
    #[2017-6-30]同一个bin文件不能同时调用多次,否则死掉,解决方法:单独复制一份
    cp "${BinDir}/putong-idle-user-sms-push" "${BinDir}/putong-idle-user-sms-push-telecom"
    cmdTelecom="${BinDir}/putong-idle-user-sms-push-telecom -config=${ConfDir}/idle-sms-recall-telecom.json -pushMinutes=${diff_time_telecom} -push=${pushConf} -send=${sendFileTelecom} -done=${doneFileTelecom} -error=${errorFileTelecom} -mode=online"
    log "[INFO] 并行发送($cmdTelecom)"
    eval "$cmdTelecom&" &&{ log "[INFO] 电信用户发送扔后台"; }||{ log "[ERROR] 电信用户发送失败,退出...";send_msg "[ERROR]" "电信用户发送失败";exit 1; }
:<<note
    {#{}内命令不具备root权限，导致bin程序无法创建文件，失败退出
      eval $cmdTelecom
      [ $? -eq 0 ]&&{ log "[INFO] 电信用户发送成功"; }||{ log "[ERROR] 电信用户发送失败,退出...";exit 1; }
    }&
note
  }
  #移动联通用户
  cmd="${BinDir}/putong-idle-user-sms-push -config=${ConfDir}/idle-sms-recall.json -pushMinutes=${pushDuration} -push=${pushConf} -send=${sendFile} -done=${doneFile} -error=${errorFile} -mode=online"
elif [ $mode == "continue"  ];then
  #Command of sending msg -- continue the latest job
  log "[NOTE] Backup $doneFile to $doneFile1 "
  #cp $doneFile $doneFile1 #[2017-6-29]没必要
  #cmdContinue="python $reformat $doneFile $sendFile $sendFile1"
  #sendFile和doneFile格式不一(按uid去重)
  log "[NOTE] 断点续发模式:重新计算用户集合(去掉已发用户) (按照第一个字段uid去重,如果格式变更，务必更新awk代码!) "
  #eval $cmdContinue
  less $sendFile | awk -F'\t' -v ready=$doneFile 'BEGIN{while(getline<ready>0)d[$1]=1}{if($1 in d)next;print}'>$sendFile1
  [ $? -eq 0 ]&&{ log "[INFO] 已发用户已去除"; }||{ log "[ERROR] 已发用户去除失败,退出...";exit 1; }
  cmd="${BinDir}/putong-idle-user-sms-push -config=${ConfDir}/idle-sms-recall.json -pushMinutes=${pushDuration} -push=${pushConf} -send=${sendFile1} -done=${doneFile} -error=${errorFile} -mode=online"
  #cmd="${BinDir}/putong-idle-user-sms-push -config=${ConfDir}/idle-sms-recall.json -pushMinutes=${pushDuration} -push=${pushConf} -send=${sendFile1} -done=${doneFile} -mode=online"
else
  log "[ERROR] mode模式取值有误($mode!=debug|online|continue),退出 !"
  exit 1
fi
log "[NOTE] 开始启动发送程序:\n\t $cmd\n================go程序运行日志============" # log
eval $cmd # Execute
if [ $? -eq 0 ];then
   log "[NOTE] 完成所有数据的发送 !"
   if [ $mode == "continue"  ];then
     log "[NOTE] 断点续发模式:开始合并已发送数据 ($doneFile1 -> $doneFile)"
     cat $doneFile1 >> $doneFile
   elif [ $mode == "debug"  ];then
     log "[NOTE] 测试短信发送完毕,无须上传pg步骤,立即退出"
     exit 0
   fi
   log "[NOTE] 上传已发送用户数据到PG($doneFile)"
   psql -f $cmdDone
   [ $? -eq 0 ]&& log "[INFO] SMS Recall发送记录表结构更新完成" || { log "[ERROR] SMS Recall发送记录表结构更新失败,退出...";exit 1; }
   psql << SQL
    --user_id | time | phone | net | provider | name | groupid | gender | cwname | cwcontent
    create table if not exists wqw.sms_daily_done_all
        (
          user_id integer,
          time timestamp without time zone,
          phone character varying(50) not null,
          net character varying(20),
          provider character varying(20),
          name character varying(50),
          groupid integer,
          gender character varying(50),
          cwname character varying(20),
          cwcontent character varying(300),
          primary key (user_id,time)
        ); --comment '历史待发送用户集合'
		create table if not exists wqw.sms_daily_done_other_tmp ( like wqw.sms_daily_done_all);
		create table if not exists wqw.sms_daily_done_telecom_tmp ( like wqw.sms_daily_done_all);
    --移动联通用户数据
    delete from wqw.sms_daily_done_other_tmp; -- 每天清理一次
    \copy wqw.sms_daily_done_other_tmp FROM '$doneFile';
    insert into wqw.sms_daily_done_all
      --select user_id,phone,name,time,cwname,gender,cwcontent from wqw.sms_daily_done_tmp
      --[2017-7-3]数据格式升级[2017-7-13]再次升级,改时间戳,加groupid
      select user_id,time,phone,net,provider,name,groupid,gender,cwname,cwcontent from wqw.sms_daily_done_other_tmp
      on conflict do nothing;
    --电信用户数据
    delete from wqw.sms_daily_done_telecom_tmp; -- 每天清理一次
    \copy wqw.sms_daily_done_telecom_tmp FROM '$doneFileTelecom';
    insert into wqw.sms_daily_done_all
      select user_id,time,phone,net,provider,name,groupid,gender,cwname,cwcontent from wqw.sms_daily_done_telecom_tmp
      on conflict do nothing;
SQL
  if [ $? -eq 0 ];then
    log "[NOTE] 成功将已发送用户数据备份至PG"
  else
    log "[ERROR] 已发送用户数据备份失败"
  fi
  send_msg "[INFO]" "移动联通流程执行完毕"
else
   log "[ERROR] 短信发送过程中出错 !"
   send_msg "[ERROR]" "移动联通流程失败"
   #log "[ERROR] Error !" | mail -s " Error ..." $mails
fi
#if [[ $mode =~ online|continue ]];then
if [ $mode == "continue" -o $mode == "online" ];then 
  [ $diff_count -gt 0 ]&&
  {
    log "[INFO] 今天消耗了180+的池子(${diff_count}个用户),开始更新"
    cat $sampleFile180 >> $doneFile180
    log "[INFO] 更新180+部分发送成功的数据文件($doneFile180)"
  }||{
    log "[INFO] 今天没有消耗180+池子,无需更新"
  }
  [ $flagRest -eq 1 ]&&
  {
    cat $dataFileRestSend >> $dataFileRestDone
    log "[INFO] 更新已消耗的缓存池($dataFileRestDone)"
  }||{
    log "[INFO] 今天没有消耗缓存池"
  }
  #[2017-8-2]remove some data to save for limited space
  for tmp_file in `echo "$dataFileNew $dataFileLike $dataFileMsg"`
  do
    [ -f $tmp_file ]&&{ log "[INFO] remove tmp file : $tmp_file";rm $tmp_file; }
  done
  #upload data to Hadoop/Hive
  #待发送文件
  send_file="${save_path}/data/$Now/$send_name"
  [ -f $send_file ]&& { echo "${send_file}已存在,清空";>$send_file; } || { echo "${send_file}不存在,创建";mkdir -p ${send_file%/*}&&>$send_file; }
  #cat ${local_path}/${Now}/output_500w3day{,_telecom}.txt >> $send_file
  cat $sendFile $sendFileTelecom >> $send_file
  #已发送文件
  done_file="${save_path}/data/$Now/$done_name"
  [ -f $done_file ]&& { echo "${done_file}已存在,清空";>$done_file; } || { echo "${done_file}不存在,创建";mkdir -p ${done_file%/*}&&>$done_file; }
  cat $doneFile $doneFileTelecom >> $done_file
  #失败文件
  error_file="${save_path}/data/$Now/$error_name"
  [ -f $error_file ]&& { echo "${error_file}已存在,清空";>$error_file; } || { echo "${error_file}不存在,创建";mkdir -p ${error_file%/*}&&>$error_file; }
  cat $errorFile $errorFileTelecom >> $error_file
  #merge
  output_file="${save_path}/$Now/$output_name"
  #[ -f "$myfile" ] && out_done=`less $myfile | awk '{d[$1]+=1;count+=1}END{print length(d)"\t"count}'` || out_done="-\t-"
  echo -e "[`date +%H:%M:%S`][$Now]开始转换格式${myfile}"
  python $copy_dir/format.py $copy_dir $Now $send_file $done_file $error_file > $output_file
  #上传至Hadoop
  local_file=$output_file
  hadoop_file="${hadoop_path}/${Now}"
  #$hadoop fs -ls /
  #hadoop fs -tail /user/wangqiwen/sms_recall/send/20170727/output_500w3day.txt
  $hadoop fs -test -e $hadoop_file
  [ $? -eq 0 ]&&{ echo "[`date +%H:%M:%S`][$Now]目录已存在:${hadoop_file},删除";$hadoop fs -rm $hadoop_file/*; }||{
    echo "[`date +%H:%M:%S`][$Now]目录不存在:${hadoop_file},开始创建";
    $hadoop fs -mkdir -p $hadoop_file
    [ $? -ne 0 ]&&{ echo "[`date +%H:%M:%S`][$Now]目录创建失败,退出";exit 1; }||{ echo "[`date +%H:%M:%S`][$Now]目录创建完毕"; }
  }
  echo "[`date +%H:%M:%S`][$Now]开始上传本地文件到Hadoop: $local_file -> $hadoop_file"
  $hadoop fs -put $local_file $hadoop_file
  [ $? -ne 0 ]&&{ echo "[`date +%H:%M:%S`][$Now]文件上传失败，退出";exit 1; }||{ echo "[`date +%H:%M:%S`][$Now]文件上传成功"; }
  $hive -f $hive_cmd -hivevar date=$Now
  [ $? -ne 0 ]&&{ echo "[`date +%H:%M:%S`][$Now]Hive外部表创建失败，退出";exit 1; }||{ echo "[`date +%H:%M:%S`][$Now]Hive外部表创建成功"; }
  rm $send_file $done_file $error_file
fi
#Close redirection
exec 3<&-
