set names utf8;
create database if not exists cube;
use cube;
create table if not exists no_result_stat(
    date varchar(20) not null,
    citycode varchar(50) not null,
    div0 varchar(50) not null,
    action varchar(50),
    source varchar(50),
    old_pv int(10),
    new_pv int(10),
    jiucuo int(10),
    no_res_num int(10),
    no_res_geo int(10),
	filter_num int(10)
);
-- exception values
-- insert into query_data values('-','-','-','-');
-- load data local infile 'data.txt' into table no_res_stat;


