#!/usr/bin/python
#-*-coding:utf8-*-

def bubble_sort(num_list):
    num = len(num_list)
    result_list = []
    for i in range(0,num):
        temp = reduce(lambda x,y:max(x,y),num_list)
        result_list.insert(0,temp)
        num_list.remove(temp)
    return result_list

num_list = [1,5,8,2]
print bubble_sort(num_list)
