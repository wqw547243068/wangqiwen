set names utf8;
create database if not exists cube;
use cube;
create table if not exists log_sp_stat(
    date varchar(20) not null,
    citycode varchar(10) not null,
    user_loc_city varchar(10) not null,
    div0 varchar(50) not null,   
    action varchar(10) not null,
    search_sceneid varchar(10) not null,
    pv int,
    uv int,
    stepid_null int,
    id int ,
    name int ,
    sug int ,
    keyword int ,
    category int ,
    is_general int ,
    no_res int ,
    jiucuo int ,
    first_page int,
    geo int ,
    city_sug int,
	is_general_firstpage int,
	may_sug_pv int ,
	sug_pv int,
	pv_dire_words int,
	count_my_loc int
);

-- exception values
-- insert into log_sp_stat values('-','-','-','-');
-- load data local infile 'data.txt' into table log_sp_stat;
-- delete from log_sp_stat where date='20140904'; 


