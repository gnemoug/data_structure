#!/usr/bin/python
#-*- coding:utf-8 -*-

import sys
import heapq
import logging.config
from os.path import isdir
import os

SORT_NUM = 1000  #the data number need to sort
MEMRORY_SIZE = 100   #the data number everyfile can containe

def generate_sorted_tempfile():
    """
        generate sorted tempfile,save them to the data directory
    """
    if not isdir('./data'):
        os.system('mkdir data') 
    
    with open('data.txt') as rf:
        for i in xrange(SORT_NUM/MEMRORY_SIZE):
            templist = []
            for j in xrange(MEMRORY_SIZE):
                templist.append(float(rf.readline().strip()))
            templist.sort()
            with open('./data/data%s.txt'%i,'w') as wf:
                wf.write('\n'.join([str(i) for i in templist]))

def merge_sort():
    """
        file merge sort
    """
    file_list,data_list = [],[]
    for i in xrange(SORT_NUM/MEMRORY_SIZE):
        try:
            rf = open('./data/data%s.txt'%i)
            file_list.append(rf)
        except Exception,e:
            log.error("Error occur in merge_sort()")
    data_list = [(float(j.readline().strip()),i) for i,j in enumerate(file_list)]
    heapq.heapify(data_list)
    
    with open('result.txt','w') as wf:
        while 1:
            try:
                item = heapq.heappop(data_list)
                wf.write(''.join((str(item[0]),'\n')))
            except IndexError:
                break
            new_float = file_list[item[1]].readline().strip()
            if new_float:
                heapq.heappush(data_list,(float(new_float),item[1]))

def main():
    """
        main fuction
    """
    logging.config.fileConfig("logging.conf")
    log = logging.getLogger('MergeSort')
    generate_sorted_tempfile()
    merge_sort()

if __name__ == '__main__':
    sys.exit(main())


