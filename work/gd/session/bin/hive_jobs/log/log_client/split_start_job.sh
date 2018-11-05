#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#            File:  start_job.sh [split_client]
#     Description:  客户端离线日志处理的hadoop启动脚本
#         Created:  2014-6-21 08:11 AM
#          AUTHOR:  warren(warren@autonavi.com)
#         COMPANY:  autonavi
#===============================================================================

#8个参数 /home/devuse/bin/hadoop/bin/hadoop /home/devuse/bin/hadoop/bin/hive /user/hive/warehouse/logamap.db/log_rc/dt=20140301/000000_0 log_sp ./ 20140301 start_20140301_log_sp 20140616
#:<<note
set -x
if [ $# -ne 8 ]; then
	echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [split_client] input error ! \$#=$# not 8"
	exit -1
fi
hadoop=$1;hive=$2;input_ready=$3;jobname=$4;main_dir=$5;date=$6;task_prefix=$7;now=$8
#note

echo "参数($#):$*"
:<<note
hive="/home/devuse/bin/hadoop/bin/hive"
date='20140619'
main_dir='.'
jobname='split_client'
note

database='log_session'
table='log_client_rest'
path="hive_jobs/log/log_client"
#path="."
date1="${date:0:4}/${date:4:2}/${date:6:2}"
# 2014-6-17 将client日志分发移动到client日志流
# client单独处理---多路输出
#:<<note
client_sql="$path/split_client.sql"
date_num='6' # 客户端日志回传天数---前一周(6)  96%
date_str=`date -d "1 days ago $date" +%Y%m%d`
for((i=2;i<=$date_num;i++))
do
    #cur_date=`date -d "$i days ago" +%Y%m%d`
    cur_date=`date -d "$i days ago $date" +%Y%m%d` # 2014-6-5 回传日志天数未生效，只有两天,修复bug
    date_str="$date_str,$cur_date"
done
echo -e "date=$date,date_str=$date_str"
${hive} -hivevar date="$date" -hivevar date_str="$date_str" -f $client_sql
if [ $? -ne 0 ];then
    echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] Fail to execute hive job (log_client_all) !"
    exit -1
else
    echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] Success to execute hive job (log_client_all) !"
fi
#note


:<<note
path="/user/hive/warehouse/${database}.db/${table}/dt=${date}"
# 生成ready文件
${hadoop} fs -test -e $path 
if [ $? -ne 0 ];then
    ${hadoop} fs -touchz ${path}/ready.done
fi
note

