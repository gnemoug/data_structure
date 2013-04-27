#include <stdio.h>

int string_comp(char* s1, char* s2)
{
    char* p1 = s1;
    char* p2 = s2;
    while(*p1!='\0' && *p2!='\0')
    {
        if(*p1>*p2)
        {
            return 1;
        }else if(*p1<*p2)
        {
            return -1;
        }else
        {
            p1++;
            p2++;
        }
    }
    // Length
    if(*p1=='\0' && *p2!='\0')
    {
        return -1;
    }else if(*p1!='\0' && *p2=='\0')
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

void string_copy(char* src, char* dst)
{
    while(*src!='\0')
    {
        *dst++ = *src++;
    }
    *dst = '\0';
}

// Append s2 to s1
void string_concat(char* s1, char* s2)
{
    // Go to end of s1
    while(*s1!='\0')
    {
        s1++;
    }
    // Copy s2
    while(*s2!='\0')
    {
        *s1++ = *s2++;
    }
    // End
    *s1 = '\0';
}

int string_length(char* s)
{
    int len = 0;
    
    while(*s!='\0')
    {
        s++;
        len++;
    }
    
    return len;
}

int main()
{
    char* s1 = "Liheyuanxx";
    char* s2 = "liheyuan";
    char buf[1024];
    printf("string_comp:%d\n", string_comp(s1, s2));
    string_copy(s1, buf);
    printf("copy result:%s\n", buf);
    string_concat(buf, s2);
    printf("concat result:%s\n", buf);
    printf("length:%d\n", string_length(buf));
    return 0;
}
