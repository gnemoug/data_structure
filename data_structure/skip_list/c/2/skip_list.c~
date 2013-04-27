#include <stdio.h>
#include <stdlib.h>

/* implementation dependent declarations */ 
typedef enum {   
    STATUS_OK,   
    STATUS_MEM_EXHAUSTED,
    STATUS_DUPLICATE_KEY,
    STATUS_KEY_NOT_FOUND
} statusEnum;

typedef int keyType;            /* type of key */

/* user data stored in tree */
typedef struct {
    int stuff;                  /* optional related data */
} recType;

#define compLT(a,b) (a < b)
#define compEQ(a,b) (a == b)

/* levels range from (0 .. MAXLEVEL) */
#define MAXLEVEL 15

typedef struct nodeTag {
    keyType key;                /* key used for searching */
    recType rec;                /* user data */  
    struct nodeTag *forward[1]; /* skip list forward pointer */
} nodeType;

/* implementation independent declarations */
typedef struct {   
    nodeType *hdr;              /* list Header */
    int listLevel;              /* current level of list */
} SkipList;

SkipList list;                  /* skip list information */

#define NIL list.hdr
static int count = 0;

void print_skip_list()
{
    int i;
    nodeType *x;

    /* 注意此处i一定为由小到大 */
    for (i = 0; i <= list.listLevel; i++) {
        x = list.hdr->forward[i];
        printf("\nlevel[%d]",i);
        while (x->forward[i] != NIL){
            printf("-->%d",x->key);
            x = x->forward[i];
        }
        printf("-->%d",x->key);     /* print the last item! */
    }
    printf("\n");
}

statusEnum insert(keyType key, recType *rec) {
    int i, newLevel;
    nodeType *update[MAXLEVEL+1];
    nodeType *x;
    count++;   
   /***********************************************
    *  allocate node for data and insert in list  *
    ***********************************************/
    printf("-insert-%d-\n",key);
    /* find where key belongs */
    /*从高层一直向下寻找，直到这层指针为NIL，也就是说  
    后面没有数据了，到头了，并且这个值不再小于要插入的值。
    记录这个位置，留着向其后面插入数据*/
    x = list.hdr;
    for (i = list.listLevel; i >= 0; i--) {
        while (x->forward[i] != NIL && compLT(x->forward[i]->key, key))
            x = x->forward[i];   
        update[i] = x;   
    }   

    /*现在让X指向第0层的X的后一个节点*/  
    x = x->forward[0];   

    /*如果相等就不用插入了*/  
    if (x != NIL && compEQ(x->key, key))    
        return STATUS_DUPLICATE_KEY;   

   /*随机的计算要插入的值的最高level*/ /* 这个随机函数一般或不太好 */
    for (newLevel = 0;rand() < RAND_MAX/2 && newLevel < MAXLEVEL;newLevel++);
        /*如果大于当前的level，则更新update数组并更新当前level*/  
        if (newLevel > list.listLevel) {   
            for (i = list.listLevel + 1; i <= newLevel; i++)   
                update[i] = NIL;   
            list.listLevel = newLevel;   
        }   
  
    /* 给新节点分配空间，分配newLevel个指针，则这个  
    节点的高度就固定了，只有newLevel。更高的层次将  
    不会再有这个值*/  
    if ((x = malloc(sizeof(nodeType) + newLevel*sizeof(nodeType *))) == 0)   
        return STATUS_MEM_EXHAUSTED;   
    x->key = key;   
    x->rec = *rec;   
  
    /* 给每层都加上这个值，相当于往链表中插入一个数*/  
    for (i = 0; i <= newLevel; i++) {   
        x->forward[i] = update[i]->forward[i];   
        update[i]->forward[i] = x;   
    }   

    return STATUS_OK;   
}   
  
statusEnum delete(keyType key) {   
    int i;   
    nodeType *update[MAXLEVEL+1], *x;   
  
   /*******************************************  
    *  delete node containing data from list  *  
    *******************************************/  
  
    /* find where data belongs */  
    x = list.hdr;   
    for (i = list.listLevel; i >= 0; i--) {   
        while (x->forward[i] != NIL    
          && compLT(x->forward[i]->key, key))   
            x = x->forward[i];   
        update[i] = x;   
    }   
    x = x->forward[0];
    if (x == NIL || !compEQ(x->key, key)) 
        return STATUS_KEY_NOT_FOUND;   
  
    /* adjust forward pointers */  
    for (i = 0; i <= list.listLevel; i++) {   
        if (update[i]->forward[i] != x) 
            break;   
        update[i]->forward[i] = x->forward[i];   
    }   
    free (x);
    /* adjust header level */
    while ((list.listLevel > 0)
    && (list.hdr->forward[list.listLevel] == NIL))   
        list.listLevel--;
  
    return STATUS_OK;
}

statusEnum find(keyType key, recType *rec) {   
    int i;   
    nodeType *x = list.hdr;   

   /*******************************
    *  find node containing data  *
    *******************************/

    /* 高效查找在这里体现 */
    for (i = list.listLevel; i >= 0; i--) {
        while (x->forward[i] != NIL && compLT(x->forward[i]->key, key))
            x = x->forward[i];
    }
    x = x->forward[0];
    if (x != NIL && compEQ(x->key, key)) {
        *rec = x->rec;   
        return STATUS_OK;   
    }   
    
    return STATUS_KEY_NOT_FOUND;
}

void initList() {
    int i;   
  
   /**************************
    *  initialize skip list  *
    **************************/

    if ((list.hdr = malloc(sizeof(nodeType) + MAXLEVEL*sizeof(nodeType *))) == 0) {
        printf ("insufficient memory (initList)\n");
        exit(1);
    }  
    for (i = 0; i <= MAXLEVEL; i++)
        list.hdr->forward[i] = NIL; /* 注意此处虽然数组越界，但是由于申请的连续内存则无碍 */
    list.listLevel = 0;
}

int main(int argc, char **argv) {
    int i, maxnum, random;
    recType *rec;
    keyType *key;
    statusEnum status;


    /* command-line:
     *  
     *   skl maxnum [random]
     *  
     *   skl 2000  
     *       process 2000 sequential records  
     *   skl 4000 r  
     *       process 4000 random records  
     *  
     */  
  
    maxnum = 20;   
    random = argc > 2;   
  
    initList();
  
    if ((rec = malloc(maxnum * sizeof(recType))) == 0) {   
        fprintf (stderr, "insufficient memory (rec)\n");/* 指向标准输出 */
        exit(1);   
    }   
    if ((key = malloc(maxnum * sizeof(keyType))) == 0) {   
        fprintf (stderr, "insufficient memory (key)\n");/* 指向标准输出 */
        exit(1);   
    }   
  
    if (random) {   
        /* fill "a" with unique random numbers */
        for (i = 0; i < maxnum; i++) key[i] = rand();
        printf ("ran, %d items\n", maxnum);
    } else {   
        for (i = 0; i < maxnum; i++) key[i] = i;
        printf ("seq, %d items\n", maxnum);
    }

    for (i = 0; i < maxnum; i++) {
        status = insert(key[i], &rec[i]);
        if (status) 
            printf("pt1: error = %d\n", status);
    }

   /**************************
    *  test skip list  *
    **************************/

    printf("the number of insert node is %d!\n",count);
    print_skip_list();

    for (i = maxnum-1; i >= 0; i--) {   
        status = find(key[i], &rec[i]);   
        if (status) printf("pt2: error = %d\n", status);   
    }   
  
    for (i = maxnum-1; i >= 0; i--) {   
        status = delete(key[i]);   
        if (status) printf("pt3: error = %d\n", status);   
    }
    
    return 0;
}  
