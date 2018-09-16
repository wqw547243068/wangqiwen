create table if not exists wqw.sms_daily_180_new as
SELECT
        cu.user_id,
        cu.mobile_number,
        cu.gender,
        ut.last_activity
FROM
        stats.core_users cu --[2017-07-12]原表权限收回，加上schema
LEFT JOIN
        usersandtokens ut USING(user_id)
WHERE
        cu.status = 'default'
        and cu.mobile_number is not null
        and date(ut.last_activity) < DATE(date(nowcst()) - '180 day'::interval);
--\copy (select * from wqw.sms_daily_180_new) to 'data_180_new.txt';
