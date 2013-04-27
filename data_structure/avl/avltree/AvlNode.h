#ifndef AVLNODE_H
#define AVLNODE_H
#include <iostream>
using namespace std;

template <class T> class AvlTree; //声明AvlTree类

template <class T>
class AvlNode{
public:
       friend class AvlTree<T>;//友元类
        
      //构造函数
      AvlNode():left(NULL),right(NULL),balance(0){};
      AvlNode(const T& e,AvlNode<T> *lt = NULL,AvlNode<T> *rt = NULL):data(e),left(lt),right(rt),balance(0){};

      int getBalance() const{return balance;}
      AvlNode<T>* getLeft() const{return left;}
      AvlNode<T>* getRight() const{return right;}
      T getData() const{return data;}
private:
      T data;    //节点的值
      AvlNode *left;    //左孩子
      AvlNode *right;    //有孩子
      int balance;        //平衡因子,右子树的高度减去左子树的高度
};
#endif //AVLNODE_H
