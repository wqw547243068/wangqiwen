set mapred.max.map.failures.percent=50;
set mapred.output.compression.codec = org.apache.hadoop.io.compress.GzipCodec;
set hive.exec.dynamic.partition.mode=nonstrict;
set hive.exec.compress.output=true;
set mapred.output.compress=true;

use log_session;

add jar ${hivevar:path}/libs/PageDecoder-0.0.1-SNAPSHOT.jar;
add jar ${hivevar:path}/libs/hive-plugins-0.0.2-SNAPSHOT.jar;
add file ${hivevar:path}/../../../tool/page-button/page-button.json;
add file ${hivevar:path}/../../../tool/xy2city.txt;

create external table if not exists log_client_flume_raw
    (
        data_line string comment 'raw data from HDFS'
    )
partitioned by (dt string)
location "/user/ops/flume/aos_page";


alter table log_client_flume_raw drop if exists partition (dt='${hivevar:date}');
alter table log_client_flume_raw add partition(dt='${hivevar:date}') location '${hivevar:date1}';

--create table if not exists log_client like log_client;
create table if not exists log_client like log_sp;


alter table log_client drop if exists partition (dt='${hivevar:date}');

create temporary  function decrypt_client as 'com.autonavi.data.client.DecryptClientLog';

--insert overwrite directory '/tmp/zhuhuo/decryptlog'
--alter table log_client_zhuhuo drop if exists partition (dt='${hivevar:date}');
insert overwrite table log_client partition (dt='${hivevar:date}')
select decrypt_client(data_line) as (uid, sessionid, stepid, time, position, source, action, request, response, cellphone, others) from  log_client_flume_raw where dt = '${hivevar:date}';


