set mapred.max.map.failures.percent=1;
set mapred.output.compression.codec = org.apache.hadoop.io.compress.GzipCodec;
set hive.exec.dynamic.partition.mode=nonstrict;


use log_session;


add file ${hivevar:path}/../../../tool/page-button/page-button.json;
add jar  ${hivevar:path}/../../log/log_client/libs/PageDecoder-0.0.1-SNAPSHOT.jar;
add jar  ${hivevar:path}/../../log/log_client/libs/hive-plugins-0.0.1-SNAPSHOT.jar;

-- join with sp and import to client_click
create table if not exists client_click
(
	  uid string, sessionid string , stepid string,
	  queryclicks array<struct<
								stepid:string,page:string,button:string,
								--source:string,service:string,action:string,act_time:string,
								--position:map<string,string>,
								paras:map<string,string>,
								act_name:string
								>
						>,
	  position map<string, string>,
	  request map<string, string>,
	  response map<string, string>,
      cellphone map<string, string> comment 'model,manufacture,device',
      other map<string, string> comment 'version,protocal,diu2,diu3'
)
    partitioned by (dt string)
    stored as rcfile;

alter table client_click drop if exists partition (dt='${hivevar:date}');

insert overwrite table client_click partition (dt='${hivevar:date}')
	 select 
	 log_sp.uid,
	 log_sp.sessionid,
	 log_sp.stepid,
	 client.queryclicks,
	 log_sp.position,
	 log_sp.request,
	 log_sp.response,
	 log_sp.cellphone,
	 log_sp.other

	 from 

	(
	 select * from 
	 log_sp where dt = '${hivevar:date}'
    )  log_sp 

	 LEFT OUTER JOIN

	 --log_client_zhuhuo_final_2 client
	(
	 select * from 
	 log_client_query_split where dt = '${hivevar:date}'
	) client 

	 on (client.uid = log_sp.uid and client.sessionid = log_sp.sessionid and client.stepid = log_sp.stepid and log_sp.dt='${hivevar:date}' and client.dt = '${hivevar:date}')


