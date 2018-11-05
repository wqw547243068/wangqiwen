use log_session;
drop table if exists new_aos;
create external table new_aos
    (
        line string
    )
    partitioned by (dt string)
    location '/user/ops/flume/aos/aos_dxp/';
--alter table drop if exists partition(dt='20140528');
alter table new_aos add partition(dt='20140528') location '2014/05/28/08';
