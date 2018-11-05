set names utf8;
create database if not exists cube;
use cube;

create table if not exists location_info(
	citycode varchar(10) not null primary key,
	adcode varchar(10),
	province_zh varchar(50),
	province_en varchar(50),
	city_zh varchar(50),
	city_en  varchar(50)
);
-- default values ----
insert into location_info values('-','-','-','-','-','-');
