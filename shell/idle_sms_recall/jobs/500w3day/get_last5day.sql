create or replace view wqw.last5day_users as 
select distinct user_id from yay.dailyuseractivities where date_time >= DATE(date(nowcst()) - '5 day'::interval)

