#include <stdio.h>
#include <malloc.h>

typedef int KeyType;

typedef struct
{
    KeyType key;
}DataType;

typedef enum
{
    Empty,Active,Deleted
}KindOfItem;

typedef struct
{
    DataType data;
    KindOfItem info;
}HashItem;

typedef struct
{
    HashItem *ht;
    int tableSize;
    int currentSize;
}HashTable;

int Initiate(HashTable *hash,int mSize)
{
    hash->tableSize=mSize;
    hash->ht=(HashItem *)malloc(sizeof(HashItem)*mSize);
    if(hash->ht==NULL)
        return 0;
    else
    {
        hash->currentSize=0;
        return 1;
    }
}

int Find(HashTable *hash,DataType x)
{
    int i=x.key%hash->tableSize;
    int j=i;

    while(hash->ht[j].info==Active && hash->ht[j].data.key!=x.key)
    {
        j=(j+1)%hash->tableSize;
        if(j==i)
            return -hash->tableSize;
    }
    if(hash->ht[j].info==Active)
        return j;
    else 
        return -j;
}

int Insert(HashTable *hash,DataType x)
{
    int i=Find(hash,x);
    if(i>0) 
        return 0;
    else if(i!=-hash->tableSize)
    {
        hash->ht[-i].data=x;
        hash->ht[-i].info=Active;
        hash->currentSize++;
        return 1;
    }
    else 
        return 0;
}

int Delete(HashTable *hash,DataType x)
{
    int i=Find(hash,x);

    if(i>=0)
    {
        hash->ht[i].info=Deleted;
        hash->currentSize--;
        return 1;
    }
    else
        return 0;
}

void Destroy(HashTable *hash)
{
    free(hash->ht);
}

int main(void)
{
    HashTable myHashTable;
    DataType a[]={180,750,600,430,541,900,460},item={430};
    int i,j,k,n=7,m=13;
    /* m is the size of hashlist*/

    Initiate(&myHashTable,m);

    for(i=0;i<n;i++)
        Insert(&myHashTable,a[i]);

    for(i=0;i<n;i++)
    {
        j=Find(&myHashTable,a[i]);
        printf("j=%d  ht[]= %d\n",j,myHashTable.ht[j].data.key);
    }
    
    k=Find(&myHashTable,item);
    
    if(k>0)
        printf("查找成功,元素%d 的地址是 %d\n",item.key,k);
    else 
        printf("查找失败\n");

    Delete(&myHashTable,item);
    k=Find(&myHashTable,item);
    
    if(k>0)
        printf("查找成功,元素%d 的地址是 %d\n",item.key,k);
    else 
        printf("查找失败\n");

    Destroy(&myHashTable);

    return 0;
}
