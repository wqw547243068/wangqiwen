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
### 学习技巧
- @爱可可-爱生活：
 - 互联时代怎么阅读？
 - 读书重在结构生长，形成扎实的支撑；
 - 碎片阅读重在视野的纳新和扩展，开枝散叶；
 - 思考重在提炼和关联，勾画错综的经脉。
 - 学习就是如此，由外而内，无广不精，无博不深，但能坚持必有所成。
 - 网络阅读的最佳实践，不在“取”，在“舍”，知舍才能知关键，料不在多，有感悟一二足矣。
- 学习金字塔

![学习金字塔](https://gss0.baidu.com/9fo3dSag_xI4khGko9WTAnF6hhy/zhidao/wh%3D600%2C800/sign=dae5bdf00ef79052ef4a4f383cc3fbf2/78310a55b319ebc44d04b87a8526cffc1f1716d1.jpg)
### 数学基础
- [线性代数的本质-Essence of Linear Algebra-视频教程](http://www.3blue1brown.com/)，[Bilibili上双语视频教程](http://www.bilibili.com/video/av6731067/). 《数学拾遗》[英文版百度云地址](https://pan.baidu.com/share/link?shareid=1204761446&uk=2416092239&fid=2111748288). 
- [生动讲解矩阵的空间变换](http://blog.csdn.net/a396901990/article/details/44905791)：平移、缩放、旋转、对称（xy或原点）、错切、组合。[行列式的本质是什么？---万门大学童哲的解释](https://www.zhihu.com/question/36966326/answer/70687817):行列式就是线性变换的放大率！理解了行列式的物理意义，很多性质你根本就瞬间理解到忘不了！

![Essence of Linear Algebra](https://pic4.zhimg.com/v2-f0b763934f02eda66a5eef93cc47eaa3_b.jpg)
- 行列式：行列式，记作 det(A)，是一个将方阵 A 映射到实数的函数。行列式等于矩阵特 征值的乘积。行列式的绝对值可以用来衡量矩阵参与矩阵乘法后空间扩大或者缩小 了多少。如果行列式是 0，那么空间至少沿着某一维完全收缩了，使其失去了所有的 体积。如果行列式是 1，那么这个转换保持空间体积不变
- [六大概率分布](http://www.csuldw.com/2016/08/19/2016-08-19-probability-distributions/)
- [最优化算法-避开鞍点](http://www.csuldw.com/2016/07/10/2016-07-10-saddlepoints/)
- [频率学派与贝叶斯学派之争](http://www.cnblogs.com/549294286/archive/2013/04/08/3009073.html)：[知乎网友解释](https://www.zhihu.com/question/20587681/answer/21294468),频率学派最先出现，疯狂打压新生的贝叶斯学派，贝叶斯很凄惨，就跟艺术圈的梵高一样，死后的论文才被自己的学生发表，经过拉普拉斯之手发扬光大，目前二派就像华山派的剑宗和气宗。频率学派挺煞笔的，非得做大量实验才能给出结论，比如你今年高考考上北大的概率是多少啊？频率学派就让你考100次，然后用考上的次数除以100。而贝叶斯学派会找几个高考特级教师对你进行一下考前测验和评估，然后让这几个教师给出一个主观的可能性，比如说：你有9成的把握考上北大。
   - 这个区别说大也大，说小也小。（1）往大里说，世界观就不同，频率派认为参数是客观存在，不会改变，虽然未知，但却是固定值；贝叶斯派则认为参数是随机值，因为没有观察到，那么和是一个随机数也没有什么区别，因此参数也可以有分布，个人认为这个和量子力学某些观点不谋而合。（2） 往小处说，频率派最常关心的是似然函数，而贝叶斯派最常关心的是后验分布。我们会发现，后验分布其实就是似然函数乘以先验分布再normalize一下使其积分到1。因此两者的很多方法都是相通的。贝叶斯派因为所有的参数都是随机变量，都有分布，因此可以使用一些基于采样的方法（如MCMC）使得我们更容易构建复杂模型。频率派的优点则是没有假设一个先验分布，因此更加客观，也更加无偏，在一些保守的领域（比如制药业、法律）比贝叶斯方法更受到信任。
   - 频率 vs 贝叶斯 =   P(X;w)  vs  P(X|w) 或 P(X,w) 
   - 频率学派认为参数固定，通过无数字实验可以估计出参数值——客观；
   - 贝叶斯学派认为参数和数据都是随机的，参数也服从一定的分布，需要借助经验——主观
- [统计学基础知识【脑图笔记】](http://www.cnblogs.com/xiaofeng1234/p/5987845.html)
- 大矩阵相乘：[分布式版本](http://weibo.com/ttarticle/p/show?id=2309404091643656571557),[MapReduce实现矩阵相乘](http://blog.csdn.net/jiangsanfeng1111/article/details/51025744)，[Hadoop实现大矩阵相乘之我见](http://www.cnblogs.com/eczhou/p/3340731.html)
 - A大B小(内存受限)
 ![图](http://images.cnitblog.com/blog/310680/201309/26133812-99b31a08aa934015a11a19cc178713db.png)
 - AB都大(内存受限)
 ![图](http://images.cnitblog.com/blog/310680/201309/26133859-83d01098a7ac4192a7ff02fbaacb2369.png)
 - 不受内存限制（最小粒度）
 ![图](http://images.cnitblog.com/blog/310680/201309/26134115-f5041d455fbe4ef98e3653a77cb31774.png)
- 其他
### 计算机基础
- 排序算法总结：[视觉感受常见排序算法](http://blog.jobbole.com/11745/)
![对比](http://hi.csdn.net/attachment/201105/24/0_1306225542srVx.gif)
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
### 机器学习
#### 算法总结
- [scikit-learn官方总结](http://scikit-learn.org/stable/tutorial/machine_learning_map/index.html#)
![算法对比](http://scikit-learn.org/stable/_static/ml_map.png)
- 算法对比

#### 机器学习经验总结
- [Google机器学习经验总结](http://martin.zinkevich.org/rules_of_ml/rules_of_ml.pdf)

#### 流形学习
- 什么是流形学习？传统的机器学习方法中，数据点和数据点之间的距离和映射函数f都是定义在欧式空间中的，然而在实际情况中，这些数据点可能不是分布在欧式空间中的，因此传统欧式空间的度量难以用于真实世界的非线性数据，从而需要对数据的分布引入新的假设。流形(Manifold)是局部具有欧式空间性质的空间，包括各种纬度的曲线曲面，例如球体、弯曲的平面等。流形是线性子空间的一种非线性推广。参考[流形学习的简单介绍](https://jlunevermore.github.io/2016/06/25/43.%E6%B5%81%E5%BD%A2%E5%AD%A6%E4%B9%A0/)
- 流形学习：本质上，流形学习就是给数据降维的过程。这里假设数据是一个随机样本，采样自一个高维欧氏空间中的流形（manifold），流形学习的任务就是把这个高维流形映射到一个低维（例如2维）的空间里。流形学习可以分为线性算法和非线性算法，前者包括主成分分析（PCA）和线性判别分析（LDA），后者包括等距映射（Isomap），拉普拉斯特征映射（LE）等。流形学习可以用于特征的降维和提取，为后续的基于特征的分析，如聚类和分类，做铺垫，也可以直接应用于数据可视化等。注：摘自[集智百科流形学习（优质，包含代码及案例）](http://wiki.swarma.net/index.php/%E6%B5%81%E5%BD%A2%E5%AD%A6%E4%B9%A0)。
 - 拟合线性的流形学习模型：LLE, LTSA, Hessian LLE, 和Modified LLE
 - 拟合非线性的流形学习模型：Isomap，MDS和Spectral Embedding
 - 效果示意如下：![降维效果](http://wiki.swarma.net/images/thumb/a/ad/Manifoldlearning_figure_1.png/800px-Manifoldlearning_figure_1.png)
#### 降维
 常见的pca属于无监督，lda有监督,常用降维方法如下图。![常用降维方法脑图](http://img.blog.csdn.net/20150522194801297)
 - t-SNE是深度学习大牛Hinton和lvdmaaten（他的弟子？）在2008年提出的，lvdmaaten对t-SNE有个主页介绍：[tsne](http://lvdmaaten.github.io/tsne/),包括论文以及各种编程语言的实现,t-SNE是非线性方法，非常适用于高维数据降维到2维或者3维，进行可视化,具体参考[t-SNE原理及python实现](http://blog.csdn.net/jyl1999xxxx/article/details/53138975)
 - 其他方法参考[流形学习](http://blog.csdn.net/zhulingchen/article/details/2123129),[MNIST数据集降维可视化效果展示(经典)](http://colah.github.io/posts/2014-10-Visualizing-MNIST/)
### 深度学习
- 深度学习书籍：[Deep Learning中文版](https://exacity.github.io/deeplearningbook-chinese/),[英文版](http://www.deeplearningbook.org/front_matter.pdf),[Andrej Karpathy博客](http://karpathy.github.io/neuralnets/),[Colah's Blog](http://colah.github.io/),[Neural Networks, Manifolds, and Topology](http://colah.github.io/posts/2014-03-NN-Manifolds-Topology/),[Understanding LSTM Networks](http://colah.github.io/posts/2015-08-Understanding-LSTMs/)
- [一文读懂深度学习](http://www.36dsj.com/archives/20382)，[深度学习为何要深?](https://zhuanlan.zhihu.com/p/22888385),[超智能体gitbook](https://www.gitbook.com/book/yjango/superorganism/details),[台大李宏毅：一天搞懂深度学习](http://v.youku.com/v_show/id_XMTY5NDUzNjIxNg==.html?from=s1.8-1-1.2&spm=0.0.0.0.LZsB12%EF%BC%8C%E4%B8%80%E5%A4%A9%E6%90%9E%E6%87%82%E6%B7%B1%E5%BA%A6%E5%AD%B8%E7%BF%92--%E5%AD%B8%E7%BF%92%E5%BF%83%E5%BE%97)
- [上海复旦大学吴立德教授的《深度学习课程》](http://list.youku.com/albumlist/show?id=21508721&ascending=1&page=1),[张俊林：深度学习在搜索推荐领域的应用](http://blog.csdn.net/malefactor/article/details/52040228#0-tsina-1-63822-397232819ff9a47a7b7e80a40613cfe1)
- [深度学习](http://my.tv.sohu.com/pl/9161916/84849655.shtml)，[从神经元到深度学习](http://www.36dsj.com/archives/39775)
- 深度学习书籍：[Deep Learning中文版](https://exacity.github.io/deeplearningbook-chinese/),[英文版](http://www.deeplearningbook.org/front_matter.pdf),[Andrej Karpathy博客](http://karpathy.github.io/neuralnets/),[Colah's Blog](http://colah.github.io/),[Neural Networks, Manifolds, and Topology](http://colah.github.io/posts/2014-03-NN-Manifolds-Topology/),[Understanding LSTM Networks](http://colah.github.io/posts/2015-08-Understanding-LSTMs/)[一文读懂深度学习](http://www.36dsj.com/archives/20382)，[深度学习为何要深?](https://zhuanlan.zhihu.com/p/22888385),[超智能体gitbook](https://www.gitbook.com/book/yjango/superorganism/details),[台大李宏毅：一天搞懂深度学习](http://v.youku.com/v_show/id_XMTY5NDUzNjIxNg==.html?from=s1.8-1-1.2&spm=0.0.0.0.LZsB12%EF%BC%8C%E4%B8%80%E5%A4%A9%E6%90%9E%E6%87%82%E6%B7%B1%E5%BA%A6%E5%AD%B8%E7%BF%92--%E5%AD%B8%E7%BF%92%E5%BF%83%E5%BE%97)，[上海复旦大学吴立德教授的《深度学习课程》](http://list.youku.com/albumlist/show?id=21508721&ascending=1&page=1),[张俊林：深度学习在搜索推荐领域的应用](http://blog.csdn.net/malefactor/article/details/52040228#0-tsina-1-63822-397232819ff9a47a7b7e80a40613cfe1)
- [寒小阳：深度学习视频](http://my.tv.sohu.com/pl/9161916/84849655.shtml)

### 知识图谱
- [精益知识图谱方法论](http://blog.memect.cn/?p=2005)，文因互联鲍捷组件的[北京知识图谱学习班](https://github.com/memect/kg-beijing),[知识管理和语义搜索的哲学思考](http://blog.memect.cn/?p=3022),更多资料参考[将门创业历届活动嘉宾视频及ppt](https://mp.weixin.qq.com/s?__biz=MzAxMzc2NDAxOQ==&mid=502876225&idx=1&sn=25894a894cc2c58214ddde13e0a8ef93&chksm=03907c9d34e7f58b57b068d0e7e74ac3db935a131cc7955478b58a98b9bc5c2b239c8ee03129&mpshare=1&scene=23&srcid=1201jRGgplUzlGGggjBesJuI#rd)
### 数据挖掘
- [谁说菜鸟不会数据分析【脑图笔记】](http://www.cnblogs.com/xiaofeng1234/p/5997018.html?from=timeline)
- [SQL必知必会【脑图笔记】](http://www.cnblogs.com/xiaofeng1234/p/6024479.html)
- 经验总结：[以什么姿势进入DataMining会少走弯路？](http://weibo.com/ttarticle/p/show?id=2309403973170330790744)
## IT资讯
- 查公司信息：[天眼查](http://www.tianyancha.com/),[IT桔子](https://www.itjuzi.com/)
- [互联网黑名单](https://github.com/shengxinjing/programmer-job-blacklist)
- 股权信息：[股权周刊](https://zhuanlan.zhihu.com/guquanzhoukan)(各种股权纠纷案例,作者[邓永权](https://www.zhihu.com/people/guquanzhoukan/answers))。[【干货】创业公司融资时如何分配股权？融资后一般怎么稀释？](http://bbs.pinggu.org/thread-4526409-1-1.html)
- [程序员跳槽全攻略-读书笔记](http://www.cnblogs.com/coderland/p/5903051.html)
![图](http://images2015.cnblogs.com/blog/1025005/201609/1025005-20160924130454027-1184504966.png)
## 工具
- 视频下载工具：[硕鼠](http://tv.cntv.cn/video/C10435/9d677bac906247de9782b1104a70110e)(可以下载流视频),[维棠](http://www.vidown.cn/)
## 编程语言
- python：[python小白笔记](http://www.cnblogs.com/xiaofeng1234/p/6052051.html)
## 新技术
- [区块链](http://t.cn/R6HR9ji)：分布式总账技术，所有节点都记录账本，更安全
- 寒小阳：计算广告小窥【[上](http://blog.csdn.net/han_xiaoyang/article/details/50580423),[中](http://blog.csdn.net/han_xiaoyang/article/details/50697074),[下](http://blog.csdn.net/han_xiaoyang/article/details/52275318)】
## 产品
- [APP技术框架](http://www.woshipm.com/pmd/240656.html),[产品必懂的web建站技术](http://www.woshipm.com/pmd/155064.html)
- [产品经理面试指南](http://www.woshipm.com/topic/ms)
- [【麦子学院】产品经理从零到无穷【脑图笔记】](http://www.cnblogs.com/xiaofeng1234/p/6116209.html)

## 经济学
- [银行和货币系统真相视频](http://v.youku.com/v_show/id_XNzIxMDQyODAw.html?spm=a2h0j.8191423.module_basic_relation.5~5!2~5~5!3~5~5~A),[出品方goldsilver](https://goldsilver.com/hidden-secrets/)
## 其他
