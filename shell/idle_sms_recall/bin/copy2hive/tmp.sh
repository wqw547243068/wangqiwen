#上传文件至Hadoop 
hadoop='/home/wangqiwen/bin/CDH-5.10.0-1.cdh5.10.0.p0.41/bin/hadoop'
hive='/home/wangqiwen/bin/CDH-5.10.0-1.cdh5.10.0.p0.41/bin/hive'
#=================================
#[2017-7-4]统计最近一个月已发送用户数据准确性
local_path="data"
save_path="merge_data"
hadoop_path="/user/wangqiwen/sms_recall/data"
cur_dir="bin/copy2hive"
hive_cmd="$cur_dir/create_daily_hive.sql"
#Now=`date +%Y%m%d`
Now='20170801'
send_name="data_send.txt"
done_name="data_done.txt"
error_name="data_error.txt"
output_name="data_merge.txt"
new="${local_path}/${Now}/output_500w3day.txt"
newTelecom="${local_path}/${Now}/output_500w3day_telecom.txt"
  #待发送文件
  send_file="${save_path}/data/$Now/$send_name"
  [ -f $send_file ]&& { echo "${send_file}已存在,清空";>$send_file; } || { echo "${send_file}不存在,创建";mkdir -p ${send_file%/*}&&>$send_file; }
  #cat ${local_path}/${Now}/output_500w3day{,_telecom}.txt >> $send_file
  cat $new $newTelecom >> $send_file
  exit
  #已发送文件
  done_file="${save_path}/data/$Now/$done_name"
  [ -f $done_file ]&& { echo "${done_file}已存在,清空";>$done_file; } || { echo "${done_file}不存在,创建";mkdir -p ${done_file%/*}&&>$done_file; }
  cat ${local_path}/${Now}/doneUser_500w3day{,_telecom}.txt >> $done_file
  #失败文件
  error_file="${save_path}/data/$Now/$error_name"
  [ -f $error_file ]&& { echo "${error_file}已存在,清空";>$error_file; } || { echo "${error_file}不存在,创建";mkdir -p ${error_file%/*}&&>$error_file; }
  cat ${local_path}/${Now}/errorUser_500w3day{,_telecom}.txt >> $error_file
  #merge
  output_file="${save_path}/data/$Now/$output_name"
  #[ -f "$myfile" ] && out_done=`less $myfile | awk '{d[$1]+=1;count+=1}END{print length(d)"\t"count}'` || out_done="-\t-"
  echo -e "[`date +%H:%M:%S`][$Now]开始转换格式${myfile}"
  python $cur_dir/format.py $cur_dir $Now $send_file $done_file $error_file > $output_file
  #上传至Hadoop
  local_file=$output_file
  hadoop_file="${hadoop_path}/${Now}"
  #$hadoop fs -ls /
  #hadoop fs -tail /user/wangqiwen/sms_recall/send/20170727/output_500w3day.txt
  $hadoop fs -test -e $hadoop_file
  [ $? -eq 0 ]&&{ echo "[`date +%H:%M:%S`][$Now]目录已存在:${hadoop_file},删除";$hadoop fs -rm $hadoop_file/*; }||{
    echo "[`date +%H:%M:%S`][$Now]目录不存在:${hadoop_file},开始创建";
    $hadoop fs -mkdir -p $hadoop_file
    [ $? -ne 0 ]&&{ echo "[`date +%H:%M:%S`][$Now]目录创建失败,退出";exit 1; }||{ echo "[`date +%H:%M:%S`][$Now]目录创建完毕"; }
  }
  echo "[`date +%H:%M:%S`][$Now]开始上传本地文件到Hadoop: $local_file -> $hadoop_file"
  $hadoop fs -put $local_file $hadoop_file
  [ $? -ne 0 ]&&{ echo "[`date +%H:%M:%S`][$Now]文件上传失败，退出";exit 1; }||{ echo "[`date +%H:%M:%S`][$Now]文件上传成功"; }
  $hive -f $hive_cmd -hivevar date=$Now
  [ $? -ne 0 ]&&{ echo "[`date +%H:%M:%S`][$Now]Hive外部表创建失败，退出";exit 1; }||{ echo "[`date +%H:%M:%S`][$Now]Hive外部表创建成功"; }
echo -e "[`date +%H:%M:%S`]所有${num}天数据处理完毕..."
