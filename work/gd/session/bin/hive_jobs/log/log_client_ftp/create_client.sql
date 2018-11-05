-- 2014-7-8
--set mapred.max.map.failures.percent=1;
set mapred.output.compression.codec = org.apache.hadoop.io.compress.GzipCodec;
set hive.exec.compress.output=true;
set mapred.output.compress=true;

use log_session;

add file ${hivevar:path}/../../../tool/page-button/page-button.json;
add file ${hivevar:path}/../../../tool/func.py;
add file ${hivevar:path}/mapper.py;

create external table if not exists log_client_raw_old
    (
        data_line string comment 'raw data from HDFS'
    )
    partitioned by (dt string)
    location "/user/amap/data/mysql/bi/ods/page/ods_page_pagelog/";
-- /user/ops/flume/aos_page

alter table log_client_raw_old drop if exists partition (dt='${hivevar:date}');
alter table log_client_raw_old add partition(dt='${hivevar:date}') location '${hivevar:date1}';


create table if not exists log_client like log_sp;

--alter table log_client drop if exists partition (dt='${hivevar:date}');
alter table log_client add if not exists partition (dt='${hivevar:date}');

insert overwrite table log_client  partition (dt='${hivevar:date}')
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
	        from log_client_raw_old
            where dt='${hivevar:date}'
            distribute by uid
            sort by uid,sessionid,cast(stepid as int),time;
