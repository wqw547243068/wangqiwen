-- usage: hive -S --hivevar date1=2014/01/07 --hivevar date=20140107 -f load_aos_log.sql

use log_session;
add file ${hivevar:path}/mapper.py;
drop table if exists log_sptuan_raw_new;
create external table log_sptuan_raw_new (
	data_line string comment 'raw data from HDFS'
)
location "/user/ops/flume/sp/sp_tuan/${hivevar:date1}"; --2014/01/02

create external table log_sptuan_ali_raw (
	data_line string comment 'raw data from HDFS'
)
location "/user/ops/flume/sp_ali/sp_tuan/${hivevar:date1}"; --2014/01/02

create table if not exists log_sptuan  like log_sp;

alter table log_sptuan drop if exists partition (dt='${hivevar:date}');  --20140102
alter table log_sptuan add if not exists partition (dt='${hivevar:date}');

set mapred.max.map.failures.percent = 30;
set mapred.reduce.tasks= 50;
--set mapred.map.tasks= 100;
set mapred.output.compression.codec = org.apache.hadoop.io.compress.GzipCodec;

insert overwrite table log_sptuan  partition (dt='${hivevar:date}')
select transform(data_line)
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
    from 
	(
		select * from log_sptuan_raw_new 
		union all
		select * from log_sptuan_ali_raw
	)log_sptuan_tmp
    distribute by uid
    sort by uid,sessionid,cast(stepid as int),time;


---- drop temp table:
-- drop table if exists log_sptuan_raw;
