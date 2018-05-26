#!/usr/bin/python2.7
# coding=utf-8
#参考<python使用mysql数据库>http://www.cnblogs.com/fnng/p/3565912.html
'''
#mysql初始化-shell
mysql=/usr/local/mysql/bin/mysql
$mysql -uroot -pwqw  < init.sql
------
$mysql -uroot -p123456 <<EOF  
source /root/temp.sql;  
select current_date();  
delete from tempdb.tb_tmp where id=3;  
select * from tempdb.tb_tmp where id=2;  
EOF 
'''

import MySQLdb
import sys
 
host = 'localhost'
user = 'root'
pwd  = 'wqw'   # to be modified.
db   = 'demo'
 
 
if __name__ == '__main__':
    #这只是连接到了数据库，要想操作数据库需要创建游标
    conn = MySQLdb.connect(host, user, pwd, db, charset='utf8');
    try:
        conn.ping()
    except:
        print 'failed to connect MySQL.'
    #创建游标
    cur = conn.cursor()
    print '进入指定数据库'
    out = cur.execute('show tables')
    print cur.fetchmany(out)
    print '连接数据库后直接查已有表'
    #out = cur.execute("select * from student")
    #print cur.fetchmany(out)
    #通过游标cur 操作execute()方法可以写入纯sql语句
    #删除已有表
    cur.execute('drop table student')
    #创建数据表
    print '创建表'
    out = cur.execute("create table if not exists student(id int ,name varchar(20),class varchar(30),age varchar(10),primary key (id))")
    print cur.fetchmany(out)
    #插入一条数据
    cur.execute("insert into student values(1,'Tom','3 year 2 class','9')")
    print '插入一条数据后再查'
    out = cur.execute("select * from student")
    print cur.fetchmany(out)
    #插入数据-变量
    sqli="insert into student values(%s,%s,%s,%s)"
    cur.execute(sqli,(2,'Huhu','2 year 1 class','7'))
    cur.execute("select * from student")
    #插入数据-批量
    sqli="insert into student values(%s,%s,%s,%s)"
    cur.executemany(sqli,[
        (3,'Tom','1 year 1 class','6'),
        (4,'Jack','2 year 1 class','7'),
        (5,'Yaheng','2 year 2 class','7')
        ])
    print '批量插入后再查'
    cur.execute("select * from student")
    #修改查询条件的数据
    cur.execute("update student set class='3 year 1 class' where name = 'Tom'")
    #删除查询条件的数据
    cur.execute("delete from student where age='9'")
    #查询数据
    sql = "select * from student where id = 2"
    out = cur.execute(sql)
    #获取结果数据-一条一条
    row = cur.fetchone()
    print '结果：',row
    for i in row:
        print i
    #获取结果数据-批量
    #打印表中的多少数据
    info = cur.fetchmany(out)
    for ii in info:
        print ii
    #关闭游标
    cur.close()
    #提交事物，在向数据库插入一条数据时必须要有这个方法，否则数据不会被真正的插入。
    conn.commit()
    #关闭连接
    conn.close()
    sys.exit()
# */* vim: set expandtab ts=4 sw=4 sts=4 tw=400: */
