#ifndef AVLTREE_H
#define AVLTREE_H

#include <iostream>
#include <queue>
#include <iomanip> 
#include "AvlNode.h"

using namespace std;

template <class T>
class AvlTree{
public:
       AvlTree():root(NULL){}
       AvlNode<T>* getRoot() const{return root;}

       bool Insert(T x){ bool taller = false; return Insert(root,x,taller ); }
       bool Delete(T x){ bool shorter = false; return Delete(root,x,shorter); }

       void PrintTree() const{PrintTree(root,0);}
       void PrintTreeLevel() const{PrintTreeLevel(root);}
       void PrintTreePre() const{PrintTreePre(root);}   
       void PrintTreePost() const{PrintTreePost(root);}              
       void PrintTreeIn() const{PrintTreeIn(root);}       
private:
        AvlNode<T> *root;

        bool Insert(AvlNode<T> *& sRoot,T x,bool &taller);
        bool Delete(AvlNode<T> *& sRoot,T x,bool &shorter);

        void RotateLeft(AvlNode<T> * &sRoot);
        void RotateRight(AvlNode<T> * &sRoot);

        void RightBalanceAfterInsert(AvlNode<T> * &sRoot,bool &taller);
        void LeftBalanceAfterInsert(AvlNode<T> * &sRoot,bool &taller);
        void RightBalanceAfterDelete(AvlNode<T> * &sRoot,bool &shorter);
        void LeftBalanceAfterDelete(AvlNode<T> * &sRoot,bool &shorter);

        void PrintTree(AvlNode<T> *t,int layer) const;
        void PrintTreeLevel(AvlNode<T> *t) const;
        void PrintTreePre(AvlNode<T> *t) const;        
        void PrintTreePost(AvlNode<T> *t) const;                
        void PrintTreeIn(AvlNode<T> *t) const;                  
};

template <typename T>
//左旋函数 
void AvlTree<T>::RotateLeft(AvlNode<T> * &sRoot){
     if( (sRoot == NULL) || (sRoot->right == NULL) ) return;
     
     AvlNode<T> *temp = new AvlNode<T>(sRoot->data);
     if(temp == NULL ) return;
     
     temp->left = sRoot->left;
     sRoot->left = temp;
     temp->right = sRoot->right->left;
     AvlNode<T> *toDelete = sRoot->right;
     sRoot->data = toDelete->data;     
     sRoot->right = toDelete->right;
     
     delete toDelete;
}

template <typename T>
//右旋函数 
void AvlTree<T>::RotateRight(AvlNode<T> * &sRoot){
     if( (sRoot == NULL) || (sRoot->left == NULL) ) return;
     
     AvlNode<T> *temp = new AvlNode<T>(sRoot->data);
     if(temp == NULL ) return;
     
     temp->right = sRoot->right;
     sRoot->right = temp;
     temp->left = sRoot->left->right;
     AvlNode<T> *toDelete = sRoot->left;
     sRoot->data = toDelete->data;
     sRoot->left = toDelete->left;
     
     delete toDelete;
}

template <typename T>
void AvlTree<T>::RightBalanceAfterInsert(AvlNode<T> *&sRoot,bool &taller){
    //如果插入节点后,sRoot的右高度增加引起不平衡，则调用此函数，使树重新平衡
    if( (sRoot == NULL) || (sRoot->right == NULL) ) return;
    AvlNode<T> *rightsub = sRoot->right,*leftsub;
    switch(rightsub->balance){
        case 1:
            sRoot->balance = rightsub->balance = 0;
            RotateLeft(sRoot);
            taller = false; break;
        case 0:
            cout<<"树已经平衡化."<<endl; break;
        case -1:
            leftsub = rightsub->left;
            switch(leftsub->balance){
                case 1:
                    sRoot->balance = -1; rightsub->balance = 0; break;
                case 0:
                    sRoot->balance = rightsub->balance = 0; break;
                case -1:
                    sRoot->balance = 0; rightsub->balance = 1; break;
            }
            leftsub->balance = 0;
            RotateRight(rightsub);
            RotateLeft(sRoot);
            taller = false; break;
    }
}

template <typename T>
void AvlTree<T>::LeftBalanceAfterInsert(AvlNode<T> *&sRoot,bool &taller){
    //如果插入节点后,sRoot的左高度增加,引起不平衡，则调用此函数，使树重新平衡
    AvlNode<T> *leftsub = sRoot->left,*rightsub;
    switch(leftsub->balance){
        case -1:
            sRoot->balance = leftsub->balance = 0;
            RotateRight(sRoot);
            taller = false; break;
        case 0:
            cout<<"树已经平衡化."<<endl; break;
        case 1:
            rightsub = leftsub->right;
            switch(rightsub->balance){
                case -1:
                    sRoot->balance = 1; leftsub->balance = 0; break;
                case 0:
                    sRoot->balance = leftsub->balance = 0; break;
                case 1:
                    sRoot->balance = 0; leftsub->balance = -1; break;
            }
            rightsub->balance = 0;
            RotateLeft(leftsub);
            RotateRight(sRoot);
            taller = false; break;
    }
}

template <typename T>
void AvlTree<T>::RightBalanceAfterDelete(AvlNode<T> * &sRoot,bool &shorter){
    //如果删除节点后，sRoot的左高度减少，引起不平衡，则调用此函数，使树重新平衡
    AvlNode<T> *rightsub = sRoot->right,*leftsub;
    switch(rightsub->balance){
        case 1: sRoot->balance = sRoot->balance = 0; RotateLeft(sRoot); break;
        case 0: sRoot->balance = 0; rightsub->balance = -1; RotateLeft(sRoot); break;
        case -1:
            leftsub = rightsub->left;
            switch(leftsub->balance){
                case -1: sRoot->balance = 0; rightsub->balance = 1; break;
                case 0: sRoot->balance = rightsub->balance = 0; break;
                case 1: sRoot->balance = -1; rightsub->balance = 0; break;
            }
            leftsub->balance = 0;
            RotateRight(rightsub);
            RotateLeft(sRoot);
            shorter = false; break;
    }
}

template <typename T>
void AvlTree<T>::LeftBalanceAfterDelete(AvlNode<T> * &sRoot,bool &shorter){
    //如果删除节点后，sRoot的右高度减少，引起不平衡，则调用此函数，使树重新平衡
    AvlNode<T> *leftsub = sRoot->left,*rightsub;
    switch(leftsub->balance){
        case 1: sRoot->balance = sRoot->balance = 0; RotateRight(sRoot); break;
        case 0: sRoot->balance = 0; leftsub->balance = -1; RotateRight(sRoot); break;
        case -1:
            rightsub = leftsub->right;
            switch(rightsub->balance){
                case -1: sRoot->balance = 0; leftsub->balance = 1; break;
                case 0: sRoot->balance = leftsub->balance = 0; break;
                case 1: sRoot->balance = -1; leftsub->balance = 0; break;
            }
            rightsub->balance = 0;
            RotateLeft(leftsub);
            RotateRight(sRoot);
            shorter = false; break;
    }
}

template <typename T>
bool AvlTree<T>::Insert(AvlNode<T> *& sRoot,T x,bool &taller){
    //递归函数,从sRoot这棵树寻找合适的位置,插入值为x的节点 
    bool success;
    if ( sRoot == NULL ) {//函数的出口,从叶节点插入 
       sRoot = new AvlNode<T>(x);
       success = sRoot != NULL ? true : false;
       if ( success ) taller = true;
    }
    else if ( x < sRoot->data ) {//如果x的值小于sRoot的值
        
       //Insert的递归调用,从sRoot的左子树寻找合适的位置插入 
       success = Insert ( sRoot->left, x, taller );
       if ( taller ){//如果插入后使得sRoot的左高度增加 
             switch ( sRoot->balance ) {
                case -1 : LeftBalanceAfterInsert( sRoot, taller ); break;
                case 0 : sRoot->balance = -1; break;
                case 1 : sRoot->balance = 0; taller = false; break; 
            }      
        }
    }
    else if ( x > sRoot->data ) {//如果x的值大于sRoot的值
    
       //Insert的递归调用,从sRoot的右子树寻找合适的位置插入 
       success = Insert ( sRoot->right, x, taller );
       
       if ( taller ){//如果插入后使得sRoot的右高度增加 
          switch ( sRoot->balance ) {              
            case -1 : sRoot->balance = 0; taller = false; break;
            case 0 : sRoot->balance = 1; break; 
            case 1 : RightBalanceAfterInsert( sRoot, taller ); break;
        }
     }
    }
    return success;    
}

template <typename T>
bool AvlTree<T>::Delete(AvlNode<T> *& sRoot,T x,bool &shorter){
    //递归函数,从sRoot这棵子树寻找值为x的节点，并删除之. 
    bool success = false;
    if(sRoot == NULL) return false; //空树，操作失败 
    if(x == sRoot->data) {//如果sRoot就是要删除的节点 
        if(sRoot->left != NULL && sRoot->right != NULL) {//如果sRoot有个子女
        
            //寻找 sRoot的中序遍历的前驱节点,用r表示 
            AvlNode<T> *r = sRoot->left;
            while(r->right != NULL) {
                 r = r->right;
            }
            
            //交换sRoot和r的值 
            T temp = sRoot->data;
            sRoot->data = r->data;
            r->data = temp;
            
            //递归函数调用,从sRoot的左子树寻找值为x的节点，并删除之.
            success = Delete(sRoot->left, x, shorter);
            if(shorter) {//如果删除后引起sRoot的左高度减少
                switch(sRoot->balance) {
                    case -1: sRoot->balance = 0; break;
                    case 0: sRoot->balance = 1; shorter = 0; break;
                    case 1: RightBalanceAfterDelete(sRoot, shorter);break;
                }
            }
        }
        else {//sRoot最多只有一个子女,这是递归的出口 
             AvlNode<T> *p = sRoot;
             sRoot = sRoot->left != NULL ? sRoot->left : sRoot->right;//令sRoot指向它的子女 
             delete p;//释放原来sRoot所占的内存空间 
             success = true;
             shorter = true;
        }
    }

    else if(x < sRoot->data) {
        //递归函数调用,从sRoot的左子树寻找值为x的节点，并删除之.
        success = Delete(sRoot->left, x, shorter);
        if(shorter) {//如果删除后引起sRoot的左高度减少
            switch(sRoot->balance) {
                case -1: sRoot->balance = 0; break;
                case 0: sRoot->balance = 1; shorter = 0; break;
                case 1: RightBalanceAfterDelete(sRoot, shorter); break;
            }
        }
    }

    else if(x > sRoot->data) {
        //递归函数调用,从sRoot的右子树寻找值为x的节点，并删除之.
        success = Delete(sRoot->right, x, shorter);
        if(shorter) {//如果删除后引起sRoot的右高度减少
            switch(sRoot->balance) {
                case -1: LeftBalanceAfterDelete(sRoot, shorter); break;
                case 0: sRoot->balance = -1; shorter = 0; break;
                case 1: sRoot->balance = 0; break;
            }
        }
    }
    return success;
}


template <typename T>
void AvlTree<T>::PrintTree(AvlNode<T> *t,int layer) const{
    if(t == NULL ) return;
    if(t->right) PrintTree(t->right,layer+1);
    for(int i =0;i<layer;i++) cout<<"    ";
    cout<<t->data<<endl;
    if(t->left) PrintTree(t->left,layer+1);
}
template <typename T>
void AvlTree<T>::PrintTreeLevel(AvlNode<T> *t) const{
     if(t == NULL) return;
     queue<AvlNode<T>*> NodeQueue;
     AvlNode<T> *node;
     NodeQueue.push(t);
     while(!NodeQueue.empty()){
        node = NodeQueue.front();
        NodeQueue.pop();
        cout<<node->data<<",";
        if(node->left != NULL) NodeQueue.push(node->left);
        if(node->right != NULL) NodeQueue.push(node->right);                               
    }
}

template <typename T>
void AvlTree<T>::PrintTreePre(AvlNode<T> *t) const{
     if(t){
          cout<<t->data<<",";
          PrintTreePre(t->left);
          PrintTreePre(t->right);     
     }
}

template <typename T>
void AvlTree<T>::PrintTreePost(AvlNode<T> *t) const{
     if(t){
          PrintTreePost(t->left);
          PrintTreePost(t->right);     
          cout<<t->data<<",";
     }
}

template <typename T>
void AvlTree<T>::PrintTreeIn(AvlNode<T> *t) const{
     if(t){
          PrintTreeIn(t->left);
          cout<<t->data<<",";     
          PrintTreeIn(t->right);     
     }
}
#endif //AVLsRoot_H
