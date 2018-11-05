--use log_rs;
-- test:  hive -f create_sp.sql -hivevar path='.' -hivevar date=20140523 -hivevar date1=2014/05/23 -hivevar date2=2014-05-23
-- 2014-7-8
--set mapred.max.map.failures.percent=1;
set mapred.output.compression.codec = org.apache.hadoop.io.compress.GzipCodec;
set hive.exec.compress.output=true;
set mapred.output.compress=true;

use log_session;

add file ${hivevar:path}/mapper.py;
add file ${hivevar:path}/../../../tool/cifa.py;
add file ${hivevar:path}/../../../tool/func.py;
add file ${hivevar:path}/../../../tool/adcode.csv;
add file ${hivevar:path}/../../../tool/fanquery.txt;

create external table if not exists log_sp_raw_old
    (
        tm string comment 'raw data from HDFS',
        req map<string,string> comment 'request info',
        resp map<string,string> comment 'response info'
    )
    partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
        collection items terminated by '+'
        map keys terminated by ':'
    stored as textfile
    location "/user/ops/flume/sp/sp_logger/old/";

--    location "/user/ops/flume/sp/sp_logger/";
alter table log_sp_raw_old drop if exists partition (dt='${hivevar:date}');
alter table log_sp_raw_old add partition(dt='${hivevar:date}') location '${hivevar:date2}';
--alter table log_sp_raw_old add partition(dt='${hivevar:date}') location '${hivevar:date1}';

create table if not exists log_sp
    (
        uid string comment 'diu,imei,user_info. diu2,diu3 and etc stored in other',
        sessionid string comment 'sessionid',
        stepid string comment 'stepid',
        time string comment 'time info: 08:34:59',
        position map<string,string> comment 'user location: (user_loc) or (x,y)..',
        source string,
        action string comment 'type of actions in source',
        request map<string,string> comment 'request info',
        response map<string,string> comment 'response info',
        cellphone map<string,string> comment 'cellphone info',
        other map<string,string> comment  'other info from raw log'
    )
    partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
        collection items terminated by '\002' -- not \001
        map keys terminated by '\003'  -- not \002
    stored as rcfile;

--alter table log_sp drop if exists partition (dt='${hivevar:date}');
alter table log_sp add if not exists partition (dt='${hivevar:date}');

--insert  into table log_sp  partition (dt='${hivevar:date}')
insert  overwrite table log_sp  partition (dt='${hivevar:date}')
        select transform(*) 
	        using 'python mapper.py'
            as (
                    uid string,
                    sessionid string,
                    stepid string,
                    time string,
                    position map<string,string>,
                    source string,
                    action string,
                    request map<string,string>,
                    response map<string,string>,
                    cellphone map<string,string>,
                    other map<string,string>
                )
	        from log_sp_raw_old
            where dt='${hivevar:date}'
            distribute by uid
            sort by uid,sessionid,cast(stepid as int),time;
