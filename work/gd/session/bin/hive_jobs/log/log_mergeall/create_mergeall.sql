use log_session;
----drop table if exists log_merge;
create table if not exists log_mergeall like log_sp;

alter table log_mergeall drop if exists partition (dt='${hivevar:date}') ;

set mapred.output.compression.codec = org.apache.hadoop.io.compress.GzipCodec;
set mapred.reduce.tasks= 50;
set hive.exec.compress.output=true;
set mapred.output.compress=true;


insert overwrite table log_mergeall partition (dt='${hivevar:date}')
select * from
(
    select uid,sessionid,stepid,time,position,source,action,request,response,cellphone,other
    from  log_aos  where dt='${hivevar:date}' union all
    select uid,sessionid,stepid,time,position,source,action,request,response,cellphone,other
    from  log_client  where dt='${hivevar:date_suf}' and other['date']='${hivevar:date}'union all
    select uid,sessionid,stepid,time,position,source,action,request,response,cellphone,other
    from  log_client  where dt='${hivevar:date}' and other['date']='${hivevar:date}' union all
    select uid,sessionid,stepid,time,position,source,action,request,response,cellphone,other
    from  log_sp  where dt='${hivevar:date}'  union all
    select uid,sessionid,stepid,time,position,source,action,request,response,cellphone,other
    from  log_sptuan where dt='${hivevar:date}' union all
    select uid,sessionid,stepid,time,position,source,action,request,response,cellphone,other
    from log_spmovie where dt='${hivevar:date}' union all
    select uid,sessionid,stepid,time,position,source,action,request,response,cellphone,other
    from log_sug where dt='${hivevar:date}'

) mergeall
where uid rlike '^[\\w-]+$' and action!='page=2000|button=0'
distribute by uid
sort by uid,sessionid,cast(stepid as int),time;

