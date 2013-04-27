#include <stdio.h>
#define max 100   //数组最大长度
#define maxnum 200//定义最大的元素的值为200

int result[max],num[max],count[maxnum+1],lenth;//结果数组,要排序的数组,临时数组,要排序的数组大小

void COUNTING_SORT()
{
    int i;
    for(i=0;i<=maxnum;i++)
        count[i]=0;
    for(i=1;i<=lenth;i++)           //记录每一个元素小于本身的个数
        count[num[i]]=count[num[i]]+1;
    for(i=1;i<=maxnum;i++)
        count[i]=count[i]+count[i-1];

    for(i=lenth;i>=1;i--)
    {
        result[count[num[i]]]=num[i];
        count[num[i]]=count[num[i]]-1;
    }
}

int main()
{
    int i;
    freopen("in.txt","r",stdin);    //重定向读文件
    scanf("%d",&lenth);
    for(i=1;i<=lenth;i++)
    {
        scanf("%d",&num[i]);
    }
    COUNTING_SORT();
    for(i=1;i<=lenth;i++)
        printf(" %d",result[i]);

    return 0;
}
