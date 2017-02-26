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
