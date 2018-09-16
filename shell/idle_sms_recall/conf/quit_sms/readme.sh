#短信退订用户处理
tmp="all.txt"
out="../quit_list.txt"
>$tmp
for file in `ls quit_*.txt`;
do
  num=`wc -l $file | awk '{print $1}'`
  echo "开始读入文件${file},${num}行"
  awk '{if($1~/^[0-9]+$/)print $1"\t"FILENAME}' $file >> $tmp
done
num=`wc -l $tmp | awk '{print $1}'`
echo "各大渠道商共${num}个用户(未去重)"
less $tmp | awk '{if($1~/^[0-9]+$/)print}'|sort|uniq -c|awk '{print $2"\t"$1}'|sort -nrk2|awk '{if(NF<2)next;print $1"\t"$2}'  > $out
num=`wc -l $out | awk '{print $1}'`
echo "融合完毕,共得到${num}个退订用户"

:<<note
#----结果示例-----
开始读入文件quit_anxinjie.txt,454204行
开始读入文件quit_guodu.txt,439767行
开始读入文件quit_welink.txt,3639行
各大渠道商共897599个用户(未去重)
融合完毕,共得到850533个退订用户
note

