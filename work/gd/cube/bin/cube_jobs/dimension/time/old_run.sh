#mysql -h127.0.0.1 -uroot -proot < create.sql
# mysql -h127.0.0.1 -uroot -proot test
source ../../../conf/common.sh

[ $# -ge 1 ] && date=$1 || date=`date -d "1 days ago" +%Y%m%d`

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
        cur_week=`date +%A -d $cur_date`
        cur_quarter=`expr $cur_month / 3 + 1`
        log INFO "第$i天:$cur_date"
        tmp_sql="insert into ${database}.time_info values('${cur_date}','${cur_year}','${cur_quarter}','${cur_month}','${cur_day}','${cur_week}')"
        mysql -h${host} -u${user} -p${passwd} -e "$tmp_sql"
    ((i++))
    done
}

#echo -e "mysql -h${host} -u${user} -p${passwd}"
#--------create table--------------
# GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.17.128.82' IDENTIFIED BY 'root' WITH GRANT OPTION;   修复连接问题
# update user set password=password("root") where user="root"; 
mysql -h${host} -u${user} -p${passwd} < "create.sql"
check "create mysql table"
#exit -1
#-------update time_info---------
#update_time $date 60  # 批量插入日期
update_time $date 1
check "create mysql table" 0

