//*****stack.h
#ifndef _STACK_H
#define _STACK_H
#define STACK_INIT_SIZE 100
#define STACKINCREMENT 10
typedef int Status;
template<class QElemType>

class stack
{
    public:
        void InitStack();
        void DestroyStack();
        void ClearStack();
        Status StackEmpty();
        Status StackLength();
        int GetTop(QElemType & e);
        void Push(QElemType e);
        int Pop(QElemType & e);
    private:
        struct SqStack{
            QElemType *base;
            QElemType *top;
            int stacksize;
        }S;
};
//******stack.cpp------
/*
    args:
    return:
    doc:初始化S
*/
template<class QElemType>
void stack<QElemType>::InitStack()
{
    S.base = (QElemType *)malloc(STACK_INIT_SIZE * sizeof(QElemType));
    if(!S.base) exit(0);
    S.top = S.base;
    S.stacksize = STACK_INIT_SIZE;
}
/*
    args:
    return:
    doc:释放S资源
*/
template <class QElemType>
void stack<QElemType>::DestroyStack()
{
    free(S.base);
}
/*
    args:
    return:
    doc:将S清为空栈
*/
template <class QElemType>
void stack<QElemType>::ClearStack()
{
    S.top = S.base;
}
/*
    args:
    return:
        0：为空栈
        1：不为空栈
    doc:判断S是否为空栈
*/
template <class QElemType>
Status stack<QElemType>::StackEmpty()
{
    if(S.top == S.base) 
        return 1;
    else 
        return 0;
}
/*
    args:
    return:栈的长度
    doc:获得栈的长度
*/
template <class QElemType>
Status stack<QElemType>::StackLength()
{
    return (S.top - S.base);
}
/*
    args:
        e:栈顶元素
    return:
        0：s为空栈
        1：s不为空栈
    doc:获得栈顶元素
*/
template <class QElemType>
int stack<QElemType>::GetTop(QElemType & e)
{
    if(S.top != S.base)
    {
        e = *(S.top - 1);
        return 1;
    }
    else 
        return 0;
}
/*
    args:
        e:将e进栈
    return:
    doc:插入元素e为新的栈顶元素
*/
template <class QElemType>
void stack<QElemType>::Push(QElemType e)
{
    if(S.top - S.base >= S.stacksize)
    {
        S.base = (QElemType *)realloc(S.base,(S.stacksize + STACKINCREMENT) * sizeof(QElemType));
        if(!S.base) exit(0);
        S.top = S.base + S.stacksize;
        S.stacksize += STACKINCREMENT;
    }
    *S.top++ = e;
}
/*
    args:
        e：弹出的栈顶元素
    return:
        0：s为空栈
        1：s不为空栈
    doc:删除s的栈顶元素，并用e返回其值
*/
template <class QElemType>
int stack<QElemType>::Pop(QElemType & e)
{
    if(S.top == S.base) 
        return 0;
    else
        e = * --S.top;
    return 1;
}
//**********stack.cpp
#endif     //stack.h ****
