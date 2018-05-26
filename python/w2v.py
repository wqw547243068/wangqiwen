# 参考地址：http://www.52nlp.cn/%E4%B8%AD%E8%8B%B1%E6%96%87%E7%BB%B4%E5%9F%BA%E7%99%BE%E7%A7%91%E8%AF%AD%E6%96%99%E4%B8%8A%E7%9A%84word2vec%E5%AE%9E%E9%AA%8C
import logging  
import os  
import time  
  
import gensim  
from gensim.models import word2vec  
import jieba  
#import nltk 
import json
  
#a=jieba.cut(str,cut_all=False)
#print '/'.join(a)
  
logging.basicConfig(format='%(asctime)s:%(levelname)s:%(message)s',level=logging.INFO)    
start1 = time.clock()   
input_file_name = u'E:/百度云/IT技术_new/编程语言/python/demo/word/result.txt' # 原始文件Unicode编码
input_file_f = open(input_file_name,'r')  
#contents = input_file_f.read() # 整个文件读到一个变量里
print '读取文件耗时：',time.clock()
#sentences = [i.strip().split(" ") for  i in contents[:10]]
sentences = []
print '转换后:\n','|'.join(['&'.join(i) for i in sentences])
# 开始逐行处理
for line in input_file_f.readlines(): 
    #按行读取 
    sentences.append(line.strip().split(" "))
#print '行数:%s,内容:\n'%(len(sentences)),json.dumps(sentences,ensure_ascii=False)
#sentences是句子序列，句子又是单词列表，比如，sentences = [['first', 'sentence'], ['second', 'sentence']]
model = word2vec.Word2Vec(sentences,min_count=2,size=200) #min_count表示小于该数的单词会被剔除，默认值为5;size表示神经网络的隐藏层单元数，默认为100
#保存生成的训练模型
output_model = u'E:/百度云/IT技术_new/编程语言/python/demo/word/model'
model.save(output_model)#加载模型文件new_model = gensim.models.Word2Vec.load('model/mymodel4')
#=================
#加载模型文件
new_model = gensim.models.Word2Vec.load(output_model)
dir(new_model) # 多种函数方法,
print new_model.vector_size # 词向量维度
print ','.join(new_model.index2word) # index2word保存单词
# 计算指定词的所以相似词
test_word = '经理'
similar_word_list = new_model.most_similar(test_word)
print json.dumps(similar_word_list,ensure_ascii=False)
#print json.dumps(similar_word_list,ensure_ascii=False,indent=4)
# 抽取北京的搜索session：select query_list from user_satisfy_query where dt=20160918 and province rlike '^010' and count > 1;
#print json.dumps(new_model.most_similar(u'天安门'),ensure_ascii=False)
#In [76]: print json.dumps(new_model.most_similar(u'旅店'),ensure_ascii=False)
#[["莫泰", 0.8472937345504761], ["易佰", 0.8139138221740723], ["168", 0.7009128928184509], ["连锁", 0.6979336738586426], ["旅馆", 0.6874777674674988], ["旺子成", 0.6520262360572815], ["快捷", 0.6426747441291809], ["家庭旅馆", 0.6317397356033325], ["人在旅途", 0.6164605021476746], ["寺易佰", 0.6112728714942932]]
#In [77]: print json.dumps(new_model.most_similar(u'菜馆'),ensure_ascii=False)
#[["家常菜", 0.8295753598213196], ["风味", 0.8144116401672363], ["正宗", 0.8008058071136475], ["菜", 0.787124514579773], ["饺子馆", 0.7830443382263184], ["刀削面", 0.7752013802528381], ["特色", 0.7629570364952087], ["面馆", 0.7591361403465271], ["面", 0.7421250939369202], ["农家菜", 0.7410575747489929]]
#In [158]: print json.dumps(new_model.most_similar(u'软件园'),ensure_ascii=False)  
#[["用友", 0.7017531991004944], ["金蝶", 0.6142528057098389], ["孵化器", 0.5947192907333374], ["网易", 0.5910834074020386], ["f11", 0.584527850151062], ["软件", 0.5816747546195984], ["租贷", 0.5489269495010376], ["卵", 0.5268262624740601], ["鲜花网", 0.5116425156593323], ["广联达", 0.507921576499939]]
#In [171]: print json.dumps(new_model.most_similar(u'美食'),ensure_ascii=False)
#[["中餐", 0.8337364196777344], ["川菜", 0.7456749677658081], ["快餐", 0.7315336465835571], ["西餐", 0.6596412658691406], ["自助餐", 0.6401817202568054], ["老姬", 0.6020432710647583], ["日本料理", 0.5849108099937439], ["合利屋", 0.5827316045761108], ["nokia", 0.5804284811019897], ["早点", 0.5785887241363525]]
#In [176]: print json.dumps(new_model.most_similar(u'麦当劳'),ensure_ascii=False)
#[["肯德基", 0.857654869556427], ["肯德鸡", 0.6457746028900146], ["KFC", 0.6434839963912964], ["kfc", 0.6308714151382446], ["街鼎", 0.6141167283058167], ["FSDT", 0.589178204536438], ["康得基", 0.5770742893218994], ["得来", 0.5747169852256775], ["十佛营", 0.5702893137931824], ["必胜客", 0.5698955655097961]]
print '（1）找某个词的相似词汇如下:\n词汇\t相似度\n','\n'.join(['%s\t%s'%(i[0],i[1]) for i in similar_word_list])
# 计算任意两个词的相似度
word_1 = '经理';word_2 = '数据'
print '（2）任意两个词汇的相似度(%s与%s)'%(word_1,word_2),new_model.similarity(word_1,word_2)
word_set_1 = ['经理','效率'];word_set_2 = ['数据','流程','重复']
print '（3）两个数据集间的余弦距离(%s)与(%s)：'%(json.dumps(word_set_1,ensure_ascii=False),json.dumps(word_set_1,ensure_ascii=False)),new_model.n_similarity(word_set_1, word_set_2) 
print '（4）找集合中不同的一项：(%s)'%(json.dumps(word_set_2,ensure_ascii=False)),new_model.doesnt_match(word_set_2)
# 独特的组合加减法
print json.dumps(new_model.most_similar(positive=[u'麦当劳'],negative=[u'肯德基',u'真功夫']),ensure_ascii=False)
