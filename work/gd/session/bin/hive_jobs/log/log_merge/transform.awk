#!/bin/awk -f
# 2014-5-17
BEGIN{
    p1="select uid,sessionid,stepid,time,position,source,action,request,response,cellphone,other from ";
    p2=" where dt="date
}{
    for(i=1;i<=NF;i++)
    {
        if($i!~/db\/.*?\//)next;
        split($i,a,"/");
        t=a[6];
        if(t=="log_client")
        {# client数据源限定日期
            p3=p2" and other[\"date\"]=\""date"\"" # 2014-6-21 开启
            #continue # 先忽略client数据源 2014-5-18
        }else{ # 其他数据源保持原值
            p3 = p2
        }
        if(out=="")
        { # 起始行
            out=p1" "t" "p3;
        }else{
            out=out" union all "p1" "t" "p3
        }
    }
}END{print out}
