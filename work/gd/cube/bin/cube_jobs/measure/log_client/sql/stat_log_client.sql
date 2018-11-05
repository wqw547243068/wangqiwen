
create database if not exists log_cube;

use log_cube;

create table if not exists cube_log_client_data 
    (
         
			div0 string comment 'cellphone: div',
            page string   comment 'action:page',
			button string  comment 'action:button',
			pv int comment 'PV'			
			
   )partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
--    line terminated by '\n'
    stored as textfile;
 
alter table cube_log_client_data drop if exists partition (dt='${hivevar:date}');
insert overwrite table cube_log_client_data partition (dt='${hivevar:date}')
--    select div0,channel,action,pv from (
    select             
            if(cellphone['div']='','-',cellphone['div']) div0,
            split(split(action,'\\|')[0],'=')[1] page,
            split(split(action,'\\|')[1],'=')[1] button,
                
--			if(action='','-',action) action,
--            case 
--                when(length(action)>100) then
--                substr(action,0,100)
--                else
--                     if(action='','-',action)
--            end as action,
			count(*) as pv
						
    from log_session.log_client
    where dt='${hivevar:date}' and uid is not NULL and uid<>'NULL'
    group by if(cellphone['div']='','-',cellphone['div']),
        split(split(action,'\\|')[0],'=')[1]  ,
        split(split(action,'\\|')[1],'=')[1]


--	) aos
--    where 
        ;

-- dt,adcode,div0,all_num,sp_num,sug_input_num,sug_no_display_num,sug_no_click_num,log_sp_num,click_top1,click_top3,click_top5
select dt,div0,page,button,pv
        
    from cube_log_client_data where dt='${hivevar:date}'
    ;

