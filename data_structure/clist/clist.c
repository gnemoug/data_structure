#include<stdlib.h>
#include<string.h>
#include"clist.h"

void clist_init(
                CList *list,
                void (*destroy)(void *))
{
    list->size      = 0;
    list->destroy   = destroy;
    list->head      = NULL;
}

int clist_ins_next(
                CList *list,
                CListElmt *iter,
                const void *data)
{
    CListElmt *new_element ;
    if((new_element = (CListElmt*)malloc(sizeof(CListElmt))) == NULL)
        return -1;

    new_element->data = (void *)data;

    //insert when circular list is empty
    if(clist_size(list) == 0)
    {
        new_element->next = new_element;
        list->head = new_element;
    } else {
        new_element->next = iter->next;
        iter->next = new_element;
    }

    list->size++;
    return 0;
}

int clist_rem_next(
                CList  *list,
                CListElmt * iter,
                void **data)
{
    CListElmt *old_element;

    if(clist_size(list) == 0)
        return -1;
    *data = iter->next->data;
    if(iter == iter->next){
        old_element = iter;
        list->head = NULL;
    } else {
        old_element = iter->next;
        iter->next = old_element->next;
        if (old_element == clist_head(list))
            list->head = old_element->next;
    }

    free(old_element);
    list->size--;
    return 0;

}

void clist_dealloc(CList *list)
{
    void *data;
    while(clist_size(list) > 0) {
        if(clist_rem_next(list, list->head,(void **)&data) == 0 && list->destroy != NULL)
                list->destroy(data);
    }
    memset(list, 0, sizeof(CList));
    return ;
}
