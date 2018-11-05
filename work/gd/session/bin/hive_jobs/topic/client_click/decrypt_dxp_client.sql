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
    partitioned by (dt string, hour string, min string)
    location '/user/ops/flume/aos_page/aos_page_dxp';

alter table  ${hiveconf:encrypt_table} drop partition(dt='${hivevar:date}');
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='00',min='00') location '${hivevar:date1}/00/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='00',min='15') location '${hivevar:date1}/00/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='00',min='30') location '${hivevar:date1}/00/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='00',min='45') location '${hivevar:date1}/00/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='01',min='00') location '${hivevar:date1}/01/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='01',min='15') location '${hivevar:date1}/01/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='01',min='30') location '${hivevar:date1}/01/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='01',min='45') location '${hivevar:date1}/01/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='02',min='00') location '${hivevar:date1}/02/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='02',min='15') location '${hivevar:date1}/02/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='02',min='30') location '${hivevar:date1}/02/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='02',min='45') location '${hivevar:date1}/02/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='03',min='00') location '${hivevar:date1}/03/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='03',min='15') location '${hivevar:date1}/03/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='03',min='30') location '${hivevar:date1}/03/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='03',min='45') location '${hivevar:date1}/03/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='04',min='00') location '${hivevar:date1}/04/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='04',min='15') location '${hivevar:date1}/04/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='04',min='30') location '${hivevar:date1}/04/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='04',min='45') location '${hivevar:date1}/04/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='05',min='00') location '${hivevar:date1}/05/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='05',min='15') location '${hivevar:date1}/05/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='05',min='30') location '${hivevar:date1}/05/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='05',min='45') location '${hivevar:date1}/05/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='06',min='00') location '${hivevar:date1}/06/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='06',min='15') location '${hivevar:date1}/06/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='06',min='30') location '${hivevar:date1}/06/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='06',min='45') location '${hivevar:date1}/06/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='07',min='00') location '${hivevar:date1}/07/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='07',min='15') location '${hivevar:date1}/07/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='07',min='30') location '${hivevar:date1}/07/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='07',min='45') location '${hivevar:date1}/07/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='08',min='00') location '${hivevar:date1}/08/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='08',min='15') location '${hivevar:date1}/08/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='08',min='30') location '${hivevar:date1}/08/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='08',min='45') location '${hivevar:date1}/08/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='09',min='00') location '${hivevar:date1}/09/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='09',min='15') location '${hivevar:date1}/09/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='09',min='30') location '${hivevar:date1}/09/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='09',min='45') location '${hivevar:date1}/09/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='10',min='00') location '${hivevar:date1}/10/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='10',min='15') location '${hivevar:date1}/10/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='10',min='30') location '${hivevar:date1}/10/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='10',min='45') location '${hivevar:date1}/10/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='11',min='00') location '${hivevar:date1}/11/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='11',min='15') location '${hivevar:date1}/11/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='11',min='30') location '${hivevar:date1}/11/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='11',min='45') location '${hivevar:date1}/11/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='12',min='00') location '${hivevar:date1}/12/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='12',min='15') location '${hivevar:date1}/12/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='12',min='30') location '${hivevar:date1}/12/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='12',min='45') location '${hivevar:date1}/12/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='13',min='00') location '${hivevar:date1}/13/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='13',min='15') location '${hivevar:date1}/13/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='13',min='30') location '${hivevar:date1}/13/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='13',min='45') location '${hivevar:date1}/13/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='14',min='00') location '${hivevar:date1}/14/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='14',min='15') location '${hivevar:date1}/14/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='14',min='30') location '${hivevar:date1}/14/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='14',min='45') location '${hivevar:date1}/14/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='15',min='00') location '${hivevar:date1}/15/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='15',min='15') location '${hivevar:date1}/15/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='15',min='30') location '${hivevar:date1}/15/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='15',min='45') location '${hivevar:date1}/15/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='16',min='00') location '${hivevar:date1}/16/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='16',min='15') location '${hivevar:date1}/16/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='16',min='30') location '${hivevar:date1}/16/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='16',min='45') location '${hivevar:date1}/16/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='17',min='00') location '${hivevar:date1}/17/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='17',min='15') location '${hivevar:date1}/17/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='17',min='30') location '${hivevar:date1}/17/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='17',min='45') location '${hivevar:date1}/17/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='18',min='00') location '${hivevar:date1}/18/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='18',min='15') location '${hivevar:date1}/18/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='18',min='30') location '${hivevar:date1}/18/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='18',min='45') location '${hivevar:date1}/18/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='19',min='00') location '${hivevar:date1}/19/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='19',min='15') location '${hivevar:date1}/19/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='19',min='30') location '${hivevar:date1}/19/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='19',min='45') location '${hivevar:date1}/19/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='20',min='00') location '${hivevar:date1}/20/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='20',min='15') location '${hivevar:date1}/20/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='20',min='30') location '${hivevar:date1}/20/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='20',min='45') location '${hivevar:date1}/20/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='21',min='00') location '${hivevar:date1}/21/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='21',min='15') location '${hivevar:date1}/21/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='21',min='30') location '${hivevar:date1}/21/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='21',min='45') location '${hivevar:date1}/21/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='22',min='00') location '${hivevar:date1}/22/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='22',min='15') location '${hivevar:date1}/22/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='22',min='30') location '${hivevar:date1}/22/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='22',min='45') location '${hivevar:date1}/22/45';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='23',min='00') location '${hivevar:date1}/23/00';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='23',min='15') location '${hivevar:date1}/23/15';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='23',min='30') location '${hivevar:date1}/23/30';
alter table ${hiveconf:encrypt_table} add if not exists partition(dt='${hivevar:date}',hour='23',min='45') location '${hivevar:date1}/23/45';



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


