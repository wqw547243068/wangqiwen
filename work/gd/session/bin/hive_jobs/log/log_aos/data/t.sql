use log_session;
create table if not exists tmp_aos
    (
        uid string comment 'diu,imei,user_info. diu2,diu3 and etc stored in other',
        sessionid string comment 'sessionid',
        stepid string comment 'stepid',
        time string comment 'time info: 08:34:59',
        position map<string,string> comment 'user location: (user_loc) or (x,y)..',
        source string,
        action string comment 'type of actions in source',
        request map<string,string> comment 'request info',
        response map<string,string> comment 'response info',
        cellphone map<string,string> comment 'cellphone info',
        other map<string,string> comment  'other info from raw log'
    )
    partitioned by (dt string)
    row format delimited
        fields terminated by '\t'
        collection items terminated by '\002' -- not \001
        map keys terminated by '\003'  -- not \002
    stored as textfile;


load data local inpath 'test.txt' overwrite into table tmp_aos partition (dt='20140611');
