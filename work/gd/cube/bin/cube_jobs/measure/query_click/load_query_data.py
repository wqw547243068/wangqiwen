import sys
import os
import MySQLdb
reload(sys) 
sys.setdefaultencoding('utf-8')
import re

pattern_citycode = re.compile(r"^\d{3,6}$",re.I)
pattern_div = re.compile(r"^\w{4}\d{6}",re.I)
#if __name__ == '__main__':
if len(sys.argv) < 1:
    data_file = 'query.txt'
    path = '../../../conf'
else:
    data_file = sys.argv[1]
    path = os.path.dirname(sys.argv[0]) + '/../../../conf'

print path
sys.path.append(path)
import vars
    
value_list = []
for line in file(data_file):
    # [date citycode div pv uv geo_num no_res_num click_num valid_click_num page_turn_num general_num query_num]
    arr = [i.strip() for i in line.strip().split('\t')]
    if len(arr) != 12:
        print >>sys.stderr,'length error!(%s)'%(line)
        continue
    #if not pattern_citycode.match(arr[0]) or not pattern_div.match(arr[-2]):
    #    continue
    if not pattern_div.match(arr[2]) and arr[2] != '-':
        continue
    arr[2] = arr[2][0:10]
    value_list.append(arr)


try:
    conn=MySQLdb.connect(host=vars.host,user=vars.user,passwd=vars.passwd,port=vars.port,charset='utf8')
    #conn=MySQLdb.connect(host='127.0.0.1',user='root',passwd='root',port=3306,charset='utf8')
    cur=conn.cursor()
    #for i in cur.fetchall():
    #    print str(i[0])+'\t'+i[1]+'\t'+i[2]
    conn.select_db(vars.database)
    #out=cur.execute('show tables')
    #cur.execute('create table test(id int,info varchar(20))')
    values = []
    cur.executemany('insert into query_data values(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)',value_list)
    conn.commit()
    cur.close()
    conn.close()
    print '-'*20+'end'+'-'*20
except MySQLdb.Error,e:
    print "Mysql Error %d: %s" % (e.args[0], e.args[1])
