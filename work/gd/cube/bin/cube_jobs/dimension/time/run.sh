#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#     Description:  维度表(time)调度程序
#         Created:  2014-8-30 22:50 PM
#          AUTHOR:  warren(warren@autonavi.com)
#    LastModified: 
#===============================================================================

# 参数 /home/devuse/bin/hadoop/bin/hadoop /home/devuse/bin/hadoop/bin/hive /user/hive/warehouse/logamap.db/log_rc/dt=20140301/000000_0 log_sp ./ 20140301 start_20140301_log_sp 20140621
#:<<note
#set -x
if [ $# -ne 8 ]; then
	echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [time] input error ! \$#=$# not 8"
	exit -1
fi
hadoop=$1;hive=$2;input_ready=$3;jobname=$4;main_dir=$5;date=$6;task_prefix=$7;now=$8
cur_dir="${main_dir}/cube_jobs/dimension/time"
#note

:<<note
cur_dir='.'
[ $# -ge 1 ] && date=$1 || date=`date -d "1 days ago" +%Y%m%d`
note

#mysql -h127.0.0.1 -uroot -proot < create.sql
# mysql -h127.0.0.1 -uroot -proot test
source ${cur_dir}/../../../conf/common.sh
#--------create table--------------
# GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.17.128.82' IDENTIFIED BY 'root' WITH GRANT OPTION;   修复连接问题
# GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.13.2.30' IDENTIFIED BY 'root' WITH GRANT OPTION;   修复连接问题
# update user set password=password("root") where user="root";  10.17.129.55

update_time(){
    # usage: update_time 20140822 4 ----插入20140822以前的4天数据信息
    local tmp_d=$1;
    local n=`expr $2 - 1`;
    local i=0;
    while [ $i -le $n ]
    do
        cur_date=`date -d "${i} days ago $tmp_d" +%Y%m%d`
        cur_year="${cur_date:0:4}"
        cur_month="${cur_date:4:2}"
        cur_day="${cur_date:6:2}"
        cur_week0=`date +%w -d $cur_date` # 2014-8-30 %A失效
        cur_week=`expr $cur_week0 + 1`
        #cur_week=`date +%A -d $cur_date`
        cur_quarter=`expr $cur_month / 3 + 1`
        log INFO "第$i天:$cur_date"
        tmp_sql="insert into ${database}.time_info values('${cur_date}','${cur_year}','${cur_quarter}','${cur_month}','${cur_day}','${cur_week}')"
        log INFO "执行sql命令:[$tmp_sql]"
        mysql -h${host} -u${user} -p${passwd} -e "$tmp_sql"
    ((i++))
    done
}

#echo -e "mysql -h${host} -u${user} -p${passwd}"
#--------create table--------------
# GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.17.128.82' IDENTIFIED BY 'root' WITH GRANT OPTION;   修复连接问题
# update user set password=password("root") where user="root"; 
sql_file="${cur_dir}/create.sql"
mysql -h${host} -u${user} -p${passwd} < $sql_file
check "create mysql table"
#exit -1
#-------update time_info---------
#pdate_time $date 60  # 批量插入日期
update_time $date 1
check "create mysql table" 0

