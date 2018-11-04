# coding:utf8
"""
    图灵机器人与青云客机器人聊天对战
    使用方法：终端执行此脚本，python chatbot.py, 输入一个词启动会话即可
    [2018-11-4]python初学者好玩案例:https://blog.csdn.net/qq_18495537/article/details/79278710
"""
from time import sleep  
import requests

s = input("请主人输入话题：(随便什么词)")
same_max = 10#中止条件，恢复语句中最多多少次相同
same_count = 0
last_resp = '-'
count = 0
print('{}\t{:<40}\t{:<40}\n{}'.format('轮数', '图灵(问)', '青云客(答)', '-'*80))
while True:
    count += 1
    #图灵机器人
    resp = requests.post("http://www.tuling123.com/openapi/api",
        data={"key": "e5ccc9c7c8834ec3b08940e290ff1559", "info": s, })  
    resp = resp.json()
    #print('第{}轮\t图灵：\t{}'.format(count, resp['text']))
    if resp == last_resp:
        same_count += 1
    if same_count > same_max:
        print('这两货把天儿聊死了。。。哈哈哈')
        break
    #青云客机器人
    s = resp['text']  
    resp = requests.get("http://api.qingyunke.com/api.php", {'key': 'free', 'appid': 0, 'msg': s})  
    resp.encoding = 'utf8'  
    resp = resp.json() 
    sleep(1)
    #print('第{}轮\t青云客：\t{}'.format(count, resp['content']))
    print('{}\t{:<40}\t{:<40}'.format(count, s, resp['content']))