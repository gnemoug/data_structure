#include<stdio.h>
#define max 10

int num[max+1],m,n,lenth;
int used[max+1];

void Exchange(int *a,int *b)//交换数组元素
{
    int temp=*a;
        *a=*b;
        *b=temp;
}

void Max_HEAPIFY(int *a,int i)//保持堆性
{
    int l=i*2,r=i*2+1,large;
    if(l<=lenth&&a[l]>a[i])
        large=l;
    else
        large=i;
    if(r<=lenth&&a[large]<a[r])
    {
        large=r;
    }
    if(large!=i)
    {
        Exchange(&a[i],&a[large]);
        Max_HEAPIFY(a,large); 
    }
}

void BUILD_MAX_HEAP(int *a)//建堆
{
  int i;
  for(i=lenth/2;i>=1;i--)
  {
      Max_HEAPIFY(a,i);
  }
}

void HEAPSORT(int *a)//堆排序
{
   int i;
   BUILD_MAX_HEAP(a);
   for(i=max;i>=2;i--)
   {
       Exchange(&a[1],&a[lenth]);       //将最大元素放到结尾
       lenth=lenth-1;
       Max_HEAPIFY(a,1);
   }
}

int main()
{
    int i,j;
    freopen("in.txt","r",stdin);//用数组长为10的做了下测试,重定向为了方便进行测试，可以像输入一样处理文件内容
    for(i=1;i<=max;i++)
    {
        scanf("%d",&num[i]);
    }

    lenth=max;
    HEAPSORT(num);
    for(i=1;i<=max;i++)
        printf("%d ",num[i]);
    
    return 0;
}
