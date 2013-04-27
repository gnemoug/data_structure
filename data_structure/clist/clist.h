#ifndef CLIST_H
#define CLIST_H

#include<stdlib.h>

typedef struct CListElmt_{

    void        *data;

    struct CListElmt_        *next;

} CListElmt;


typedef struct CList_{
    int                 size;
    int                 (*cmp)(const void *, const void *);
    void                (*destroy)(void *);
    CListElmt           *head;
}CList;

void clist_init(
                CList *list,
                void (*destroy)(void *));

int clist_ins_next(
                CList *list,
                CListElmt *iter,
                const void *data);

int clist_rem_next(
                CList  *list,
                CListElmt * iter,
                void **data);

void clist_dealloc(CList *list);


#define clist_size(list) ((list)->size)
#define clist_head(list) ((list)->head)
#define clist_data(iter) ((iter)->data)
#define clist_next(iter) ((iter)->next)

#endif
