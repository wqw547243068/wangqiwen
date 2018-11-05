
disk_result_file='disk_rest.txt'
alarm_mail_prefix='warren,jeff,randy,clay,huo.zhu,kerui.ji,haiming.zhang,yao.rao'
alarm_mail_receiver="${alarm_mail_prefix//,/@autonavi.com,}@autonavi.com"
max_per='95'
df -h > $disk_result_file
rest_num=`cat $disk_result_file | awk '{if(NR==2)print $4}'`
rest_per=`cat $disk_result_file | awk '{if(NR==2)print $5}'`
if [[ $rest_per > 95 ]];then
    #title='磁盘空间不足,已占用$rest_per,剩余$rest_num,请及时清理空间,避免线上模块挂掉...'
    title="Disk(/dev/sda1 ) space is insufficient, $rest_per(>$max_per) used, $rest_num rested, please clear up data as soon as possible to avoid online module's failure ..."
    cat $disk_result_file | mail -s "[ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] $title"  $alarm_mail_receiver
else
    echo "[INFO] [`date "+%Y-%m-%d %H:%M:%S"`] 磁盘空间充足:$rest_num,$rest_per"
fi


