#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#     Description:  度量表调度程序
#         Created:  2014-9-22 18:00 PM
#          AUTHOR:  warren(warren@autonavi.com)
#    LastModified: 
#===============================================================================

# 参数 /home/devuse/bin/hadoop/bin/hadoop /home/devuse/bin/hadoop/bin/hive /user/hive/warehouse/logamap.db/log_rc/dt=20140301/000000_0 log_sp ./ 20140301 start_20140301_log_sp 20140621
#:<<note
#set -x
if [ $# -ne 8 ]; then
	echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [cube_log_sug] input error ! \$#=$# not 8"
	exit -1
fi
hadoop=$1;hive=$2;input_ready=$3;jobname=$4;main_dir=$5;date=$6;task_prefix=$7;now=$8
cur_dir="${main_dir}/cube_jobs/measure/log_sug"
#note
:<<note
cur_dir='.'
[ $# -ge 1 ] && date=$1 || date=`date -d "1 days ago" +%Y%m%d`
hive='/opt/bin/hadoop/bin/hive'
main_dir='/home/devuse/warren/svn/cube/bin'
note


#echo $main_dir


mysql_table='log_sug_stat'
#mysql -h127.0.0.1 -uroot -proot < create.sql
# mysql -h127.0.0.1 -uroot -proot test
source ${cur_dir}/../../../conf/common.sh
#echo ${cur_dir}

#date +%Y-%m-%d-%a-%w -d '20140821'
echo -e "mysql -h${host} -u${user} -p${passwd}"
#--------create table--------------
# GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.17.128.82' IDENTIFIED BY 'root' WITH GRANT OPTION;   修复连接问题
# GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.13.2.30' IDENTIFIED BY 'root' WITH GRANT OPTION;   修复连接问题
# update user set password=password("root") where user="root";  10.17.129.55
# mysql -h10.17.129.55 -uroot -proot
mysql -h${host} -u${user} -p${passwd} < "${cur_dir}/sql/create.sql"
check "create mysql table"
#--------get data------------------
#sudo -u devuse /opt/bin/hadoop/bin/hive -f query_click_stat.sql -hiveconf date=20140824 >d.txt
sql_file="${cur_dir}/sql/stat_log_sug.sql"
data_file="${main_dir}/../data/$now/data_${jobname}_$date.txt"
#echo $data_file
#echo 'sql file :'
#echo $sql_file
if [ ! -f $data_file ];then
   # echo -e "${hive} -f ${sql_file} -hivevar date=${date} > ${data_file}"
    $hive -f $sql_file -hivevar date=$date > $data_file
    check "get hive data" 1 # 执行失败时退出
fi
#-------load log_sp_data------------
# 清除当天已有数据
mysql -h${host} -u${user} -p${passwd} -e "use cube;delete from $mysql_table where date=$date"
check "delete old data : $mysql_table,$date"
python ${cur_dir}/../../../tool/load2MySQL.py -n 21 -t $mysql_table -f $data_file  
check "load $jobname data"
