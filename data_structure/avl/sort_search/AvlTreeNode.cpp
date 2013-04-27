#include "AvlTreeNode.h"

const int AvlTreeNode::LEFT = 0;
const int AvlTreeNode::RIGHT = 1;
const int AvlTreeNode::BALANCED = -1;

/* 
 * args:
 *    pComparable : [in] A pointer to a Comparable object to be searched.
 * return:
 *    'FOUND' if the node was found, if not 'NOT_FOUND'. In case the tree is 
 *    full, return value is 'FULL'.
 * doc:Search a node in the tree. After calling 'Probe', you can call other tree-operation functions.with the 'ProbePath' object returned.
 * 
 */
AvlTreeNode::probe_result AvlTreeNode::Probe(const Comparable* pComparable, ProbePath* pPath)
{
   int nComp, nDir;
   probe_result eRet = NOT_FOUND;
   AvlTreeNode** ppThis;
   int nStackTop = 0;
   AvlTreeNode*** arppNodeStack = pPath->m_arppNodeStack;
   int* arnDirStack = pPath->m_arnDirStack;

   assert(pComparable);
   assert(pPath);

   // Setup the root node.
   pPath->m_pRoot = this;
   ppThis = &(pPath->m_pRoot);

   // Find the node.
   while(*ppThis)
   {
      // Compare this node with the node we are finding.
      nComp = (*ppThis)->CompareTo(pComparable);

      // Save this node into the stack.
      nDir = nComp < 0;
      arppNodeStack[nStackTop] = ppThis;
      arnDirStack[nStackTop++] = nDir;

      // Is the node found?
      if(nComp == 0)
      {
         eRet = FOUND;
         break;
      }

      // Is the tree full?
      if(nStackTop >= TREE_MAX_HEIGHT)
      {
         eRet = FULL;
         break;
      }
      // Follow the next node.
      ppThis = &((*ppThis)->m_pChild[nDir]);
   }

   // Save the lastly accessed node.
   if(!*ppThis) arppNodeStack[nStackTop++] = ppThis;

   // Keep stack top.
   pPath->m_nStackTop = nStackTop;

   pPath->m_eResult = eRet;

   pPath->m_pComparable = pComparable;

   return eRet;
}

/* 
 * args:
 *    pInsert : A pointer to a node to be inserted.
 * return:
 *    A pointer to the root node. Node insertion sometimes causes change 
 *    of the root node.
 * doc:
 *    Insert a node into the tree.If a node with same value already exist or the tree is full, this function does nothing.
 * 
 */
AvlTreeNode* AvlTreeNode::Insert(AvlTreeNode* pInsert)
{
   int n;
   AvlTreeNode** ppThis;
   AvlTreeNode* pRoot;
   AvlTreeNode* pNode;
   
   int nStackTop = 0;
   AvlTreeNode** arppNodeStack[TREE_MAX_HEIGHT];
   int arnDirStack[TREE_MAX_HEIGHT];

   assert(pInsert);

   // Setup the root node.
   pRoot = this;
   ppThis = &pRoot;
   
   // Find the appropriate position to insert the node.
   while(*ppThis)
   {
      // Compare this node with the node to be inserted.
      n = (*ppThis)->CompareTo(pInsert);
      
      // Already exist?
      if(n == 0) return pRoot; // Return the root node.

      // Is the tree full?
      if(nStackTop >= TREE_MAX_HEIGHT) return pRoot;
      
      // Save this node into the stack.
      n = n < 0;
      arppNodeStack[nStackTop] = ppThis;
      arnDirStack[nStackTop++] = n;

      // Follow the next node.
      ppThis = &((*ppThis)->m_pChild[n]);
   }

   // Insert the node.
   *ppThis = pInsert;
   
   // Rebalance the tree.
   while(nStackTop > 0)
   {
      // Restore a node from the stack.
      ppThis = arppNodeStack[--nStackTop];
      n = arnDirStack[nStackTop];
      
      pNode = *ppThis;

      // Adjust the balance of the node.
      if(pNode->m_nState == BALANCED)
      {
         pNode->m_nState = n;
      }
      else if(pNode->m_nState == 1 - n)
      {
         pNode->m_nState = BALANCED;
         break; // Don't need to follow the tree path any more.
      }
      else
      {
         // Need rotation.
         pNode->Rotate(ppThis, n);
         break; // Don't need to follow the tree path any more.
      }
   }
   
   // Return the root node.
   return pRoot;
}

/* 
 * args:
 *    pPath :  A pointer to 'TraversePath' object.
 * return:
 * doc:Initialize 'TraversePath' In order to traver the tree, function call to 'InitTraverse' must be made before begining to call 'Traverse'.
 * 
 */
void AvlTreeNode::InitTraverse(TraversePath* pPath)
{
   AvlTreeNode** ppStack;
   AvlTreeNode* pNode = this;
   int nTop = 0;

   assert(pPath);

   ppStack = pPath->m_arpNodeStack;

   // Go to the left most node(the smallest).
   do
   {
      ppStack[nTop++] = pNode;
      pNode = pNode->m_pChild[LEFT];
   }while(pNode);

   pPath->m_nStackTop = nTop;
}

/* 
 * args:
 *    pPath:A pointer to 'TraversePath' object which was returned 
 *            from previous 'InitTraverse' function call.
 * return:A pointer to the current node or null when it reaches the end.
 * doc:Traverse tree nodes in order.
 *
 */
AvlTreeNode* AvlTreeNode::Traverse(TraversePath* pPath)
{
   AvlTreeNode** ppStack;
   AvlTreeNode* pNode;
   AvlTreeNode* pRet;
   int nTop;

   assert(pPath);

   // Finished?
   if(pPath->m_nStackTop <= 0) return NULL;

   ppStack = pPath->m_arpNodeStack;

   // Save the node to be returned.
   pRet = pNode = ppStack[--pPath->m_nStackTop];

   nTop = pPath->m_nStackTop;

   if(pNode->m_pChild[RIGHT])
   {
      pNode = pNode->m_pChild[RIGHT];

      // Go to the left most node(the smallest).
      do
      {
         ppStack[nTop++] = pNode;
         pNode = pNode->m_pChild[LEFT];
      }while(pNode);
   }

   pPath->m_nStackTop = nTop;

   return pRet;
}

/*
 * args:
 *    ppThis:we rotate the binarytree whice root is *ppThis
 * return:
 *    true:rotate true,false:rotate false
 * doc:rotate the binarytree
 *
 */
bool AvlTreeNode::Rotate(AvlTreeNode** ppThis, int n)
{
   int r = 1 - n;
   AvlTreeNode* pChild;
   AvlTreeNode* pGrandChild;
   
   // Setup a child and grandchild.
   pChild = m_pChild[n];
   pGrandChild = pChild->m_pChild[r];
   
   if(pChild->m_nState != r)
   {
      m_pChild[n] = pGrandChild;
      pChild->m_pChild[r] = this;
      *ppThis = pChild;

      // Adjust balance.
      if(pChild->m_nState == BALANCED)
      {
         pChild->m_nState  = r;
         return true; // No need to rebalance any more.
      }

      m_nState = BALANCED;
   }
   else
   {
      pChild->m_pChild[r] = pGrandChild->m_pChild[n];
      m_pChild[n] = pGrandChild->m_pChild[r];
      pGrandChild->m_pChild[n] = pChild;
      pGrandChild->m_pChild[r] = this;
      *ppThis = pGrandChild;

      // Adjust balance.
      m_nState = BALANCED;
      pChild->m_nState = BALANCED;
      if(pGrandChild->m_nState == n) m_nState = r;
      else if(pGrandChild->m_nState == r) pChild->m_nState = n;
   }

   // Adjust balance.
   (*ppThis)->m_nState = BALANCED;

   return false;
}
