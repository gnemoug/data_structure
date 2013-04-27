#include "BiTree.h"

int main()
{
    BiTree tree;
    tree.set_front(-1);
    tree.set_rear(-1);
    tree.InorderCreate();
    
    tree.PrintBiTree();//树形打印T中元素

    cout << "前缀表达式为:";
    tree.PreOrder();//获取算术表达式的前缀表达式
    cout << endl;

    cout << "后缀表达式为:";
    tree.FllowUp();//获取算术表达式的后缀表达式
    cout << endl;

    cout << "值为:" << tree.Operate() << endl;//递归求解树表示的表达式的值

    tree.DestroyQueue();
    tree.DestroyTree();
    return 0;
}



