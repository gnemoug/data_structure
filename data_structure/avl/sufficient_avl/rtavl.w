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

@deftypedef rtavl_comparison_func
@deftypedef rtavl_item_func
@deftypedef rtavl_copy_func

@node Right-Threaded AVL Trees, Right-Threaded Red-Black Trees, Right-Threaded Binary Search Trees, Top
@chapter Right-Threaded AVL Trees

In the same way that we can combine threaded trees with AVL trees to
produce threaded AVL trees, we can combine right-threaded trees with
AVL trees to produce right-threaded AVL trees.  This chapter explores
this combination, producing another table implementation.

Here's the form of the source and header files.  Notice the use of
|rtavl_| as the identifier prefix.  Likewise, we will often refer to
right-threaded AVL trees as ``RTAVL trees''.

@(rtavl.h@> =
@<Library License@>
#ifndef RTAVL_H
#define RTAVL_H 1

#include <stddef.h>

@<Table types; tbl => rtavl@>
@<BST maximum height; bst => rtavl@>
@<TBST table structure; tbst => rtavl@>
@<RTAVL node structure@>
@<TBST traverser structure; tbst => rtavl@>
@<Table function prototypes; tbl => rtavl@>

#endif /* rtavl.h */
@ 

@(rtavl.c@> =
@<Library License@>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "rtavl.h"

@<RTAVL functions@>
@

@menu
* RTAVL Data Types::            
* RTAVL Operations::            
* RTBST Rotations::             
* Inserting into an RTAVL Tree::  
* Deleting from an RTAVL Tree::  
* Copying an RTAVL Tree::       
* Testing RTAVL Trees::         
@end menu

@node RTAVL Data Types, RTAVL Operations, Right-Threaded AVL Trees, Right-Threaded AVL Trees
@section Data Types

Besides the members needed for any BST, an RTAVL node structure needs a
tag to indicate whether the right link is a child pointer or a thread,
and a balance factor to facilitate AVL balancing.  Here's what we end up
with:

@<RTAVL node structure@> =
/* Characterizes a link as a child pointer or a thread. */
enum rtavl_tag @
  {@-
    RTAVL_CHILD,                     /* Child pointer. */
    RTAVL_THREAD                     /* Thread. */
  };@+

/* A threaded binary search tree node. */
struct rtavl_node @
  {@-
    struct rtavl_node *rtavl_link[2]; /* Subtrees. */
    void *rtavl_data;                 /* Pointer to data. */
    unsigned char rtavl_rtag;         /* Tag field. */
    signed char rtavl_balance;        /* Balance factor. */
  };@+

@

@node RTAVL Operations, RTBST Rotations, RTAVL Data Types, Right-Threaded AVL Trees
@section Operations

Most of the operations for RTAVL trees can come directly from their
RTBST implementations.  The notable exceptions are, as usual, the
insertion and deletion functions.  The copy function will also need a
small tweak.  Here's the list of operations:

@<RTAVL functions@> =
@<TBST creation function; tbst => rtavl@>
@<RTBST search function; rtbst => rtavl@>
@<RTAVL item insertion function@>
@<Table insertion convenience functions; tbl => rtavl@>
@<RTAVL item deletion function@>
@<RTBST traversal functions; rtbst => rtavl@>
@<RTAVL copy function@>
@<RTBST destruction function; rtbst => rtavl@>
@<Default memory allocation functions; tbl => rtavl@>
@<Table assertion functions; tbl => rtavl@>
@

@node RTBST Rotations, Inserting into an RTAVL Tree, RTAVL Operations, Right-Threaded AVL Trees
@section Rotations

We will use rotations in right-threaded trees in the same way as for
other kinds of trees that we have already examined.  As always, a
generic rotation looks like this:

@center @image{rotation}

On the left side of this diagram, |a| may be an empty subtree and |b|
and |c| may be threads.  On the right side, |a| and |b| may be empty
subtrees and |c| may be a thread.  If none of them in fact represent
actual nodes, then we end up with the following pathological case:

@center @image{rtavlrot}

Notice the asymmetry here: in a right rotation the right thread from
|X| to |Y| becomes a null left child of |Y|, but in a left rotation
this is reversed and a null subtree |b| becomes a right thread from
|X| to |Y|.  Contrast this to the correponding rotation in a threaded
tree (@pxref{TBST Rotations}), where either way the same kind of
change occurs: the thread from |X| to |Y|, or vice versa, simply
reverses direction.

As with other kinds of rotations we've seen, there is no need to make
any changes in subtrees of |a|, |b|, or |c|, because of rotations'
locality and order-preserving properties (@pxref{BST Rotations}).  In
particular, nodes |a| and |c|, if they exist, need no adjustments, as
implied by the diagram above, which shows no changes to these subtrees
on opposite sides.

@exercise rtbstrot
Write functions for right and left rotations in right-threaded BSTs,
analogous to those for unthreaded BSTs developed in @value{bstrotation}.

@answer
@cat rtbst Rotation, right
@<Anonymous@> =
/* Rotates right at |*yp|. */
static void @
rotate_right (struct rtbst_node **yp) @
{
  struct rtbst_node *y = *yp;
  struct rtbst_node *x = y->rtbst_link[0];
  if (x->rtbst_rtag[1] == RTBST_THREAD) @
    {@-
      x->rtbst_rtag = RTBST_CHILD;
      y->rtbst_link[0] = NULL;
    }@+
  else @
    y->rtbst_link[0] = x->rtbst_link[1];
  x->rtbst_link[1] = y;
  *yp = x;
}
@

@cat rtbst Rotation, left
@<Anonymous@> =
/* Rotates left at |*xp|. */
static void @
rotate_left (struct rtbst_node **xp) @
{
  struct rtbst_node *x = *xp;
  struct rtbst_node *y = x->rtbst_link[1];
  if (y->rtbst_link[0] == NULL) @
    {@-
      x->rtbst_rtag = RTBST_THREAD;
      x->rtbst_link[1] = y;
    }@+
  else @
    x->rtbst_link[1] = y->rtbst_link[0];
  y->rtbst_link[0] = x;
  *xp = y;
}
@
@end exercise

@node Inserting into an RTAVL Tree, Deleting from an RTAVL Tree, RTBST Rotations, Right-Threaded AVL Trees
@section Insertion

Insertion into an RTAVL tree follows the same pattern as insertion into
other kinds of balanced tree.  The outline is straightforward:

@cat rtavl Insertion
@<RTAVL item insertion function@> =
@iftangle
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree, 
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
@end iftangle
void **@
rtavl_probe (struct rtavl_table *tree, void *item) @
{
  @<|avl_probe()| local variables; avl => rtavl@>

  assert (tree != NULL && item != NULL);

  @<Step 1: Search RTAVL tree for insertion point@>
  @<Step 2: Insert RTAVL node@>
  @<Step 3: Update balance factors after AVL insertion; avl => rtavl@>
  @<Step 4: Rebalance after RTAVL insertion@>
}

@

@menu
* Steps 1-1 in RTAVL Insertion::  
* Rebalancing RTAVL Trees::     
@end menu

@node Steps 1-1 in RTAVL Insertion, Rebalancing RTAVL Trees, Inserting into an RTAVL Tree, Inserting into an RTAVL Tree
@subsection Steps 1--2: Search and Insert

The basic insertion step itself follows the same steps as @<RTBST item
insertion function@> does for a plain RTBST.  We do keep track of the
directions moved on stack |da[]| and the last-seen node with nonzero
balance factor, in the same way as @<Step 1: Search AVL tree for
insertion point@> for unthreaded AVL trees.

@<Step 1: Search RTAVL tree for insertion point@> =
z = (struct rtavl_node *) &tree->rtavl_root;
y = tree->rtavl_root;
if (tree->rtavl_root != NULL)
  for (q = z, p = y; ; q = p, p = p->rtavl_link[dir]) @
    {@-
      int cmp = tree->rtavl_compare (item, p->rtavl_data, tree->rtavl_param);
      if (cmp == 0)
        return &p->rtavl_data;

      if (p->rtavl_balance != 0)
        z = q, y = p, k = 0;
      da[k++] = dir = cmp > 0;

      if (dir == 0) @
        {@-
          if (p->rtavl_link[0] == NULL)
            break;
        }@+ @
      else /* |dir == 1| */ @
        {@-
          if (p->rtavl_rtag == RTAVL_THREAD)
            break;
        }@+
    }@+
else @
  {@-
    p = (struct rtavl_node *) &tree->rtavl_root;
    dir = 0;
  }@+
@

@<Step 2: Insert RTAVL node@> =
n = tree->rtavl_alloc->libavl_malloc (tree->rtavl_alloc, sizeof *n);
if (n == NULL)
  return NULL;

tree->rtavl_count++;
n->rtavl_data = item;
n->rtavl_link[0] = NULL;
if (dir == 0)
  n->rtavl_link[1] = p;
else /* |dir == 1| */ @
  {@-
    p->rtavl_rtag = RTAVL_CHILD;
    n->rtavl_link[1] = p->rtavl_link[1];
  }@+
n->rtavl_rtag = RTAVL_THREAD;
n->rtavl_balance = 0;
p->rtavl_link[dir] = n;
if (y == NULL) @
  {@-
    n->rtavl_link[1] = NULL;
    return &n->rtavl_data;
  }@+

@

@node Rebalancing RTAVL Trees,  , Steps 1-1 in RTAVL Insertion, Inserting into an RTAVL Tree
@subsection Step 4: Rebalance

Unlike all of the AVL rebalancing algorithms we've seen so far,
rebalancing of a right-threaded AVL tree is not symmetric.  This means
that we cannot single out left-side rebalancing or right-side
rebalancing as we did before, hand-waving the rest of it as a symmetric
case.  But both cases are very similar, if not exactly symmetric, so we
will present the corresponding cases together.  The theory is exactly
the same as before (@pxref{Rebalancing AVL Trees}).  Here is the code
to choose between left-side and right-side rebalancing:

@<Step 4: Rebalance after RTAVL insertion@> =
if (y->rtavl_balance == -2)
  { @
    @<Step 4: Rebalance RTAVL tree after insertion to left@> @
  }
else if (y->rtavl_balance == +2)
  { @
    @<Step 4: Rebalance RTAVL tree after insertion to right@> @
  }
else @
  return &n->rtavl_data;

z->rtavl_link[y != z->rtavl_link[0]] = w;
return &n->rtavl_data;
@

The code to choose between the two subcases within the left-side and
right-side rebalancing cases follows below.  As usual during
rebalancing, |y| is the node at which rebalancing occurs, |x| is its
child on the same side as the inserted node, and cases are
distinguished on the basis of |x|'s balance factor:

@<Step 4: Rebalance RTAVL tree after insertion to left@> =
struct rtavl_node *x = y->rtavl_link[0];
if (x->rtavl_balance == -1)
  { @
    @<Rebalance for |-| balance factor in RTAVL insertion in left subtree@> @
  } 
else @
  { @
    @<Rebalance for |+| balance factor in RTAVL insertion in left subtree@> @
  }
@

@<Step 4: Rebalance RTAVL tree after insertion to right@> =
struct rtavl_node *x = y->rtavl_link[1];
if (x->rtavl_balance == +1)
  { @
    @<Rebalance for |+| balance factor in RTAVL insertion in right subtree@> @
  } 
else @
  { @
    @<Rebalance for |-| balance factor in RTAVL insertion in right subtree@> @
  }
@

@subsubheading Case 1: |x| has taller subtree on side of insertion

If node |x|'s taller subtree is on the same side as the inserted node,
then we perform a rotation at |y| in the opposite direction.  That is,
if the insertion occurred in the left subtree of |y| and |x| has a |-|
balance factor, we rotate right at |y|, and if the insertion was to
the right and |x| has a |+| balance factor, we rotate left at |y|.
This changes the balance of both |x| and |y| to zero.  None of this is
a change from unthreaded or fully threaded rebalancing.  The
difference is in the handling of empty subtrees, that is, in the
rotation itself (@pxref{RTBST Rotations}).

Here is a diagram of left-side rebalancing for the interesting case
where |x| has a right thread.  Taken along with |x|'s |-| balance
factor, this means that |n|, the newly inserted node, must be |x|'s left
child.  Therefore, subtree |x| has height 2, so |y| has no right child
(because it has a |-2| balance factor).  This chain of logic means that
we know exactly what the tree looks like in this particular subcase:

@center @image{rtavlins1}

@<Rebalance for |-| balance factor in RTAVL insertion in left subtree@> =
w = x;
if (x->rtavl_rtag == RTAVL_THREAD) @
  {@-
    x->rtavl_rtag = RTAVL_CHILD;
    y->rtavl_link[0] = NULL;
  }@+
else @
  y->rtavl_link[0] = x->rtavl_link[1];
x->rtavl_link[1] = y;
x->rtavl_balance = y->rtavl_balance = 0;
@

Here is the diagram and code for the similar right-side case:

@center @image{rtavlins2}

@<Rebalance for |+| balance factor in RTAVL insertion in right subtree@> =
w = x;
if (x->rtavl_link[0] == NULL) @
  {@-
    y->rtavl_rtag = RTAVL_THREAD;
    y->rtavl_link[1] = x;
  }@+
else @
  y->rtavl_link[1] = x->rtavl_link[0];
x->rtavl_link[0] = y;
x->rtavl_balance = y->rtavl_balance = 0;
@

@subsubheading Case 2: |x| has taller subtree on side opposite insertion
@anchor{rtavlinscase2}

If node |x|'s taller subtree is on the side opposite the newly inserted
node, then we perform a double rotation: first rotate at |x| in the same
direction as the inserted node, then in the opposite direction at |y|.
This is the same as in a threaded or unthreaded tree, and indeed we can
reuse much of the code.

The case where the details differ is, as usual, where threads or null
child pointers are moved around.  In the most extreme case for insertion
to the left, where |w| is a leaf, we know that |x| has no left child and
|s| no right child, and the situation looks like the diagram below
before and after the rebalancing step:

@center @image{rtavlins3}

@<Rebalance for |+| balance factor in RTAVL insertion in left subtree@> =
@<Rotate left at |x| then right at |y| in AVL tree; avl => rtavl@>
if (x->rtavl_link[1] == NULL) @
  {@-
    x->rtavl_rtag = RTAVL_THREAD;
    x->rtavl_link[1] = w;
  }@+
if (w->rtavl_rtag == RTAVL_THREAD) @
  {@-
    y->rtavl_link[0] = NULL;
    w->rtavl_rtag = RTAVL_CHILD;
  }@+
@

Here is the code and diagram for right-side insertion rebalancing:

@center @image{rtavlins4}

@<Rebalance for |-| balance factor in RTAVL insertion in right subtree@> =
@<Rotate right at |x| then left at |y| in AVL tree; avl => rtavl@>
if (y->rtavl_link[1] == NULL) @
  {@-
    y->rtavl_rtag = RTAVL_THREAD;
    y->rtavl_link[1] = w;
  }@+
if (w->rtavl_rtag == RTAVL_THREAD) @
  {@-
    x->rtavl_link[0] = NULL;
    w->rtavl_rtag = RTAVL_CHILD;
  }@+
@

@node Deleting from an RTAVL Tree, Copying an RTAVL Tree, Inserting into an RTAVL Tree, Right-Threaded AVL Trees
@section Deletion

Deletion in an RTAVL tree takes the usual pattern.

@cat rtavl Deletion (left-looking)
@<RTAVL item deletion function@> =
@iftangle
/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
@end iftangle
void *@
rtavl_delete (struct rtavl_table *tree, const void *item) @
{
  /* Stack of nodes. */
  struct rtavl_node *pa[RTAVL_MAX_HEIGHT]; /* Nodes. */
  unsigned char da[RTAVL_MAX_HEIGHT];     /* |rtavl_link[]| indexes. */
  int k;                                  /* Stack pointer. */

  struct rtavl_node *p; /* Traverses tree to find node to delete. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Search RTAVL tree for item to delete@>
  @<Step 2: Delete RTAVL node@>
  @<Steps 3 and 4: Update balance factors and rebalance after RTAVL deletion@>

  return (void *) item;
}

@

@menu
* Deleting a RTAVL Node Step 1 - Search::  
* Deleting a RTAVL Node Step 2 - Delete::  
* Deleting a RTAVL Node Step 3 - Update::  
* Deleting a RTAVL Node Step 4 - Rebalance::  
@end menu

@node Deleting a RTAVL Node Step 1 - Search, Deleting a RTAVL Node Step 2 - Delete, Deleting from an RTAVL Tree, Deleting from an RTAVL Tree
@subsection Step 1: Search

There's nothing new in searching an RTAVL tree for a node to delete.  We
use |p| to search the tree, and push its chain of parent nodes onto
stack |pa[]| along with the directions |da[]| moved down from them,
including the pseudo-root node at the top.

@<Step 1: Search RTAVL tree for item to delete@> =
k = 1;
da[0] = 0;
pa[0] = (struct rtavl_node *) &tree->rtavl_root;
p = tree->rtavl_root;
if (p == NULL)
  return NULL;

for (;;) @
  {@-
    int cmp, dir;

    cmp = tree->rtavl_compare (item, p->rtavl_data, tree->rtavl_param);
    if (cmp == 0)
      break;

    dir = cmp > 0;
    if (dir == 0) @
      {@-
        if (p->rtavl_link[0] == NULL)
          return NULL;
      }@+ @
    else /* |dir == 1| */ @
      {@-
        if (p->rtavl_rtag == RTAVL_THREAD)
          return NULL;
      }@+

    pa[k] = p;
    da[k++] = dir;
    p = p->rtavl_link[dir];
  }@+
tree->rtavl_count--;
item = p->rtavl_data;

@

@node Deleting a RTAVL Node Step 2 - Delete, Deleting a RTAVL Node Step 3 - Update, Deleting a RTAVL Node Step 1 - Search, Deleting from an RTAVL Tree
@subsection Step 2: Delete

As demonstrated in the previous chapter, left-looking deletion, where we
examine the left subtree of the node to be deleted, is more efficient
than right-looking deletion in an RTBST (@pxref{Left-Looking
Deletion in an RTBST}).  This holds true in an RTAVL tree, too.

@<Step 2: Delete RTAVL node@> =
if (p->rtavl_link[0] == NULL) @
  {@-
    if (p->rtavl_rtag == RTAVL_CHILD)
      { @
        @<Case 1 in RTAVL deletion@> @
      }
    else @
      { @
        @<Case 2 in RTAVL deletion@> @
      }
  }@+ @
else @
  {@-
    struct rtavl_node *r = p->rtavl_link[0];
    if (r->rtavl_rtag == RTAVL_THREAD)
      { @
        @<Case 3 in RTAVL deletion@> @
      }
    else @
      { @
        @<Case 4 in RTAVL deletion@> @
      }
  }@+

tree->rtavl_alloc->libavl_free (tree->rtavl_alloc, p);

@

@subsubheading Case 1: |p| has a right child but no left child

If the node to be deleted, |p|, has a right child but not a left child,
then we replace it by its right child.

@<Case 1 in RTAVL deletion@> =
pa[k - 1]->rtavl_link[da[k - 1]] = p->rtavl_link[1];
@

@subsubheading Case 2: |p| has a right thread and no left child

If we are deleting a leaf, then we replace it by a null pointer if it's
a left child, or by a pointer to its own former right thread if it's a
right child.  Refer back to the commentary on @<Case 2 in right-looking
RTBST deletion@> for further explanation.

@<Case 2 in RTAVL deletion@> =
pa[k - 1]->rtavl_link[da[k - 1]] = p->rtavl_link[da[k - 1]];
if (da[k - 1] == 1)
  pa[k - 1]->rtavl_rtag = RTAVL_THREAD;
@

@subsubheading Case 3: |p|'s left child has a right thread

If |p| has a left child |r|, and |r| has a right thread, then we replace
|p| by |r| and transfer |p|'s former right link to |r|.  Node |r| also
receives |p|'s balance factor.

@<Case 3 in RTAVL deletion@> =
r->rtavl_link[1] = p->rtavl_link[1];
r->rtavl_rtag = p->rtavl_rtag;
r->rtavl_balance = p->rtavl_balance;
pa[k - 1]->rtavl_link[da[k - 1]] = r;
da[k] = 0;
pa[k++] = r;
@

@subsubheading Case 4: |p|'s left child has a right child

The final case, where node |p|'s left child |r| has a right child, is
also the most complicated.  We find |p|'s predecessor |s| first:

@<Case 4 in RTAVL deletion@> =
struct rtavl_node *s;
int j = k++;

for (;;) @
  {@-
    da[k] = 1;
    pa[k++] = r;
    s = r->rtavl_link[1];
    if (s->rtavl_rtag == RTAVL_THREAD)
      break;

    r = s;
  }@+

@

Then we move |s| into |p|'s place, not forgetting to update links and
tags as necessary:

@<Case 4 in RTAVL deletion@> +=
da[j] = 0;
pa[j] = pa[j - 1]->rtavl_link[da[j - 1]] = s;

if (s->rtavl_link[0] != NULL)
  r->rtavl_link[1] = s->rtavl_link[0];
else @
  {@-
    r->rtavl_rtag = RTAVL_THREAD;
    r->rtavl_link[1] = s;
  }@+

@

Finally, we copy |p|'s old information into |s|, except for the actual
data:

@<Case 4 in RTAVL deletion@> +=
s->rtavl_balance = p->rtavl_balance;
s->rtavl_link[0] = p->rtavl_link[0];
s->rtavl_link[1] = p->rtavl_link[1];
s->rtavl_rtag = p->rtavl_rtag;
@

@node Deleting a RTAVL Node Step 3 - Update, Deleting a RTAVL Node Step 4 - Rebalance, Deleting a RTAVL Node Step 2 - Delete, Deleting from an RTAVL Tree
@subsection Step 3: Update Balance Factors

Updating balance factors works exactly the same way as in unthreaded AVL
deletion (@pxref{Deleting an AVL Node Step 3 - Update}).

@<Steps 3 and 4: Update balance factors and rebalance after RTAVL deletion@> =
assert (k > 0);
while (--k > 0) @
  {@-
    struct rtavl_node *y = pa[k];

    if (da[k] == 0) @
      {@-
        y->rtavl_balance++;
        if (y->rtavl_balance == +1)
          break;
        else if (y->rtavl_balance == +2) @
          {@-
            @<Step 4: Rebalance after RTAVL deletion in left subtree@>
          }@+
      }@+ @
    else @
      {@-
        y->rtavl_balance--;
	if (y->rtavl_balance == -1)
          break;
	else if (y->rtavl_balance == -2) @
	  {@-
            @<Step 4: Rebalance after RTAVL deletion in right subtree@>
	  }@+
      }@+
  }@+
@

@node Deleting a RTAVL Node Step 4 - Rebalance,  , Deleting a RTAVL Node Step 3 - Update, Deleting from an RTAVL Tree
@subsection Step 4: Rebalance

Rebalancing in an RTAVL tree after deletion is not completely symmetric
between left-side and right-side rebalancing, but there are pairs of
similar subcases on each side.  The outlines are similar, too.  Either
way, rebalancing occurs at node |y|, and cases are distinguished based
on the balance factor of |x|, the child of |y| on the side opposite the
deletion.

@<Step 4: Rebalance after RTAVL deletion in left subtree@> =
struct rtavl_node *x = y->rtavl_link[1];

assert (x != NULL);
if (x->rtavl_balance == -1) @
  {@-
    @<Rebalance for |-| balance factor after left-side RTAVL deletion@>
  }@+ @
else @
  {@-
    pa[k - 1]->rtavl_link[da[k - 1]] = x;
    if (x->rtavl_balance == 0) @
      {@-
        @<Rebalance for 0 balance factor after left-side RTAVL deletion@>
        break;
      }@+
    else /* |x->rtavl_balance == +1| */ @
      {@-
        @<Rebalance for |+| balance factor after left-side RTAVL deletion@>
      }@+
  }@+
@

@<Step 4: Rebalance after RTAVL deletion in right subtree@> =
struct rtavl_node *x = y->rtavl_link[0];

assert (x != NULL);
if (x->rtavl_balance == +1) @
  {@-
    @<Rebalance for |+| balance factor after right-side RTAVL deletion@>
  }@+ @
else @
  {@-
    pa[k - 1]->rtavl_link[da[k - 1]] = x;
    if (x->rtavl_balance == 0) @
      {@-
        @<Rebalance for 0 balance factor after right-side RTAVL deletion@>
        break;
      }@+
    else /* |x->rtavl_balance == -1| */ @
      {@-
        @<Rebalance for |-| balance factor after right-side RTAVL deletion@>
      }@+
  }@+
@

@subsubheading Case 1: |x| has taller subtree on same side as deletion

If the taller subtree of |x| is on the same side as the deletion, then
we rotate at |x| in the opposite direction from the deletion, then at
|y| in the same direction as the deletion. This is the same as case 2
for RTAVL insertion (@pageref{rtavlinscase2}), which in turn performs
the general transformation described for AVL deletion case 1
(@pageref{avldelcase1}), and we can reuse the code.

@<Rebalance for |-| balance factor after left-side RTAVL deletion@> =
struct rtavl_node *w;

@<Rebalance for |-| balance factor in RTAVL insertion in right subtree@>
pa[k - 1]->rtavl_link[da[k - 1]] = w;
@

@<Rebalance for |+| balance factor after right-side RTAVL deletion@> =
struct rtavl_node *w;

@<Rebalance for |+| balance factor in RTAVL insertion in left subtree@>
pa[k - 1]->rtavl_link[da[k - 1]] = w;
@

@subsubheading Case 2: |x|'s subtrees are equal height

If |x|'s two subtrees are of equal height, then we perform a rotation at
|y| toward the deletion.  This rotation cannot be troublesome, for the
same reason discussed for rebalancing in TAVL trees
(@pageref{tavldelcase2}).  We can even reuse the code:

@<Rebalance for 0 balance factor after left-side RTAVL deletion@> =
@<Rebalance for 0 balance factor after TAVL deletion in left subtree; tavl => rtavl@>
@

@<Rebalance for 0 balance factor after right-side RTAVL deletion@> =
@<Rebalance for 0 balance factor after TAVL deletion in right subtree; tavl => rtavl@>
@

@subsubheading Case 3: |x| has taller subtree on side opposite deletion

When |x|'s taller subtree is on the side opposite the deletion, we
rotate at |y| toward the deletion, same as case 2.  If the deletion was
on the left side of |y|, then the general form is the same as for TAVL
deletion (@pageref{tavldelcase3}).  The special case for left-side
deletion, where |x| lacks a left child, and the general form of the
code, are shown here:

@center @image{rtavldel1}

@<Rebalance for |+| balance factor after left-side RTAVL deletion@> =
if (x->rtavl_link[0] != NULL)
  y->rtavl_link[1] = x->rtavl_link[0];
else @
  y->rtavl_rtag = RTAVL_THREAD;
x->rtavl_link[0] = y;  
y->rtavl_balance = x->rtavl_balance = 0;
@

The special case for right-side deletion, where |x| lacks a right child,
and the general form of the code, are shown here:

@center @image{rtavldel2}

@<Rebalance for |-| balance factor after right-side RTAVL deletion@> =
if (x->rtavl_rtag == RTAVL_CHILD)
  y->rtavl_link[0] = x->rtavl_link[1];
else @
  {@-
    y->rtavl_link[0] = NULL;
    x->rtavl_rtag = RTAVL_CHILD;
  }@+
x->rtavl_link[1] = y;  
y->rtavl_balance = x->rtavl_balance = 0;
@

@exercise
In the chapter about TAVL deletion, we offered two implementations of
deletion: one using a stack (@<TAVL item deletion function, with
stack@>) and one using an algorithm to find node parents (@<TAVL item
deletion function@>).  For RTAVL deletion, we offer only a stack-based
implementation.  Why?

@answer
There is no general efficient algorithm to find the parent of a node in
an RTAVL tree.  The lack of left threads means that half the time we
must do a full search from the top of the tree.  This would increase the
execution time for deletion unacceptably.
@end exercise

@exercise
The introduction to this section states that left-looking deletion is
more efficient than right-looking deletion in an RTAVL tree.  Confirm
this by writing a right-looking alternate implementation of @<Step 2:
Delete RTAVL node@> and comparing the two sets of code.

@answer
@cat rtavl Deletion, right-looking
@c tested 2001/11/10
@<Step 2: Delete RTAVL node, right-looking@> =
if (p->rtavl_rtag == RTAVL_THREAD) @
  {@-
    if (p->rtavl_link[0] != NULL)
      { @
        @<Case 1 in RTAVL deletion, right-looking@> @
      }
    else @
      { @
        @<Case 2 in RTAVL deletion, right-looking@> @
      }
  }@+ @
else @
  {@-
    struct rtavl_node *r = p->rtavl_link[1];
    if (r->rtavl_link[0] == NULL)
      { @
        @<Case 3 in RTAVL deletion, right-looking@> @
      }
    else @
      { @
        @<Case 4 in RTAVL deletion, right-looking@> @
      }
  }@+

tree->rtavl_alloc->libavl_free (tree->rtavl_alloc, p);
@

@<Case 1 in RTAVL deletion, right-looking@> =
struct rtavl_node *t = p->rtavl_link[0];
while (t->rtavl_rtag == RTAVL_CHILD)
  t = t->rtavl_link[1];
t->rtavl_link[1] = p->rtavl_link[1];
pa[k - 1]->rtavl_link[da[k - 1]] = p->rtavl_link[0];
@

@<Case 2 in RTAVL deletion, right-looking@> =
pa[k - 1]->rtavl_link[da[k - 1]] = p->rtavl_link[da[k - 1]];
if (da[k - 1] == 1)
  pa[k - 1]->rtavl_rtag = RTAVL_THREAD;
@

@<Case 3 in RTAVL deletion, right-looking@> =
r->rtavl_link[0] = p->rtavl_link[0];
if (r->rtavl_link[0] != NULL) @
  {@-
    struct rtavl_node *t = r->rtavl_link[0];
    while (t->rtavl_rtag == RTAVL_CHILD)
      t = t->rtavl_link[1];
    t->rtavl_link[1] = r;
  }@+
pa[k - 1]->rtavl_link[da[k - 1]] = r;
r->rtavl_balance = p->rtavl_balance;
da[k] = 1;
pa[k++] = r;
@

@<Case 4 in RTAVL deletion, right-looking@> =
struct rtavl_node *s;
int j = k++;

for (;;) @
  {@-
    da[k] = 0;
    pa[k++] = r;
    s = r->rtavl_link[0];
    if (s->rtavl_link[0] == NULL)
      break;

    r = s;
  }@+

da[j] = 1;
pa[j] = pa[j - 1]->rtavl_link[da[j - 1]] = s;

if (s->rtavl_rtag == RTAVL_CHILD)
  r->rtavl_link[0] = s->rtavl_link[1];
else @
  r->rtavl_link[0] = NULL;

if (p->rtavl_link[0] != NULL) @
  {@-
    struct rtavl_node *t = p->rtavl_link[0];
    while (t->rtavl_rtag == RTAVL_CHILD)
      t = t->rtavl_link[1];
    t->rtavl_link[1] = s;
  }@+

s->rtavl_link[0] = p->rtavl_link[0];
s->rtavl_link[1] = p->rtavl_link[1];
s->rtavl_rtag = RTAVL_CHILD;
s->rtavl_balance = p->rtavl_balance;
@
@end exercise

@exercise
Rewrite @<Case 4 in RTAVL deletion@> to replace the deleted node's
|rtavl_data| by its successor, then delete the successor, instead of
shuffling pointers.  (Refer back to @value{modifydata} for an
explanation of why this approach cannot be used in @libavl{}.)

@answer
@cat rtavl Deletion, with data modification
@c tested 2001/11/10
@<Case 4 in RTAVL deletion, alternate version@> =
struct rtavl_node *s;

da[k] = 0;
pa[k++] = p;
for (;;) @
  {@-
    da[k] = 1;
    pa[k++] = r;
    s = r->rtavl_link[1];
    if (s->rtavl_rtag == RTAVL_THREAD)
      break;
    r = s;
  }@+

if (s->rtavl_link[0] != NULL) @
  {@-
    struct rtavl_node *t = s->rtavl_link[0];
    while (t->rtavl_rtag == RTAVL_CHILD)
      t = t->rtavl_link[1];
    t->rtavl_link[1] = p;
  }@+

p->rtavl_data = s->rtavl_data;
if (s->rtavl_link[0] != NULL)
  r->rtavl_link[1] = s->rtavl_link[0];
else @
  {@-
    r->rtavl_rtag = RTAVL_THREAD;
    r->rtavl_link[1] = p;
  }@+

p = s;
@
@end exercise

@node Copying an RTAVL Tree, Testing RTAVL Trees, Deleting from an RTAVL Tree, Right-Threaded AVL Trees
@section Copying

We can reuse most of the RTBST copying functionality for copying RTAVL
trees, but we must modify the node copy function to copy the balance
factor into the new node as well.

@cat rtavl Copying
@<RTAVL copy function@> =
@<RTAVL node copy function@>
@<RTBST copy error helper function; rtbst => rtavl@>
@<RTBST main copy function; rtbst => rtavl@>
@

@cat rtavl Copying a node
@<RTAVL node copy function@> =
@iftangle
/* Creates a new node as a child of |dst| on side |dir|.
   Copies data from |src| into the new node, applying |copy()|, if non-null.
   Returns nonzero only if fully successful.
   Regardless of success, integrity of the tree structure is assured,
   though failure may leave a null pointer in a |rtavl_data| member. */
@end iftangle
static int @
copy_node (struct rtavl_table *tree, @
	   struct rtavl_node *dst, int dir,
	   const struct rtavl_node *src, rtavl_copy_func *copy) @
{
  struct rtavl_node *new = tree->rtavl_alloc->libavl_malloc (tree->rtavl_alloc,
                                                             sizeof *new);
  if (new == NULL)
    return 0;

  new->rtavl_link[0] = NULL;
  new->rtavl_rtag = RTAVL_THREAD;
  if (dir == 0)
    new->rtavl_link[1] = dst;
  else @
    {@-
      new->rtavl_link[1] = dst->rtavl_link[1];
      dst->rtavl_rtag = RTAVL_CHILD;
    }@+
  dst->rtavl_link[dir] = new;
  
  new->rtavl_balance = src->rtavl_balance;

  if (copy == NULL)
    new->rtavl_data = src->rtavl_data;
  else @
    {@-
      new->rtavl_data = copy (src->rtavl_data, tree->rtavl_param);
      if (new->rtavl_data == NULL)
	return 0;
    }@+

  return 1;
}

@

@node Testing RTAVL Trees,  , Copying an RTAVL Tree, Right-Threaded AVL Trees
@section Testing

@(rtavl-test.c@> =
@<Program License@>
#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include "rtavl.h"
#include "test.h"

@<RTBST print function; rtbst => rtavl@>
@<BST traverser check function; bst => rtavl@>
@<Compare two RTAVL trees for structure and content@>
@<Recursively verify RTAVL tree structure@>
@<AVL tree verify function; avl => rtavl@>
@<BST test function; bst => rtavl@>
@<BST overflow test function; bst => rtavl@>
@

@<Compare two RTAVL trees for structure and content@> =
@iftangle
/* Compares binary trees rooted at |a| and |b|, @
   making sure that they are identical. */
@end iftangle
static int @
compare_trees (struct rtavl_node *a, struct rtavl_node *b) @
{
  int okay;

  if (a == NULL || b == NULL) @
    {@-
      if (a != NULL || b != NULL) @
	{@-
	  printf (" a=%d b=%d\n",
		  a ? *(int *) a->rtavl_data : -1, @
		  b ? *(int *) b->rtavl_data : -1);
	  assert (0);
	}@+
      return 1;
    }@+
  assert (a != b);

  if (*(int *) a->rtavl_data != *(int *) b->rtavl_data
      || a->rtavl_rtag != b->rtavl_rtag 
      || a->rtavl_balance != b->rtavl_balance) @
    {@-
      printf (" Copied nodes differ: a=%d (bal=%d) b=%d (bal=%d) a:",
	      *(int *) a->rtavl_data, a->rtavl_balance,
	      *(int *) b->rtavl_data, b->rtavl_balance);

      if (a->rtavl_rtag == RTAVL_CHILD) @
	printf ("r");

      printf (" b:");
      if (b->rtavl_rtag == RTAVL_CHILD) @
	printf ("r");

      printf ("\n");
      return 0;
    }@+

  if (a->rtavl_rtag == RTAVL_THREAD)
    assert ((a->rtavl_link[1] == NULL) != (a->rtavl_link[1] != b->rtavl_link[1]));

  okay = compare_trees (a->rtavl_link[0], b->rtavl_link[0]);
  if (a->rtavl_rtag == RTAVL_CHILD)
    okay &= compare_trees (a->rtavl_link[1], b->rtavl_link[1]);
  return okay;
}

@

@<Recursively verify RTAVL tree structure@> =
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
recurse_verify_tree (struct rtavl_node *node, int *okay, size_t *count, 
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
  d = *(int *) node->rtavl_data;

  @<Verify binary search tree ordering@>

  subcount[0] = subcount[1] = 0;
  subheight[0] = subheight[1] = 0;
  recurse_verify_tree (node->rtavl_link[0], okay, &subcount[0], 
                       min, d -  1, &subheight[0]);
  if (node->rtavl_rtag == RTAVL_CHILD)
    recurse_verify_tree (node->rtavl_link[1], okay, &subcount[1], 
                         d + 1, max, &subheight[1]);
  *count = 1 + subcount[0] + subcount[1];
  *height = 1 + (subheight[0] > subheight[1] ? subheight[0] : subheight[1]);

  @<Verify AVL node balance factor; avl => rtavl@>
}

@
