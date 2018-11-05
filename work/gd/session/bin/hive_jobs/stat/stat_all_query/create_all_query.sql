use log_data;

create table if not exists stat_all_query 
    (
			keywords string,
			time string,
			citycode string,
			query_type string,
			x string,
			y string,
			geoobj string,
			user_loc string
    )partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
--    line terminated by '\n'
    stored as textfile;
 
alter table stat_all_query drop if exists partition (dt='${hivevar:date}');

insert overwrite table stat_all_query partition (dt='${hivevar:date}')
		select request['keywords'],time,position['citycode'],action,position['x'],position['y'],position['geoobj'],position['user_loc']
		from log_session.log_sp
		where dt='${hivevar:date}'
			and request['keywords'] is not null
			and action in ('TQUERY','RQBXY')
			and request['query_src'] = 'amap6'
			and request['data_type'] = 'POI'
			;
