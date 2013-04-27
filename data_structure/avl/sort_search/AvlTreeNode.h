#if !defined(_AVLTREENODE_H_)
#define _AVLTREENODE_H_

#include <assert.h>
#include "Comparable.h"

#if !defined(NULL)
#define NULL 0
#endif

class AvlTreeNode : public Comparable
{
   public :
      enum { TREE_MAX_HEIGHT = 33 };

      typedef int balance_state;
      typedef enum _probe_result
      {
         FOUND,
         NOT_FOUND,
         FULL
      }probe_result;

      class ProbePath//for probe some specific node
      {
         friend class AvlTreeNode;

         private :
            AvlTreeNode* m_pRoot;
            int m_nStackTop;
            AvlTreeNode** m_arppNodeStack[TREE_MAX_HEIGHT];
            int m_arnDirStack[TREE_MAX_HEIGHT];
            probe_result m_eResult;
            const Comparable* m_pComparable;

         public :
            AvlTreeNode* Access();
      };

      class TraversePath//for traverse the avltree
      {
         friend class AvlTreeNode;

         private :
            int m_nStackTop;
            AvlTreeNode* m_arpNodeStack[TREE_MAX_HEIGHT];
      };

   public :
      static const int LEFT;
      static const int RIGHT;
      static const int BALANCED;

   protected :
      balance_state m_nState;
      AvlTreeNode* m_pChild[2];
   
   public :
        AvlTreeNode();
      virtual ~AvlTreeNode();

      //Search a node in the tree. After calling 'Probe', you can call other tree-operation functions.with the 'ProbePath' object returned.
      probe_result Probe(const Comparable* pComparable, ProbePath* pPath);

      //Insert a node into the tree.If a node with same value already exist or the tree is full, this function does nothing.
      AvlTreeNode* Insert(AvlTreeNode* pInsert);
      
      //Initialize 'TraversePath' In order to traver the tree, function call to 'InitTraverse' must be made before begining to call 'Traverse'.
      void InitTraverse(TraversePath* pPath);

      //Traverse tree nodes in order.
      AvlTreeNode* Traverse(TraversePath* pPath);

   protected :
      //rotate the binarytre
      bool Rotate(AvlTreeNode** ppThis, int n);
};

/*
 * args:
 * return:
 * doc:the constructor of the AvlTreeNode
 *
 */
inline AvlTreeNode::AvlTreeNode() 
: m_nState(BALANCED)
{
    m_pChild[LEFT] = NULL;
    m_pChild[RIGHT] = NULL;
}
/*
 * args:
 * return:
 * doc:the destructor of the AvlTreeNode
 *
 */
inline AvlTreeNode::~AvlTreeNode()
{

}

/*
 * args:
 * return:the pointer point to the finded node
 * doc:get the finded node
 *
 */
inline AvlTreeNode* AvlTreeNode::ProbePath::Access()
{
    return (m_eResult == FOUND) ? *m_arppNodeStack[m_nStackTop - 1] : NULL;
}
#endif
