#/usr/bin/env python
# coding:utf8
import sys
import os
import re
import sys
reload(sys)
sys.setdefaultencoding('utf-8')


if __name__ == '__main__':
    #reformat.py doneFile sendFile newFile
    if len(sys.argv) < 4:
        print sys.stderr,'参数不足! reformat.py doneFile sendFile newFile'
        sys.exit(1)
    doneFile = sys.argv[1]
    sendFile = sys.argv[2]
    newFile = sys.argv[3]
    print >> sys.stderr, 'doneFile=%s sendFile=%s newFile=%s'%(doneFile,sendFile,newFile)
    #加载已发文件doneUser.txt
    doneSet = set([])
    for line in file(doneFile):
        arr = [i.strip() for i in line.strip().split('\t')]
        if len(arr) < 1:
            print >> sys.stderr,'格式有误![%s]'%(line.strip())
            continue
        doneSet.add(arr[0])
    doneCount = len(doneSet)
    print >> sys.stderr,'%s文件已有%s行'%(doneFile,doneCount)
    if doneCount == 0:
        print >> sys.stderr,'%s为空,无需去重!'%(doneFile)
        sys.exit(1)
    #生成新output
    f = open(newFile,'w')
    curCount = 0
    allCount = 0
    for line in file(sendFile):
        allCount += 1
        arr = [i.strip() for i in line.strip().split('\t')]
        if len(arr) < 1:
            print >> sys.stderr,'格式有误![%s]'%(line.strip())
            continue
        #if arr[1] in doneSet:
        if arr[0] in doneSet:
            curCount += 1
            print >> sys.stderr,'[%s]已发送，跳过...'%(arr[0])
            continue
        print >> f,line.strip()
    print '已遍历文件(%s)%s人,其中跳过%s人(%.3f%%),待过滤文件(%s)共%s人,更新发送集合(%s)共%s人'%(sendFile,allCount,curCount,curCount*100/allCount,doneFile,doneCount,newFile,allCount-curCount)
# */* vim: set expandtab ts=4 sw=4 sts=4 tw=400: */
