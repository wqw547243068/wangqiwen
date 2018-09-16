select s.user_id,age_calculator(a.birthdate) as age from wqw.sms_daily_500w3day_raw s LEFT JOIN stats.core_users a on s.user_id = a.user_id limit 10;
