#[2017-06-05] SMS Recall配置文件
来源:/etc/putong/putong-sms-service/config.json
sudo vim /etc/putong/putong-sms-service/config.json
#debug
nohup sh start.sh -m debug -n 500w3day -t 16:00 -l 120 &
#online
nohup sh start.sh -m online -n 500w3day -t 16:00 -l 120 &
#[2017-06-20]升级机器配置文件(puppet机器ip变更)
sudo cp /etc/putong/idle-user-push.json idle-sms-recall.json


