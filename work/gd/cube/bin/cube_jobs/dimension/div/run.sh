source ../../conf/common.sh
[ $# -ge 1 ] && date=$1 || date=`date -d "1 days ago" +%Y%m%d`
#date +%Y-%m-%d-%a-%w -d '20140821'
echo -e "mysql -h${host} -u${user} -p${passwd}"
#--------create table--------------
# GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.17.128.82' IDENTIFIED BY 'root' WITH GRANT OPTION;   修复连接问题
# update user set password=password("root") where user="root"; 
mysql -h${host} -u${user} -p${passwd} < "create.sql"
check "create mysql table"
#-------load div_info------------
python load_div.py
#insert into div_info values('-','-','-','-');
:<<note
div='ANDH060600'
os="${div:0:3}";device="${div:3:1}";version="${div:4:6}"
tmp_sql="insert into $database.div_info values('${div}','${os}','${device}','${version}')"
mysql -h${host} -u${user} -p${passwd} -e "$tmp_sql"
check "update div_info" 0
note
