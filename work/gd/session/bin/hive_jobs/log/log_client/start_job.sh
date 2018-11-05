#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#            File:  start_job.sh [client]
#           Usage:  
#     Description:  客户端flume离线日志处理的hadoop启动脚本
#    LastModified:
#         Created:  2014-7-23 11:34 PM
#          AUTHOR:  huo.zhu(huo.zhu@autonavi.com)
#         COMPANY:  autonavi
#         VERSION:  1.0
#            NOTE:  
#           input:  
#          output:  
#===============================================================================

#8个参数 /home/devuse/bin/hadoop/bin/hadoop /home/devuse/bin/hadoop/bin/hive /user/hive/warehouse/logamap.db/log_rc/dt=20140301/000000_0 log_sp ./ 20140301 start_20140301_log_sp 20140616
#:<<note
set -x
if [ $# -ne 8 ]; then
	echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [session-client] input error ! \$#=$# not 8"
	exit -1
fi
hadoop=$1;hive=$2;input_ready=$3;jobname=$4;main_dir=$5;date=$6;task_prefix=$7;now=$8
#note

echo "参数($#):$*"

database='log_session'
table='log_client'
path="hive_jobs/log/$table"
sql="$path/client_from_flume.sql"
date1="${date:0:4}/${date:4:2}/${date:6:2}"
# 启动hive任务
$hive -hivevar path=$path -hivevar date="$date" -hivevar date1="$date1" -f $sql
if [ $? -ne 0 ];then
    echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [client] Fail to execute hive job !"
    exit -1
else
    echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] [client] Success to execute hive job !"
fi

 
