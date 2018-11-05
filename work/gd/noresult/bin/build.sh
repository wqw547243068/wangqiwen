#!/bin/bash
# -*- coding: utf-8 -*-

#===============================================================================
#            File:  build.sh
#           Usage:  sh build.sh
#     Description:  搭建执行环境：新增目录、删除文件、修改权限
#    LastModified:  
#         Created:  6/12/2012 13:33 PM CST
# 
#          AUTHOR:  wangqiwen(wangqiwen@baidu.com)
#         COMPANY:  baidu Inc
#         VERSION:  1.0
#            NOTE:  
#           input:  
#          output:  
#===============================================================================

# 2014-9-12 磁盘空间检测
sh check_disk.sh

readonly LogDayCnt=14	#日志保存的天数
readonly BakDayCnt=7	#数据备份保存的天数
readonly DataDayCnt=14	#接口数据保存的天数
readonly pythonBin=`which python` #python解析器的绝对路径，要求python的版本2.5+
readonly shellBin=`which bash`

ShellDir=`pwd`
cd $ShellDir

#增加shell文件的可执行权限
#for file in `ls ${ShellDir}/*.sh ${ShellDir}/conf/*.sh`
#do
#        [ ! -x $file ] && chmod a+x $file
#done

readonly RootDir=${ShellDir%/*}
readonly LogID=`date "+%Y.%m.%d"`
readonly BakDir=${RootDir}/bak/$LogID
readonly LogDir=${RootDir}/log/$LogID
readonly DataDir=${RootDir}/data/$LogID

#创建目录
file_dir=( $BakDir $LogDir $DataDir )
index=$((${#file_dir[*]}-1))
for i in `seq 0 $index`
do
        [ ! -d ${file_dir[$i]} ] && mkdir -p ${file_dir[$i]}
done

#删除过期的备份
find ${BakDir%/*} -maxdepth 1 -mindepth 1 -mtime +${BakDayCnt} -exec rm \-rf {} \; -print
find ${LogDir%/*} -maxdepth 1 -mindepth 1 -mtime +$LogDayCnt -exec rm \-rf {} \; -print
find ${DataDir%/*} -maxdepth 1 -mindepth 1 -mtime +$DataDayCnt -exec rm \-rf {} \; -print

#备份
cp -r ./* ${BakDir}/

