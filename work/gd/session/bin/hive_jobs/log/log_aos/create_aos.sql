-- usage: hive -S --hivevar date1=2014/05/21 --hivevar date=20140521 -f create_aos.sql
-- hadoop fs -touchz /user/hive/warehouse/log_session.db/log_aos/ready_20140524.done
-- 2014-7-8
--set mapred.max.map.failures.percent=1;
set mapred.output.compression.codec = org.apache.hadoop.io.compress.GzipCodec;
set mapred.max.map.failures.percent = 30;
set mapred.skip.map.max.skip.records = 1;
set hive.exec.compress.output=true;
set mapred.output.compress=true;
--set mapred.map.max.attempts = 1;
use log_session;

add file ${hivevar:path}/mapper.py;
add file ${hivevar:path}/../../../tool/aos.txt;
add file ${hivevar:path}/../../../tool/func.py;
add file ${hivevar:path}/../../../tool/xy2ccode.py;
add file ${hivevar:path}/../../../tool/xy2city.txt;
add file ${hivevar:path}/../../../tool/adcode.csv;

create external table if not exists log_aos_raw_dxp_old
    (
        line string comment 'raw data from HDFS'
    )
    partitioned by (dt string,hour string,min string)
    location "/user/ops/flume/aos/aos_dxp/";

create external table if not exists log_aos_oss_raw
    (
        line string comment 'raw data from HDFS'
    )
    partitioned by (dt string,hour string,min string)
    location "/user/ops/flume/aos_oss/aos_oss_dxp/";

create external table if not exists log_aos_sns_raw
    (
        line string comment 'raw data from HDFS'
    )
    partitioned by (dt string)
    location "/user/ops/flume/aos_sns/";

create external table if not exists log_aos_ali_raw
    (
        line string comment 'raw data from HDFS'
    )
    partitioned by (dt string)
    location "/user/ops/flume/aos/aos_ali";

set file;
alter table log_aos_sns_raw drop if exists partition (dt='${hivevar:date}');
alter table log_aos_sns_raw add if not exists partition (dt='${hivevar:date}') location '${hivevar:date1}';
--alter table log_aos_raw_dxp_old drop if exists partition (dt='${hivevar:date}');
alter table log_aos_ali_raw drop if exists partition (dt='${hivevar:date}');
alter table log_aos_ali_raw add if not exists partition (dt='${hivevar:date}') location '${hivevar:date1}';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='00',min='00') location '${hivevar:date1}/00/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='00',min='15') location '${hivevar:date1}/00/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='00',min='30') location '${hivevar:date1}/00/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='00',min='45') location '${hivevar:date1}/00/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='01',min='00') location '${hivevar:date1}/01/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='01',min='15') location '${hivevar:date1}/01/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='01',min='30') location '${hivevar:date1}/01/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='01',min='45') location '${hivevar:date1}/01/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='02',min='00') location '${hivevar:date1}/02/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='02',min='15') location '${hivevar:date1}/02/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='02',min='30') location '${hivevar:date1}/02/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='02',min='45') location '${hivevar:date1}/02/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='03',min='00') location '${hivevar:date1}/03/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='03',min='15') location '${hivevar:date1}/03/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='03',min='30') location '${hivevar:date1}/03/30/';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='03',min='45') location '${hivevar:date1}/03/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='04',min='00') location '${hivevar:date1}/04/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='04',min='15') location '${hivevar:date1}/04/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='04',min='30') location '${hivevar:date1}/04/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='04',min='45') location '${hivevar:date1}/04/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='05',min='00') location '${hivevar:date1}/05/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='05',min='15') location '${hivevar:date1}/05/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='05',min='30') location '${hivevar:date1}/05/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='05',min='45') location '${hivevar:date1}/05/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='06',min='00') location '${hivevar:date1}/06/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='06',min='15') location '${hivevar:date1}/06/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='06',min='30') location '${hivevar:date1}/06/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='06',min='45') location '${hivevar:date1}/06/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='07',min='00') location '${hivevar:date1}/07/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='07',min='15') location '${hivevar:date1}/07/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='07',min='30') location '${hivevar:date1}/07/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='07',min='45') location '${hivevar:date1}/07/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='08',min='00') location '${hivevar:date1}/08/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='08',min='15') location '${hivevar:date1}/08/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='08',min='30') location '${hivevar:date1}/08/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='08',min='45') location '${hivevar:date1}/08/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='09',min='00') location '${hivevar:date1}/09/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='09',min='15') location '${hivevar:date1}/09/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='09',min='30') location '${hivevar:date1}/09/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='09',min='45') location '${hivevar:date1}/09/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='10',min='00') location '${hivevar:date1}/10/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='10',min='15') location '${hivevar:date1}/10/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='10',min='30') location '${hivevar:date1}/10/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='10',min='45') location '${hivevar:date1}/10/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='11',min='00') location '${hivevar:date1}/11/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='11',min='15') location '${hivevar:date1}/11/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='11',min='30') location '${hivevar:date1}/11/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='11',min='45') location '${hivevar:date1}/11/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='12',min='00') location '${hivevar:date1}/12/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='12',min='15') location '${hivevar:date1}/12/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='12',min='30') location '${hivevar:date1}/12/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='12',min='45') location '${hivevar:date1}/12/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='13',min='00') location '${hivevar:date1}/13/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='13',min='15') location '${hivevar:date1}/13/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='13',min='30') location '${hivevar:date1}/13/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='13',min='45') location '${hivevar:date1}/13/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='14',min='00') location '${hivevar:date1}/14/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='14',min='15') location '${hivevar:date1}/14/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='14',min='30') location '${hivevar:date1}/14/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='14',min='45') location '${hivevar:date1}/14/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='15',min='00') location '${hivevar:date1}/15/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='15',min='15') location '${hivevar:date1}/15/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='15',min='30') location '${hivevar:date1}/15/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='15',min='45') location '${hivevar:date1}/15/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='16',min='00') location '${hivevar:date1}/16/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='16',min='15') location '${hivevar:date1}/16/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='16',min='30') location '${hivevar:date1}/16/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='16',min='45') location '${hivevar:date1}/16/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='17',min='00') location '${hivevar:date1}/17/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='17',min='15') location '${hivevar:date1}/17/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='17',min='30') location '${hivevar:date1}/17/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='17',min='45') location '${hivevar:date1}/17/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='18',min='00') location '${hivevar:date1}/18/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='18',min='15') location '${hivevar:date1}/18/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='18',min='30') location '${hivevar:date1}/18/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='18',min='45') location '${hivevar:date1}/18/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='19',min='00') location '${hivevar:date1}/19/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='19',min='15') location '${hivevar:date1}/19/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='19',min='30') location '${hivevar:date1}/19/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='19',min='45') location '${hivevar:date1}/19/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='20',min='00') location '${hivevar:date1}/20/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='20',min='15') location '${hivevar:date1}/20/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='20',min='30') location '${hivevar:date1}/20/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='20',min='45') location '${hivevar:date1}/20/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='21',min='00') location '${hivevar:date1}/21/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='21',min='15') location '${hivevar:date1}/21/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='21',min='30') location '${hivevar:date1}/21/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='21',min='45') location '${hivevar:date1}/21/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='22',min='00') location '${hivevar:date1}/22/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='22',min='15') location '${hivevar:date1}/22/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='22',min='30') location '${hivevar:date1}/22/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='22',min='45') location '${hivevar:date1}/22/45';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='23',min='00') location '${hivevar:date1}/23/00';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='23',min='15') location '${hivevar:date1}/23/15';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='23',min='30') location '${hivevar:date1}/23/30';
alter table log_aos_raw_dxp_old add if not exists partition(dt='${hivevar:date}',hour='23',min='45') location '${hivevar:date1}/23/45';


alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='00',min='00') location '${hivevar:date1}/00/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='00',min='15') location '${hivevar:date1}/00/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='00',min='30') location '${hivevar:date1}/00/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='00',min='45') location '${hivevar:date1}/00/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='01',min='00') location '${hivevar:date1}/01/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='01',min='15') location '${hivevar:date1}/01/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='01',min='30') location '${hivevar:date1}/01/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='01',min='45') location '${hivevar:date1}/01/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='02',min='00') location '${hivevar:date1}/02/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='02',min='15') location '${hivevar:date1}/02/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='02',min='30') location '${hivevar:date1}/02/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='02',min='45') location '${hivevar:date1}/02/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='03',min='00') location '${hivevar:date1}/03/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='03',min='15') location '${hivevar:date1}/03/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='03',min='30') location '${hivevar:date1}/03/30/';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='03',min='45') location '${hivevar:date1}/03/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='04',min='00') location '${hivevar:date1}/04/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='04',min='15') location '${hivevar:date1}/04/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='04',min='30') location '${hivevar:date1}/04/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='04',min='45') location '${hivevar:date1}/04/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='05',min='00') location '${hivevar:date1}/05/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='05',min='15') location '${hivevar:date1}/05/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='05',min='30') location '${hivevar:date1}/05/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='05',min='45') location '${hivevar:date1}/05/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='06',min='00') location '${hivevar:date1}/06/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='06',min='15') location '${hivevar:date1}/06/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='06',min='30') location '${hivevar:date1}/06/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='06',min='45') location '${hivevar:date1}/06/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='07',min='00') location '${hivevar:date1}/07/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='07',min='15') location '${hivevar:date1}/07/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='07',min='30') location '${hivevar:date1}/07/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='07',min='45') location '${hivevar:date1}/07/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='08',min='00') location '${hivevar:date1}/08/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='08',min='15') location '${hivevar:date1}/08/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='08',min='30') location '${hivevar:date1}/08/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='08',min='45') location '${hivevar:date1}/08/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='09',min='00') location '${hivevar:date1}/09/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='09',min='15') location '${hivevar:date1}/09/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='09',min='30') location '${hivevar:date1}/09/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='09',min='45') location '${hivevar:date1}/09/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='10',min='00') location '${hivevar:date1}/10/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='10',min='15') location '${hivevar:date1}/10/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='10',min='30') location '${hivevar:date1}/10/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='10',min='45') location '${hivevar:date1}/10/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='11',min='00') location '${hivevar:date1}/11/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='11',min='15') location '${hivevar:date1}/11/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='11',min='30') location '${hivevar:date1}/11/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='11',min='45') location '${hivevar:date1}/11/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='12',min='00') location '${hivevar:date1}/12/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='12',min='15') location '${hivevar:date1}/12/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='12',min='30') location '${hivevar:date1}/12/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='12',min='45') location '${hivevar:date1}/12/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='13',min='00') location '${hivevar:date1}/13/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='13',min='15') location '${hivevar:date1}/13/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='13',min='30') location '${hivevar:date1}/13/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='13',min='45') location '${hivevar:date1}/13/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='14',min='00') location '${hivevar:date1}/14/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='14',min='15') location '${hivevar:date1}/14/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='14',min='30') location '${hivevar:date1}/14/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='14',min='45') location '${hivevar:date1}/14/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='15',min='00') location '${hivevar:date1}/15/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='15',min='15') location '${hivevar:date1}/15/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='15',min='30') location '${hivevar:date1}/15/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='15',min='45') location '${hivevar:date1}/15/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='16',min='00') location '${hivevar:date1}/16/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='16',min='15') location '${hivevar:date1}/16/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='16',min='30') location '${hivevar:date1}/16/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='16',min='45') location '${hivevar:date1}/16/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='17',min='00') location '${hivevar:date1}/17/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='17',min='15') location '${hivevar:date1}/17/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='17',min='30') location '${hivevar:date1}/17/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='17',min='45') location '${hivevar:date1}/17/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='18',min='00') location '${hivevar:date1}/18/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='18',min='15') location '${hivevar:date1}/18/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='18',min='30') location '${hivevar:date1}/18/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='18',min='45') location '${hivevar:date1}/18/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='19',min='00') location '${hivevar:date1}/19/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='19',min='15') location '${hivevar:date1}/19/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='19',min='30') location '${hivevar:date1}/19/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='19',min='45') location '${hivevar:date1}/19/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='20',min='00') location '${hivevar:date1}/20/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='20',min='15') location '${hivevar:date1}/20/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='20',min='30') location '${hivevar:date1}/20/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='20',min='45') location '${hivevar:date1}/20/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='21',min='00') location '${hivevar:date1}/21/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='21',min='15') location '${hivevar:date1}/21/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='21',min='30') location '${hivevar:date1}/21/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='21',min='45') location '${hivevar:date1}/21/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='22',min='00') location '${hivevar:date1}/22/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='22',min='15') location '${hivevar:date1}/22/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='22',min='30') location '${hivevar:date1}/22/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='22',min='45') location '${hivevar:date1}/22/45';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='23',min='00') location '${hivevar:date1}/23/00';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='23',min='15') location '${hivevar:date1}/23/15';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='23',min='30') location '${hivevar:date1}/23/30';
alter table log_aos_oss_raw add if not exists partition(dt='${hivevar:date}',hour='23',min='45') location '${hivevar:date1}/23/45';

create table if not exists log_aos  like log_sp;

alter table log_aos drop if exists partition (dt='${hivevar:date}');  --20140102
alter table log_aos add if not exists partition (dt='${hivevar:date}');

insert overwrite table log_aos  partition (dt='${hivevar:date}')
select transform(*)
	using 'python mapper.py'
        as (
		uid string,
		sessionid string,
		stepid string,
		time string,
		position map<string,string>,
		source string,
		action string,
		request map<string,string>,
		response map<string,string>,
		cellphone map<string,string>,
		other map<string,string>
	)
    from
    (
        select line,dt from log_aos_raw_dxp_old where dt='${hivevar:date}'
        union all
        select line,dt from log_aos_sns_raw where dt='${hivevar:date}'
		union all
		select line,dt from log_aos_oss_raw where dt='${hivevar:date}'
		union all
		select line,dt from log_aos_ali_raw where dt='${hivevar:date}'
    )log_aos_tmp
    distribute by uid
    sort by uid,sessionid,cast(stepid as int),time;

