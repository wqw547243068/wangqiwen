--[2017-7-5] 每天发送sms召回短信各通道的对应信息
WITH sms_table AS (
    SELECT
            td.net AS "运营商",
            COUNT(td.user_id) AS "总用户数量", --total_user,
            COUNT(td.user_id) FILTER (WHERE td.groupid = '1') AS "实验组用户数量",--total_send,
            COUNT(td.user_id) FILTER (WHERE td.groupid = '0') AS "对照组用户数量",--total_not_send,
            COUNT(d.user_id) AS "总活跃用户数量",--total_active,
            COUNT(d.user_id) FILTER (WHERE td.groupid = '1') AS "实验组活跃用户数量",--send_active,
            COUNT(d.user_id) FILTER (WHERE td.groupid = '0') AS "对照组活跃用户数量",--not_send_active,
            ROUND(
                    CASE
                            WHEN COUNT(td.user_id) FILTER (WHERE td.groupid = '1') > 0 
                            THEN COUNT(d.user_id) FILTER (WHERE td.groupid = '1') ::NUMERIC / COUNT(td.user_id) FILTER (WHERE td.groupid = '1')::NUMERIC
                            ELSE NULL::NUMERIC
            END, 4) AS "实验组活跃率",--send_active_ratio,
            ROUND(
                    CASE
                            WHEN COUNT(td.user_id) FILTER (WHERE td.groupid = '0') > 0 
                            THEN COUNT(d.user_id) FILTER (WHERE td.groupid = '0') ::NUMERIC / COUNT(td.user_id) FILTER (WHERE td.groupid = '0')::NUMERIC
                            ELSE NULL::NUMERIC
            END, 4) AS "对照组活跃率"--not_send_active_ratio
    FROM
            wqw.sms_daily_500w3day_send td
    LEFT JOIN
            dailyuseractivities d ON (d.user_id = td.user_id AND d.date_time = DATE(td.dt))   
    WHERE 
            DATE(td.dt) = DATE(nowcst()) - '1 day'::INTERVAL        
    GROUP BY 1
    ORDER BY 1
)
SELECT 
        "运营商",
        "总用户数量",
        "实验组用户数量",
        "对照组用户数量",
        "总活跃用户数量",
        "实验组活跃用户数量",
        "对照组活跃用户数量",
        "实验组活跃率",
        "对照组活跃率",
        ROUND(
                CASE
                        WHEN "实验组用户数量" > 0
                        THEN ("实验组活跃用户数量" - "实验组活跃用户数量" * "对照组活跃率") ::NUMERIC / "实验组用户数量" ::NUMERIC
                        ELSE NULL::NUMERIC
        END, 4) AS "召回率"
FROM
        sms_table s
GROUP BY 1,2,3,4,5,6,7,8,9
ORDER BY 1;
--七天内总体召回率的变化
WITH second_table AS(
SELECT
      date(td.dt) AS date_time,
      COUNT(td.user_id) FILTER (WHERE td.groupid = '1') AS total_send,     --"实验组用户数量",
      COUNT(d.user_id) FILTER (WHERE td.groupid = '1') AS send_active,     --"实验组活跃用户数量"       
      ROUND(
              CASE
                    WHEN COUNT(td.user_id) FILTER (WHERE td.groupid = '0') > 0 
                    THEN COUNT(d.user_id) FILTER (WHERE td.groupid = '0') ::NUMERIC / COUNT(td.user_id) FILTER (WHERE td.groupid = '0')::NUMERIC
                    ELSE NULL::NUMERIC
      END, 4) AS not_send_active_ratio                                     --"对照组活跃率"
FROM
      wqw.sms_daily_500w3day_send td                                       -- 这个表只从2017-06-28才有数据
LEFT JOIN
      dailyuseractivities d ON (d.user_id = td.user_id AND d.date_time = DATE(td.dt))   
WHERE 
      DATE(td.dt) BETWEEN date(nowcst() - '7 day'::interval) AND date(nowcst() - '1 day'::interval)      --时间可修改，输出七天内的总体召回率
GROUP BY 1
ORDER BY 1
)
SELECT 
        date_time,
        ROUND(
                (send_active ::NUMERIC - (send_active ::NUMERIC * not_send_active_ratio ::NUMERIC))/total_send ::NUMERIC
              , 4) AS recall_ratio
FROM    
        second_table
GROUP BY 1,send_active,not_send_active_ratio,total_send
ORDER BY 1;

