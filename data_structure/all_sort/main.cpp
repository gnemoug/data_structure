#include<iostream>
#include<stdio.h>
using namespace std;

void print(int data[],int s, int n)
{
    for(int i = s; i < n; i++)
    {
        printf("%d ",data[i]);
    }

    cout<<endl;
}

void bubbleSort(int data[], int n)
{


    for(int i=0; i<n-1; i++)
        for( int j = n-1; j >= i; j--)
        {
            if( data[j] > data[j+1] )
            {
                data[j] = data[j] ^ data[j+1];
                data[j+1] = data[j] ^ data[j+1];
                data[j] = data[j] ^ data[j+1];
            }
        }
}
void insertSort(int data[], int n)
{

    for(int i=1; i<n; i++)
    {
        int temp = data[i];
        int j ;
        for( j = i-1; temp < data[j]  && j>=0  ; j--)
             data[j+1] = data[j] ;
        data[j+1] = temp;
    }

}

void selectSort(int data[], int n)
{
    for(int i=0; i<n-1; i++)
    {
        int min = i;
        for( int j = i+1;  j<n  ; j++)
            if( data[min] > data[j])
                min = j;
         if(min != i)
         {
            data[i] = data[i] ^ data[min];
            data[min] = data[i] ^ data[min];
            data[i] = data[i] ^ data[min];
         }

    }
}

void merge(int data[],int s,int mid,int e)
{
    int n1= mid - s +1;
    int n2 = e - mid ;

    int t1[n1] ;
    int t2[n2] ;

    for( int i = 0; i< n1; i++)
    {
        t1[i] = data[s+i];

    }
    for( int i = 0; i< n2 ; i++)
    {
        t2[i] = data[mid + 1 +i];

    }

    int i =0,j =0,z=s;

    while(i < n1 && j < n2)
    {
        if(t1[i] <= t2[j])
        {
            data[z++] = t1[i++];
        }
        else
        {
            data[z++] = t2[j++];
        }

    }

    while(i < n1 )
         data[z++] = t1[i++];

    while(j < n2 )
         data[z++] = t2[j++];


}

void mergeSort(int data[], int s, int e)
{
    if(s < e)
    {

        int mid = s + (e - s)/2;

        mergeSort(data,s,mid);
        mergeSort(data,mid+1,e);
        merge(data,s,mid,e);
    }

}

int partion(int data[], int s, int e)
{
    int start =s;
    int end = e;

    int temp = data[s];
    while( start < end)
    {
        while(start < end && data[end] > temp) end--;

        if(start < end)
        {
            data[start++] = data[end];
        }

        while(start < end && data[start] < temp) start++;

        if(start < end)
        {
            data[end--] = data[start];
        }
    }

    data[start] = temp;
    return start;
}

void quickSort(int data[], int s, int e)
{
    if( s < e)
    {
        int temp = partion(data,s,e);
        quickSort(data,s,temp-1);
        quickSort(data, temp+1, e);
    }
}



void heapMax(int data[],int index, int n)
{
    int max_index;
    for( int i = index; i*2+1 < n; )
    {
        if( i*2 +2 < n  )
            max_index = data[i*2+1] >data[i*2+2] ? i*2+1: i*2+2;
        if( data[i] < data[max_index])
        {
            data[i] = data[i] ^ data[max_index];
            data[max_index] = data[i] ^ data[max_index];
            data[i] = data[i] ^ data[max_index];
            i = max_index;
        }
        else
            break;
    }
}

void buildHeap(int data[],int n)
{
    for( int i = (n-2)/2; i >=0; i--)
    {
        heapMax(data, i, n);
    }

}

void heapSort(int data[],int n)
{
    buildHeap(data,n);

    for(int i = n-1; i >0; i--)
    {
        data[i] = data[i] ^ data[0];
        data[0] = data[i] ^ data[0];
        data[i] = data[i] ^ data[0];
        heapMax(data, 0, i);
    }
}



int main()
{
    int data[7] = {10,9,8,7,6,5,4};

    //bubbleSort(data,7);
    //insertSort(data,7);
    //selectSort(data,7);
    //mergeSort(data,0,6);
    //quickSort(data,0,6);
    heapSort(data,7);
    print(data,0,7);
    return 0;

}
