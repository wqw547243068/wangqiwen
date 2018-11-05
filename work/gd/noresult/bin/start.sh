#!/bin/bash
# -*- coding: utf-8 -*-
#
#===============================================================================
#            File:  start.sh [monitor]
#           Usage:  
#                运行指定日期：    sh start.sh  20120104
#		 正常运行(昨天):   sh start.sh
#		 查看运行日志：    tail -f ../log/20120104/run_log_20120103.txt
#     Description:  检索query无结果监控模块
#    LastModified:  
#         Created:  2013-12-17 12:17 PM CST
#          AUTHOR:  warren@autonavi.com
#         COMPANY:  baidu Inc
#         VERSION:  1.0
#            NOTE: 
#	    input:  
#	   output:
#===============================================================================
# 2014-3-14,warren
#set -x 

#关联时间
if [ $# -eq 1 ];then
	date_check=`echo "$1" | sed -n '/^[0-9]\{8\}$/p'`
	if [ -z $date_check ];then
		# 如果字符串为空,表明输入参数不当
		echo "[`date "+%Y-%m-%d %H:%M:%S"`] [ERROR] date of start.sh input error ... 启动脚本的日期参数错误!"
		exit -1
	else
		readonly date=$1   # test date
	fi
else
	readonly date=`date -d "1 days ago" +%Y%m%d`
fi
newdate=${date:0:4}-${date:4:2}-${date:6:2}

#搭建执行环境
source ./build.sh
LogFile=${LogDir}/"log_${date}.txt" #日志文件,依赖于build.sh
#导入公共函数
source ./common.sh #增加./,防止与环境变量重名
#日志初始化
init_log  #common.sh中定义

#重定向标准输入和输出到指定文件
exec 3<>$LogFile
exec 1>&3 2>&1

log "$alarm_module_info" #模块信息
log "[NOTE] load conf file 加载配置文件..."


# 模块信息
alarm_module_info="[no-result-monitor:LSE2]"
#==========online=============
#:<<note
alarm_mail_prefix="warren,feng.liao,Ann,xin.hu,xinxin.liu,leywar.liang,damon,michael,jeff,pengjie.wu,zhanglei03,arc,jay,aili.liang,xiaoyu.zhang,xiaoying.sun,jing.yang,sicong.wang,yunfei.wang,v-cuitingting,reid,huo.zhu,kerui.ji,jianfu.han"
alarm_mail_receiver="${alarm_mail_prefix//,/@autonavi.com,}@autonavi.com"
alarm_mail_receiver_in="warren,jeff"
alarm_msg_receiver="15210923792,18600457353,18500191878,18611100524,18600428712,13466778772"
#note
#==========test=============
:<<note
alarm_msg_receiver="15210923792"
alarm_mail_receiver="warren@autonavi.com"
alarm_mail_receiver_in="warren@autonavi.com"
note
#=======================
alarm_mail_title="$alarm_module_info[$date]"

#null_file="/opt/data1/log/logAnalyze_result/amap_lse2/day/${date}-${date}_tquerypoinoresultkeywordwithcitycode.txt"
#equalFilterFile="/home/atd/work/logAnalyze_cfg_file/equalFilterWord.txt"
#containFilterFile="/home/atd/work/logAnalyze_cfg_file/containFilterWord.txt"
equalFilterFile="conf/equalFilterWord.txt"
containFilterFile="conf/containFilterWord.txt"
data_file="$DataDir/no_result_${date}.txt"
data_file_filter="$DataDir/no_result_filter_${date}.txt"
mail_file="$DataDir/mail_${date}.txt"
min='1' # 报警阈值(检索无结果比例)

function checkCode( )
{ # 检查命令运行状态 checkCode $1(提示消息) $2(失败时是否退出,yes,no)
    if [ $? -eq 0 ];then
        echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] $1 success..."
    else
        if [ $2 == 'yes' ];then
            echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] $1 fail,exit..."
            echo "[$alarm_module_info] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] $1 fail,exit" | mail -s "$1 fail,exit" $alarm_mail_receiver_in
            exit -1
        else
            echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] $1 fail,continue to run..."
            echo "[$alarm_module_info] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] $1 fail,continue to run" | mail -s "$1 fail,continue to run" $alarm_mail_receiver_in
        fi
    fi
}

#date1=${date//-}
hql_get_file="tool/get_no_result.sql"
# 执行Hive任务，获取无结果数据
#hive="/data/soft/hadoop2/hive/bin/hive"
hive="/home/devuse/bin/hadoop/bin/hive"
#hive="/opt/bin/CDH-5.0.0-1.cdh5.0.0.p0.47/bin/hive"
if [ -f $data_file ];then
    echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] hive数据($data_file)已存在，跳过抽取步骤."
else
	echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] 从hive中抽取检索无结果数据"
	$hive -hivevar date=$date -f $hql_get_file > $data_file
	if [ $? -ne 0 ];then
	    echo "[$0] [ERROR] [`date "+%Y-%m-%d %H:%M:%S"`] 点击无结果数据抽取失败 !"
        exit -1
	else
	    echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] 点击无结果数据抽取完毕 !"
	fi
fi
# city字典,百度api,过滤词 
echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] 数据过滤"
if [ -f $data_file_filter ];then
    echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] 过滤后的文件($data_file_filter)已存在，跳过"
else
    cat $data_file | python filter.py > $data_file_filter
    checkCode "data filter" "yes"
fi
# 数据写入hive
echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] 无结果数据写入hive"
hql_create_file='tool/create_no_result_data.sql'
$hive -hivevar date=$date -hivevar file=$data_file_filter -f $hql_create_file
checkCode "writing data into hive table" "yes"

# 抽取全局信息
hql_stat_file='tool/get_stat_info.sql'
data_stat_file="$DataDir/hql_stat_${date}.txt"
if [ -f $data_stat_file ];then
    echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] 全局信息文件($data_stat_file)已存在，跳过."
else
    $hive -hivevar date=$date -f $hql_stat_file > $data_stat_file
    checkCode "stat global info" "yes"
fi
# 读取文件内容到shell数组
# 示例:RQBXY 1815907 303359 IDQ 2128498 270790 TQUERY 3290366 1193551
stat_array=( `cat $data_stat_file` )
echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] 全局信息:[${stat_array[*]}]"

global_tquery_freq_num=`awk '{if ($1=="TQUERY") print $2}' $data_stat_file`
global_tquery_query_num=`awk '{if ($1=="TQUERY") print $3}' $data_stat_file`
global_rqbxy_freq_num=`awk '{if ($1=="RQBXY") print $2}' $data_stat_file`
global_rqbxy_query_num=`awk '{if ($1=="RQBXY") print $3}' $data_stat_file`

# 统计点击无结果指标
stat_awk_file='tool/stat.awk'
number_string=`cat $data_file_filter | awk -F'\t' -f $stat_awk_file`
# out: query统计信息(一框搜,周边搜,总和) 检索频次信息           geo信息(全部都是一框搜,频次) 
# 示例: 201049,27643,228692,              325694,50174,375868,  56009
array=( ${number_string//,/ } ) # shell数组: line user count
echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] 无结果统计信息:[${array[*]}]"
tquery_query_num=${array[0]}
rqbxy_query_num=${array[1]}
all_query_num=${array[2]}
tquery_freq_num=${array[3]}
rqbxy_freq_num=${array[4]}
all_freq_num=${array[5]}
geo_freq_num=${array[6]}
echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] number_string=$number_string"
echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] tquery_query_num=$tquery_query_num rqbxy_query_num=$rqbxy_query_num all_query_num=$all_query_num tquery_freq_num=$tquery_freq_num rqbxy_freq_num=$rqbxy_freq_num all_freq_num=$all_freq_num geo_freq_num=$geo_freq_num"

# 计算检索无结果比例
per_query_tquery=`awk -v a=$tquery_query_num -v b=$global_tquery_query_num 'BEGIN{print a*100./b}'`
per_query_rqbxy=`awk -v a=$rqbxy_query_num -v b=$global_rqbxy_query_num 'BEGIN{print a*100./b}'`
per_freq_tquery=`awk -v a=$tquery_freq_num -v b=$global_tquery_freq_num 'BEGIN{print a*100./b}'`
per_freq_rqbxy=`awk -v a=$rqbxy_freq_num -v b=$global_rqbxy_freq_num 'BEGIN{print a*100./b}'`
per_freq_geo=`awk -v a=$geo_freq_num -v b=$global_tquery_freq_num 'BEGIN{print a*100./b}'`
echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] per_query_tquery=$per_query_tquery per_query_rqbxy=$per_query_rqbxy per_freq_tquery=$per_freq_tquery per_freq_rqbxy=$per_freq_rqbxy"


# 邮件正文
mail_content_file="$DataDir/content_${date}.txt"
echo -e "all_freq_num\t$all_freq_num\t-\t-\nall_query\t$all_query_num\t-\t-" > $mail_content_file
echo -e "global_tquery_query_num\t$global_tquery_query_num\t-\t-\nglobal_tquery_freq_num\t$global_tquery_freq_num\t-\t-" >> $mail_content_file
echo -e "global_rqbxy_query_num\t$global_rqbxy_query_num\t-\t-\nglobal_rqbxy_freq_num\t$global_rqbxy_freq_num\t-\t-" >> $mail_content_file
echo -e "tquery_query_info\t$tquery_query_num\t$per_query_tquery%\t(tquery_query_num*100/global_tquery_query_num)" >> $mail_content_file
echo -e "tquery_freq_info\t$tquery_freq_num\t$per_freq_tquery%\t(tquery_freq_num*100/global_tquery_freq_num)" >> $mail_content_file
echo -e "rqbxy_query_info\t$rqbxy_query_num\t$per_query_rqbxy%\t(rqbxy_query_num*100/global_rqbxy_query_num)" >> $mail_content_file
echo -e "rqbxy_freq_info\t$rqbxy_freq_num\t$per_freq_rqbxy%\t(rqbxy_freq_num*100/global_rqbxy_freq_num)" >> $mail_content_file
echo -e "geo_freq_info\t$geo_freq_num\t$per_freq_geo%\t(geo_freq_num*100/global_tquery_freq_num)" >> $mail_content_file

# 统计信息写入hive
echo "[$0] [INFO] [`date "+%Y-%m-%d %H:%M:%S"`] 统计数据写入hive"
hql_create_file='tool/create_no_result_stat.sql'
$hive -hivevar date=$date -hivevar file=$mail_content_file -f $hql_create_file
checkCode "writing stat info into hive table" "yes"
alarm_msg_title="无结果:频次=$per_freq_tquery% 检索词=$per_query_tquery%"
#alarm_msg_title="$alarm_mail_title无结果比例:频次=$per_freq_tquery" # 2014-4-9 短信报警失灵，疑似信息过长，修复之
alarm_mail_title="$alarm_mail_title TQUERY freq=$per_freq_tquery% query=$per_query_tquery%"

#alarm_mail_title="$alarm_mail_title,query_number:$total_number,user:$total_freq,frequence:$total_freq,percentage)" # 2014-3-14,warren
log "检索无结果比例(TQUERY:freq,$per_freq_tquery%;query,$per_query_tquery%)"
echo -e "-----------检索无结果统计值(新)--------------------"  > $mail_file
cat $mail_content_file >> $mail_file
echo -e "-----------检索无结果query列表-----------------\nquery query_type citycode cityname geo user_freq count_freq baidu\n------------------------------------" >> $mail_file
cat $data_file_filter | awk -F'\t' '{if($6>=2&&$2=="TQUERY")print}' >> $mail_file
#cat $data_file_filter | iconv -f gbk -t utf8 >> $mail_file
# 发送报警邮件
cat  $mail_content_file | mail -s "$alarm_mail_title" -a $mail_file $alarm_mail_receiver  # -s 后面的参数要加""，避免长字符串导致邮件发送失败
checkCode "send mail" "yes"
# 发送报警短信
send_alarm_msg "$alarm_msg_receiver" "sp-monitor" "10.13.2.30"  "$alarm_msg_title:"
checkCode "send msg" "yes"
log "================end===================="

#关闭重定向
exec 3<&-
