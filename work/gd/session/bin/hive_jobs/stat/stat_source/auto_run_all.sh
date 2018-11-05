# sh auto_run_all.sh 20141012 [3]
[ $# -ge 1 ] && date=$1 || date=`date -d "1 days ago" +%Y%m%d`
#readonly rp_hadoop="/home/work/bin/hadoop-client-rp-product/hadoop/bin/hadoop"
readonly hive='/data/soft/hadoop2/hive/bin/hive'
[ $# -ge 2 ]&&n=$2||n=10
i=0;
while [ $i -le $n ]
do
	d=`date -d "${i} days ago $date" +%Y%m%d`
	echo "[`date "+%Y-%m-%d %H:%M:%S"`] day: $i ($d)"
	d1="${d:0:4}/${d:4:2}/${d:6:2}"
	d2=${d1//\//-}
	$hive -f all.sql -hivevar date=$d -hivevar date1=$d1 -hivevar date2=$d2
	[ $? -ne 0 ] && { echo "[`date "+%Y-%m-%d %H:%M:%S"`] day $i ($d) fail ...";exit -1; } || { echo "[`date "+%Y-%m-%d %H:%M:%S"`] day $i ($d) succeed ...";  }
    ((i++))
done
