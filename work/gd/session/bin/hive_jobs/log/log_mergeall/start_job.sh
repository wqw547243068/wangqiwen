#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#            File:  start_job.sh [merge]
#           Usage:
#     Description:  merge日志处理的hadoop启动脚本
#    LastModified:
#         Created:  2014-3-10 13:10 PM
#
#          AUTHOR:  warren(warren@autonavi.com)
#         COMPANY:  autonavi
#         VERSION:  1.0
#            NOTE:
#           input:
#          output:
#===============================================================================

#7个参数 /home/devuse/bin/hadoop/bin/hadoop /home/devuse/bin/hadoop/bin/hive /user/hive/warehouse/logamap.db/log_rc/dt=20140301/000000_0 log_merge ./ 20140301 start_20140301_log_merge
#:<<note
set -x
if [ $# -ne 8 ]; then
	echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [session-merge] input error ! \$#=$# not 8"
	exit -1
fi
hadoop=$1;hive=$2;input_ready=$3;jobname=$4;main_dir=$5;date=$6;task_prefix=$7;now=$8
#note

echo "参数($#):[$*]"
:<<note
hive="/home/devuse/bin/hadoop/bin/hive"
date='20140308'
note

echo "input_ready=$input_ready"

database='log_session'
table='log_mergeall'
path="hive_jobs/log/$table"
sql="$path/create_mergeall.sql"
date1="${date:0:4}/${date:4:2}/${date:6:2}"
date_pre=`date -d "1 days ago $date" +%Y%m%d`
date_suf=$6
# 启动hive任务
#${hive} -hivevar path=$path -hivevar date1=$date1 -hivevar date2=$date -f $sql
${hive} -hivevar path=$path -hivevar date="$date_pre" -hivevar date_suf="$date_suf" -f $sql
if [ $? -ne 0 ];then
    echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] Fail to execute hive job !"
    exit -1
else
    echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] Success to execute hive job !"
fi


