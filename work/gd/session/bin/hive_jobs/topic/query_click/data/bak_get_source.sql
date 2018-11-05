use log_session;
drop table if exists tmp_query_click;
create table tmp_query_click
as
select *
    from
    (
        select *
        from log_merge
        where dt='20140520'
        and uid rlike '[3-4]'
        and 
            (
                source = 'SP' and action in ('TQUERY','RQBXY')
                or
                source = 'AOS' and action = '/ws/valueadded/deepinfo/search'
            )
        distribute by uid,source,sessionid
        sort by uid,source desc,sessionid,cast(stepid as int),time
    )tmp;
--    limit 1000;
-- hive -e "select * from log_session.log_merge where uid='001C6B7D-43CE-448A-87D2-EF02EB8B3DAF' and dt=20140611">test.txt
