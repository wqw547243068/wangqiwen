--create or replace view wqw.last5day_users as 
\copy (  select distinct user_id from yay.dailyuseractivities where date_time >= DATE(date(nowcst()) - '1 day'::interval) ) to 'data_day.txt';

