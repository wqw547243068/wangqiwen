#!/usr/bin/env python
# -*- coding:utf-8 _*_

import os
import sys
import time
import json
import re
import urllib
import urllib2

reload(sys)
sys.setdefaultencoding( "utf-8" )

def json2mapstr(json_dict,seg2='\002',seg3='\003'):
    ''' ½«json×ª³ÉhiveµÄmapÀà±ð  '''
    out_str = ''
    for k,v in json_dict.items():
        out_str += k + seg3 + str(v) + seg2
    out_str = out_str.rstrip(seg2)
    return out_str

def str2map(line, sep_re1='+', sep_re2='='):
    res = {}
    try:
        parts = re.split(sep_re1, line)
        for p in parts:
            kv = re.split(sep_re2, p, 1)  # two parts
            if len(kv) != 2:
                continue
            res[kv[0]] = kv[1]
    except Exception, e:
        print >>sys.stderr, "err: (err=%s) (line=%s)"%(e, line)
    return res

def extract_info(str,seg_item='+',seg_kv=':'):
    tmp_dict = {}
    for item in str.split(seg_item):
        item_arr = item.split(seg_kv,1)
        if len(item_arr) != 2:
            continue
        if item_arr[1] == '':
            item_arr[1] = '-'
        tmp_dict[item_arr[0]] = item_arr[1]
    return tmp_dict


def main( input = sys.stdin , output = sys.stdout ):

    # input: diu    date    time    path    para
    # output: uid   time    position  source action request response other; partition: dt
    # 359188049115769   2014-01-07  00:00:00    /ASS    t=traf
    out_list = ['uid','sessionid','stepid','time','position','source','action','request','response','cellphone','other']
    format_str = ('date','time','para')
    pattern_apache = re.compile(r"^(\d{4}\-\d{2}\-\d{2})\s+(\d{2}\:\d{2}\:\d{2})\s+INFO\s+access\s+:\s+\d+\s+\d+\s+\d+\s+[\w\.\:]+\s+\/bin\/movie\?(.*)$",re.I)
    pattern_uid = re.compile(r'^[\w-]+$',re.I)
    sep1,sep2 = '\002','\003'  # hive default sep between kv pairs
    para_dict = {'uid':'diu','sessionid':'session','stepid':'stepid','position':['user_loc','geoobj','city','citycode','adcode'],'cellphone':['div','device','manufacture'],'other':['diu2','diu3','datatype','tid']}
    position_key = ('user_loc','geoobj','city','citycode','adcode', 'result_city')
    in_dict = {}
    for line in input:
        try:
            line = line.replace("%0A","").replace("%0D","")  #remove %0D %0A
            p = pattern_apache.match(line)
            if not p:
                continue
            out_dict = {}
            in_dict = dict(zip(format_str,p.groups()))
            out_dict['time'] = in_dict['time']
            in_dict['para'] = urllib.unquote(in_dict['para'])
            tmp_para = extract_info(in_dict['para'],'&','=')
            # 保留tid
            #if "tid" in tmp_para:
                #del tmp_para["tid"]
                #del tmp_para["cifa"]
            for k in tmp_para:
                tmp_para[k] = tmp_para[k].strip()
            if 'diu' not in tmp_para or not pattern_uid.match(tmp_para['diu']) or tmp_para['diu'] == "-":
                # diu missed  [2014-3-17]
                print >>sys.stderr,'diu missed ! (%s)'%(repr(tmp_para))
                continue
            for k in para_dict:
                v = para_dict[k]
                if k == 'uid' and ( v not in tmp_para or tmp_para[v] == ''):
                    print >>sys.stderr,'diu  missed !aaaaaaaaaaaaaaaaaaaa! (%s)'%(repr(tmp_para))
                    continue
                if type(v) == type('str'):
                    if v not in tmp_para:
                        out_dict[k] = '-'
                        if v == "stepid" and ("step" in tmp_para):
                            out_dict[k] = tmp_para["step"]
                    else:
                        out_dict[k] = tmp_para[v]
                elif type(v) == type([]):
                    out_dict[k] = {}
                    for i in v:
                        if i in tmp_para:
                            if i == "city":
                                out_dict[k]["citycode"] = tmp_para[i]
                            else:
                                out_dict[k][i] = tmp_para[i]
                else:
                    print >>sys.stderr,'Illegal key(%s) found !'%(k)
                    continue
            if "custom" in tmp_para:
                tmp_para['custom'] = urllib2.unquote(tmp_para['custom']).decode("gbk")
                custom = extract_info(tmp_para['custom'], '+', '=')
                if custom:
                    tmp_para = dict(tmp_para,**custom)
                del tmp_para['custom']
            #keywords编码问题
            if "keywords" in tmp_para:
                try:
                    tmp_para["keywords"] = urllib.unquote(tmp_para["keywords"]).decode("gbk")
                except:pass

        #cellphone
        #print tmp_para["cifa"]
            if "cifa" in tmp_para:
                cifa = tmp_para["cifa"]
                tmp_cifa = cifa.split(";")
                for item in tmp_cifa:
                    tmp_item = item.split("=")
                    if len(tmp_item) == 2:
                        if tmp_item[1] == "":
                            tmp_item[1] = "-"
                        if tmp_item[0] == "manufacture" :
                            out_dict["cellphone"]["manufacture"] = tmp_item[1]
                        elif tmp_item[0] == "device" :
                            out_dict["cellphone"]["device"] = tmp_item[1]
                        elif tmp_item[0] == "model" :
                            out_dict["cellphone"]["model"] = tmp_item[1]
            else:
                out_dict["cellphone"]["manufacture"] = "-"
                out_dict["cellphone"]["device"] = "-"
                out_dict["cellphone"]["model"] = "-"


        #para = str2map(content_array[4], r"&", r"=+")
        # position: user_loc, x, y, longitude,lon, latitude,lat,geoobj, fromX, fromY, toX, toY,
            out_dict['position'] = {}
            (x, y) = ("-", "-")
            if tmp_para.has_key('x') and tmp_para.has_key('y'):
                (x, y) = (tmp_para['x'], tmp_para['y'])
            elif tmp_para.has_key('longitude') and tmp_para.has_key('latitude'):
                (x, y) = (tmp_para['longitude'], tmp_para['latitude'])
            elif tmp_para.has_key('lon') and tmp_para.has_key('lat'):
                (x, y) = (tmp_para['lon'], tmp_para['lat'])
            elif tmp_para.has_key('result_x') and tmp_para.has_key('result_y'):
                (x, y) = (tmp_para['result_x'], tmp_para['result_y'])

            if x != "-" and y != "-":
                out_dict['position']['x'] = x
                out_dict['position']['y'] = y
            for k in position_key:
                if not tmp_para.has_key(k):
                    continue
                if k == "city" :
                    out_dict['position']["citycode"] = tmp_para[k]
                elif k == "result_city":
                    out_dict['position']["citycode"] = tmp_para[k]
                else:
                    out_dict['position'][k] = tmp_para[k]
            if out_dict['position'] == {}:
                out_dict['position'] = {"-":"-"}
            out_dict['source'] = "SPMOVIE" # source
            out_dict['action'] = tmp_para['query_type'] # action,È¥µôÓÒ²à/
            if out_dict['action'] == "/ASS" and "t" in tmp_para:
                out_dict['action']  = "/ASS" +"?t="+tmp_para["t"]
            out_dict['request'] = tmp_para # request
            out_dict['response'] = {"-":"-"} # response,aos²»¼ÇÂ¼·µ»ØÐÅÏ¢
            #out_dict['other'] = {} # info
            #if tmp_para.has_key('diu2'):
             #   out_dict['other']['diu2'] = tmp_para['diu2']
            #if tmp_para.has_key('diu3'):
             #   out_dict['other']['diu3'] = tmp_para['diu3']
            if out_dict['other'] ==   {} :
                out_dict['other'] = {"-":"-"}

        #if out_dict['action'] == '/ASS':
        #    continue
        # pack result:
            out_str = ''
            all_str = ''
            for i in range(0,len(out_list)):
                if out_list[i] not in out_dict:
                    v ="-"
                #print >>output,'key(%s) not in out_dict!'%(i)
                #continue
                else:
                    v = out_dict[out_list[i]]
                if type(v) == type({}):
                    for key in v:

                        item = key + sep2 + v[key]
                        all_str += item + sep1
                    all_str = all_str.strip(sep1)
                    out_str += all_str + "\t"
                    all_str = ""

                else:
                    out_str +=  v + "\t"
            out_str = out_str.strip('\t')
            arr = out_str.split('\t')
            if arr[0] == "" or not pattern_uid.match(arr[0]):
                continue
            print >>output,out_str
        except Exception, e:
            print >>sys.stderr, "err: (err=%s) (line=%s)"%(e, line)

if __name__ == '__main__':
    #input = file('./log_sptuan_raw')
    #output = open('test','w+')
    #main(input,output)
    main()

