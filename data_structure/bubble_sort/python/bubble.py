#!/usr/bin/env python

a = [1,5,2,8,12,3,89,4,12,0]

for i in xrange(10):
    for j in xrange(9 - i): 
        if a[j] > a[j+1]:
            a[j], a[j+1] = a[j+1], a[j]
print a
