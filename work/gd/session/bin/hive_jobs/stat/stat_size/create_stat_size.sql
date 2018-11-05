use log_data;
-- hive -f create_stat.sql -hivevar file=data_size.txt -hivevar date=20140601 
--add file '${hivevar:out_path}'/data_size.txt;
create table if not exists stat_size
    (
		source string,
        raw_size string,
        log_size string
    )partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
--    line terminated by '\n'
    stored as textfile;
 
--alter table stat_size drop if exists partition (dt='${hivevar:date}');
load data local inpath '${hivevar:file}' overwrite into table stat_size partition (dt='${hivevar:date}');
