#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#            File:  start_job.sh [sug]
#           Usage:  
#     Description:  客户端离线日志处理的hadoop启动脚本
#    LastModified:  2014-9-19 MR转码后,导入hive 
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
#path="hive_jobs/log/$table" # online
#note


echo "参数($#):$*"
:<<note
#hive="/home/devuse/bin/hadoop/bin/hive"
hive="/data/soft/hadoop2/hive/bin/hive"
date='20141025'
#[ $# -ge 1 ] && date=$1 || date=`date -d "1 days ago" +%Y%m%d`
path="." # test
jobname="sug-transcode"
#hadoop="/home/devuse/bin/hadoop/bin/hadoop"
hadoop="/opt/cloudera/parcels/CDH-4.2.1-1.cdh4.2.1.p0.5/bin/hadoop"
note

sql="$path/transcode_create_sug.sql"
date1="${date:0:4}/${date:4:2}/${date:6:2}"
date2="${date:0:4}-${date:4:2}-${date:6:2}"
echo -e "[$0] [NOTE] [`date "+%Y-%m-%d %H:%M:%S"`] date=$date\tdate1=$date1\tdate2=$date2"
conf_file="$path/../../../tool/func.py"
chardet_file="$path/../../../tool/chardet.zip"
#conf_file2="$path/../../../tool/fanquery.txt"
#conf_file3="$path/../../../tool/adcode.csv"
mapper_file="$path/mapper.py"
#mapper_file="$path/mapper.py"
# =============== 2014-9-18 提前转码 ================
hadoop_home="${hadoop%/bin/hadoop}"
#input="/user/ops/flume/sp/sp_logger/old/${date2}"
input="/user/ops/flume/sug/old/${date}/${date1}"
input2="/user/ops/flume/sug_ali/${date1}"
output="/user/devuse/warren/sug/$date/0000"
map_con_num="100"
reduce_num="100"

echo "=========================$jobname start ============================="
done_file="${output%/*}/${output##*/}.done"
${hadoop} fs -test -e ${output} && ${hadoop} fs -rmr ${output}
${hadoop} fs -test -e ${done_file} && ${hadoop} fs -rm ${done_file}
echo "[$0] [NOTE] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] start to commit hadoop job"
#${hadoop} streaming \
#${hadoop} jar ${hadoop_home}/lib/hadoop-mapreduce/hadoop-streaming.jar \
#${hadoop} --config /root/ShuBeiCONF/ jar ${hadoop_home}/lib/hadoop-0.20-mapreduce/contrib/streaming/hadoop-streaming-2.0.0-mr1-cdh4.2.1.jar \
${hadoop} jar ${hadoop_home}/lib/hadoop-0.20-mapreduce/contrib/streaming/hadoop-streaming-2.0.0-mr1-cdh4.2.1.jar \
		-jobconf mapred.job.name="$jobname" \
		-jobconf mapred.job.priority=HIGH \
		-jobconf mapred.map.tasks=$map_con_num \
		-jobconf mapred.reduce.tasks=$reduce_num \
		-jobconf mapred.job.map.capacity=$map_con_num -jobconf mapred.job.reduce.capacity=$reduce_num \
		-jobconf mapred.map.max.attempts=10 -jobconf mapred.reduce.max.attempts=10 \
        -file $chardet_file \
        -file $conf_file \
		-file $mapper_file \
		-output ${output} \
		-input ${input} \
		-input ${input2} \
		-mapper "python mapper.py" \
		-reducer "cat"

#		-mapper "python m.py" \
#        -cacheArchive /user/devuse/warren/tool/chardet.tar.gz#chardet\
if [ $? -ne 0 ];then
    echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [sug] Fail to execute MR job !"
    exit -1
else
    echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] [sug] Success to execute MR job !"
fi

#		-jobconf stream.num.map.output.key.fields=2 \
#		-jobconf num.key.fields.for.partition=1 \
#		-partitioner org.apache.hadoop.mapred.lib.KeyFieldBasedPartitioner \

# create ready file
${hadoop} fs -touchz ${done_file}
echo "=========================$jobname end ============================="
#load data inpath $output overwrite into table log_sug partition (dt=)
#LOAD DATA LOCAL INPATH '/home/hadoop/login_array.txt' OVERWRITE INTO TABLE login_array PARTITION (dt='20130101');
# ---------- load data to hive table ------------------
#:<<note
echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] [sug] Start to load data to hive(log_sug) !"
$hive -hivevar path=$path -hivevar date="$date" -hivevar date1="$date1" -f $sql
if [ $? -ne 0 ];then
    echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [sug] Fail to execute hive job !"
    exit -1
else
    echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] [sug] Success to execute hive job !"
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

echo "[$0] [NOTE] [`date "+%Y-%m-%d %H:%M:%S"`] [$jobname] hadoop job finished"
