#!/usr/bin/python
# encoding:utf8

import sys
import re
import subprocess
import json
import datetime
import random


if __name__ == '__main__':
    # 调用外部curl命令抓取页面数据
    # 机器之心-资讯频道-文章主页: http://jiqizhixin.com/article/1734
    pattern_article = re.compile(r'''<div\s+class="sellDetailHeader">.*?
                                        <div\s+class="title">.*?
                                            <h1\s+class="main"\s+title=.*?>(.*?)</h1>.*? # title 主标题
                                            <div\s+class="sub"\s+title=.*?>(.*?)</div>.*? # sub title 子标题
                                        </div>.*?
                                            <div\s+class="btnContainer\s+">.*?
                                                <div>.*?
                                                    <div\s+class="action">.*?
                                                        <span\s+id="favCount"\s+class="count">(.*?)</span>.*? # 关注人数
                                                    </div>.*?
                                                    <div\s+class="action\s+">.*?
                                                        <span\s+id="cartCount"\s+class="count">(.*?)</span>.*? # 看过人数
                                                    </div>.*?
                                                </div>.*?
                                            </div>.*?
                                        </div>.*?
                                    </div>.*?
                                    <div\s+class="intro\s+clear".*?
                                    <div\s+class="overview">.*?<div\s+class="content">.*?<div\s+class="price\s+"><span\s+class="total">(.*?)</span>.*? # 总价
                                        <div\s+class="text"><div\s+class="unitPrice"><span\s+class="unitPriceValue">(.*?)<i>元/平米</i></span></div> # 均价,元/平方米
                                        <div\s+class="tax"><span>首付(.*?)</span>税费<span><span\s+id="PanelTax">(.*?)</span>万\(仅供参考\)\s+</span>.*? #首付,税费
                                        <div\s+class="houseInfo">
                                            <div\s+class="room">
                                                <div\s+class="mainInfo">(.*?)</div> #户型
                                                <div\s+class="subInfo">(.*?)</div> #楼层
                                            </div>
                                            <div\s+class="type">
                                                <div\s+class="mainInfo"\s+title=.*?>(.*?)</div> #朝向
                                                <div\s+class="subInfo">(.*?)</div> #装修
                                            </div>
                                            <div\s+class="area">
                                                <div\s+class="mainInfo">(.*?)</div> #面积
                                                <div\s+class="subInfo">(.*?)</div> #建设时间
                                            </div>
                                        </div>
                                        <div\s+class="aroundInfo">
                                            <div\s+class="communityName"><i></i><span\s+class="label">小区名称</span><a\s+href="(.*?)".*?class="info">(.*?)</a><a\s+href=".*?"\s+class="map">地图</a></div> # 小区链接,小区名
                                            <div\s+class="areaName"><i></i><span\s+class="label">所在区域</span><span\s+class="info"><a\s+href="(.*?)".*?>(.*?)</a>.*?<a\s+href="(.*?)".*?>(.*?)</a>(.*?)</span>.*?</div> # 小区所在区域:昌平,北七家,五环到六环
                                            <div\s+class="visitTime"><i></i><span\s+class="label">看房时间</span><span\s+class="info">(.*?)</span></div> # 看房时间
                                            <div\s+class="houseRecord"><span\s+class="label">链家编号</span><span\s+class="info">(.*?)<span\s+class="jubao">.*?</span></span></div> # 看房时间
                                        .*?</div>.*?
                                      ''',re.X|re.S)
    pattern_tag = re.compile(r'''<span\s+class="al-article-tag">(.*?)</span>''',re.X|re.S)
    pattern_para = re.compile(r'''<p\s+.*?>(.*?)</p>''',re.X|re.S)
    # 剔除特殊符号
    #p_single = re.compile(r'<img.*?/>') # 剔除图片信息
    #p_pair = re.compile(r'<(.*?)\s?.*?>(.*?)</\1>') # 剔除外链信息
    p_html = re.compile(r'(<[^>]+>)|(&nbsp;)',re.S)
        
    # 抓取资讯首页
    # http://jiqizhixin.com/edge/p/1
    #["燕城苑南北两居，业主诚心出售，看房方便。", "南北通透两居，视野好，集中供暖！", "35", "2", "345", "40464", "121万 ", "13.8", "2室2厅", "高楼层/共6层", "南 北", "平层/简装", "85.26平米", "1995年建/板楼", "/xiaoqu/1111027381547/", "燕城苑北区", "/ershoufang/changping/", "昌平", "/ershoufang/beiqijia/", "北七家", "&nbsp;五至六环", "有租户需要预约", "101100960378"]
    output_format = ['房源','备注','关注人数','看过人数','总价','均价','首付','税费','户型','楼层','朝向','装修','面积','年代','小区链接','小区名称','区链接','区名','镇链接','镇名','街道','看房','编号']
    print('\t'.join(output_format))
    page_list = ['101100791393','101100960378']
    #for page in page_list:
    for line in file('house_id.txt'):
        page = line.strip().strip('.html')
        #curl_path = 'curl http://bj.lianjia.com/ershoufang/101100960378.html'
        curl_path = 'curl http://bj.lianjia.com/ershoufang/%s.html'%(page)
        content = subprocess.check_output(curl_path,shell=True); #如果命令执行的返回值不为0，则会抛出CalledProcessError的错误
        #print(content)
        result =  re.findall(pattern_article,content)
        output_dict = dict(zip(output_format,result[0]))
        #output =  re.findall(pattern_article,content.decode('utf8'))
        print('\t'.join(result[0]))
        #print(json.dumps(result[0],ensure_ascii=False))
        #print(json.dumps(output_dict,ensure_ascii=False))


