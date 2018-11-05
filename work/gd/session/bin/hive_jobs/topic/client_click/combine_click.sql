set mapred.max.map.failures.percent=1;
set mapred.output.compression.codec = org.apache.hadoop.io.compress.GzipCodec;
set hive.exec.dynamic.partition.mode=nonstrict;
--set mapred.child.java.opts=-XX:-UseGCOverheadLimit -Xmx997266369;
set mapred.map.child.java.opts=-XX:-UseGCOverheadLimit -Xmx2000m;
--set mapred.reduce.child.java.opts=-XX:-UseGCOverheadLimit -Xmx2000m

--set wait time to 1 hour
set mapred.task.timeout=3600000;

use log_session;


add file ${hivevar:path}/../../../tool/page-button/page-button.json;
add jar  ${hivevar:path}/../../log/log_client/libs/PageDecoder-0.0.1-SNAPSHOT.jar;
add jar  ${hivevar:path}/../../log/log_client/libs/hive-plugins-0.0.1-SNAPSHOT.jar;


create table if not exists log_client_query_split
    (
      --diu string ,
	  uid string, sessionid string , stepid string,
	  queryclicks array< struct <
								stepid:string, page:string, button:string,
							   	--source:string, service:string,action:string, act_time:string,position:map<string,string>, 
                                paras:map<string,string>,
								act_name:string
                            >
                   > comment 'all clicks for one diu, may be multi session', 
      others string comment 'version,protocal,diu2,diu3'
    )
    partitioned by (dt string)
    stored as textfile;


create temporary  function clean_client as 'com.autonavi.data.client.CleanClientNetworkEvent';
create temporary  function combine_click as 'com.autonavi.data.client.SimpleCombineClick';
create temporary  function union_table as 'com.autonavi.data.hive.UnionTable';
create temporary  function project as 'com.autonavi.data.hive.ProjectCols';


alter table log_client_query_split drop if exists partition (dt='${hivevar:date}');
insert into table log_client_query_split  partition (dt='${hivevar:date}')
--insert overwrite directory '/tmp/zhuhuo/abc'
	select uid, sessionid, querystepid, queryclicks, others
	from 
	(
		select * from 
		(
			select uid, sessionid, collect_set(stepid) as sp_stepids  
			from log_sp 
			where dt = '${hivevar:date}'
				  and stepid rlike '^\\d+$'
			      and request["query_src"] ="amap6"
			group by uid, sessionid 
		) sp

		left outer join

   		(
			--select uid, sessionid, collect_set(clicks) as clicks , others
			select uid, sessionid, union_table(clean_client(project(clicks, 0, 1, 2, 8))) as clicks , others
		   	from log_client_decrypt
		   	where act_date = '${hivevar:date}'
			      and (sessionid != '' or sessionid is not null ) 
			      and uid is not null 
				  and clicks is not null
				  and dt >= '${hivevar:startdate}'
				  and dt <= '${hivevar:enddate}'
		  	group by uid, sessionid, others

		) client

		on sp.uid = client.uid and sp.sessionid = client.sessionid 

	)  sp_client
    LATERAL VIEW combine_click(clicks, sp_stepids, split(others,':')[0]) tmp as querystepid, queryclicks

