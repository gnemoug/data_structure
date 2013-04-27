#!/usr/bin/python
#-*- coding:utf-8 -*-

from random import randint,random

with open('data.txt','w') as f:
    for i in xrange(1000):
        f.write("%s\n"%(randint(1,99999)*random()))
