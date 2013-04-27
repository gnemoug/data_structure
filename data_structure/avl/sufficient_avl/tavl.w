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

@deftypedef tavl_comparison_func
@deftypedef tavl_item_func
@deftypedef tavl_copy_func

@node Threaded AVL Trees, Threaded Red-Black Trees, Threaded Binary Search Trees, Top
@chapter Threaded AVL Trees

The previous chapter introduced a new concept in BSTs, the idea of
threads.  Threads allowed us to simplify traversals and eliminate the
use of stacks.  On the other hand, threaded trees can still grow tall
enough that they reduce the program's performance unacceptably, the
problem that balanced trees were meant to solve.  Ideally, we'd like
to add threads to balanced trees, to produce threaded balanced trees
that combine the best of both worlds.

We can do this, and it's not even very difficult.  This chapter will show
how to add threads to AVL trees.  The next will show how to add them to
red-black trees.

Here's an outline of the table implementation for threaded AVL or
``TAVL'' trees that we'll develop in this chapter.  Note the usage of
prefix |tavl_| for these functions.

@(tavl.h@> =
@<Library License@>
#ifndef TAVL_H
#define TAVL_H 1

#include <stddef.h>

@<Table types; tbl => tavl@>
@<BST maximum height; bst => tavl@>
@<TBST table structure; tbst => tavl@>
@<TAVL node structure@>
@<TBST traverser structure; tbst => tavl@>
@<Table function prototypes; tbl => tavl@>

#endif /* tavl.h */
@ 

@(tavl.c@> =
@<Library License@>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "tavl.h"

@<TAVL functions@>
@

@menu
* TAVL Data Types::             
* TBST Rotations::              
* TAVL Operations::             
* Inserting into a TAVL Tree::  
* Deleting from a TAVL Tree::   
* Copying a TAVL Tree::         
* Testing TAVL Trees::          
@end menu

@node TAVL Data Types, TBST Rotations, Threaded AVL Trees, Threaded AVL Trees
@section Data Types

The TAVL node structure takes the basic fields for a BST and adds a
balance factor for AVL balancing and a pair of tag fields to allow for
threading.

@<TAVL node structure@> =
/* Characterizes a link as a child pointer or a thread. */
enum tavl_tag @
  {@-
    TAVL_CHILD,                     /* Child pointer. */
    TAVL_THREAD                     /* Thread. */
  };@+

/* An TAVL tree node. */
struct tavl_node @
  {@-
    struct tavl_node *tavl_link[2]; /* Subtrees. */
    void *tavl_data;                /* Pointer to data. */
    unsigned char tavl_tag[2];      /* Tag fields. */
    signed char tavl_balance;       /* Balance factor. */
  };@+

@

@exercise tavlnodesize
|struct avl_node| contains three pointer members and a single
character member, whereas |struct tavl_node| additionally contains an
array of two characters.  Is |struct tavl_node| necessarily larger
than |struct avl_node|?

@answer
No: the compiler may insert padding between or after structure members.
For example, today (2002) the most common desktop computers have 32-bit
pointers and and 8-bit |char|s.  On these systems, most compilers will
pad out structures to a multiple of 32 bits.  Under these circumstances,
|struct tavl_node| is no larger than |struct avl_node|, because |(32 +
32 + 8)| and |(32 + 32 + 8 + 8 + 8)| both round up to the same multiple of
32 bits, or 96 bits.
@end exercise

@node TBST Rotations, TAVL Operations, TAVL Data Types, Threaded AVL Trees
@section Rotations

Rotations are just as useful in threaded BSTs as they are in unthreaded
ones.  We do need to re-examine the idea, though, to see how the
presence of threads affect rotations.

A generic rotation looks like this diagram taken from @ref{BST
Rotations}:

@center @image{rotation}

Any of the subtrees labeled |a|, |b|, and |c| may be in fact threads.
In the most extreme case, all of them are threads, and the rotation
looks like this:

@center @image{tavlrot}

As you can see, the thread from |X| to |Y|, represented by subtree
|b|, reverses direction and becomes a thread from |Y| to |X| following
a right rotation.  This has to be handled as a special case in code
for rotation.  See @value{tbstrotbrief} for details.

On the other hand, there is no need to do anything special with
threads originating in subtrees of a rotated node.  This is a direct
consequence of the locality and order-preserving properties of a
rotation (@pxref{BST Rotations}).  Here's an example diagram to
demonstrate.  Note in particular that the threads from |A|, |B|, and
|C| point to the same nodes in both trees:

@center @image{tavlrot2}

@exercise tbstrot
Write functions for right and left rotations in threaded BSTs, analogous
to those for unthreaded BSTs developed in @value{bstrotation}.

@answer
We just have to special-case the possibility that subtree |b| is a
thread.

@cat tbst Rotation, right
@c tested 2001/11/10
@<Anonymous@> =
/* Rotates right at |*yp|. */
static void @
rotate_right (struct tavl_node **yp) @
{
  struct tavl_node *y = *yp;
  struct tavl_node *x = y->tavl_link[0];
  if (x->tavl_tag[1] == TAVL_THREAD) @
    {@-
      x->tavl_tag[1] = TAVL_CHILD;
      y->tavl_tag[0] = TAVL_THREAD;
      y->tavl_link[0] = x;
    }@+
  else @
    y->tavl_link[0] = x->tavl_link[1];
  x->tavl_link[1] = y;
  *yp = x;
}
@

@cat tbst Rotation, left
@c tested 2001/11/10
@<Anonymous@> =
/* Rotates left at |*xp|. */
static void @
rotate_left (struct tavl_node **xp) @
{
  struct tavl_node *x = *xp;
  struct tavl_node *y = x->tavl_link[1];
  if (y->tavl_tag[0] == TAVL_THREAD) @
    {@-
      y->tavl_tag[0] = TAVL_CHILD;
      x->tavl_tag[1] = TAVL_THREAD;
      x->tavl_link[1] = y;
    }@+
  else @
    x->tavl_link[1] = y->tavl_link[0];
  y->tavl_link[0] = x;
  *xp = y;
}
@
@end exercise

@node TAVL Operations, Inserting into a TAVL Tree, TBST Rotations, Threaded AVL Trees
@section Operations

Now we'll implement all the usual operations for TAVL trees.  We can
reuse everything from TBSTs except insertion, deletion, and copy
functions.  Most of the copy function code will in fact be reused
also.  Here's the outline:

@<TAVL functions@> =
@<TBST creation function; tbst => tavl@>
@<TBST search function; tbst => tavl@>
@<TAVL item insertion function@>
@<Table insertion convenience functions; tbl => tavl@>
@<TAVL item deletion function@>
@<TBST traversal functions; tbst => tavl@>
@<TAVL copy function@>
@<TBST destruction function; tbst => tavl@>
@<Default memory allocation functions; tbl => tavl@>
@<Table assertion functions; tbl => tavl@>
@

@node Inserting into a TAVL Tree, Deleting from a TAVL Tree, TAVL Operations, Threaded AVL Trees
@section Insertion

Insertion into an AVL tree is not complicated much by the need to update
threads.  The outline is the same as before, and the code for step 3
and the local variable declarations can be reused entirely:

@cat tavl Insertion
@<TAVL item insertion function@> =
@iftangle
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree, 
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
@end iftangle
void **@
tavl_probe (struct tavl_table *tree, void *item) @
{
  @<|avl_probe()| local variables; avl => tavl@>

  assert (tree != NULL && item != NULL);

  @<Step 1: Search TAVL tree for insertion point@>
  @<Step 2: Insert TAVL node@>
  @<Step 3: Update balance factors after AVL insertion; avl => tavl@>
  @<Step 4: Rebalance after TAVL insertion@>
}

@

@menu
* Steps 1 and 2 in TAVL Insertion::  
* Rebalancing TAVL Trees::      
* TAVL Insertion Symmetric Case::  
@end menu

@node Steps 1 and 2 in TAVL Insertion, Rebalancing TAVL Trees, Inserting into a TAVL Tree, Inserting into a TAVL Tree
@subsection Steps 1 and 2: Search and Insert

The first step is a lot like the unthreaded AVL version in @<Step 1:
Search AVL tree for insertion point@>.  There is an unfortunate
special case for an empty tree, because a null pointer for |tavl_root|
indicates an empty tree but in a nonempty tree we must seek a thread
link.  After we're done, |p|, not |q| as before, is the node below
which a new node should be inserted, because the test for stepping
outside the binary tree now comes before advancing |p|.

@<Step 1: Search TAVL tree for insertion point@> =
z = (struct tavl_node *) &tree->tavl_root;
y = tree->tavl_root;
if (y != NULL) @
  {@-
    for (q = z, p = y; ; q = p, p = p->tavl_link[dir]) @
      {@-
        int cmp = tree->tavl_compare (item, p->tavl_data, tree->tavl_param);
        if (cmp == 0)
          return &p->tavl_data;

        if (p->tavl_balance != 0)
          z = q, y = p, k = 0;
        da[k++] = dir = cmp > 0;

        if (p->tavl_tag[dir] == TAVL_THREAD)
          break;
      }@+
  }@+ @
else @
  {@-
    p = z;
    dir = 0;
  }@+

@

The insertion adds to the TBST code by setting the balance factor of
the new node and handling the first insertion into an empty tree as a
special case:

@<Step 2: Insert TAVL node@> =
@<Step 2: Insert TBST node; tbst => tavl@>
n->tavl_balance = 0;
if (tree->tavl_root == n)
  return &n->tavl_data;

@

@node Rebalancing TAVL Trees, TAVL Insertion Symmetric Case, Steps 1 and 2 in TAVL Insertion, Inserting into a TAVL Tree
@subsection Step 4: Rebalance

Now we're finally to the interesting part, the rebalancing step.  We
can tell whether rebalancing is necessary based on the balance factor
of |y|, the same as in unthreaded AVL insertion:

@<Step 4: Rebalance after TAVL insertion@> =
if (y->tavl_balance == -2)
  { @
    @<Rebalance TAVL tree after insertion in left subtree@> @
  }
else if (y->tavl_balance == +2)
  { @
    @<Rebalance TAVL tree after insertion in right subtree@> @
  }
else @
  return &n->tavl_data;
z->tavl_link[y != z->tavl_link[0]] = w;

return &n->tavl_data;
@

We will examine the case of insertion in the left subtree of |y|, the
node at which we must rebalance.  We take |x| as |y|'s child on the
side of the new node, then, as for unthreaded AVL insertion, we
distinguish two cases based on the balance factor of |x|:

@<Rebalance TAVL tree after insertion in left subtree@> =
struct tavl_node *x = y->tavl_link[0];
if (x->tavl_balance == -1)
  { @
    @<Rebalance for |-| balance factor in TAVL insertion in left subtree@> @
  } 
else @
  { @
    @<Rebalance for |+| balance factor in TAVL insertion in left subtree@> @
  }
@

@subsubheading Case 1: |x| has |-| balance factor

As for unthreaded insertion, we rotate right at |y| (@pxref{Rebalancing
AVL Trees}).  Notice the resemblance of the following code to
|rotate_right()| in the solution to @value{tbstrot}.

@<Rebalance for |-| balance factor in TAVL insertion in left subtree@> =
w = x;
if (x->tavl_tag[1] == TAVL_THREAD) @
  {@-
    x->tavl_tag[1] = TAVL_CHILD;
    y->tavl_tag[0] = TAVL_THREAD;
    y->tavl_link[0] = x;
  }@+
else @
  y->tavl_link[0] = x->tavl_link[1];
x->tavl_link[1] = y;
x->tavl_balance = y->tavl_balance = 0;
@

@subsubheading Case 2: |x| has |+| balance factor

When |x| has a |+| balance factor, we perform the transformation shown
below, which consists of a left rotation at |x| followed by a right
rotation at |y|.  This is the same transformation used in unthreaded
insertion:

@center @image{tavlins1}

We could simply apply the standard code from @value{tbstrot} in each
rotation (see @value{tavlaltdblrotbrief}), but it is just as
straightforward to do both of the rotations together, then clean up
any threads.  Subtrees |a| and |d| cannot cause thread-related
trouble, because they are not disturbed during the transformation: |a|
remains |x|'s left child and |d| remains |y|'s right child.  The
children of |w|, subtrees |b| and |c|, do require handling.  If
subtree |b| is a thread, then after the rotation and before fix-up
|x|'s right link points to itself, and, similarly, if |c| is a thread
then |y|'s left link points to itself.  These links must be changed
into threads to |w| instead, and |w|'s links must be tagged as child
pointers.

If both |b| and |c| are threads then the transformation looks like the
diagram below, showing pre-rebalancing and post-rebalancing,
post-fix-up views.  The AVL balance rule implies that if |b| and |c|
are threads then |a| and |d| are also:

@center @image{tavlins2}

The required code is heavily based on the corresponding code for
unthreaded AVL rebalancing:

@cat tavl Rotation, left double, version 1
@<Rebalance for |+| balance factor in TAVL insertion in left subtree@> =
@<Rotate left at |x| then right at |y| in AVL tree; avl => tavl@>
if (w->tavl_tag[0] == TAVL_THREAD) @
  {@-
    x->tavl_tag[1] = TAVL_THREAD;
    x->tavl_link[1] = w;
    w->tavl_tag[0] = TAVL_CHILD;
  }@+
if (w->tavl_tag[1] == TAVL_THREAD) @
  {@-
    y->tavl_tag[0] = TAVL_THREAD;
    y->tavl_link[0] = w;
    w->tavl_tag[1] = TAVL_CHILD;
  }@+
@

@exercise tavlaltdblrot
Rewrite @<Rebalance for |+| balance factor in TAVL insertion in left
subtree@> in terms of the routines from @value{tbstrot}.

@answer
Besides this change, the statement

@<Anonymous@> =
z->tavl_link[y != z->tavl_link[0]] = w;
@

@noindent
must be removed from @<Step 4: Rebalance after TAVL insertion@>, and
copies added to the end of @<Rebalance TAVL tree after insertion in
right subtree@> and @<Rebalance for |-| balance factor in TAVL
insertion in left subtree@>.

@cat tavl Rotation, left double, version 2
@c tested 2001/11/10
@<Rebalance |+| balance in TAVL insertion in left subtree, alternate version@> =
w = x->tavl_link[1];
rotate_left (&y->tavl_link[0]);
rotate_right (&z->tavl_link[y != z->tavl_link[0]]);
if (w->tavl_balance == -1) @
  x->tavl_balance = 0, y->tavl_balance = +1;
else if (w->tavl_balance == 0) @
  x->tavl_balance = y->tavl_balance = 0;
else /* |w->tavl_balance == +1| */ @
  x->tavl_balance = -1, y->tavl_balance = 0;
w->tavl_balance = 0;
@
@end exercise

@node TAVL Insertion Symmetric Case,  , Rebalancing TAVL Trees, Inserting into a TAVL Tree
@subsection Symmetric Case

Here is the corresponding code for the case where insertion occurs in
the right subtree of |y|.

@<Rebalance TAVL tree after insertion in right subtree@> =
struct tavl_node *x = y->tavl_link[1];
if (x->tavl_balance == +1)
  { @
    @<Rebalance for |+| balance factor in TAVL insertion in right subtree@> @
  } 
else @
  { @
    @<Rebalance for |-| balance factor in TAVL insertion in right subtree@> @
  }
@

@<Rebalance for |+| balance factor in TAVL insertion in right subtree@> =
w = x;
if (x->tavl_tag[0] == TAVL_THREAD) @
  {@-
    x->tavl_tag[0] = TAVL_CHILD;
    y->tavl_tag[1] = TAVL_THREAD;
    y->tavl_link[1] = x;
  }@+
else @
  y->tavl_link[1] = x->tavl_link[0];
x->tavl_link[0] = y;
x->tavl_balance = y->tavl_balance = 0;
@

@cat tavl Rotation, right double
@<Rebalance for |-| balance factor in TAVL insertion in right subtree@> =
@<Rotate right at |x| then left at |y| in AVL tree; avl => tavl@>
if (w->tavl_tag[0] == TAVL_THREAD) @
  {@-
    y->tavl_tag[1] = TAVL_THREAD;
    y->tavl_link[1] = w;
    w->tavl_tag[0] = TAVL_CHILD;
  }@+
if (w->tavl_tag[1] == TAVL_THREAD) @
  {@-
    x->tavl_tag[0] = TAVL_THREAD;
    x->tavl_link[0] = w;
    w->tavl_tag[1] = TAVL_CHILD;
  }@+
@

@node Deleting from a TAVL Tree, Copying a TAVL Tree, Inserting into a TAVL Tree, Threaded AVL Trees
@section Deletion

Deletion from a TAVL tree can be accomplished by combining our
knowledge about AVL trees and threaded trees.  From one perspective,
we add rebalancing to TBST deletion.  From the other perspective, we
add thread handling to AVL tree deletion.

The function outline is about the same as usual.  We do add a helper
function for finding the parent of a TAVL node:

@cat tavl Deletion (without stack)
@<TAVL item deletion function@> =
@<Find parent of a TBST node; tbst => tavl@>

@iftangle
/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
@end iftangle
void *@
tavl_delete (struct tavl_table *tree, const void *item) @
{
  struct tavl_node *p; /* Traverses tree to find node to delete. */
  struct tavl_node *q; /* Parent of |p|. */
  int dir;             /* Index into |q->tavl_link[]| to get |p|. */
  int cmp;             /* Result of comparison between |item| and |p|. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Search TAVL tree for item to delete@>
  @<Step 2: Delete item from TAVL tree@>
  @<Steps 3 and 4: Update balance factors and rebalance after TAVL deletion@>
}

@

@menu
* Deleting a TAVL Node Step 1 - Search::  
* Deleting a TAVL Node Step 2 - Delete::  
* Deleting a TAVL Node Step 3 - Update::  
* Deleting a TAVL Node Step 4 - Rebalance::  
* TAVL Deletion Symmetric Case::  
* Finding the Parent of a TBST Node::  
@end menu

@node Deleting a TAVL Node Step 1 - Search, Deleting a TAVL Node Step 2 - Delete, Deleting from a TAVL Tree, Deleting from a TAVL Tree
@subsection Step 1: Search

We use |p| to search down the tree and keep track of |p|'s parent with
|q|.  We keep the invariant at the beginning of the loop here that
|q->tavl_link[dir] == p|.  As the final step, we record the item deleted
and update the tree's item count.

@<Step 1: Search TAVL tree for item to delete@> =
if (tree->tavl_root == NULL)
  return NULL;
  
q = (struct tavl_node *) &tree->tavl_root;
p = tree->tavl_root;
dir = 0;
for (;;) 
  {@-
    cmp = tree->tavl_compare (item, p->tavl_data, tree->tavl_param);
    if (cmp == 0)
      break;
    dir = cmp > 0;

    q = p;
    if (p->tavl_tag[dir] == TAVL_THREAD)
      return NULL;
    p = p->tavl_link[dir];
  }@+
item = p->tavl_data;

@

@node Deleting a TAVL Node Step 2 - Delete, Deleting a TAVL Node Step 3 - Update, Deleting a TAVL Node Step 1 - Search, Deleting from a TAVL Tree
@subsection Step 2: Delete

The cases for deletion are the same as for a TBST (@pxref{Deleting from
a TBST}).  The difference is that we have to copy around balance factors
and keep track of where balancing needs to start.  After the deletion,
|q| is the node at which balance factors must be updated and possible
rebalancing occurs and |dir| is the side of |q| from which the node was
deleted.  For cases 1 and 2, |q| need not change from its current value
as the parent of the deleted node.  For cases 3 and 4, |q| will need to
be changed.

@<Step 2: Delete item from TAVL tree@> =
if (p->tavl_tag[1] == TAVL_THREAD) @
  {@-
    if (p->tavl_tag[0] == TAVL_CHILD)
      { @
        @<Case 1 in TAVL deletion@> @
      }
    else @
      { @
        @<Case 2 in TAVL deletion@> @
      }
  }@+ @
else @
  {@-
    struct tavl_node *r = p->tavl_link[1];
    if (r->tavl_tag[0] == TAVL_THREAD)
      { @
        @<Case 3 in TAVL deletion@> @
      }
    else @
      { @
        @<Case 4 in TAVL deletion@> @
      }
  }@+

tree->tavl_alloc->libavl_free (tree->tavl_alloc, p);

@

@subsubheading Case 1: |p| has a right thread and a left child

If |p| has a right thread and a left child, then we replace it by its
left child.  Rebalancing must begin right above |p|, which is already
set as |q|.  There's no need to change the TBST code:

@<Case 1 in TAVL deletion@> =
@<Case 1 in TBST deletion; tbst => tavl@>
@

@subsubheading Case 2: |p| has a right thread and a left thread

If |p| is a leaf, then we change |q|'s pointer to |p| into a thread.
Again, rebalancing must begin at the node that's already set up as |q|
and there's no need to change the TBST code:

@<Case 2 in TAVL deletion@> =
@<Case 2 in TBST deletion; tbst => tavl@>
@

@subsubheading Case 3: |p|'s right child has a left thread

If |p| has a right child |r|, which in turn has no left child, then we
move |r| in place of |p|.  In this case |r|, having replaced |p|,
acquires |p|'s former balance factor and rebalancing must start from
there.  The deletion in this case is always on the right side of the
node.

@<Case 3 in TAVL deletion@> =
@<Case 3 in TBST deletion; tbst => tavl@>
r->tavl_balance = p->tavl_balance;
q = r;
dir = 1;
@

@subsubheading Case 4: |p|'s right child has a left child

The most general case comes up when |p|'s right child has a left child,
where we replace |p| by its successor |s|.  In that case |s| acquires
|p|'s former balance factor and rebalancing begins from |s|'s parent
|r|.  Node |s| is always the left child of |r|.

@<Case 4 in TAVL deletion@> =
@<Case 4 in TBST deletion; tbst => tavl@>
s->tavl_balance = p->tavl_balance;
q = r;
dir = 0;
@

@exercise
Rewrite @<Case 4 in TAVL deletion@> to replace the deleted node's
|tavl_data| by its successor, then delete the successor, instead of
shuffling pointers.  (Refer back to @value{modifydata} for an
explanation of why this approach cannot be used in @libavl{}.)

@answer
We can just reuse the alternate implementation of case 4 for TBST
deletion, following it by setting up |q| and |dir| as the rebalancing
step expects them to be.

@cat tavl Deletion, with data modification
@c tested 2001/11/10
@<Case 4 in TAVL deletion, alternate version@> =
@<Case 4 in TBST deletion, alternate version; tbst => tavl@>
q = r;
dir = 0;
@
@end exercise

@node Deleting a TAVL Node Step 3 - Update, Deleting a TAVL Node Step 4 - Rebalance, Deleting a TAVL Node Step 2 - Delete, Deleting from a TAVL Tree
@subsection Step 3: Update Balance Factors

Rebalancing begins from node |q|, from whose side |dir| a node was
deleted.  Node |q| at the beginning of the iteration becomes node |y|,
the root of the balance factor update and rebalancing, and |dir| at the
beginning of the iteration is used to separate the left-side and
right-side deletion cases.  

The loop also updates the values of |q| and |dir| for rebalancing and
for use in the next iteration of the loop, if any.  These new values can
only be assigned after the old ones are no longer needed, but must be
assigned before any rebalancing so that the parent link to |y| can be
changed.  For |q| this is after |y| receives |q|'s old value and before
rebalancing.  For |dir|, it is after the branch point that separates the
left-side and right-side deletion cases, so the |dir| assignment is
duplicated in each branch.  The code used to update |q| is discussed
later.

@<Steps 3 and 4: Update balance factors and rebalance after TAVL deletion@> =
while (q != (struct tavl_node *) &tree->tavl_root) @
  {@-
    struct tavl_node *y = q;

    q = find_parent (tree, y);

    if (dir == 0) @
      {@-
        dir = q->tavl_link[0] != y;
        y->tavl_balance++;
        if (y->tavl_balance == +1)
          break;
        else if (y->tavl_balance == +2)
          { @
            @<Step 4: Rebalance after TAVL deletion@> @
          }
      }@+
    else @
      { @
        @<Steps 3 and 4: Symmetric case in TAVL deletion@> @
      }
  }@+

tree->tavl_count--;
return (void *) item;
@

@node Deleting a TAVL Node Step 4 - Rebalance, TAVL Deletion Symmetric Case, Deleting a TAVL Node Step 3 - Update, Deleting from a TAVL Tree
@subsection Step 4: Rebalance

Rebalancing after deletion in a TAVL tree divides into three cases.  The
first of these is analogous to case 1 in unthreaded AVL deletion, the
other two to case 2 (@pxref{Inserting into a TBST}).  The cases are
distinguished, as usual, based on the balance factor of right child |x|
of the node |y| at which rebalancing occurs:

@<Step 4: Rebalance after TAVL deletion@> =
struct tavl_node *x = y->tavl_link[1];

assert (x != NULL);
if (x->tavl_balance == -1) @
  {@-
    @<Rebalance for |-| balance factor after TAVL deletion in left subtree@>
  }@+ @
else @
  {@-
    q->tavl_link[dir] = x;

    if (x->tavl_balance == 0) @
      {@-
        @<Rebalance for 0 balance factor after TAVL deletion in left subtree@>
        break;
      }@+ @
    else /* |x->tavl_balance == +1| */ @
      {@-
        @<Rebalance for |+| balance factor after TAVL deletion in left subtree@>
      }@+
  }@+
@

@subsubheading Case 1: |x| has |-| balance factor

This case is just like case 2 in TAVL insertion.  In fact, we can even
reuse the code:

@<Rebalance for |-| balance factor after TAVL deletion in left subtree@> =
struct tavl_node *w;

@<Rebalance for |-| balance factor in TAVL insertion in right subtree@>
q->tavl_link[dir] = w;
@

@subsubheading Case 2: |x| has 0 balance factor
@anchor{tavldelcase2}

If |x| has a 0 balance factor, then we perform a left rotation at |y|.
The transformation looks like this, with subtree heights listed under
their labels:

@center @image{tavldel}

Subtree |b| is taller than subtree |a|, so even if |h| takes its
minimum value of 1, then subtree |b| has height |h @= 1| and,
therefore, it must contain at least one node and there is no need to
do any checking for threads.  The code is simple:

@<Rebalance for 0 balance factor after TAVL deletion in left subtree@> =
y->tavl_link[1] = x->tavl_link[0];
x->tavl_link[0] = y;
x->tavl_balance = -1;
y->tavl_balance = +1;
@

@subsubheading Case 3: |x| has |+| balance factor
@anchor{tavldelcase3}

If |x| has a |+| balance factor, we perform a left rotation at |y|, same
as for case 2, and the transformation looks like this:

@center @image{tavldel2}

@noindent
One difference from case 2 is in the resulting balance factors.  The
other is that if |h @= 1|, then subtrees |a| and |b| have height |h - 1
@= 0|, so |a| and |b| may actually be threads.  In that case, the
transformation must be done this way:

@center @image{tavldel3}

@noindent
This code handles both possibilities:

@<Rebalance for |+| balance factor after TAVL deletion in left subtree@> =
if (x->tavl_tag[0] == TAVL_CHILD)
  y->tavl_link[1] = x->tavl_link[0];
else @
  {@-
    y->tavl_tag[1] = TAVL_THREAD;
    x->tavl_tag[0] = TAVL_CHILD;
  }@+
x->tavl_link[0] = y;  
y->tavl_balance = x->tavl_balance = 0;
@

@node TAVL Deletion Symmetric Case, Finding the Parent of a TBST Node, Deleting a TAVL Node Step 4 - Rebalance, Deleting from a TAVL Tree
@subsection Symmetric Case

Here's the code for the symmetric case.

@<Steps 3 and 4: Symmetric case in TAVL deletion@> =
dir = q->tavl_link[0] != y;
y->tavl_balance--;
if (y->tavl_balance == -1) @
  break;
else if (y->tavl_balance == -2) @
  {@-
    struct tavl_node *x = y->tavl_link[0];
    assert (x != NULL);
    if (x->tavl_balance == +1) @
      {@-
        @<Rebalance for |+| balance factor after TAVL deletion in right subtree@>
      }@+ @
    else @
      {@-
        q->tavl_link[dir] = x;

        if (x->tavl_balance == 0) @
          {@-
            @<Rebalance for 0 balance factor after TAVL deletion in right subtree@>
            break;
          }@+ @
        else /* |x->tavl_balance == -1| */ @
          {@-
            @<Rebalance for |-| balance factor after TAVL deletion in right subtree@>
          }@+
      }@+
  }@+
@

@<Rebalance for |+| balance factor after TAVL deletion in right subtree@> =
struct tavl_node *w;

@<Rebalance for |+| balance factor in TAVL insertion in left subtree@>
q->tavl_link[dir] = w;
@

@<Rebalance for 0 balance factor after TAVL deletion in right subtree@> =
y->tavl_link[0] = x->tavl_link[1];
x->tavl_link[1] = y;
x->tavl_balance = +1;
y->tavl_balance = -1;
@

@<Rebalance for |-| balance factor after TAVL deletion in right subtree@> =
if (x->tavl_tag[1] == TAVL_CHILD)
  y->tavl_link[0] = x->tavl_link[1];
else @
  {@-
    y->tavl_tag[0] = TAVL_THREAD;
    x->tavl_tag[1] = TAVL_CHILD;
  }@+
x->tavl_link[1] = y;  
y->tavl_balance = x->tavl_balance = 0;
@

@node Finding the Parent of a TBST Node,  , TAVL Deletion Symmetric Case, Deleting from a TAVL Tree
@subsection Finding the Parent of a Node

The last component of |tavl_delete()| left undiscussed is the
implementation of its helper function |find_parent()|, which requires
an algorithm for finding the parent of an arbitrary node in a TAVL
tree.  If there were no efficient algorithm for this purpose, we would
have to keep a stack of parent nodes as we did for unthreaded AVL
trees.  (This is still an option, as shown in
@value{tbstdelstackbrief}.)  We are fortunate that such an algorithm
does exist.  Let's discover it.

Because child pointers always lead downward in a BST, the only way
that we're going to get from one node to another one above it is by
following a thread.  Almost directly from our definition of threads,
we know that if a node |q| has a right child |p|, then there is a left
thread in the subtree rooted at |p| that points back to |q|.  Because
a left thread points from a node to its predecessor, this left thread
to |q| must come from |q|'s successor, which we'll call |s|.  The
situation looks like this:

@center @image{tbstparent}

This leads immediately to an algorithm to find |q| given |p|, if |p|
is |q|'s right child.  We simply follow left links starting at |p|
until we we reach a thread, then we follow that thread.  On the other
hand, it doesn't help if |p| is |q|'s left child, but there's an
analogous situation with |q|'s predecessor in that case.

Will this algorithm work for any node in a TBST?  It won't work for the
root node, because no thread points above the root (see
@value{tbstrootparentbrief}).  It will work for any other node, because
any node other than the root has its successor or predecessor as its
parent.

Here is the actual code, which finds and returns the parent of |node|.
It traverses both the left and right subtrees of |node| at once, using
|x| to move down to the left and |y| to move down to the right.  When
it hits a thread on one side, it checks whether it leads to |node|'s
parent.  If it does, then we're done.  If it doesn't, then we continue
traversing along the other side, which is guaranteed to lead to
|node|'s parent.

@cat tbst Parent of a node
@<Find parent of a TBST node@> =
/* Returns the parent of |node| within |tree|,
   or a pointer to |tbst_root| if |s| is the root of the tree. */
static struct tbst_node *@
find_parent (struct tbst_table *tree, struct tbst_node *node) @
{
  if (node != tree->tbst_root) @
    {@-
      struct tbst_node *x, *y;

      for (x = y = node; ; x = x->tbst_link[0], y = y->tbst_link[1])
        if (y->tbst_tag[1] == TBST_THREAD) @
          {@-
            struct tbst_node *p = y->tbst_link[1];
            if (p == NULL || p->tbst_link[0] != node) @
              {@-
                while (x->tbst_tag[0] == TBST_CHILD)
                  x = x->tbst_link[0];
                p = x->tbst_link[0];
              }@+
            return p;
          }@+
        else if (x->tbst_tag[0] == TBST_THREAD) @
          {@-
            struct tbst_node *p = x->tbst_link[0];
            if (p == NULL || p->tbst_link[1] != node) @
              {@-
                while (y->tbst_tag[1] == TBST_CHILD)
                  y = y->tbst_link[1];
                p = y->tbst_link[1];
              }@+
            return p;
          }@+
    }@+
  else @
    return (struct tbst_node *) &tree->tbst_root;
}
@

@references
@bibref{Knuth 1997}, exercise 2.3.1-19.

@exercise*
Show that finding the parent of a given node using this algorithm,
averaged over all the node within a TBST, requires only a constant
number of links to be followed.

@answer
Our argument here is similar to that in @value{tbstthreadsearch}.
Consider the links that are traversed to successfully find the parent
of each node, besides the root, in the tree shown below.  Do not
include links followed on the side that does not lead to the node's
parent.  Because there are never more of these than on the successful
side, they add only a constant time to the algorithm and can be
ignored.

@center @image{tbstdel6}

@noindent
The table below lists the links followed.  The important point is that
no link is listed twice.

@multitable @columnfractions .3 .1 .3
@item
@tab Node
@tab Links Followed to Node's Parent

@item
@tab 0
@tab |0->2, 2->3|

@item
@tab 1
@tab |1->2|

@item
@tab 2
@tab |2->1, 1->0|

@item
@tab 3
@tab |3->5, 5->6|

@item
@tab 4
@tab |4->5|

@item
@tab 5
@tab |5->4, 4->3|

@item
@tab 6
@tab (root)

@item
@tab 7
@tab |7->6|
@end multitable

This generalizes to all TBSTs.  Because a TBST with |n| nodes contains
only |2n| links, this means we have an upper bound on finding the parent
of every node in a TBST of at most |2n| successful link traversals plus
|2n| unsuccessful link traversals.  Averaging |4n| over |n| nodes, we
get an upper bound of |4n/n @= 4| link traversals, on average, to find
the parent of a given node.

This upper bound applies only to the average case, not to the case of
any individual node.  In particular, it does not say that the usage of
the algorithm in |tavl_delete()| will exhibit average behavior.  In
practice, however, the performance of this algorithm in
|tavl_delete()| seems quite acceptable.  See @value{tbstdelstackbrief}
for an alternative with more certain behavior.
@end exercise

@exercise tbstrootparent
The structure of threads in our TBSTs force finding the parent of the
root node to be special-cased.  Suggest a modification to the tree
structure to avoid this.

@answer
Instead of storing a null pointer in the left thread of the least node
and the right thread of the greatest node, store a pointer to a node
``above the root''.  To make this work properly, |tavl_root| will have
to become an actual node, not just a node pointer, because otherwise
trying to find its right child would invoke undefined behavior.  Also,
both of |tavl_root|'s children would have to be the root node.

This is probably not worth it.  On the surface it seems like a good idea
but ugliness lurks beneath.
@end exercise

@exercise tbstdelstack
It can take several steps to find the parent of an arbitrary node in a
TBST, even though the operation is ``efficient'' in the sense of
@value{tbstthreadsearch}.  On the other hand, finding the parent of a
node is very fast with a stack, but it costs time to construct the
stack.  Rewrite |tavl_delete()| to use a stack instead of the parent
node algorithm.

@answer
The necessary changes are pervasive, so the complete code for the
modified function is presented below.  The search step is borrowed from
TRB deletion, presented in the next chapter.

@cat tavl Deletion, with stack
@c tested 2001/11/10
@<TAVL item deletion function, with stack@> =
@iftangle
/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
@end iftangle
void *@
tavl_delete (struct tavl_table *tree, const void *item) @
{
  /* Stack of nodes. */
  struct tavl_node *pa[TAVL_MAX_HEIGHT]; /* Nodes. */
  unsigned char da[TAVL_MAX_HEIGHT];     /* |tavl_link[]| indexes. */
  int k = 0;                             /* Stack pointer. */
  
  struct tavl_node *p; /* Traverses tree to find node to delete. */
  int cmp;             /* Result of comparison between |item| and |p|. */
  int dir;             /* Child of |p| to visit next. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Search TRB tree for item to delete; trb => tavl@>
  @<Step 2: Delete item from TAVL tree, with stack@>
  @<Steps 3 and 4: Update balance factors and rebalance after TAVL deletion, with stack@>

  return (void *) item;
}

@

@<Step 2: Delete item from TAVL tree, with stack@> =
if (p->tavl_tag[1] == TAVL_THREAD) @
  {@-
    if (p->tavl_tag[0] == TAVL_CHILD)
      { @
        @<Case 1 in TAVL deletion, with stack@> @
      }
    else @
      { @
        @<Case 2 in TAVL deletion, with stack@> @
      }
  }@+ @
else @
  {@-
    struct tavl_node *r = p->tavl_link[1];
    if (r->tavl_tag[0] == TAVL_THREAD)
      { @
        @<Case 3 in TAVL deletion, with stack@> @
      }
    else @
      { @
        @<Case 4 in TAVL deletion, with stack@> @
      }
  }@+

tree->tavl_count--;
tree->tavl_alloc->libavl_free (tree->tavl_alloc, p);

@

@<Case 1 in TAVL deletion, with stack@> =
struct tavl_node *r = p->tavl_link[0];
while (r->tavl_tag[1] == TAVL_CHILD)
  r = r->tavl_link[1];
r->tavl_link[1] = p->tavl_link[1];
pa[k - 1]->tavl_link[da[k - 1]] = p->tavl_link[0];
@

@<Case 2 in TAVL deletion, with stack@> =
pa[k - 1]->tavl_link[da[k - 1]] = p->tavl_link[da[k - 1]];
if (pa[k - 1] != (struct tavl_node *) &tree->tavl_root)
  pa[k - 1]->tavl_tag[da[k - 1]] = TAVL_THREAD;
@

@<Case 3 in TAVL deletion, with stack@> =
r->tavl_link[0] = p->tavl_link[0];
r->tavl_tag[0] = p->tavl_tag[0];
r->tavl_balance = p->tavl_balance;
if (r->tavl_tag[0] == TAVL_CHILD) @
  {@-
    struct tavl_node *x = r->tavl_link[0];
    while (x->tavl_tag[1] == TAVL_CHILD)
      x = x->tavl_link[1];
    x->tavl_link[1] = r;
  }@+
pa[k - 1]->tavl_link[da[k - 1]] = r;
da[k] = 1;
pa[k++] = r;
@

@<Case 4 in TAVL deletion, with stack@> =
struct tavl_node *s;
int j = k++;

for (;;) @
  {@-
    da[k] = 0;
    pa[k++] = r;
    s = r->tavl_link[0];
    if (s->tavl_tag[0] == TAVL_THREAD)
      break;

    r = s;
  }@+

da[j] = 1;
pa[j] = pa[j - 1]->tavl_link[da[j - 1]] = s;

if (s->tavl_tag[1] == TAVL_CHILD)
  r->tavl_link[0] = s->tavl_link[1];
else @
  {@-
    r->tavl_link[0] = s;
    r->tavl_tag[0] = TAVL_THREAD;
  }@+

s->tavl_balance = p->tavl_balance;

s->tavl_link[0] = p->tavl_link[0];
if (p->tavl_tag[0] == TAVL_CHILD) @
  {@-
    struct tavl_node *x = p->tavl_link[0];
    while (x->tavl_tag[1] == TAVL_CHILD)
      x = x->tavl_link[1];
    x->tavl_link[1] = s;

    s->tavl_tag[0] = TAVL_CHILD;
  }@+

s->tavl_link[1] = p->tavl_link[1];
s->tavl_tag[1] = TAVL_CHILD;
@

@<Steps 3 and 4: Update balance factors and rebalance after TAVL deletion, with stack@> =
assert (k > 0);
while (--k > 0) @
  {@-
    struct tavl_node *y = pa[k];

    if (da[k] == 0) @
      {@-
        y->tavl_balance++;
        if (y->tavl_balance == +1) @
          break;
        else if (y->tavl_balance == +2) @
          {@-
            @<Step 4: Rebalance after TAVL deletion, with stack@>
          }@+
      }@+ @
    else @
      {@-
        @<Steps 3 and 4: Symmetric case in TAVL deletion, with stack@>
      }@+
  }@+
@

@<Step 4: Rebalance after TAVL deletion, with stack@> =
struct tavl_node *x = y->tavl_link[1];
assert (x != NULL);
if (x->tavl_balance == -1) @
  {@-
    struct tavl_node *w;

    @<Rebalance for |-| balance factor in TAVL insertion in right subtree@>
    pa[k - 1]->tavl_link[da[k - 1]] = w;
  }@+
else if (x->tavl_balance == 0) @
  {@-
    y->tavl_link[1] = x->tavl_link[0];
    x->tavl_link[0] = y;
    x->tavl_balance = -1;
    y->tavl_balance = +1;
    pa[k - 1]->tavl_link[da[k - 1]] = x;
    break;
  }@+
else /* |x->tavl_balance == +1| */ @
  {@-
    if (x->tavl_tag[0] == TAVL_CHILD)
      y->tavl_link[1] = x->tavl_link[0];
    else @
      {@-
        y->tavl_tag[1] = TAVL_THREAD;
        x->tavl_tag[0] = TAVL_CHILD;
      }@+
    x->tavl_link[0] = y;  
    x->tavl_balance = y->tavl_balance = 0;
    pa[k - 1]->tavl_link[da[k - 1]] = x;
  }@+
@

@<Steps 3 and 4: Symmetric case in TAVL deletion, with stack@> =
y->tavl_balance--;
if (y->tavl_balance == -1) @
  break;
else if (y->tavl_balance == -2) @
  {@-
    struct tavl_node *x = y->tavl_link[0];
    assert (x != NULL);
    if (x->tavl_balance == +1) @
      {@-
        struct tavl_node *w;

        @<Rebalance for |+| balance factor in TAVL insertion in left subtree@>
        pa[k - 1]->tavl_link[da[k - 1]] = w;
      }@+
    else if (x->tavl_balance == 0) @
      {@-
        y->tavl_link[0] = x->tavl_link[1];
        x->tavl_link[1] = y;
        x->tavl_balance = +1;
        y->tavl_balance = -1;
        pa[k - 1]->tavl_link[da[k - 1]] = x;
        break;
      }@+
    else /* |x->tavl_balance == -1| */ @
      {@-
        if (x->tavl_tag[1] == TAVL_CHILD)
          y->tavl_link[0] = x->tavl_link[1];
        else @
          {@-
            y->tavl_tag[0] = TAVL_THREAD;
            x->tavl_tag[1] = TAVL_CHILD;
          }@+
        x->tavl_link[1] = y;
        x->tavl_balance = y->tavl_balance = 0;
        pa[k - 1]->tavl_link[da[k - 1]] = x;
      }@+
  }@+
@
@end exercise

@node Copying a TAVL Tree, Testing TAVL Trees, Deleting from a TAVL Tree, Threaded AVL Trees
@section Copying

We can use the tree copy function for TBSTs almost verbatim here.  The
one necessary change is that |copy_node()| must copy node balance
factors.  Here's the new version:

@cat tavl Copying a node
@<TAVL node copy function@> =
@iftangle
/* Creates a new node as a child of |dst| on side |dir|.
   Copies data and |tavl_balance| from |src| into the new node, @
   applying |copy()|, if non-null.
   Returns nonzero only if fully successful.
   Regardless of success, integrity of the tree structure is assured,
   though failure may leave a null pointer in a |tavl_data| member. */
@end iftangle
static int @
copy_node (struct tavl_table *tree, @
           struct tavl_node *dst, int dir,
           const struct tavl_node *src, tavl_copy_func *copy) @
{
  struct tavl_node *new = @
    tree->tavl_alloc->libavl_malloc (tree->tavl_alloc, sizeof *new);
  if (new == NULL)
    return 0;

  new->tavl_link[dir] = dst->tavl_link[dir];
  new->tavl_tag[dir] = TAVL_THREAD;
  new->tavl_link[!dir] = dst;
  new->tavl_tag[!dir] = TAVL_THREAD;
  dst->tavl_link[dir] = new;
  dst->tavl_tag[dir] = TAVL_CHILD;

  new->tavl_balance = src->tavl_balance;
  if (copy == NULL)
    new->tavl_data = src->tavl_data;
  else @
    {@-
      new->tavl_data = copy (src->tavl_data, tree->tavl_param);
      if (new->tavl_data == NULL)
        return 0;
    }@+

  return 1;
}

@

@<TAVL copy function@> =
@<TAVL node copy function@>
@<TBST copy error helper function; tbst => tavl@>
@<TBST main copy function; tbst => tavl@>
@

@node Testing TAVL Trees,  , Copying a TAVL Tree, Threaded AVL Trees
@section Testing

The testing code harbors no surprises.

@(tavl-test.c@> =
@<Program License@>
#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include "tavl.h"
#include "test.h"

@<TBST print function; tbst => tavl@>
@<BST traverser check function; bst => tavl@>
@<Compare two TAVL trees for structure and content@>
@<Recursively verify TAVL tree structure@>
@<AVL tree verify function; avl => tavl@>
@<BST test function; bst => tavl@>
@<BST overflow test function; bst => tavl@>
@

@<Compare two TAVL trees for structure and content@> =
@iftangle
/* Compares binary trees rooted at |a| and |b|, @
   making sure that they are identical. */
@end iftangle
static int @
compare_trees (struct tavl_node *a, struct tavl_node *b) @
{
  int okay;

  if (a == NULL || b == NULL) @
    {@-
      if (a != NULL || b != NULL) @
	{@-
	  printf (" a=%d b=%d\n",
		  a ? *(int *) a->tavl_data : -1, @
		  b ? *(int *) b->tavl_data : -1);
	  assert (0);
	}@+
      return 1;
    }@+
  assert (a != b);

  if (*(int *) a->tavl_data != *(int *) b->tavl_data
      || a->tavl_tag[0] != b->tavl_tag[0] @
      || a->tavl_tag[1] != b->tavl_tag[1]
      || a->tavl_balance != b->tavl_balance) @
    {@-
      printf (" Copied nodes differ: a=%d (bal=%d) b=%d (bal=%d) a:",
	      *(int *) a->tavl_data, a->tavl_balance,
              *(int *) b->tavl_data, b->tavl_balance);

      if (a->tavl_tag[0] == TAVL_CHILD) @
	printf ("l");
      if (a->tavl_tag[1] == TAVL_CHILD) @
	printf ("r");

      printf (" b:");
      if (b->tavl_tag[0] == TAVL_CHILD) @
	printf ("l");
      if (b->tavl_tag[1] == TAVL_CHILD) @
	printf ("r");

      printf ("\n");
      return 0;
    }@+

  if (a->tavl_tag[0] == TAVL_THREAD)
    assert ((a->tavl_link[0] == NULL) != (a->tavl_link[0] != b->tavl_link[0]));
  if (a->tavl_tag[1] == TAVL_THREAD)
    assert ((a->tavl_link[1] == NULL) != (a->tavl_link[1] != b->tavl_link[1]));

  okay = 1;
  if (a->tavl_tag[0] == TAVL_CHILD)
    okay &= compare_trees (a->tavl_link[0], b->tavl_link[0]);
  if (a->tavl_tag[1] == TAVL_CHILD)
    okay &= compare_trees (a->tavl_link[1], b->tavl_link[1]);
  return okay;
}

@

@<Recursively verify TAVL tree structure@> =
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
recurse_verify_tree (struct tavl_node *node, int *okay, size_t *count, 
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
  d = *(int *) node->tavl_data;

  @<Verify binary search tree ordering@>

  subcount[0] = subcount[1] = 0;
  subheight[0] = subheight[1] = 0;
  if (node->tavl_tag[0] == TAVL_CHILD)
    recurse_verify_tree (node->tavl_link[0], okay, &subcount[0], 
                         min, d -  1, &subheight[0]);
  if (node->tavl_tag[1] == TAVL_CHILD)
    recurse_verify_tree (node->tavl_link[1], okay, &subcount[1], 
                         d + 1, max, &subheight[1]);
  *count = 1 + subcount[0] + subcount[1];
  *height = 1 + (subheight[0] > subheight[1] ? subheight[0] : subheight[1]);

  @<Verify AVL node balance factor; avl => tavl@>
}

@

