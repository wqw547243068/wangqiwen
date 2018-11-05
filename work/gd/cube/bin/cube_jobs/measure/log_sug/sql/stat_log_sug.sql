
create database if not exists log_cube;

use log_cube;

create table if not exists cube_log_sug_data
    (
            citycode string comment 'location: search city',
			user_loc_city string comment 'location: user city',
			div0 string comment 'cellphone: div',
            query_src string comment 'query_src',
			pv int comment 'PV',
			uv int comment 'UV',
			stepid_null int comment 'stepid null num',
			keywords_null int comment 'name num',
			sug_err int comment 'sug num',
			no_res int comment 'keyword num',
			son_num int comment 'category num'

   )partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
--    line terminated by '\n'
    stored as textfile;
 
alter table cube_log_sug_data drop if exists partition (dt='${hivevar:date}');
insert overwrite table cube_log_sug_data partition (dt='${hivevar:date}')

	select 
	    city_code,tool_city_ad.citycode city_user,diva,querysrca,
        sum(pva),sum(uva),sum(stepid_nulla),sum(keyword_nulla),
        sum(sug_erra),sum(no_resa),sum(son_numa)
        from log_session.tool_city_ad right outer join (
	select city.citycode city_code,sug.usercity usercitya,sug.div0 diva,sug.query_src querysrca,sug.pv pva,
        sug.uv uva, sug.stepid_null stepid_nulla,sug.keyword_null keyword_nulla,
    	sug.sug_err sug_erra,sug.no_res no_resa,sug.son_num son_numa from 
		log_session.tool_city_ad city right outer join (
        select 
        if(request['adcode']='','-',request['adcode']) adcode,
        if(position['user_city']='','-',position['user_city']) usercity,
        if(cellphone['div']='','-',cellphone['div']) div0,
        if(request['query_src']='','-',request['query_src']) query_src,
        
        count(*) as pv,
        count(distinct uid) as uv,
        sum(if(stepid='-',1,0)) as stepid_null,

		sum(if(request['keyword'] is null or request['keyword']='-',1,0)) as keyword_null,

        sum(if(response['count']!=response['num'] ,1,0)) as sug_err,
        sum(if(response['count']='0' or response['result'] = '-',1,0)) as no_res,
        sum(if(response['son_num'] is not null,1,0)) as son_num        
from log_session.log_sug
where dt='${hivevar:date}'
group by if(request['adcode']='','-',request['adcode']),
        if(position['user_city']='','-',position['user_city']),
        if(cellphone['div']='','-',cellphone['div']),
        if(request['query_src']='','-',request['query_src']) 
	) sug on city.adcode = sug.adcode
	) sug2 on tool_city_ad.adcode = sug2.usercitya
	
	group by city_code,tool_city_ad.citycode,diva,querysrca
	sort by city_code,city_user,diva
    ;



    select dt,if(citycode is null or citycode='NULL','-',citycode),
		if(user_loc_city is null or user_loc_city='NULL','-',user_loc_city),
		div0,query_src,pv,uv,stepid_null,keywords_null,sug_err,no_res,son_num
        from cube_log_sug_data 
		where dt='${hivevar:date}' ;
