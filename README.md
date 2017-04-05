# 个人代码集锦
积累平时的代码
## python使用mysql方法
### 安装方法
mac下安装MySQL-python

要想使python可以操作mysql，就需要MySQL-python驱动，它是python 操作mysql必不可少的模块。
- [下载地址](https://pypi.python.org/pypi/MySQL-python/)
- 下载MySQL-python-1.2.5.zip 文件之后直接解压。
- 进入MySQL-python-1.2.5目录:
```shell
python setup.py install
```
### 连接mysql
shell 代码，shell脚本中调用sql脚本
```shell
#mysql初始化-shell
mysql=/usr/local/mysql/bin/mysql
$mysql -uroot -pwqw  < init.sql
```
或者shell脚本中直接执行sql
```shell
mysql=/usr/local/mysql/bin/mysql
$mysql -uroot -p123456 <<EOF  
source /root/temp.sql;  
select current_date();  
delete from tempdb.tb_tmp where id=3;  
select * from tempdb.tb_tmp where id=2;  
EOF
```
## 爬虫
### python抓取链接二手房数据
- [链家二手房数据分析](https://zhuanlan.zhihu.com/p/25132058)
- [scrapy爬链家成都房价并可视化](https://github.com/happyte/buyhouse)
- [抓知乎爬虫](http://www.csuldw.com/2016/11/05/2016-11-05-simulate-zhihu-login/)

## json使用

### shell中使用json
- #[2016-12-31] shell中使用json
- 安装：
> pip install git+https://github.com/dominictarr/JSON.sh#egg=JSON.sh

- 使用：
```shell
echo '{"a":2,"b":[3,6,8]}' |JSON.sh
```
详情参考：https://github.com/dominictarr/JSON.sh

## 可视化
### 地图数据可视化
- [地图汇](http://www.dituhui.com/)
- [5min上手写echarts第一个图标](http://echarts.baidu.com/echarts2/doc/start.html),[echarts如何从json文件读数据？](http://bbs.csdn.net/topics/392042291)

## 学习资料
### 数学基础
- [六大概率分布](http://www.csuldw.com/2016/08/19/2016-08-19-probability-distributions/)
- [最优化算法-避开鞍点](http://www.csuldw.com/2016/07/10/2016-07-10-saddlepoints/)
- [频率学派与贝叶斯学派之争](http://www.cnblogs.com/549294286/archive/2013/04/08/3009073.html)：[知乎网友解释](https://www.zhihu.com/question/20587681/answer/21294468),频率学派最先出现，疯狂打压新生的贝叶斯学派，贝叶斯很凄惨，就跟艺术圈的梵高一样，死后的论文才被自己的学生发表，经过拉普拉斯之手发扬光大，目前二派就像华山派的剑宗和气宗。频率学派挺煞笔的，非得做大量实验才能给出结论，比如你今年高考考上北大的概率是多少啊？频率学派就让你考100次，然后用考上的次数除以100。而贝叶斯学派会找几个高考特级教师对你进行一下考前测验和评估，然后让这几个教师给出一个主观的可能性，比如说：你有9成的把握考上北大。
   - 这个区别说大也大，说小也小。（1）往大里说，世界观就不同，频率派认为参数是客观存在，不会改变，虽然未知，但却是固定值；贝叶斯派则认为参数是随机值，因为没有观察到，那么和是一个随机数也没有什么区别，因此参数也可以有分布，个人认为这个和量子力学某些观点不谋而合。（2） 往小处说，频率派最常关心的是似然函数，而贝叶斯派最常关心的是后验分布。我们会发现，后验分布其实就是似然函数乘以先验分布再normalize一下使其积分到1。因此两者的很多方法都是相通的。贝叶斯派因为所有的参数都是随机变量，都有分布，因此可以使用一些基于采样的方法（如MCMC）使得我们更容易构建复杂模型。频率派的优点则是没有假设一个先验分布，因此更加客观，也更加无偏，在一些保守的领域（比如制药业、法律）比贝叶斯方法更受到信任。
   - 频率 vs 贝叶斯 =   P(X;w)  vs  P(X|w) 或 P(X,w) 
   - 频率学派认为参数固定，通过无数字实验可以估计出参数值——客观；
   - 贝叶斯学派认为参数和数据都是随机的，参数也服从一定的分布，需要借助经验——主观
- 其他

### 推荐系统
- [项量：关于LDA，pLSA，SVD和Word2vector的一些看法](https://zhuanlan.zhihu.com/p/21377575)：
  - SVD算法是指在SVD的基础上引入隐式反馈，使用用户的历史浏览数据、用户历史评分数据、电影的历史浏览数据、电影的历史评分数据等作为新的参数
  - LSA最初是用在语义检索上，为了解决一词多义和一义多词的问题,将词语（term）中的concept提取出来，建立一个词语和概念的关联关系（t-c relationship），这样一个文档就能表示成为概念的向量。这样输入一段检索词之后，就可以先将检索词转换为概念，再通过概念去匹配文档。在实际实现这个思想时，LSA使用了SVD分解的数学手段.x=T*S*D
  - PLSA和LSA基础思想是相同的，都是希望能从term中抽象出概念，但是具体实现的方法不相同。PLSA使用了概率模型，并且使用EM算法来估计P（t|c）和P（c|d）矩阵.LDA是pLSA的generalization：一方面LDA的hyperparameter设为特定值的时候，就specialize成pLSA了
  - NMF：一种矩阵分解，要求输入矩阵元素非负，目标和 SVD 一样。
  - pLSA：SVD 的一种概率解释方法——要求矩阵元素是非负整数。LDA：pLSA 加上 topics 的 Dirichlet 先验分布后得到的 Bayesian model，数学上更漂亮。为什么是 Dirichlet 先验分布，主要是利用了 Dirichlet 和 multinomial 分布的共轭性，方便计算。
- [从item-base到svd再到rbm，多种Collaborative Filtering(协同过滤算法)从原理到实现](http://blog.csdn.net/dark_scope/article/details/17228643)
- 案例分享：[世纪佳缘推荐系统经验分享](http://www.csdn.net/article/2015-02-15/2823976)
- 其他
### 深度学习
- 深度学习书籍：[Deep Learning中文版](https://exacity.github.io/deeplearningbook-chinese/),[英文版](http://www.deeplearningbook.org/front_matter.pdf),[Andrej Karpathy博客](http://karpathy.github.io/neuralnets/),[Colah's Blog](http://colah.github.io/)
### 知识图谱
- [精益知识图谱方法论](http://blog.memect.cn/?p=2005)
## IT资讯
- 查公司信息：[天眼查](http://www.tianyancha.com/),[IT桔子](https://www.itjuzi.com/)
- [互联网黑名单](https://github.com/shengxinjing/programmer-job-blacklist)
- 查公司信息：[天眼查](http://www.tianyancha.com/),[IT桔子](https://www.itjuzi.com/)
 ## 工具
- 视频下载工具：[硕鼠](http://tv.cntv.cn/video/C10435/9d677bac906247de9782b1104a70110e)(可以下载流视频),[维棠](http://www.vidown.cn/)
 ## 新技术
- [区块链](http://t.cn/R6HR9ji)：分布式总账技术，所有节点都记录账本，更安全
