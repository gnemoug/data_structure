#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX 256

int get_next(char* p, int* next)
{
    int len = strlen(p);
    int i = 0, k = -1;
    next[0] = -1;//make next[0] to be -1
    while(i<len)
    {
        if(k==-1 || p[i]==p[k])//k=-1 is to make has no match
        {
            i++;
            k++;
            next[i] = k;            //next[i] 每一次0值都是通过K==-1完成
        }else
        {
            k = next[k];
        }
    }
}

int kmp_index(char* s, char* p, int* next, int start)
{
    int i=start,j=0;
    int slen = strlen(s);
    int plen = strlen(p);
    while(i<slen && j<plen)
    {
        if(j==-1 || s[i]==p[j])
        {
            i++;
            j++;
        }else
        {
            j = next[j];
        }
    }
    if(j>=plen)
    {
        return i-plen;
    }else
    {
        return -1;
    }
}

int main()
{
    char* str = "xxabaabcacxxabaabcacdabaabcac99";
    char* pattern = "abaabcac"; //-1 0 0 1 1 2 0 1
    int next[MAX];
    int plen = strlen(pattern);
    int i;
    // Get next value
    get_next(pattern, next);
    for(i=0;i<plen;i++)
    {
        printf("%d ", next[i]);
    }
    printf("\n");
    // KMP Index
    i=0;
    while(i!=-1)
    {
        i = kmp_index(str, pattern, next, i);
        if(i!=-1)
        {
            printf("'%s' @ %dth of '%s'\n", pattern, i, str);
            i++;
        }
    }
    return 0;
}
