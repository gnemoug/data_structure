@c -*-texinfo-*-
@c 
@c GNU libavl - library for manipulation of binary trees.
@c Copyright (C) 1998, 1999, 2000, 2001, 2002, 2004 Free Software 
@c Foundation, Inc.
@c Permission is granted to copy, distribute and/or modify this document
@c under the terms of the GNU Free Documentation License, Version 1.2
@c or any later version published by the Free Software Foundation;
@c with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
@c A copy of the license is included in the section entitled "GNU
@c Free Documentation License".

@deftypedef avl_comparison_func
@deftypedef avl_item_func
@deftypedef avl_copy_func

@node AVL Trees, Red-Black Trees, Binary Search Trees, Top
@chapter AVL Trees

In the last chapter, we designed and implemented a table ADT using
binary search trees.  We were interested in binary trees from the
beginning because of their promise of speed compared to linear lists.

But we only get these speed improvements if our binary trees are
arranged more or less optimally, with the tree's height as small as
possible.  If we insert and delete items in the tree in random order,
then chances are that we'll come pretty close to this optimal
tree.@footnote{This seems true intuitively, but there are some difficult
mathematics in this area.  For details, refer to @bibref{Knuth 1998b}
theorem 6.2.2H, @bibref{Knuth 1977}, and @bibref{Knuth 1978}.}

In ``pathological'' cases, search within binary search trees can be as
slow as sequential search, or even slower when the extra bookkeeping
needed for a binary tree is taken into account.  For example, after
inserting items into a BST in sorted order, we get something like the
vines on the left and the right below.  The BST in the middle below
illustrates a more unusual case, a ``zig-zag'' BST that results from
inserting items from alternating ends of an ordered list.

@center @image{patholog2}

Unfortunately, these pathological cases can easily come up in
practice, because sorted data in the input to a program is common.  We
could periodically balance the tree using some heuristic to detect
that it is ``too tall''.  In the last chapter, in fact, we used a weak
version of this idea, rebalancing when a stack overflow force it.  We
could abandon the idea of a binary search tree, using some other data
structure.  Finally, we could adopt some modifications to binary
search trees that prevent the pathological case from occurring.

For the remainder of this book, we're only interested in the latter
choice.  We'll look at two sets of rules that, when applied to the
basic structure of a binary search tree, ensure that the tree's height
is kept within a constant factor of the minimum value.  Although this
is not as good as keeping the BST's height at its minimum, it comes
pretty close, and the required operations are much faster.  A tree
arranged to rules such as these is called a @gloss{balanced tree}.
The operations used for minimizing tree height are said to
@gloss{rebalance} the tree, even though this is different from the
sort of rebalancing we did in the previous chapter, and are said to
maintain the tree's ``balance.''

A balanced tree arranged according to the first set of rebalancing
rules that we'll examine is called an @gloss{AVL tree}, after its
inventors, G.@: M.@: Adel'son-Vel'ski@v{@dotless{i}} and E.@: M.@:
Landis.  AVL trees are the subject of this chapter, and the next
chapter will discuss red-black trees, another type of balanced tree.

In the following sections, we'll construct a table implementation based
on AVL trees.  Here's an outline of the AVL code:

@(avl.h@> =
@<Library License@>
#ifndef AVL_H
#define AVL_H 1

#include <stddef.h>

@<Table types; tbl => avl@>
@<AVL maximum height@>
@<BST table structure; bst => avl@>
@<AVL node structure@>
@<BST traverser structure; bst => avl@>
@<Table function prototypes; tbl => avl@>

#endif /* avl.h */
@

@(avl.c@> =
@<Library License@>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "avl.h"

@<AVL functions@>
@

@menu
* AVL Balancing Rule::          
* AVL Data Types::              
* AVL Operations::              
* Inserting into an AVL Tree::  
* Deleting from an AVL Tree::   
* Traversal of an AVL Tree::    
* Copying an AVL Tree::         
* Testing AVL Trees::           
@end menu

@references
@bibref{Knuth 1998b}, sections 6.2.2 and 6.2.3;
@bibref{Cormen 1990}, section 13.4.

@node AVL Balancing Rule, AVL Data Types, AVL Trees, AVL Trees
@section Balancing Rule

A binary search tree is an AVL tree if the difference in height between
the subtrees of each of its nodes is between |-1| and |+1|.  Said
another way, a BST is an AVL tree if it is an empty tree or if its
subtrees are AVL trees and the difference in height between its left and
right subtree is between |-1| and |+1|.

Here are some AVL trees:

@center @image{avlex}

These binary search trees are not AVL trees:

@center @image{notavlex}

In an AVL tree, the height of a node's right subtree minus the height of
its left subtree is called the node's @gloss{balance factor}.  Balance
factors are always |-1|, |0|, or |+1|.  They are often represented as
one of the single characters |-|, |0|, or |+|.  Because of their
importance in AVL trees, balance factors will often be shown in this
chapter in AVL tree diagrams along with or instead of data items.  
@ifinfo
In tree diagrams, balance factors are enclosed in angle brackets:
@code{<->}, @code{<0>}, @code{<+>}.
@end ifinfo
Here are the AVL trees from above, but with balance factors shown in
place of data values:

@center @image{avlbalex}

@references
@bibref{Knuth 1998b}, section 6.2.3.

@menu
* Analysis of AVL Balancing Rule::  
@end menu

@node Analysis of AVL Balancing Rule,  , AVL Balancing Rule, AVL Balancing Rule
@subsection Analysis

How good is the AVL balancing rule?  That is, before we consider how
much complication it adds to BST operations, what does this balancing
rule guarantee about performance?  This is a simple question only if
you're familiar with the mathematics behind computer science.  For our
purposes, it suffices to state the results:

@quotation
An AVL tree with @altmath{n, |n|} nodes has height between
@altmath{\log_2(n + 1), |log2 (n + 1)|} and
@altmath{1.44\log_2(n+2)-\nobreak .328, |1.44 * log2 (n + 2) - 0.328|}.
An AVL tree with height @altmath{h, |h|} has between
@altmath{1.17(1.618^h) - 2, |1.17 * pow (1.618|@comma{}| h) - 2|} and
@altmath{2^h - 1, |pow (2|@comma{}| h) - 1|} nodes.

For comparison, an optimally balanced BST with |n| nodes has height
@altmath{\lceil\log_2{(n+1)}\rceil, |ceil (log2 (n + 1))|}.  An
optimally balanced BST with height |h| has between @altmath{2^{h - 1},
|pow (2|@comma{}| h - 1)|} and @altmath{2^h - 1, |pow (2|@comma{}| h) - 1|}
@iftex
nodes.
@end iftex
@ifnottex
nodes.@footnote{Here |log2| is the standard C base-2 logarithm
function, |pow| is the exponentiation function, and |ceil| is the
``ceiling'' or ``round up'' function.  For more information, consult a
C reference guide, such as @bibref{Kernighan 1988}.}
@end ifnottex
@end quotation

The average speed of a search in a binary tree depends on the tree's
height, so the results above are quite encouraging: an AVL tree will
never be more than about 50% taller than the corresponding optimally
balanced tree.  Thus, we have a guarantee of good performance even in
the worst case, and optimal performance in the best case.

To support at least @altmath{2^{64} - 1, 2**64 - 1} nodes in an AVL
tree, as we do for unbalanced binary search trees, we must define the
maximum AVL tree height to be @altmath{1.44\log_2((2^64-1)+2)-\nobreak .328,
|1.44 * log2 ((2**64 - 1) + 2) - 0.328|}, which is 92:

@<AVL maximum height@> =
/* Maximum AVL tree height. */
#ifndef AVL_MAX_HEIGHT
#define AVL_MAX_HEIGHT 92
#endif

@

@references
@bibref{Knuth 1998b}, theorem 6.2.3A.

@node AVL Data Types, AVL Operations, AVL Balancing Rule, AVL Trees
@section Data Types

We need to define data types for AVL trees like we did for BSTs.  AVL
tree nodes contain all the fields that a BST node does, plus a field
recording its balance factor:

@<AVL node structure@> =
/* An AVL tree node. */
struct avl_node @
  {@-
    struct avl_node *avl_link[2];  /* Subtrees. */
    void *avl_data;                /* Pointer to data. */
    signed char avl_balance;       /* Balance factor. */
  };@+

@

We're using |avl_| as the prefix for all AVL-related identifiers.

The other data structures for AVL trees are the same as for BSTs.

@node AVL Operations, Inserting into an AVL Tree, AVL Data Types, AVL Trees
@section Operations

Now we'll implement for AVL trees all the operations that we did for
BSTs.  Here's the outline.  Creation and search of AVL trees is
exactly like that for plain BSTs, and the generic table functions for
insertion convenience, assertion, and memory allocation are still
relevant, so we just reuse the code.  Of the remaining functions, we
will write new implementations of the insertion and deletion functions
and revise the traversal and copy functions.

@<AVL functions@> =
@<BST creation function; bst => avl@>
@<BST search function; bst => avl@>
@<AVL item insertion function@>
@<Table insertion convenience functions; tbl => avl@>
@<AVL item deletion function@>
@<AVL traversal functions@>
@<AVL copy function@>
@<BST destruction function; bst => avl@>
@<Default memory allocation functions; tbl => avl@>
@<Table assertion functions; tbl => avl@>
@

@node Inserting into an AVL Tree, Deleting from an AVL Tree, AVL Operations, AVL Trees
@section Insertion

The insertion function for unbalanced BSTs does not maintain the AVL
balancing rule, so we have to write a new insertion function.  But
before we get into the nitty-gritty details, let's talk in generalities.
This is time well spent because we will be able to apply many of the
same insights to AVL deletion and insertion and deletion in red-black
trees.

Conceptually, there are two stages to any insertion or deletion
operation in a balanced tree.  The first stage may lead to violation
of the tree's balancing rule.  If so, we fix it in the second stage.
The insertion or deletion itself is done in the first stage, in much
the same way as in an unbalanced BST, and we may also do a bit of
additional bookkeeping work, such as updating balance factors in an
AVL tree, or swapping node ``colors'' in red-black trees.

If the first stage of the operation does not lead to a violation of
the tree's balancing rule, nothing further needs to be done.  But if
it does, the second stage rearranges nodes and modifies their
attributes to restore the tree's balance.  This process is said to
@gloss{rebalance} the tree.  The kinds of rebalancing that might be
necessary depend on the way the operation is performed and the tree's
balancing rule.  A well-chosen balancing rule helps to minimize the
necessity for rebalancing.

When rebalancing does become necessary in an AVL or red-black tree,
its effects are limited to the nodes along or near the direct path
from the inserted or deleted node up to the root of the tree.
Usually, only one or two of these nodes are affected, but, at most,
one simple manipulation is performed at each of the nodes along this
path.  This property ensures that balanced tree operations are
efficient (see @value{balancedspeedbrief} for details).

That's enough theory for now.  Let's return to discussing the details of
AVL insertion.  There are four steps in @libavl{}'s implementation of
AVL insertion:

@enumerate 1
@item @strong{Search} for the location to insert the new item.

@item @strong{Insert} the item as a new leaf.

@item @strong{Update} balance factors in the tree that were changed by
the insertion.

@item @strong{Rebalance} the tree, if necessary.
@end enumerate

Steps 1 and 2 are the same as for insertion into a BST.  Step 3
performs the additional bookkeeping alluded to above in the general
description of balanced tree operations.  Finally, step 4 rebalances the
tree, if necessary, to restore the AVL balancing rule.

The following sections will cover all the details of AVL insertion.  For
now, here's an outline of |avl_probe()|:

@cat avl Insertion (iterative)
@<AVL item insertion function@> =
@iftangle
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree,
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
@end iftangle
void **@
avl_probe (struct avl_table *tree, void *item) @
{
  @<|avl_probe()| local variables@>

  assert (tree != NULL && item != NULL);

  @<Step 1: Search AVL tree for insertion point@>
  @<Step 2: Insert AVL node@>
  @<Step 3: Update balance factors after AVL insertion@>
  @<Step 4: Rebalance after AVL insertion@>
}

@

@<|avl_probe()| local variables@> =
struct avl_node *y, *z; /* Top node to update balance factor, and parent. */
struct avl_node *p, *q; /* Iterator, and parent. */
struct avl_node *n;     /* Newly inserted node. */
struct avl_node *w;     /* New root of rebalanced subtree. */
int dir;                /* Direction to descend. */

unsigned char da[AVL_MAX_HEIGHT]; /* Cached comparison results. */
int k = 0;              /* Number of cached results. */
@

@menu
* Step 1 in AVL Insertion::     
* Step 2 in AVL Insertion::     
* Step 3 in AVL Insertion::     
* Rebalancing AVL Trees::       
* AVL Insertion Symmetric Case::  
* AVL Insertion Example::       
* Recursive Insertion::         
@end menu

@references
@bibref{Knuth 1998b}, algorithm 6.2.3A.

@exercise* balancedspeed
When rebalancing manipulations are performed on the chain of nodes from
the inserted or deleted node to the root, no manipulation takes more
than a fixed amount of time.  In other words, individual manipulations
do not involve any kind of iteration or loop.  What can you conclude
about the speed of an individual insertion or deletion in a large
balanced tree, compared to the best-case speed of an operation for
unbalanced BSTs?

@answer
In a BST, the time for an insertion or deletion is the time required
to visit each node from the root down to the node of interest, plus
some time to perform the operation itself.  Functions |bst_probe()|
and |bst_delete()| contain only a single loop each, which iterates
once for each node examined.  As the tree grows, the time for the
actual operation loses significance and the total time for the
operation becomes essentially proportional to the height of the tree,
which is approximately @altmath{\log_2n, |log2 (n)|} in the best case
(@pxref{Analysis of AVL Balancing Rule}).

We were given that the additional work for rebalancing an AVL or
red-black tree is at most a constant amount multiplied by the height
of the tree.  Furthermore, the maximum height of an AVL tree is 1.44
times the maximum height for the corresponding perfectly balanced
binary tree, and a red-black tree has a similar bound on its height.
Therefore, for trees with many nodes, the worst-case time required to
insert or delete an item in a balanced tree is a constant multiple of
the time required for the same operation on an unbalanced BST in the
best case.  In the formal terms of computer science, insertion and
deletion in a balanced tree are O(|log n|) operations, where |n| is
the number of nodes in the tree.

In practice, operations on balanced trees of reasonable size are, at
worst, not much slower than operations on unbalanced binary trees and,
at best, much faster.
@end exercise

@node Step 1 in AVL Insertion, Step 2 in AVL Insertion, Inserting into an AVL Tree, Inserting into an AVL Tree
@subsection Step 1: Search

The search step is an extended version of the corresponding code for
BST insertion in @<BST item insertion function@>.  The earlier code
had only two variables to maintain: the current node the direction to
descend from |p|.  The AVL code does this, but it maintains some other
variables, too.  During each iteration of the |for| loop, |p| is the
node we are examining, |q| is |p|'s parent, |y| is the most recently
examined node with nonzero balance factor, |z| is |y|'s parent, and
elements |0|@dots{}|k - 1| of array |da[]| record each direction
descended, starting from |z|, in order to arrive at |p|.  The purposes
for many of these variables are surely uncertain right now, but they
will become clear later.

@<Step 1: Search AVL tree for insertion point@> =
z = (struct avl_node *) &tree->avl_root;
y = tree->avl_root;
dir = 0;
for (q = z, p = y; p != NULL; q = p, p = p->avl_link[dir]) @
  {@-
    int cmp = tree->avl_compare (item, p->avl_data, tree->avl_param);
    if (cmp == 0)
      return &p->avl_data;

    if (p->avl_balance != 0)
      z = q, y = p, k = 0;
    da[k++] = dir = cmp > 0;
  }@+

@

@node Step 2 in AVL Insertion, Step 3 in AVL Insertion, Step 1 in AVL Insertion, Inserting into an AVL Tree
@subsection Step 2: Insert

Following the search loop, |q| is the last non-null node examined, so
it is the parent of the node to be inserted.  The code below creates
and initializes a new node as a child of |q| on side |dir|, and stores
a pointer to it into |n|.  Compare this code for insertion to that
within @<BST item insertion function@>.

@<Step 2: Insert AVL node@> =
n = q->avl_link[dir] = @
  tree->avl_alloc->libavl_malloc (tree->avl_alloc, sizeof *n);
if (n == NULL)
  return NULL;

tree->avl_count++;
n->avl_data = item;
n->avl_link[0] = n->avl_link[1] = NULL;
n->avl_balance = 0;
if (y == NULL)
  return &n->avl_data;

@

@exercise
How can |y| be |NULL|?  Why is this special-cased?

@answer
Variable |y| is only modified within @<Step 1: Search AVL tree for
insertion point@>.  If |y| is set during the loop, it is set to |p|,
which is always a non-null pointer within the loop.  So |y| can only be
|NULL| if it is last set before the loop begins.  If that is true, it
will be |NULL| only if |tree->avl_root == NULL|.  So, variable |y| can
only be |NULL| if the AVL tree was empty before the insertion.

A |NULL| value for |y| is a special case because later code assumes that
|y| points to a node.
@end exercise

@node Step 3 in AVL Insertion, Rebalancing AVL Trees, Step 2 in AVL Insertion, Inserting into an AVL Tree
@subsection Step 3: Update Balance Factors

When we add a new node |n| to an AVL tree, the balance factor of |n|'s
parent must change, because the new node increases the height of one
of the parent's subtrees.  The balance factor of |n|'s parent's parent
may need to change, too, depending on the parent's balance factor, and
in fact the change can propagate all the way up the tree to its root.

At each stage of updating balance factors, we are in a similar
situation.  First, we are examining a particular node |p| that is one
of |n|'s direct ancestors.  The first time around, |p| is |n|'s
parent, the next time, if necessary, |p| is |n|'s grandparent, and so
on.  Second, the height of one of |p|'s subtrees has increased, and
which one can be determined using |da[]|.

In general, if the height of |p|'s left subtree increases, |p|'s
balance factor decreases.  On the other hand, if the right subtree's
height increases, |p|'s balance factor increases.  If we account for
the three possible starting balance factors and the two possible
sides, there are six possibilities.  The three of these corresponding
to an increase in one subtree's height are symmetric with the others
that go along with an increase in the other subtree's height.  We
treat these three cases below.

@subsubheading Case 1: |p| has balance factor 0

If |p| had balance factor 0, its new balance factor is |-| or |+|,
depending on the side of the root to which the node was added.  After
that, the change in height propagates up the tree to |p|'s parent
(unless |p| is the tree's root) because the height of the subtree rooted
at |p|'s parent has also increased.

The example below shows a new node |n| inserted as the left child of a
node with balance factor 0.  On the far left is the original tree before
insertion; in the middle left is the tree after insertion but before any
balance factors are adjusted; in the middle right is the tree after the
first adjustment, with |p| as |n|'s parent; on the far right is the tree
after the second adjustment, with |p| as |n|'s grandparent.  Only in the
trees on the far left and far right are all of the balance factors
correct.

@center @image{avlins1}

@subsubheading Case 2: |p|'s shorter subtree has increased in height

If the new node was added to |p|'s shorter subtree, then the subtree has
become more balanced and its balance factor becomes 0.  If |p| started
out with balance factor |+|, this means the new node is in |p|'s left
subtree.  If |p| had a |-| balance factor, this means the new node is in
the right subtree.  Since tree |p| has the same height as it did before,
the change does not propagate up the tree any farther, and we are done.
Here's an example that shows pre-insertion and post-balance factor
updating views:

@center @image{avlins2}

@subsubheading Case 3: |p|'s taller subtree has increased in height

If the new node was added on the taller side of a subtree with nonzero
balance factor, the balance factor becomes |+2| or |-2|.  This is a
problem, because balance factors in AVL trees must be between |-1| and
|+1|.  We have to rebalance the tree in this case.  We will cover
rebalancing later.  For now, take it on faith that rebalancing does
not increase the height of subtree |p| as a whole, so there is no need
to propagate changes any farther up the tree.

Here's an example of an insertion that leads to rebalancing.  On the
left is the tree before insertion; in the middle is the tree after
insertion and updating balance factors; on the right is the tree after
rebalancing to.  The |-2| balance factor is shown as two minus signs
(|-|@w{}|-|).  The rebalanced tree is the same height as the original
tree before insertion.

@center @image{avlins3}

As another demonstration that the height of a rebalanced subtree does
not change after insertion, here's a similar example that has one more
layer of nodes.  The trees below follow the same pattern as the ones
above, but the rebalanced subtree has a parent.  Even though the tree's
root has the wrong balance factor in the middle diagram, it turns out to
be correct after rebalancing.

@center @image{avlins4}

@subsubheading Implementation

Looking at the rules above, we can see that only in case 1, where |p|'s
balance factor is 0, do changes to balance factors continue to propagate
upward in the tree.  So we can start from |n|'s parent and move upward
in the tree, handling case 1 each time, until we hit a nonzero balance
factor, handle case 2 or case 3 at that node, and we're done (except for
possible rebalancing afterward).

Wait a second---there is no efficient way to move upward in a binary
search tree!@footnote{We could make a list of the nodes as we move down
the tree and reuse it on the way back up.  We'll do that for deletion,
but there's a simpler way for insertion, so keep reading.}  Fortunately,
there is another approach we can use.  Remember the extra code we put
into @<Step 1: Search AVL tree for insertion point@>?  This code kept
track of the last node we'd passed through that had a nonzero balance
factor as |y|.  We can use |y| to move downward, instead of upward,
through the nodes whose balance factors are to be updated.

Node |y| itself is the topmost node to be updated; when we arrive at
node |n|, we know we're done.  We also kept track of the directions we
moved downward in |da[]|.  Suppose that we've got a node |p| whose
balance factor is to be updated and a direction |d| that we moved from
it.  We know that if we moved down to the left (|d == 0|) then the
balance factor must be decreased, and that if we moved down to the right
(|d == 1|) then the balance factor must be increased.

Now we have enough knowledge to write the code to update balance
factors.  The results are almost embarrassingly short:

@<Step 3: Update balance factors after AVL insertion@> =
for (p = y, k = 0; p != n; p = p->avl_link[da[k]], k++)
  if (da[k] == 0)
    p->avl_balance--;
  else @
    p->avl_balance++;

@

Now |p| points to the new node as a consequence of the loop's exit
condition.  Variable |p| will not be modified again in this function, so
it is used in the function's final |return| statement to take the
address of the new node's |avl_data| member (see @<AVL item insertion
function@> above).

@exercise
Can case 3 be applied to the parent of the newly inserted node?

@answer
No.  Suppose that |n| is the new node, that |p| is its parent, and that
|p| has a |-| balance factor before |n|'s insertion (a similar argument
applies if |p|'s balance factor is |+|).  Then, for |n|'s insertion to
decrease |p|'s balance factor to |-2|, |n| would have to be the left
child of |p|.  But if |p| had a |-| balance factor before the insertion,
it already had a left child, so |n| cannot be the new left of |p|.  This
is a contradiction, so case 3 will never be applied to the parent of a
newly inserted node.
@end exercise

@exercise avlinsert
For each of the AVL trees below, add a new node with a value smaller
than any already in the tree and update the balance factors of the
existing nodes.  For each balance factor that changes, indicate the
numbered case above that applies.  Which of the trees require
rebalancing after the insertion?

@center @image{avlexer}
@answer

@image{avlexera}

In the leftmost tree, case 2 applies to the root's left child and the
root's balance factor does not change.  In the middle tree, case 1
applies to the root's left child and case 2 applies to the root.  In
the rightmost tree, case 1 applies to the root's left child and case 3
applies to the root.  The tree on the right requires rebalancing, and
the others do not.
@end exercise

@exercise
Earlier versions of @libavl{} used |char|s, not |unsigned char|s, to
cache the results of comparisons, as the elements of |da[]| are used
here.  At some warning levels, this caused the GNU C compiler to emit
the warning ``array subscript has type `char'@dmn{''} when it
encountered expressions like |q->avl_link[da[k]]|.  Explain why this
can be a useful warning message.

@answer
Type |char| may be signed or unsigned, depending on the C compiler
and/or how the C compiler is run.  Also, a common use for subscripting
an array with a character type is to translate an arbitrary character
to another character or a set of properties.  For example, this is a
common way to implement the standard C functions from |ctype.h|.  This
means that subscripting such an array with a |char| value can have
different behavior when |char| changes between signed and unsigned
with different compilers (or with the same compiler invoked with
different options).

@references
@bibref{ISO 1990}, section 6.1.2.5;
@bibref{Kernighan 1988}, section A4.2.
@end exercise

@exercise
If our AVL trees won't ever have a height greater than 32, then we can
portably use the bits in a single |unsigned long| to compactly store
what the entire |da[]| array does.  Write a new version of step 3 to
use this form, along with any necessary modifications to other steps
and |avl_probe()|'s local variables.

@answer
Here is one possibility:

@cat avl Insertion, with bitmask
@c tested 2002/1/6
@<Step 3: Update balance factors after AVL insertion, with bitmasks@> =
for (p = y; p != n; p = p->avl_link[cache & 1], cache >>= 1)
  if ((cache & 1) == 0)
    p->avl_balance--;
  else @
    p->avl_balance++;
@

@noindent
Also, replace the declarations of |da[]| and |k| by these:

@<Anonymous@> =
unsigned long cache = 0; /* Cached comparison results. */
int k = 0;              /* Number of cached comparison results. */
@

@noindent
and replace the second paragraph of code within the loop in step 1 by
this:

@<Anonymous@> =
if (p->avl_balance != 0)
  z = q, y = p, cache = 0, k = 0;

dir = cmp > 0;
if (dir)
  cache |= 1ul << k;
k++;
@

It is interesting to note that the speed difference between this
version and the standard version was found to be negligible, when
compiled with full optimization under GCC (both 2.95.4 and 3.0.3) on
x86.
@end exercise

@node Rebalancing AVL Trees, AVL Insertion Symmetric Case, Step 3 in AVL Insertion, Inserting into an AVL Tree
@subsection Step 4: Rebalance

We've covered steps 1 through 3 so far.  Step 4, rebalancing, is
somewhat complicated, but it's the key to the entire insertion
procedure.  It is also similar to, but simpler than, other rebalancing
procedures we'll see later.  As a result, we're going to discuss it in
detail.  Follow along carefully and it should all make sense.

Before proceeding, let's briefly review the circumstances under which
we need to rebalance.  Looking back a few sections, we see that there
is only one case where this is required: case 3, when the new node is
added in the taller subtree of a node with nonzero balance factor.

Case 3 is the case where |y| has a |-2| or |+2| balance factor after
insertion.  For now, we'll just consider the |-2| case, because we can
write code for the |+2| case later in a mechanical way by applying the
principle of symmetry.  In accordance with this idea, step 4 branches
into three cases immediately, one for each rebalancing case and a third
that just returns from the function if no rebalancing is necessary:

@<Step 4: Rebalance after AVL insertion@> =
if (y->avl_balance == -2)
  { @
    @<Rebalance AVL tree after insertion in left subtree@> @
  }
else if (y->avl_balance == +2)
  { @
    @<Rebalance AVL tree after insertion in right subtree@> @
  }
else @
  return &n->avl_data;
@

We will call |y|'s left child |x|.  The new node is somewhere in the
subtrees of |x|.  There are now only two cases of interest,
distinguished on whether |x| has a |+| or |-| balance factor.  These
cases are almost entirely separate:

@<Rebalance AVL tree after insertion in left subtree@> =
struct avl_node *x = y->avl_link[0];
if (x->avl_balance == -1)
  { @
    @<Rotate right at |y| in AVL tree@> @
  }
else @
  { @
    @<Rotate left at |x| then right at |y| in AVL tree@> @
  }
@

In either case, |w| receives the root of the rebalanced subtree, which
is used to update the parent's pointer to the subtree root (recall that
|z| is the parent of |y|):

@<Step 4: Rebalance after AVL insertion@> +=
z->avl_link[y != z->avl_link[0]] = w;

@

Finally, we increment the generation number, because the tree's
structure has changed.  Then we're done and we return to the caller:

@<Step 4: Rebalance after AVL insertion@> +=
tree->avl_generation++;
return &n->avl_data;
@

@subsubheading Case 1: |x| has |-| balance factor

For a |-| balance factor, we just rotate right at |y|.  Then the
entire process, including insertion and rebalancing, looks like this:

@center @image{avlcase1}

@iftex
This figure also introduces some new graphical conventions.  When both
balance factors and node labels are shown in a figure, node labels are
shown beside the node circles, instead of inside them.  Second, the
change in subtree |a| between the first and second diagrams is
indicated by an asterisk (*).@footnote{A ``prime'' (@altmath{\prime,
'}) is traditional, but primes are easy to overlook.}
@end iftex
@ifnottex
This figure also introduces a new graphical convention.  The change in
subtree |a| between the first and second diagrams is indicated by an
asterisk (*).@footnote{A ``prime'' (@altmath{\prime, '}) is
traditional, but primes are easy to overlook.}
@end ifnottex
In this case, it indicates that the new node was inserted in subtree
|a|.

The code here is similar to |rotate_right()| in the solution to
@value{bstrotation}:

@<Rotate right at |y| in AVL tree@> =
w = x;
y->avl_link[0] = x->avl_link[1];
x->avl_link[1] = y;
x->avl_balance = y->avl_balance = 0;
@

@subsubheading Case 2: |x| has |+| balance factor

This case is just a little more intricate.  First, let |x|'s right child
be |w|.  Either |w| is the new node, or the new node is in one of |w|'s
subtrees.  To restore balance, we rotate left at |x|, then rotate right
at |y| (this is a kind of ``double rotation'').  The process, starting
just after the insertion and showing the results of each rotation, looks
like this:

@center @image{avlcase2}

At the beginning, the figure does not show the balance factor of |w|.
This is because there are three possibilities:

@table @asis
@item @strong{Case 2.1:} |w| has balance factor |0|.
This means that |w| is the new node.  @i{a}, @i{b}, @i{c}, and @i{d}
have height 0.  After the rotations, |x| and |y| have balance factor
0.

@item @strong{Case 2.2:} |w| has balance factor |-|.
@i{a}, @i{b}, and @i{d} have height |h > 0|, and @i{c} has height |h -
1|.

@item @strong{Case 2.3:} |w| has balance factor |+|.
@i{a}, @i{c}, and @i{d} have height |h > 0|, and @i{b} has height |h -
1|.
@end table

@cat bst Rotation, left double
@<Rotate left at |x| then right at |y| in AVL tree@> =
assert (x->avl_balance == +1);
w = x->avl_link[1];
x->avl_link[1] = w->avl_link[0];
w->avl_link[0] = x;
y->avl_link[0] = w->avl_link[1];
w->avl_link[1] = y;
if (w->avl_balance == -1) @
  x->avl_balance = 0, y->avl_balance = +1;
else if (w->avl_balance == 0) @
  x->avl_balance = y->avl_balance = 0;
else /* |w->avl_balance == +1| */ @
  x->avl_balance = -1, y->avl_balance = 0;
w->avl_balance = 0;
@

@exercise
Why can't the new node be |x| rather than a node in |x|'s subtrees?

@answer
Because then |y|'s right subtree would have height 1, so there's no
way that |y| could have a |+2| balance factor.
@end exercise

@exercise
Why can't |x| have a 0 balance factor?

@answer
The value of |y| is set during the search for |item| to point to the
closest node above the insertion point that has a nonzero balance
factor, so any node below |y| along this search path, including |x|,
must have had a 0 balance factor originally.  All such nodes are updated
to have a nonzero balance factor later, during step 3.  So |x| must have
either a |-| or |+| balance factor at the time of rebalancing.
@end exercise

@exercise
For each subcase of case 2, draw a figure like that given for generic
case 2 that shows the specific balance factors at each step.

@answer .1

@center @image{avlcase21}

@answer .2

@center @image{avlcase22}

@answer .3

@center @image{avlcase23}
@end exercise

@exercise ynezlink0
Explain the expression |z->avl_link[y != z->avl_link[0]] = w| in the
second part of @<Step 4: Rebalance after AVL insertion@> above.  Why
would it be a bad idea to substitute the apparent equivalent
@w{|z->avl_link[y == z->avl_link[1]] = w|}?

@answer
|w| should replace |y| as the left or right child of |z|.  |y !=
z->avl_link[0]| has the value |1| if |y| is the right child of |z|, or
|0| if |y| is the left child.  So the overall expression replaces |y|
with |w| as a child of |z|.

The suggested substitution is a poor choice because if |z == (struct
avl_node *) &tree->root|, |z->avl_link[1]| is undefined.
@end exercise

@exercise
Suppose that we wish to make a copy of an AVL tree, preserving the
original tree's shape, by inserting nodes from the original tree into
a new tree, using |avl_probe()|.  Will inserting the original tree's
nodes in level order (see the answer to @value{levelorder}) have the
desired effect?

@answer
Yes.
@c FIXME: come up with convincing proof.
@end exercise

@node AVL Insertion Symmetric Case, AVL Insertion Example, Rebalancing AVL Trees, Inserting into an AVL Tree
@subsection Symmetric Case

Finally, we need to write code for the case that we chose not to discuss
earlier, where the insertion occurs in the right subtree of |y|.  All we
have to do is invert the signs of balance factors and switch
|avl_link[]| indexes between 0 and 1.  The results are this:

@<Rebalance AVL tree after insertion in right subtree@> =
struct avl_node *x = y->avl_link[1];
if (x->avl_balance == +1)
  { @
    @<Rotate left at |y| in AVL tree@> @
  }
else @
  { @
    @<Rotate right at |x| then left at |y| in AVL tree@> @
  }
@

@<Rotate left at |y| in AVL tree@> =
w = x;
y->avl_link[1] = x->avl_link[0];
x->avl_link[0] = y;
x->avl_balance = y->avl_balance = 0;
@

@cat bst Rotation, right double
@<Rotate right at |x| then left at |y| in AVL tree@> =
assert (x->avl_balance == -1);
w = x->avl_link[0];
x->avl_link[0] = w->avl_link[1];
w->avl_link[1] = x;
y->avl_link[1] = w->avl_link[0];
w->avl_link[0] = y;
if (w->avl_balance == +1) @
  x->avl_balance = 0, y->avl_balance = -1;
else if (w->avl_balance == 0) @
  x->avl_balance = y->avl_balance = 0;
else /* |w->avl_balance == -1| */ @
  x->avl_balance = +1, y->avl_balance = 0;
w->avl_balance = 0;
@

@node AVL Insertion Example, Recursive Insertion, AVL Insertion Symmetric Case, Inserting into an AVL Tree
@subsection Example

We're done with writing the code.  Now, for clarification, let's run
through an example designed to need lots of rebalancing along the way.
Suppose that, starting with an empty AVL tree, we insert 6, 5, and 4, in
that order.  The first two insertions do not require rebalancing.  After
inserting 4, rebalancing is needed because the balance factor of node 6
would otherwise become |-2|, an invalid value.  This is case 1, so we
perform a right rotation on 6.  So far, the AVL tree has evolved this
way:

@center @image{avlex2}

@noindent
If we now insert 1, then 3, a double rotation (case 2.1) becomes
necessary, in which we rotate left at 1, then rotate right at 4:

@center @image{avlex3}

@noindent
Inserting a final item, 2, requires a right rotation (case 1) on 5:

@center @image{avlex4}

@node Recursive Insertion,  , AVL Insertion Example, Inserting into an AVL Tree
@subsection Aside: Recursive Insertion

In previous sections we first looked at recursive approaches because
they were simpler and more elegant than iterative solutions.  As it
happens, the reverse is true for insertion into an AVL tree.  But just
for completeness, we will now design a recursive implementation of
|avl_probe()|.

Our first task in such a design is to figure out what arguments and
return value the recursive core of the insertion function will have.
We'll begin by considering AVL insertion in the abstract.  Our existing
function |avl_probe()| works by first moving down the tree, from the
root to a leaf, then back up the tree, from leaf to root, as necessary
to adjust balance factors or rebalance.  In the existing iterative
version, down and up movement are implemented by pushing nodes onto and
popping them off from a stack.  In a recursive version, moving down the
tree becomes a recursive call, and moving up the tree becomes a function
return.

While descending the tree, the important pieces of information are the
tree itself (to allow for comparisons to be made), the current node, and
the data item we're inserting.  The latter two items need to be
modifiable by the function, the former because the tree rooted at the
node may need to be rearranged during a rebalance, and the latter
because of |avl_probe()|'s return value.

While ascending the tree, we'll still have access to all of this
information, but, to allow for adjustment of balance factors and
rebalancing, we also need to know whether the subtree visited in a
nested call became taller.  We can use the function's return value for
this.

Finally, we know to stop moving down and start moving up when we find a
null pointer in the tree, which is the place for the new node to be
inserted.  This suggests itself naturally as the test used to stop the
recursion.

Here is an outline of a recursive insertion function directly
corresponding to these considerations:

@cat avl Insertion, recursive
@c tested 2001/11/10
@<Recursive insertion into AVL tree@> =
@iftangle
/* Inserts item |**data| at or below |*p| in |tree|.
   If the item is inserted, sets |*data| to a pointer to the new item.
   If an item matching |**data| already exists,
   no change is made and sets |*data| to a pointer to the existing item.
   If a memory allocation error occurs, sets |*data| to |NULL|.
   If the height of the tree rooted at |*p| increases, returns 1. @
   Otherwise, returns 0. */
@end iftangle
static int @
probe (struct avl_table *tree, struct avl_node **p, void ***data) @
{
  struct avl_node *y; /* The current node; shorthand for |*p|. */

  assert (tree != NULL && p != NULL && data != NULL);

  y = *p;
  if (y == NULL)
    { @
      @<Found insertion point in recursive AVL insertion@> @
    }
  else /* |y != NULL| */ @
    { @
      @<Move down then up in recursive AVL insertion@> @
    }
}

@

Parameter |p| is declared as a double pointer (|struct avl_node **|) and
|data| as a triple pointer (|void ***|).  In both cases, this is because
C passes arguments by value, so that a function modifying one of its
arguments produces no change in the value seen in the caller.  As a
result, to allow a function to modify a scalar, a pointer to it must be
passed as an argument; to modify a pointer, a double pointer must be
passed; to modify a double pointer, a triple pointer must be passed.
This can result in difficult-to-understand code, so it is often
advisable to copy the dereferenced argument into a local variable for
read-only use, as |*p| is copied into |y| here.

When the insertion point is found, a new node is created and a pointer
to it stored into |*p|.  Because the insertion causes the subtree to
increase in height (from 0 to 1), a value of 1 is then returned:

@<Found insertion point in recursive AVL insertion@> =
y = *p = tree->avl_alloc->libavl_malloc (tree->avl_alloc, sizeof *y);
if (y == NULL) @
  {@-
    *data = NULL;
    return 0;
  }@+

y->avl_data = **data;
*data = &y->avl_data;
y->avl_link[0] = y->avl_link[1] = NULL;
y->avl_balance = 0;

tree->avl_count++;
tree->avl_generation++;

return 1;
@

When we're not at the insertion point, we move down, then back up.
Whether to move down to the left or the right depends on the value of
the item to insert relative to the value in the current node |y|.
Moving down is the domain of the recursive call to |probe()|.  If the
recursive call doesn't increase the height of a subtree of |y|, then
there's nothing further to do, so we return immediately.  Otherwise, on
the way back up, it is necessary to at least adjust |y|'s balance
factor, and possibly to rebalance as well.  If only adjustment of the
balance factor is necessary, it is done and the return value is based on
whether this subtree has changed height in the process.  Rebalancing is
accomplished using the same code used in iterative insertion.  A
rebalanced subtree has the same height as before insertion, so the value
returned is 0.  The details are in the code itself:

@<Move down then up in recursive AVL insertion@> =
struct avl_node *w; /* New root of this subtree; replaces |*p|. */
int cmp;

cmp = tree->avl_compare (**data, y->avl_data, tree->avl_param);
if (cmp < 0) @
  {@-
    if (probe (tree, &y->avl_link[0], data) == 0)
      return 0;

    if (y->avl_balance == +1) @
      {@-
        y->avl_balance = 0;
        return 0;
      }@+
    else if (y->avl_balance == 0) @
      {@-
        y->avl_balance = -1;
        return 1;
      }@+ @
    else @
      { @
        @<Rebalance AVL tree after insertion in left subtree@> @
      }
  }@+ @
else if (cmp > 0) @
  {@-
    struct avl_node *r; /* Right child of |y|, for rebalancing. */

    if (probe (tree, &y->avl_link[1], data) == 0)
      return 0;

    if (y->avl_balance == -1) @
      {@-
        y->avl_balance = 0;
        return 0;
      }@+
    else if (y->avl_balance == 0) @
      {@-
        y->avl_balance = +1;
        return 1;
      }@+ @
    else @
      { @
        @<Rebalance AVL tree after insertion in right subtree@> @
      }
  }@+ @
else /* |cmp == 0| */ @
  {@-
    *data = &y->avl_data;
    return 0;
  }@+

*p = w;
return 0;
@

Finally, we need a wrapper function to start the recursion off correctly
and deal with passing back the results:

@<Recursive insertion into AVL tree@> +=
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree,
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
void **@
avl_probe (struct avl_table *tree, void *item) @
{
  void **ret = &item;

  probe (tree, &tree->avl_root, &ret);

  return ret;
}
@

@node Deleting from an AVL Tree, Traversal of an AVL Tree, Inserting into an AVL Tree, AVL Trees
@section Deletion

Deletion in an AVL tree is remarkably similar to insertion.  The steps
that we go through are analogous:

@enumerate 1
@item @strong{Search} for the item to delete.

@item @strong{Delete} the item.

@item @strong{Update} balance factors.

@item @strong{Rebalance} the tree, if necessary.

@item @strong{Finish up} and return.
@end enumerate

The main difference is that, after a deletion, we may have to rebalance
at more than one level of a tree, starting from the bottom up.  This is
a bit painful, because it means that we have to keep track of all the
nodes that we visit as we search for the node to delete, so that we can
then move back up the tree.  The actual updating of balance factors and
rebalancing steps are similar to those used for insertion.

The following sections cover deletion from an AVL tree in detail.
Before we get started, here's an outline of the function.

@cat avl Deletion (iterative)
@<AVL item deletion function@> =
@iftangle
/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
@end iftangle
void *@
avl_delete (struct avl_table *tree, const void *item) @
{
  /* Stack of nodes. */
  struct avl_node *pa[AVL_MAX_HEIGHT]; /* Nodes. */
  unsigned char da[AVL_MAX_HEIGHT];    /* |avl_link[]| indexes. */
  int k;                               /* Stack pointer. */

  struct avl_node *p;   /* Traverses tree to find node to delete. */
  int cmp;              /* Result of comparison between |item| and |p|. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Search AVL tree for item to delete@>
  @<Step 2: Delete item from AVL tree@>
  @<Steps 3--4: Update balance factors and rebalance after AVL deletion@>
  @<Step 5: Finish up and return after AVL deletion@>
}

@

@references
@bibref{Knuth 1998b}, pages 473--474;
@bibref{Pfaff 1998}.

@menu
* Deleting an AVL Node Step 1 - Search::  
* Deleting an AVL Node Step 2 - Delete::  
* Deleting an AVL Node Step 3 - Update::  
* Deleting an AVL Node Step 4 - Rebalance::  
* Deleting an AVL Node Step 5 - Finish Up::  
* AVL Deletion Symmetric Case::  
@end menu

@node Deleting an AVL Node Step 1 - Search, Deleting an AVL Node Step 2 - Delete, Deleting from an AVL Tree, Deleting from an AVL Tree
@subsection Step 1: Search

The only difference between this search and an ordinary search in a
BST is that we have to keep track of the nodes above the one we're
deleting.  We do this by pushing them onto the stack defined above.
Each iteration through the loop compares |item| to |p|'s data, pushes
the node onto the stack, moves down in the proper direction.  The
first trip through the loop is something of an exception: we hard-code
the comparison result to |-1| so that the pseudo-root node is always
the topmost node on the stack.  When we find a match, we set |item| to
the actual data item found, so that we can return it later.

@anchor{avldelsaveitem}
@<Step 1: Search AVL tree for item to delete@> =
k = 0;
p = (struct avl_node *) &tree->avl_root;
for (cmp = -1; cmp != 0; @
     cmp = tree->avl_compare (item, p->avl_data, tree->avl_param)) @
  {@-
    int dir = cmp > 0;

    pa[k] = p;
    da[k++] = dir;

    p = p->avl_link[dir];
    if (p == NULL)
      return NULL;
  }@+
item = p->avl_data;

@

@node Deleting an AVL Node Step 2 - Delete, Deleting an AVL Node Step 3 - Update, Deleting an AVL Node Step 1 - Search, Deleting from an AVL Tree
@subsection Step 2: Delete

At this point, we've identified |p| as the node to delete.  The node
on the top of the stack, |da[k - 1]|, is |p|'s parent node.  There are the same
three cases we saw in deletion from an ordinary BST (@pxref{Deleting
from a BST}), with the addition of code to copy balance factors and
update the stack.

The code for selecting cases is the same as for BSTs:

@<Step 2: Delete item from AVL tree@> =
if (p->avl_link[1] == NULL)
@ifweave
  { @<Case 1 in AVL deletion@> }
@end ifweave
@iftangle
  @<Case 1 in AVL deletion@>
@end iftangle
else @
  {@-
    struct avl_node *r = p->avl_link[1];
    if (r->avl_link[0] == NULL)
      { @
        @<Case 2 in AVL deletion@> @
      }
    else @
      { @
        @<Case 3 in AVL deletion@> @
      }
  }@+

@

Regardless of the case, we are in the same situation after the
deletion: node |p| has been removed from the tree and the stack
contains |k| nodes at which rebalancing may be necessary.  Later code
may change |p| to point elsewhere, so we free the node immediately.  A
pointer to the item data has already been saved in |item|
(@pageref{avldelsaveitem}):

@<Step 2: Delete item from AVL tree@> +=
tree->avl_alloc->libavl_free (tree->avl_alloc, p);

@

@subsubheading Case 1: |p| has no right child

If |p| has no right child, then we can replace it with its left child,
the same as for BSTs (@pageref{bstdelcase1}).

@<Case 1 in AVL deletion@> =
pa[k - 1]->avl_link[da[k - 1]] = p->avl_link[0];
@

@subsubheading Case 2: |p|'s right child has no left child

If |p| has a right child |r|, which in turn has no left child, then we
replace |p| by |r|, attaching |p|'s left child to |r|, as we would in
an unbalanced BST (@pageref{bstdelcase2}).  In addition, |r| acquires
|p|'s balance factor, and |r| must be added to the stack of nodes
above the deleted node.

@<Case 2 in AVL deletion@> =
r->avl_link[0] = p->avl_link[0];
r->avl_balance = p->avl_balance;
pa[k - 1]->avl_link[da[k - 1]] = r;
da[k] = 1;
pa[k++] = r;
@

@subsubheading Case 3: |p|'s right child has a left child

If |p|'s right child has a left child, then this is the third and most
complicated case.  On the other hand, as a modification from the third
case in an ordinary BST deletion (@pageref{bstdelcase3}), it is rather
simple.  We're deleting the inorder successor of |p|, so we push the
nodes above it onto the stack.  The only trickery is that we do not
know in advance the node that will replace |p|, so we reserve a spot
on the stack for it (|da[j]|) and fill it in later:

@<Case 3 in AVL deletion@> =
struct avl_node *s;
int j = k++;

for (;;) @
  {@-
    da[k] = 0;
    pa[k++] = r;
    s = r->avl_link[0];
    if (s->avl_link[0] == NULL)
      break;

    r = s;
  }@+

s->avl_link[0] = p->avl_link[0];
r->avl_link[0] = s->avl_link[1];
s->avl_link[1] = p->avl_link[1];
s->avl_balance = p->avl_balance;

pa[j - 1]->avl_link[da[j - 1]] = s;
da[j] = 1;
pa[j] = s;
@

@exercise avlmodifydata
Write an alternate version of @<Case 3 in AVL deletion@> that moves data
instead of pointers, as in @value{bstaltdel}.

@answer
This approach cannot be used in @libavl{} (see @value{modifydata}).

@cat avl Deletion, with data modification
@c tested 2001/11/10
@<Case 3 in AVL deletion, alternate version@> =
struct avl_node *s;

da[k] = 1;
pa[k++] = p;
for (;;) @
  {@-
    da[k] = 0;
    pa[k++] = r;
    s = r->avl_link[0];
    if (s->avl_link[0] == NULL)
      break;

    r = s;
  }@+
p->avl_data = s->avl_data;
r->avl_link[0] = s->avl_link[1];
p = s;
@
@end exercise

@exercise
Why is it important that the item data was saved earlier?  (Why
couldn't we save it just before freeing the node?)

@answer
We could, if we use the standard @libavl{} code for deletion case 3.
The alternate version in @value{avlmodifydatabrief} modifies item
data, which would cause the wrong value to be returned later.
@end exercise

@node Deleting an AVL Node Step 3 - Update, Deleting an AVL Node Step 4 - Rebalance, Deleting an AVL Node Step 2 - Delete, Deleting from an AVL Tree
@subsection Step 3: Update Balance Factors

When we updated balance factors in insertion, we were lucky enough to
know in advance which ones we'd need to update.  Moreover, we never
needed to rebalance at more than one level in the tree for any one
insertion.  These two factors conspired in our favor to let us do all
the updating of balance factors at once from the top down.

Everything is not quite so simple in AVL deletion.  We don't have any
easy way to figure out during the search process which balance factors
will need to be updated, and for that matter we may need to perform
rebalancing at multiple levels.  Our strategy must change.

This new approach is not fundamentally different from the previous
one.  We work from the bottom up instead of from the top down.  We
potentially look at each of the nodes along the direct path from the
deleted node to the tree's root, starting at |pa[k - 1]|, the parent
of the deleted node.  For each of these nodes, we adjust its balance
factor and possibly perform rebalancing.  After that, if we're lucky,
this was enough to restore the tree's balancing rule, and we are
finished with updating balance factors and rebalancing.  Otherwise,
we look at the next node, repeating the process.

Here is the loop itself with the details abstracted out:

@<Steps 3--4: Update balance factors and rebalance after AVL deletion@> =
assert (k > 0);
while (--k > 0) @
  {@-
    struct avl_node *y = pa[k];

    if (da[k] == 0)
      { @
        @<Update |y|'s balance factor after left-side AVL deletion@> @
      }
    else @
      { @
        @<Update |y|'s balance factor after right-side AVL deletion@> @
      }
  }@+

@

The reason this works is the loop invariants.  That is, because each
time we look at a node in order to update its balance factor, the
situation is the same.  In particular, if we're looking at a node
|pa[k]|, then we know that it's because the height of its subtree on
side |da[k]| decreased, so that the balance factor of node |pa[k]|
needs to be updated.  The rebalancing operations we choose reflect
this invariant: there are sometimes multiple valid ways to rebalance
at a given node and propagate the results up the tree, but only one
way to do this while maintaining the invariant.  (This is especially
true in red-black trees, for which we will develop code for two
possible invariants under insertion and deletion.)

Updating the balance factor of a node after deletion from its left
side and right side are symmetric, so we'll discuss only the left-side
case here and construct the code for the right-side case later.
Suppose we have a node |y| whose left subtree has decreased in height.
In general, this increases its balance factor, because the balance
factor of a node is the height of its right subtree minus the height
of its left subtree.  More specifically, there are three cases,
treated individually below.

@subsubheading Case 1: |y| has |-| balance factor

If |y| started with a |-| balance factor, then its left subtree was
taller than its right subtree.  Its left subtree has decreased in
height, so the two subtrees must now be the same height and we set
|y|'s balance factor to |0|.  This is between |-1| and |+1|, so there
is no need to rebalance at |y|.  However, binary tree |y| has itself
decreased in height, so that means that we must rebalance the AVL tree
above |y| as well, so we continue to the next iteration of the loop.

The diagram below may help in visualization.  On the left is shown the
original configuration of a subtree, where subtree |a| has height |h|
and subtree |b| has height |h - 1|.  The height of a nonempty binary
tree is one plus the larger of its subtrees' heights, so tree |y| has
height |h + 1|.  The diagram on the right shows the situation after
a node has been deleted from |a|, reducing that subtree's height.  The
new height of tree |y| is |(h - 1) + 1 @= h|.

@center @image{avldelre1}

@subsubheading Case 2: |y| has |0| balance factor

If |y| started with a |0| balance factor, and its left subtree decreased in
height, then the result is that its right subtree is now taller than its
left subtree, so the new balance factor is |+|.  However, the overall
height of binary tree |y| has not changed, so no balance factors above
|y| need to be changed, and we are done, hence we |break| to exit the
loop.

Here's the corresponding diagram, similar to the one for the previous
case.  The height of tree |y| on both sides of the diagram is |h + 1|,
since |y|'s taller subtree in both cases has height |h|.

@center @image{avldelre2}

@subsubheading Case 3: |y| has |+| balance factor

Otherwise, |y| started with a |+| balance factor, so the decrease in
height of its left subtree, which was already shorter than its right
subtree, causes a violation of the AVL constraint with a |+2| balance
factor.  We need to rebalance.  After rebalancing, we may or may not
have to rebalance further up the tree.

Here's a diagram of what happens to forcing rebalancing:

@center @image{avldelre3}

@subsubheading Implementation

The implementation is straightforward:

@<Update |y|'s balance factor after left-side AVL deletion@> =
y->avl_balance++;
if (y->avl_balance == +1)
  break;
else if (y->avl_balance == +2)
  { @
    @<Step 4: Rebalance after AVL deletion@> @
  }
@

@node Deleting an AVL Node Step 4 - Rebalance, Deleting an AVL Node Step 5 - Finish Up, Deleting an AVL Node Step 3 - Update, Deleting from an AVL Tree
@subsection Step 4: Rebalance

Now we have to write code to rebalance when it becomes necessary.
We'll use rotations to do this, as before.  Again, we'll distinguish
the cases on the basis of |x|'s balance factor, where |x| is |y|'s
right child:

@<Step 4: Rebalance after AVL deletion@> =
struct avl_node *x = y->avl_link[1];
if (x->avl_balance == -1)
  { @
    @<Left-side rebalancing case 1 in AVL deletion@> @
  }
else @
  { @
    @<Left-side rebalancing case 2 in AVL deletion@> @
  }
@

@subsubheading Case 1: |x| has |-| balance factor
@anchor{avldelcase1}

If |x| has a |-| balance factor, we handle rebalancing in a manner
analogous to case 2 for insertion.  In fact, we reuse the code.  We
rotate right at |x|, then left at |y|.  |w| is the left child of |x|.
The two rotations look like this:

@center @image{avldel1}

@<Left-side rebalancing case 1 in AVL deletion@> =
struct avl_node *w;
@<Rotate right at |x| then left at |y| in AVL tree@>
pa[k - 1]->avl_link[da[k - 1]] = w;
@

@subsubheading Case 2: |x| has |+| or |0| balance factor

@anchor{avldel2}
When |x|'s balance factor is |+|, the needed treatment is analogous to
Case 1 for insertion.  We simply rotate left at |y| and update the
pointer to the subtree, then update balance factors.  The deletion and
rebalancing then look like this:

@center @image{avldel2}

When |x|'s balance factor is |0|, we perform the same rotation, but the
height of the overall subtree does not change, so we're done and can
exit the loop with |break|.  Here's what the deletion and rebalancing
look like for this subcase:

@center @image{avldel3}

@<Left-side rebalancing case 2 in AVL deletion@> =
y->avl_link[1] = x->avl_link[0];
x->avl_link[0] = y;
pa[k - 1]->avl_link[da[k - 1]] = x;
if (x->avl_balance == 0) @
  {@-
    x->avl_balance = -1;
    y->avl_balance = +1;
    break;
  }@+
else @
  x->avl_balance = y->avl_balance = 0;
@

@exercise
In @<Step 4: Rebalance after AVL deletion@>, we refer to fields in
|x|, the right child of |y|, without checking that |y| has a non-null
right child.  Why can we assume that node |x| is non-null?

@answer
Tree |y| started out with a |+| balance factor, meaning that its right
subtree is taller than its left.  So, even if |y|'s left subtree had
height 0, its right subtree has at least height 1, meaning that |y|
must have at least one right child.
@end exercise

@exercise
Describe the shape of a tree that might require rebalancing at every
level above a particular node.  Give an example.

@answer
Rebalancing is required at each level if, at every level of the tree,
the deletion causes a |+2| or |-2| balance factor at a node |p| while
there is a |+1| or |-1| balance factor at |p|'s child opposite the
deletion.

For example, consider the AVL tree below:

@center @image{avlmuchbal}

Deletion of node 32 in this tree leads to a |-2| balance factor on the
left side of node 31, causing a right rotation at node 31.  This
shortens the right subtree of node 28, causing it to have a |-2|
balance factor, leading to a right rotation there.  This shortens the
right subtree of node 20, causing it to have a |-2| balance factor,
forcing a right rotation there, too.  Here is the final tree:

@center @image{avlmuchbal2}

Incidentally, our original tree was an example of a ``Fibonacci
tree'', a kind of binary tree whose form is defined recursively, as
follows.  A Fibonacci tree of order 0 is an empty tree and a Fibonacci
tree of order 1 is a single node.  A Fibonacci tree of order |n @>= 2|
is a node whose left subtree is a Fibonacci tree of order |n - 1| and
whose right subtree is a Fibonacci tree of order |n - 2|.  Our example
is a Fibonacci tree of order 7.  Any big-enough Fibonacci tree will
exhibit this pathological behavior upon AVL deletion of its maximum
node.
@end exercise

@node Deleting an AVL Node Step 5 - Finish Up, AVL Deletion Symmetric Case, Deleting an AVL Node Step 4 - Rebalance, Deleting from an AVL Tree
@subsection Step 5: Finish Up

@<Step 5: Finish up and return after AVL deletion@> =
tree->avl_count--;
tree->avl_generation++;
return (void *) item;
@

@node AVL Deletion Symmetric Case,  , Deleting an AVL Node Step 5 - Finish Up, Deleting from an AVL Tree
@subsection Symmetric Case

Here's the code for the symmetric case, where the deleted node was in the
right subtree of its parent.

@<Update |y|'s balance factor after right-side AVL deletion@> =
y->avl_balance--;
if (y->avl_balance == -1)
  break;
else if (y->avl_balance == -2) @
  {@-
    struct avl_node *x = y->avl_link[0];
    if (x->avl_balance == +1) @
      {@-
        struct avl_node *w;
        @<Rotate left at |x| then right at |y| in AVL tree@>
        pa[k - 1]->avl_link[da[k - 1]] = w;
      }@+ @
    else @
      {@-
        y->avl_link[0] = x->avl_link[1];
        x->avl_link[1] = y;
        pa[k - 1]->avl_link[da[k - 1]] = x;
        if (x->avl_balance == 0) @
          {@-
            x->avl_balance = +1;
            y->avl_balance = -1;
            break;
          }@+
        else @
          x->avl_balance = y->avl_balance = 0;
      }@+
  }@+
@

@node Traversal of an AVL Tree, Copying an AVL Tree, Deleting from an AVL Tree, AVL Trees
@section Traversal

Traversal is largely unchanged from BSTs.  However, we can be confident
that the tree won't easily exceed the maximum stack height, because of
the AVL balance condition, so we can omit checking for stack overflow.

@<AVL traversal functions@> =
@<BST traverser refresher; bst => avl@>
@<BST traverser null initializer; bst => avl@>
@<AVL traverser least-item initializer@>
@<AVL traverser greatest-item initializer@>
@<AVL traverser search initializer@>
@<AVL traverser insertion initializer@>
@<BST traverser copy initializer; bst => avl@>
@<AVL traverser advance function@>
@<AVL traverser back up function@>
@<BST traverser current item function; bst => avl@>
@<BST traverser replacement function; bst => avl@>
@

We do need to make a new implementation of the insertion traverser
initializer.  Because insertion into an AVL tree is so complicated, we
just write this as a wrapper to |avl_probe()|.  There probably wouldn't
be much of a speed improvement by inlining the code anyhow:

@cat avl Initialization of traverser to inserted item
@<AVL traverser insertion initializer@> =
@iftangle
/* Attempts to insert |item| into |tree|.
   If |item| is inserted successfully, it is returned and |trav| is @
   initialized to its location.
   If a duplicate is found, it is returned and |trav| is initialized to
   its location.  No replacement of the item occurs.
   If a memory allocation failure occurs, |NULL| is returned and |trav|
   is initialized to the null item. */
@end iftangle
void *@
avl_t_insert (struct avl_traverser *trav, struct avl_table *tree, void *item) @
{
  void **p;

  assert (trav != NULL && tree != NULL && item != NULL);

  p = avl_probe (tree, item);
  if (p != NULL) @
    {@-
      trav->avl_table = tree;
      trav->avl_node =
        ((struct avl_node *) @
         ((char *) p - offsetof (struct avl_node, avl_data)));
      trav->avl_generation = tree->avl_generation - 1;
      return *p;
    }@+ @
  else @
    {@-
      avl_t_init (trav, tree);
      return NULL;
    }@+
}

@

We will present the rest of the modified functions without further
comment.

@cat avl Initialization of traverser to least item
@<AVL traverser least-item initializer@> =
@iftangle
/* Initializes |trav| for |tree| @
   and selects and returns a pointer to its least-valued item.
   Returns |NULL| if |tree| contains no nodes. */
@end iftangle
void *@
avl_t_first (struct avl_traverser *trav, struct avl_table *tree) @
{
  struct avl_node *x;

  assert (tree != NULL && trav != NULL);

  trav->avl_table = tree;
  trav->avl_height = 0;
  trav->avl_generation = tree->avl_generation;

  x = tree->avl_root;
  if (x != NULL)
    while (x->avl_link[0] != NULL) @
      {@-
	assert (trav->avl_height < AVL_MAX_HEIGHT);
	trav->avl_stack[trav->avl_height++] = x;
	x = x->avl_link[0];
      }@+
  trav->avl_node = x;

  return x != NULL ? x->avl_data : NULL;
}

@

@cat avl Initialization of traverser to greatest item
@<AVL traverser greatest-item initializer@> =
@iftangle
/* Initializes |trav| for |tree| @
   and selects and returns a pointer to its greatest-valued item.
   Returns |NULL| if |tree| contains no nodes. */
@end iftangle
void *@
avl_t_last (struct avl_traverser *trav, struct avl_table *tree) @
{
  struct avl_node *x;

  assert (tree != NULL && trav != NULL);

  trav->avl_table = tree;
  trav->avl_height = 0;
  trav->avl_generation = tree->avl_generation;

  x = tree->avl_root;
  if (x != NULL)
    while (x->avl_link[1] != NULL) @
      {@-
	assert (trav->avl_height < AVL_MAX_HEIGHT);
	trav->avl_stack[trav->avl_height++] = x;
	x = x->avl_link[1];
      }@+
  trav->avl_node = x;

  return x != NULL ? x->avl_data : NULL;
}

@

@cat avl Initialization of traverser to found item
@<AVL traverser search initializer@> =
@iftangle
/* Searches for |item| in |tree|.
   If found, initializes |trav| to the item found and returns the item @
   as well.
   If there is no matching item, initializes |trav| to the null item @
   and returns |NULL|. */
@end iftangle
void *@
avl_t_find (struct avl_traverser *trav, struct avl_table *tree, void *item) @
{
  struct avl_node *p, *q;

  assert (trav != NULL && tree != NULL && item != NULL);
  trav->avl_table = tree;
  trav->avl_height = 0;
  trav->avl_generation = tree->avl_generation;
  for (p = tree->avl_root; p != NULL; p = q) @
    {@-
      int cmp = tree->avl_compare (item, p->avl_data, tree->avl_param);

      if (cmp < 0) @
	q = p->avl_link[0];
      else if (cmp > 0) @
	q = p->avl_link[1];
      else /* |cmp == 0| */ @
	{@-
	  trav->avl_node = p;
	  return p->avl_data;
	}@+

      assert (trav->avl_height < AVL_MAX_HEIGHT);
      trav->avl_stack[trav->avl_height++] = p;
    }@+

  trav->avl_height = 0;
  trav->avl_node = NULL;
  return NULL;
}

@

@cat avl Advancing a traverser
@<AVL traverser advance function@> =
@iftangle
/* Returns the next data item in inorder @
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
@end iftangle
void *@
avl_t_next (struct avl_traverser *trav) @
{
  struct avl_node *x;

  assert (trav != NULL);

  if (trav->avl_generation != trav->avl_table->avl_generation)
    trav_refresh (trav);

  x = trav->avl_node;
  if (x == NULL) @
    {@-
      return avl_t_first (trav, trav->avl_table);
    }@+ @
  else if (x->avl_link[1] != NULL) @
    {@-
      assert (trav->avl_height < AVL_MAX_HEIGHT);
      trav->avl_stack[trav->avl_height++] = x;
      x = x->avl_link[1];

      while (x->avl_link[0] != NULL) @
	{@-
          assert (trav->avl_height < AVL_MAX_HEIGHT);
	  trav->avl_stack[trav->avl_height++] = x;
	  x = x->avl_link[0];
	}@+
    }@+ @
  else @
    {@-
      struct avl_node *y;

      do @
	{@-
	  if (trav->avl_height == 0) @
	    {@-
	      trav->avl_node = NULL;
	      return NULL;
	    }@+

	  y = x;
	  x = trav->avl_stack[--trav->avl_height];
	}@+ @
      while (y == x->avl_link[1]);
    }@+
  trav->avl_node = x;

  return x->avl_data;
}

@

@cat avl Backing up a traverser
@<AVL traverser back up function@> =
@iftangle
/* Returns the previous data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
@end iftangle
void *@
avl_t_prev (struct avl_traverser *trav) @
{
  struct avl_node *x;

  assert (trav != NULL);

  if (trav->avl_generation != trav->avl_table->avl_generation)
    trav_refresh (trav);

  x = trav->avl_node;
  if (x == NULL) @
    {@-
      return avl_t_last (trav, trav->avl_table);
    }@+ @
  else if (x->avl_link[0] != NULL) @
    {@-
      assert (trav->avl_height < AVL_MAX_HEIGHT);
      trav->avl_stack[trav->avl_height++] = x;
      x = x->avl_link[0];

      while (x->avl_link[1] != NULL) @
	{@-
          assert (trav->avl_height < AVL_MAX_HEIGHT);
	  trav->avl_stack[trav->avl_height++] = x;
	  x = x->avl_link[1];
	}@+
    }@+ @
  else @
    {@-
      struct avl_node *y;

      do @
	{@-
	  if (trav->avl_height == 0) @
	    {@-
	      trav->avl_node = NULL;
	      return NULL;
	    }@+

	  y = x;
	  x = trav->avl_stack[--trav->avl_height];
	}@+ @
      while (y == x->avl_link[0]);
    }@+
  trav->avl_node = x;

  return x->avl_data;
}

@

@exercise
Explain the meaning of this ugly expression, used in |avl_t_insert()|:

@<Anonymous@> =
    (struct avl_node *) ((char *) p - offsetof (struct avl_node, avl_data))
@

@answer
At this point in the code, |p| points to the |avl_data| member of an
|struct avl_node|.  We want a pointer to the |struct avl_node| itself.
To do this, we just subtract the offset of the |avl_data| member within
the structure.  A cast to |char *| is necessary before the subtraction,
because |offsetof| returns a count of bytes, and a cast to |struct
avl_node *| afterward, to make the result the right type.
@end exercise

@node Copying an AVL Tree, Testing AVL Trees, Traversal of an AVL Tree, AVL Trees
@section Copying

Copying an AVL tree is similar to copying a BST.  The only important
difference is that we have to copy the AVL balance factor between nodes
as well as node data.  We don't check our stack height here, either.

@cat avl Copying (iterative)
@<AVL copy function@> =
@<BST copy error helper function; bst => avl@>

@iftangle
/* Copies |org| to a newly created tree, which is returned.
   If |copy != NULL|, each data item in |org| is first passed to |copy|,
   and the return values are inserted into the tree, 
   with |NULL| return values taken as indications of failure.
   On failure, destroys the partially created new tree,
   applying |destroy|, if non-null, to each item in the new tree so far, @
   and returns |NULL|.
   If |allocator != NULL|, it is used for allocation in the new tree.
   Otherwise, the same allocator used for |org| is used. */
@end iftangle
struct avl_table *@
avl_copy (const struct avl_table *org, avl_copy_func *copy,
	  avl_item_func *destroy, struct libavl_allocator *allocator) @
{
  struct avl_node *stack[2 * (AVL_MAX_HEIGHT + 1)];
  int height = 0;

  struct avl_table *new;
  const struct avl_node *x;
  struct avl_node *y;

  assert (org != NULL);
  new = avl_create (org->avl_compare, org->avl_param,
                    allocator != NULL ? allocator : org->avl_alloc);
  if (new == NULL)
    return NULL;
  new->avl_count = org->avl_count;
  if (new->avl_count == 0)
    return new;

  x = (const struct avl_node *) &org->avl_root;
  y = (struct avl_node *) &new->avl_root;
  for (;;) @
    {@-
      while (x->avl_link[0] != NULL) @
	{@-
	  assert (height < 2 * (AVL_MAX_HEIGHT + 1));

	  y->avl_link[0] = @
            new->avl_alloc->libavl_malloc (new->avl_alloc,
                                           sizeof *y->avl_link[0]);
	  if (y->avl_link[0] == NULL) @
	    {@-
	      if (y != (struct avl_node *) &new->avl_root) @
		{@-
		  y->avl_data = NULL;
		  y->avl_link[1] = NULL;
		}@+

	      copy_error_recovery (stack, height, new, destroy);
	      return NULL;
	    }@+

	  stack[height++] = (struct avl_node *) x;
	  stack[height++] = y;
	  x = x->avl_link[0];
	  y = y->avl_link[0];
	}@+
      y->avl_link[0] = NULL;

      for (;;) @
	{@-
          y->avl_balance = x->avl_balance;
	  if (copy == NULL)
	    y->avl_data = x->avl_data;
	  else @
	    {@-
	      y->avl_data = copy (x->avl_data, org->avl_param);
	      if (y->avl_data == NULL) @
		{@-
		  y->avl_link[1] = NULL;
		  copy_error_recovery (stack, height, new, destroy);
		  return NULL;
		}@+
	    }@+

	  if (x->avl_link[1] != NULL) @
	    {@-
	      y->avl_link[1] = @
                new->avl_alloc->libavl_malloc (new->avl_alloc,
                                               sizeof *y->avl_link[1]);
	      if (y->avl_link[1] == NULL) @
		{@-
		  copy_error_recovery (stack, height, new, destroy);
		  return NULL;
		}@+

	      x = x->avl_link[1];
	      y = y->avl_link[1];
	      break;
	    }@+
	  else @
	    y->avl_link[1] = NULL;

	  if (height <= 2)
	    return new;

	  y = stack[--height];
	  x = stack[--height];
	}@+
    }@+
}

@

@node Testing AVL Trees,  , Copying an AVL Tree, AVL Trees
@section Testing

Our job isn't done until we can demonstrate that our code works.  We'll
do this with a test program built using the framework from the previous
chapter (@pxref{Testing BST Functions}).  All we have to do is
produce functions for AVL trees that correspond to each of those in
@(bst-test.c@>.  This just involves making small changes to the
functions used there.  They are presented below without additional
comment.

@(avl-test.c@> =
@<Program License@>
#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include "avl.h"
#include "test.h"

@<BST print function; bst => avl@>
@<BST traverser check function; bst => avl@>
@<Compare two AVL trees for structure and content@>
@<Recursively verify AVL tree structure@>
@<AVL tree verify function@>
@<BST test function; bst => avl@>
@<BST overflow test function; bst => avl@>
@

@<Compare two AVL trees for structure and content@> =
@iftangle
/* Compares binary trees rooted at |a| and |b|,
   making sure that they are identical. */
@end iftangle
static int @
compare_trees (struct avl_node *a, struct avl_node *b) @
{
  int okay;

  if (a == NULL || b == NULL) @
    {@-
      assert (a == NULL && b == NULL);
      return 1;
    }@+

  if (*(int *) a->avl_data != *(int *) b->avl_data
      || ((a->avl_link[0] != NULL) != (b->avl_link[0] != NULL))
      || ((a->avl_link[1] != NULL) != (b->avl_link[1] != NULL))
      || a->avl_balance != b->avl_balance) @
    {@-
      printf (" Copied nodes differ: a=%d (bal=%d) b=%d (bal=%d) a:",
              *(int *) a->avl_data, a->avl_balance,
              *(int *) b->avl_data, b->avl_balance);

      if (a->avl_link[0] != NULL) @
	printf ("l");
      if (a->avl_link[1] != NULL) @
	printf ("r");

      printf (" b:");
      if (b->avl_link[0] != NULL) @
	printf ("l");
      if (b->avl_link[1] != NULL) @
	printf ("r");

      printf ("\n");
      return 0;
    }@+

  okay = 1;
  if (a->avl_link[0] != NULL) @
    okay &= compare_trees (a->avl_link[0], b->avl_link[0]);
  if (a->avl_link[1] != NULL) @
    okay &= compare_trees (a->avl_link[1], b->avl_link[1]);
  return okay;
}

@

@<Recursively verify AVL tree structure@> =
/* Examines the binary tree rooted at |node|.  
   Zeroes |*okay| if an error occurs.  @
   Otherwise, does not modify |*okay|.
   Sets |*count| to the number of nodes in that tree, @
   including |node| itself if |node != NULL|.
   Sets |*height| to the tree's height.
   All the nodes in the tree are verified to be at least |min| @
   but no greater than |max|. */
static void @
recurse_verify_tree (struct avl_node *node, int *okay, size_t *count, 
                     int min, int max, int *height) @
{
  int d;                /* Value of this node's data. */
  size_t subcount[2];   /* Number of nodes in subtrees. */
  int subheight[2];     /* Heights of subtrees. */

  if (node == NULL) @
    {@-
      *count = 0;
      *height = 0;
      return;
    }@+
  d = *(int *) node->avl_data;

  @<Verify binary search tree ordering@>

  recurse_verify_tree (node->avl_link[0], okay, &subcount[0], 
                       min, d -  1, &subheight[0]);
  recurse_verify_tree (node->avl_link[1], okay, &subcount[1], 
                       d + 1, max, &subheight[1]);
  *count = 1 + subcount[0] + subcount[1];
  *height = 1 + (subheight[0] > subheight[1] ? subheight[0] : subheight[1]);

  @<Verify AVL node balance factor@>
}

@

@<Verify AVL node balance factor@> =
if (subheight[1] - subheight[0] != node->avl_balance) @
  {@-
    printf (" Balance factor of node %d is %d, but should be %d.\n",
            d, node->avl_balance, subheight[1] - subheight[0]);
    *okay = 0;
  }@+
else if (node->avl_balance < -1 || node->avl_balance > +1) @
  {@-
    printf (" Balance factor of node %d is %d.\n", d, node->avl_balance);
    *okay = 0;
  }@+
@

@<AVL tree verify function@> =
@iftangle
/* Checks that |tree| is well-formed
   and verifies that the values in |array[]| are actually in |tree|.
   There must be |n| elements in |array[]| and |tree|.
   Returns nonzero only if no errors detected. */
@end iftangle
static int @
verify_tree (struct avl_table *tree, int array[], size_t n) @
{
  int okay = 1;

  @<Check |tree->bst_count| is correct; bst => avl@>

  if (okay) @
    { @
      @<Check AVL tree structure@> @
    }

  if (okay) @
    { @
      @<Check that the tree contains all the elements it should; bst => avl@> @
    }

  if (okay) @
    { @
      @<Check that forward traversal works; bst => avl@> @
    }

  if (okay) @
    { @
      @<Check that backward traversal works; bst => avl@> @
    }

  if (okay) @
    { @
      @<Check that traversal from the null element works; bst => avl@> @
    }

  return okay;
}

@

@<Check AVL tree structure@> =
/* Recursively verify tree structure. */
size_t count;
int height;

recurse_verify_tree (tree->avl_root, &okay, &count, @
                     0, INT_MAX, &height);
@<Check counted nodes@>
@

