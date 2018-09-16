--psql << SQL
--[user_id name gender mobile_number operator group_id send_time provider status copywrite_name sms_parameters copywrite_content]
DROP TABLE IF EXISTS wqw.daily_idle_sms_recall_tmp;
CREATE TABLE IF NOT EXISTS wqw.daily_idle_sms_recall_tmp
  (
      user_id INTEGER NOT NULL,
      name CHARACTER VARYING(50),
      gender gender,
      mobile_number CHARACTER VARYING(50),
      operator CHARACTER VARYING(20),
      group_id  INTEGER NOT NULL,
      send_time TIMESTAMP WITHOUT TIME ZONE NOT NULL,
      provider CHARACTER VARYING(30),
      status CHARACTER VARYING(20),
      copywrite_name CHARACTER VARYING(20),
      sms_parameters jsonb,
      copywrite_content CHARACTER VARYING(200)
      --primary key (user_id,mobile_number,send_time)
  ); --comment '历史待发送用户集合'
DROP TABLE IF EXISTS wqw.daily_idle_sms_recall;
CREATE TABLE IF NOT EXISTS wqw.daily_idle_sms_recall(
      id SERIAL,
      user_id INTEGER NOT NULL,
      name CHARACTER VARYING(50),
      gender gender,
      mobile_number CHARACTER VARYING(50),
      operator CHARACTER VARYING(20),
      group_id  INTEGER NOT NULL,
      send_time TIMESTAMP WITHOUT TIME ZONE NOT NULL,
      provider CHARACTER VARYING(30),
      status CHARACTER VARYING(20),
      copywrite_name CHARACTER VARYING(20),
      sms_parameters jsonb,
      copywrite_content CHARACTER VARYING(200),
      PRIMARY KEY (user_id,mobile_number,send_time)
);
--CREATE TABLE IF NOT EXISTS wqw.daily_idle_sms_recall ( like wqw.daily_idle_sms_recall_tmp);
--ALTER TABLE wqw.daily_idle_sms_recall ADD CONSTRAINT pk_daily_idle_sms_recall PRIMARY KEY (user_id,mobile_number,send_time);
--COMMON ON TABLE wqw.daily_idle_sms_recall IS '存储当天待发送的SMS Recall用户信息(含对照组)';
DELETE FROM wqw.daily_idle_sms_recall_tmp;
--\COPY wqw.daily_idle_sms_recall_tmp FROM '$tmpfile' DELIMITER E'\t';
\COPY wqw.daily_idle_sms_recall_tmp FROM 'data/20170727/data_merge.txt' DELIMITER E'\t';
INSERT INTO wqw.daily_idle_sms_recall (user_id,name,gender,mobile_number,operator,group_id,send_time,provider,status,copywrite_name,sms_parameters,copywrite_content)
  SELECT 
    user_id,name,gender,mobile_number,operator,group_id,send_time,provider,status,copywrite_name,sms_parameters,copywrite_content
    --CAST(user_id AS INTEGER),name,gender,mobile_number,operator,group_id,send_time,provider,status,copywrite_name,sms_parameters,copywrite_content
    --to_date(dt,'YYYYMMDD'),uid,name,phone,gender,net,group_id,other
  FROM wqw.daily_idle_sms_recall_tmp
  ON CONFLICT DO NOTHING; 
--SQL
