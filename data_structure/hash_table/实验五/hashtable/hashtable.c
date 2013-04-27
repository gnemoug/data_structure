#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>

typedef int KeyType;

typedef struct
{
    KeyType key;
    char value[256];
}DataType;

typedef enum
{
    Empty,Active
}KindOfItem;

typedef struct
{
    DataType *data;
    KindOfItem info;
    int collison;
}HashItem;

typedef struct
{
    HashItem *ht;
    int tableSize;
    int currentSize;
}HashTable;

/*
 * args:
 *      phash:the pointer point to the HashTable
 *      mSize:the size of the HashTable
 * return:
 *      1:success
 *      0:fail
 * doc:init the HashTable
 *
 */
int Initiate(HashTable *phash,int mSize)
{
    phash->tableSize=mSize;
    phash->ht=(HashItem *)malloc(sizeof(HashItem)*mSize);
    if(phash->ht==NULL)
        return 0;
    else
    {
        phash->currentSize=0;
        return 1;
    }
}

/*
 * args:
 *      tableSize:the size of the tableSize
 *      hashkey:the key 
 * return:the hash position
 * doc:get the hash position
 *
 */
int hash(int tableSize,int hashkey)
{
    return hashkey % tableSize;
}

/*
 * args:
 *      phash:the pointer points to the HashTable
 *      x:the DataType to Insert
 * return:the actual position to insert
 * doc:find the actual position to Insert
 *
 */
int FindInsertPosition(HashTable *phash,DataType *x)
{
    int i = hash(phash->tableSize,x->key);
    int j = i;

    while(phash->ht[j].info == Active && phash->ht[j].data->key != x->key)
    {
        j=(j+1)%phash->tableSize;
        if(j==i)
            return -phash->tableSize;
    }
    if(phash->ht[j].info==Active)
        return j;
    else 
        return -j;
}

/*
 * args:
 *      phash:the pointer points to the HashTable
 *      x:the DataType to Insert
 * return:
 *      1:success
 *      0:fail
 * doc:insert data into the HashTable
 *
 */
int Insert(HashTable *phash,DataType *x)
{
    int i = FindInsertPosition(phash,x);
    if(i > 0) 
        return 0;
    else if(i != -phash->tableSize)
    {
        phash->ht[-i].data = x;
        phash->ht[-i].info = Active;
        phash->ht[hash(phash->tableSize,x->key)].collison += 1; 
        phash->currentSize++;
        return 1;
    }
    else 
        return 0;
}

/*
 * args:
 *      phash:the pointer points to the HashTable
 * return:
 * doc:print the HashTable
 *
 */
void Traverse(HashTable *phash)
{
    int j = 0;
    for(j = 0;j < phash->tableSize;j++)
    {
        if(phash->ht[j].info == Active)
        {
            printf("the collison is %d,the info is Active,the key is %d,the value is %s\n",phash->ht[j].collison,phash->ht[j].data->key,phash->ht[j].data->value);
        }else
        {
            printf("the collison is %d,the info is Empty.\n",phash->ht[j].collison);
        }
    }
}

/*
 * args:
 *      phash:the pointer points to the HashTable
 *      pkey:the key to Find
 * return:the HashItem result
 * doc:find the HashItem whose key is pkey
 *
 */
HashItem* Find(HashTable *phash,KeyType pkey)
{
    int i = hash(phash->tableSize,pkey);
    int j = i;
    int collison = phash->ht[j].collison;

    while(collison != 0)
    {
        if(phash->ht[j].info == Empty)
        {
            j += 1;
        }else
        {
            if(phash->ht[j].data->key == pkey)
            {
               return &(phash->ht[j]);  
            }else
            {
                if(hash(phash->tableSize,phash->ht[j].data->key) == i)
                {
                    collison -= 1;
                }
                j += 1;
            }
       }
    }

    return NULL;
}

/*
 * args:
 *      phash:the pointer points to the HashTable
 *      pkey:the key to Delete
 * return:
 *      1:success
 *      0:fail
 * doc:Delete the HashItem whose key is pkey
 *
 */
int Delete(HashTable *phash,KeyType key)
{
    HashItem *result = Find(phash,key);

    if(result != NULL)
    {
        result->info = Empty;
        result->collison -= 1;
        result->data = NULL;
        phash->currentSize--;

        return 1;
    }
    else
        return 0;
}

/*
 * args:
 *      phash:the pointer points to the HashTable
 * return:
 * doc:Destroy the HashTable
 *
 */
void Destroy(HashTable *phash)
{
    int j = 0;
    for(j = 0;j < phash->tableSize;j++)
    {
        if(phash->ht[j].info == Active)
        {
            free(phash->ht[j].data);
        }
    }
    free(phash->ht);
}

/*
 * args:
 * return:
 * doc:show help messages
 *
 */
void showhelp()
{
    printf("*****************************Please choose******************************\n");
    printf("1---Add a new record;\n");
    printf("2---Find the record by key;\n");
    printf("3---Delete the record by key;\n");
    printf("4---Show the records;\n");
    printf("5---Exit.\n");
}

int main(void)
{
    int choose;
    int initsize = 20;
    KeyType key;
    char value[256] = {0};
    HashTable myHashTable;
    DataType *data = NULL;
    HashItem *result = NULL;

    Initiate(&myHashTable,initsize);
    do{
        showhelp();
        printf("please input your choose:\n");
        scanf("%d",&choose);
        switch(choose)
        {
            case 1:
                data = (DataType *)malloc(sizeof(DataType));
                printf("Please input the key(int):");
                scanf("%d",&(data->key));
                printf("Please input the value(string):");
                scanf("%s",data->value);
                if(Insert(&myHashTable,data) == 1)
                {
                    printf("Add successfully!\n");
                }else
                {
                    printf("Add failed!\n");
                }
                break;
            case 2:
                printf("Please input the key(int):");
                scanf("%d",&key);
                result = Find(&myHashTable,key);
                if(result == NULL)
                {
                    printf("Not Existed!\n");
                }else
                {
                    printf("The key is %d,the value is %s\n",key,result->data->value);
                }
                break;
            case 3:
                printf("Please input the key(int):");
                scanf("%d",&key);
                if(Delete(&myHashTable,key) == 1)
                {
                    printf("Delete successfully!\n");  
                }else
                {
                    printf("Delete failed!\n");
                }
                break;
            case 4:
                Traverse(&myHashTable); 
                break;
            case 5:
                Destroy(&myHashTable);
                exit(0);
            default:
                break;
        }
    }while(1);
}
