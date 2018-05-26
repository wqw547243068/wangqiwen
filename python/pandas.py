# pandas读取excel数据示例
# 【2016-7-30】 参考：十分钟搞定pandas：http://www.cnblogs.com/chaosimple/p/4153083.html
import pandas as pd
import numpy as np

# 读取数据 D:\work\用户建模画像\家公司挖掘\code\warren.xls
# 数据格式：time
print('start')
df = pd.read_excel('C:\Users\warren\Desktop\warren.xlsx',index='time')
# df = pandas.read_excel(open('your_xls_xlsx_filename','rb'), sheetname='Sheet 1')
#df.index # 行序号
df.columns # 列名
#df['lon'],df['lat'],df[:30] # 按照列名读取数据
#df.ix[:30,:3] # 使用ix、loc或者iloc(按照下标组合)进行行列双向读取，即切片操作
#df.ix[:20,['lon','lat']] # 跨属性组合选取
df.loc[:100,['time','lon','lat']] # 同上
#new = df.iloc[:20,[1,2]]
#new.describe # 基本统计信息
#type(new)
#df[df.lon>117] # 按照数值过滤筛选
#df[df.time<'2016-07-20']
#new.values.tolist() # DataFrame转成list结构
#df.sort(columns='time') # 排序
