#!/usr/bin/sh
# -*- coding: utf-8 -*-

#===============================================================================
#            File:  build.sh
#           Usage:  sh build.sh
#     Description:  Create and maintain local directory structure
#    LastModified:  
#         Created:  5/31/2017 16:33 PM CST
# 
#          AUTHOR:  wangqiwen@p1.com)
#         COMPANY:  Tantan Inc
#         VERSION:  1.0
#            NOTE:  
#===============================================================================


readonly LogDayCnt=30 # Retenion time of local log files
readonly BakDayCnt=30 # Retenion time of backup files
readonly DataDayCnt=70 # Retenion time of data files

# Grant the permission to execute if needed
#:<<note
#for file in `ls ${ShellDir}/*.sh ${ShellDir}/conf/*.sh`
#do
#        [ ! -x $file ] && chmod a+x $file
#done
#note

#readonly RootDir=${ShellDir%/*}
readonly RootDir=`pwd`
readonly Now=`date "+%Y%m%d"`
readonly BakDir="${RootDir}/bak/$Now"
readonly LogDir="${RootDir}/log/$Now"
readonly DataDir="${RootDir}/data/$Now"
readonly BinDir="${RootDir}/bin"
readonly ConfDir="${RootDir}/conf"

# Create local module directory 
file_dir=( $BakDir $LogDir $DataDir $BinDir $ConfDir)
index=$((${#file_dir[*]}-1))
for i in `seq 0 $index`
do
  [ ! -d ${file_dir[$i]} ] && { mkdir -p ${file_dir[$i]};echo -e "Successed to create dir ${file_dir[$i]}"; }
  #[ ! -d ${file_dir[$i]} ] && { mkdir -p ${file_dir[$i]};echo -e "Successed to create dir ${file_dir[$i]}"; } || echo -e "${file_dir[$i]} exists already"
done

# Backup the current info
cp -r {conf,bin,*.sh} ${BakDir}/
#cp -r {conf,bin,data,*.sh} ${BakDir}/

# Remove the expired directories and files
#find ${BakDir%/*} -maxdepth 1 -mindepth 1 -mtime +${BakDayCnt} -exec rm \-rf {} \; -print
#find ${LogDir%/*} -maxdepth 1 -mindepth 1 -mtime +$LogDayCnt -exec rm \-rf {} \; -print
#find ${DataDir%/*} -maxdepth 1 -mindepth 1 -mtime +$DataDayCnt -exec rm \-rf {} \; -print

#PG参数
#[2017-06-02] pg数据库参数
export PGTZ=UTC
export PGHOSTADDR=10.191.160.28
export PGDATABASE=putong-stats
export PGUSER=wangqiwen
# PGUSER=putong-stats
export PGPASSWORD=3ef2d0f0-6f0e-4cf5-96af-991df77b44a1

#邮件服务
readonly mail_on=1
readonly mail_receivers="wangqiwen@p1.com,wqw547243068@163.com"
readonly mail_receivers_out="wangqiwen@p1.com,wqw547243068@163.com,wangyikai@p1.com,huoyujia@p1.com,wangwei@p1.com,jiangyongbing@p1.com,hanzhibai@p1.com,zhoulu@p1.com,zhongwenxin@p1.com,zhangxiaoyu@p1.com,sunbenxin@p1.com"
#readonly msg_on=0
readonly msg_on=1
readonly msg_receivers="15210923792,18911639523,13911619671,13116152536,17610968213"
msg_list=( ${msg_receivers//,/ } ) # 字符串变数组

#公用函数
function log()
{
  echo -e "[$0] [`date "+%Y-%m-%d %H:%M:%S"`] $*"
}

function waitTime()
{
  if [ $# -lt 1 ];then
    log "[ERROR] Input error ! wait time"
    exit 1
  fi
  end=$1
  log "[INFO] Start to wait until $end"
  cur=`date "+%H:%M:%S"`
  while [ $cur \< $end ];
  do
    log "[INFO] Time early ($cur<$end),continue to sleep"
    sleep 1m
    #sleep 2s
    cur=`date "+%H:%M:%S"`
  done
  log "[INFO] Time's up ! ($cur,$end) Stop sleeping ..."
}

function send_mail()
{ # send_mail title content type(in/out)
    if [ $# -lt 2 ]; then
       log "[ERROR] $0: 参数不够!请参考格式: send_mail title content [type]!"
       return 1
    fi
    title="$1";content="$2"
    receiver=$mail_receivers
    #[ $# -ge 3 -a $3 == "out" ]&& { receiver=$mail_receivers_out;log "[INFO][$0] 对外邮件"; }|| log "[INFO][$0] 对内邮件"
    [ $# -ge 3 -a $3 == "out" ]&& { receiver=$mail_receivers_out;log "[INFO][$0] 对外邮件"; }|| { log "[INFO][$0] 对内邮件"; }
    if [ $mail_on -ne 1 ];then
       log "[INFO] Mail off, skip it ($1,$2)"
       return 0
    fi
    log "$content" | mail -s "[Idle SMS Recall] $title" "$receiver"
    if [ $? -ne 0 ]; then
       log "[ERROR] Failed to send email to $receiver ($1)!"
    else
       log "[NOTE] Success to send email $receiver ($1)!"
    fi
    return 0
}

function send_msg()
{ #send msg alarm: $1(错误级别) $2(细节) $3 $4
  #[2017-7-5]上一行的#不能紧挨着{，会导致send_msg函数无法识别
  if [ $# -lt 2 ]; then
    log "[ERROR] $0: Input error !"
    return -1
  fi
  level=$1;content=$2
  [ $msg_on -ne 1 ] && { log "[INFO] $0: Msg alarm off, pass";return 0; }
  #template="【探探社交-SMS Recall Alarm】scp当前时段[`date +'%F %H:%M:%S'`]转化率($level) 隔日同比变化异常($content) 由${3}变为${4}，请检查"
  template="【探探-SMS Recall Alarm】[`date +'%F %H:%M:%S'`] $1 $2 "
  #[2017-7-3] 
  #wget -O tmp.1 "http://124.251.7.232:9007/axj_http_server/sms?name=ttfa22&pass=a1s2d3&subid=123&mobiles=$monlist&content=$line&sendtime="
  msg_url="http://124.251.7.232:9007/axj_http_server/sms?name=ttfa22&pass=a1s2d3" # new
  #msg_url="http://111.13.56.193:9007/axj_http_server/sms?name=ttfa11&pass=q1w2e3" #old 
  #wget -O tmp.1 "${msg_url}&subid=123&mobiles=${msg_receivers}&content=${template}&sendtime="
  for((i=0;i<${#msg_list[@]};i++))
  do
    log "开始发送短信给${msg_list[i]}"
    wget -O tmp_msg "${msg_url}&subid=123&mobiles=${msg_list[i]}&content=${template}&sendtime="
    [ -f "tmp_msg" ]&& rm tmp_msg;
  done
:<<note
  local i="-"
  local phone_number="-"
  for((i=2;i<=$#;i++))
  do
    eval "phone_number=\${$i}"
    # Ïò$phone_number·¢ËÍ±¨¾¯ÐÅÏ¢$1
    gsmsend -s $GSMSERVER1:$GSMPORT1 -s $GSMSERVER2:$GSMPORT2 *$GSMPIORITY*"$phone_number@$1" 
    if [ $? -ne 0 ];then
      log "[ERROR] Fail to send msg alarm !"
      #log "[`date "+%Y-%m-%d %H:%M:%S"`] [ERROR] ±¨¾¯¶ÌÐÅ·¢ËÍÊ§°Ü !"
    else
      log "[NOTE] Succeed to send ($1) to $phone_number !"
    fi  
  done
note
}
