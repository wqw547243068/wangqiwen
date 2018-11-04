# -*- coding=utf-8 -*-
import requests
import itchat
import random
# import sys
# reload(sys)
# sys.setdefaultencoding('utf-8')

import os
import sys
import json
import cv2
from PIL import ImageGrab

#原文：https://blog.csdn.net/weixin_37557902/article/details/82740593 
usageMsg = u"使用方法：\n1.运行CMD命令：cmd xxx (xxx为命令)\n" \
           u"例如关机命令:\ncmd shutdown -s -t 0 \n" \
           u"2.获取摄像头并拍照：cap\n" \
           u"2.获取屏幕截屏：pc\n" \

KEY = '04f44290d4cf462aae8ac563ea7aac16'

def get_response(msg):
    apiUrl = 'http://www.tuling123.com/openapi/api'
    data = {
        'key'    : KEY,
        'info'   : msg,
        'userid' : 'wechat-robot',
    }
    try:
        r = requests.post(apiUrl, data=data).json()
        return r.get('text')
    except:
        return

@itchat.msg_register('Text')
def handler_receive_msg(msg):  # 处理收到的消息
    message = msg['Text']
    toName = msg['ToUserName']
    #owner = msg['User']['PYQuanPin']
    # 临时保存截屏图片地址
    #path = 'C:\Users\wqw\Desktop\fig\temp.jpg'
    path = 'tmp.jpg'
    reply = json.dumps(msg, ensure_ascii=False)
    reply = '你发了：%s'%message
    #{"MsgId": "9212371634710588729", "FromUserName": "@ad238825281702d637159eab5f24f89e", "ToUserName": "@ad238825281702d637159eab5f24f89e", "MsgType": 1, "Content": "你", "Status": 3, "ImgStatus": 1, "CreateTime": 1541315145, "VoiceLength": 0, "PlayLength": 0, "FileName": "", "FileSize": "", "MediaId": "", "Url": "", "AppMsgType": 0, "StatusNotifyCode": 0, "StatusNotifyUserName": "", "RecommendInfo": {"UserName": "", "NickName": "", "QQNum": 0, "Province": "", "City": "", "Content": "", "Signature": "", "Alias": "", "Scene": 0, "VerifyFlag": 0, "AttrStatus": 0, "Sex": 0, "Ticket": "", "OpCode": 0}, "ForwardFlag": 0, "AppInfo": {"AppID": "", "Type": 0}, "HasProductId": 0, "Ticket": "", "ImgHeight": 0, "ImgWidth": 0, "SubMsgType": 0, "NewMsgId": 9212371634710588729, "OriContent": "", "EncryFileName": "", "User": {"MemberList": [], "UserName": "@ad238825281702d637159eab5f24f89e", "City": "海淀", "DisplayName": "", "PYQuanPin": "wangqiwen", "RemarkPYInitial": "", "Province": "北京", "KeyWord": "wqw", "RemarkName": "", "PYInitial": "WQW", "EncryChatRoomId": "", "Alias": "", "Signature": "自律更自由", "NickName": "王奇文", "RemarkPYQuanPin": "", "HeadImgUrl": "/cgi-bin/mmwebwx-bin/webwxgeticon?seq=661826231&username=@ad238825281702d637159eab5f24f89e&skey=@crypt_15c532e6_ba943df756f74fb80686ff7d62c8c677", "UniFriend": 0, "Sex": 1, "AppAccountFlag": 0, "VerifyFlag": 0, "ChatRoomId": 0, "HideInputBarFlag": 0, "AttrStatus": 33656871, "SnsFlag": 17, "MemberCount": 0, "OwnerUin": 0, "ContactFlag": 3, "Uin": 965715160, "StarFriend": 0, "Statues": 0, "WebWxPluginSwitch": 0, "HeadImgFlag": 1, "IsOwner": 0}, "Type": "Text", "Text": "你"}
    if toName in ('@ad238825281702d637159eab5f24f89e', "filehelper" ):
        if message == "cap":  # 拍照
            #  要使用摄像头，需要使用cv2.VideoCapture(0)创建VideoCapture对象，
            # 参数：0指的是摄像头的编号。如果你电脑上有两个摄像头的话，访问第2个摄像头就可以传入1
            cap = cv2.VideoCapture(0)
            ret, img = cap.read()  # 获取一帧
            cv2.imwrite("temp.jpg", img)
            itchat.send('@img@%s' % u'temp.jpg', toName)
            cap.release()  # 释放资源
        if message[0:3] == "cmd":  # 处理cmd命令
            os.system(message.strip(message[0:4]))
        if message == "pc":  # 截图
            im = ImageGrab.grab()  # 实现截屏功能
            im.save(path, 'JPEG')  # 设置保存路径和图片格式
            itchat.send_image(path, toName)

    robots = ['-^-','^-^','~v~']
    reply = get_response(msg['Text'])+random.choice(robots)
    res = '收到%s的消息[%s], 回复:[%s]'%(toName, message, reply)
    print(sys.stderr, res)
    return reply or defaultReply

# @itchat.msg_register(itchat.content.TEXT)
# def tuling_reply(msg):
#     defaultReply = 'I received: ' + msg['Text']
#     #robot = ['——By机器人小杨','——By机器人白杨','——By反正不是本人']
#     robots = ['-^-','^-^','~v~']
#     reply = get_response(msg['Text'])+random.choice(robots)
#     return reply or defaultReply

# 处理群聊消息
"""
@itchat.msg_register(itchat.content.TEXT, isGroupChat=True)
def text_reply(msg):
  if msg['isAt']:
    itchat.send(u'@%s\u2005I received: %s' % (msg['ActualNickName'], msg))
"""
# 自动回复
# 封装好的装饰器，当接收到的消息是Text，即文字消息
"""
@itchat.msg_register('Text')
def text_reply(msg):
    # 当消息不是由自己发出的时候
    if not msg['FromUserName'] == myUserName:
        # 发送一条提示给文件助手
        itchat.send_msg(u"[%s]收到好友@%s 的信息：%s\n" %
                        (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(msg['CreateTime'])),
                         msg['User']['NickName'],
                         msg['Text']), 'filehelper')
        # 回复给好友
        return u'[自动回复]您好，我现在有事不在，一会再和您联系。\n已经收到您的的信息：%s\n' % (msg['Text'])
"""



if __name__ == '__main__':
    itchat.auto_login()
    # 获取自己的UserName
    #myUserName = itchat.get_friends(update=True)[0]["UserName"]
    owner = "@ad238825281702d637159eab5f24f89e"#filehelper
    itchat.send(usageMsg, owner)#,filehelper
    itchat.run()