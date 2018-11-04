##################### 完整代码##############################
# 加载库
from itchat.content import *
import requests
import json
import itchat


# 调用图灵机器人的api，采用爬虫的原理，根据聊天消息返回回复内容
def tuling(info):
    appkey = "e5ccc9c7c8834ec3b08940e290ff1559"
    url = "http://www.tuling123.com/openapi/api?key=%s&info=%s"%(appkey,info)
    req = requests.get(url)
    content = req.text
    data = json.loads(content)
    answer = data['text']
    return answer

# 对于群聊信息，定义获取想要针对某个群进行机器人回复的群ID函数
def group_id(name):
    df = itchat.search_chatrooms(name=name)
    return df[0]['UserName']

# 注册文本消息，绑定到text_reply处理函数
# text_reply msg_files可以处理好友之间的聊天回复
@itchat.msg_register([TEXT,MAP,CARD,NOTE,SHARING])
def text_reply(msg):
    itchat.send('%s' % tuling(msg['Text']),msg['FromUserName'])

@itchat.msg_register([PICTURE, RECORDING, ATTACHMENT, VIDEO])
def download_files(msg):
    msg['Text'](msg['FileName'])
    return '@%s@%s' % ({'Picture': 'img', 'Video': 'vid'}.get(msg['Type'], 'fil'), msg['FileName'])

# 现在微信加了好多群，并不想对所有的群都进行设置微信机器人，只针对想要设置的群进行微信机器人，可进行如下设置
@itchat.msg_register(TEXT, isGroupChat=True)
def group_text_reply(msg):
    # 当然如果只想针对@你的人才回复，可以设置if msg['isAt']: 
    item = group_id(u'想要设置的群的名称')  # 根据自己的需求设置
    if msg['ToUserName'] == item:
        itchat.send(u'%s' % tuling(msg['Text']), item)

if __name__ == '__main__':
    appkey = "e5ccc9c7c8834ec3b08940e290ff1559"
    info = '你好!' 
    cnt = 1
    while True:
        info = input("[第%s轮]\t"%(cnt))
        if info.find("exit") != -1 or info.find("quit") != -1 or info.find("退出") != -1:
            print("退出...")
            break
        url = "http://www.tuling123.com/openapi/api?key=%s&info=%s"%(appkey,info)
        req = requests.get(url)
        content = req.text
        data = json.loads(content)
        answer = data['text']
        print("答 复: \t%s"%(answer))
        cnt += 1
    print('='*30)
    print(tuling(u'你好'))
    #itchat.auto_login(hotReload = True)
    #itchat.run()
