#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#            File:  start_job.sh [sp]
#           Usage:  
#     Description:  sp 日志处理的hadoop启动脚本
#    LastModified:
#         Created:  2014-3-3 16:54 PM
#          AUTHOR:  warren(warren@autonavi.com)
#         COMPANY:  autonavi
#===============================================================================

# 参数 /home/devuse/bin/hadoop/bin/hadoop /home/devuse/bin/hadoop/bin/hive /user/hive/warehouse/logamap.db/log_rc/dt=20140301/000000_0 log_sp ./ 20140301 start_20140301_log_sp 20140616
#:<<note
set -x
if [ $# -ne 8 ]; then
	echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [session-sp] input error ! \$#=$# not 8"
	exit -1
fi
hadoop=$1;hive=$2;input_ready=$3;jobname=$4;main_dir=$5;date=$6;task_prefix=$7;now=$8
#note

echo "参数($#):$*"
:<<note
hive="/opt/hadoop/CDH-4.2.1-1.cdh4.2.1.p0.5/bin/hive"
date='20140301'
note

database='log_session'
table='log_sp'
path="hive_jobs/log/$table"
sql="$path/create_sp.sql"
date1="${date:0:4}/${date:4:2}/${date:6:2}"

# 2014-11-10 warren,增加rgeo监控
#rgeo_url="http://10.17.130.89:8887/sisserver.php?query_type=RGEOCODE&x=116.3544845&y=39.98882653&poinum=10&range=200&roadlevel=0&pattern=0&ignorePoi=0&query_src=test&user_info=test"
rgeo_url="http://10.13.2.30:8887/sisserver.php?query_type=RGEOCODE&x=116.3544845&y=39.98882653&poinum=10&range=200&roadlevel=0&pattern=0&ignorePoi=0&query_src=test&user_info=test"
data="page.html"
curl -o $data "$rgeo_url"
if [ $? -ne 0 ];then
    echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] fail to connect to server ! exit ... url=[$rgeo_url]"
    exit -1
else
    echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] success to connect to server ... url=[$rgeo_url]"
fi
result=`cat $data | awk '{if($0~/citycode>[0-9]+<\/citycode/)print "Y"}'`  
echo "result=$result"
if [ "$result" == "Y" ];then
    echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] rgeo info normal (citycode)"
else
    echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] rgeo info illegal (no citycode),exit !"
    exit -1
fi
rm $data
echo "rm $data"

# 启动hive任务
${hive} -hivevar path=$path -hivevar date=$date -hivevar date1=$date1  -f $sql
if [ $? -ne 0 ];then
    echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [sp] Fail to execute hive job !"
    exit -1
else
    echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] [sp] Success to execute hive job !"
fi

:<<note
path="/user/hive/warehouse/${database}.db/${table}/dt=${date}"
# 生成ready文件
${hadoop} fs -test -e $path 
if [ $? -ne 0 ];then
    ${hadoop} fs -touchz ${path}/ready.done
fi
note

