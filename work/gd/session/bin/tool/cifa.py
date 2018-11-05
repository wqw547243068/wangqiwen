# -*- coding: utf-8  -*-
#!/usr/local/bin/python

import struct
import StringIO


def unicode2utf8(_value):
    if isinstance(_value, unicode):
        _value = _value.encode("utf-8")
    if not isinstance(_value, basestring):
        _value = str(_value)
    return _value


def parse_cifa(_cifa):
    param_dict = {}
    _stream = StringIO.StringIO()
    try:
        for i in range(0, len(_cifa)/2):
            _str = _cifa[2*i: 2*i+2]
            _tmp = int(_str, 16)
            _stream.write(struct.pack('B', _tmp))
            
        _stream.seek(0)
        width, = struct.unpack('h', _stream.read(2))
        param_dict['width'] = width
        height, = struct.unpack('h', _stream.read(2))
        param_dict['height'] = height
        lon, = struct.unpack('i', _stream.read(4))
        param_dict['lon'] = lon
        lat, = struct.unpack('i', _stream.read(4))
        param_dict['lat'] = lat
        ant, = struct.unpack('b', _stream.read(1))
        param_dict['ant'] = ant
        nt, = struct.unpack('b', _stream.read(1))
        param_dict['nt'] = nt
        pt, = struct.unpack('b', _stream.read(1))
        param_dict['pt'] = pt
        mcc, = struct.unpack('h', _stream.read(2))
        param_dict['mcc'] =mcc 
        mnc, = struct.unpack('h', _stream.read(2))
        param_dict['mnc'] = mnc
        lac, = struct.unpack('i', _stream.read(4))
        param_dict['lac'] = lac
        cid, = struct.unpack('i', _stream.read(4))
        param_dict['cid'] = cid
        sid, = struct.unpack('i', _stream.read(4))
        param_dict['sid'] = sid
        nid, = struct.unpack('i', _stream.read(4))
        param_dict['nid'] = nid
        bid, = struct.unpack('i', _stream.read(4))
        param_dict['bid'] = bid
        strength, = struct.unpack('i', _stream.read(4))
        param_dict['strength'] = strength
        SDKVersion, = struct.unpack('h', _stream.read(2))
        param_dict['SDKVersion'] = SDKVersion
        
        l, = struct.unpack('h', _stream.read(2))
        wifimac, = struct.unpack('%ss'%l, _stream.read(l))
        param_dict['wifimac'] = unicode2utf8(wifimac)
        
        l, = struct.unpack('h', _stream.read(2))
        model, = struct.unpack('%ss'%l, _stream.read(l))
        param_dict['model'] = unicode2utf8(model)
        
        l, = struct.unpack('h', _stream.read(2))
        device, = struct.unpack('%ss'%l, _stream.read(l))
        param_dict['device'] = unicode2utf8(device)
        
        l, = struct.unpack('h', _stream.read(2))
        manufacture, = struct.unpack('%ss'%l, _stream.read(l))
        param_dict['manufacture'] = unicode2utf8(manufacture)
        
        l, = struct.unpack('h', _stream.read(2))
        amapVersion, = struct.unpack('%ss'%l, _stream.read(l))
        param_dict['amapVersion'] = unicode2utf8(amapVersion)
        
        entryTime, = struct.unpack('i', _stream.read(4))
        param_dict['entryTime'] = entryTime
        exitTime, = struct.unpack('i', _stream.read(4))
        param_dict['exitTime'] = exitTime
        
        _glrender = _stream.read(2)
        if len(_glrender)==2:
            l, = struct.unpack('h', _glrender)
            glrender, = struct.unpack('%ss'%l, _stream.read(l))
            param_dict['glrender'] = unicode2utf8(glrender)
        
        _accuracy = _stream.read(2)
        if _accuracy and len(_accuracy)==2:
            accuracy, = struct.unpack('h', _accuracy)
            param_dict['accuracy'] = accuracy
        
    except Exception, e:
        pass
    finally:
        if _stream and not _stream.closed:
            _stream.close()
    
    return param_dict

