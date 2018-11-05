create database if not exists log_cube;
use log_cube;

create table if not exists cube_sug_click_data 
    (
            adcode string,
            div0 string,
            all_num string comment 'all num = sug pv + sp(sug) pv',
            sp_num string comment 'only in sp,no sug input info',
            sug_input_num string comment 'sug input info',
            sug_no_display_num string comment 'sug display info',
            sug_no_click_num string comment 'sug display,no click info',
            sug_click_num string comment 'sug click info',
            click_top1 string comment 'top 1 click',
            click_top3 string comment 'top 3 click',
            click_top5 string comment 'top 5 click'
   )partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
--    line terminated by '\n'
    stored as textfile;
 
alter table cube_sug_click_data drop if exists partition (dt='${hivevar:date}');

insert overwrite table cube_sug_click_data partition (dt='${hivevar:date}')
    select 
            position['user_city'],
            cellphone['div'],
            count(*) as all_num,
            sum(if(input='-',1,0)) as sp_num,
            sum(if(input!='-',1,0)) as sug_input_num,
            sum(if(input!='-' and sug='',1,0)) as sug_no_display_num,
            sum(if(input!='-' and sug!='' and click['type'] is null,1,0)) as sug_no_click_num,
            sum(if(input!='-' and sug!='' and click['type']='sug',1,0)) as sug_click_num,
            sum(if(cast(click['order'] as int)=1,1,0)) as click_top1,
            sum(if(cast(click['order'] as int)<=3,1,0)) as click_top3,
            sum(if(cast(click['order'] as int)<=5,1,0)) as click_top5
    from log_session.sug_click
    where dt='${hivevar:date}'
    group by position['user_city'],cellphone['div']
        ;

-- dt,adcode,div0,all_num,sp_num,sug_input_num,sug_no_display_num,sug_no_click_num,sug_click_num,click_top1,click_top3,click_top5
--select dt,adcode,div0,
select dt,
        if(adcode rlike '^(-|[0-9]{3,10})$',adcode,'null'),
        if(div0 rlike '^(-|\\w{4}\\d{6})',substr(div0,0,10),'null'),
        all_num,sp_num,sug_input_num,sug_no_display_num,sug_no_click_num,sug_click_num,
        click_top1,click_top3,click_top5
    from cube_sug_click_data where dt='${hivevar:date}'
    ;
