import sys
import MySQLdb
reload(sys) 
sys.setdefaultencoding('utf-8')
import re
sys.path.append('../../conf')
import vars

print vars.host
pattern_div = re.compile(r"^\w{4}\d{6}$",re.I)
#if __name__ == '__main__':
div_dict = {}
for line in file('div_all.txt'):
    arr = [i.strip() for i in line.strip().split()]
    if len(arr) != 2:
        print >>sys.stderr,'length error!(%s)'%(line)
        continue
    cur_div = arr[0]
    if not pattern_div.match(cur_div):
        continue
    if cur_div in div_dict:
        continue
    else:
        div_dict[cur_div] = 1

try:
    conn=MySQLdb.connect(host=vars.host,user=vars.user,passwd=vars.passwd,port=vars.port,charset='utf8')
    cur=conn.cursor()
    #out=cur.execute('select * from tmp.tb_time')
    #for i in cur.fetchall():
    #    print str(i[0])+'\t'+i[1]+'\t'+i[2]
    conn.select_db(vars.database)
    #cur.execute('create table test(id int,info varchar(20))')
    values = []
    for i in div_dict:
        os = i[0:3]
        device = i[3]
        version = i[4:]
        values.append((i,os,device,version))
        #sql = 'insert into location_info values(%s,%s,%s,%s,%s,%s)'%(i,v[-1],v[0],v[1],v[2],v[3])
        #cur.execute(sql)
    cur.executemany('insert into div_info values(%s,%s,%s,%s)',values)
    conn.commit()
    cur.close()
    conn.close()
    print 'end'
except MySQLdb.Error,e:
    print "Mysql Error %d: %s" % (e.args[0], e.args[1])
