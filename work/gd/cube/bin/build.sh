#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#            File:  build.sh
#           Usage:  sh build.sh
#     Description:  搭建执行环境：新增目录、删除文件、修改权限
#    LastModified:  
#         Created:  2014-3-19 16:17 PM CST
# 
#          AUTHOR:  warren@autonavi.com)
#         COMPANY:  autonavi Inc
#         VERSION:  1.0
#            NOTE:  
#           input:  
#          output:  
#===============================================================================


readonly LogDayCnt=90	#日志保存的天数
readonly BakDayCnt=20	#代码备份的天数
readonly DataDayCnt=7	#数据备份的天数

ShellDir=`pwd`
cd $ShellDir

#增加shell文件的可执行权限
#for file in `ls ${ShellDir}/*.sh ${ShellDir}/conf/*.sh`
#do
#        [ ! -x $file ] && chmod a+x $file
#done

readonly RootDir=${ShellDir%/*}
readonly now=`date "+%Y%m%d"`
readonly BakDir=${RootDir}/bak/$now
readonly LogDir=${RootDir}/log/$now
readonly DataDir=${RootDir}/data/$now

#创建目录
file_dir=( $BakDir $LogDir $DataDir )
index=$((${#file_dir[*]}-1))
for i in `seq 0 $index`
do
        [ ! -d ${file_dir[$i]} ] && mkdir -p ${file_dir[$i]}
done

#删除过期的备份
#for i in `seq 0 $index`
#do
#	find ${BakDir%/*} -maxdepth 1 -mindepth 1 -mtime +${BakDayCnt} -exec rm \-rf {} \; -print
#done

#备份,时间戳最新
cp -ru ./* ${BakDir}/

find ${BakDir%/*} -maxdepth 1 -mindepth 1 -mtime +${BakDayCnt} -exec rm \-rf {} \; -print
find ${LogDir%/*} -maxdepth 1 -mindepth 1 -mtime +$LogDayCnt -exec rm \-rf {} \; -print
find ${DataDir%/*} -maxdepth 1 -mindepth 1 -mtime +$DataDayCnt -exec rm \-rf {} \; -print

