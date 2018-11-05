set names utf8;
create database if not exists cube;
use cube;
create table if not exists query_data(
    date varchar(20) not null,
    citycode varchar(50) not null,
    div0 varchar(50) not null,
    pv int(10),
    uv int(10),
    geo_num int(10),
    no_res_num int(10),
    click_num int(10),
    valid_click_num int(10),
    page_turn_num int(10),
    general_num int(10),
    query_num int(10)
);
-- exception values
-- insert into query_data values('-','-','-','-');
