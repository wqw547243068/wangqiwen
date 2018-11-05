create database if not exists log_cube;
use log_cube;

create table if not exists cube_no_result_data 
    (   
            keywords string,
            citycode string,
            div0 string,
            action string comment 'query_type',
            source string comment 'query_src',
            old_pv string comment 'PV : count(*)',
            new_pv string comment 'request[page]=1 and action in (TQUERY,RQBXY)',
            jiucuo string comment 'response[pinyins] is null',
            no_res_num string comment 'response[count]=0',
            no_res_geo string comment 'response[addr_poi] is not null',
            filter_num string comment 'keywords in wordlist'
    )partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
--    line terminated by '\n'
    stored as textfile;

alter table cube_no_result_data drop if exists partition (dt='${hivevar:date}');

LOAD DATA LOCAL INPATH '${hivevar:path}' INTO TABLE cube_no_result_data PARTITION (dt='${hivevar:date}');

select 
    dt,
    citycode,
    div0,
    action,
    source,
    sum(old_pv),
    sum(new_pv),
    sum(jiucuo),
    sum(no_res_num),
    sum(no_res_geo),
    sum(filter_num)
from cube_no_result_data
where dt='${hivevar:date}'
group by 
    dt,
    citycode,
    div0,
    action,
    source
    ;

