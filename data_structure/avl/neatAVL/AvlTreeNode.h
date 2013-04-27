#if !defined(_AVLTREENODE_H_)
#define _AVLTREENODE_H_

#include <assert.h>
#include "Comparable.h"

#define verify(exp)    assert(exp)

#if !defined(NULL)
#define NULL      0
#endif

class AvlTreeNode : public Comparable
{
   public :
      enum { TREE_MAX_HEIGHT = 33 };

      typedef int    balance_state;
      typedef enum   _probe_result
      {
         FOUND, 
         NOT_FOUND, 
         FULL
      }probe_result;

      class ProbePath
      {
         friend class AvlTreeNode;

         private :
            AvlTreeNode*               m_pRoot;
            int                        m_nStackTop;
            AvlTreeNode**              m_arppNodeStack[TREE_MAX_HEIGHT];
            int                        m_arnDirStack[TREE_MAX_HEIGHT];
            probe_result               m_eResult;
#if !defined(NDEBUG)
            const Comparable*          m_pComparable;
#endif

         public :
            AvlTreeNode*   Access();
      };

      class TraversePath
      {
         friend class AvlTreeNode;

         private :
            int                        m_nStackTop;
            AvlTreeNode*               m_arpNodeStack[TREE_MAX_HEIGHT];
      };

   public :
      static const int     LEFT;
      static const int     RIGHT;
      static const int     BALANCED;

   protected :
      balance_state  m_nState;
      AvlTreeNode*   m_pChild[2];
   
   public :
                     AvlTreeNode();
      virtual        ~AvlTreeNode();

      /* 
       * Probe
       *    Search a node in the tree.
       * <Parameter>
       *    pComparable : [in] A pointer to a 'Comparable' object to be searched.
       * <Return>
       *    'FOUND' if the node was found, if not 'NOT_FOUND'. In case the tree is 
       *    full, return value is 'FULL'.
       * <Remarks>
       *    After calling 'Probe', you can call other tree-operation functions 
       *    with the 'ProbePath' object returned.
       */
      probe_result   Probe(const Comparable* pComparable, ProbePath* pPath);

      /* 
       * Insert(1)
       *    Insert a node into the tree.
       * <Parameter>
       *    pInsert : [in] A pointer to a node to be inserted.
       * <Return>
       *    A pointer to the root node. Node insertion sometimes causes change 
       *    of the root node.
       * <Remarks>
       *    If a node with same value already exist or the tree is full, this 
       *    function does nothing.
       */
      AvlTreeNode*   Insert(AvlTreeNode* pInsert);

      /* 
       * Insert(2)
       *    Insert a node into the tree.
       * <Parameter>
       *    pPath   : [in] A pointer 'ProbePath' object which was returned from 
       *              previous 'Probe' function call.
       *    pInsert : [in] A pointer to a node to be inserted.
       * <Return>
       *    A pointer to the root node. Node insertion sometimes causes change 
       *    of the root node.
       * <Remarks>
       *    If a node with same value already exist or the tree is full, this 
       *    function does nothing.
       *    If you have done probing already, call this function rather than 
       *    'Insert(1)' to get better performance.
       */
      AvlTreeNode*   Insert(ProbePath* pPath, AvlTreeNode* pInsert);

      /* 
       * Remove(1)
       *    Remove a node from the tree.
       * <Parameter>
       *    pComparable : [in] A pointer to 'Comparable' object to find.
       *    ppRemoved   : [out] A pointer to 'AvlTreeNode*' that receives a node 
       *                  removed.
       * <Return>
       *    A pointer to the root node. Node removal sometimes causes change 
       *    of the root node.
       * <Remarks>
       *    If a node with same value does not exist, this function does nothing
       *    and '*ppRemoved' points null.
       */
      AvlTreeNode*   Remove(Comparable* pComparable, AvlTreeNode** ppRemoved);

      /* 
       * Remove(2)
       *    Remove a node from the tree.
       * <Parameter>
       *    pPath     : [in] A pointer 'ProbePath' object which was returned from 
       *                previous 'Probe' function call.
       *    ppRemoved : [out] A pointer to 'AvlTreeNode*' that receives a node 
       *                removed.
       * <Return>
       *    A pointer to the root node. Node removal sometimes causes change 
       *    of the root node.
       * <Remarks>
       *    If a node with same value does not exist, this function does nothing
       *    and '*ppRemoved' points null.
       *    If you have done probing already, call this function rather than 
       *    'Remove(1)' to get better performance.
       */
      AvlTreeNode*   Remove(ProbePath* pPath, AvlTreeNode** ppRemoved);

      /* 
       * Replace(1)
       *    Replace a node in the tree with new node.
       * <Parameter>
       *    pComparable : [in] A pointer to 'Comparable' object to find.
       *    ppReplace   : [in/out] A pointer to 'AvlTreeNode*' which is used to 
       *                  replace with and this pointer will be updated with a 
       *                  pointer to a node removed when finished.
       * <Return>
       *    A pointer to the root node. Replace operation does not cause change
       *    of the root. However, in order to keep consistancy with other 
       *    functions, this function return the root node.
       * <Remarks>
       *    If a node with same value does not exist, this function does nothing.
       */
      AvlTreeNode*   Replace(Comparable* pComparable, AvlTreeNode** ppReplace);

      /* 
       * Replace(2)
       *    Replace a node in the tree with new node.
       * <Parameter>
       *    pPath     : [in] A pointer 'ProbePath' object which was returned from 
       *                previous 'Probe' function call.
       *    ppReplace : [in/out] A pointer to 'AvlTreeNode*' which is used to 
       *                replace with and this pointer will be updated with a 
       *                pointer to a node removed when finished.
       * <Return>
       *    A pointer to the root node. Replace operation does not cause change
       *    of the root. However, in order to keep consistancy with other 
       *    functions, this function return the root node.
       * <Remarks>
       *    If a node with same value does not exist, this function does nothing.
       *    If you have done probing already, call this function rather than 
       *    'Replace(1)' to get better performance.
       */
      AvlTreeNode*   Replace(ProbePath* pPath, AvlTreeNode** ppReplace);

      /* 
       * GetMaxNode
       *    Get the maximum value node in the tree.
       * <Parameter>
       *    None.
       * <Return>
       *    A pointer to the maximum value node in the tree.
       * <Remarks>
       *    None.
       */
      AvlTreeNode*   GetMaxNode();

      /* 
       * GetMinNode
       *    Get the minimum value node in the tree.
       * <Parameter>
       *    None.
       * <Return>
       *    A pointer to the minimum value node in the tree.
       * <Remarks>
       *    None.
       */
      AvlTreeNode*   GetMinNode();

      /* 
       * InitTraverse
       *    Initialize 'TraversePath' 
       * <Parameter>
       *    pPath : [in] A pointer to 'TraversePath' object.
       * <Return>
       *    None.
       * <Remarks>
       *    In order to traver the tree, function call to 'InitTraverse' must 
       *    be made before begining to call 'Traverse'.
       */
      void           InitTraverse(TraversePath* pPath);

      /* 
       * Traverse
       *    Traverse tree nodes in order.
       * <Parameter>
       *    pPath : [in] A pointer to 'TraversePath' object which was returned 
       *            from previous 'InitTraverse' function call.
       * <Return>
       *    A pointer to the current node or null when it reaches the end.
       * <Remarks>
       *    None.
       */
      AvlTreeNode*   Traverse(TraversePath* pPath);

#if defined(_VERIFICATION_TOOLS) && !defined(NDEBUG)
   protected :
      int   GetHeight() const;
      int   CalcBalance() const;
      bool  CheckIntegrity() const;
#endif

   protected :
      bool           Rotate(AvlTreeNode** ppThis, int n);
      AvlTreeNode*   GetPolarNode(int n);
};

inline AvlTreeNode::AvlTreeNode() 
: m_nState(BALANCED)
{
   m_pChild[LEFT]       = NULL;
   m_pChild[RIGHT]      = NULL;
}

inline AvlTreeNode::~AvlTreeNode()
{
}

inline AvlTreeNode* AvlTreeNode::GetMaxNode()
{
   return GetPolarNode(RIGHT);
}

inline AvlTreeNode* AvlTreeNode::GetMinNode()
{
   return GetPolarNode(LEFT);
}

inline AvlTreeNode* AvlTreeNode::ProbePath::Access()
{
   return (m_eResult == FOUND) ? *m_arppNodeStack[m_nStackTop - 1] : NULL;
}

#endif
