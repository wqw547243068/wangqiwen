#/usr/bin/env python 
# -*- encoding:utf8 -*-

import sys
import json
import os

reload(sys)
sys.setdefaultencoding( "utf-8" )

if __name__ == '__main__':
    pb_dict = {}
    for f in os.listdir('.'):
        if not f.endswith('txt'):
            continue
        version = f.strip('.txt')
        tmp_pb_dict = {}
        for line in file(f):
            # [page_id=v1  button_id=v2   explain [para] ]
            arr = [i.strip() for i in line.strip().split('\t')]
            para = '-'
            length = len(arr)
            if length < 3:
                continue
            elif length > 3:
                # 参数取值示例
                para = arr[3]
            p_id = arr[0].split('=')[-1]
            b_id = arr[1].split('=')[-1]
            tmp_b_dict = {b_id:{'explain':arr[2],'para':para}}
            if p_id not in tmp_pb_dict:
                tmp_pb_dict[p_id] = {}
            tmp_pb_dict[p_id].update(tmp_b_dict) 
        pb_dict[version] = tmp_pb_dict
    print json.dumps(pb_dict,ensure_ascii=False,encoding='utf-8',indent=4)
    '''
    for i in ('ios','android'):
        for j in pb_dict[i]:
            print '%s\t%s'%(i,j)
    '''

