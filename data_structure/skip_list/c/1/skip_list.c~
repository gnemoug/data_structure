#include <stdlib.h>
#include <stdio.h>
#include <memory.h>
#include <pthread.h>
#include <time.h>
#include <math.h>
#include <limits.h>

#define TIME(A,B) (double)(B-A)/CLOCKS_PER_SEC*1000

/* Skip List Level Limit, Level begin wth 0 */
#define MAX_SKIP_LEVEL 20
/* Level Weight for Calc node level */
#define LEVEL_W 20

/* Skip List Struct */
typedef struct skip_list_struct skip_list_t;
struct skip_list_struct {
    int key;
    int value;
    int level;
    /* Level[i] have (i+1) pointer to */
    skip_list_t *forward[MAX_SKIP_LEVEL];
};

/* Rand Node Level  */
int rand_level() 
{
    int level = 0;
    int i = 0;

    /* Node which level more bigger, more less */
    for(; i< MAX_SKIP_LEVEL-1; ++i)
    //for(; i< MAX_SKIP_LEVEL; ++i) 这里不对，可能生成超过MAX_SKIP_LEVEL的数
    {
        level += rand()%(2*(LEVEL_W-1)) >= (LEVEL_W - 1) ? 1 : 0;
    }

    return level;   /* 0,1....MAX_SKIP_LEVEL-1 */
}

/* Make a new node and init it */
skip_list_t *init_skip_list_node (int level, int key, int value) 
{
    skip_list_t *node = (skip_list_t *)malloc(sizeof(skip_list_t));
    node->level = level;
    node->key = key;
    node->value = value;
    int i = 0;
    for (; i < MAX_SKIP_LEVEL; ++i)
    {
        node->forward[i] = NULL;
    }
 
    return node;
}

/* Insert or Update a value on Skip List */
int skip_list_write (skip_list_t *skip_list, int key, int value)
{
    skip_list_t *update_node[MAX_SKIP_LEVEL];/* point the insert positon of every level */
    skip_list_t *node = skip_list;
    int i = skip_list->level;

    for(; i>=0; --i)    /* find the insert positon of every level */
    {
        while (node->forward[i] != NULL && key > node->forward[i]->key)
        {
            node = node->forward[i];
        }
        update_node[i] = node;
    }
    node = node->forward[0] == NULL ? node : node->forward[0];
    if (key == node->key) /* find the node,change value */
    {
        node->value = value;
    }
    else    /* insert a node with the value*/
    {
        int level = rand_level();
        node = init_skip_list_node(level, key, value);
        for (i = 0; i <= level; ++i)
        {
            node->forward[i] = update_node[i]->forward[i];
            update_node[i]->forward[i] = node;
        }
    }
}

/* Delete a node on Skip List */
int skip_list_delete (skip_list_t* skip_list, int key)
{
    skip_list_t* update_node[MAX_SKIP_LEVEL];
    skip_list_t* node = skip_list;
    int i = skip_list->level;
    
    for(; i>=0; --i) 
    {
        while (node->forward[i]!= NULL && key> node->forward[i]->key) 
        {
            node= node->forward[i];
        }
        update_node[i]= node;
    }
    node = node->forward[0] == NULL ? node: node->forward[0];
    if (key == node->key) 
    {
        for (i = 0; i <= skip_list->level; ++i) 
        {
            if (update_node[i]->forward[i] != node)
            {
                break;
            }
            update_node[i]->forward[i] = node->forward[i];
        }
        free(node);
        
        return 0; // SUCCESS
    } 
    else 
    {
        return 1; // NO FOUND
    }
}

/* Search a key from Skip List */
int skip_list_search (skip_list_t* skip_list, int key)
{
    skip_list_t *node = skip_list;
    int level = node->level;
    int i = level;
    
    for (; i>= 0; --i) 
    {
        while (node->forward[i] != NULL && key > node->forward[i]->key) 
        {
            node = node->forward[i];
        }
    }
    node = node->forward[0] == NULL ? node : node->forward[0];
    if (key == node->key)
    {
        return node->value;
    }
    else
    { 
        return INT_MIN;
    }
}

/* print the key in every level */
int print_skip_list (skip_list_t *skip_list)
{
    skip_list_t *node;
    int i = 0;

    for(; i < MAX_SKIP_LEVEL; ++i) 
    {
        node = skip_list->forward[i];
        printf("Level[%d]: ", i);
        while(node != NULL) 
        {
            printf("%d -> ", node->key);
            node = node->forward[i];
        }
        printf("NULL\n");
    }
}
 
/* Free All Nodes */
int free_skip_list (skip_list_t* skip_list) 
{
    skip_list_t *node = skip_list->forward[0];
    skip_list_t *next_node;

    while (node != NULL)
    {
        next_node = node->forward[0];
        free(node);
        node = next_node;
    }
    
    free(skip_list);
}

int main(int argc, char *argv[])
{
    srand((unsigned)time(0));
    int count = 0;
    int i = 0;

    /* Function Test */
    printf("#### Function Test ####\n");

    count = 20;
    printf("== Init Skip List ==\n");

    /* INT_MIN is the min int value of c */
    skip_list_t *skip_list = init_skip_list_node(MAX_SKIP_LEVEL-1, INT_MIN, INT_MIN);
//skip_list_t* skip_list= init_skip_list_node(MAX_SKIP_LEVEL, INT_MIN, INT_MIN); 多了一层所以会越界
    for (i = 0; i<count; ++i) 
    {
        skip_list_write(skip_list, i, i);
    }

    printf("== Print Skip List ==\n");
    print_skip_list(skip_list);

    printf("== Search Key ==\n");
    for(i = 0; i<count; ++i) 
    {
        int key = rand()%(count+5);
        printf("Search [%d]: %d\n", key, skip_list_search(skip_list, key));
    }

    printf("== Delete Key ==\n");
    for(i = 0; i < count; ++i) 
    {
        int key = rand()%(count+5);
        printf("Delete [%d]: %s\n",key,skip_list_delete(skip_list, key) ? "NO FOUND" : "SUCCESS");
    }
 
    printf("== Print Skip List ==\n");
    print_skip_list(skip_list);
 
    /* Performance Test */
    printf("#### Performance Test ####\n");
    clock_t start, finish;  //使用计时函数，计算程序执行时间
    float time = 0;

    count = 1000000;
    printf("== Insert 10^6 Items (%d Level) ==\n", MAX_SKIP_LEVEL);
    start = clock();
    for(i = 0; i < count; ++i) 
    {
        skip_list_write(skip_list, i, i);
    }
    finish = clock();
    time = TIME(start, finish);
    printf ("Time: %f ms, Speed: %f Node/s\n", time, count/time*1000);
 
    printf("== Search 10^6 Items (%d Level) ==\n", MAX_SKIP_LEVEL);
    start = clock();
    for(i = 0; i<count; ++i) 
    {
        skip_list_search(skip_list, rand()%count);
    }
    finish = clock();
    time = TIME(start, finish);
    printf ("Time: %f ms, Speed: %f Node/s\n", time, count/time*1000);
 
    //free memory
    printf("#### Clear Memory ####\n");
    free_skip_list(skip_list);
 
    return 0;
}
