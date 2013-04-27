#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <cstdlib>
#include <iostream>
#include <cstring>
#include <string.h>
#include "AvlTreeNode.h"

using namespace std;

class IntegerNode : public AvlTreeNode
{
   public :
      int            key;
      string         m_nValue;

   public :
      IntegerNode(int pkey,string v) : key(pkey), m_nValue(v) {}
      string GetValue(){ return m_nValue; }
      int CompareTo(const Comparable* pComparable) const
      { 
          return key - (static_cast<const IntegerNode*>(pComparable))->key;
      }
};

int main(int argc, char* argv[])
{
   int                        i, j, a, b;
   time_t                     t;
   const int                  NUM_OF_TEST_NODES = 10;
   IntegerNode*               pIntegerNode[NUM_OF_TEST_NODES];
   AvlTreeNode*               pRoot;
   IntegerNode*               pTemp;
   IntegerNode*               pNode;
   IntegerNode*               pFound;
   int                        nReplace;
   AvlTreeNode::ProbePath     sProbePath;
   AvlTreeNode::TraversePath  sTraversePath;
   AvlTreeNode::probe_result  eResult;

   srand(time(&t));

//AGAIN :

   /* Make 70% unique nodes.                                                  */
   for(i = 0; i < NUM_OF_TEST_NODES * 0.7; i++)
   {
      pIntegerNode[i] = new IntegerNode(i,"-");
   }

   /* Make 30% duplicated nodes for testing.                                  */
   for(j = i; j < NUM_OF_TEST_NODES; j++)
   {
      pIntegerNode[j] = new IntegerNode(abs(rand()) % i,"-");
   }

   /* shuffle them enough.                                                    */
   for(i = 0; i < NUM_OF_TEST_NODES * 2; i++)
   {
      a = rand() % NUM_OF_TEST_NODES;
      b = rand() % NUM_OF_TEST_NODES;

      pTemp             = pIntegerNode[a];
      pIntegerNode[a]   = pIntegerNode[b];
      pIntegerNode[b]   = pTemp;
   }

   /* Set the root.                                                           */
   pRoot = pIntegerNode[0];
   printf("Root : %s\n", pIntegerNode[0]->GetValue().c_str());

   /* Insert 50% of them into the tree by calling the first insertion function*/
   for(i = 1; i < NUM_OF_TEST_NODES * 0.5; i++)
   {
      printf("Insert : %s\n", pIntegerNode[i]->GetValue().c_str());

      /* Insert a node. When a duplicated node is inserted, it will be        */
      /* rejected naturally and there is no way to notice that. If you really */
      /* need to be sure the result of insertion, use the other insertion     */
      /* function.                                                            */
      pRoot = pRoot->Insert(pIntegerNode[i]);
   }

   /* Insert left of them into the tree by calling the second insertion       */
   /* function.                                                               */
   for( ; i < NUM_OF_TEST_NODES; i++)
   {
      printf("Probe & Insert: %s", pIntegerNode[i]->GetValue().c_str());

      /* Probe first.                                                         */
      eResult = pRoot->Probe(pIntegerNode[i], &sProbePath);

      switch(eResult)
      {
         case AvlTreeNode::FOUND     : printf(" -> found.\n"); break;
         case AvlTreeNode::NOT_FOUND : printf(" -> not found.\n"); break;
         case AvlTreeNode::FULL      : printf(" -> the tree is full.\n"); break;
      }

      /* We just push the node into the tree for testing no matter what       */
      /* result we got. If 'bResult == false', the insertion will be rejected */
      /* naturally.                                                           */
      pRoot = pRoot->Insert(&sProbePath, pIntegerNode[i]);
   }

   /* Traverse nodes.                                                         */
   printf("Traverse : ");
   pRoot->InitTraverse(&sTraversePath);

   pNode = static_cast<IntegerNode*>(pRoot->Traverse(&sTraversePath));

   do
   {
      printf("%s ", pNode->GetValue().c_str());
      pNode = static_cast<IntegerNode*>(pRoot->Traverse(&sTraversePath));
   }while(pNode);

   printf("\n");

   /* Get the smallest node.                                                  */
   pNode = static_cast<IntegerNode*>(pRoot->GetMinNode());
   printf("Min Node : %s\n", pNode->GetValue().c_str());

   /* Get the largest node.                                                   */
   pNode = static_cast<IntegerNode*>(pRoot->GetMaxNode());
   printf("Max Node : %s\n", pNode->GetValue().c_str());

   for(i = 0; i < NUM_OF_TEST_NODES; i++)
   {
      delete pIntegerNode[i];
   }

   return 0;
}

