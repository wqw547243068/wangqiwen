--[2017.6.28]发送信息表结构升级(不含分桶用户)
--alter table wqw.sms_daily_done rename to sms_daily_done_bak;
--drop table if exists wqw.sms_daily_done;
create table if not exists wqw.sms_daily_done
(
  user_id integer,
  dt character varying(20) default '-',
  time character varying(20) default '-',
  --time timestamp without time zone,
  phone character varying(50) not null default '-',
  net character varying(20) default '-',
  provider character varying(50) default '-',
  name character varying(50) default '-',
  gender character varying(50) default '-',
  cwname character varying(50) default '-',
  cwcontent character varying(200) default '-',
  primary key (user_id,dt,time,phone)
); 
comment on table wqw.sms_daily_done is '历史所有SMS Recall用户信息';
comment on column wqw.sms_daily_done.user_id is '用户id';
comment on column wqw.sms_daily_done.phone is '手机号(仅国内用户)';
comment on column wqw.sms_daily_done.net is '网络运营商(移动,联通,电信等)';
comment on column wqw.sms_daily_done.provider is '短信发送服务商';
comment on column wqw.sms_daily_done.name is '用户名';
comment on column wqw.sms_daily_done.dt is '短信发送时间-天';
comment on column wqw.sms_daily_done.time is '短信发送时间-时间';
comment on column wqw.sms_daily_done.cwname is '任务名';
comment on column wqw.sms_daily_done.gender is '性别(male,female)';
comment on column wqw.sms_daily_done.cwcontent is '文案内容';
-- alter table wqw.sms_daily_telecom_done_tmp add column net1 character varying(20);
--drop table if exists wqw.sms_daily_done_tmp;
create table if not exists wqw.sms_daily_done_tmp ( like wqw.sms_daily_done );
comment on table wqw.sms_daily_done_tmp is '当天非电信用户发送集合';

--drop table if exists wqw.sms_daily_telecom_done_tmp;
create table if not exists wqw.sms_daily_telecom_done_tmp ( like wqw.sms_daily_done );
comment on table wqw.sms_daily_telecom_done_tmp is '当天电信用户发送集合';

--迁移旧数据
--insert into wqw.sms_daily_done
--  select user_id,date(time),to_char(time, 'HH:MI:SS'),phone,'-','-',name,gender,cwname,cwcontent from wqw.sms_daily_done_bak;
  --select user_id,'-','-',phone,name,date(time),to_char(nowcst(), 'HH:MI:SS'),cwname,gender,cwcontent from wqw.sms_daily_done_bak ; -- on conflict do nothing

