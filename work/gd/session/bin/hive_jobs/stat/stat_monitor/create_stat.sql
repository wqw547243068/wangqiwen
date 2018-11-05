use log_data;

create table if not exists stat_monitor
	(
		source string comment 'SP/SUG/AOS/CLIENT',
		pv	string comment 'PV : count(*)',
		uv	string comment 'UV : count(distinct uid)'
	)partitioned by (dt string)
	row format delimited
		fields terminated by '\t'
		stored as textfile;

alter table stat_monitor drop if exists partition(dt='${hivevar:date}');
insert overwrite table stat_monitor partition(dt='${hivevar:date}')
	select source,count(*) as pv,count(distinct uid) as uv from log_session.log_merge where source in ('SP','SUG','CLIENT','AOS') and  dt='${hivevar:date}' group by source order by source;
