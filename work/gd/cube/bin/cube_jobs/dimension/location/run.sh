#mysql -h127.0.0.1 -uroot -proot < create.sql
# mysql -h127.0.0.1 -uroot -proot test
source ../../../conf/common.sh
[ $# -ge 1 ] && date=$1 || date=`date -d "1 days ago" +%Y%m%d`
#--------create table--------------
# GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.17.128.82' IDENTIFIED BY 'root' WITH GRANT OPTION;   修复连接问题
# update user set password=password("root") where user="root"; 
mysql -h${host} -u${user} -p${passwd} < "create.sql"
check "create mysql table"
#-------load location_info-------
python load_location.py
check "load_location_info" 0

