#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#            File:  start_job.sh [stat_source]
#           Usage:  
#     Description:  stat_source
#    LastModified:
#         Created:  2014-10-14 18:00 PM
#          AUTHOR:  (warren@autonavi.com)
#===============================================================================

# 8: /home/devuse/bin/hadoop/bin/hadoop /home/devuse/bin/hadoop/bin/hive /user/hive/warehouse/logamap.db/log_rc/dt=20140301/000000_0 log_sp ./ 20140301 start_20140301_log_sp 20140616
#:<<note
set -x
if [ $# -ne 8 ]; then
	echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [$0] input error ! \$#=$# not 8"
	exit -1
fi
hadoop=$1;hive=$2;input_ready=$3;jobname=$4;main_dir=$5;date=$6;task_prefix=$7;now=$8
#note

echo "args:($#):$*"
:<<note
#hive="/home/devuse/bin/hadoop/bin/hive"
hive="/data/soft/hadoop2/hive/bin/hive"
date='20141010'
now="20141014"
main_dir='../../../'
jobname="stat_source"
note

database='log_session'
table='stat_source'

path="hive_jobs/stat/$table"
#path="./"

sql="$path/all_external.sql"
date1="${date:0:4}/${date:4:2}/${date:6:2}"
date2="${date1//\//-}"
echo -e "date=$date\tdate1=$date1\tdate2=$date2"
data="$main_dir/../data/$now/source_$date.txt"
# start hive job
${hive} -hivevar path=$path -hivevar date=$date -hivevar date1=$date1 -hivevar date2=$date2 -f $sql  > $data
if [ $? -ne 0 ];then
    echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] Fail to execute hive job !"
    exit -1
else
    echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] Success to execute hive job !"
fi
#hostname="10.17.128.82:8200"
hostname="logdata.amap.com"
out=`cat $data | awk '{if(NF<3)next;else{a=a"|"$1","$2","$3}}END{print a}'`
#curl -X POST --data @data.txt  http://10.19.1.52/rest/api/2/issue/
curl -X POST --data "data=$out"  http://$hostname/index.php/logdata/dataAPI/monitorData

:<<note
path="/user/hive/warehouse/${database}.db/${table}/dt=${date}"
# generate ready file
${hadoop} fs -test -e $path 
if [ $? -ne 0 ];then
    ${hadoop} fs -touchz ${path}/ready.done
fi
note

