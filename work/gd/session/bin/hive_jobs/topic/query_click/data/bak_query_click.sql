use log_session;

add file bak_mapper.py;
add file func.py;

drop table if exists query_click1;

create table query_click1 as
    select transform(*)
        using 'python bak_mapper.py'
        as 
        (
            uid string,
            query_type string,
            city string,
            sessionid string,
            stepid string,
            time string,
            query string,
            count string,
            poi_ids string,
            click_poi string,
            click_pos string
        )
        from tmp_query_click
        distribute by uid
        sort by uid,sessionid,cast(stepid as int),time;
