#ifndef _BITREE_H
#define _BITREE_H
#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <iomanip>
#include "stack.h"
using namespace std;

struct BiTreeNode
{
    char OPT[10];
    BiTreeNode *lchild,*rchild;
};
class BiTree
{
    public:
        int get_front();//获取变量front的值
        void set_front(int pfront);//设置变量front的值
        int get_rear();//获取变量rear的值
        void set_rear(int prear);//设置变量rear的值
        int IsEmpty();//判断rear是否等于front
        void EnQueue(BiTreeNode *p);//将节点地址放入Q中
        void DestroyQueue();//清空Q
        BiTreeNode * DeQueue();//获取Q中指定位置的节点内存地址
        int BiTreeEmpty(BiTreeNode *T);//判断T是否为空
        int BiTreeDepth(BiTreeNode *T);//获取T的深度
        int BiTreeDepth();//获取T的深度
        void PrintBiTree();//树形打印T中元素
        void PrintBiTree(BiTreeNode *T);//树形打印T中元素
        void InorderCreate();
        void InorderCreate(BiTreeNode *&T,char str[30][10],int start,int end);//递归构造表达式转化为的二叉树（利用栈）
        int compare(char a,char b);//定义了任意两个运算符的优先级
        int IsNumber(char a);//判断一个字符是否为数值形式的
        double Operate(BiTreeNode *T);//递归求解树表示的表达式的值
        double Operate();//调用Operate(BiTreeNode *T)递归求解树表示的表达式的值
        void PreOrder(BiTreeNode *T);//获取算术表达式的前缀表达式       
        void PreOrder();//调用PreOrder(BiTreeNode *T)获取算术表达式的前缀表达式 
        void FllowUp(BiTreeNode *T);//获取算术表达式的后缀表达式
        void FllowUp();//调用PreOrder(BiTreeNode *T)获取算术表达式的后缀表达式 
        void DestroyTree(BiTreeNode *T);//销毁一颗树
        void DestroyTree();//销毁T
    private:
        BiTreeNode *T;                       //T是根结点
        BiTreeNode *Q[40];
        int front;
        int rear;
};
/*
    args:
    return
        front:front的值
    doc:获取变量front的值
*/
int BiTree::get_front()
{
    return front;
}
/*
    args:
        pfront:设置front的值
    return
    doc:设置变量front的值
*/
void BiTree::set_front(int pfront)
{
    front = pfront;
}
/*
    args
    return
        rear：rear的值
    doc:获取变量rear的值
*/
int BiTree::get_rear()
{
    return rear;
}
/*
    args:
        prear:设置rear的值
    return
    doc:设置变量rear的值
*/
void BiTree::set_rear(int prear)
{
    rear = prear;
}
/*
    args
    return
        true:相等
        false:不等
    doc:判断rear是否等于front
*/
int BiTree::IsEmpty()
{
    return (front==rear);
}
/*
    args:
        p：要存入Q中的节点内存地址
    return
    doc:将节点地址放入Q中
*/
void BiTree::EnQueue(BiTreeNode *p)
{
    Q[++rear]=p;
}
/*
    args
    return
    doc:清空Q
*/
void BiTree::DestroyQueue()
{
    front=rear=-1;
}
/*
    args
    return：Q中指定位置的节点内存地址
    doc:获取Q中指定位置的节点内存地址
*/
BiTreeNode * BiTree::DeQueue()
{
    return IsEmpty()? NULL : Q[++front];
}
/*
    args:
        T：树的根节点
    return
        0：为空树
        1：不为空树
    doc:判断T是否为空
*/
int BiTree::BiTreeEmpty(BiTreeNode *T)
{
    if(T==NULL)
        return 0;
    else
        return 1;
}
/*
    args
    return
    doc:获取T的深度
*/
int BiTree::BiTreeDepth()
{
    return BiTreeDepth(T);
}
/*
    args:
        T:树的根节点
    return：树的深度
    doc:获取T的深度
*/
int BiTree::BiTreeDepth(BiTreeNode *T)
{
    int dl,dr,max;

    if(BiTreeEmpty(T))
    {
        dl=BiTreeDepth(T->lchild);
        dr=BiTreeDepth(T->rchild);
        max=dl>dr?dl:dr;
        return max+1;
    }
    else
        return 0;
}
/*
    args
    return
    doc:树形打印T中元素
*/
void BiTree::PrintBiTree()
{
    PrintBiTree(T);
}
/*
    args:
        T：树的根节点
    return
    doc:树形打印T中元素
*/
void BiTree::PrintBiTree(BiTreeNode *T)
{
    int i,k,j;
    int row=BiTreeDepth(T);
    BiTreeNode *p=T;

    EnQueue(p);

    for(i=0;i<row;i++)
    {
        cout << " ";

        for(k=0;k<pow(2,i);k++)
        {
            for(j=0;j<(pow(2,row-i-1)-1);j++){
                cout << setw(4);
                cout << "  ";
            }

            p=DeQueue();
            if(p){
                cout << setw(4);
                cout << p->OPT;
            }
                
            else{
                cout << setw(4);
                cout << " *";
            }

            if(!p)
            {
                EnQueue(NULL);
                EnQueue(NULL);
            }
            else
            {
                if(p->lchild)
                    EnQueue(p->lchild);
                else
                    EnQueue(NULL);
                
                if(p->rchild)
                    EnQueue(p->rchild);
                else
                    EnQueue(NULL);
            }        
            for(j=0;j<=(pow(2,row-i-1)-1);j++){
                cout << setw(4);
                cout << "  ";
            }
        }        
        cout << endl;
    }

}
/*
    args
    return
    doc:递归构造表达式转化为的二叉树（利用栈）
*/
void BiTree::InorderCreate()
{
    char OPT[30][10];
    cout << "请输入表达式:";
    char c = getchar();
    bool flag = true;
    int i = 0,j;
    while(c != 10)                          //输入的是空格
    {
        j = 0;
        if(c == '-' && flag == true)              //flag判断是否是一个负数的值
        {
            OPT[i][j++] = c;
            for(c = getchar();IsNumber(c);c = getchar())
                OPT[i][j++] = c;
            OPT[i++][j] = '\0';
            flag = false;
        }
        else if(IsNumber(c))
        {
            OPT[i][j++] = c;
            for(c = getchar();IsNumber(c);c = getchar())
                OPT[i][j++] = c;
            OPT[i++][j] = '\0';
            flag = false;
        }
        else                                           //运算符时的处理
        {
            flag = true;
            OPT[i][j++] = c;
            OPT[i++][j] = '\0';
            c = getchar();
        }
    }
    InorderCreate(T,OPT,0,i-1);
}

/*
    args
        T：树的根节点
        str:输入的表达式
        start:str中的起点
        end:str中的终点
    return
    doc:递归构造表达式转化为的二叉树（利用栈）
*/
void BiTree::InorderCreate(BiTreeNode *&T,char str[30][10],int start,int end)   //递归构造start,end分别是一个式子开始值和结束值的索引
{
    if(start == end)                                                           //递归终止
    {
        if(!(T = (BiTreeNode *)malloc(sizeof(BiTreeNode)))) exit(0);
        strcpy(T->OPT,str[start]);
        T->lchild = NULL;
        T->rchild = NULL;
    }
    else
    {
        stack<char> opt;
        stack<int> num;
        num.InitStack();
        opt.InitStack();
        char last;
        int index;
        int a;
        bool jump = false;
        for(int i = start;i <= end;i++)          //begin求解优先级最小的一个运算符
        {
            if(jump) break;
            if(IsNumber(str[i][0]) || (str[i][0] == '-' && IsNumber(str[i][1]))) 
                continue;
            else
            {
                char c = str[i][0];
                char b;
                if(i == start && c == '(') {start += 1;continue;}
                else if(opt.StackEmpty() || (opt.GetTop(b) && compare(b,c) == -1))
                {opt.Push(c);num.Push(i);}

                else
                {
                    if(c != ')')
                    {
                        opt.Pop(b);num.Pop(a);
                        if(!opt.StackEmpty())
                        {
                            opt.GetTop(b);
                            if(compare(b,c) == 1)
                            {
                                opt.Pop(b);num.Pop(a);
                                opt.Push(c);num.Push(i);
                            }
                            else
                            {opt.Push(c);num.Push(i);}
                        }
                        else
                        {opt.Push(c);num.Push(i);}
                    }
                    else
                    {
                        for(opt.GetTop(b);compare(b,c) != 0;opt.GetTop(b))
                        {
                            opt.Pop(b);num.Pop(a);
                            if(opt.StackEmpty()) 
                            {opt.Push(b);num.Push(a);end -= 1;jump = true;break;}
                        }
                        if(compare(b,c) == 0) {opt.Pop(b);num.Pop(a);}
                    }
                }
            }
        }                                                 //end，得到的是该步中的根结点字符last及其索引index
        opt.Pop(last);num.Pop(index);
        if(!opt.StackEmpty())
        {
            opt.Pop(last);num.Pop(index);
        }
        opt.DestroyStack();
        num.DestroyStack();
        if(!(T = (BiTreeNode *)malloc(sizeof(BiTreeNode)))) exit(0);
        T->OPT[0] = last;T->OPT[1] = '\0';
        InorderCreate(T->lchild,str,start,index-1);
        InorderCreate(T->rchild,str,index+1,end);
    }
}
/*
    args:
        a:字符a
        b:字符b：
    return
        0：优先级相等
        1：a比b优先级高
        -1：a比b优先级低
    doc:定义了任意两个运算符的优先级
*/
int BiTree::compare(char a,char b)
{ //1表示栈顶优先级高于待入栈的元素
    if(a == '(' && b == ')') return 0;
     else if((a == '+' && b == '*') || (a == '+' && b == '/') 
        || (a == '-' && b == '*') || (a == '-' && b == '/') 
        || (a != ')' && b == '(') || (a == '(' && b != ')'))
        return -1;
    else return 1;
}
/*
    args:
        a:要判断的char
    return
        0：数值形式
        1：char形式
    doc:判断一个字符是否为数值形式的
*/
int BiTree::IsNumber(char a)
{
    if(a == '.') return 1;
    for(int i = 0;i < 10;i++)
        if(a-'0' == i) return 1;
        return 0;
}
/*
    args:
        T：要计算的运算表达式的树的根节点
    return
    doc:获取变量front的值
*/
double BiTree::Operate(BiTreeNode *T)
{
    if(T->lchild==NULL && T->rchild==NULL)
    {
        double num = atof(T->OPT);//把字符串转化成浮点数
        return num;
    }
    double ld,rd;
    ld = Operate(T->lchild);
    rd = Operate(T->rchild);
    char c = T->OPT[0];
    switch(c)
    {
        case '+': return ld+rd;break;
        case '-': return ld-rd;break;
        case '*': return ld*rd;break;
        case '/': return ld/rd;break;
    }
}
/*
    args:
    return
    doc:调用Operate(BiTreeNode *T)递归求解树表示的表达式的值
*/
double BiTree::Operate()
{
    return Operate(T);
}
/*
    args:
        T：要前序遍历的树的根节点
    return
    doc:获取算术表达式的前缀表达式 
*/
void BiTree::PreOrder(BiTreeNode *T)
{
    if (T==NULL)  
        return;  
  
    cout << T->OPT << " ";
    
    if (T->lchild!=NULL)//遍历左子树  
        PreOrder(T->lchild);  
  
    if (T->rchild!=NULL)//遍历右子树  
        PreOrder(T->rchild);
}
/*
    args
    return
    doc:调用PreOrder(BiTreeNode *T)获取算术表达式的前缀表达式 
*/
void BiTree::PreOrder()
{
    PreOrder(T);
}
/*
    args:
        T：要后序遍历的树的根节点
    return
    doc:获取算术表达式的后缀表达式  
*/
void BiTree::FllowUp(BiTreeNode *T)
{
    if (T==NULL)  
        return;  
    
    if (T->lchild!=NULL)//遍历左子树  
        FllowUp(T->lchild);  
  
    if (T->rchild!=NULL)//遍历右子树  
        FllowUp(T->rchild);

    cout << T->OPT << " ";
}
/*
    args
    return
    doc:调用PreOrder(BiTreeNode *T)获取算术表达式的后缀表达式
*/
void BiTree::FllowUp()
{
    FllowUp(T);
}
/*
    args:
        T:要销毁的树的根节点
    return
    doc:销毁一颗树
*/
void BiTree::DestroyTree(BiTreeNode *T)
{
    if(T)
    {
        DestroyTree(T->lchild);
        DestroyTree(T->rchild);
        free(T);
    }
}
/*
    args
    return
    doc:销毁T
*/
void BiTree::DestroyTree()
{
    DestroyTree(T);
}

#endif
