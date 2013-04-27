#include "AvlTreeNode.h"

const int                     AvlTreeNode::LEFT             =  0;
const int                     AvlTreeNode::RIGHT            =  1;
const int                     AvlTreeNode::BALANCED         = -1;

AvlTreeNode::probe_result AvlTreeNode::Probe(const Comparable* pComparable, ProbePath* pPath)
{
   int            nComp, nDir;
   probe_result   eRet = NOT_FOUND;
   AvlTreeNode**  ppThis;
   int            nStackTop = 0;
   AvlTreeNode*** arppNodeStack  = pPath->m_arppNodeStack;
   int*           arnDirStack    = pPath->m_arnDirStack;

   assert(pComparable);
   assert(pPath);

   /* Setup the root node.                                                    */
   pPath->m_pRoot = this;
   ppThis         = &(pPath->m_pRoot);

   /* Find the node.                                                          */
   while(*ppThis)
   {
      /* Compare this node with the node we are finding.                      */
      nComp = (*ppThis)->CompareTo(pComparable);

      /* Save this node into the stack.                                       */
      nDir = nComp < 0;
      arppNodeStack[nStackTop] = ppThis;
      arnDirStack[nStackTop++] = nDir;

      /* Is the node found?                                                   */
      if(nComp == 0)
      {
         eRet = FOUND;
         break;
      }

      /* Is the tree full?                                                    */
      if(nStackTop >= TREE_MAX_HEIGHT)
      {
         eRet = FULL;
         break;
      }
      /* Follow the next node.                                                */
      ppThis = &((*ppThis)->m_pChild[nDir]);
   }

   /* Save the lastly accessed node.                                          */
   if(!*ppThis) arppNodeStack[nStackTop++] = ppThis;

   /* Keep stack top.                                                         */
   pPath->m_nStackTop = nStackTop;

   pPath->m_eResult = eRet;

#if !defined(NDEBUG)
   pPath->m_pComparable = pComparable;
#endif

   return eRet;
}

AvlTreeNode* AvlTreeNode::Insert(AvlTreeNode* pInsert)
{
   int            n;
   AvlTreeNode**  ppThis;
   AvlTreeNode*   pRoot;
   AvlTreeNode*   pNode;
   
   int            nStackTop = 0;
   AvlTreeNode**  arppNodeStack[TREE_MAX_HEIGHT];
   int            arnDirStack[TREE_MAX_HEIGHT];

   assert(pInsert);

   /* Setup the root node.                                                    */
   pRoot    = this;
   ppThis   = &pRoot;
   
   /* Find the appropriate position to insert the node.                       */
   while(*ppThis)
   {
      /* Compare this node with the node to be inserted.                      */
      n = (*ppThis)->CompareTo(pInsert);
      
      /* Already exist?                                                       */
      if(n == 0) return pRoot; /* Return the root node.                       */

      /* Is the tree full?                                                    */
      if(nStackTop >= TREE_MAX_HEIGHT) return pRoot;
      
      /* Save this node into the stack.                                       */
      n = n < 0;
      arppNodeStack[nStackTop]   = ppThis;
      arnDirStack[nStackTop++]   = n;

      /* Follow the next node.                                                */
      ppThis = &((*ppThis)->m_pChild[n]);
   }

   /* Insert the node.                                                        */
   *ppThis = pInsert;
   
   /* Rebalance the tree.                                                     */
   while(nStackTop > 0)
   {
      /* Restore a node from the stack.                                       */
      ppThis   = arppNodeStack[--nStackTop];
      n        = arnDirStack[nStackTop];
      
      pNode    = *ppThis;

      /* Adjust the balance of the node.                                      */
      if(pNode->m_nState == BALANCED)
      {
         pNode->m_nState = n;
      }
      else if(pNode->m_nState == 1 - n)
      {
         pNode->m_nState = BALANCED;
         break; /* Don't need to follow the tree path any more.               */
      }
      else
      {
         /* Need rotation.                                                    */
         pNode->Rotate(ppThis, n);
         break; /* Don't need to follow the tree path any more.               */
      }
   }
   
#if defined(_VERIFICATION_TOOLS) && !defined(NDEBUG) && defined(_AVL_UNDER_DEVELOPMENT)
   bool b = pRoot->CheckIntegrity();
   verify(b == true);
#endif
   
   /* Return the root node.                                                   */
   return pRoot;
}

AvlTreeNode* AvlTreeNode::Insert(ProbePath* pPath, AvlTreeNode* pInsert)
{
   int            n;
   AvlTreeNode**  ppThis;
   AvlTreeNode*   pNode;
   
   int            nStackTop      = pPath->m_nStackTop;
   AvlTreeNode*** arppNodeStack  = pPath->m_arppNodeStack;
   int*           arnDirStack    = pPath->m_arnDirStack;

   assert(pPath);
   assert(pInsert);
   assert(pPath->m_pComparable->CompareTo(pInsert) == 0);

   /* Restore a node from the stack.                                          */
   ppThis = arppNodeStack[--nStackTop];

   /* Already exist?                                                          */
   if(*ppThis) return pPath->m_pRoot; /* Return the root node.              */

   /* Insert the node.                                                        */
   *ppThis = pInsert;
   
   /* Rebalance the tree.                                                     */
   while(nStackTop > 0)
   {
      /* Restore a node from the stack.                                       */
      ppThis   = arppNodeStack[--nStackTop];
      n        = arnDirStack[nStackTop];
      
      pNode    = *ppThis;

      /* Adjust the balance of the node.                                      */
      if(pNode->m_nState == BALANCED)
      {
         pNode->m_nState = n;
      }
      else if(pNode->m_nState == 1 - n)
      {
         pNode->m_nState = BALANCED;
         break; /* Don't need to follow the tree path any more.               */
      }
      else
      {
         /* Need ratation.                                                    */
         pNode->Rotate(ppThis, n);
         break; /* Don't need to follow the tree path any more.               */
      }
   }
   
#if defined(_VERIFICATION_TOOLS) && !defined(NDEBUG) && defined(_AVL_UNDER_DEVELOPMENT)
   bool b = pPath->m_pRoot->CheckIntegrity();
   verify(b == true);
#endif
   
   /* Return the root node.                                                   */
   return pPath->m_pRoot;
}

AvlTreeNode* AvlTreeNode::Remove(Comparable* pComparable, AvlTreeNode** ppRemoved)
{
   int               n;
   AvlTreeNode**     ppThis;
   AvlTreeNode*      pRoot;
   AvlTreeNode*      pNode;

   AvlTreeNode**     ppTarget = NULL;
   AvlTreeNode***    pppStack;
   AvlTreeNode*      pTarget;

   int               nStackTop = 0;
   AvlTreeNode**     arppNodeStack[TREE_MAX_HEIGHT];
   int               arnDirStack[TREE_MAX_HEIGHT];

   assert(pComparable);
   assert(ppRemoved);

   /* Setup the root node.                                                    */
   pRoot    = this;
   ppThis   = &pRoot;

   /* Find the node to be removed and swapped.                                */
   while(*ppThis)
   {
      /* Compare this node with the node to be removed.                       */
      n = (*ppThis)->CompareTo(pComparable);
      
      /* Found?                                                               */
      if(n == 0)
      {
         /* Save the target node and the stack position to be modified later. */
         ppTarget = ppThis;
         pppStack = &arppNodeStack[nStackTop + 1];

         /* Keep searching to find the node to be swapped.                    */
      }

      /* Save this node into the stack.                                       */
      n = n < 0;
      arppNodeStack[nStackTop]   = ppThis;
      arnDirStack[nStackTop++]   = n;

      /* Follow the next node.                                                */
      ppThis = &((*ppThis)->m_pChild[n]);
   }
   
   /* Not found?                                                              */
   if(!ppTarget)
   {
      *ppRemoved = NULL;
      return pRoot; /* Return the root node.                                  */
   }

   /* Restore a node from the stack.                                          */
   ppThis   = arppNodeStack[--nStackTop];
   n        = arnDirStack[nStackTop];
   
   /* 'pTarget' is the node to be removed. 'pNode' is the node to be swapped. */
   pTarget  = *ppTarget;
   pNode    = *ppThis;
   
   /* Swap 'pTarget' for 'pNode'.                                             */
   *ppTarget               = pNode;
   *ppThis                 = pNode->m_pChild[1 - n];
   pNode->m_pChild[LEFT]   = pTarget->m_pChild[LEFT];
   pNode->m_pChild[RIGHT]  = pTarget->m_pChild[RIGHT];
   pNode->m_nState         = pTarget->m_nState;
   
   /* Modify the stack to reflect swap.                                       */
   *pppStack = &pNode->m_pChild[1 - n];
   
   /* Return the removed node to the caller.                                  */
   *ppRemoved = pTarget;

   /* Just to be strict.                                                      */
   pTarget->m_pChild[LEFT] = pTarget->m_pChild[RIGHT] = NULL; 

   /* Rebalance the tree.                                                     */
   while(nStackTop > 0)
   {
      /* Restore a node from the stack.                                       */
      ppThis   = arppNodeStack[--nStackTop];
      n        = arnDirStack[nStackTop];

      pNode    = *ppThis;

      /* Adjust the balance of the node.                                      */
      if(pNode->m_nState == BALANCED)
      {
         pNode->m_nState = 1 - n;
         break; /* Don't need to follow the tree path any more.               */
      }
      else if(pNode->m_nState == n)
      {
         pNode->m_nState = BALANCED;
      }
      else
      {
         /* Need rotation.                                                    */
         if(pNode->Rotate(ppThis, 1 - n)) break; 
      }
   }
   
#if defined(_VERIFICATION_TOOLS) && !defined(NDEBUG) && defined(_AVL_UNDER_DEVELOPMENT)
   bool b = pRoot ? pRoot->CheckIntegrity() : true;
   verify(b == true);
#endif
   
   /* Return the root node.                                                   */
   return pRoot;
}

AvlTreeNode* AvlTreeNode::Remove(ProbePath* pPath, AvlTreeNode** ppRemoved)
{
   int            n;
   AvlTreeNode**  ppThis;
   AvlTreeNode*   pNode;

   AvlTreeNode**  ppTarget;
   AvlTreeNode*** pppStack;
   AvlTreeNode*   pTarget;

   int            nStackTop      = pPath->m_nStackTop;
   AvlTreeNode*** arppNodeStack  = pPath->m_arppNodeStack;
   int*           arnDirStack    = pPath->m_arnDirStack;

   assert(pPath);
   assert(ppRemoved);
   assert(pPath->m_pComparable->CompareTo(*ppRemoved) == 0);

   /* Restore a node from the stack.                                          */
   ppThis = arppNodeStack[nStackTop - 1];

   /* Not found?                                                              */
   if(*ppThis == NULL)
   {
      *ppRemoved = NULL;
      return pPath->m_pRoot;
   }

   /* Restore a direction also from the stack.                                */
   n = arnDirStack[nStackTop - 1];

   /* Save the target node and the stack position to be modified later.       */
   ppTarget = ppThis;
   pppStack = &arppNodeStack[nStackTop];

   /* Follow the next node.                                                   */
   ppThis = &((*ppThis)->m_pChild[n]);

   /* Find the node to be swapped.                                            */
   while(*ppThis)
   {
      /* Compare this node with the node to be removed.                       */
      n = (*ppThis)->CompareTo(*ppTarget) < 0;

      /* Save this node into the stack.                                       */
      arppNodeStack[nStackTop] = ppThis;
      arnDirStack[nStackTop++] = n;

      /* Follow the next node.                                                */
      ppThis = &((*ppThis)->m_pChild[n]);
   }
   
   /* Restore a node from the stack.                                          */
   ppThis   = arppNodeStack[--nStackTop];
   n        = arnDirStack[nStackTop];
   
   /* 'pTarget' is the node to be removed. 'pNode' is the node to be swapped. */
   pTarget  = *ppTarget;
   pNode    = *ppThis;
   
   /* Swap 'pTarget' for 'pNode'.                                             */
   *ppTarget               = pNode;
   *ppThis                 = pNode->m_pChild[1 - n];
   pNode->m_pChild[LEFT]   = pTarget->m_pChild[LEFT];
   pNode->m_pChild[RIGHT]  = pTarget->m_pChild[RIGHT];
   pNode->m_nState         = pTarget->m_nState;
   
   /* Modify the stack to reflect swapping.                                   */
   *pppStack = &pNode->m_pChild[1 - n];
   
   /* Return the removed node to the caller.                                  */
   *ppRemoved = pTarget;

   /* Just to be strict.                                                      */
   pTarget->m_pChild[LEFT] = pTarget->m_pChild[RIGHT] = NULL; 
   
   /* Rebalance the tree.                                                     */
   while(nStackTop > 0)
   {
      /* Restore a node from the stack.                                       */
      ppThis   = arppNodeStack[--nStackTop];
      n        = arnDirStack[nStackTop];

      pNode    = *ppThis;

      /* Adjust the balance of the node.                                      */
      if(pNode->m_nState == BALANCED)
      {
         pNode->m_nState = 1 - n;
         break; /* Don't need to follow the tree path any more.               */
      }
      else if(pNode->m_nState == n)
      {
         pNode->m_nState = BALANCED;
      }
      else
      {
         /* Need rotation.                                                    */
         if(pNode->Rotate(ppThis, 1 - n)) break;
      }
   }
   
#if defined(_VERIFICATION_TOOLS) && !defined(NDEBUG) && defined(_AVL_UNDER_DEVELOPMENT)
   bool b = pPath->m_pRoot ? pPath->m_pRoot->CheckIntegrity() : true;
   verify(b == true);
#endif
   
   /* Return the root node.                                                   */
   return pPath->m_pRoot;
}

AvlTreeNode* AvlTreeNode::Replace(Comparable* pComparable, AvlTreeNode** ppReplace)
{
   int            n;
   AvlTreeNode**  ppThis;
   AvlTreeNode*   pRoot;
   AvlTreeNode*   pReturn;

   assert(pComparable);
   assert(ppReplace);
   assert(pComparable->CompareTo(*ppReplace) == 0);

   /* Setup the root node.                                                    */
   pRoot    = this;
   ppThis   = &pRoot;
   
   /* Find the node to be replaced.                                           */
   while(*ppThis)
   {
      /* Compare this node with the node to be inserted.                      */
      n = (*ppThis)->CompareTo(pComparable);
      
      /* Found?                                                               */
      if(n == 0)
      {
         /* Same object?                                                      */
         if(*ppReplace == *ppThis) return pRoot;

         /* Replace the node.                                                 */
         pReturn     = *ppThis;
         *ppThis     = *ppReplace;
         *ppReplace  = pReturn;

         (*ppThis)->m_pChild[LEFT]  = pReturn->m_pChild[LEFT];
         (*ppThis)->m_pChild[RIGHT] = pReturn->m_pChild[RIGHT];
         (*ppThis)->m_nState        = pReturn->m_nState;

         /* Just to be strict.                                                */
         pReturn->m_pChild[LEFT]    = NULL;
         pReturn->m_pChild[RIGHT]   = NULL;
         pReturn->m_nState          = BALANCED;
         break;
      }

      /* Follow the next node.                                                */
      ppThis = &((*ppThis)->m_pChild[n < 0]);
   }
   
   /* Return the root node.                                                   */
   return pRoot;
}

AvlTreeNode* AvlTreeNode::Replace(ProbePath* pPath, AvlTreeNode** ppReplace)
{
   AvlTreeNode**  ppThis;
   AvlTreeNode*   pReturn;
   
   assert(pPath);
   assert(ppReplace);
   assert(pPath->m_pComparable->CompareTo(*ppReplace) == 0);

   /* Restore a node from the stack.                                          */
   ppThis = pPath->m_arppNodeStack[--pPath->m_nStackTop];

   /* Not found?                                                              */
   if(*ppThis == NULL) return pPath->m_pRoot;

   /* Same object?                                                            */
   if(*ppReplace == *ppThis) return pPath->m_pRoot;

   /* Replace the node.                                                       */
   pReturn     = *ppThis;
   *ppThis     = *ppReplace;
   *ppReplace  = pReturn;

   (*ppThis)->m_pChild[LEFT]  = pReturn->m_pChild[LEFT];
   (*ppThis)->m_pChild[RIGHT] = pReturn->m_pChild[RIGHT];
   (*ppThis)->m_nState        = pReturn->m_nState;

   /* Just to be strict.                                                      */
   pReturn->m_pChild[LEFT]    = NULL;
   pReturn->m_pChild[RIGHT]   = NULL;
   pReturn->m_nState          = BALANCED;
   
   return pPath->m_pRoot;
}

AvlTreeNode* AvlTreeNode::GetPolarNode(int n)
{
   AvlTreeNode*         pNode = this;

   for(pNode = this; pNode->m_pChild[n]; pNode = pNode->m_pChild[n]) ;

   return pNode;
}

void AvlTreeNode::InitTraverse(TraversePath* pPath)
{
   AvlTreeNode**     ppStack;
   AvlTreeNode*      pNode = this;
   int               nTop = 0;

   assert(pPath);

   ppStack = pPath->m_arpNodeStack;

   /* Go to the left most node(the smallest).                                 */
   do
   {
      ppStack[nTop++] = pNode;
      pNode = pNode->m_pChild[LEFT];
   }while(pNode);

   pPath->m_nStackTop = nTop;
}

AvlTreeNode* AvlTreeNode::Traverse(TraversePath* pPath)
{
   AvlTreeNode**     ppStack;
   AvlTreeNode*      pNode;
   AvlTreeNode*      pRet;
   int               nTop;

   assert(pPath);

   /* Finished?                                                               */
   if(pPath->m_nStackTop <= 0) return NULL;

   ppStack = pPath->m_arpNodeStack;

   /* Save the node to be returned.                                           */
   pRet = pNode = ppStack[--pPath->m_nStackTop];

   nTop = pPath->m_nStackTop;

   if(pNode->m_pChild[RIGHT])
   {
      pNode = pNode->m_pChild[RIGHT];

      /* Go to the left most node(the smallest).                              */
      do
      {
         ppStack[nTop++] = pNode;
         pNode = pNode->m_pChild[LEFT];
      }while(pNode);
   }

   pPath->m_nStackTop = nTop;

   return pRet;
}

bool AvlTreeNode::Rotate(AvlTreeNode** ppThis, int n)
{
   int            r = 1 - n;
   AvlTreeNode*   pChild;
   AvlTreeNode*   pGrandChild;
   
   /* Setup a child and grandchild.                                           */
   pChild      = m_pChild[n];
   pGrandChild = pChild->m_pChild[r];
   
   if(pChild->m_nState != r)
   {
      /*
       *  this        : A
       *  child       : C
       *
       *  Initial      A -> D      C -> A       R -> C
       *  R        |  R        |  R    C    |     R     
       *   \       |   \       |   \ /   \  |      \    
       *    A      |    A      |    A     E |       C    
       *  /   \    |  /  |     |  /  |      |     /   \ 
       * B     C   | B   | C   | B   |      |    A     E
       *      / \  |     |/ \  |     |      |  /  |     
       *     D   E |     D   E |     D      | B   |     
       *           |           |            |     |     
       *           |           |            |     D     
       */
      m_pChild[n]          = pGrandChild;
      pChild->m_pChild[r]  = this;
      *ppThis              = pChild;

      /* Adjust balance.                                                      */
      if(pChild->m_nState == BALANCED)
      {
         pChild->m_nState  = r;
         return true; /* No need to rebalance any more.                       */
      }

      m_nState = BALANCED;
   }
   else
   {
      /*
       *  this        : A
       *  child       : C
       *  grand child : D
       *
       *  Initial      C -> G    D -> C       A -> F        D -> A       R -> D
       *  R        |  R        |  R      |  R           |  R   D     |    R      
       *   \       |   \       |   \     |   \          |   \ / \    |     \     
       *    A      |    A      |    A    |    A   D     |    A   C   |      D    
       *  /   \    |  /   \    |  /  |   |  /  \ / \    |  /  \  |\  |     / \   
       * B     C   | B     C   | B   |   | B    F   C   | B    F | E |    A   C  
       *      / \  |       |\  |     |   |          |\  |        |   |  /  \  |\ 
       *     D   E |     D | E |   D |   |          | E |        G   | B    F | E
       *    / \    |    / \|   |  / \|   |          |   |            |        |  
       *   F   G   |   F   G   | F   C   |          G   |            |        G  
       *           |           |     |\  |              |            |
       *           |           |     | E |              |            |
       *           |           |     |   |              |            |
       *           |           |     G   |              |            |
       */
      pChild->m_pChild[r]        = pGrandChild->m_pChild[n];
      m_pChild[n]                = pGrandChild->m_pChild[r];
      pGrandChild->m_pChild[n]   = pChild;
      pGrandChild->m_pChild[r]   = this;
      *ppThis                    = pGrandChild;

      /* Adjust balance.                                                      */
      m_nState                   = BALANCED;
      pChild->m_nState           = BALANCED;
      if(pGrandChild->m_nState == n)      m_nState         = r;
      else if(pGrandChild->m_nState == r) pChild->m_nState = n;
   }

   /* Adjust balance.                                                         */
   (*ppThis)->m_nState = BALANCED;

   return false;
}

#if defined(_VERIFICATION_TOOLS) && !defined(NDEBUG)
int AvlTreeNode::GetHeight() const 
{
   int      left, right;

   left  = m_pChild[LEFT]  ? m_pChild[LEFT]->GetHeight() + 1  : 0;
   right = m_pChild[RIGHT] ? m_pChild[RIGHT]->GetHeight() + 1 : 0;

   return (left > right) ? left : right;
}

int AvlTreeNode::CalcBalance() const
{
   int      left, right;

   left  = m_pChild[LEFT]  ? m_pChild[LEFT]->GetHeight() + 1  : 0;
   right = m_pChild[RIGHT] ? m_pChild[RIGHT]->GetHeight() + 1 : 0;

   return right - left;
}

bool AvlTreeNode::CheckIntegrity() const
{
   bool     check_left, check_right, balance, comp_left, comp_right;

   /* This node should be bigger than the left node. */
   comp_left   = m_pChild[LEFT]  ? CompareTo(m_pChild[LEFT])  > 0 : true;

   /* This node should be smaller than the right node. */
   comp_right  = m_pChild[RIGHT] ? CompareTo(m_pChild[RIGHT]) < 0 : true;

   /* Balance should be -1, 0 or 1, and m_nState should have correct value according to the balance. */
   switch(CalcBalance())
   {
      case -1 : balance = (m_nState == LEFT); break;
      case  0 : balance = (m_nState == BALANCED); break;
      case  1 : balance = (m_nState == RIGHT); break;
      default : balance = false;
   }

   /* Check the integrity of left subtree. */
   check_left     = m_pChild[LEFT]  ? m_pChild[LEFT]->CheckIntegrity()  : true;

   /* Check the integrity of right subtree. */
   check_right    = m_pChild[RIGHT] ? m_pChild[RIGHT]->CheckIntegrity() : true;

   return check_left && check_right && balance && comp_left && comp_right;
}
#endif
