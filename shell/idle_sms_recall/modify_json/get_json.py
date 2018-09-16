#/usr/bin/env python
# coding:utf8
import sys
import os
import re
import json
import random
import sys
import time

reload(sys)
sys.setdefaultencoding('utf-8')

if __name__ == '__main__':
  #修改sms-service的渠道商配比
  conf_file = '/etc/putong/putong-sms-service/config.json'
  sms_service = json.load(open(conf_file))
  #Sms->(providers)->(domestic|abroad)->(marketing|confirmation)
  sms_provider = sms_service['Sms']['providers']['domestic']['marketing']
  # 'welink':{appKey,name,weight,enabled,baseUrl,appSecret}
  output_format = ['name','weight','enabled','appKey','appSecret','baseUrl']
  ratio_provider = sms_provider.keys()
  print '所有可选渠道商：%s'%(','.join(sms_provider.keys()))
  print '\t'.join(['provider']+output_format)+'\n'+'-'*100
  for k in sms_provider:
      output = [ str(sms_provider[k][i]) for i in output_format]
      output.insert(0,k)
      #print '\t'.join(output)
      if not sms_provider[k]['enabled']:
          continue
          #pass
      print '\t'.join([str(sms_provider[k][i]) for i in ['weight','enabled','name']])
      #print '\t'.join([str(sms_provider[k][i]) for i in ratio_provider])
  print '-'*100
  #print json.dumps(sms_provider,ensure_ascii=False,indent=4)
  if len(sys.argv) < 2:
      print >> sys.stderr,'未传入修改参数,不做修改\n\t传参示例:python get_json.py welink:1,montnets:7'
      sys.exit(0)
  else:
      ratio_str = sys.argv[1]
      print >> sys.stderr,'传入的参数:%s'%(ratio_str)
  #修改配置
  ratio_new = {}
  for item in ratio_str.split(','):
      item_list = item.split(':')
      if len(item_list) != 2:
          print >> sys.stderr,'参数有误，无法解析(%s),跳过'%(item)
          continue
      ratio_new[item_list[0]] = item_list[1]
  #ratio_new = {'dahantc':3,"montnets":4}
  print '解析后的渠道商配置:%s'%(json.dumps(ratio_new))
  for k in sms_service['Sms']['providers']['domestic']['marketing']:
      if k in ratio_new:
          sms_service['Sms']['providers']['domestic']['marketing'][k]['enabled'] =  True
          sms_service['Sms']['providers']['domestic']['marketing'][k]['weight'] =  ratio_new[k]
      else:
          sms_service['Sms']['providers']['domestic']['marketing'][k]['enabled'] =  False
  print '修改后渠道商配比'
  print '-'*100
  sms_provider = sms_service['Sms']['providers']['domestic']['marketing']
  for k in sms_provider:
      output = [ str(sms_provider[k][i]) for i in output_format]
      output.insert(0,k)
      #print '\t'.join(output)
      if not sms_provider[k]['enabled']:
          continue
      print '\t'.join([str(sms_provider[k][i]) for i in ['weight','enabled','name']])
      #print str(sms_provider[k]['weight']),sms_provider[k]['enabled'],sms_provider[k]['name']
  f = open('config.json','w')
  print >> f,json.dumps(sms_service,ensure_ascii=False,indent=4)


# */* vim: set expandtab ts=4 sw=4 sts=4 tw=400: */



