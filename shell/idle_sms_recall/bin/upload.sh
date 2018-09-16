source ../conf/pg_conf.sh
doneFile="`pwd`/../data/20170601/doneUser.txt "
echo "doneFile=$doneFile"
psql << SQL
    create table if not exists wqw.sms_recall_done
    (
      phone character varying(20) not null,
      name character varying(50),
      time timestamp without time zone,
      cwname character varying(50),
      gender character varying(10),
      cwcontent character varying(200),
      primary key (phone,time)
    ); 
    \copy wqw.sms_recall_done FROM '$doneFile'
SQL
#\copy  wqw.sms_recall_done from '/home/wangqiwen/online/bin/../data/20170601/doneUser.txt';

