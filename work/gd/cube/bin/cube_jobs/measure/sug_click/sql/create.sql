set names utf8;
create database if not exists cube;
use cube;
create table if not exists sug_click_stat(
    date varchar(20) not null,
    adcode varchar(50) not null,
    div0 varchar(50) not null,
    all_num int(10),
    sp_num int(10),
    sug_input_num int(10),
    sug_no_display_num int(10),
    sug_no_click_num int(10),
    sug_click_num int(10),
    click_top1 int(10),
    click_top3 int(10),
    click_top5 int(10)
);

-- exception values
-- insert into query_data values('-','-','-','-');
-- load data local infile 'data.txt' into table no_res_stat;
-- delete from sug_click_stat where date='20140904'; 


