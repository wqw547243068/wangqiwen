#!/bin/bash
# -*- coding: utf-8 -*-

if [ $# -ne 4 ];then
    echo "[$0]参数($*)不足(send_alarm_msg "18600428712,18500191878" "baidu_monitor" "0.0.0.0"  "smsinfo"),退出..."
    exit -1
fi

function url_encode()
{
        local encode=`echo "$1" | hexdump -C | awk '{for(i=2;i<=17;i++){if(i!=NF) printf "%%"$i}}' | awk -F '%0d' '{print $1}' |awk -F '%0a' '{print $1}'`
        echo "$encode"
}

# send_alarm_msg "18600428712,18500191878" "baidu_monitor" "0.0.0.0"  "$smsinfo"
#                                           模块名(随意) ip(随意，必须有) 短信内容(长度有限,必须有:) 
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

send_alarm_msg $*
