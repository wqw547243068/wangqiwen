use log_session;

set hive.map.aggr=true;
set hive.groupby.skewindata=true;

add file ${hivevar:path}/reducer.py;
add file ${hivevar:path}/../../../tool/func.py;

--drop table if exists query_click;
--alter table query_click add partition(dt='${hivevar:date}');

create table if not exists query_click 
    (
            uid string,
            sessionid string,
            stepid string,
            time string,
            query map<string,string>,
            result map<string,string>,
            click map<string,string>,
            request map<string,string>,
            response map<string,string>,
            position map<string,string>,
            cellphone map<string,string>
    )partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
        collection items terminated by '\002'
        map keys terminated by '\003'
--    line terminated by '\n'
    stored as textfile;
 
alter table query_click drop if exists partition (dt='${hivevar:date}');

insert overwrite table query_click partition (dt='${hivevar:date}')
    select transform(*)
        using 'python reducer.py'
        as 
--(uid,query_type,sessionid,stepid,time,query,count,poi_ids,click_poi,click_pos,aos_info,request,response,position,cellphone)
        (
            uid string,
            sessionid string,
            stepid string,
            time string,
            query map<string,string>,
            result map<string,string>,
            click map<string,string>,
            request map<string,string>,
            response map<string,string>,
            position map<string,string>,
            cellphone map<string,string>
        )
        from (
				select * from
				(
					select * from log_sp
-- 2014-6-24 add amap6 parse
						where dt='${hivevar:date}' and action in ('TQUERY','RQBXY') and uid rlike '^[\\w][\\w-]+$' and request['query_src'] = 'amap6'
					union all
					select * from log_aos
-- 2014-7-4 fix bug response->request
						where dt='${hivevar:date}' and action = '/ws/valueadded/deepinfo/search' and uid rlike '^[\\w][\\w-]+$' and request['channel']='amap6'
				)tmp
                distribute by uid
                sort by uid,sessionid,source desc,cast(stepid as int),time
            )tmp
        distribute by uid
        sort by uid,sessionid,cast(stepid as int),time;
