set names utf8;
create database if not exists cube;
use cube;
create table if not exists time_info(
	date varchar(20) not null primary key,
	year varchar(10),
	quarter varchar(5),
	month varchar(5),
	day varchar(5),
	week  varchar(20)
);
/*drop table if exists time_info;*/
/*
create table if not exists location_info(
	citycode varchar(10) not null primary key,
	adcode varchar(10),
	province_zh varchar(50),
	province_en varchar(50),
	city_zh varchar(50),
	city_en  varchar(50)
);

create table if not exists div_info(
	div0 varchar(10) not null primary key,
	os varchar(10),
	device varchar(10),
	version varchar(10)
);

create table if not exists query_type_info(
	query_type varchar(10) not null primary key
);
*/

