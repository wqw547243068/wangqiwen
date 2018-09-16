WITH tmp AS (
      SELECT
          cu.user_id as user_id,
          cu.mobile_number as phone,
          cu.gender as gender
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
  OR      date(ut.last_activity) = DATE(date(nowcst()) - '180 day'::interval)
  )
), sent_phone AS (
    select 
            distinct phone 
    from 
            wqw.sms_recall_done 
    where time > DATE(date(nowcst()) - '7 d'::interval )
)
SELECT
      tmp.*
FROM
      tmp 
LEFT JOIN
      sent_phone USING(phone)
WHERE
      sent_phone.phone IS NULL

