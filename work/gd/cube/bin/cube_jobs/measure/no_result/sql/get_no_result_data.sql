
select
        if(request['keywords'] is null or request['keywords']='','null',request['keywords']),
        if(position['citycode'] rlike '^(-|[0-9]{3,10})$',position['citycode'],'null'),
        if(cellphone['div'] rlike '^(-|\\w{4}\\d{6})',substr(cellphone['div'],0,10),'null'),
        if(length(action)<11,action,'null'),
        request['query_src'],

        count(*) as old_pv,
        sum(if(request['page']=1
			    and action in ('TQUERY','RQBXY')
            , 1, 0)) as new_pv,
        sum(if(response['pinyins'] is null  
                and  request['keywords'] is not null 
                and  request['page']=1 
                and action in ('TQUERY','RQBXY')
            ,1,0))  as jiucuo,
        sum(if(response['count']=0 
                and response['pinyins'] is null  
                and  request['keywords'] is not  null
                and  request['page']=1 
                and action in ('TQUERY','RQBXY')
            , 1,0)) as no_res_num,
        sum(if(response['count']=0 
                and response['addr_poi'] is not null
                and response['pinyins'] is null   
                and  request['keywords'] is not null 
                and  request['page']=1 
                and action in ('TQUERY','RQBXY')
            , 1,0)) as no_res_geo

    from log_session.log_sp
    where dt='${hivevar:date}'
            and request['data_type']='POI'
            and request['query_src'] in ('amap6','amap7')
    group by 
        if(request['keywords'] is null or request['keywords']='','null',request['keywords']),
        if(position['citycode'] rlike '^(-|[0-9]{3,10})$',position['citycode'],'null'),
        if(cellphone['div'] rlike '^(-|\\w{4}\\d{6})',substr(cellphone['div'],0,10),'null'),
        if(length(action)<11,action,'null'),
        request['query_src']
        ;   


