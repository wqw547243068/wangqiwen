#awk -F'\t' -v max=$diff_count -v ready=$doneFile180 
'BEGIN{
  while(getline<ready>0)
    d[$1]=1
}
{
  if($1 in d)next;
  if(count<=max)print;
  count+=1
}'
