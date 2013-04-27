#include <stdio.h>
#include <stdlib.h>
#include "dbDomain.h"

int main()
{
    struct timeval now_time;
    struct timeval after_time;
    unsigned char flags = 3;
    result_t res;
    char *info = NULL;
    char name_buf[256];

    unsigned int ip;
    unsigned int rip;

    InitializeSearchTree();
    printf("Input the URL:");

    scanf("%s", name_buf);

    res = SearchDomainName(name_buf, &flags, &info);
    printf("Resalt: %d\n", res);
    printf("Resalt: %d\n",flags );
    printf("Resalt: %s\n",info );
    return 0;
}
