select 
        request['keywords'] as query,
        action as query_type,
        position['citycode'] as citycode,
        coalesce(response['addr_poi'],'-') as geo,
        count(distinct concat(dt, ':',uid)) as user_freq,
        count(1) as count_freq
    from log_session.log_sp
    where dt='${hivevar:date}' 
        and request['keywords'] is not null
        and action in ('TQUERY','RQBXY')
        and request['data_type']='POI' 
        and response['count']='0'
        and response['pinyins'] is null
    group by request['keywords'],action,position['citycode'],response['addr_poi']
    order by user_freq desc;
