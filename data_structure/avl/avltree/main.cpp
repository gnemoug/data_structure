#include <iostream>
#include <stdlib.h>
#include "AvlTree.h"
//#include "BTree.h"
//#include "BSTree.h"
using namespace std;
int main(){
    AvlTree<int> l;
    for(int i = 1 ; i <= 15 ; i++){
        l.Insert(i);
    }
    l.PrintTree();
    while(true){
        int toDelete;
        cout<<"请输入要删除节点的值:"<<endl;
        cin>>toDelete;
        l.Delete(toDelete);
        cout<<"删除后的树为:"<<endl;
        l.PrintTree();
    }
    return 0;
    system("PAUSE");
}
