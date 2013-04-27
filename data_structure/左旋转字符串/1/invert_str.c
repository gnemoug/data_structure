#include <stdio.h>  
#include <string.h>  
  
char *invert(char *start, char *end)  
{
    char tmp, *ptmp = start;
    while (start != NULL && end != NULL && start < end)    
    {     
        tmp = *start;
        *start = *end;
        *end = tmp; 
        start ++;
        end --; 
    }
    
    return ptmp;
}

char *left(char *s, int pos)   //pos为要旋转的字符个数，或长度，下面主函数测试中，pos=3。  
{  
    int len = strlen(s);  
    invert(s, s + (pos - 1));  //如上，X->X^T，即 abc->cba  
    invert(s + pos, s + (len - 1)); //如上，Y->Y^T，即 def->fed  
    invert(s, s + (len - 1));  //如上，整个翻转，(X^TY^T)^T=YX，即 cbafed->defabc。  
    return s;
}  
  
int main()  
{     
    char s[] = "abcdefghij";
    puts(left(s, 3));  
    return 0;  
}  
