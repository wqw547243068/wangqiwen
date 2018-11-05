create database if not exists log_data;
use log_data;
create table if not exists no_result_stat(
	    type string,
	    value string,
	    ratio string,
	    info string
    )
    partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
        --collection items terminated by '\002'
        --map keys terminated ny '\003'
    stored as textfile;

load data local inpath '${hivevar:file}' overwrite into table no_result_stat partition(dt='${hivevar:date}');
