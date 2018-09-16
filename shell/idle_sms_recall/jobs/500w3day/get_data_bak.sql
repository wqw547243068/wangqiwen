--\copy ( ... ) to 'input.txt' delimiter ',' csv header; -- copy命令不能换行!
create or replace view wqw.sms_recall_500w3day as

SELECT
        cu.user_id,
        cu.mobile_number,
        cu.gender
FROM
        core_users cu
LEFT JOIN
        usersandtokens ut USING(user_id)
WHERE
        cu.status = 'default'
AND (
        date(ut.last_activity) = DATE(date(nowcst()) - '7 day'::interval)
OR      date(ut.last_activity) = DATE(date(nowcst()) - '15 day'::interval)
OR      date(ut.last_activity) = DATE(date(nowcst()) - '22 day'::interval)
OR      date(ut.last_activity) = DATE(date(nowcst()) - '30 day'::interval)
OR      date(ut.last_activity) = DATE(date(nowcst()) - '37 day'::interval)
OR      date(ut.last_activity) = DATE(date(nowcst()) - '45 day'::interval)
OR      date(ut.last_activity) = DATE(date(nowcst()) - '52 day'::interval)
OR      date(ut.last_activity) = DATE(date(nowcst()) - '60 day'::interval)
OR      date(ut.last_activity) = DATE(date(nowcst()) - '90 day'::interval)
OR      date(ut.last_activity) = DATE(date(nowcst()) - '120 day'::interval)
OR      date(ut.last_activity) = DATE(date(nowcst()) - '150 day'::interval)
OR      date(ut.last_activity) = DATE(date(nowcst()) - '180 day'::interval)
);
--start to download data
--\copy ( select * from wqw.sms_recall_500w3day ) to :'output';
--\copy ( select * from wqw.sms_recall_500w3day ) to 'input.txt';

