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

@deftypedef rtrb_comparison_func
@deftypedef rtrb_item_func
@deftypedef rtrb_copy_func

@node Right-Threaded Red-Black Trees, BSTs with Parent Pointers, Right-Threaded AVL Trees, Top
@chapter Right-Threaded Red-Black Trees

This chapter is this book's final demonstration of right-threaded trees,
carried out by using them in a red-black tree implementation of tables.
The chapter, and the code, follow the pattern that should now be
familiar, using |rtrb_| as the naming prefix and often referring to
right-threaded right-black trees as ``RTRB trees''.

@(rtrb.h@> =
@<Library License@>
#ifndef RTRB_H
#define RTRB_H 1

#include <stddef.h>

@<Table types; tbl => rtrb@>
@<RB maximum height; rb => rtrb@>
@<TBST table structure; tbst => rtrb@>
@<RTRB node structure@>
@<TBST traverser structure; tbst => rtrb@>
@<Table function prototypes; tbl => rtrb@>

#endif /* rtrb.h */
@ 

@(rtrb.c@> =
@<Library License@>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "rtrb.h"

@<RTRB functions@>
@

@menu
* RTRB Data Types::             
* RTRB Operations::             
* Inserting into an RTRB Tree::  
* Deleting from an RTRB Tree::  
* Testing RTRB Trees::          
@end menu

@node RTRB Data Types, RTRB Operations, Right-Threaded Red-Black Trees, Right-Threaded Red-Black Trees
@section Data Types

Like any right-threaded tree node, an RTRB node has a right tag, and like
any red-black tree node, an RTRB node has a color, either red or black.
The combination is straightforward, as shown here.

@<RTRB node structure@> =
/* Color of a red-black node. */
enum rtrb_color @
  {@-
    RTRB_BLACK,                     /* Black. */
    RTRB_RED                        /* Red. */
  };@+

/* Characterizes a link as a child pointer or a thread. */
enum rtrb_tag @
  {@-
    RTRB_CHILD,                     /* Child pointer. */
    RTRB_THREAD                     /* Thread. */
  };@+

/* A threaded binary search tree node. */
struct rtrb_node @
  {@-
    struct rtrb_node *rtrb_link[2]; /* Subtrees. */
    void *rtrb_data;                /* Pointer to data. */
    unsigned char rtrb_color;       /* Color. */
    unsigned char rtrb_rtag;        /* Tag field. */
  };@+

@

@node RTRB Operations, Inserting into an RTRB Tree, RTRB Data Types, Right-Threaded Red-Black Trees
@section Operations

Most of the operations on RTRB trees can be borrowed from the
corresponding operations on TBSTs, RTBSTs, or RTAVL trees, as shown
below.

@<RTRB functions@> =
@<TBST creation function; tbst => rtrb@>
@<RTBST search function; rtbst => rtrb@>
@<RTRB item insertion function@>
@<Table insertion convenience functions; tbl => rtrb@>
@<RTRB item deletion function@>
@<RTBST traversal functions; rtbst => rtrb@>
@<RTAVL copy function; rtavl => rtrb; rtavl_balance => rtrb_color@>
@<RTBST destruction function; rtbst => rtrb@>
@<Default memory allocation functions; tbl => rtrb@>
@<Table assertion functions; tbl => rtrb@>
@

@node Inserting into an RTRB Tree, Deleting from an RTRB Tree, RTRB Operations, Right-Threaded Red-Black Trees
@section Insertion

Insertion is, as usual, one of the operations that must be newly
implemented for our new type of tree.  There is nothing surprising in
the function's outline:

@cat rtrb Insertion
@<RTRB item insertion function@> =
@iftangle
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree, 
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
@end iftangle
void **@
rtrb_probe (struct rtrb_table *tree, void *item) @
{
  struct rtrb_node *pa[RTRB_MAX_HEIGHT]; /* Nodes on stack. */
  unsigned char da[RTRB_MAX_HEIGHT];   /* Directions moved from stack nodes. */
  int k;                               /* Stack height. */

  struct rtrb_node *p; /* Current node in search. */
  struct rtrb_node *n; /* New node. */
  int dir;             /* Side of |p| on which |p| is located. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Search RTRB tree for insertion point@>
  @<Step 2: Insert RTRB node@>
  @<Step 3: Rebalance after RTRB insertion@>

  return &n->rtrb_data;
}

@

@menu
* Steps 1 and 2 in RTRB Insertion::  
* Step 3 in RTRB Insertion::    
@end menu

@node Steps 1 and 2 in RTRB Insertion, Step 3 in RTRB Insertion, Inserting into an RTRB Tree, Inserting into an RTRB Tree
@subsection Steps 1 and 2: Search and Insert

The process of search and insertion proceeds as usual.  Stack |pa[]|,
with |pa[k - 1]| at top of stack, records the parents of the node |p|
currently under consideration, with corresponding stack |da[]|
indicating the direction moved.  We use the standard code for insertion
into an RTBST.  When the loop exits, |p| is the node under which a new
node should be inserted on side |dir|.

@<Step 1: Search RTRB tree for insertion point@> =
da[0] = 0;
pa[0] = (struct rtrb_node *) &tree->rtrb_root;
k = 1;
if (tree->rtrb_root != NULL)
  for (p = tree->rtrb_root; ; p = p->rtrb_link[dir]) @
    {@-
      int cmp = tree->rtrb_compare (item, p->rtrb_data, tree->rtrb_param);
      if (cmp == 0)
        return &p->rtrb_data;

      pa[k] = p;
      da[k++] = dir = cmp > 0;

      if (dir == 0) @
        {@-
          if (p->rtrb_link[0] == NULL)
            break;
        }@+ @
      else /* |dir == 1| */ @
        {@-
          if (p->rtrb_rtag == RTRB_THREAD)
            break;
        }@+
    }@+
else @
  {@-
    p = (struct rtrb_node *) &tree->rtrb_root;
    dir = 0;
  }@+

@

@<Step 2: Insert RTRB node@> =
n = tree->rtrb_alloc->libavl_malloc (tree->rtrb_alloc, sizeof *n);
if (n == NULL)
  return NULL;

tree->rtrb_count++;
n->rtrb_data = item;
n->rtrb_link[0] = NULL;
if (dir == 0) @
  {@-
    if (tree->rtrb_root != NULL)
      n->rtrb_link[1] = p;
    else @
      n->rtrb_link[1] = NULL;
  }@+ @
else /* |dir == 1| */ @
  {@-
    p->rtrb_rtag = RTRB_CHILD;
    n->rtrb_link[1] = p->rtrb_link[1];
  }@+
n->rtrb_rtag = RTRB_THREAD;
n->rtrb_color = RTRB_RED;
p->rtrb_link[dir] = n;

@

@node Step 3 in RTRB Insertion,  , Steps 1 and 2 in RTRB Insertion, Inserting into an RTRB Tree
@subsection Step 3: Rebalance

The rebalancing outline follows @<Step 3: Rebalance after RB
insertion@>.

@<Step 3: Rebalance after RTRB insertion@> =
while (k >= 3 && pa[k - 1]->rtrb_color == RTRB_RED) @
  {@-
    if (da[k - 2] == 0)
      { @
        @<Left-side rebalancing after RTRB insertion@> @
      }
    else @
      { @
        @<Right-side rebalancing after RTRB insertion@> @
      }
  }@+
tree->rtrb_root->rtrb_color = RTRB_BLACK;
@

The choice of case for insertion on the left side is made in the same
way as in @<Left-side rebalancing after RB insertion@>, except that of
course right-side tests for non-empty subtrees are made using
|rtrb_rtag| instead of |rtrb_link[1]|, and similarly for insertion on
the right side.  In short, we take |q| (which is not a real variable) as
the new node |n| if this is the first time through the loop, or a node
whose color has just been changed to red otherwise.  We know that both
|q| and its parent |pa[k - 1]| are red, violating rule 1 for red-black
trees, and that |q|'s grandparent |pa[k - 2]| is black.  Here is the
code to distinguish cases:

@<Left-side rebalancing after RTRB insertion@> =
struct rtrb_node *y = pa[k - 2]->rtrb_link[1];
if (pa[k - 2]->rtrb_rtag == RTRB_CHILD && y->rtrb_color == RTRB_RED)
  { @
    @<Case 1 in left-side RTRB insertion rebalancing@> @
  }
else @
  {@-
    struct rtrb_node *x;

    if (da[k - 1] == 0)
      y = pa[k - 1];
    else @
      { @
        @<Case 3 in left-side RTRB insertion rebalancing@> @
      }

    @<Case 2 in left-side RTRB insertion rebalancing@>
    break;
  }@+
@

@<Right-side rebalancing after RTRB insertion@> =
struct rtrb_node *y = pa[k - 2]->rtrb_link[0];
if (pa[k - 2]->rtrb_link[0] != NULL && y->rtrb_color == RTRB_RED)
  { @
    @<Case 1 in right-side RTRB insertion rebalancing@> @
  }
else @
  {@-
    struct rtrb_node *x;

    if (da[k - 1] == 1)
      y = pa[k - 1];
    else @
      { @
        @<Case 3 in right-side RTRB insertion rebalancing@> @
      }

    @<Case 2 in right-side RTRB insertion rebalancing@>
    break;
  }@+
@

@subsubheading Case 1: |q|'s uncle is red

If node |q|'s uncle is red, then no links need be changed.  Instead,
we will just recolor nodes.  We reuse the code for RB insertion
(@pageref{rbinscase1}):

@<Case 1 in left-side RTRB insertion rebalancing@> =
@<Case 1 in left-side RB insertion rebalancing; rb => rtrb@>
@

@<Case 1 in right-side RTRB insertion rebalancing@> =
@<Case 1 in right-side RB insertion rebalancing; rb => rtrb@>
@

@subsubheading Case 2: |q| is on same side of parent as parent is of grandparent

If |q| is a left child of its parent |y| and |y| is a left child of its
own parent |x|, or if both |q| and |y| are right children, then we
rotate at |x| away from |y|.  This is the same that we would do in an
unthreaded RB tree (@pageref{rbinscase2}).

However, as usual, we must make sure that threads are fixed up properly
in the rotation.  In particular, for case 2 in left-side rebalancing, we
must convert a right thread of |y|, after rotation, into a null left child
pointer of |x|, like this:

@center @image{rtrbins}

@<Case 2 in left-side RTRB insertion rebalancing@> =
@<Case 2 in left-side RB insertion rebalancing; rb => rtrb@>

if (y->rtrb_rtag == RTRB_THREAD) @
  {@-
    y->rtrb_rtag = RTRB_CHILD;
    x->rtrb_link[0] = NULL;
  }@+
@

For the right-side rebalancing case, we must convert a null left child
of |y|, after rotation, into a right thread of |x|:

@center @image{rtrbins2}

@<Case 2 in right-side RTRB insertion rebalancing@> =
@<Case 2 in right-side RB insertion rebalancing; rb => rtrb@>

if (x->rtrb_link[1] == NULL) @
  {@-
    x->rtrb_rtag = RTRB_THREAD;
    x->rtrb_link[1] = y;
  }@+
@

@subsubheading Case 3: |q| is on opposite side of parent as parent is of grandparent

If |q| is a left child and its parent is a right child, or vice versa,
then we have an instance of case 3, and we rotate at |q|'s parent in the
direction from |q| to its parent.  We handle this case as seen before
for unthreaded RB trees (@pageref{rbinscase3}), with the addition of
fix-ups for threads during rotation.

The left-side fix-up and the code to do it look like this:

@center @image{rtrbins3}

@<Case 3 in left-side RTRB insertion rebalancing@> =
@<Case 3 in left-side RB insertion rebalancing; rb => rtrb@>

if (x->rtrb_link[1] == NULL) @
  {@-
    x->rtrb_rtag = RTRB_THREAD;
    x->rtrb_link[1] = y;
  }@+
@

Here's the right-side fix-up and code:

@center @image{rtrbins4}

@<Case 3 in right-side RTRB insertion rebalancing@> =
@<Case 3 in right-side RB insertion rebalancing; rb => rtrb@>

if (y->rtrb_rtag == RTRB_THREAD) @
  {@-
    y->rtrb_rtag = RTRB_CHILD;
    x->rtrb_link[0] = NULL;
  }@+
@

@node Deleting from an RTRB Tree, Testing RTRB Trees, Inserting into an RTRB Tree, Right-Threaded Red-Black Trees
@section Deletion

The process of deletion from an RTRB tree is the same that we've seen
many times now.  Code for the first step is borrowed from RTAVL
deletion:

@cat rtrb Deletion
@<RTRB item deletion function@> =
@iftangle
/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
@end iftangle
void *@
rtrb_delete (struct rtrb_table *tree, const void *item) @
{
  struct rtrb_node *pa[RTRB_MAX_HEIGHT]; /* Nodes on stack. */
  unsigned char da[RTRB_MAX_HEIGHT];   /* Directions moved from stack nodes. */
  int k;                               /* Stack height. */

  struct rtrb_node *p;

  assert (tree != NULL && item != NULL);

  @<Step 1: Search RTAVL tree for item to delete; rtavl => rtrb@>
  @<Step 2: Delete RTRB node@>
  @<Step 3: Rebalance after RTRB deletion@>
  @<Step 4: Finish up after RTRB deletion@>
}

@

@menu
* Deleting an RTRB Node Step 2 - Delete::  
* Deleting an RTRB Node Step 3 - Rebalance::  
* Deleting an RTRB Node Step 4 - Finish Up::  
@end menu

@node Deleting an RTRB Node Step 2 - Delete, Deleting an RTRB Node Step 3 - Rebalance, Deleting from an RTRB Tree, Deleting from an RTRB Tree
@subsection Step 2: Delete

We use left-looking deletion.  At this point, |p| is the node to delete.
After the deletion, |x| is the node that replaced |p|, or a null pointer
if the node was deleted without replacement.  The cases are
distinguished in the usual way:

@<Step 2: Delete RTRB node@> =
if (p->rtrb_link[0] == NULL) @
  {@-
    if (p->rtrb_rtag == RTRB_CHILD)
      { @
        @<Case 1 in RTRB deletion@> @
      }
    else @
      { @
        @<Case 2 in RTRB deletion@> @
      }
  }@+ @
else @
  {@-
    enum rtrb_color t;
    struct rtrb_node *r = p->rtrb_link[0];

    if (r->rtrb_rtag == RTRB_THREAD)
      { @
        @<Case 3 in RTRB deletion@> @
      }
    else @
      { @
        @<Case 4 in RTRB deletion@> @
      }
  }@+

@

@subsubheading Case 1: |p| has a right child but no left child

If |p|, the node to be deleted, has a right child but no left child,
then we replace it by its right child.  This is the same as @<Case 1 in
RTAVL deletion@>.

@<Case 1 in RTRB deletion@> =
@<Case 1 in RTAVL deletion; rtavl => rtrb@>
@

@subsubheading Case 2: |p| has a right thread and no left child

Similarly, case 2 is the same as @<Case 2 in RTAVL deletion@>, with the
addition of an assignment to |x|.

@<Case 2 in RTRB deletion@> =
@<Case 2 in RTAVL deletion; rtavl => rtrb@>
@

@subsubheading Case 3: |p|'s left child has a right thread

If |p| has a left child |r|, and |r| has a right thread, then we replace
|p| by |r| and transfer |p|'s former right link to |r|.  Node |r| also
receives |p|'s balance factor.

@<Case 3 in RTRB deletion@> =
r->rtrb_link[1] = p->rtrb_link[1];
r->rtrb_rtag = p->rtrb_rtag;
t = r->rtrb_color;
r->rtrb_color = p->rtrb_color;
p->rtrb_color = t;
pa[k - 1]->rtrb_link[da[k - 1]] = r;
da[k] = 0;
pa[k++] = r;
@

@subsubheading Case 4: |p|'s left child has a right child

The fourth case, where |p| has a left child that itself has a right
child, uses the same algorithm as @<Case 4 in RTAVL deletion@>, except
that instead of setting the balance factor of |s|, we swap the colors
of |t| and |s| as in @<Case 3 in RB deletion@>.

@<Case 4 in RTRB deletion@> =
struct rtrb_node *s;
int j = k++;

for (;;) @
  {@-
    da[k] = 1;
    pa[k++] = r;
    s = r->rtrb_link[1];
    if (s->rtrb_rtag == RTRB_THREAD)
      break;

    r = s;
  }@+

da[j] = 0;
pa[j] = pa[j - 1]->rtrb_link[da[j - 1]] = s;

if (s->rtrb_link[0] != NULL)
  r->rtrb_link[1] = s->rtrb_link[0];
else @
  {@-
    r->rtrb_rtag = RTRB_THREAD;
    r->rtrb_link[1] = s;
  }@+

s->rtrb_link[0] = p->rtrb_link[0];
s->rtrb_link[1] = p->rtrb_link[1];
s->rtrb_rtag = p->rtrb_rtag;

t = s->rtrb_color;
s->rtrb_color = p->rtrb_color;
p->rtrb_color = t;
@

@node Deleting an RTRB Node Step 3 - Rebalance, Deleting an RTRB Node Step 4 - Finish Up, Deleting an RTRB Node Step 2 - Delete, Deleting from an RTRB Tree
@subsection Step 3: Rebalance

The rebalancing step's outline is much like that for deletion in a
symmetrically threaded tree, except that we must check for a null
child pointer on the left side of |x| versus a thread on the right
side:

@<Step 3: Rebalance after RTRB deletion@> =
if (p->rtrb_color == RTRB_BLACK) @
  {@-
    for (; k > 1; k--) @
      {@-
        struct rtrb_node *x;
        if (da[k - 1] == 0 || pa[k - 1]->rtrb_rtag == RTRB_CHILD)
          x = pa[k - 1]->rtrb_link[da[k - 1]];
        else @
          x = NULL;
        if (x != NULL && x->rtrb_color == RTRB_RED) @
          {@-
            x->rtrb_color = RTRB_BLACK;
            break;
          }@+
	  
        if (da[k - 1] == 0)
          { @
            @<Left-side rebalancing after RTRB deletion@> @
          }
        else @
          { @
            @<Right-side rebalancing after RTRB deletion@> @
          }
      }@+

    if (tree->rtrb_root != NULL) @
      tree->rtrb_root->rtrb_color = RTRB_BLACK;
  }@+

@

As for RTRB insertion, rebalancing on either side of the root is not
symmetric because the tree structure itself is not symmetric, but
again the rebalancing steps are very similar.  The outlines of the
left-side and right-side rebalancing code are below.  The code for
ensuring that |w| is black and for case 1 on each side are the same as
the corresponding unthreaded RB code, because none of that code needs
to check for empty trees:

@<Left-side rebalancing after RTRB deletion@> =
struct rtrb_node *w = pa[k - 1]->rtrb_link[1];

if (w->rtrb_color == RTRB_RED) 
  { @
    @<Ensure |w| is black in left-side RB deletion rebalancing; rb => rtrb@> @
  }

if ((w->rtrb_link[0] == NULL @
     || w->rtrb_link[0]->rtrb_color == RTRB_BLACK)
    && (w->rtrb_rtag == RTRB_THREAD @
        || w->rtrb_link[1]->rtrb_color == RTRB_BLACK))
  { @
    @<Case 1 in left-side RB deletion rebalancing; rb => rtrb@> @
  }
else @
  {@-
    if (w->rtrb_rtag == RTRB_THREAD @
        || w->rtrb_link[1]->rtrb_color == RTRB_BLACK)
      { @
        @<Transform left-side RTRB deletion rebalancing case 3 into case 2@> @
      }

    @<Case 2 in left-side RTRB deletion rebalancing@>
    break;
  }@+
@

@<Right-side rebalancing after RTRB deletion@> =
struct rtrb_node *w = pa[k - 1]->rtrb_link[0];

if (w->rtrb_color == RTRB_RED) 
  { @
    @<Ensure |w| is black in right-side RB deletion rebalancing; rb => rtrb@> @
  }

if ((w->rtrb_link[0] == NULL @
     || w->rtrb_link[0]->rtrb_color == RTRB_BLACK)
    && (w->rtrb_rtag == RTRB_THREAD @
        || w->rtrb_link[1]->rtrb_color == RTRB_BLACK))
  { @
    @<Case 1 in right-side RB deletion rebalancing; rb => rtrb@> @
  }
else @
  {@-
    if (w->rtrb_link[0] == NULL @
        || w->rtrb_link[0]->rtrb_color == RTRB_BLACK)
      { @
        @<Transform right-side RTRB deletion rebalancing case 3 into case 2@> @
      }

    @<Case 2 in right-side RTRB deletion rebalancing@>
    break;
  }@+
@

@subsubheading Case 2: |w|'s child opposite the deletion is red

If the deletion was on the left side of |w| and |w|'s right child is
red, we rotate left at |pa[k - 1]| and perform some recolorings, as we
did for unthreaded RB trees (@pageref{rbdelcase2}).  There is a
special case when |w| has no left child.  This must be transformed
into a thread from leading to |w| following the rotation:

@center @image{rtrbdel1}

@<Case 2 in left-side RTRB deletion rebalancing@> =
@<Case 2 in left-side RB deletion rebalancing; rb => rtrb@>

if (w->rtrb_link[0]->rtrb_link[1] == NULL) @
  {@-
    w->rtrb_link[0]->rtrb_rtag = RTRB_THREAD;
    w->rtrb_link[0]->rtrb_link[1] = w;
  }@+
@

Alternately, if the deletion was on the right side of |w| and |w|'s
left child is right, we rotate right at |pa[k - 1]| and recolor.
There is an analogous special case:

@center @image{rtrbdel2}

@<Case 2 in right-side RTRB deletion rebalancing@> =
@<Case 2 in right-side RB deletion rebalancing; rb => rtrb@>

if (w->rtrb_rtag == RTRB_THREAD) @
  {@-
    w->rtrb_rtag = RTRB_CHILD;
    pa[k - 1]->rtrb_link[0] = NULL;
  }@+
@

@subsubheading Case 3: |w|'s child on the side of the deletion is red

If the deletion was on the left side of |w| and |w|'s left child is
red, then we rotate right at |w| and recolor, as in case 3 for
unthreaded RB trees (@pageref{rbdelcase3}).  There is a special case
when |w|'s left child has a right thread.  This must be transformed
into a null left child of |w|'s right child following the rotation:

@center @image{rtrbdel3}

@<Transform left-side RTRB deletion rebalancing case 3 into case 2@> =
@<Transform left-side RB deletion rebalancing case 3 into case 2; rb => rtrb@>

if (w->rtrb_rtag == RTRB_THREAD) @
  {@-
    w->rtrb_rtag = RTRB_CHILD;
    w->rtrb_link[1]->rtrb_link[0] = NULL;
  }@+
@

Alternately, if the deletion was on the right side of |w| and |w|'s
right child is red, we rotate left at |w| and recolor.  There is an
analogous special case:

@center @image{rtrbdel4}

@<Transform right-side RTRB deletion rebalancing case 3 into case 2@> =
@<Transform right-side RB deletion rebalancing case 3 into case 2; rb => rtrb@>

if (w->rtrb_link[0]->rtrb_link[1] == NULL) @
  {@-
    w->rtrb_link[0]->rtrb_rtag = RTRB_THREAD;
    w->rtrb_link[0]->rtrb_link[1] = w;
  }@+
@

@node Deleting an RTRB Node Step 4 - Finish Up,  , Deleting an RTRB Node Step 3 - Rebalance, Deleting from an RTRB Tree
@subsection Step 4: Finish Up

@<Step 4: Finish up after RTRB deletion@> =
tree->rtrb_alloc->libavl_free (tree->rtrb_alloc, p);
return (void *) item;
@

@node Testing RTRB Trees,  , Deleting from an RTRB Tree, Right-Threaded Red-Black Trees
@section Testing

@(rtrb-test.c@> =
@<Program License@>
#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include "rtrb.h"
#include "test.h"

@<RTBST print function; rtbst => rtrb@>
@<BST traverser check function; bst => rtrb@>
@<Compare two RTRB trees for structure and content@>
@<Recursively verify RTRB tree structure@>
@<RB tree verify function; rb => rtrb@>
@<BST test function; bst => rtrb@>
@<BST overflow test function; bst => rtrb@>
@

@<Compare two RTRB trees for structure and content@> =
@iftangle
/* Compares binary trees rooted at |a| and |b|, @
   making sure that they are identical. */
@end iftangle
static int @
compare_trees (struct rtrb_node *a, struct rtrb_node *b) @
{
  int okay;

  if (a == NULL || b == NULL) @
    {@-
      if (a != NULL || b != NULL) @
	{@-
	  printf (" a=%d b=%d\n",
		  a ? *(int *) a->rtrb_data : -1, @
		  b ? *(int *) b->rtrb_data : -1);
	  assert (0);
	}@+
      return 1;
    }@+
  assert (a != b);

  if (*(int *) a->rtrb_data != *(int *) b->rtrb_data
      || a->rtrb_rtag != b->rtrb_rtag 
      || a->rtrb_color != b->rtrb_color) @
    {@-
      printf (" Copied nodes differ: a=%d%c b=%d%c a:",
	      *(int *) a->rtrb_data, a->rtrb_color == RTRB_RED ? 'r' : 'b',
	      *(int *) b->rtrb_data, b->rtrb_color == RTRB_RED ? 'r' : 'b');

      if (a->rtrb_rtag == RTRB_CHILD) @
	printf ("r");

      printf (" b:");
      if (b->rtrb_rtag == RTRB_CHILD) @
	printf ("r");

      printf ("\n");
      return 0;
    }@+

  if (a->rtrb_rtag == RTRB_THREAD)
    assert ((a->rtrb_link[1] == NULL) != (a->rtrb_link[1] != b->rtrb_link[1]));

  okay = compare_trees (a->rtrb_link[0], b->rtrb_link[0]);
  if (a->rtrb_rtag == RTRB_CHILD)
    okay &= compare_trees (a->rtrb_link[1], b->rtrb_link[1]);
  return okay;
}

@

@<Recursively verify RTRB tree structure@> =
@iftangle
/* Examines the binary tree rooted at |node|.  
   Zeroes |*okay| if an error occurs.  @
   Otherwise, does not modify |*okay|.
   Sets |*count| to the number of nodes in that tree, @
   including |node| itself if |node != NULL|.
   Sets |*bh| to the tree's black-height.
   All the nodes in the tree are verified to be at least |min| @
   but no greater than |max|. */
@end iftangle
static void @
recurse_verify_tree (struct rtrb_node *node, int *okay, size_t *count, 
                     int min, int max, int *bh) @
{
  int d;                /* Value of this node's data. */
  size_t subcount[2];   /* Number of nodes in subtrees. */
  int subbh[2];         /* Black-heights of subtrees. */

  if (node == NULL) @
    {@-
      *count = 0;
      *bh = 0;
      return;
    }@+
  d = *(int *) node->rtrb_data;

  @<Verify binary search tree ordering@>

  subcount[0] = subcount[1] = 0;
  subbh[0] = subbh[1] = 0;
  recurse_verify_tree (node->rtrb_link[0], okay, &subcount[0], 
                       min, d - 1, &subbh[0]);
  if (node->rtrb_rtag == RTRB_CHILD)
    recurse_verify_tree (node->rtrb_link[1], okay, &subcount[1], 
                         d + 1, max, &subbh[1]);
  *count = 1 + subcount[0] + subcount[1];
  *bh = (node->rtrb_color == RTRB_BLACK) + subbh[0];

  @<Verify RB node color; rb => rtrb@>
  @<Verify RTRB node rule 1 compliance@>
  @<Verify RB node rule 2 compliance; rb => rtrb@>
}

@

@<Verify RTRB node rule 1 compliance@> =
/* Verify compliance with rule 1. */
if (node->rtrb_color == RTRB_RED) @
  {@-
    if (node->rtrb_link[0] != NULL @
        && node->rtrb_link[0]->rtrb_color == RTRB_RED) @
      {@-
        printf (" Red node %d has red left child %d\n",
                d, *(int *) node->rtrb_link[0]->rtrb_data);
        *okay = 0;
      }@+

    if (node->rtrb_rtag == RTRB_CHILD @
        && node->rtrb_link[1]->rtrb_color == RTRB_RED) @
      {@-
        printf (" Red node %d has red right child %d\n",
                d, *(int *) node->rtrb_link[1]->rtrb_data);
        *okay = 0;
      }@+
  }@+

@
