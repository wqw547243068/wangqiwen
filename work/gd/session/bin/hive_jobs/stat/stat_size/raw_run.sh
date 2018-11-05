hadoop='/home/devuse/bin/hadoop/bin/hadoop'
date='20140501'
#i=4
#for((i=0;i<$num;i++))
# sp: /user/ops/flume/sp/sp_logger/2014/06/11    gz
# client: /user/amap/data/mysql/bi/ods/page/ods_page_pagelog/2014/06/11
# aos: /user/ops/flume/aos/2014/06/11  gz 
# sug: /user/ops/flume/sug/2014/06/11  gz 
# old_sug: /user/ops/flume/sug/old/20140611/2014/06/11
# old_sp: /user/ops/flume/sp/sp_logger/old/2014-06-29
#echo -e "date\tsp_time\tsp_size\tsug_time\tsug_size\told_sug_time\told_sug_size\taos_time\taos_size\tclient_time\tclient_size"
echo -e "date\tsp_size\tsp_old_size\tsug_size\told_sug_size\taos_size\taos_dxp_size\tclient_size"
for i in `seq 0 70`
do
	cur_date1=`date -d "$i day $date" "+%Y/%m/%d"`
	cur_date2=`date -d "$i day $date" "+%Y-%m-%d"`
	cur_date=`date -d "$i day $date" "+%Y%m%d"`
	#cur_date=`date -d "-$i day $date" "+%Y%m%d"`
	size=''
	#for i in `echo '/user/ops/flume/sp/sp_logger /user/ops/flume/sp/sp_logger/old /user/ops/flume/sug /user/ops/flume/sug/old /user/ops/flume/aos /user/ops/flume/aos_new/aos_dxp /user/amap/data/mysql/bi/ods/page/ods_page_pagelog'`
	for i in `echo '/user/ops/flume/aos /user/ops/flume/aos_new/aos_dxp'`
	do
		#path="/user/hive/warehouse/log_session.db/$i/dt=$cur_date"
		if [ $i == '/user/ops/flume/sug/old' ];then
			path="$i/$cur_date/$cur_date1"
		elif [ $i == '/user/ops/flume/sp/sp_logger/old' ];then
			path="$i/$cur_date2"
		elif [ $i == '/user/ops/flume/aos_new/aos_dxp' ];then
			path="$i/$cur_date1/*/*"
		else
			path="$i/$cur_date1"
		fi
		out=`$hadoop fs -ls $path | awk '{a+=$5}END{print a/(1024.**3)}'`
		#out=`$hadoop fs -ls $path | awk '{a+=$5}END{print $6"-"$7"\t"a/(1024.**3)}'`
		size="$size\t$out"
	done
	#echo -e "date=$cur_date\tsize=$size"
	echo -e "$cur_date\t$size"
done

# cat data.txt | awk '{split($2,a,"=");printf a[2]","}END{print ""}'
