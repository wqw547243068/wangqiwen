#!/bin/awk -f
{
    # 执行方式: cat no_result_filter.txt | awk -F'\t' -f test.awk 
    # [ query query_type citycode cityname geo user_freq count_freq baidu]
    query[$2]++; # query数(不同城市同一query算做不同query)
    query["all"]++; # query总数
    freq[$2]+=$7; # 检索频次(不对用户去重)
    freq["all"]+=$7; 
    if($5!="-")
    {
        geo+=$7; # 记录geo频次
    }
}END{
    # out: 201049,27643,228692,              325694,50174,375868,  56009
    # out: query统计信息(一框搜,周边搜,总和) 检索频次信息           geo信息(全部都是一框搜,频次) 
    print query["TQUERY"]","query["RQBXY"]","query["all"]","freq["TQUERY"]","freq["RQBXY"]","freq["all"]","geo
}
