
create database if not exists log_cube;

use log_cube;

create table if not exists cube_special_keywords
(
	keywords string

)
row format delimited
   fields terminated by '\t'
 --    line terminated by '\n'
   stored as textfile;

load Data local inpath '/home/devuse/haiming.zhang/svn/cube/special_keywords.txt' overwrite into table cube_special_keywords;

create table if not exists cube_my_location
(
	    keywords string

)
row format delimited
  fields terminated by '\t'
  --    line terminated by '\n'
  stored as textfile;

load Data local inpath '/home/devuse/haiming.zhang/svn/cube/my_location.txt' overwrite into table cube_my_location;


create table if not exists cube_log_sp_data 
    (
            citycode string comment 'location: search city',
			user_loc_city string comment 'location: user city',
			div0 string comment 'cellphone: div',
            action string  comment 'query_type',
			search_sceneid string   comment 'search_sceneid',
			
			pv int comment 'PV',
			uv int comment 'UV',
			
			stepid_null int comment 'stepid null num',
			id int comment 'id num',
			name int comment 'name num',
			sug int comment 'sug num',
			keyword int comment 'keyword num',
			category int comment 'category num',
			is_general int comment 'is_general num',
			no_res int comment 'no_res num',
			jiucuo int comment 'jiucuo num',
			first_page int comment 'first page num',
			geo int comment 'geo num',
			city_sug int comment 'city sug num',
			is_general_firstpage int comment 'is_general_firstpage',
			may_sug_pv int comment 'pv that may generaled by sug',
			sug_pv int comment 'pv of sug',
			pv_dire_words int comment 'pv of direct sp words',
			count_my_loc int comment 'pv my location'
   )partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
--    line terminated by '\n'
    stored as textfile;
 
alter table cube_log_sp_data drop if exists partition (dt='${hivevar:date}');
insert overwrite table cube_log_sp_data partition (dt='${hivevar:date}')

select sp_dire_wds.citycode,sp_dire_wds.user_loc_city , sp_dire_wds.div0  ,sp_dire_wds.action, sp_dire_wds.search_sceneid  ,sp_dire_wds.pv  ,sp_dire_wds.uv  ,
sp_dire_wds.stepid_null ,sp_dire_wds.id  ,sp_dire_wds.name ,sp_dire_wds.sug  ,sp_dire_wds.keyword ,
sp_dire_wds.category  ,sp_dire_wds.is_general  ,sp_dire_wds.no_res  ,sp_dire_wds.jiucuo  ,sp_dire_wds.first_page  ,sp_dire_wds.geo ,  sp_dire_wds.city_sug  ,
sp_dire_wds.is_general_firstpage ,  sp_dire_wds.may_sug_pv , sp_dire_wds.sug_pv ,sp_dire_wds.pv_dire_words,my_location.count_my_loc
 from 
	(
	  select 
	    if(sp.position['citycode']='','-',sp.position['citycode']) citycodeb,
        if(sp.position['user_loc_city']='','-',sp.position['user_loc_city']) user_loc_cityb,
         if(sp.cellphone['div']='','-',sp.cellphone['div']) divb,
         if(sp.action='','-',sp.action) actionb,
        if(sp.request['search_sceneid']='' or sp.request['search_sceneid'] is null ,'-',sp.request['search_sceneid']) search_sceneidb,
        count(*) as count_my_loc 
		 from log_cube.cube_my_location loc join log_session.log_sp sp on loc.keywords = sp.request['keywords'] 
	     where sp.dt='${hivevar:date}'  and request['query_src'] = 'amap6'
	    group by if(sp.position['citycode']='','-',sp.position['citycode']) ,
           if(sp.position['user_loc_city']='','-',sp.position['user_loc_city']) ,
           if(sp.cellphone['div']='','-',sp.cellphone['div']) ,
           if(sp.action='','-',sp.action) ,
           if(sp.request['search_sceneid']=''  or sp.request['search_sceneid'] is null  ,'-',sp.request['search_sceneid']) 
													    
	) my_location right outer join 

 (select logsp.citycodez citycode,logsp.user_loc_cityz user_loc_city,logsp.divz div0,logsp.actionz action,logsp.search_sceneidz search_sceneid,
	logsp.pv pv,logsp.uv uv,logsp.stepid_null stepid_null,logsp.id id,logsp.name name,logsp.sug sug,
	logsp.keyword keyword,logsp.category category,logsp.is_general is_general,
	logsp.no_res no_res,logsp.jiucuo jiucuo,logsp.first_page first_page,logsp.geo geo,logsp.city_sug city_sug,logsp.is_general_firstpage is_general_firstpage,
   logsp.may_sug_pv may_sug_pv,logsp.sug_pv  sug_pv,  direct_sp_words.pv_direct_sp_words pv_dire_words from 
       (select 
			if(sp.position['citycode']='','-',sp.position['citycode']) citycodea,
            if(sp.position['user_loc_city']='','-',sp.position['user_loc_city']) user_loc_citya,
		    if(sp.cellphone['div']='','-',sp.cellphone['div']) diva,
		    if(sp.action='','-',sp.action) actiona,
		    if(sp.request['search_sceneid']=''  or sp.request['search_sceneid'] is null ,'-',sp.request['search_sceneid']) search_sceneida,
		    count(*) as pv_direct_sp_words

 from log_cube.cube_special_keywords kw join log_session.log_sp sp on kw.keywords = sp.request['keywords'] 
     where sp.dt='${hivevar:date}'  and request['query_src'] = 'amap6'
	    group by if(sp.position['citycode']='','-',sp.position['citycode']) ,
             if(sp.position['user_loc_city']='','-',sp.position['user_loc_city']) ,
            if(sp.cellphone['div']='','-',sp.cellphone['div']) ,
             if(sp.action='','-',sp.action) ,
            if(sp.request['search_sceneid']=''  or sp.request['search_sceneid'] is null ,'-',sp.request['search_sceneid']) 
	  ) direct_sp_words right outer join 
		(
	     select
            if(position['citycode']='','-',position['citycode']) citycodez,
            if(position['user_loc_city']='','-',position['user_loc_city']) user_loc_cityz,
           if(cellphone['div']='','-',cellphone['div']) divz,
           if(action='','-',action) actionz,
           if(request['search_sceneid']=''  or request['search_sceneid'] is null ,'-',request['search_sceneid']) search_sceneidz,

          count(*) as pv,
           count(distinct uid) as uv,
			sum(if(stepid='-',1,0)) as stepid_null,
            sum(if(request['id'] is not null,1,0)) as id,
		   sum(if(request['name'] is not null,1,0)) as name,
		    sum(if(request['sug'] is not null,1,0)) as sug,
            sum(if(request['keywords'] is not null,1,0)) as keyword,
            sum(if(request['category'] is not null,1,0)) as category,
            sum(if(request['is_general'] is not null,1,0)) as is_general,
            sum(if(response['count']='0',1,0)) as no_res,
           sum(if(response['pinyins'] is not null,1,0)) as jiucuo,
            sum(if(request['page']='1',1,0)) as first_page,
            sum(if(response['addr_poi'] is not null,1,0)) as geo,
           sum(if(response['citysuggestcitycode_res'] is not null,1,0)) as city_sug,
            sum(if(request['is_general'] is not null and request['page']='1',1,0)) as is_general_firstpage,
            sum(if(request['category'] is null and request['keywords'] is not null,1,0)) as may_sug_pv,
           sum(if(request['name'] is not null and request['keywords'] is not null ,1,0)) as sug_pv
		 from log_session.log_sp
		    where dt='${hivevar:date}' and request['query_src'] = 'amap6'
			    group by if(position['citycode']='','-',position['citycode']),
            if(position['user_loc_city']='','-',position['user_loc_city']),
		            if(cellphone['div']='','-',cellphone['div']),
		            if(action='','-',action),
		            if(request['search_sceneid']=''  or request['search_sceneid'] is null ,'-',request['search_sceneid'])
        ) logsp
		  on  direct_sp_words.citycodea = logsp.citycodez and direct_sp_words.user_loc_citya = logsp.user_loc_cityz
            and direct_sp_words.diva = logsp.divz and direct_sp_words.actiona = logsp.actionz and direct_sp_words.search_sceneida = logsp.search_sceneidz
    ) sp_dire_wds on
	sp_dire_wds.citycode = my_location.citycodeb and sp_dire_wds.user_loc_city = my_location.user_loc_cityb
    and sp_dire_wds.div0 = my_location.divb and sp_dire_wds.action = my_location.actionb and sp_dire_wds.search_sceneid = my_location.search_sceneidb ;

-- dt,adcode,div0,all_num,sp_num,sug_input_num,sug_no_display_num,sug_no_click_num,log_sp_num,click_top1,click_top3,click_top5
--select dt,citycode,user_loc_city,div0,action,search_sceneid,
select dt,
        if(citycode rlike '^(-|[0-9]{3,10})$',citycode,'null'),
        if(user_loc_city rlike '^(-|[0-9]{3,10})$',user_loc_city,'null'),
        if(div0 rlike '^(-|\\w{4}\\d{6})',substr(div0,0,10),'null'),
        case when action='-' then action when length(action)<11 then action  else 'null' end,
        if(search_sceneid rlike '^([0-9]{1,10})$',rpad(search_sceneid,6,'0'),'-'),
        pv,uv,stepid_null,id,name,sug,keyword,category,is_general,no_res,jiucuo,first_page,geo,city_sug,is_general_firstpage,may_sug_pv,sug_pv,
		if(pv_dire_words is null,0,pv_dire_words),if(count_my_loc is null,0,count_my_loc)

    from cube_log_sp_data where dt='${hivevar:date}'
    ;

