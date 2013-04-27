#include <iostream>  
#include <string>  
using namespace std;  
  
//颜沙，思路二之方案二，  
//July、updated，2011.04.16。  
void rotate(string &str, int m)  
{  
    if (str.length() == 0 || m < 0)  
        return;  
  
    //初始化p1，p2  
    int p1 = 0, p2 = m;     
    int n = str.length();  
  
    // 处理m大于n  
    if (m % n == 0)  
        return;  
      
    // 循环直至p2到达字符串末尾  
    while(true)  
    {    
        swap(str[p1], str[p2]);  
        p1++;  
        if (p2 < n - 1)  
            p2++;  
        else  
            break;  
    }  
      
    // 处理尾部，r为尾部循环左移次数  
    int r = m - n % m;  // r = 1.  
    while (r--)  //外循环执行一次  
    {  
        int i = p1;  
        char temp = str[p1];  
        while (i < p2)  //内循环执行俩次  
        {  
            str[i] = str[i+1];  
            i++;  
        }     
        str[p2] = temp;  
    }  
    //举一个例子  
    //abcdefghijk  
    //当执行到这里的时候，defghiabcjk  
    //      p1    p2  
    //defghi a b c j k，a 与 j交换，jbcak，然后，p1++，p2++  
    //        p1    p2  
    //       j b c a k，b 与 k交换，jkcab，然后，p1++，p2不动，  
      
    //r = m - n % m= 3-11%3=1，即循环移位1次。  
    //          p1  p2  
    //       j k c a b  
    //p1所指元素c实现保存在temp里，  
    //然后执行此条语句：str[i] = str[i+1]; 即a跑到c的位置处，a_b  
    //i++，再次执行：str[i] = str[i+1]，ab_  
    //最后，保存好的c 填入，为abc，所以，最终序列为defghi jk abc。  
    //July、updated，2011.04.17晚，送走了她。  
}  
  
int main()  
{  
    string ch="abcdefghijk";  
    rotate(ch,3);  
    cout<<ch<<endl;  
    return 0;     
}  
