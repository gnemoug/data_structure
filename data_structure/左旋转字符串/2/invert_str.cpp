//copyright@July、颜沙  
//最终代码，July，updated again，2011.04.17。  
#include <iostream>  
#include <string>  

using namespace std;  
  
void rotate(string &str, int m)  
{  
      
    if (str.length() == 0 || m <= 0)  
        return;  
      
    int n = str.length();  
      
    if (m % n <= 0)  
        return;  
      
    int p1 = 0, p2 = m;  
    int k = (n - m) - n % m;  
      
    // 交换p1，p2指向的元素，然后移动p1，p2  
    while (k --)   
    {  
        swap(str[p1], str[p2]);//c++有现成的swap函数
        p1++;  
        p2++;  
    }  
      
    // 重点，都在下述几行。  
    // 处理尾部，r为尾部左移次数  
    int r = n - p2;  
    while (r--)  
    {  
        int i = p2;  
        while (i > p1)  
        {  
            swap(str[i], str[i-1]);  
            i--;  
        }  
        p2++;  
        p1++;  
    }  
    //比如一个例子，abcdefghijk  
    //                    p1    p2  
    //当执行到这里时，defghi a b c j k  
    //p2+m出界 了，  
    //r=n-p2=2，所以以下过程，要执行循环俩次。  
      
    //第一次：j 步步前移，abcjk->abjck->ajbck->jabck  
    //然后，p1++，p2++，p1指a，p2指k。  
    //               p1    p2  
    //第二次：defghi j a b c k  
    //同理，此后，k步步前移，abck->abkc->akbc->kabc。  
}  
  
int main()     
{     
    string ch="abcdefghijk";     
    rotate(ch,3);     
    cout<<ch<<endl;     
    return 0;        
}    
