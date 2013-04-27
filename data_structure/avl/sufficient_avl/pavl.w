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

@deftypedef pavl_comparison_func
@deftypedef pavl_item_func
@deftypedef pavl_copy_func

@node AVL Trees with Parent Pointers, Red-Black Trees with Parent Pointers, BSTs with Parent Pointers, Top
@chapter AVL Trees with Parent Pointers

This chapter adds parent pointers to AVL trees.  The result is a data
structure that combines the strengths of AVL trees and trees with
parent pointers.  Of course, there's no free lunch: it combines their
disadvantages, too.

The abbreviation we'll use for the term "AVL tree with parent
pointers'' is ``PAVL tree'', with corresponding prefix |pavl_|.
Here's the outline for the PAVL table implementation:

@(pavl.h@> =
@<Library License@>
#ifndef PAVL_H
#define PAVL_H 1

#include <stddef.h>

@<Table types; tbl => pavl@>
@<BST maximum height; bst => pavl@>
@<TBST table structure; tbst => pavl@>
@<PAVL node structure@>
@<TBST traverser structure; tbst => pavl@>
@<Table function prototypes; tbl => pavl@>

#endif /* pavl.h */
@ 

@(pavl.c@> =
@<Library License@>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "pavl.h"

@<PAVL functions@>
@

@menu
* PAVL Data Types::             
* PBST Rotations::              
* PAVL Operations::             
* Inserting into a PAVL Tree::  
* Deleting from a PAVL Tree::   
* Traversing a PAVL Tree::      
* Copying a PAVL Tree::         
* Testing PAVL Trees::          
@end menu

@node PAVL Data Types, PBST Rotations, AVL Trees with Parent Pointers, AVL Trees with Parent Pointers
@section Data Types

A PAVL tree node has a parent pointer and an AVL balance field in
addition to the usual members needed for any binary search tree:

@<PAVL node structure@> =
/* An PAVL tree node. */
struct pavl_node @
  {@-
    struct pavl_node *pavl_link[2]; /* Subtrees. */
    struct pavl_node *pavl_parent;  /* Parent node. */
    void *pavl_data;                /* Pointer to data. */
    signed char pavl_balance;       /* Balance factor. */
  };@+

@

The other data structures are the same as the corresponding ones for
TBSTs.

@node PBST Rotations, PAVL Operations, PAVL Data Types, AVL Trees with Parent Pointers
@section Rotations

Let's consider how rotations work in PBSTs.  Here's the usual
illustration of a rotation:

@center @image{rotation}

As we move from the left side to the right side, rotating right at
|Y|, the parents of up to three nodes change.  In any case, |Y|'s
former parent becomes |X|'s new parent and |X| becomes |Y|'s new
parent.  In addition, if |b| is not an empty subtree, then the parent
of subtree |b|'s root node becomes |Y|.  Moving from right to left,
the situation is reversed.

@references
@bibref{Cormen 1990}, section 14.2.

@exercise pbstrot
Write functions for right and left rotations in BSTs with parent
pointers, analogous to those for plain BSTs developed in
@value{bstrotation}.

@answer
@cat pbst Rotation, right
@<Anonymous@> =
/* Rotates right at |*yp|. */
static void @
rotate_right (struct pbst_node **yp) @
{
  struct pbst_node *y = *yp;
  struct pbst_node *x = y->pbst_link[0];
  y->pbst_link[0] = x->pbst_link[1];
  x->pbst_link[1] = y;
  *yp = x;
  x->pbst_parent = y->pbst_parent;
  y->pbst_parent = x;
  if (y->pbst_link[0] != NULL)
    y->pbst_link[0]->pbst_parent = y;
}
@

@cat pbst Rotation, left
@<Anonymous@> =
/* Rotates left at |*xp|. */
static void @
rotate_left (struct pbst_node **xp) @
{
  struct pbst_node *x = *xp;
  struct pbst_node *y = x->pbst_link[1];
  x->pbst_link[1] = y->pbst_link[0];
  y->pbst_link[0] = x;
  *xp = y;
  y->pbst_parent = x->pbst_parent;
  x->pbst_parent = y;
  if (x->pbst_link[1] != NULL)
    x->pbst_link[1]->pbst_parent = x;
}
@
@end exercise

@node PAVL Operations, Inserting into a PAVL Tree, PBST Rotations, AVL Trees with Parent Pointers
@section Operations

As usual, we must reimplement the item insertion and deletion
functions.  The tree copy function and some of the traversal functions
also need to be rewritten.

@<PAVL functions@> =
@<TBST creation function; tbst => pavl@>
@<BST search function; bst => pavl@>
@<PAVL item insertion function@>
@<Table insertion convenience functions; tbl => pavl@>
@<PAVL item deletion function@>
@<PAVL traversal functions@>
@<PAVL copy function@>
@<BST destruction function; bst => pavl@>
@<Default memory allocation functions; tbl => pavl@>
@<Table assertion functions; tbl => pavl@>
@

@node Inserting into a PAVL Tree, Deleting from a PAVL Tree, PAVL Operations, AVL Trees with Parent Pointers
@section Insertion

The same basic algorithm has been used for insertion in all of our AVL
tree variants so far.  (In fact, all three functions share the same
set of local variables.)  For PAVL trees, we will slightly modify our
approach.  In particular, until now we have cached comparison results
on the way down in order to quickly adjust balance factors after the
insertion.  Parent pointers let us avoid this caching but still
efficiently update balance factors.

Before we look closer, here is the function's outline:

@cat pavl Insertion
@<PAVL item insertion function@> =
@iftangle
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree, 
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
@end iftangle
void **@
pavl_probe (struct pavl_table *tree, void *item) @
{
  struct pavl_node *y;     /* Top node to update balance factor, and parent. */
  struct pavl_node *p, *q; /* Iterator, and parent. */
  struct pavl_node *n;     /* Newly inserted node. */
  struct pavl_node *w;     /* New root of rebalanced subtree. */
  int dir;                 /* Direction to descend. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Search PAVL tree for insertion point@>
  @<Step 2: Insert PAVL node@>
  @<Step 3: Update balance factors after PAVL insertion@>
  @<Step 4: Rebalance after PAVL insertion@>
}

@

@menu
* Steps 1 and 2 in PAVL Insertion::  
* Step 3 in PAVL Insertion::    
* Rebalancing PAVL Trees::      
* PAVL Insertion Symmetric Case::  
@end menu

@node Steps 1 and 2 in PAVL Insertion, Step 3 in PAVL Insertion, Inserting into a PAVL Tree, Inserting into a PAVL Tree
@subsection Steps 1 and 2: Search and Insert

We search much as before.  Despite use of the parent pointers, we
preserve the use of |q| as the parent of |p| because the termination
condition is a value of |NULL| for |p|, and |NULL| has no parent.
(Thus, |q| is not, strictly speaking, always |p|'s parent, but rather
the last node examined before |p|.)

Because of parent pointers, there is no need for variable |z|, used in
earlier implementations of AVL insertion to maintain |y|'s parent.

@<Step 1: Search PAVL tree for insertion point@> =
y = tree->pavl_root;
for (q = NULL, p = tree->pavl_root; p != NULL; q = p, p = p->pavl_link[dir]) @
  {@-
    int cmp = tree->pavl_compare (item, p->pavl_data, tree->pavl_param);
    if (cmp == 0)
      return &p->pavl_data;
    dir = cmp > 0;

    if (p->pavl_balance != 0)
      y = p;
  }@+

@

The node to create and insert the new node is based on that for PBSTs.
There is a special case for a node inserted into an empty tree:

@<Step 2: Insert PAVL node@> =
@<Step 2: Insert PBST node; pbst => pavl@>
n->pavl_balance = 0;
if (tree->pavl_root == n)
  return &n->pavl_data;

@

@node Step 3 in PAVL Insertion, Rebalancing PAVL Trees, Steps 1 and 2 in PAVL Insertion, Inserting into a PAVL Tree
@subsection Step 3: Update Balance Factors

Until now, in step 3 of insertion into AVL trees we've always updated
balance factors from the top down, starting at |y| and working our way
down to |n| (see, e.g., @<Step 3: Update balance factors after AVL
insertion@>).  This approach was somewhat unnatural, but it worked.
The original reason we did it this way was that it was either
impossible, as for AVL and RTAVL trees, or slow, as for TAVL trees, to
efficiently move upward in a tree.  That's not a consideration
anymore, so we can do it from the bottom up and in the process
eliminate the cache used before.

At each step, we need to know the node to update and, for that node,
on which side of its parent it is a child.  In the code below, |q| is
the node and |dir| is the side.

@<Step 3: Update balance factors after PAVL insertion@> =
for (p = n; p != y; p = q) @
  {@-
    q = p->pavl_parent;
    dir = q->pavl_link[0] != p;
    if (dir == 0)
      q->pavl_balance--;
    else @
      q->pavl_balance++;
  }@+

@

@exercise
Does this step 3 update the same set of balance factors as would a
literal adaptation of @<Step 3: Update balance factors after AVL
insertion@>?

@answer
Yes.  Both code segments update the nodes along the direct path from
|y| down to |n|, including node |y| but not node |n|.  The plain AVL
code excluded node |n| by updating nodes as it moved down to them and
making arrival at node |n| the loop's termination condition.  The PAVL
code excludes node |n| by starting at it but updating the parent of
each visited node instead of the node itself.  

There still could be a problem at the edge case where no nodes'
balance factors were to be updated, but there is no such case.  There
is always at least one balance factor to update, because every
inserted node has a parent whose balance factor is affected by its
insertion.  The one exception would be the first node inserted into an
empty tree, but that was already handled as a special case.
@end exercise

@exercise
Would it be acceptable to substitute |q->pavl_link[1] == p| for
|q->pavl_link[0] != p| in the code segment above?

@answer
Sure.  There is no parallel to @value{ynezlink0} because |q| is never
the pseudo-root.
@end exercise

@node Rebalancing PAVL Trees, PAVL Insertion Symmetric Case, Step 3 in PAVL Insertion, Inserting into a PAVL Tree
@subsection Step 4: Rebalance

The changes needed to the rebalancing code for parent pointers
resemble the changes for threads in that we can reuse most of the code
from plain AVL trees.  We just need to add a few new statements to
each rebalancing case to adjust the parent pointers of nodes whose
parents have changed.

The outline of the rebalancing code should be familiar by now.  The
code to update the link to the root of the rebalanced subtree is the
only change.  It needs a special case for the root, because the parent
pointer of the root node is a null pointer, not the pseudo-root node.
The other choice would simplify this piece of code, but complicate
other pieces (@pxref{PBST Data Types}).

@<Step 4: Rebalance after PAVL insertion@> =
if (y->pavl_balance == -2)
  { @
    @<Rebalance PAVL tree after insertion in left subtree@> @
  }
else if (y->pavl_balance == +2)
  { @
    @<Rebalance PAVL tree after insertion in right subtree@> @
  }
else @
  return &n->pavl_data;
if (w->pavl_parent != NULL)
  w->pavl_parent->pavl_link[y != w->pavl_parent->pavl_link[0]] = w;
else @
  tree->pavl_root = w;

return &n->pavl_data;
@

As usual, the cases for rebalancing are distinguished based on the
balance factor of the child of the unbalanced node on its taller side:

@<Rebalance PAVL tree after insertion in left subtree@> =
struct pavl_node *x = y->pavl_link[0];
if (x->pavl_balance == -1)
  { @
    @<Rebalance for |-| balance factor in PAVL insertion in left subtree@> @
  } 
else @
  { @
    @<Rebalance for |+| balance factor in PAVL insertion in left subtree@> @
  }
@

@subsubheading Case 1: |x| has |-| balance factor

The added code here is exactly the same as that added to BST rotation
to handle parent pointers (in @value{pbstrot}), and for good reason
since this case simply performs a right rotation in the PAVL tree.

@<Rebalance for |-| balance factor in PAVL insertion in left subtree@> =
@<Rotate right at |y| in AVL tree; avl => pavl@>
x->pavl_parent = y->pavl_parent;
y->pavl_parent = x;
if (y->pavl_link[0] != NULL)
  y->pavl_link[0]->pavl_parent = y;
@

@subsubheading Case 2: |x| has |+| balance factor

When |x| has a |+| balance factor, we need a double rotation, composed
of a right rotation at |x| followed by a left rotation at |y|.  The
diagram below show the effect of each of the rotations:

@center @image{avlcase2}

Along with this double rotation comes a small bulk discount in parent
pointer assignments.  The parent of |w| changes in both rotations, but
we only need assign to it its final value once, ignoring the
intermediate value.

@<Rebalance for |+| balance factor in PAVL insertion in left subtree@> =
@<Rotate left at |x| then right at |y| in AVL tree; avl => pavl@>
w->pavl_parent = y->pavl_parent;
x->pavl_parent = y->pavl_parent = w;
if (x->pavl_link[1] != NULL)
  x->pavl_link[1]->pavl_parent = x;
if (y->pavl_link[0] != NULL)
  y->pavl_link[0]->pavl_parent = y;
@

@node PAVL Insertion Symmetric Case,  , Rebalancing PAVL Trees, Inserting into a PAVL Tree
@subsection Symmetric Case

@<Rebalance PAVL tree after insertion in right subtree@> =
struct pavl_node *x = y->pavl_link[1];
if (x->pavl_balance == +1)
  { @
    @<Rebalance for |+| balance factor in PAVL insertion in right subtree@> @
  } 
else @
  { @
    @<Rebalance for |-| balance factor in PAVL insertion in right subtree@> @
  }
@

@<Rebalance for |+| balance factor in PAVL insertion in right subtree@> =
@<Rotate left at |y| in AVL tree; avl => pavl@>
x->pavl_parent = y->pavl_parent;
y->pavl_parent = x;
if (y->pavl_link[1] != NULL)
  y->pavl_link[1]->pavl_parent = y;
@

@<Rebalance for |-| balance factor in PAVL insertion in right subtree@> =
@<Rotate right at |x| then left at |y| in AVL tree; avl => pavl@>
w->pavl_parent = y->pavl_parent;
x->pavl_parent = y->pavl_parent = w;
if (x->pavl_link[0] != NULL)
  x->pavl_link[0]->pavl_parent = x;
if (y->pavl_link[1] != NULL)
  y->pavl_link[1]->pavl_parent = y;
@

@node Deleting from a PAVL Tree, Traversing a PAVL Tree, Inserting into a PAVL Tree, AVL Trees with Parent Pointers
@section Deletion

Deletion from a PAVL tree is a natural outgrowth of algorithms we have
already implemented.  The basic algorithm is the one originally used
for plain AVL trees.  The search step is taken verbatim from PBST
deletion.  The deletion step combines PBST and TAVL tree code.
Finally, the rebalancing strategy is the same as used in TAVL
deletion.

The function outline is below.  As noted above, step 1 is borrowed
from PBST deletion.  The other steps are implemented in the following
sections.

@cat pavl Deletion
@<PAVL item deletion function@> =
@iftangle
/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
@end iftangle
void *@
pavl_delete (struct pavl_table *tree, const void *item) @
{
  struct pavl_node *p; /* Traverses tree to find node to delete. */
  struct pavl_node *q; /* Parent of |p|. */
  int dir;             /* Side of |q| on which |p| is linked. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Find PBST node to delete; pbst => pavl@>
  @<Step 2: Delete item from PAVL tree@>
  @<Steps 3 and 4: Update balance factors and rebalance after PAVL deletion@>
}

@

@menu
* Deleting a PAVL Node Step 2 - Delete::  
* Deleting a PAVL Node Step 3 - Update::  
* Deleting a PAVL Node Step 4 - Rebalance::  
* PAVL Deletion Symmetric Case::  
@end menu

@node Deleting a PAVL Node Step 2 - Delete, Deleting a PAVL Node Step 3 - Update, Deleting from a PAVL Tree, Deleting from a PAVL Tree
@subsection Step 2: Delete

The actual deletion step is derived from that for PBSTs.  We add code
to modify balance factors and set up for rebalancing.  After the
deletion, |q| is the node at which balance factors must be updated and
possible rebalancing occurs and |dir| is the side of |q| from which
the node was deleted.  This follows the pattern already seen in TAVL
deletion (@pxref{Deleting a TAVL Node Step 2 - Delete}).

@<Step 2: Delete item from PAVL tree@> =
if (p->pavl_link[1] == NULL)
  { @
    @<Case 1 in PAVL deletion@> @
  }
else @
  {@-
    struct pavl_node *r = p->pavl_link[1];
    if (r->pavl_link[0] == NULL)
      { @
        @<Case 2 in PAVL deletion@> @
      }
    else @
      { @
        @<Case 3 in PAVL deletion@> @
      }
  }@+
tree->pavl_alloc->libavl_free (tree->pavl_alloc, p);

@

@subsubheading Case 1: |p| has no right child

No changes are needed for case 1.  No balance factors need change and
|q| and |dir| are already set up correctly.

@<Case 1 in PAVL deletion@> =
@<Case 1 in PBST deletion; pbst => pavl@>
@

@subsubheading Case 2: |p|'s right child has no left child

See the commentary on @<Case 3 in TAVL deletion@> for details.

@<Case 2 in PAVL deletion@> =
@<Case 2 in PBST deletion; pbst => pavl@>
r->pavl_balance = p->pavl_balance;
q = r;
dir = 1;
@

@subsubheading Case 3: |p|'s right child has a left child

See the commentary on @<Case 4 in TAVL deletion@> for details.

@<Case 3 in PAVL deletion@> =
@<Case 3 in PBST deletion; pbst => pavl@>
s->pavl_balance = p->pavl_balance;
q = r;
dir = 0;
@

@node Deleting a PAVL Node Step 3 - Update, Deleting a PAVL Node Step 4 - Rebalance, Deleting a PAVL Node Step 2 - Delete, Deleting from a PAVL Tree
@subsection Step 3: Update Balance Factors

Step 3, updating balance factors, is taken straight from TAVL deletion
(@pxref{Deleting a TAVL Node Step 3 - Update}), with the call to
|find_parent()| replaced by inline code that uses |pavl_parent|.

@<Steps 3 and 4: Update balance factors and rebalance after PAVL deletion@> =
while (q != (struct pavl_node *) &tree->pavl_root) @
  {@-
    struct pavl_node *y = q;

    if (y->pavl_parent != NULL)
      q = y->pavl_parent;
    else @
      q = (struct pavl_node *) &tree->pavl_root;

    if (dir == 0) @
      {@-
        dir = q->pavl_link[0] != y;
        y->pavl_balance++;
        if (y->pavl_balance == +1)
          break;
        else if (y->pavl_balance == +2) 
          { @
            @<Step 4: Rebalance after PAVL deletion@> @
          }
      }@+
    else @
      { @
        @<Steps 3 and 4: Symmetric case in PAVL deletion@> @
      }
  }@+

tree->pavl_count--;
return (void *) item;
@

@node Deleting a PAVL Node Step 4 - Rebalance, PAVL Deletion Symmetric Case, Deleting a PAVL Node Step 3 - Update, Deleting from a PAVL Tree
@subsection Step 4: Rebalance

The two cases for PAVL deletion are distinguished based on |x|'s
balance factor, as always:

@<Step 4: Rebalance after PAVL deletion@> =
struct pavl_node *x = y->pavl_link[1];
if (x->pavl_balance == -1)
  { @
    @<Left-side rebalancing case 1 in PAVL deletion@> @
  }
else @
  { @
    @<Left-side rebalancing case 2 in PAVL deletion@> @
  }
@

@subsubheading Case 1: |x| has |-| balance factor

The same rebalancing is needed here as for a |-| balance factor in
PAVL insertion, and the same code is used.

@<Left-side rebalancing case 1 in PAVL deletion@> =
struct pavl_node *w;

@<Rebalance for |-| balance factor in PAVL insertion in right subtree@>
q->pavl_link[dir] = w;
@

@subsubheading Case 2: |x| has |+| or 0 balance factor

If |x| has a |+| or 0 balance factor, we rotate left at |y| and update
parent pointers as for any left rotation (@pxref{PBST Rotations}).  We
also update balance factors.  If |x| started with balance factor 0,
then we're done.  Otherwise, |x| becomes the new |y| for the next loop
iteration, and rebalancing continues.  @xref{avldel2}, for details on
this rebalancing case.

@<Left-side rebalancing case 2 in PAVL deletion@> =
y->pavl_link[1] = x->pavl_link[0];
x->pavl_link[0] = y;
x->pavl_parent = y->pavl_parent;
y->pavl_parent = x;
if (y->pavl_link[1] != NULL)
  y->pavl_link[1]->pavl_parent = y;
q->pavl_link[dir] = x;
if (x->pavl_balance == 0) @
  {@-
    x->pavl_balance = -1;
    y->pavl_balance = +1;
    break;
  }@+ @
else @
  {@-
    x->pavl_balance = y->pavl_balance = 0;
    y = x;
  }@+
@

@node PAVL Deletion Symmetric Case,  , Deleting a PAVL Node Step 4 - Rebalance, Deleting from a PAVL Tree
@subsection Symmetric Case

@<Steps 3 and 4: Symmetric case in PAVL deletion@> =
dir = q->pavl_link[0] != y;
y->pavl_balance--;
if (y->pavl_balance == -1)
  break;
else if (y->pavl_balance == -2) @
  {@-
    struct pavl_node *x = y->pavl_link[0];
    if (x->pavl_balance == +1)
      { @
        @<Right-side rebalancing case 1 in PAVL deletion@> @
      }
    else @
      { @
        @<Right-side rebalancing case 2 in PAVL deletion@> @
      }
  }@+
@

@<Right-side rebalancing case 1 in PAVL deletion@> =
struct pavl_node *w;
@<Rebalance for |+| balance factor in PAVL insertion in left subtree@>
q->pavl_link[dir] = w;
@

@<Right-side rebalancing case 2 in PAVL deletion@> =
y->pavl_link[0] = x->pavl_link[1];
x->pavl_link[1] = y;
x->pavl_parent = y->pavl_parent;
y->pavl_parent = x;
if (y->pavl_link[0] != NULL)
  y->pavl_link[0]->pavl_parent = y;
q->pavl_link[dir] = x;
if (x->pavl_balance == 0) @
  {@-
    x->pavl_balance = +1;
    y->pavl_balance = -1;
    break;
  }@+ @
else @
  {@-
    x->pavl_balance = y->pavl_balance = 0;
    y = x;
  }@+
@

@node Traversing a PAVL Tree, Copying a PAVL Tree, Deleting from a PAVL Tree, AVL Trees with Parent Pointers
@section Traversal

The only difference between PAVL and PBST traversal functions is the
insertion initializer.  We use the TBST implementation here, which
performs a call to |pavl_probe()|, instead of the PBST implementation,
which inserts the node directly without handling node colors.

@<PAVL traversal functions@> =
@<TBST traverser null initializer; tbst => pavl@>
@<PBST traverser first initializer; pbst => pavl@>
@<PBST traverser last initializer; pbst => pavl@>
@<PBST traverser search initializer; pbst => pavl@>
@<TBST traverser insertion initializer; tbst => pavl@>
@<TBST traverser copy initializer; tbst => pavl@>
@<PBST traverser advance function; pbst => pavl@>
@<PBST traverser back up function; pbst => pavl@>
@<BST traverser current item function; bst => pavl@>
@<BST traverser replacement function; bst => pavl@>
@

@node Copying a PAVL Tree, Testing PAVL Trees, Traversing a PAVL Tree, AVL Trees with Parent Pointers
@section Copying

The copy function is the same as @<PBST copy function@>, except that
it copies |pavl_balance| between copied nodes.

@cat pavl Copying
@<PAVL copy function@> =
@<PBST copy error helper function; pbst => pavl@>

@iftangle
/* Copies |org| to a newly created tree, which is returned.
   If |copy != NULL|, each data item in |org| is first passed to |copy|,
   and the return values are inserted into the tree;
   |NULL| return values are taken as indications of failure.
   On failure, destroys the partially created new tree,
   applying |destroy|, if non-null, to each item in the new tree so far, @
   and returns |NULL|.
   If |allocator != NULL|, it is used for allocation in the new tree.
   Otherwise, the same allocator used for |org| is used. */
@end iftangle
struct pavl_table *@
pavl_copy (const struct pavl_table *org, pavl_copy_func *copy,
           pavl_item_func *destroy, struct libavl_allocator *allocator) @
{
  struct pavl_table *new;
  const struct pavl_node *x;
  struct pavl_node *y;

  assert (org != NULL);
  new = pavl_create (org->pavl_compare, org->pavl_param,
                    allocator != NULL ? allocator : org->pavl_alloc);
  if (new == NULL)
    return NULL;
  new->pavl_count = org->pavl_count;
  if (new->pavl_count == 0)
    return new;

  x = (const struct pavl_node *) &org->pavl_root;
  y = (struct pavl_node *) &new->pavl_root;
  for (;;) @
    {@-
      while (x->pavl_link[0] != NULL) @
        {@-
          y->pavl_link[0] = @
            new->pavl_alloc->libavl_malloc (new->pavl_alloc,
					    sizeof *y->pavl_link[0]);
          if (y->pavl_link[0] == NULL) @
            {@-
              if (y != (struct pavl_node *) &new->pavl_root) @
                {@-
                  y->pavl_data = NULL;
                  y->pavl_link[1] = NULL;
                }@+

              copy_error_recovery (y, new, destroy);
              return NULL;
            }@+
	  y->pavl_link[0]->pavl_parent = y;

          x = x->pavl_link[0];
          y = y->pavl_link[0];
        }@+
      y->pavl_link[0] = NULL;

      for (;;) @
        {@-
          y->pavl_balance = x->pavl_balance;
          if (copy == NULL)
            y->pavl_data = x->pavl_data;
          else @
            {@-
              y->pavl_data = copy (x->pavl_data, org->pavl_param);
              if (y->pavl_data == NULL) @
                {@-
                  y->pavl_link[1] = NULL;
                  copy_error_recovery (y, new, destroy);
                  return NULL;
                }@+
            }@+

          if (x->pavl_link[1] != NULL) @
            {@-
              y->pavl_link[1] = @
                new->pavl_alloc->libavl_malloc (new->pavl_alloc,
                                               sizeof *y->pavl_link[1]);
              if (y->pavl_link[1] == NULL) @
                {@-
                  copy_error_recovery (y, new, destroy);
                  return NULL;
                }@+
	      y->pavl_link[1]->pavl_parent = y;

              x = x->pavl_link[1];
              y = y->pavl_link[1];
              break;
            }@+
          else @
            y->pavl_link[1] = NULL;

	  for (;;) @
	    {@-
	      const struct pavl_node *w = x;
	      x = x->pavl_parent;
	      if (x == NULL) @
		{@-
		  new->pavl_root->pavl_parent = NULL;
		  return new;
		}@+
	      y = y->pavl_parent;

	      if (w == x->pavl_link[0])
		break;
	    }@+
        }@+
    }@+
}

@

@node Testing PAVL Trees,  , Copying a PAVL Tree, AVL Trees with Parent Pointers
@section Testing

The testing code harbors no surprises.

@(pavl-test.c@> =
@<Program License@>
#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include "pavl.h"
#include "test.h"

@<BST print function; bst => pavl@>
@<BST traverser check function; bst => pavl@>
@<Compare two PAVL trees for structure and content@>
@<Recursively verify PAVL tree structure@>
@<AVL tree verify function; avl => pavl@>
@<BST test function; bst => pavl@>
@<BST overflow test function; bst => pavl@>
@

@<Compare two PAVL trees for structure and content@> =
/* Compares binary trees rooted at |a| and |b|,
   making sure that they are identical. */
static int @
compare_trees (struct pavl_node *a, struct pavl_node *b) @
{
  int okay;

  if (a == NULL || b == NULL) @
    {@-
      assert (a == NULL && b == NULL);
      return 1;
    }@+

  if (*(int *) a->pavl_data != *(int *) b->pavl_data
      || ((a->pavl_link[0] != NULL) != (b->pavl_link[0] != NULL))
      || ((a->pavl_link[1] != NULL) != (b->pavl_link[1] != NULL))
      || ((a->pavl_parent != NULL) != (b->pavl_parent != NULL))
      || (a->pavl_parent != NULL && b->pavl_parent != NULL
	  && a->pavl_parent->pavl_data != b->pavl_parent->pavl_data)
      || a->pavl_balance != b->pavl_balance) @
    {@-
      printf (" Copied nodes differ:\n"
	      "  a: %d, bal %+d, parent %d, %s left child, %s right child\n"
	      "  b: %d, bal %+d, parent %d, %s left child, %s right child\n",
              *(int *) a->pavl_data, a->pavl_balance,
	      a->pavl_parent != NULL ? *(int *) a->pavl_parent : -1,
	      a->pavl_link[0] != NULL ? "has" : "no",
	      a->pavl_link[1] != NULL ? "has" : "no",
	      *(int *) b->pavl_data, b->pavl_balance,
	      b->pavl_parent != NULL ? *(int *) b->pavl_parent : -1,
	      b->pavl_link[0] != NULL ? "has" : "no",
	      b->pavl_link[1] != NULL ? "has" : "no");
      return 0;
    }@+

  okay = 1;
  if (a->pavl_link[0] != NULL)
    okay &= compare_trees (a->pavl_link[0], b->pavl_link[0]);
  if (a->pavl_link[1] != NULL)
    okay &= compare_trees (a->pavl_link[1], b->pavl_link[1]);
  return okay;
}

@

@<Recursively verify PAVL tree structure@> =
@iftangle
/* Examines the binary tree rooted at |node|.  
   Zeroes |*okay| if an error occurs.  @
   Otherwise, does not modify |*okay|.
   Sets |*count| to the number of nodes in that tree, @
   including |node| itself if |node != NULL|.
   Sets |*height| to the tree's height.
   All the nodes in the tree are verified to be at least |min| @
   but no greater than |max|. */
@end iftangle
static void @
recurse_verify_tree (struct pavl_node *node, int *okay, size_t *count, 
                     int min, int max, int *height) @
{
  int d;                /* Value of this node's data. */
  size_t subcount[2];   /* Number of nodes in subtrees. */
  int subheight[2];     /* Heights of subtrees. */
  int i;

  if (node == NULL) @
    {@-
      *count = 0;
      *height = 0;
      return;
    }@+
  d = *(int *) node->pavl_data;

  @<Verify binary search tree ordering@>

  recurse_verify_tree (node->pavl_link[0], okay, &subcount[0], 
                       min, d -  1, &subheight[0]);
  recurse_verify_tree (node->pavl_link[1], okay, &subcount[1], 
                       d + 1, max, &subheight[1]);
  *count = 1 + subcount[0] + subcount[1];
  *height = 1 + (subheight[0] > subheight[1] ? subheight[0] : subheight[1]);

  @<Verify AVL node balance factor; avl => pavl@>

  @<Verify PBST node parent pointers; pbst => pavl@>
}

@

