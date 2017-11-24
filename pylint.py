#!/usr/bin/env python
# coding:utf8
"""
    test sample. google编码规范：(URL不受80字符限制)
    https://zh-google-styleguide.readthedocs.io/en/latest/google-python-styleguide/python_style_rules/
    2017-11-24
    wangqiwen@didichuxing.com
"""
import sys

class MyClass(object):
    """class测试: 类名满足Pascal风格"""
    public_name = '-public-' # public
    _myname = '-protected' # protected
    __private_name = '-private-' # private
    def __init__(self, name="wang"):
        self._myname = name
        print '我的名字是%s'%(self._myname)
    def say(self):
        """打招呼"""
        print '你好,我是%s,%s,%s'%(self._myname, self.public_name, self.__private_name)
        return 'yes'
    def modify(self, name="-"):
        """更改属性值"""
        self._myname = name

def my_fun(value=0, delta=9):
    """
        外部函数：名字_连接。多参数时,逗号后面加一个空格
    """
    res = value + delta
    return res

if __name__ == '__main__':
    #main里的都是全局变量,需要大写
    A = 3
    NEW = my_fun(A)
    W = MyClass("wqw")
    #不能访问protected、private变量.W._myname, W.__private_name
    #超过80字符时，可以用\换行，注：(),[]时可省略\
    print >> sys.stdout, 'hello,related values are listed as : %s , %s,I am \
        %s,%s ...'%(A, NEW, W.say(), W.public_name)
# */* vim: set expandtab ts=4 sw=4 sts=4 tw=400: */
