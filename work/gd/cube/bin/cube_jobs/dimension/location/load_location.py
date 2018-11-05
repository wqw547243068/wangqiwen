import sys
import MySQLdb
import re
reload(sys) 
sys.setdefaultencoding('utf-8')
sys.path.append('../../../conf')
import vars

 
#if __name__ == '__main__':
pattern_city = re.compile(r"^\d{3,6}$",re.I)
city_dict = {}
for line in file('new_city.txt'):
    arr = [i.strip() for i in line.strip().split()]
    if len(arr) != 6:
        print >>sys.stderr,'length error!(%s)'%(line)
        continue
    cur_city = arr[-1]
    if not pattern_city.match(cur_city):
        print >>sys.stderr,'citycode error (%s)!'%(cur_city)
        continue
    if cur_city in city_dict:
        print >>sys.stderr,'citycode repeat (%s)!'%(cur_city)
        continue
    else:
        city_dict[cur_city] = arr[:-1]
#print city_dict

try:
    conn=MySQLdb.connect(host=vars.host,user=vars.user,passwd=vars.passwd,port=vars.port,charset='utf8')
    #conn=MySQLdb.connect(host='127.0.0.1',user='root',passwd='root',port=3306,charset='utf8')
    cur=conn.cursor()
    #out=cur.execute('select * from tmp.tb_time')
    #for i in cur.fetchall():
    #    print str(i[0])+'\t'+i[1]+'\t'+i[2]
    conn.select_db(vars.database)
    #cur.execute('create table test(id int,info varchar(20))')
    values = []
    for i in city_dict:
        v = city_dict[i]
        values.append((i,v[-1],v[0],v[1],v[2],v[3]))
        #sql = 'insert into location_info values(%s,%s,%s,%s,%s,%s)'%(i,v[-1],v[0],v[1],v[2],v[3])
        #cur.execute(sql)
    cur.executemany('insert into location_info values(%s,%s,%s,%s,%s,%s)',values)
    #values=[]
    #for i in range(20):
    #    values.append((i,'hi rollen'+str(i)))
    #cur.executemany('insert into test values(%s,%s)',values)
    #cur.execute('update test set info="I am rollen" where id=3')
    conn.commit()
    cur.close()
    conn.close()
    print 'end'
except MySQLdb.Error,e:
     print "Mysql Error %d: %s" % (e.args[0], e.args[1])
