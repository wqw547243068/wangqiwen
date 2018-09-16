--[2017-6-28]上传待发送文件至pg(含分组)
--157 13810347287 mobile  user_name male  1 ...
create table if not exists wqw.sms_daily_${jobName}_send
  (
    user_id integer,
    phone character varying(50) not null,
    net character varying(20),
    name character varying(50),
    gender character varying(50),
    groupid character varying(50),
    dt character varying(10),
    --time timestamp without time zone
    primary key (user_id,dt)
  ); --comment '历史待发送用户集合'
create table if not exists wqw.sms_daily_${jobName}_send_tmp ( like wqw.sms_daily_${jobName}_send);
comment on table wqw.sms_daily_${jobName}_send_tmp is '存储当天的SMS Recall用户信息(每天清理一次)';
delete from wqw.sms_daily_${jobName}_send_tmp; --先清除
\copy wqw.sms_daily_${jobName}_send_tmp FROM '$dataFileNew';
insert into wqw.sms_daily_${jobName}_send
  select user_id,phone,gender,current_date  from wqw.sms_daily_${jobName}_send_tmp 
  on conflict do nothing;	

