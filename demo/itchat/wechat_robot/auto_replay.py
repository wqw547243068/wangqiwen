# -*- coding:utf-8 -*-
"""
	微信机器人，自动回复
"""
import requests
import random
import sys
import json
import itchat, time, re
from itchat.content import *


@itchat.msg_register([TEXT])
def text_reply(msg, category = 2):
	""" 文本消息回复 """
	message = msg['Text']
	toName = msg['ToUserName']
    #owner = msg['User']['PYQuanPin']
    #reply = json.dumps(msg, ensure_ascii=False)
    # 微信表情符对照表：https://www.cnblogs.com/xuange306/p/7098236.html
	emoji_tag = [')', 'B', 'X', 'Z', 'Q', 'T', 'L', 'g', '|', '<','>', '~', ",(", '$', '!','O', 'P', '+', '*']
	emoji_list = ["/::%s"%(i) for i in emoji_tag]
	reply = '不知道说啥好了' # 安全回答
	if category == 1:
		# （1）自动拜年回复
	    match = re.search(u'年', msg['Text']).span()
	    if match:
	    	reply = '谢谢！新春快乐，鸡年大吉，身体健康，万事如意！'
	elif category == 2:
		# （2）启动图灵机器人
		try:
			#reply_api = tuling(msg['Text'])
			reply_api = get_response(msg['Text'])
		except Exception:
			print(sys.stderr, '接口故障，请跟进，返回默认答复')
			reply_api = reply
		# 拼接微信表情符(随机选取)
		reply = '%s %s'%(reply_api, random.choice(emoji_list))
	else:
		print('category取值异常')
	# 回复
	#itchat.send(reply, msg['FromUserName'])
	res = '收到%s的消息[%s], 回复:[%s]'%(toName, message, reply)
	print(sys.stderr, res)
	return reply

@itchat.msg_register([PICTURE, RECORDING, VIDEO, SHARING])
def other_reply(msg):
    itchat.send((u'新春快乐，鸡年大吉，身体健康，万事如意！'), msg['FromUserName'])


# 注册文本消息，绑定到text_reply处理函数
# text_reply msg_files可以处理好友之间的聊天回复
@itchat.msg_register([MAP,CARD,NOTE,SHARING])
def text_reply(msg):
    itchat.send('%s' % tuling(msg['Text']),msg['FromUserName'])

@itchat.msg_register([PICTURE, RECORDING, ATTACHMENT, VIDEO])
def download_files(msg):
    msg['Text'](msg['FileName'])
    return '@%s@%s' % ({'Picture': 'img', 'Video': 'vid'}.get(msg['Type'], 'fil'), msg['FileName'])

# # 对于群聊信息，定义获取想要针对某个群进行机器人回复的群ID函数
# def group_id(name):
#     df = itchat.search_chatrooms(name=name)
#     return df[0]['UserName']

# # 现在微信加了好多群，并不想对所有的群都进行设置微信机器人，只针对想要设置的群进行微信机器人，可进行如下设置
# @itchat.msg_register(TEXT, isGroupChat=True)
# def group_text_reply(msg):
#     # 当然如果只想针对@你的人才回复，可以设置if msg['isAt']: 
#     item = group_id('未来计划群')  # 根据自己的需求设置
#     if msg['ToUserName'] == item:
#         itchat.send(u'%s' % tuling(msg['Text']), item)

# 调用图灵机器人的api，采用爬虫的原理，根据聊天消息返回回复内容
def tuling(info):
    appkey = "e5ccc9c7c8834ec3b08940e290ff1559"
    url = "http://www.tuling123.com/openapi/api?key=%s&info=%s"%(appkey,info)
    req = requests.get(url)
    content = req.text
    data = json.loads(content)
    answer = data['text']
    return answer

def get_response(msg):
	""" 机器人API """
	result = '-'
	source = '图灵'
	# 图灵机器人＞青云客
	api_turing = 'http://www.tuling123.com/openapi/api'
	appkey = "e5ccc9c7c8834ec3b08940e290ff1559"
	api_qingyunke = "http://api.qingyunke.com/api.php"
	data = {
        'key'    : appkey,
        'info'   : msg,
        'userid' : 'wechat-robot',
	}
	try:
		result = requests.post(api_turing, data=data).json().get('text')
	except:
		#青云客机器人 
		resp = requests.get(api_qingyunke, {'key': 'free', 'appid': 0, 'msg': msg}) 
		resp.encoding = 'utf8'  
		result = resp.json()['content']
		source = '青云客'
	print('{}\t{:<40}\t{:<40}'.format(source, msg, result))
	return result




if __name__ == '__main__':
	# 主程序
	itchat.auto_login(hotReload=True) # 图片二维码
	#itchat.auto_login(enableCmdQR=0.5,hotReload=True) # 终端二维码
	itchat.run()