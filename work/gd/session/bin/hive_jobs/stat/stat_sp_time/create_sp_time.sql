use log_data;

create table if not exists stat_sp_time 
    (
            time string,
            count string
    )partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
--    line terminated by '\n'
    stored as textfile;
 
alter table stat_sp_time drop if exists partition (dt='${hivevar:date}');

insert overwrite table stat_sp_time partition (dt='${hivevar:date}')
	select a.time,count(1) as freq
	from
	(
		select request['resp_time'] as time
--		select regexp_extract(line,'([^ ]*?ms)$',1) as time
		from log_session.log_aos
		where dt='${hivevar:date}'
			and action='/ws/mapapi/poi/info'
--			and line rlike '/ws/mapapi/poi/info.*ms$'
	)a
	group by a.time
	order by freq desc;
--select regexp_extract(line,'/ws/mapapi/poi/info.*?([^ ]*?ms)$',1) as time from log_session.log_aos_raw where dt=20140604 and line rlike '/ws/mapapi/poi/info.*ms$' limit 10;
