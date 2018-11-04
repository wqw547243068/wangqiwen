# coding: utf8
"""
    微信好友分析
"""
import os
import json
import pandas as pd
import itchat
import jieba
import re
import pyecharts as pe

def get_icon(img_dir):
    """
        获取微信好友头像
    """
    #itchat.search_friends()
    print('获取微信好友头像')
    if not os.path.isdir(img_dir):
        os.mkdir(img_dir)
    for friend in itchat.get_friends(update=True)[0:]:
        #可以用此句print查看好友的微信名、备注名
        img_name = friend['NickName']+"_"+friend['RemarkName']
        img_content = itchat.get_head_img(userName=friend["UserName"])
        img_file = '%s/%s.jpg'%(img_dir, img_name)
        print(img_file)
        try:
            with open(img_file,'wb') as f:
                f.write(img_content)
        except Exception as e:
            print(repr(e))



def stitch_icon(img_dir, out_dir):
    """
        拼接好友微信头像
    """
    import math
    import random
    #pip install pillow
    from PIL import Image
    x = 0
    y = 0
    imgs = os.listdir(img_dir)
    random.shuffle(imgs)
    # 创建640*640的图片用于填充各小图片
    newImg = Image.new('RGBA', (640, 640))
    # 以640*640来拼接图片，math.sqrt()开平方根计算每张小图片的宽高，
    width = int(math.sqrt(640 * 640 / len(imgs)))
    # 每行图片数
    numLine = int(640 / width)

    for i in imgs:
        img_file = './%s/%s'%(img_dir, i)
        try:
            img = Image.open(img_file)
        except Exception:
            print('图片文件读取异常：%s'%(img_file))
            continue
        # 缩小图片
        img = img.resize((width, width), Image.ANTIALIAS)
        # 拼接图片，一行排满，换行拼接
        newImg.paste(img, (x * width, y * width))
        x += 1
        if x >= numLine:
            x = 0
            y += 1
    out_file = '%s/all_%s.png'%(out_dir, user)
    newImg.save(out_file)
    return out_file

if __name__ == '__main__':
    # 先登录
    #关键字实参hotReload取True使得短时间内无需再次扫码登录
    #itchat.auto_login(hotReload=True)
    itchat.login()
    # 获取好友列表
    friends = itchat.get_friends(update=True)[0:]
    #print(friends)
    import numpy as np
    np.save('wechat_data.npy', friends)

    #friends[0].keys()
    json.dumps(friends[0], ensure_ascii=False)
    # 获取账户主人名字
    user = friends[0]['NickName']
    # 遍历这个列表，列表里第一位是自己，所以从"自己"之后开始计算
    input_format = ['UserName', 'City', 'DisplayName', 'UniFriend', 'OwnerUin', 'MemberList', 'PYQuanPin', 'RemarkPYInitial', 'Uin', 'AppAccountFlag', 'VerifyFlag', 'Province', 'KeyWord', 'RemarkName', 'PYInitial', 'ChatRoomId', u'IsOwner', 'HideInputBarFlag', u'HeadImgFlag', 'EncryChatRoomId', 'AttrStatus', 'SnsFlag', 'MemberCount', u'WebWxPluginSwitch', 'Alias', 'Signature', 'ContactFlag', 'NickName', 'RemarkPYQuanPin', 'HeadImgUrl', 'Sex', 'StarFriend', 'Statues']
    output_format = ['NickName','Province','City','PYQuanPin','RemarkName','DisplayName','Sex','Signature']
    out_list = []
    for item in friends:
        #new_item = [item[i] for i in output_format if not isinstance(item[i],'unicode') else item[i].encode('gbk')]
        cur_list = []
        for i in output_format:
            new_value = item[i]
            #if isinstance(item[i],unicode):#python2专用
            #    new_value = new_value.encode('utf8')
            cur_list.append(new_value)
        print('\t'.join([str(i) for i in cur_list]))
        out_list.append(cur_list)
        #print json.dumps(new_item, ensure_ascii=False)
    #print json.dumps(friends[:5], ensure_ascii=False)
    #=======================
    dh = pd.DataFrame(out_list, columns=output_format)
    #out_list
    #!pip install xlwt
    dh.to_excel('wechat_data.xls')# 保存数据到本地
    print('{0}好友信息抓取完毕{0}'.format('-'*10))
    # 初始化计数器，有男有女，当然，有些人是不填的
    # 1表示男性，2女性
    sex_dict = {'1':['男',0], '2':['女',0], '0':['其他',0]}
    for i in friends[1:]:
        sex = str(i["Sex"])
        sex_dict[sex][1] += 1
    # 计算性别比
    total = len(friends[1:])
    male = sex_dict['1'][1] 
    female = sex_dict['2'][1]
    other = sex_dict['0'][1]
    # 打印结果
    print("男性好友：%d, 一共%s, 比例 %.2f%%" % (male, total, float(male) / total * 100))
    print(u"女性好友：%d, 一共%s, 比例 %.2f%%" % (female, total, float(female) / total * 100))
    print(u"其他：%d, 一共%s, 比例 %.2f%%" % (other, total, float(other) / total * 100))
    print(sex_dict)

    # 地理位置分布
    location_list = dh.filter(['Province','City']).values
    location_dict = {}
    city_dict = {}
    for i in location_list:
        location_dict[i[0]] = location_dict.get(i[0], 0) + 1
        city_dict[i[1]] = city_dict.get(i[1], 0) + 1
    #location_dict
    #city_dict

    #jieba自定义词库
    # ①一个个添加
    word_seg_list = ['邹市明','不冒不失','大数据','机器学习','星辰大海','本','删人','微信','蝶变','蹉跎']
    for i in word_seg_list:
        jieba.add_word(i) # 添加
    #jieba.del_word("不冒") # 删除
    # 直接加载字典文件
    #格式：一个词占一行；每一行分三部分：词语、词频（可省略）、词性（可省略），用空格隔开，顺序不可颠倒。
    #file_name 若为路径或二进制方式打开的文件，则文件必须为 UTF-8 编码。
    #jieba.load_userdict(file_name) 
    # 中文停用词表，下载地址：
    # ①https://download.csdn.net/download/ybk233/10606306
    # ②1893个，https://blog.csdn.net/shijiebei2009/article/details/39696571
    stopword_file = 'stopword_china.txt'
    stopword_list = [i.strip() for i in open(stopword_file, encoding='utf8')]
    #stopword_list

    sign_list = []
    cut_list = []
    sign_dict = {'empty':{'男':0, '女':0, '其他':0},
                 'not':{'男':0, '女':0, '其他':0},
                 'all':{'男':0, '女':0, '其他':0}}
    word_dict = {} # 词频记录
    print(sex_dict)
    for i in friends:
        signature = i["Signature"]
        signature.replace(" ", "").replace("span", "").replace("class", "").replace("emoji", "")
        #rep = re.compile("1f\d.+")
        rep = re.compile("<span.*?>.*?</span>")
        signature = rep.sub("", signature.replace('\n','|'))
        # 当前信息
        cur_name = i['NickName']
        cur_sex = sex_dict[str(i['Sex'])][0]# 性别
        sign_dict['all'][cur_sex] += 1
        if signature:
            sign_dict['not'][cur_sex] += 1
        else:
            sign_dict['empty'][cur_sex] += 1
            continue
        # 当前签名分词
        sign_cut = [w for w in jieba.cut(signature)]#, cut_all=True)
        for w in sign_cut:
            w = w.strip()
            if w not in word_dict:
                word_dict[w] = {'男':0,'女':0,'其他':0, 'all':0}
            word_dict[w][cur_sex] += 1
            word_dict[w]['all'] += 1
        sign_list.append([signature, cur_sex])
        cut_list.extend(sign_cut)
        print('[%s]\t%s\t%s ==> %s'%( cur_sex, cur_name, signature, '/'.join(sign_cut)))
    #print(word_dict)
    word_list = []
    # 去停用词
    for w in word_dict:
        if not w or w in stopword_list:
            #word_dict.pop(w)
            continue
        word_list.append([w, word_dict[w]])
    #print(word_list)
    word_list = sorted(word_list, key=lambda x:x[1]['all'], reverse=True)
    print(word_list[:10])
    print('{0}数据准备完毕{0}'.format('-'*10))
    # 生成报告
    page = pe.Page('签名词云分布')
    #-------性别分布---------
    attr = []
    val = []
    for _, v in sex_dict.items():
        attr.append(v[0])
        val.append(v[1])
    pie = pe.Pie('%s的%s微信好友性别分布'%(user, total), title_pos='center')
    pie.add('百分比', attr, val, radius=[10,50], 
            is_label_show=True, legend_orient='vertical',legend_pos='right',
           label_text_color='green', is_more_utils=True)#,rosetype=True)
    page.add(pie)
    #-------签名习惯-------------
    attr = ['无', '有']
    val1 = [sign_dict['empty']['男'], sign_dict['not']['男']]
    val2 = [sign_dict['empty']['女'], sign_dict['not']['女']]
    val3 = [sign_dict['empty']['其他'], sign_dict['not']['其他']]
    pie = pe.Pie('%s的朋友是否有签名(男，女，其他)'%(user), title_pos='center')
    pie.add('男性签名倾向', attr, val1, radius=[5,30], 
            is_label_show=True, legend_orient='vertical',legend_pos='right',
           label_text_color='green')#,rosetype=True)#is_random=True, 
    pie.add('女性签名倾向', attr, val2, radius=[35,60], 
            is_label_show=True, legend_orient='vertical',legend_pos='right',
            label_text_color='green')#,rosetype=True)
    pie.add('其他签名倾向', attr, val3, radius=[65,80], 
            is_label_show=True, legend_orient='vertical',legend_pos='right',
           label_text_color='green', is_more_utils=True)#,rosetype=True)
    page.add(pie)
    #------------地理位置分布-------
    #先安装扩展包
    #pip install echarts-countries-pypkg echarts-china-provinces-pypkg echarts-china-cities-pypkg echarts-china-counties-pypkg echarts-china-misc-pypkg
    attr = location_dict.keys()
    value = location_dict.values()
    #value = [155, 10, 66, 78, 33, 80, 190, 53, 49.6]
    #attr = ["福建", "山东", "北京", "上海", "甘肃", "新疆", "河南", "广西", "西藏"]
    map = pe.Map("%s的微信好友地理分布"%(user), title_pos='center')#, width=600, height=400
    map.add("好友人数",attr,value,maptype="china", #world,china
        is_visualmap=True,visual_text_color="#050",legend_pos='left', is_more_utils=True)
    map.render('map_china.html')
    page.add(map)
    #-----------词云--------
    name = [i[0] for i in word_list]
    value_all = [i[1]['all'] for i in word_list]
    value_male = [i[1]['男'] for i in word_list]
    value_female = [i[1]['女'] for i in word_list]
    value_other = [i[1]['其他'] for i in word_list]
    wc1 = pe.WordCloud('%s微信好友签名关键词-男'%(user), title_pos='center')
    wc1.add("关键词", name, value_male, word_size_range=[10, 100], is_more_utils=True)
    page.add(wc1)
    wc2 = pe.WordCloud('%s微信好友签名关键词-女'%(user), title_pos='center')
    wc2.add("关键词", name, value_female, word_size_range=[10, 100], is_more_utils=True)
    page.add(wc2)
    wc3 = pe.WordCloud('%s微信好友签名关键词-其他'%(user), title_pos='center')
    wc3.add("关键词", name, value_other, word_size_range=[10, 100], is_more_utils=True)
    page.add(wc3)
    wc4 = pe.WordCloud('%s微信好友签名关键词-所有'%(user), title_pos='center')
    wc4.add("关键词", name, value_all, word_size_range=[10, 100], is_more_utils=True)
    page.add(wc4)
    #---------------------
    page.render('wechat_%s.html'%(user))
    #page
    print('{0}报表渲染完毕{0}'.format('-'*10))
    # 微信头像保存地址
    img_dir = './img_%s'%(user)
    # 下载微信头像
    get_icon(img_dir)
    # 拼接微信头像
    out_dir = '.'
    out_file = stitch_icon(img_dir, out_dir)
    # 将这张得到的图片发送到你的微信
    itchat.send_image(out_file)
    # 当然你也可以将这张得到的图片分享给你的好友
    itchat.send_image(out_file, toUserName='filehelper')
    print('{0}微信头像处理完毕{0}'.format('-'*10))
