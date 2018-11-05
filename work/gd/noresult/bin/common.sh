#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#            File:  common.sh
#           Usage:  sh common.sh
#     Description:  定义了常用函数
#    LastModified:  6/12/2012 16:28 PM CST
#         Created:  1/4/2012 11:06 AM CST
#          AUTHOR:  warren@autonavi.com
#         COMPANY:  baidu Inc
#         VERSION:  1.0
#            NOTE:  
#===============================================================================

ulimit -c unlimited
#init_log <log_file>
init_log()#清空log文件打一条日志
{
	>$LogFile # conf/var.sh中定义
	log "====================================="
	log "LogFile=$LogFile"
	log "====================================="
}

log()
{
	echo -e "[`date "+%Y-%m-%d %H:%M:%S"`] $@"
}

#向指定的邮件发送邮件告警
#$1:    告警主题
#$2:    需要被告警的详细内容
send_alarm_mail( )
{
        if [ $# -ne 2 ]; then
                return -1
        fi
	#获取收件人列表
        echo "$2" | mail -s "$1" "$mail_receivers"
        if [ $? -ne 0 ]; then
                log "[`date "+%Y-%m-%d %H:%M:%S"`] [ERROR] 发送到 $mail_receivers 的邮件($1)失败!"
        else
                log "[`date "+%Y-%m-%d %H:%M:%S"`] [NOTE] 成功将邮件($1---$2) 发送至 $mail_receivers !"
        fi
        return 0
}

function url_encode()
{
        local encode=`echo "$1" | hexdump -C | awk '{for(i=2;i<=17;i++){if(i!=NF) printf "%%"$i}}' | awk -F '%0d' '{print $1}' |awk -F '%0a' '{print $1}'`
        echo "$encode"
}

# send_alarm_msg "18600428712,18500191878" "baidu_monitor" "0.0.0.0"  "$smsinfo"
#                                   模块名(随意) ip(随意，必须有) 短信内容(长度有限,必须有:) 
#                                       不能有特殊符号,支持_,,; 中间不能有空格
function send_alarm_msg()
{
        mobilelist="$1"
        name="$2"
        ip="$3"
        info="$4"
        alarm_urlprefix="http://www.findpath.net:82/smmp/servletsendmoremsg.do?name=autonavi261_sc&password=Aplan%24%25%23&type=101301"
        content_gbk="mse:$name on $ip: null $info-`date +'%Y-%m-%d %H:%M:%S'`"
        content=`echo "$content_gbk" | iconv -f utf8 -t gbk`
        content_encode=$(url_encode "$content")
        url="$alarm_urlprefix&&mobiles=$mobilelist&content=$content_encode"
        echo "`curl "$url" | grep RETURN | awk -F '<|>' '{print $3}'` $mobilelist $content_gbk"
        #echo "`curl "$url" | grep RETURN | awk -F '<|>' '{print $3}'` $mobilelist $content_gbk" >> alarm.log.$today_s
}


#------------------------------------------------------
# 2012-2-25 PM 22:33   wangqiwen@baidu.com
# input: 每次等5min
# type=1 检测多个目录，各目录tag文件命名规则一致，且都在上一级目录
#(1) wait_hadoop_file   hadoop  time  1 tag_file   hadoop_dir1   hadoop_dir2   hadoop_dir3  
# 公用tag文件名（非绝对路径，tag文件默认在目录的上一层）
# 示例：wait_hadoop_file $hadoop 10   1  done        /a/b/c        /a/m/c       /a/m/d
# 或：  wait_hadoop_file $hadoop 10   1  finish.txt  /a/b/c        /a/m/c       /a/m/d
#	目录/a/b/c,/a/m/c,/a/m/d
#	若tag文件分别为:/a/b/c.done和/a/m/c.done和/a/m/d.done，那么，tag_file="done"
#	否则，所有目录的tag文件名相同，tag_file可自定义为某文件名
#
# type=2 检测多个目录，各目录的tag文件路径无规则，需直接指定其完整路径
#(2) wait_hadoop_file hadoop    time   2  hadoop_dir1 tag_file1  hadoop_dir2 tag_file2  # 私用tag文件名，绝对路径
# 示例：wait_hadoop_file $hadoop 10   2  /a/b/c      /a/b/c.done /a/m/c     /a/m/c.txt   /a/m/d     /a/m_d.txt 
# 目录与tag文件要依次成对出现
#
# type=3 检测多个集群文件（非目录），无须tag文件
#(3) wait_hadoop_file    hadoop    time   3	hadoop_file1    hadoop_file2   hadoop_file3   # 判断多个hadoop文件的存在性
# 示例：wait_hadoop_file $hadoop    10    3     /a/b/file1.txt  /a/b/file2.txt  /a/m/file3.log 
#
# output: 通过变量FILE_READY记录，返回状态值0~3 
#   0 : 检查完毕，或成功删除临时目录
#   1 : 参数输入有误：个数、奇偶性不对。type=2时要保证tag文件与目录依次成对出现
#   2 : 超时，停止检查
#   3 : _temporary目录删除失败,但不影响hadoop任务，属于成功状态
#   成功状态值: 0 和 3
#------------------------------------------------------
#shopt -s -o nounset  # 变量声明才能使用
wait_hadoop_file(){
	local FILE_READY=1 # 检查结果
	local ARG_NUM=$# # 参数个数
	[ $ARG_NUM -lt 4 ] && {  echo -e "input error ! $ARG_NUM < 4 , please check !\t参数有误，小于4个，请确认！";return $FILE_READY;} 
	local HADOOP=$1 # Hadoop集群客户端地址
	local HADOOP_CHECK_PATH="/" # 待检查的集群目录或文件
	local HADOOP_TEMP_PATH="/" # _temporary目录
	local HADOOP_CHECK_TAG="/"  # 待检查的tag文件
	local HADOOP_WATI_TIME=$2 # 最长等待时间（单位：分钟）
	local CURRENT_ERRORTIME=1 # 等待时间
	local CURRENT_PATH=1  # 当前遍历目录数
	local PATH_INDEX=0  # 当前检测目录所在的参数位置
	local TAG_INDEX=0  # 当前检测tag文件所在的参数位置
	local TAG_NAME="/"
	local DIR_NUM=0  # 待检测目录数
	local TYPE=$3  # type
	# 根据类型分别处理
	# type=1,2时，输入参数至少5个；type=3时，输入参数至少4个
	case $TYPE in
	1) 
		[ $ARG_NUM -eq 4 ] && {  echo -e "input error ! $ARG_NUM < 5 , please check !\t参数有误，小于5个，请确认！";return $FILE_READY;}
		DIR_NUM=$(($ARG_NUM-4));;  # 待检测的目录数
	2)
		[ $ARG_NUM -eq 4 ] && {  echo -e "input error ! $ARG_NUM < 5 , please check !\t参数有误，小于5个，请确认！";return $FILE_READY;}
		[ $((($ARG_NUM-3)%2)) -ne 0 ] && { FILE_READY=1; echo -e "Input error ! Dirs miss to match tags in pairs ...";return $FILE_READY;} # 目录和tag文件不成对，退出case
		DIR_NUM=$((($ARG_NUM-3)/2));;  # 待检测的目录数
	3)	
		DIR_NUM=$(($ARG_NUM-3));; # 待检测文件数
	*)
		echo "Input error ! Type value $TYPE illegal... type参数值错误，1-3，非$TYPE"
		return $FILE_READY;;
	esac

	while [ $CURRENT_PATH -le $DIR_NUM ]
	do
		# path/tag参数位置获取
		if [ $TYPE -eq 1 ];then
			PATH_INDEX=$((4+$CURRENT_PATH))
			TAG_INDEX=4
			eval "HADOOP_CHECK_PATH=\${$PATH_INDEX}"  # 待检查的集群目录
			eval "TAG_NAME=\${$TAG_INDEX}"
			if [ "$TAG_NAME" == "done" ];then #tag文件在上一级目录
				HADOOP_CHECK_TAG="${HADOOP_CHECK_PATH%/*}/${HADOOP_CHECK_PATH##*/}.$TAG_NAME" # tag文件名为：上一级目录名字.done
			else
				HADOOP_CHECK_TAG="${HADOOP_CHECK_PATH%/*}/$TAG_NAME" # 上一级目录自定义tag文件名
			fi
		elif [ $TYPE -eq 2 ];then
			PATH_INDEX=$((4+2*($CURRENT_PATH-1))) 
			TAG_INDEX=$(($PATH_INDEX+1))
			eval "HADOOP_CHECK_PATH=\${$PATH_INDEX}"  # 待检查的集群目录
			eval "HADOOP_CHECK_TAG=\${$TAG_INDEX}" # tag文件的绝对路径
		else
			PATH_INDEX=$((3+$CURRENT_PATH))
			eval "HADOOP_CHECK_PATH=\${$PATH_INDEX}"  # 待检查的集群文件
		fi
		while [ $CURRENT_ERRORTIME -le $HADOOP_WATI_TIME ]
		do
			$HADOOP fs -test -e $HADOOP_CHECK_PATH  # 检测path目录是否存在
			if [ $? -eq 0 ];then # 目录存在
				break
			else  # 目录不存在，等待生成
				CURRENT_ERRORTIME=$(($CURRENT_ERRORTIME+1))
				date "+%Y-%m-%d %H:%M:%S"
				sleep 5m
			fi
		done
		[ $CURRENT_ERRORTIME -gt $HADOOP_WATI_TIME ] && { FILE_READY=2; echo -e "Time out when checking dirs[$HADOOP_CHECK_PATH] ...\t等待超时，目录未检查完毕！" ;break;}
		if [ $TYPE -eq  3 ];then
			CURRENT_PATH=$(($CURRENT_PATH+1)) # 检查下一个目录
		else
			HADOOP_TEMP_PATH="${HADOOP_CHECK_PATH}/_temporary" # 临时目录
			# 检测tag文件，并删除临时目录
			while [ $CURRENT_ERRORTIME -le $HADOOP_WATI_TIME ]
			do
				$HADOOP fs -test -e $HADOOP_CHECK_TAG # 检测tag文件是否存在
				if [ $? -eq 0 ];then  # tag文件存在  [2012-12-4]停止临时文件删除
					#$HADOOP fs -test -e $HADOOP_TEMP_PATH  # 检查临时目录是否存在
					#if [ $? -eq 0 ];then  # 临时目录存在
					#	$HADOOP fs -rmr $HADOOP_TEMP_PATH  # 删除临时目录
					#	[ $? -ne 0 ] && { FILE_READY=3; echo -e "Failed to delete temp dir[$HADOOP_TEMP_PATH]...\t临时目录删除失败";} #break 2; } # 删除失败，退出2重循环 [2012-2-23]不退出，继续检查
					#fi
					CURRENT_PATH=$(($CURRENT_PATH+1)) # 检查下一个目录
					break 
				else  # tag文件不存在，错误次数自增，循环等待
					CURRENT_ERRORTIME=$(($CURRENT_ERRORTIME+1))
					date "+%Y-%m-%d %H:%M:%S"
					sleep 5m
				fi
			done
		fi
	done
	[ $CURRENT_PATH -gt $DIR_NUM ] && { [ $FILE_READY -ne 3 ] && FILE_READY=0;  echo "All dirs ready ! 目录检查完毕！";} # 所有目录都准备好,新增成功状态3,[2012-2-23]
	return $FILE_READY
}

