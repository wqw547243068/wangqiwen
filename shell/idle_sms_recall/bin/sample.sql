CREATE TABLE IF NOT EXISTS GenderHiddenDaily (
  date_time timestamp NOT NULL,
  total int NOT NULL,
  male int NOT NULL,
  female int NOT NULL,
  PRIMARY KEY (date_time)
);

alter table retentiondata add constraint PK_retentiondata primary key (date_time,target_time);
ALTER TABLE users_signup ADD COLUMN location_id int DEFAULT NULL;

CREATE TABLE IF NOT EXISTS dailyStreetstyle (
  date_time date NOT NULL,
  staff character varying(50) NOT NULL,
  streetstyle int NOT NULL,
  city character varying(50) NOT NULL
);


ALTER TABLE users_signup ADD COLUMN mobile_number character varying(32);

CREATE TABLE IF NOT EXISTS affiliateChannels(
  date_time timestamp without time zone NOT NULL,
  affiliate character varying(50),
  total integer NOT NULL DEFAULT 0,
  PRIMARY KEY (date_time,affiliate)
);

ALTER TABLE users_signup ADD affiliate varchar(50) DEFAULT NULL;

CREATE TABLE IF NOT EXISTS users_devices (
  user_id serial NOT NULL,
  iphone_app_build text[],
  android_app_build text[],
  PRIMARY KEY (user_id)
);

CREATE TABLE IF NOT EXISTS hiddenUsersByChannels(
  date_time timestamp without time zone NOT NULL,
  affiliate character varying(50),
  total integer NOT NULL DEFAULT 0,
  PRIMARY KEY (date_time,affiliate)
);
