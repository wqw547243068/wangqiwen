--use log_rs;
-- test:  hive -f create.sql -hivevar path='.' -hivevar date=20140512 -hivevar date1=2014/05/12
-- 2014-7-8
--set mapred.max.map.failures.percent=5;
--set mapred.max.map.failures.percent=1;
--set mapred.output.compression.codec = org.apache.hadoop.io.compress.GzipCodec;
--set mapred.max.map.failures.percent = 30;
--LOAD DATA local INPATH '/home/lijun/bucket.txt' OVERWRITE INTO TABLE student partition(stat_date="20120802");
use smsrecall;
--[user_id name gender mobile_number operator group_id send_time provider status copywrite_name sms_parameters copywrite_content]
--user_id name gender mobile_number operator group_id send_time provider sms_parameters copywrite_name copywrite_content
--30706963  15127733369 mobile  俊俊  female  3 2017-07-27  10  real_like 5 2.5
create external table if not exists sms_recall_daily
  (
    user_id int comment 'user_id',
    name string comment 'user name',
    gender string comment 'user gender',
    mobile_number string comment 'phone number',
    operator string comment 'network operator,such as unicom,mobile,telecom and so on',
    group_id smallint comment 'group id',
    send_time string comment 'time of sending SMS',
    provider string comment 'channel for SMS sending',
    status string comment 'status for SMS sending,including limited values: send,error,done,control',
    copywrite_name string comment 'name of copywrite template',
    sms_parameters string comment 'the related number for SMS, json format',
    copywrite_content string comment 'content of copywrite'
  )partitioned by (dt string)
  row format delimited
      fields terminated by '\t'
      collection items terminated by '\002'
      map keys terminated by '\003'
  stored as textfile
  location "/user/wangqiwen/sms_recall/data/";
--alter table sms_recall_daily drop if exists partition (dt='${hivevar:date}');
alter table sms_recall_daily add if not exists partition(dt='${hivevar:date}') location '${hivevar:date}' ;
--LOAD DATA local INPATH '/home/lijun/bucket.txt' OVERWRITE INTO TABLE student partition(stat_date="20120802");
--drop table if exists sms_recall_send;
--create external table if not exists sms_recall_send
--  (
--    user_id int comment 'user_id',
--    mobile_number string comment 'phone number',
--    operator string comment 'network operator,such as unicom,mobile,telecom and so on',
--    name string comment 'user name',
--    gender string comment 'user gender',
--    group_id smallint comment 'group id',
--    send_time string comment 'time of sending SMS',
--    new_num int comment 'new num',
--    copywrite_name string comment 'name of copywrite template',
--    msg_num int comment 'msg num',
--    dist_num int comment 'dist num'
--  )partitioned by (dt string)
--  row format delimited
--      fields terminated by '\t'
--      collection items terminated by '\002'
--      map keys terminated by '\003'
--  stored as textfile
--  location "/user/wangqiwen/sms_recall/send/";
----alter table sms_recall_send drop if exists partition (dt='${hivevar:date}');
--alter table sms_recall_send add if not exists partition(dt='${hivevar:date}') location '${hivevar:date}' ;
--alter table sms_recall_send add if not exists partition(dt='${hivevar:date}') location "/user/wangqiwen/sms_recall/send/20170727" ;
