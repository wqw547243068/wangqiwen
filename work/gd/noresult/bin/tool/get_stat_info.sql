select action,count(1) as count_freq,count( distinct request['keywords']) as query_freq
    from log_session.log_sp
    where dt='${hivevar:date}' 
        and request['data_type']='POI'
    group by action
    order by count_freq;
