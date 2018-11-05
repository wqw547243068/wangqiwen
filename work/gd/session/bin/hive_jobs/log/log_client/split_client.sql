use log_session;
set date;
set date_str;
set hive.exec.dynamic.partition.mode=nonstrict;

create table if not exists log_client_rest like log_client;
-- 2014-7-24 warren log_merge -> log_rest
insert into table log_client_rest partition (dt)
        select x.uid,x.sessionid,x.stepid,x.time,x.position,x.source,x.action,x.request,x.response,x.cellphone,x.other,x.other['date']
            from log_client x
            where dt = '${hivevar:date}'
				and array_contains(split('${hivevar:date_str}',','),x.other['date'])
--                where x.other['date'] <= '${hivevar:date}' and x.other['date'] >= date_sub(concat_ws('-',substr('${hivevar:date}',1,4),substr('${hivevar:date}',5,2),substr('${hivevar:date}',7,2)),cast('${hivevar:delta}' as int))
                and uid rlike '^[\\w-]+$'
        distribute by uid 
        sort by uid,sessionid,cast(stepid as int),time; 

