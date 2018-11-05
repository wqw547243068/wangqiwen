set names utf8;
create database if not exists cube;
use cube;
create table if not exists log_sug_stat(
    date varchar(20) not null,
    citycode varchar(10) not null,
    user_loc_city varchar(10) not null,
    div0 varchar(50) not null,  
    query_src varchar(50) not null, 
    pv int,
    uv int,
    stepid_null int,
    keywords_null int ,
    sug_err int ,
    no_res int ,
    son_num int
);

-- exception values
-- insert into log_sp_stat values('-','-','-','-');
-- load data local infile 'data.txt' into table log_sp_stat;
-- delete from log_sp_stat where date='20140904'; 


