#ifndef _MULTI_THREADED
#define _MULTI_THREADED
#endif
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <time.h>

#include "dbDomain.h"

#define LOCKNUM 10
#define MAXBUCKETS 65535
#define SUBMAX 7

/*
 * (Domain Data in Hash-B-Tree) structure definition
 */

typedef struct BlackRecord
{
   unsigned char control_type; // 数据控制策略（0为丢弃，1为重定向，2为欺骗）
   char* value_domain;         // 域名
   char* info;                 // 重定向信息（IP字符串）
   struct BlackRecord *next;   // 后继数据结点
}BlackRecord,* BRecordList;

/*
 * (Domain Data in Cache) structure definition
 */

/*#pragma pack(1)
 *作用：调整结构体的边界对齐，让其以一个字节对齐；
 *
 * (2) #pragma pack(push,1)

 *这是给编译器用的参数设置，有关结构体字节对齐方式的设置

 *大概是指把原来对齐方式设置压栈，并设新的设置为1
 */

#pragma pack(push, 1)
typedef struct TempRecord
{
   unsigned long key1;         // Hash函数生成的关键字，用于查询哈希表
   unsigned long key2;         // Hash关键字，作为B树中的关键字
   unsigned char control_type:2,
		 opcode_type:2,
		 reserve:4;    // control_type为控制策略，opcode_type为更新类型（0为增加，1为删除）
   char* value_domain;
   char* info;
   struct TempRecord* next;
}TempRecord,*TempList;
#pragma pack(pop)
/*
 *  B Tree node structure definition
 */
typedef struct BTNode
{
  int keynum;                     // 当前结点中存在的关键字数
  unsigned long key[SUBMAX+1];    // 关键字列表
  struct BTNode *parent;          // 父指针
  struct BTNode *ptr[SUBMAX+1];   // 子树列表
  BRecordList brecord[SUBMAX+1];  // Domain数据
}BTNode,* BTree;

/*
 * structure of node in Hash-table
 */
struct HashNode
{
  unsigned long members; // 当前Hash桶结点中包含的Domain数
  BTree pb;              // B树根结点
};
/*
 * search result of B-Tree
 */
typedef struct
{
  BTNode * pt;         // 所查数据在B树中的位置，如果数据不存在则返回待插入的结点位置
  int i;               // 所查数据在当前结点所有关键字列表中的位置（pt->key[i]），如果数据不存在则返回待插入的关键字位置
  int tag;             // 所查数据是否存在（0为不存在，1为存在）
}Result, *PResult;

/*
 * Cache structure
 */
struct CacheList
{
  TempList list;        //主缓存，立即生效数据添加至主缓存
  TempList templist;    //辅缓存，当清空主缓存时，先将主缓存数据加入辅缓存，然后将辅缓存数据加入Hash-B-Tree
};

//upper char convert lower
static unsigned char maptolower[] = {
	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
	0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
	0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
	0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
	0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
	0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
	0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
	0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
	0x40, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67,
	0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f,
	0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77,
	0x78, 0x79, 0x7a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
	0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67,
	0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f,
	0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77,
	0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f,
	0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
	0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
	0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
	0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
	0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
	0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf,
	0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7,
	0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf,
	0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7,
	0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf,
	0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7,
	0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf,
	0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7,
	0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef,
	0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7,
	0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff
};

//Hash Table & Cache
struct HashNode* HashTable=NULL;
struct CacheList* Cache=NULL;

// locks
pthread_rwlock_t CacheLock;            //Cache list lock.
pthread_rwlock_t *RecordLock=NULL;     //The search tree locks.

// Function declare.
static result_t
CreateFromFile(void);
static result_t
SearchInList(char* domain, unsigned char* control_type,unsigned long lockindex,unsigned long key2,char** info);
static result_t
SearchInBTree(char* domain,unsigned char* control_type,unsigned long key1,unsigned long key2,char** info);
static int
UpdateToList(void* collection,size_t size);
static int
UpdateToBTree(void* collection,size_t size);
static result_t
AddDomainName(char* domain,unsigned char control_type,unsigned long key1,unsigned long key2,char* info);
static result_t
DeleteDomainName(char* domain,unsigned long key1,unsigned long key2);
// BTree functions
static unsigned long hashkey1(char* str);
static unsigned long hashkey2(char* str);
static result_t NewRoot(BTree*,unsigned long,BRecordList,BTree);
static result_t InsertBTNode(BTree*,unsigned long,BRecordList,BTree,int);
static void SearchBTNode(BTree,unsigned long,PResult);
static void AdjustBTree(BTree*,BTree);
static void DeleteBTNode(BTree*,BTree,int);
static void FreeTree(BTree);
// write logs
static void DBLogging(const char *filePath, const char *logString);

static inline void UPPERTOLOWER(char* str)
{
    while(*str!='\0')
    {
        *str=maptolower[(unsigned char)(*str)];
        str++;
    }
}

static unsigned long hashkey1(char* str)
{ //Used in OpenSSL,it is effective
  int i,l;
  unsigned long ret=0;
  unsigned short* s;
  if(str!=NULL)
   {
      l=(strlen(str)+1)/2;
      s=(unsigned short *)str;
      for(i=0;i<l;i++)
         ret^=(s[i]<<(i&0x0f));
   }
   return ret;
}
static unsigned long hashkey2(char* str)
{  //Used in PHP
   unsigned long h=0,g;
   char * strCurrent=str;
   char * strEnd=str+strlen(str);
   while(strCurrent<strEnd)
   {
      h=(h<<4)+*strCurrent++;
      if((g=(h&0xF0000000)))
      {
         h=h^(g>>24);
         h=h^g;
      }
   }
   return h;
}

static void SearchBTNode(BTree T,unsigned long K,PResult r)
{
   BTree p=T,q=NULL;
   int found=0,i=0,n;
   while(p && found==0)
   {
      //Search(p,K)----find i at p->key[1...n]
      n=p->keynum;
      if(K>=p->key[1] && K<p->key[n])
      {
        for(i=1;i<n;i++)
        {
          if(K>=p->key[i] && K<p->key[i+1])
             break;
        }
      }else if(K<p->key[1])
         i=0;
      else
         i=n;

      //find the right position
      if(i!=0 && p->key[i]==K)
        found=1;
      else{
         q=p;
         p=p->ptr[i];
      }
   }
   r->i=i;
   if(found==1)
   {
      r->pt=p;
      r->tag=1;
   }
   else{
      r->pt=q;
      r->tag=0;
   }
}

static result_t NewRoot(BTree* T,unsigned long K,BRecordList record,BTree p)
{
    char logString[256];
    BTree newtree=(BTNode*)malloc(sizeof(BTNode));
    if(newtree==NULL)
    {
       goto err_malloc;
    }
    newtree->keynum=1;
    newtree->key[1]=K;
    newtree->brecord[1]=record;
    if(p==NULL)             //Create first root.
       newtree->ptr[0]=NULL;
    else                    //Sqlit to two trees,and Create a new root.
       newtree->ptr[0]=*T;
    newtree->ptr[1]=p;
    newtree->parent=NULL;
    if(newtree->ptr[0]!=NULL)
       newtree->ptr[0]->parent=newtree;
    if(newtree->ptr[1]!=NULL)
       newtree->ptr[1]->parent=newtree;
    *T=newtree;
    return R_SUCCESS;

err_malloc:
   memset(logString, 0, 256);
   snprintf(logString,256,"[ERROR] dbDomain.c @ NewRoot @ malloc --- no enough memory!");
   DBLogging(PROG_ERROR_LOG, logString);
   return R_FAILED;
}

static result_t InsertBTNode(BTree* T,unsigned long K,BRecordList record,BTree q,int i)
{
    unsigned long x=K;
    BTree ap=NULL,cq=q;
    BRecordList br=record;
    int finished=0,index=i,s=(SUBMAX+1)/2,j,n;
    char logString[256];

    while(cq && finished==0)
    { //Insert key='x' to tree 'cq', and subtree cq->ptr[index+1]='ap'.
       (cq->keynum)++;
       for(j=cq->keynum;j>index+1;j--)
       {
          cq->key[j]=cq->key[j-1];
          cq->brecord[j]=cq->brecord[j-1];
          cq->ptr[j]=cq->ptr[j-1];
       }
       cq->key[index+1]=x;
       cq->brecord[index+1]=br;
       cq->ptr[index+1]=ap;

       if(cq->keynum<SUBMAX)
          finished=1;
       else
       { //sqlit the tree cq to two trees: 'cq' and 'ap'.
          ap=(BTNode*)malloc(sizeof(BTNode));
          if(ap==NULL)
          {
             goto err_malloc;
          }
            //move the last half keys of 'cq' to 'ap'.
          ap->keynum=SUBMAX-s;
          for(j=1;j<=ap->keynum;j++)
          {
             ap->key[j]=cq->key[s+j];
             ap->brecord[j]=cq->brecord[s+j];
             ap->ptr[j]=cq->ptr[s+j];
             cq->ptr[s+j]=NULL;
             if(ap->ptr[j]!=NULL)
               ap->ptr[j]->parent=ap;
          }
          ap->ptr[0]=cq->ptr[s];
          cq->ptr[s]=NULL;
          if(ap->ptr[0]!=NULL)
            ap->ptr[0]->parent=ap;
          ap->parent=cq->parent;
             //delete the last half keys from 'cq'.
          cq->keynum=s-1;
             //reset 'x','br' and 'cq'.
          x=cq->key[s];
          br=cq->brecord[s];
          cq=cq->parent;
          if(cq)
          { //If 'cq' not NULL,then search the right position of 'x' in 'cq'. And the value save in 'index'.
            n=cq->keynum;
            if(x>=cq->key[1] && x<cq->key[n])
            {
               for(index=1;index<n;index++)
               {
                  if(x>=cq->key[index] && x<cq->key[index+1])
                     break;
               }
            }else if(x<cq->key[1])
               index=0;
            else
               index=n;
          }
       }
    }
    //If 'T' is null or the root has sqlit,then make a new root.
    if(finished==0)
       return NewRoot(T,x,br,ap);
    else
       return R_SUCCESS;

err_malloc:
   memset(logString, 0, 256);
   snprintf(logString,256,"[ERROR] dbDomain.c @ InsertBTNode @ malloc --- no enough memory!");
   DBLogging(PROG_ERROR_LOG, logString);
   return R_FAILED;
}
static result_t
AddDomainName(char* domain,unsigned char control_type, unsigned long key1,unsigned long key2,char* info)
{
   BTree* newbt;
   Result* pr;
   BlackRecord *record,*pb,*pre;
   char logString[256];

   //Create a new record
   record=(BlackRecord *)malloc(sizeof(BlackRecord));
   if(record==NULL)
   {
	goto err_malloc;
   }
   record->value_domain=(char*)malloc((strlen(domain)+1)*sizeof(char));
   if(record->value_domain==NULL)
   {
        free(record);
        goto err_malloc;
   }
   strcpy(record->value_domain,domain);
   if(info==NULL)
        record->info=NULL;
   else
   {
        record->info=(char*)malloc((strlen(info)+1)*sizeof(char));
        if(record->info==NULL)
        {
           free(record->value_domain);
           free(record);
           goto err_malloc;
        }
        strcpy(record->info,info);
   }
   record->control_type=control_type;
   record->next=NULL;

   //Add record
   if(HashTable[key1].members==0)
   {
       newbt=(BTree*)malloc(sizeof(BTree));
       if(newbt==NULL)
       {
           free(record->value_domain);
           free(record);
           if((record->info)!=NULL)
               free(record->info);
           goto err_malloc;
       }
       if(InsertBTNode(newbt,key2,record,NULL,0) == R_FAILED)
       {
           free(newbt);
           goto err_insert;
       }else{
           HashTable[key1].pb=*newbt;
           free(newbt);
           HashTable[key1].members++;
       }
    }else {
       pr=(Result*)malloc(sizeof(Result));
       if(pr==NULL)
       {
          free(record->value_domain);
          free(record);
          if((record->info)!=NULL)
              free(record->info);
          goto err_malloc;
       }
       SearchBTNode(HashTable[key1].pb,key2,pr);
       if(pr->tag==0)
       {
          if(InsertBTNode(&(HashTable[key1].pb),key2,record,pr->pt,pr->i) == R_FAILED)
          {
               free(pr);
               goto err_insert;
          }
          HashTable[key1].members++;
       }else{
         pb=pr->pt->brecord[pr->i];
         pre=pb;
         while(pb!=NULL)
         {
             if(strcmp(pb->value_domain,domain)==0)
             { // HAVE EXIST!!!
                pb->control_type=control_type;
                char* tmp=pb->info;
		pb->info=record->info;
                if(tmp!=NULL)
                   free(tmp);
                free(record->value_domain);
                free(record);
                break;
             }
             pre=pb;
             pb=pb->next;
         }
         if(pb==NULL)
         {
            pre->next=record;
            HashTable[key1].members++;
         }
      }
      free(pr);
   }
   return R_SUCCESS;

err_malloc:
   memset(logString, 0, 256);
   snprintf(logString,256,"[ERROR] dbDomain.c @ AddDomainName @ malloc --- no enough memory!");
   DBLogging(PROG_ERROR_LOG, logString);
err_insert:
   return R_FAILED;
}

static void AdjustBTree(BTree* T,BTree q)
{
    BTree parent,brother;
    int i=0,j,num,s=(SUBMAX+1)/2;
    if((q->keynum)>=(s-1))
      return;
    //Search in its parent,find its own position.save it in i.
    parent=q->parent;
    if(parent!=NULL)
    { //find the right position in its parent
       for(i=0;i<=parent->keynum;i++)
       {
          if((parent->ptr[i])==q)
             break;
       }
    }else
    { //Reset the root
       if((*T)->keynum==0 && (*T)->ptr[0]!=NULL)
       { /* If the key of root is 0,rebuilt the root
          * else if the number of root's key isn't 0, it's just OK.
          */
          *T=q->ptr[0];
          (*T)->parent=NULL;
          free(q);
       }else if((*T)->keynum==0 && (*T)->ptr[0]==NULL)
         free(q);
       return;
    }
    //Begin adjust the tree.
    if(q->keynum==(s-2) && i<parent->keynum && parent->ptr[i+1]!=NULL && (parent->ptr[i+1]->keynum)>(s-1))
    { //right to left balance adjust
       brother=parent->ptr[i+1];
       (q->keynum)++;
         //Add node at its last place
       q->key[q->keynum]=parent->key[i+1];
       q->brecord[q->keynum]=parent->brecord[i+1];
         //Add the right brother's first subtree as its own last subtree
       q->ptr[q->keynum]=brother->ptr[0];
       if(q->ptr[q->keynum]!=NULL)
          q->ptr[q->keynum]->parent=q;
         //Set parent's key
       parent->key[i+1]=brother->key[1];
       parent->brecord[i+1]=brother->brecord[1];
         //delete brother's first node
       brother->ptr[0]=brother->ptr[1];
       for(j=1;j<brother->keynum;j++)
       {
          brother->key[j]=brother->key[j+1];
          brother->brecord[j]=brother->brecord[j+1];
          brother->ptr[j]=brother->ptr[j+1];
       }
       brother->ptr[brother->keynum]=NULL;
       (brother->keynum)--;
       return;
    }else if(q->keynum==(s-2) && i>0 && parent->ptr[i-1]!=NULL && (parent->ptr[i-1]->keynum)>(s-1))
    { //left to right balance adjust
       brother=parent->ptr[i-1];
          //Move q itself,Add key at first place
       (q->keynum)++;
       for(j=q->keynum;j>1;j--)
       {
          q->key[j]=q->key[j-1];
          q->brecord[j]=q->brecord[j-1];
          q->ptr[j]=q->ptr[j-1];
       }
       q->ptr[1]=q->ptr[0];
         //Set its first key as its parent's
       q->key[1]=parent->key[i];
       q->brecord[1]=parent->brecord[i];
         //Insert the left brother's last subtree as its own first subtree
       q->ptr[0]=brother->ptr[brother->keynum];
       if(q->ptr[0]!=NULL)
         q->ptr[0]->parent=q;
         //Set parent's key
       parent->key[i]=brother->key[brother->keynum];
       parent->brecord[i]=brother->brecord[brother->keynum];
         //delete brother's last node
        brother->ptr[brother->keynum]=NULL;
       (brother->keynum)--;
       return;
    }else
    { //joint the brother trees
       if(i<parent->keynum && parent->ptr[i+1]!=NULL)
       { //join to the right brother
          brother=parent->ptr[i+1];
          num=brother->keynum;
          brother->keynum=(brother->keynum)+(q->keynum)+1;
          for(j=brother->keynum;j>(q->keynum)+1;j--)
          { //move brother itself
             brother->key[j]=brother->key[j-(q->keynum)-1];
             brother->brecord[j]=brother->brecord[j-(q->keynum)-1];
             brother->ptr[j]=brother->ptr[j-(q->keynum)-1];
          }
          brother->ptr[j]=brother->ptr[0];
            //insert a node of parent to it
          brother->key[j]=parent->key[i+1];
          brother->brecord[j]=parent->brecord[i+1];
            //insert its left brother to it
          for(j=q->keynum;j>0;j--)
          {
             brother->key[j]=q->key[j];
             brother->brecord[j]=q->brecord[j];
             brother->ptr[j]=q->ptr[j];
             if(brother->ptr[j]!=NULL)              //very important
               brother->ptr[j]->parent=brother;
          }
          brother->ptr[0]=q->ptr[0];
          if(brother->ptr[0]!=NULL)
            brother->ptr[0]->parent=brother;
            //adjust the parent
          parent->ptr[i]=parent->ptr[i+1];
          for(j=i+1;j<parent->keynum;j++)
          {
             parent->key[j]=parent->key[j+1];
             parent->brecord[j]=parent->brecord[j+1];
             parent->ptr[j]=parent->ptr[j+1];
          }
          parent->ptr[parent->keynum]=NULL;
          parent->keynum--;
          free(q);
       }else if(i>0 && parent->ptr[i-1]!=NULL)
       { //join to the left brother
          brother=parent->ptr[i-1];
          num=brother->keynum;
          brother->keynum=(brother->keynum)+(q->keynum)+1;
            //add a node of parent to its last place
          brother->key[num+1]=parent->key[i];
          brother->brecord[num+1]=parent->brecord[i];
            //add its right brother node to its last place
          brother->ptr[num+1]=q->ptr[0];
          if(brother->ptr[num+1]!=NULL)
            brother->ptr[num+1]->parent=brother;
          for(j=num+2;j<=brother->keynum;j++)
          {
             brother->key[j]=q->key[j-num-1];
             brother->brecord[j]=q->brecord[j-num-1];
             brother->ptr[j]=q->ptr[j-num-1];
             if(brother->ptr[j]!=NULL)
               brother->ptr[j]->parent=brother;
          }
            //adjust parent node. because i==parent->keynum ,so it's just ok.
          for(j=i;j<parent->keynum;j++)
          {
             parent->key[j]=parent->key[j+1];
             parent->brecord[j]=parent->brecord[j+1];
             parent->ptr[j]=parent->ptr[j+1];
          }
          parent->ptr[parent->keynum]=NULL;
          parent->keynum--;
          free(q);
       }else
       { /* its left and right brother all NULL,
          * Normally this condition won't occur,but we still do sth here.
          */
         return;
       }
       AdjustBTree(T,parent);
    }
}

static void DeleteBTNode(BTree* T,BTree q,int i)
{
    BTree current=q;
    BRecordList br=q->brecord[i];
    int j;
    if(q->ptr[i-1]!=NULL || q->ptr[i]!=NULL)
    { //Not the leaf
       if(q->ptr[i]!=NULL)
       {  //find in the right child
          current=q->ptr[i];
            //find a MIN key in the right subtree.
          while((current->ptr[0]))
             current=current->ptr[0];
            //replace the key
          q->key[i]=current->key[1];
          q->brecord[i]=current->brecord[1];
            //adjust current node
          current->ptr[0]=current->ptr[1];
          for(j=1;j<=current->keynum;j++)
          {
            current->key[j]=current->key[j+1];
            current->ptr[j]=current->ptr[j+1];
            current->brecord[j]=current->brecord[j+1];
          }
       }else{
        //find in the left child
          current=q->ptr[i-1];
           //find a MAX key in left subtree.
          while((current->ptr[current->keynum]))
             current=current->ptr[current->keynum];
           //replace the key
          q->key[i]=current->key[current->keynum];
          q->brecord[i]=current->brecord[current->keynum];
       }
    }else{
     //It is a leaf.then delete the key directly.
        for(j=i;j<current->keynum;j++)
        {
           current->key[j]=current->key[j+1];
           current->ptr[j]=current->ptr[j+1];
           current->brecord[j]=current->brecord[j+1];
        }
    }
    (current->keynum)--;
    free(br->value_domain);
    if((br->info)!=NULL)
	free(br->info);
    free(br);
    AdjustBTree(T,current);
}

static result_t DeleteDomainName(char* domain,unsigned long key1,unsigned long key2)
{
   BlackRecord * pb,* pre;
   Result* pr;
   char logString[256];

   if(HashTable[key1].members!=0)
   {
        pr=(Result*)malloc(sizeof(Result));
        if(pr==NULL)
        {
           goto err_malloc;
        }
        SearchBTNode(HashTable[key1].pb,key2,pr);
        if(pr->tag!=0)
        {
           pb=pr->pt->brecord[pr->i];
           if(pb->next==NULL && strcmp(pb->value_domain,domain)==0)
           {
              DeleteBTNode(&(HashTable[key1].pb),pr->pt,pr->i);
              HashTable[key1].members--;
              free(pr);
           }else if(pb->next!=NULL)
           {
              pre=pb;
              while(pb!=NULL)
              {
                 if(strcmp(pb->value_domain,domain)==0)
                 {
                    if(pre!=pb)
                       pre->next=pb->next;
                    else
                    {
                       pre=pb->next;
                       pr->pt->brecord[pr->i]=pre;
                    }
                    HashTable[key1].members--;
                    free(pb->value_domain);          //delete the record
                    if((pb->info)!=NULL)
			free(pb->info);
                    free(pb);
                    break;
                 }
                 pre=pb;
                 pb=pb->next;
              }
              free(pr);
           }
        }
   }
    return R_SUCCESS;

err_malloc:
   memset(logString, 0, 256);
   snprintf(logString,256,"[ERROR] dbDomain.c @ DeleteDomainName @ malloc --- no enough memory!");
   DBLogging(PROG_ERROR_LOG, logString);
   return R_FAILED;
}

static void FreeTree(BTree bt)
{
   int i,j;
   if(bt==NULL)
     return;
   for(i=0;i<=bt->keynum;i++)
     FreeTree(bt->ptr[i]);
   for(j=1;j<=bt->keynum;j++)
   {
     BRecordList pre=bt->brecord[j],current;
     while(pre!=NULL)
     {
        current=pre;
        pre=pre->next;
        free(current->value_domain);
        if((current->info)!=NULL)
	   free(current->info);
        free(current);
     }
   }
   free(bt);
}

static result_t CreateFromFile(void)
{
    int fin,sum=0;
	void *start;
	struct stat sb;
	result_t result;
	char logString[256];

    struct data_hdr *hdr;
	char *domain, *info;
	unsigned long key1,key2;

	if(access(DOMAIN_DATA_PATH, F_OK) == -1)        //用于判断文件是否存在
		return R_SUCCESS;

    fin=open(DOMAIN_DATA_PATH,O_RDONLY);        
    if(fin == -1)
    {
        /* 访问被禁止 */
		memset(logString, 0, 256);
		snprintf(logString,256,"[ERROR] dbDomain.c @ CreateFromFile @ open --- %s", strerror(errno));
		goto err_out;
    }
	fstat(fin,&sb);     //获取文件信息
	if(sb.st_size > 0)  //判断文件大小
		start=mmap(NULL,sb.st_size,PROT_READ,MAP_PRIVATE,fin,0);
	else
		goto out;
	if(start== MAP_FAILED)
	{	/* 判断是否映射成功 */
		close(fin);
		memset(logString, 0, 256);
		snprintf(logString,256,"[ERROR] dbDomain.c @ CreateFromFile @ mmap --- %s", strerror(errno));
		goto err_out;
	}

	while(sum<sb.st_size)
	{
		hdr=(struct data_hdr *)start;
		start+=sizeof(*hdr);

		domain=(char*)malloc(sizeof(char)*(hdr->val_length + 1));
		if(domain == NULL)
		{
			memset(logString, 0, 256);
			snprintf(logString,256,"[ERROR] dbDomain.c @ CreateFromFile @ malloc --- %s", strerror(errno));
			goto err_out0;
		}
 		memcpy(domain,start,hdr->val_length);       //进行二进制内存复制数据
		domain[hdr->val_length]='\0';
		start= start+hdr->val_length;

		if(hdr->info_length!=0)
		{
			info=(char*)malloc(sizeof(char)*(hdr->info_length+1));
			if(info == NULL)
			{
				free(domain);
				memset(logString, 0, 256);
				snprintf(logString,256,"[ERROR] dbDomain.c @ CreateFromFile @ malloc --- %s", strerror(errno));
				goto err_out0;
			}
			memcpy(info,start,hdr->info_length);
			info[hdr->info_length]='\0';
			start= start+hdr->info_length;
		}else
			info=NULL;

		UPPERTOLOWER(domain);
		key1=(hashkey1(domain))%MAXBUCKETS;
		key2=hashkey2(domain);

        if(hdr->opcode_type==OPCODE_ADD)
		{
                     result=AddDomainName(domain,hdr->control_type,key1,key2,info);
		}else if(hdr->opcode_type==OPCODE_DELETE)
		{
                     result=DeleteDomainName(domain,key1,key2);
		}else
		     result=R_FAILED;
		/*
		 *  Add 'result' to logs.
		 */
		if(result == R_FAILED)
		{
			memset(logString, 0, 256);
			snprintf(logString,256,"[ERROR] dbDomain.c @ CreateFromFile @ Update_Data --- %s", domain);
			free(domain);
			if(info!=NULL)
				free(info);
			goto err_out0;
		}
		free(domain);
		if(info!=NULL)
			free(info);

		sum=sum + hdr->val_length + hdr->info_length + sizeof(*hdr);
	}
	munmap(start,sb.st_size); /*解除映射*/
out:
	close(fin);
	return R_SUCCESS;
err_out0:
	munmap(start,sb.st_size); /*解除映射*/
	close(fin);
err_out:
	DBLogging(PROG_ERROR_LOG, logString);
	return R_FAILED;
}

result_t InitializeSearchTree(void)
{
   int i,j,rtn=0;
   char logString[256];

   if(HashTable!=NULL)
   {   //Database has exist,then delete it
	if(DestroySearchTree()!=R_SUCCESS)
		return R_FAILED;
   }
   
   //initial hash table, data initial as 0
   HashTable=(struct HashNode*)calloc(MAXBUCKETS, sizeof(struct HashNode));
   if(HashTable==NULL)
   {
	memset(logString, 0, 256);
	snprintf(logString,256,"[ERROR] dbDomain.c @ InitializeSearchTree @ calloc --- %s", strerror(errno));
	goto err_out;
   }

   //initial cache, initial as NULL(0)
    Cache=(struct CacheList*)calloc(LOCKNUM, sizeof(struct CacheList));
    if(Cache==NULL)
    {
	free(HashTable);
	memset(logString, 0, 256);
	snprintf(logString,256,"[ERROR] dbDomain.c @ InitializeSearchTree @ calloc --- %s", strerror(errno));
	goto err_out;
    }

   //initial the locks
   rtn = pthread_rwlock_init(&CacheLock, NULL);
   if(rtn!=0)
   {
         free(HashTable);
         free(Cache);
	 memset(logString, 0, 256);
	 snprintf(logString,256,"[ERROR] dbDomain.c @ InitializeSearchTree @ pthread_rwlock_init --- cache lock initial error!");
	 goto err_out;
   }
   RecordLock=(pthread_rwlock_t*)malloc(LOCKNUM*sizeof(pthread_rwlock_t));
   if(RecordLock==NULL)
   {
      free(HashTable);
      free(Cache);
      pthread_rwlock_destroy(&CacheLock);
      memset(logString, 0, 256);
      snprintf(logString,256,"[ERROR] dbDomain.c @ InitializeSearchTree @ malloc --- %s", strerror(errno));
      goto err_out;
   }
   for(i=0;i<LOCKNUM;i++)
   {
      rtn = pthread_rwlock_init((RecordLock+i), NULL);
      if(rtn!=0)
      {
         free(HashTable);
         free(Cache);
          //destory locks which have create
         pthread_rwlock_destroy(&CacheLock);
	 for(j=0;j<i;j++)
    		pthread_rwlock_destroy((RecordLock+j));
	 free(RecordLock);
	 memset(logString, 0, 256);
	 snprintf(logString,256,"[ERROR] dbDomain.c @ InitializeSearchTree @ pthread_rwlock_init --- record lock initial error!");
	 goto err_out;
      }
   }
   //read file,and initial search tree
   return CreateFromFile();

err_out:
   DBLogging(PROG_ERROR_LOG, logString);
   return R_FAILED;
}

result_t DestroySearchTree(void)
{
   int i;
   if(HashTable==NULL)
      return R_SUCCESS;

   //Destroy locks
   for(i=0;i<LOCKNUM;i++)
        pthread_rwlock_destroy((RecordLock+i));
   pthread_rwlock_destroy(&CacheLock);

   //Free record locks memory
    free(RecordLock);

   //Free Cache
   for(i=0;i<LOCKNUM;i++)
   {
      if(Cache[i].list!=NULL)
      {   //free cachelist
          TempRecord* p,*q=Cache[i].list;
	  while(q)
	  {
          	p=q;
		q=q->next;
		free(p->value_domain);
		if((p->info)!=NULL)
			free(p->info);
		free(p);
	  }
      }
      if(Cache[i].templist!=NULL)
      {   //free temp list in cache
          TempRecord* p,*q=Cache[i].templist;
	  while(q)
	  {
          	p=q;
		q=q->next;
		free(p->value_domain);
		if((p->info)!=NULL)
			free(p->info);
		free(p);
	  }
      }
   }
   free(Cache);

   //Free Hash Table
   for(i=0;i<MAXBUCKETS;i++)
   {
      if(HashTable[i].members==0)
         continue;
      FreeTree(HashTable[i].pb);
   }
   free(HashTable);
   return R_SUCCESS;
}

result_t
SearchDomainName(char* domain, unsigned char* control_type, char** info)
{
   unsigned long key1,key2,lockindex;
   result_t result=R_NOTFOUND;
   *info=NULL;

   UPPERTOLOWER(domain);
   key1=(hashkey1(domain))%MAXBUCKETS;
   key2=hashkey2(domain);
   lockindex=key1%LOCKNUM;

   if(HashTable[key1].members!=0)
   {    //search in cache list
	if(Cache[lockindex].list || Cache[lockindex].templist)
	{
		pthread_rwlock_rdlock(&CacheLock);
		result=SearchInList(domain,control_type,lockindex,key2,info);
		pthread_rwlock_unlock(&CacheLock);
        	if(result==R_INVALID)
        	{
        		//found in list ,but is deleting.
			return R_NOTFOUND;
		}
	}
	if(result!=R_FOUND)
	{       //search in B Tree
        	pthread_rwlock_rdlock((RecordLock+lockindex));
		result=SearchInBTree(domain,control_type,key1,key2,info);
		pthread_rwlock_unlock((RecordLock+lockindex));
	}
   }
   if(result == R_FOUND && *control_type == CFLAG_REDIRECT && *info == NULL)
   {
        //指定默认重定向地址
        *info=(char*)malloc(sizeof(char)*(strlen(DEFAULT_REDI_IP)+1));
	if((*info)!=NULL)
	     strcpy(*info,DEFAULT_REDI_IP);
   }
   return result;
}

static result_t SearchInList(char* domain, unsigned char* control_type,unsigned long lockindex,
				unsigned long key2,char** info)
{   
    /*
     *  Return: R_FOUND or R_NOTFOUND
     */
     
   result_t result = R_NOTFOUND;
   TempRecord* cur=Cache[lockindex].list;
   while(cur!=NULL)
   {
      if((cur->key2)==key2 && strcmp(cur->value_domain,domain)==0)
      {
	 if(cur->opcode_type==OPCODE_DELETE)
		return R_INVALID;

         *control_type=cur->control_type;
         if((cur->info)!=NULL)
	 {
             *info=(char*)malloc(sizeof(char)*(strlen(cur->info)+1));
	     if((*info)!=NULL)
	        strcpy(*info,cur->info);
  	 }
	 return R_FOUND;
      }
      cur=cur->next;
   }

   cur=Cache[lockindex].templist;
   while(cur!=NULL)
   {
      if((cur->key2)==key2 && strcmp(cur->value_domain,domain)==0)
      {
       	 if(cur->opcode_type==OPCODE_DELETE)
		return R_INVALID;

         *control_type=cur->control_type;
         if((cur->info)!=NULL)
	 {
             *info=(char*)malloc(sizeof(char)*(strlen(cur->info)+1));
	     if((*info)!=NULL)
	        strcpy(*info,cur->info);
  	 }
         return R_FOUND;
      }
      cur=cur->next;
   }
   return result;
}

static result_t
SearchInBTree(char* domain, unsigned char* control_type,unsigned long key1,unsigned long key2,char** info)
{
   Result* pr;
   result_t result=R_NOTFOUND;
   BlackRecord * pb;
   char logString[256];

   pr=(Result*)malloc(sizeof(Result));
   if(pr==NULL)
   {
      memset(logString, 0, 256);
      snprintf(logString,256,"[ERROR] dbDomain.c @ SearchInBTree @ malloc --- %s", strerror(errno));
      goto err_out;
   }
   SearchBTNode(HashTable[key1].pb,key2,pr);
   if(pr->tag!=0)
   {
       pb=pr->pt->brecord[pr->i];
       while(pb)
       {
            if(strcmp(pb->value_domain,domain)==0)
            {
                *control_type=pb->control_type;
           	if((pb->info)!=NULL)
		{
         	    *info=(char*)malloc(sizeof(char)*(strlen(pb->info)+1));
	  	    if((*info)!=NULL)
	  	        strcpy(*info,pb->info);
  	 	}
                result=R_FOUND;
                break;
            }
            pb=pb->next;
       }
   }
   free(pr);
   return result;

err_out:
   DBLogging(PROG_ERROR_LOG, logString);
   return R_NOTFOUND;
}

int UpdateDomainName(void* collection,size_t size,unsigned char tag)
{
    if(tag==UPDATE_NORMAL)
	return UpdateToBTree(collection,size);  //normal update
    else if(tag==UPDATE_QUICK)
	return UpdateToList(collection,size);   //fast update
    else
	return 0;
}

static int UpdateToList(void* collection,size_t size)
{
    int index=0, count = 0;
    size_t sum=0;
    void* start=collection;
    struct data_hdr *hdr;
    TempList groups[LOCKNUM];
    TempList ends[LOCKNUM];
    char logString[256];
    //get tokens from collection.

    memset(groups, 0, LOCKNUM*sizeof(TempList));
    memset(ends, 0, LOCKNUM*sizeof(TempList));

    while(sum<size)
    {
	TempRecord* pr=(TempRecord*)malloc(sizeof(TempRecord));

        hdr=(struct data_hdr *)start;
	start+=sizeof(*hdr);
        pr->opcode_type=hdr->opcode_type;
        pr->control_type=hdr->control_type;

	pr->value_domain=(char*)malloc(sizeof(char)*(hdr->val_length + 1));
	if(pr->value_domain == NULL)
		goto err_malloc;
 	memcpy(pr->value_domain,start, hdr->val_length);
	pr->value_domain[hdr->val_length]='\0';
	start= start+hdr->val_length;

	if(hdr->info_length!=0)
	{
		pr->info=(char*)malloc(sizeof(char)*(hdr->info_length+1));
		if(pr->info == NULL)
		{
			free(pr->value_domain);
			goto err_malloc;
		}
		memcpy(pr->info,start,hdr->info_length);
		pr->info[hdr->info_length]='\0';
		start= start+hdr->info_length;
	}else
		pr->info=NULL;

	UPPERTOLOWER(pr->value_domain);
	pr->key1=(hashkey1(pr->value_domain))%MAXBUCKETS;
	pr->key2=hashkey2(pr->value_domain);

	if(groups[(pr->key1)%LOCKNUM]==NULL)
		ends[(pr->key1)%LOCKNUM]=pr;
        pr->next=groups[(pr->key1)%LOCKNUM];
	groups[(pr->key1)%LOCKNUM]=pr;

	count++;
	sum=sum + hdr->val_length + hdr->info_length + sizeof(*hdr);
    }

    //get the lock,and update.
    pthread_rwlock_wrlock(&CacheLock);
    for(index=0;index<LOCKNUM;++index)
    {
	if(groups[index]==NULL)
		continue;
	(ends[index])->next=Cache[index].list;
        Cache[index].list=groups[index];
    }
    pthread_rwlock_unlock(&CacheLock);

    return count;

err_malloc:
   memset(logString, 0, 256);
   snprintf(logString,256,"[ERROR] dbDomain.c @ UpdateToList @ malloc --- no enough memory!");
   DBLogging(PROG_ERROR_LOG, logString);
   return count;
}

static int UpdateToBTree(void* collection,size_t size)
{
    int index=0,count = 0;
    size_t sum=0;
    void* start=collection;
    struct data_hdr *hdr;
    TempList groups[LOCKNUM];
    char logString[256];

    //get tokens from collection.
    memset(groups, 0, LOCKNUM*sizeof(TempList));
    while(sum<size)
    {
	TempRecord* pr=(TempRecord*)malloc(sizeof(TempRecord));

        hdr=(struct data_hdr *)start;
	start+=sizeof(*hdr);
        pr->opcode_type=hdr->opcode_type;
        pr->control_type=hdr->control_type;

	pr->value_domain=(char*)malloc(sizeof(char)*(hdr->val_length + 1));
	if(pr->value_domain == NULL)
		goto out_mem;
 	memcpy(pr->value_domain,start,hdr->val_length);
	pr->value_domain[hdr->val_length]='\0';
	start= start+hdr->val_length;

	if(hdr->info_length!=0)
	{
		pr->info=(char*)malloc(sizeof(char)*(hdr->info_length+1));
		if(pr->info == NULL)
		{
			free(pr->value_domain);
			goto out_mem;
		}
		memcpy(pr->info,start,hdr->info_length);
		pr->info[hdr->info_length]='\0';
		start= start+hdr->info_length;
	}else
		pr->info=NULL;

	UPPERTOLOWER(pr->value_domain);
	pr->key1=(hashkey1(pr->value_domain))%MAXBUCKETS;
	pr->key2=hashkey2(pr->value_domain);

        pr->next=groups[(pr->key1)%LOCKNUM];
	groups[(pr->key1)%LOCKNUM]=pr;

	sum=sum + hdr->val_length + hdr->info_length + sizeof(*hdr);
    }

    //get locks and update.
    for(index=0;index<LOCKNUM;++index)
    {
    	if(groups[index]==NULL)
		continue;
	pthread_rwlock_wrlock((RecordLock+index));
	TempRecord* pre,*cur;
	pre=cur=groups[index];
        while(cur!=NULL)
	{
        	cur=cur->next;
		if(pre->opcode_type==OPCODE_ADD)
		{
			if(AddDomainName(pre->value_domain,pre->control_type,pre->key1,pre->key2,pre->info) == R_FAILED)
			{
				memset(logString, 0, 256);
				snprintf(logString,256,"[ERROR] dbDomain.c @ UpdateToBTree @ UPDATE --- add %s failed.", pre->value_domain);
				DBLogging(PROG_ERROR_LOG, logString);
			}
			count++;
		}else if(pre->opcode_type==OPCODE_DELETE)
		{
			if(DeleteDomainName(pre->value_domain,pre->key1,pre->key2) == R_FAILED)
			{
				memset(logString, 0, 256);
				snprintf(logString,256,"[ERROR] dbDomain.c @ UpdateToBTree @ UPDATE --- delete %s failed.", pre->value_domain);
				DBLogging(PROG_ERROR_LOG, logString);
			}
			count++;
		}else{
			memset(logString, 0, 256);
			snprintf(logString,256,"[ERROR] dbDomain.c @ UpdateToBTree @ UPDATE --- operate type error!");
			DBLogging(PROG_ERROR_LOG, logString);
		}

		free(pre->value_domain);
		if((pre->info)!=NULL)
			free(pre->info);
		free(pre);
	        pre=cur;
	}
	pthread_rwlock_unlock((RecordLock+index));
    }
    return count;

out_mem:
   for(index=0;index<LOCKNUM;++index)
    {  // free resource.
    	if(groups[index]==NULL)
		continue;
	TempRecord* pre,*cur;
	pre=cur=groups[index];
        while(cur!=NULL)
	{
		free(pre->value_domain);
		if((pre->info)!=NULL)
			free(pre->info);
		free(pre);
	        pre=cur;
	}
   }
   memset(logString, 0, 256);
   snprintf(logString,256,"[ERROR] dbDomain.c @ UpdateToBTree @ malloc --- no enough memory!");
   DBLogging(PROG_ERROR_LOG, logString);
   return 0;
}

result_t AddListToBTree(void)
{
    int index=0;
    result_t result = R_SUCCESS;
    TempList temp[LOCKNUM];
    char logString[256];

    //copy to temp
    pthread_rwlock_wrlock(&CacheLock);
    for(index=0;index<LOCKNUM;++index)
    {
       Cache[index].templist=Cache[index].list;
       Cache[index].list=NULL;
    }
    pthread_rwlock_unlock(&CacheLock);

    //Add list to BTree.
    for(index=0;index<LOCKNUM;++index)
    {
        //first step: copy to temp list
        temp[index]=Cache[index].templist;

	//next step: add to Btree.
    if(temp[index]==NULL)
	{
            continue;
	}
	TempRecord* cur;
	cur=temp[index];
        while(cur!=NULL)
	{
                pthread_rwlock_wrlock((RecordLock+index));
		if(cur->opcode_type==OPCODE_ADD)
		{
                     if(AddDomainName(cur->value_domain,cur->control_type,cur->key1,cur->key2,cur->info) == R_FAILED)
                     {
				memset(logString, 0, 256);
				snprintf(logString,256,"[ERROR] dbDomain.c @ AddListToBTree @ UPDATE --- add %s failed.", cur->value_domain);
				DBLogging(PROG_ERROR_LOG, logString);
				result = R_FAILED;
                     }
		}else if(cur->opcode_type==OPCODE_DELETE)
		{
               	     if(DeleteDomainName(cur->value_domain,cur->key1,cur->key2) == R_FAILED)
                     {
				memset(logString, 0, 256);
				snprintf(logString,256,"[ERROR] dbDomain.c @ AddListToBTree @ UPDATE --- delete %s failed.", cur->value_domain);
				DBLogging(PROG_ERROR_LOG, logString);
				result = R_FAILED;
                     }
		}else{
			memset(logString, 0, 256);
			snprintf(logString,256,"[ERROR] dbDomain.c @ AddListToBTree @ UPDATE --- operate type error!");
			DBLogging(PROG_ERROR_LOG, logString);
			result = R_FAILED;
                }
                pthread_rwlock_unlock((RecordLock+index));

                cur=cur->next;
	}
    }

    //flush list.
    pthread_rwlock_wrlock(&CacheLock);
    for(index=0;index<LOCKNUM;++index)
    {
       Cache[index].templist=NULL;
    }
    pthread_rwlock_unlock(&CacheLock);

    //free temp list.
    for(index=0;index<LOCKNUM;++index)
    {
        if(temp[index]==NULL)
	{
            continue;
	}
        TempRecord* pre,*cur;
	pre=cur=temp[index];
        while(cur!=NULL)
	{
        	cur=cur->next;
		free(pre->value_domain);
		if((pre->info)!=NULL)
                    free(pre->info);
		free(pre);
	        pre=cur;
	}
    }
    return result;;
}

result_t
SaveToFile(void* collection,size_t size)
{
        int fin;
	size_t sz=0;

	fin=open(DOMAIN_DATA_PATH,O_WRONLY|O_CREAT|O_APPEND,666);
	sz=write(fin,collection,size);
	close(fin);

	return sz == size ? R_SUCCESS : R_FAILED;
}

static void
DBLogging(const char *filePath, const char *logString )
{
	char timeLog[32];
	FILE *LogFile;
	time_t now = time(NULL);
	strftime(timeLog,sizeof(timeLog),"%d/%b/%Y:%H:%M:%S %Z",localtime(&now));

	if((LogFile = fopen(filePath,"a+")) == NULL) { perror("fopen");  return; }
	fprintf(LogFile,"[%s]  ",timeLog);
	fprintf(LogFile,"%s\n",logString);
	fclose(LogFile);
}
