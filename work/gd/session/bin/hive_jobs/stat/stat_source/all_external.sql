--use log_rs;
-- test:  hive -f create_sp.sql -hivevar path='.' -hivevar date=20140523 -hivevar date1=2014/05/23 -hivevar date2=2014-05-23
-- 2014-7-8
--/*
--set mapred.max.map.failures.percent=1;
--set mapred.output.compression.codec = org.apache.hadoop.io.compress.GzipCodec;
--*/

set date;
set date1;
set date2;

use log_session;
-- log_sp_raw ---------
create external table if not exists log_sp_raw_flume
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
    location "/user/ops/flume/sp/sp_logger/";

--alter table log_sp_raw drop if exists partition (dt='${hivevar:date}');
alter table log_sp_raw_flume add if not exists partition(dt='${hivevar:date}') location '${hivevar:date1}';

-- log_sp_raw_old ---------
create external table if not exists log_sp_raw_ftp
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

alter table log_sp_raw_ftp add if not exists partition(dt='${hivevar:date}') location '${hivevar:date2}';



-- log_sug_raw ---------
--drop table if exists log_sug_raw;

create external table if not exists log_sug_raw_flume
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
alter table log_sug_raw_flume add if not exists partition (dt='${hivevar:date}') location '${hivevar:date1}';


-- log_sug_raw_old ---------
--drop table if exists log_sug_raw_old;
create external table if not exists log_sug_raw_ftp
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
    location "/user/ops/flume/sug/old/";
alter table log_sug_raw_ftp add if not exists partition (dt='${hivevar:date}') location '${hivevar:date}/${hivevar:date1}';

use log_data;
create table if not exists stat_source
	(
		source string,
		pv string
	)
    partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
    stored as textfile;
 
-- stat all info ---
insert overwrite table stat_source partition(dt='${hivevar:date}')
	select * from (
		select 'sp_flume' as source,count(*) as pv from log_session.log_sp_raw_flume where dt='${hivevar:date}'
		union all
		select 'sp_ftp' as source,count(*) as pv from log_session.log_sp_raw_ftp where dt='${hivevar:date}'
		union all
		select 'sug_flume' as source,count(*) as pv from log_session.log_sug_raw_flume where dt='${hivevar:date}'
		union all
		select 'sug_ftp' as source,count(*) as pv from log_session.log_sug_raw_ftp where dt='${hivevar:date}'
	)all_data;

select * from log_data.stat_source where dt='${hivevar:date}';
