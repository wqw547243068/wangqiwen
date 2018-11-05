#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#            File:  start_job.sh [aos]
#           Usage:  
#     Description:  aos日志处理的hadoop启动脚本
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

#7个参数 /home/devuse/bin/hadoop/bin/hadoop /home/devuse/bin/hadoop/bin/hive /user/hive/warehouse/logamap.db/log_rc/dt=20140301/000000_0 log_aos ./ 20140301 start_20140301_log_aos
#:<<note
set -x
if [ $# -ne 8 ]; then
	echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [session-aos] input error ! \$#=$# not 8"
	exit -1
fi
hadoop=$1;hive=$2;input_ready=$3;jobname=$4;main_dir=$5;date=$6;task_prefix=$7;now=$8
#note

echo "参数($#):[$*]"
:<<note
hive="/home/devuse/bin/hadoop/bin/hive"
date='20140308'
note

database='log_session'
table='log_aos'
#path="."  # test
path="hive_jobs/log/$table"
aos_path="../../../tool/aos.txt"
sql="$path/old_create_aos.sql"
date1="${date:0:4}/${date:4:2}/${date:6:2}"
# 启动hive任务
${hive} -hivevar path=$path -hivevar aos_path=$aos_path -hivevar date1=$date1 -hivevar date=$date -f $sql
if [ $? -ne 0 ];then
    echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] Fail to execute hive job !"
    exit -1
else
    echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] Success to execute hive job !"
fi

:<<note
path="/user/hive/warehouse/${database}.db/${table}/dt=${date}"
# 生成ready文件
${hadoop} fs -test -e $path 
if [ $? -ne 0 ];then
    ${hadoop} fs -touchz ${path}/ready.done
fi
note

