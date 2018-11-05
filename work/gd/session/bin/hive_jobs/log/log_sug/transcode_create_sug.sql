--hive -f tmp_create_sug.sql -hivevar path=. -hivevar date=20140524 -hivevar date1=2014/05/24
use log_session;
-- 2014-9-19

set date;
set date1;

--drop table if exists log_sug_raw_old;
create external table if not exists log_sug_code(
                    uid string,
                    sessionid string,
                    stepid string,
                    time string,
                    position map<string,string>,
                    source string,
                    action string,
                    request map<string,string>,
                    response map<string,string>,
                    cellphone map<string,string>,
                    other map<string,string>
    )
    partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
    stored as textfile
    location "/user/devuse/warren/sug/";

--alter table log_sug_code drop if exists partition (dt='${hivevar:date}');
alter table log_sug_code add if not exists partition (dt='${hivevar:date}') location '${hivevar:date}/0000';



create table if not exists log_sug like log_sp;

--alter table log_sug drop if exists partition (dt='${hivevar:date}');
alter table log_sug add if not exists partition (dt='${hivevar:date}');
insert overwrite table log_sug  partition (dt='${hivevar:date}')
        select uid,sessionid,stepid,time,position,source,action,request,response,cellphone,other from log_sug_code
        where dt='${hivevar:date}'
        distribute by uid
            sort by uid,sessionid,cast(stepid as int),time;
--load data into hive table
--load data inpath '/user/devuse/warren/sug/${hivevar:date}/0000/part-*' overwrite into table log_sug partition (dt='${hivevar:date}');

