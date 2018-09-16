--copy "USERS"("COL00","COL01","COL02") FROM '/home/test/pg_1m.txt'  DELIMITER '|'  ENCODING 'utf-8'
--drop table if exists wqw.sms_recall_done;
    create table if not exists wqw.sms_recall_done
    (
      phone character varying(50) not null,
      name character varying(50),
      time timestamp without time zone,
      cwname character varying(50),
      gender character varying(50),
      cwcontent character varying(200),
      primary key (phone,time)
    ); 
    \copy wqw.sms_recall_done FROM '$doneFile' ENCODING 'utf-8';

\copy wqw.sms_recall_done FROM ":'local_file'"  ENCODING 'utf-8';
--\copy wqw.sms_recall_done FROM '../online/data/20170601/doneUser.txt'  ENCODING 'utf-8';
--\copy "wqw.sms_recall_done" ("phone","name","time","cwname","cwcontent") FROM '../online/data/20170601/saveUser.txt'  DELIMITER '\t'  ENCODING 'utf-8'
