#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#            File:  start_job.sh [sug]
#           Usage:  
#     Description:  客户端离线日志处理的hadoop启动脚本
#    LastModified:  2014-10-16 取消MR转码
#         Created:  2014-5-20 11:01 PM
# 
#          AUTHOR:  warren(warren@autonavi.com)
#         COMPANY:  autonavi
#         VERSION:  1.0
#            NOTE:  
#           input:  
#          output:  
#===============================================================================

#7个参数 /home/devuse/bin/hadoop/bin/hadoop /home/devuse/bin/hadoop/bin/hive /user/hive/warehouse/logamap.db/log_rc/dt=20140301/000000_0 log_sp ./ 20140301 start_20140301_log_sp 20140701

database='log_session'
table='log_sug'

#:<<note
set -x
if [ $# -ne 8 ]; then
	echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [session-sug] input error ! \$#=$# not 8"
	exit -1
fi
hadoop=$1;hive=$2;input_ready=$3;jobname=$4;main_dir=$5;date=$6;task_prefix=$7;now=$8
path="hive_jobs/log/${table}" # online
#note

echo "参数($#):$*"

:<<note
hive="/data/soft/hadoop2/hive/bin/hive"
date='20141015'
path="." # test
jobname="log_sug"
hadoop="/opt/cloudera/parcels/CDH-4.2.1-1.cdh4.2.1.p0.5/bin/hadoop"
note

sql="$path/old_create_sug.sql"
date1="${date:0:4}/${date:4:2}/${date:6:2}"
date2="${date1//\//-}"
#load data inpath $output overwrite into table log_sug partition (dt=)
#LOAD DATA LOCAL INPATH '/home/hadoop/login_array.txt' OVERWRITE INTO TABLE login_array PARTITION (dt='20130101');
# ---------- load data to hive table ------------------
echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] [sug] Start to load data to hive(log_sug) !"
$hive -hivevar path=$path -hivevar date="$date" -hivevar date1="$date1" -hivevar date2="$date2" -f $sql
if [ $? -ne 0 ];then
    echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [sug] Fail to execute hive job !"
    exit -1
else
    echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] [sug] Success to execute hive job !"
fi

:<<note
path="/user/hive/warehouse/${database}.db/${table}/dt=${date}"
# 生成ready文件
${hadoop} fs -test -e $path 
if [ $? -ne 0 ];then
    ${hadoop} fs -touchz ${path}/ready.done
fi
note

echo "[$0] [NOTE] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] hadoop job finished"
