set mapred.max.map.failures.percent=1;
set mapred.output.compression.codec = org.apache.hadoop.io.compress.GzipCodec;
set hive.exec.dynamic.partition.mode=nonstrict;
set mapred.reduce.child.java.opts=-Xmx10737418240;



set encrypt_table=bak_log_client_encrypt;
use log_session;



add file ${hivevar:path}/../../../tool/page-button/page-button.json;
add jar  ${hivevar:path}/../../log/log_client/libs/PageDecoder-0.0.1-SNAPSHOT.jar;
add jar  ${hivevar:path}/../../log/log_client/libs/hive-plugins-0.0.1-SNAPSHOT.jar;



create external table if not exists ${hiveconf:encrypt_table}
    (
        data_line string comment 'raw data from HDFS'
    )
    partitioned by (dt string)
    location '/user/ops/flume/aos_page/aos_page_dxp';

alter table  ${hiveconf:encrypt_table} drop partition(dt='${hivevar:date}');
alter table  ${hiveconf:encrypt_table} add partition(dt='${hivevar:date}') location '${hivevar:date1}';

--
--

create table if not exists log_client_decrypt
    (
	   uid string, 
	   sessionid string ,
	   --clicks string , 
	   clicks array< struct <
                                stepid:string, page:string, button:string, source:string, service:string,
							    action:string, acttime:string,
								position:map<string, string>,
                                paras:map<string,string>
                            >
                   > comment 'all clicks in one session' ,
	   others string comment 'version:protocal:diu2:diu3:dic:model:device:manufacturer',
	   act_date string 
    )
    partitioned by (dt string)
    stored as rcfile;

--create index sessionid_index on table log_client_decrypt(sessionid) as 'COMPACT' WITH DEFERRED REBUILD;
create temporary  function decrypt_client as 'com.autonavi.data.client.SimpleDecryptClientLog';

--insert overwrite directory '/tmp/zhuhuo/decryptlog'
alter table log_client_decrypt drop if exists partition (dt='${hivevar:date}');
insert overwrite table log_client_decrypt partition (dt='${hivevar:date}') 
    select decrypt_client(data_line) as (uid, sessionid, clicks, others, act_date) from ${hiveconf:encrypt_table} where dt = '${hivevar:date}';


