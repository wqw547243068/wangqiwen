--[2017-06-23]获取女用户的消息数
--../../../../pg/sms_recall/test/get_female.sql 
set work_mem = '8 GB';
create or replace view wqw.sms_recall_500w3day_msg as
WITH user_messages AS (
  SELECT
    s.user_id,
    COALESCE(SUM(messages_count), 0) AS all_msg,
    COALESCE(SUM(messages_count) FILTER(WHERE m.date_time > date(ut.last_activity + '8 h'::interval)), 0) AS new_msg,
    COALESCE(COUNT(distinct m.user_id) FILTER(WHERE m.date_time > date(ut.last_activity + '8 h'::interval) AND m.messages_count > 0), 0) AS new_user
  --FROM wqw.sms_daily_500w3day_send_tmp s LEFT JOIN usersAndTokens ut USING(user_id) LEFT JOIN yay.daily_messages_by_users m ON ( s.user_id = m.other_user_id )
  FROM wqw.sms_daily_500w3day_send_tmp s LEFT JOIN usersAndTokens ut USING(user_id) LEFT JOIN yay.daily_messages_by_users m ON ( s.user_id = m.other_user_id) 
  --where s.gender = "female"
  GROUP BY 1
)
SELECT
  u.user_id,
  cu.gender,
  cu.mobile_number,
  cu.name AS user_name,
  ut.last_activity + '8 h' AS last_activity,
  date_part('day', NOW() - ut.last_activity) as leave_days,
  all_msg,
  new_msg,
  new_user
FROM user_messages u JOIN usersandtokens ut USING(user_id) JOIN core_users cu USING(user_id);
--\copy ( select * from wqw.sms_recall_500w3day_msg ) to 'data_msg.txt';
