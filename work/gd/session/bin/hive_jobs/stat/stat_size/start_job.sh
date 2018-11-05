#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#            File:  start_job.sh [stat_size]
#           Usage:  
#     Description:  stat_size表启动程序
#    LastModified:
#         Created:  2014-6-12 16:40 PM
# 
#          AUTHOR:  warren(warren@autonavi.com)
#         COMPANY:  autonavi
#         VERSION:  1.0
#            NOTE:  
#           input:  
#          output:  
#===============================================================================

#7个参数 /home/devuse/bin/hadoop/bin/hadoop /home/devuse/bin/hadoop/bin/hive /user/hive/warehouse/logamap.db/log_rc/dt=20140301/000000_0 log_sp ./ 20140301 start_20140301_log_sp 20140621
#:<<note
set -x
if [ $# -ne 8 ]; then
	echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [stat_size] input error ! \$#=$# not 8"
	exit -1
fi
hadoop=$1;hive=$2;input_ready=$3;jobname=$4;main_dir=$5;date=$6;task_prefix=$7;now=$8
#note

echo "参数($#):$*"
:<<note
jobname='stat_size'
hadoop="/home/devuse/bin/hadoop/bin/hadoop"
hive="/home/devuse/bin/hadoop/bin/hive"
date='20140602'
note

table='stat_size'
#path='.'
path="$main_dir/hive_jobs/stat/$table"
out_file="$path/data_size.txt"
sql="$path/create_stat_size.sql"
date1="${date:0:4}/${date:4:2}/${date:6:2}"

# 待检测数据源: source raw_path log_path
data_arr=( 
	"sp|/user/ops/flume/sp/sp_logger/$date1|/user/hive/warehouse/log_session.db/log_sp/dt=$date"	
	"sug|/user/ops/flume/sug/$date1|/user/hive/warehouse/log_session.db/log_sug/dt=$date"	
	"aos|/user/ops/flume/aos/$date1|/user/hive/warehouse/log_session.db/log_aos/dt=$date"	
	"client|/user/amap/data/mysql/bi/ods/page/ods_page_pagelog/$date1|/user/hive/warehouse/log_session.db/log_client/dt=$date"	
 )
out=''
for i in ${data_arr[@]}
do	
	i_arr=( ${i//|/ } )  # 按|分隔成数组: 	source_name raw_path log_path
	source_name=${i_arr[0]};raw_path=${i_arr[1]};log_path=${i_arr[2]}	
	raw_size=`$hadoop fs -ls $raw_path | awk '{a+=$5}END{print a/(1024.**3)}'`
	log_size=`$hadoop fs -ls $log_path | awk '{a+=$5}END{print a/(1024.**3)}'`
	#eval "path=\$${t}_dir/\$name"	echo "path=$path"	
	out="$out\n$source_name\t$raw_size\t$log_size"
done
echo -e "$out" |awk -F'\t' '{if(NF<2)next;else print}'| tee > $out_file
echo "out_file=$out_file"
#:<<note
# 启动hive任务
#$hive -hivevar out_path=${out_file%/*} -hivevar date=$date -f $sql
$hive -hivevar file=${out_file} -hivevar date=$date -f $sql
if [ $? -ne 0 ];then
    echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] Fail to execute hive job !"
    exit -1
else
    echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] Success to execute hive job !"
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

