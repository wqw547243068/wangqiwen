#============vars=============
# mysql -h10.17.129.55 -uroot -proot
#host='127.0.0.1'
host='10.17.129.55'
user='root'
passwd='root'
database='cube'
#hadoop='sudo -u devuse /opt/bin/hadoop/bin/hadoop'
#hive='sudo -u devuse /opt/bin/hadoop/bin/hive'
hadoop='/usr/bin/hadoop'
hive='/data/soft/hadoop2/hive/bin/hive'
#==========function===================
log(){
    echo "[$0] [$1] [`date "+%Y-%m-%d %H:%M:%S"`] $2"
}
check(){
    if [ $? -ne 0 ];then
        log "ERROR" "命令执行失败: $1 !"
        [ $# -lt 2 ]&& return 0
        [ $2 -eq 1 ] && { log "ERROR" "退出程序...";exit -1; } || { log "ERROR" "忽略错误,继续执行..."; }
    else
        log "INFO" "命令执行成功: $1 !"
    fi
}

