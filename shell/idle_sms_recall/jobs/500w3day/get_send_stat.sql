--[2017-6-27]统计resend发送次数分布
WITH send_freq AS (
    SELECT
            rs.user_id AS user_id,            -- 待发送的user_id
            coalesce(count(h.user_id), 0) AS freq    -- 待发送的user_id 出现的次数
    FROM
            wqw.sms_daily_500w3day_send rs    -- 此表是临时文件，是今天准备发送sms的用户信息
    LEFT JOIN
            wqw.sms_daily_done h ON (rs.user_id = h.user_id and h.dt::timestamp >= date(nowcst()) - '30 day'::interval)  -- 历史发送用户信息文件,可调整时间间隔，h表中max_time是6月22日
    WHERE rs.dt::timestamp = date(nowcst())
    GROUP BY 1
), total AS ( 
                SELECT 
                        COUNT(DISTINCT user_id) AS num 
                FROM
                        wqw.sms_daily_500w3day_send a
                WHERE a.dt::timestamp = date(nowcst())
             )
SELECT 
        freq+1 "发送次数", --(1表示首次发送) 
        COUNT(user_id) AS "人数",   -- 总的发送人数 
        num "当天总人数",
        ROUND(
              CASE
                    WHEN COUNT(user_id) > 0 THEN COUNT(user_id)::NUMERIC * 100 / num::NUMERIC
                    ELSE NULL::NUMERIC
        END, 4) AS "频次占比(%)"
FROM
        send_freq, total
GROUP BY 1,num
ORDER BY 1
;
