#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#     Description:  度量表调度程序
#         Created:  2014-9-2 13:01 PM
#          AUTHOR:  warren(warren@autonavi.com)
#    LastModified: 
#===============================================================================

# 参数 /home/devuse/bin/hadoop/bin/hadoop /home/devuse/bin/hadoop/bin/hive /user/hive/warehouse/logamap.db/log_rc/dt=20140301/000000_0 log_sp ./ 20140301 start_20140301_log_sp 20140621
#:<<note
#set -x
if [ $# -ne 8 ]; then
	echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] [cube_no_result] input error ! \$#=$# not 8"
	exit -1
fi
hadoop=$1;hive=$2;input_ready=$3;jobname=$4;main_dir=$5;date=$6;task_prefix=$7;now=$8
cur_dir="${main_dir}/cube_jobs/measure/no_result"
#note
:<<note
cur_dir='.'
[ $# -ge 1 ] && date=$1 || date=`date -d "1 days ago" +%Y%m%d`
hive='/opt/bin/hadoop/bin/hive'
main_dir='/home/devuse/warren/svn/cube/bin'
note

mysql_table='no_result_stat'
#mysql -h127.0.0.1 -uroot -proot < create.sql
# mysql -h127.0.0.1 -uroot -proot test
source ${cur_dir}/../../../conf/common.sh
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
sql_file="${cur_dir}/sql/stat_no_result.sql"
get_data_file="${cur_dir}/sql/get_no_result_data.sql"
filter_file="${cur_dir}/filter.py"
data_file="${main_dir}/../data/$now/data_${jobname}_$date.txt"
source_data_file="${main_dir}/../data/$now/source_data_${jobname}_$date.txt"
filter_data_file="${main_dir}/../data/$now/filter_data_${jobname}_$date.txt"

#导出数据
if [ ! -f $source_data_file ];then
    $hive -f $get_data_file -hivevar date=$date > $source_data_file
    check "get hive data file $source_data_file $cur_dir" 1 # 执行失败时退出
else
	echo "$source_data_file  is exists"
fi

#过滤数据
if [ -f $filter_data_file ];then
	echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] 过滤后的文件($filter_data_file)已存在，跳过"
else
    cat $source_data_file | python $filter_file $cur_dir> $filter_data_file
	check "data filter to $filter_data_file" 1  # 执行出错时退出
fi


#导入数据到log_cube并导出到文件
if [ ! -f $data_file ];then
    $hive -f $sql_file -hivevar date=$date -hivevar path=$filter_data_file > $data_file
    check "get hive data" 1 # 执行失败时退出
else
    echo "$data_file 已存在，路过导入数据到log_cube"
fi
#-------load data------------
# 清除当天已有数据 
mysql -h${host} -u${user} -p${passwd} -e "use cube;delete from $mysql_table where date=$date"
check "delete old data : $mysql_table,$date"
#mysql -h${host} -u${user} -p${passwd} -e "load data local infile ${data_file} into table no_res_stat"
python ${cur_dir}/../../../tool/load2MySQL.py -n 11 -t $mysql_table -f $data_file
check "load data $mysql_table"
