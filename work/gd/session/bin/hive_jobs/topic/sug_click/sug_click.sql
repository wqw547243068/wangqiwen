use log_session;

set hive.map.aggr=true;
set hive.groupby.skewindata=true;

add file ${hivevar:path}/reducer.py;
add file ${hivevar:path}/../../../tool/func.py;

--drop table if exists sug_click;
--alter table sug_click add partition(dt='${hivevar:date}');

create table if not exists sug_click 
    (
            uid string,
            sessionid string,
            stepid string,
            time string,
            input string,
            sug string,
            click map<string,string>,
            request map<string,string>,
            response map<string,string>,
            sp_request map<string,string>,
            sp_response map<string,string>,
            position map<string,string>,
            cellphone map<string,string>
    )partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
        collection items terminated by '\002'
        map keys terminated by '\003'
--    line terminated by '\n'
    stored as textfile;
 
alter table sug_click drop if exists partition (dt='${hivevar:date}');

insert overwrite table sug_click partition (dt='${hivevar:date}')
    select transform(*)
        using 'python reducer.py'
        as 
--(uid,query_type,sessionid,stepid,time,query,count,poi_ids,click_poi,click_pos,aos_info,request,response,position,cellphone)
        (
            uid string,
            sessionid string,
            stepid string,
            time string,
            input string,
            sug string,
            click map<string,string>,
            request map<string,string>,
            response map<string,string>,
            sp_request map<string,string>,
            sp_response map<string,string>,
            position map<string,string>,
            cellphone map<string,string>
        )
        from (
				select * from
				(
					select * from log_sp
						where dt='${hivevar:date}' and ( request['name'] is not null or request['sug'] is not null ) and uid rlike '^[\\w][\\w-]+$' and request['query_src']='amap6'
					union all
					select * from log_sug
						where dt='${hivevar:date}' and uid rlike '^[\\w][\\w-]+$' and request['query_src']='amap6'
				)tmp
                distribute by uid
                sort by uid,sessionid,source desc,cast(stepid as int),time
            )tmp
        distribute by uid
        sort by uid,sessionid,cast(stepid as int),time;
