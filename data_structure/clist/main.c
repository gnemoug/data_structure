#include <stdio.h>
#include <stdlib.h>
#include<string.h>
#include<time.h>
#include"clist.h"

typedef struct Email_ {
        char subject[1024];
        time_t  time_date;
        char from[64];
}Email;

/*static*/
void print_email_list(const CList *list) {

    CListElmt          *iter;

    int                size,
                        i;

    fprintf(stdout, "Email_list size is %d (circling twice)\n\n", clist_size(list));

    size = clist_size(list);
    iter = clist_head(list);
    i = 0;
    Email *email;

    while (i < size * 2) {
        email = clist_data(iter);
        fprintf(stdout, "email_list[%03d] =\nEmail {\nsubjet: %s,\nfrom: %s,\ntime_date: %d }\n\n",\
           (i % size), email->subject, email->from, (int) email->time_date);
        iter = clist_next(iter);
        i++;
    }
    return;
}



int main()
{
    Email eemail = {.subject = "this is a test demo", .from = "Thomas<youremail@domain>"};
    Email *email;
    CList email_list;
    clist_init(&email_list, free);

    CListElmt *iter;

    iter = clist_head(&email_list);
    int i = 0;
    fprintf(stdout, "...Insert ten emial objects\n");
    while(i < 10){
        if((email = (Email*)malloc(sizeof(Email))) == NULL )
            return 1;
        email->time_date = time(NULL);
        strncpy(email->subject, eemail.subject, 1023);
        strncpy(email->from, eemail.from, 63);

        fprintf(stdout,  "insert [%03d] item...\n", i);

        if(clist_ins_next(&email_list, iter, (void *)email ) != 0)
            return 1;
        if (iter == NULL)
            iter = clist_next(clist_head(&email_list));
        else
            iter = clist_next(iter);

        i++;
    }

    print_email_list(&email_list);

    for (i = 0; i < 15; i++)
      iter = clist_next(iter);
    email = clist_data(iter);
     fprintf(stdout, "remove after Email {\nsubjet: %s,\nfrom: %s,\ntime_date: %d }\n\n",\
            email->subject, email->from, (int)email->time_date);
    if (clist_rem_next(&email_list, iter, (void **)&email) != 0)
        return 1;
    free(email);
    print_email_list(&email_list);

    fprintf(stdout, "Destory Email circular list\n");
    clist_dealloc(&email_list);
    return 0;
}
