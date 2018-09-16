#上传文件至Hadoop 
hadoop='/home/wangqiwen/bin/CDH-5.10.0-1.cdh5.10.0.p0.41/bin/hadoop'
hive='/home/wangqiwen/bin/CDH-5.10.0-1.cdh5.10.0.p0.41/bin/hive'
#=================================
#[2017-7-4]统计最近一个月已发送用户数据准确性
#[2018-8-4]root账号下的JAVA_HOME设置失败
JAVA_HOME="/home/wangqiwen/bin/java/jdk1.7.0_80"
local_path="../../data"
save_path="../../merge_data"
hadoop_path="/user/wangqiwen/sms_recall/data"
hive_cmd="create_daily_hive.sql"
cur_dir=`pwd`
#num=5
#num=60
num=1
#end=`date +%Y-%m-%d -d "-1 days ago"`
end=`date +%Y%m%d`
#end='2017-07-31'
end='2017-08-01'
send_name="data_send.txt"
done_name="data_done.txt"
error_name="data_error.txt"
output_name="data_merge.txt"
for((i=0;i<num;i++))
do
  #dt=`date -d "$i days ago $end"  +%Y-%m-%d `
  dt=`date -d "$i days ago $end"  +%Y%m%d `
  #num=`psql -f get_uniq.sql -v dt=$dt|awk '{if($1~/^[0-9]+$/)print $1}'`
  out="$dt"
  #待发送文件
  send_file="${save_path}/data/$dt/$send_name"
  [ -f $send_file ]&& { echo "${send_file}已存在,清空";>$send_file; } || { echo "${send_file}不存在,创建";mkdir -p ${send_file%/*}&&>$send_file; }
  for file in `echo "output_500w3day.txt output_500w3day_telecom.txt output_500w3day_test.txt"`
  do
    myfile="${local_path}/${dt}/${file}"
    [ ! -f $myfile ] && { echo "$myfile 不存在";continue; }||{ cat $myfile>>$send_file; }
  done
  #已发送文件
  done_file="${save_path}/data/$dt/$done_name"
  [ -f $done_file ]&& { echo "${done_file}已存在,清空";>$done_file; } || { echo "${done_file}不存在,创建";mkdir -p ${done_file%/*}&&>$done_file; }
  for file in `echo "doneUser_500w3day.txt doneUser_500w3day_telecom.txt doneUser_500w3day_test.txt"`
  do
    myfile="${local_path}/${dt}/${file}"
    [ ! -f $myfile ] && { echo "$myfile 不存在";continue; }||{ cat $myfile>>$done_file; }
  done
  #失败文件
  error_file="${save_path}/data/$dt/$error_name"
  [ -f $error_file ]&& { echo "${error_file}已存在,清空";>$error_file; } || { echo "${error_file}不存在,创建";mkdir -p ${error_file%/*}&&>$error_file; }
  for file in `echo "errorUser_500w3day.txt errorUser_500w3day_telecom.txt errorUser_500w3day_test.txt"`
  do
    myfile="${local_path}/${dt}/${file}"
    [ ! -f $myfile ] && { echo "$myfile 不存在";continue; }||{ cat $myfile>>$error_file; }
  done
  output_file="${save_path}/data/$dt/$output_name"
  #[ -f "$myfile" ] && out_done=`less $myfile | awk '{d[$1]+=1;count+=1}END{print length(d)"\t"count}'` || out_done="-\t-"
  echo -e "[`date +%H:%M:%S`][$dt]开始转换格式${myfile}"
  python format.py $cur_dir $dt $send_file $done_file $error_file > $output_file
  echo -e "[`date +%H:%M:%S`][$dt]转换前:"
  head -3 $send_file
  echo -e "[`date +%H:%M:%S`][$dt]转换后:"
  head -3 $output_file
  #上传至Hadoop
  local_file=$output_file
  #local_file="${local_path}/${file}"
  hadoop_file="${hadoop_path}/${dt}"
  #hadoop_file="${hadoop_dest}/${file}"
  #$hadoop fs -ls /
  #hadoop fs -tail /user/wangqiwen/sms_recall/send/20170727/output_500w3day.txt
  $hadoop fs -test -e $hadoop_file
  [ $? -eq 0 ]&&{ echo "[`date +%H:%M:%S`][$dt]目录已存在:${hadoop_file},删除";$hadoop fs -rm $hadoop_file/*; }||{
    echo "[`date +%H:%M:%S`][$dt]目录不存在:${hadoop_file},开始创建";
    $hadoop fs -mkdir -p $hadoop_file
    [ $? -ne 0 ]&&{ echo "[`date +%H:%M:%S`][$dt]目录创建失败,退出";exit 1; }||{ echo "[`date +%H:%M:%S`][$dt]目录创建完毕"; }
  }
  echo "[`date +%H:%M:%S`][$dt]开始上传本地文件到Hadoop: $local_file -> $hadoop_file"
  $hadoop fs -put $local_file $hadoop_file
  [ $? -ne 0 ]&&{ echo "[`date +%H:%M:%S`][$dt]文件上传失败，退出";exit 1; }||{ echo "[`date +%H:%M:%S`][$dt]文件上传成功"; }
  $hive -f $hive_cmd -hivevar date=$dt
  [ $? -ne 0 ]&&{ echo "[`date +%H:%M:%S`][$dt]Hive外部表创建失败，退出";exit 1; }||{ echo "[`date +%H:%M:%S`][$dt]Hive外部表创建成功"; }
done
echo -e "[`date +%H:%M:%S`]所有${num}天数据处理完毕..."
