--hive -f create_sug.sql -hivevar path=. -hivevar date=20140521 -hivevar date1=2014/05/21

use log_session;
set date;
set date1;
-- 2014-7-8
--set mapred.max.map.failures.percent=1;
set mapred.output.compression.codec = org.apache.hadoop.io.compress.GzipCodec;
set mapred.max.map.failures.percent = 30;
set hive.exec.compress.output=true;
set mapred.output.compress=true;

add file ${hivevar:path}/../../../tool/func.py;
add file ${hivevar:path}/mapper.py;

--drop table if exists log_sug_raw;
create external table if not exists log_sug_raw
    (
        time string,
        log_server string,
        tid string,
        type string comment 'hive',
        sysinfo string,
        req1 string,
        req2 string,
        resp string
    )
    partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
    stored as textfile
    location "/user/ops/flume/sug/";

--alter table log_sug_raw drop if exists partition (dt='${hivevar:date}');
alter table log_sug_raw add if not exists partition (dt='${hivevar:date}') location '${hivevar:date1}';


create table if not exists log_sug like log_sp;

--alter table log_sug drop if exists partition (dt='${hivevar:date}');
alter table log_sug add if not exists partition (dt='${hivevar:date}');

insert overwrite table log_sug  partition (dt='${hivevar:date}')
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
	        from log_sug_raw
            where dt='${hivevar:date}'
            distribute by uid
            sort by uid,sessionid,cast(stepid as int),time;
