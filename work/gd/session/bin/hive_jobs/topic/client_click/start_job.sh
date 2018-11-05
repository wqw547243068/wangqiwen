#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#            File:  start_job.sh [sp]
#           Usage:  
#     Description:  query_click表启动程序
#    LastModified:
#         Created:  2014-6-3 14:46 PM
#          AUTHOR:  warren(warren@autonavi.com)
#===============================================================================

#8个参数 /home/devuse/bin/hadoop/bin/hadoop /home/devuse/bin/hadoop/bin/hive /user/hive/warehouse/logamap.db/log_rc/dt=20140301/000000_0 log_sp ./ 20140301 start_20140301_log_sp 20140616
#:<<note
set -x
if [ $# -ne 8 ]; then
	echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [query_click] input error ! \$#=$# not 8"
	exit -1
fi
hadoop=$1;hive=$2;input_ready=$3;jobname=$4;main_dir=$5;date=$6;task_prefix=$7;now=$8
#note

function exitOnRet()
{
    if [ $1 -ne 0 ];then
        echo "[ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [sp] Fail to execute hive job !"
        exit -1
    else
        echo "[INFO] [`date "+%Y-%m-%d %H:%M:%S"`] [sp] Success to execute hive job !"
    fi
}


echo "参数($#):$*"

database='log_session'
table='client_click'
path="hive_jobs/topic/$table"

sql1="$path/decrypt_dxp_client.sql"
sql2="$path/combine_click.sql"
sql3="$path/last_step.sql"


enddate=$date
startdate=`date +%Y%m%d -d "-2 day $date"`

clientdate=$startdate

date1="${date:0:4}/${date:4:2}/${date:6:2}"
# 启动hive任务
${hive} -hivevar path=$path -hivevar date=$date  -hivevar date1=${date:0:4}/${date:4:2}/${date:6:2} -f $sql1
exitOnRet $? 

${hive} -hivevar path=$path -hivevar date=$clientdate -hivevar startdate=${startdate} -hivevar enddate=${enddate} -hivevar date1=${date:0:4}/${date:4:2}/${date:6:2} -f $sql2 
exitOnRet $? 

${hive} -hivevar path=$path -hivevar date=$clientdate -hivevar date1=${date:0:4}/${date:4:2}/${date:6:2} -f $sql3
exitOnRet $? 


#${hive} -hivevar path=$path -hivevar date=$date -hivevar date1=$date1  -f $sql3

