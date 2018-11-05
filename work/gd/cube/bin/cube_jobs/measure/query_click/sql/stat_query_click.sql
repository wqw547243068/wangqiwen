create database if not exists log_cube;
use log_cube;

create table if not exists cube_query_click 
    (
            citycode string,
            div0 string,
            pv string comment 'PV : count(*)',
            uv string comment 'UV : count(distinct uid)',
            geo_num string comment 'Geo num : sum(if(response[addr_poi] is not null,1,0))',
            no_res_num string comment 'No result num : sum(if(result[count]<1 and response[addr_poi] is null,1,0)',
--            valid_pv string comment 'Valid PV : PV - Geo : count(*) - sum(if(response[addr_poi] is not null,1,0))',
            click_num string comment 'All click num,including muti-click : sum(cast(click[num] as int))',
            valid_click_num string comment 'Valid click num : sum(if(click[num]>0 and response[addr_poi] is null,1,0))',
--			click_rate string comment 'click rate : ClickRate=ValidClick/ValidPV',
            page_turn_num string comment 'sum(if(request[page]>1 and response[addr_poi] is null,1,0))',
--			page_turn_rate string comment 'PageTurnRate=PageTurn/ValidPV',
            general_num string comment 'general num',
            query_num string comment 'all query num'
--			general_rate string comment 'General Rate=isGeneral/query_num'
    )partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
--    line terminated by '\n'
    stored as textfile;
 
alter table cube_query_click drop if exists partition (dt='${hivevar:date}');

insert overwrite table cube_query_click partition (dt='${hivevar:date}')
    select 
        position['citycode'],
        cellphone['div'],
        count(*) as pv,
        count(distinct uid) as uv,
        sum(if(response['addr_poi'] is not null,1,0)) as geo_num,
        sum(if(response['addr_poi'] is null and result['count']<1,1,0)) as no_res_num,
--		count(*) - sum(if(response['addr_poi'] is not null,1,0)) as valid_pv,
        sum(cast(click['num'] as int)) as click_num,
		sum(if(click['num']>0 and response['addr_poi'] is null,1,0)) as valid_click_num,
--		sum(if(click['num']>0 and response['addr_poi'] is null,1,0))*100/(count(*) - sum(if(response['addr_poi'] is not null,1,0))) as click_rate,
		sum(if(request['page']>1 and response['addr_poi'] is null,1,0)) as page_turn_num,
--		sum(if(request['page']>1 and response['addr_poi'] is null,1,0))*100/(count(*) - sum(if(response['addr_poi'] is not null,1,0))) as page_turn_rate,
		sum(if(request['is_general']=1 and response['addr_poi'] is null,1,0)) as general_num,
		sum(if(query['keywords'] is not null and response['addr_poi'] is null,1,0)) as query_num
--		sum(if(request['is_general']=1 and response['addr_poi'] is null,1,0))*100/sum(if(query['keywords'] is not null and response['addr_poi'] is null,1,0)) as general_rate
    from log_session.query_click 
    where dt='${hivevar:date}'
        and request['query_src']='amap6' 
        and substr(cellphone['div'],-6,6)>='060200' 
        and sessionid != '-' 
		and stepid > '0'
    group by position['citycode'],cellphone['div']
        ;

--select dt,citycode,div0,pv,uv,geo_num,no_res_num,click_num,valid_click_num,page_turn_num,general_num,query_num 
select dt,
        if(citycode rlike '^(-|[0-9]{3,10})$',citycode,'null'),
        if(div0 rlike '^(-|\\w{4}\\d{6})',substr(div0,0,10),'null'),
        pv,uv,geo_num,no_res_num,click_num,valid_click_num,page_turn_num,general_num,query_num 
    from cube_query_click where dt='${hivevar:date}';
