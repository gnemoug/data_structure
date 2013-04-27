#!/usr/bin/python
#-*-coding:utf8-*-

def qsort(L):
    if len(L) <=1 : return L
    return qsort([lt for lt in L[1:] if lt < L[0]]) + L[0:1] + qsort([ge for ge in L[1:] if ge >= L[0]])

print qsort([5,4,3,222,12,-11])
