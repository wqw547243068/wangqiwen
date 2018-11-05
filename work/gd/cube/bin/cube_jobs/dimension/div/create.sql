set names utf8;
create database if not exists cube;
use cube;

create table if not exists div_info(
	div0 varchar(10) not null primary key,
	os varchar(10),
	device varchar(10),
	version varchar(10)
);
-- default values ----
insert into div_info values('-','-','-','-');
