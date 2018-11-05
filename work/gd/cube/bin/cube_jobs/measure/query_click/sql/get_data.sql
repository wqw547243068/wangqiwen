    select 
        dt,
--        concat(dt,'-',substr(time,0,2)),
        position['citycode'],
        cellphone['div'],
        count(*) as pv,
        count(distinct uid) as uv,
        sum(if(response['addr_poi'] is not null,1,0)) as geo_num,
        sum(if(response['addr_poi'] is null and result['count']<1,1,0)) as no_res_num,
        sum(cast(click['num'] as int)) as click_num,
		sum(if(click['num']>0 and response['addr_poi'] is null,1,0)) as valid_click_num,
		sum(if(request['page']>1 and response['addr_poi'] is null,1,0)) as page_turn_num,
		sum(if(request['is_general']=1 and response['addr_poi'] is null,1,0)) as general_num,
		sum(if(query['keywords'] is not null and response['addr_poi'] is null,1,0)) as query_num
    from log_session.query_click 
    where dt='${hivevar:date}'
        and request['query_src']='amap6' 
        and substr(cellphone['div'],-6,6)>='060200' 
        and sessionid != '-' 
		and stepid > '0'
        group by dt,position['citycode'],cellphone['div']
--        group by concat(dt,'-',substr(time,0,2)),position['citycode'],cellphone['div']
        ;
