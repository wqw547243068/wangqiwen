import sys
import os
import MySQLdb
reload(sys) 
sys.setdefaultencoding('utf-8')
import re

from optparse import OptionParser 

if __name__ == '__main__':
    usage = "usage: python load2MySQL.py -n num -t table_name [-d cube] [-f data_file] [-a]"
    parser = OptionParser(usage=usage) 
    #parser.add_option("-p", "--path", dest = "path", default = '../../../conf', help = "the path of data file")
    parser.add_option("-f", "--file", dest = "data_file", default = './data.txt', help = "the path of data file")
    parser.add_option("-d", "--database", dest = "database", default = 'cube', help = "database name")
    parser.add_option("-t", "--table", dest = "table", default = '-', help = "table name")
    parser.add_option("-n", "--num", type = "int", dest = "num", default = 0, help = "the num of table format segments")
    parser.add_option("-a", "--all", action = "store_true", dest = "all", default = True, help = "load all or one by one")
    (options, args) = parser.parse_args() 
    print '-'*30 + 'all input arguments' + '-'*30
    print options
    if options.num == 0:
        print 'please input num !\n\t%s'%(usage)
        sys.exit(-1)
    #if options.database == '-':
    #    print 'please input database name !\n\t%s'%(usage)
    #    sys.exit(-1)
    if options.table == '-':
        print 'please input table name !\n\t%s'%(usage)
        sys.exit(-1)
    #if options.data_file == '-':
    #    print 'please input data file !\n\t%s'%(usage)
    #    sys.exit(-1)
    pattern_citycode = re.compile(r"^\d{3,6}$",re.I)
    pattern_div = re.compile(r"^\w{4}\d{6}",re.I)
    #sys.path.append(path)
    #import vars
    
    # MySQL conneciton info
    #host='127.0.0.1'
    host='10.17.129.55'
    user='root'
    passwd='root'
    port=3306
    database='cube'

    print 'start to load data into MySQL'
    try:
        print '-'*30 + 'connect to MySQL' + '-'*30
        conn = MySQLdb.connect( host = host , user = user , passwd = passwd , port = port , charset='utf8' )
        print '\thost=%s,user=%s,passwd=%s,port=%s'%(host,user,passwd,port)
        cur = conn.cursor()
        #for i in cur.fetchall():
        #   print str(i[0])+'\t'+i[1]+'\t'+i[2]
        conn.select_db(options.database)
        #cur.execute('create table test(id int,info varchar(20))')
        if options.all:
            print '-'*30 + 'load all at a time' + '-'*30
            cmd = 'load data local infile \'%s\' into table %s' %( options.data_file , options.table )
            #cmd = 'delete from sug_click_stat where date='20140909';' 
            print 'command :\n\t%s'%( cmd )
            out = cur.execute( cmd )
        else:
            print '-'*30 + 'process data ...' + '-'*30
            value_list = []
            for line in file(options.data_file):
                arr = [i.strip() for i in line.strip().split('\t')]
                if len(arr) != options.num:
                    print >>sys.stderr,'length error!(%s)'%(line)
                    continue
                #if not pattern_citycode.match(arr[0]) or not pattern_div.match(arr[-2]):
                #   continue
                if not pattern_div.match(arr[2]) and arr[2] != '-':
                    continue
                # div ajust
                arr[2] = arr[2][0:10]
                value_list.append(arr)
            print '-'*30 + 'load one by one' + '-'*30
            format_str = ','.join(['%s' for i in xrange(options.num)])
            cmd = 'insert into ' + options.table +' values( ' + format_str + ' )'
            print 'command:\n\t' + cmd
            cur.executemany( cmd , value_list )
            #cur.executemany('insert into %s values(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)',%( table , value_list ) )
        conn.commit()
        cur.close()
        conn.close()
        print '='*30 + 'finish' + '='*30
    except MySQLdb.Error,e:
        print "Mysql Error %d: %s" % (e.args[0], e.args[1])
