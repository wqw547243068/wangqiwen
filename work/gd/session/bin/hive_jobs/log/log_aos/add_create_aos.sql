-- usage: hive -hivevar date1=2014/06/11 -hivevar date=20140611 -hivevar path=. -f create_aos.sql
-- 2014-7-8
--set mapred.max.map.failures.percent=1;
set mapred.output.compression.codec = org.apache.hadoop.io.compress.GzipCodec;
set mapred.max.map.failures.percent = 30;
--set mapred.map.max.attempts = 1;
use log_session;

add file ${hivevar:path}/mapper.py;
add file ${hivevar:path}/../../../tool/aos.txt;
add file ${hivevar:path}/../../../tool/func.py;
add file ${hivevar:path}/../../../tool/xy2ccode.py;
add file ${hivevar:path}/../../../tool/xy2city.txt;
add file ${hivevar:path}/../../../tool/adcode.csv;

create external table if not exists log_aos_old2_raw
    (
        line string comment 'raw data from HDFS'
    )
    partitioned by (dt string)
    location "/user/ops/flume/aos/old/";

create external table if not exists log_sns_raw
    (
        line string comment 'raw data from HDFS'
    )
    partitioned by (dt string)
    location "/user/ops/flume/aos_sns/";

alter table log_aos_old2_raw drop if exists partition (dt='${hivevar:date}');
alter table log_aos_old2_raw add partition(dt='${hivevar:date}') location '${hivevar:date2}';

alter table log_sns_raw drop if exists partition (dt='${hivevar:date}');
alter table log_sns_raw add partition(dt='${hivevar:date}') location '${hivevar:date1}';
create table if not exists log_aos  like log_sp;

alter table log_aos drop if exists partition (dt='${hivevar:date}');  --20140102
alter table log_aos add if not exists partition (dt='${hivevar:date}');

insert overwrite table log_aos  partition (dt='${hivevar:date}')
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
    from 
    (   
        select * from log_aos_old2_raw where dt='${hivevar:date}' union all 
        select * from log_sns_raw where dt='${hivevar:date}'
    )log_aos_raw
    distribute by uid 
    sort by uid,sessionid,cast(stepid as int),time;


