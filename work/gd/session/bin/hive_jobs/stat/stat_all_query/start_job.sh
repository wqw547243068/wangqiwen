#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#            File:  start_job.sh [stat_all_query]
#           Usage:  
#     Description:  stat_all_query表启动程序
#         Created:  2014-6-16 11:37 PM
#          AUTHOR:  warren(warren@autonavi.com)
#    LastModified: 2014-6-16 修改start.py框架,增加当天日期now参数
#===============================================================================

# 参数 /home/devuse/bin/hadoop/bin/hadoop /home/devuse/bin/hadoop/bin/hive /user/hive/warehouse/logamap.db/log_rc/dt=20140301/000000_0 log_sp ./ 20140301 start_20140301_log_sp 20140621
#:<<note
set -x
if [ $# -ne 8 ]; then
	echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [stat_all_query] input error ! \$#=$# not 8"
	exit -1
fi
hadoop=$1;hive=$2;input_ready=$3;jobname=$4;main_dir=$5;date=$6;task_prefix=$7;now=$8
#note

echo "参数($#):$*"
:<<note
hive="/home/devuse/bin/hadoop/bin/hive"
date='20140601'
main_dir='/home/devuse/warren/svn/plana/home/warren/session'
now='20140616'
path='.'
note

database='log_session'
table='stat_all_query'
path="hive_jobs/stat/$table"
sql="$path/create_all_query.sql"
date1="${date:0:4}/${date:4:2}/${date:6:2}"
data_file="${main_dir}/../data/$now/${table}_${date}.txt"
# 启动hive任务
${hive} -hivevar path=$path -hivevar date=$date -hivevar date1=$date1  -f $sql
if [ $? -ne 0 ];then
    echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] Fail to execute hive job !"
    exit -1
fi

echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] Success to execute hive job !"
echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] Download data file to local path ($data_file)..."
${hive} -e "select * from log_data.stat_all_query where dt='$date'" > $data_file
if [ $? -ne 0 ];then
	echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] Fail to dowload data file ($data_file) !"
	exit -1
else
	echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] Success to dowload data file ($data_file) !"
fi
:<<note
path="/user/hive/warehouse/${database}.db/${table}/dt=${date}"
# 生成ready文件
${hadoop} fs -test -e $path 
if [ $? -ne 0 ];then
    ${hadoop} fs -touchz ${path}/ready.done
fi
note

