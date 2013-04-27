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

@deftypedef prb_comparison_func
@deftypedef prb_item_func
@deftypedef prb_copy_func

@node Red-Black Trees with Parent Pointers, References, AVL Trees with Parent Pointers, Top
@chapter Red-Black Trees with Parent Pointers

As our twelfth and final example of a table data structure, this
chapter will implement a table as a red-black tree with parent
pointers, or ``PRB'' tree for short.  We use |prb_| as the prefix for
identifiers.  Here's the outline:

@(prb.h@> =
@<Library License@>
#ifndef PRB_H
#define PRB_H 1

#include <stddef.h>

@<Table types; tbl => prb@>
@<RB maximum height; rb => prb@>
@<TBST table structure; tbst => prb@>
@<PRB node structure@>
@<TBST traverser structure; tbst => prb@>
@<Table function prototypes; tbl => prb@>

#endif /* prb.h */
@ 

@(prb.c@> =
@<Library License@>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "prb.h"

@<PRB functions@>
@

@menu
* PRB Data Types::              
* PRB Operations::              
* Inserting into a PRB Tree::   
* Deleting from a PRB Tree::    
* Testing PRB Trees::           
@end menu

@node PRB Data Types, PRB Operations, Red-Black Trees with Parent Pointers, Red-Black Trees with Parent Pointers
@section Data Types

The PRB node structure adds a color and a parent pointer to the basic
binary tree data structure.  The other PRB data structures are the
same as the ones used for TBSTs.

@<PRB node structure@> =
/* Color of a red-black node. */
enum prb_color @
  {@-
    PRB_BLACK,   /* Black. */
    PRB_RED      /* Red. */
  };@+

/* A red-black tree with parent pointers node. */
struct prb_node @
  {@-
    struct prb_node *prb_link[2];  /* Subtrees. */
    struct prb_node *prb_parent;   /* Parent. */
    void *prb_data;                /* Pointer to data. */
    unsigned char prb_color;       /* Color. */
  };@+

@

@references
@bibref{Cormen 1990}, section 14.1.

@node PRB Operations, Inserting into a PRB Tree, PRB Data Types, Red-Black Trees with Parent Pointers
@section Operations

Most of the PRB operations use the same implementations as did PAVL
trees in the last chapter.  The PAVL copy function is modified to copy
colors instead of balance factors.  The item insertion and deletion
functions must be newly written, of course.

@<PRB functions@> =
@<TBST creation function; tbst => prb@>
@<BST search function; bst => prb@>
@<PRB item insertion function@>
@<Table insertion convenience functions; tbl => prb@>
@<PRB item deletion function@>
@<PAVL traversal functions; pavl => prb@>
@<PAVL copy function; pavl => prb; pavl_balance => prb_color@>
@<BST destruction function; bst => prb@>
@<Default memory allocation functions; tbl => prb@>
@<Table assertion functions; tbl => prb@>
@

@node Inserting into a PRB Tree, Deleting from a PRB Tree, PRB Operations, Red-Black Trees with Parent Pointers
@section Insertion

Inserting into a red-black tree is a problem whose form of solution
should by now be familiar to the reader.  We must now update parent
pointers, of course, but the major difference here is that it is fast
and easy to find the parent of any given node, eliminating any need
for a stack.

Here's the function outline.  The code for finding the insertion point
is taken directly from the PBST code:

@cat prb Insertion
@<PRB item insertion function@> =
@iftangle
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree, 
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
@end iftangle
void **@
prb_probe (struct prb_table *tree, void *item) @
{
  struct prb_node *p; /* Traverses tree looking for insertion point. */
  struct prb_node *q; /* Parent of |p|; node at which we are rebalancing. */
  struct prb_node *n; /* Newly inserted node. */
  int dir;            /* Side of |q| on which |n| is inserted. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Search PBST tree for insertion point; pbst => prb@>
  @<Step 2: Insert PRB node@>
  @<Step 3: Rebalance after PRB insertion@>

  return &n->prb_data;
}

@

@references
@bibref{Cormen 1990}, section 14.3.

@menu
* Step 2 in PRB Insertion::     
* Step 3 in PRB Insertion::     
* PRB Insertion Symmetric Case::  
@end menu

@node Step 2 in PRB Insertion, Step 3 in PRB Insertion, Inserting into a PRB Tree, Inserting into a PRB Tree
@subsection Step 2: Insert

The code to do the insertion is based on that for PBSTs.  We need only
add initialization of the new node's color.

@<Step 2: Insert PRB node@> =
@<Step 2: Insert PBST node; pbst => prb@>
n->prb_color = PRB_RED;

@

@node Step 3 in PRB Insertion, PRB Insertion Symmetric Case, Step 2 in PRB Insertion, Inserting into a PRB Tree
@subsection Step 3: Rebalance

When we rebalanced ordinary RB trees, we used the expressions |pa[k -
1]| and @w{|pa[k - 2]|} to refer to the parent and grandparent,
respectively, of the node at which we were rebalancing, and we called
that node |q|, though that wasn't a variable name (@pxref{Inserting an
RB Node Step 3 - Rebalance}).  Now that we have parent pointers, we use
a real variable |q| to refer to the node where we're rebalancing.

This means that we could refer to its parent and grandparent as
|q->prb_parent| and |q->prb_parent->prb_parent|, respectively, but
there's a small problem with that.  During rebalancing, we will need
to move nodes around and modify parent pointers.  That means that
|q->prb_parent| and |q->prb_parent->prb_parent| will be changing under
us as we work.  This makes writing correct code hard, and reading it
even harder.  It is much easier to use a pair of new variables to hold
|q|'s parent and grandparent.

That's exactly the role that |f| and |g|, respectively, play in the
code below.  If you compare this code to @<Step 3: Rebalance after RB
insertion@>, you'll also notice the way that checking that |f| and |g|
are non-null corresponds to checking that the stack height is at least
3 (see @value{mink3} for an explanation of the reason this is a valid
test).

@<Step 3: Rebalance after PRB insertion@> =
q = n;
for (;;) @
  {@-
    struct prb_node *f; /* Parent of |q|. */
    struct prb_node *g; /* Grandparent of |q|. */

    f = q->prb_parent;
    if (f == NULL || f->prb_color == PRB_BLACK)
      break;

    g = f->prb_parent;
    if (g == NULL)
      break;

    if (g->prb_link[0] == f)
      { @
        @<Left-side rebalancing after PRB insertion@> @
      }
    else @
      { @
        @<Right-side rebalancing after PRB insertion@> @
      } @
  }@+
tree->prb_root->prb_color = PRB_BLACK;
@

After replacing |pa[k - 1]| by |f| and |pa[k - 2]| by |g|, the cases
for PRB rebalancing are distinguished on the same basis as those for
RB rebalancing (see @<Left-side rebalancing after RB insertion@>).
One addition: cases 2 and 3 need to work with |q|'s great-grandparent,
so they stash it into a new variable |h|.

@<Left-side rebalancing after PRB insertion@> =
struct prb_node *y = g->prb_link[1];
if (y != NULL && y->prb_color == PRB_RED) 
  { @
    @<Case 1 in left-side PRB insertion rebalancing@> @
  }
else @
  {@-
    struct prb_node *h; /* Great-grandparent of |q|. */

    h = g->prb_parent;
    if (h == NULL)
      h = (struct prb_node *) &tree->prb_root;

    if (f->prb_link[1] == q)
      { @
        @<Case 3 in left-side PRB insertion rebalancing@> @
      }

    @<Case 2 in left-side PRB insertion rebalancing@>
    break;
  }@+
@

@subsubheading Case 1: |q|'s uncle is red

In this case, as before, we need only rearrange colors
(@pageref{rbinscase1}).  Instead of popping the top two items off the
stack, we directly set up |q|, the next node at which to rebalance, to
be the (former) grandparent of the original |q|.

@center @image{prbins1}

@<Case 1 in left-side PRB insertion rebalancing@> =
f->prb_color = y->prb_color = PRB_BLACK;
g->prb_color = PRB_RED;
q = g;
@

@subsubheading Case 2: |q| is the left child of its parent

If |q| is the left child of its parent, we rotate right at |g|:

@center @image{prbins2}

@noindent
The result satisfies both RB balancing rules.  Refer back to the
discussion of the same case in ordinary RB trees for more details
(@pageref{rbinscase2}).

@<Case 2 in left-side PRB insertion rebalancing@> =
g->prb_color = PRB_RED;
f->prb_color = PRB_BLACK;

g->prb_link[0] = f->prb_link[1];
f->prb_link[1] = g;
h->prb_link[h->prb_link[0] != g] = f;

f->prb_parent = g->prb_parent;
g->prb_parent = f;
if (g->prb_link[0] != NULL)
  g->prb_link[0]->prb_parent = g;
@

@subsubheading Case 3: |q| is the right child of its parent

If |q| is a right child, then we transform it into case 2 by rotating
left at |f|:

@center @image{prbins3}

@noindent
Afterward we relabel |q| as |f| and treat the result as case 2.  There
is no need to properly set |q| itself because case 2 never uses
variable |q|.  For more details, refer back to case 3 in ordinary RB
trees (@pageref{rbinscase3}).

@<Case 3 in left-side PRB insertion rebalancing@> =
f->prb_link[1] = q->prb_link[0];
q->prb_link[0] = f;
g->prb_link[0] = q;
f->prb_parent = q;
if (f->prb_link[1] != NULL)
  f->prb_link[1]->prb_parent = f;

f = q;
@

@node PRB Insertion Symmetric Case,  , Step 3 in PRB Insertion, Inserting into a PRB Tree
@subsection Symmetric Case

@<Right-side rebalancing after PRB insertion@> =
struct prb_node *y = g->prb_link[0];
if (y != NULL && y->prb_color == PRB_RED)
  { @
    @<Case 1 in right-side PRB insertion rebalancing@> @
  }
else @
  {@-
    struct prb_node *h; /* Great-grandparent of |q|. */

    h = g->prb_parent;
    if (h == NULL)
      h = (struct prb_node *) &tree->prb_root;

    if (f->prb_link[0] == q)
      { @
        @<Case 3 in right-side PRB insertion rebalancing@> @
      }

    @<Case 2 in right-side PRB insertion rebalancing@>
    break;
  }@+
@

@<Case 1 in right-side PRB insertion rebalancing@> =
f->prb_color = y->prb_color = PRB_BLACK;
g->prb_color = PRB_RED;
q = g;
@

@<Case 2 in right-side PRB insertion rebalancing@> =
g->prb_color = PRB_RED;
f->prb_color = PRB_BLACK;

g->prb_link[1] = f->prb_link[0];
f->prb_link[0] = g;
h->prb_link[h->prb_link[0] != g] = f;

f->prb_parent = g->prb_parent;
g->prb_parent = f;
if (g->prb_link[1] != NULL)
  g->prb_link[1]->prb_parent = g;
@

@<Case 3 in right-side PRB insertion rebalancing@> =
f->prb_link[0] = q->prb_link[1];
q->prb_link[1] = f;
g->prb_link[1] = q;
f->prb_parent = q;
if (f->prb_link[0] != NULL)
  f->prb_link[0]->prb_parent = f;

f = q;
@

@node Deleting from a PRB Tree, Testing PRB Trees, Inserting into a PRB Tree, Red-Black Trees with Parent Pointers
@section Deletion

The RB item deletion algorithm needs the same kind of changes to
handle parent pointers that the RB item insertion algorithm did.  We
can reuse the code from PBST trees for finding the node to delete.
The rest of the code will be presented in the following sections.

@cat prb Deletion
@<PRB item deletion function@> =
@iftangle
/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
@end iftangle
void *@
prb_delete (struct prb_table *tree, const void *item) @
{
  struct prb_node *p; /* Node to delete. */
  struct prb_node *q; /* Parent of |p|. */
  struct prb_node *f; /* Node at which we are rebalancing. */
  int dir;            /* Side of |q| on which |p| is a child;
                         side of |f| from which node was deleted. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Find PBST node to delete; pbst => prb@>
  @<Step 2: Delete item from PRB tree@>
  @<Step 3: Rebalance tree after PRB deletion@>
  @<Step 4: Finish up after PRB deletion@>
}

@

@references
@bibref{Cormen 1990}, section 14.4.

@menu
* Deleting a PRB Node Step 2 - Delete::  
* Deleting a PRB Node Step 3 - Rebalance::  
* Deleting a PRB Node Step 4 - Finish Up::  
* PRB Deletion Symmetric Case::  
@end menu

@node Deleting a PRB Node Step 2 - Delete, Deleting a PRB Node Step 3 - Rebalance, Deleting from a PRB Tree, Deleting from a PRB Tree
@subsection Step 2: Delete

The goal of this step is to remove |p| from the tree and set up |f| as
the node where rebalancing should start.  Secondarily, we set |dir| as
the side of |f| from which the node was deleted.  Together, |f| and
|dir| fill the role that the top-of-stack entries in |pa[]| and |da[]|
took in ordinary RB deletion.

@<Step 2: Delete item from PRB tree@> =
if (p->prb_link[1] == NULL)
  { @
    @<Case 1 in PRB deletion@> @
  }
else @
  {@-
    enum prb_color t;
    struct prb_node *r = p->prb_link[1];

    if (r->prb_link[0] == NULL)
      { @
        @<Case 2 in PRB deletion@> @
      }
    else @
      { @
        @<Case 3 in PRB deletion@> @
      }
  }@+

@

@subsubheading Case 1: |p| has no right child

If |p| has no right child, then rebalancing should start at its
parent, |q|, and |dir| is already the side that |p| is on.  The rest
is the same as PBST deletion (@pageref{pbstdel1}).

@<Case 1 in PRB deletion@> =
@<Case 1 in PBST deletion; pbst => prb@>

f = q;
@

@subsubheading Case 2: |p|'s right child has no left child

In case 2, we swap the colors of |p| and |r| as for ordinary RB
deletion (@pageref{rbcolorswap}).  We set up |f| and |dir| in the same
way that @<Case 2 in RB deletion@> set up the top of stack.  The rest
is the same as PBST deletion (@pageref{pbstdel2}).

@<Case 2 in PRB deletion@> =
@<Case 2 in PBST deletion; pbst => prb@>

t = p->prb_color;
p->prb_color = r->prb_color;
r->prb_color = t;

f = r;
dir = 1;
@

@subsubheading Case 3: |p|'s right child has a left child

Case 2 swaps the colors of |p| and |s| the same way as in ordinary RB
deletion (@pageref{rbcolorswap}), and sets up |f| and |dir| in the
same way that @<Case 3 in RB deletion@> set up the stack.  The rest is
borrowed from PBST deletion (@pageref{pbstdel3}).

@<Case 3 in PRB deletion@> =
@<Case 3 in PBST deletion; pbst => prb@>

t = p->prb_color;
p->prb_color = s->prb_color;
s->prb_color = t;

f = r;
dir = 0;
@

@node Deleting a PRB Node Step 3 - Rebalance, Deleting a PRB Node Step 4 - Finish Up, Deleting a PRB Node Step 2 - Delete, Deleting from a PRB Tree
@subsection Step 3: Rebalance

The rebalancing code is easily related to the analogous code for
ordinary RB trees in @<Rebalance after RB deletion@>.  As we carefully
set up in step 2, we use |f| as the top of stack node and |dir| as the
side of |f| from which a node was deleted.  These variables |f| and
|dir| were formerly represented by |pa[k - 1]| and |da[k - 1]|,
respectively.  Additionally, variable |g| is used to represent the
parent of |f|.  Formerly the same node was referred to as |pa[k - 2]|.

The code at the end of the loop simply moves |f| and |dir| up one
level in the tree.  It has the same effect as did popping the stack
with |k--|.

@<Step 3: Rebalance tree after PRB deletion@> =
if (p->prb_color == PRB_BLACK) @
  {@-
    for (;;) @
      {@-
        struct prb_node *x; /* Node we want to recolor black if possible. */
        struct prb_node *g; /* Parent of |f|. */
        struct prb_node *t; /* Temporary for use in finding parent. */

        x = f->prb_link[dir];
        if (x != NULL && x->prb_color == PRB_RED)
          {
            x->prb_color = PRB_BLACK;
            break;
          }

        if (f == (struct prb_node *) &tree->prb_root)
          break;

        g = f->prb_parent;
        if (g == NULL)
          g = (struct prb_node *) &tree->prb_root;

        if (dir == 0)
          { @
            @<Left-side rebalancing after PRB deletion@> @
          }
        else @
          { @
            @<Right-side rebalancing after PRB deletion@> @
          }
          
        t = f;
        f = f->prb_parent;
        if (f == NULL)
          f = (struct prb_node *) &tree->prb_root;
        dir = f->prb_link[0] != t;
      }@+
  }@+

@

The code to distinguish rebalancing cases in PRB trees is almost
identical to @<Left-side rebalancing after RB deletion@>.

@<Left-side rebalancing after PRB deletion@> =
struct prb_node *w = f->prb_link[1];

if (w->prb_color == PRB_RED) 
  { @
    @<Ensure |w| is black in left-side PRB deletion rebalancing@> @
  }

if ((w->prb_link[0] == NULL @
     || w->prb_link[0]->prb_color == PRB_BLACK)
    && (w->prb_link[1] == NULL @
        || w->prb_link[1]->prb_color == PRB_BLACK))
  { @
    @<Case 1 in left-side PRB deletion rebalancing@> @
  }
else @
  {@-
    if (w->prb_link[1] == NULL @
        || w->prb_link[1]->prb_color == PRB_BLACK)
      { @
        @<Transform left-side PRB deletion rebalancing case 3 into case 2@> @
      }

    @<Case 2 in left-side PRB deletion rebalancing@>
    break;
  }@+
@

@subsubheading Case Reduction: Ensure |w| is black

The case reduction code is much like that for plain RB trees
(@pageref{rbdcr}), with @w{|pa[k - 1]|} replaced by |f| and |pa[k -
2]| replaced by |g|.  Instead of updating the stack, we change |g|.
Node |f| need not change because it's already what we want it to be.
We also need to update parent pointers for the rotation.

@center @image{prbdr1}

@<Ensure |w| is black in left-side PRB deletion rebalancing@> =
w->prb_color = PRB_BLACK;
f->prb_color = PRB_RED;

f->prb_link[1] = w->prb_link[0];
w->prb_link[0] = f;
g->prb_link[g->prb_link[0] != f] = w;

w->prb_parent = f->prb_parent;
f->prb_parent = w;

g = w;
w = f->prb_link[1];

w->prb_parent = f;
@

@subsubheading Case 1: |w| has no red children

Case 1 is trivial.  No changes from ordinary RB trees are necessary
(@pageref{rbdelcase1}).

@<Case 1 in left-side PRB deletion rebalancing@> =
@<Case 1 in left-side RB deletion rebalancing; rb => prb@>
@

@subsubheading Case 2: |w|'s right child is red

The changes from ordinary RB trees (@pageref{rbdelcase2}) for case 2
follow the same pattern.

@<Case 2 in left-side PRB deletion rebalancing@> =
w->prb_color = f->prb_color;
f->prb_color = PRB_BLACK;
w->prb_link[1]->prb_color = PRB_BLACK;

f->prb_link[1] = w->prb_link[0];
w->prb_link[0] = f;
g->prb_link[g->prb_link[0] != f] = w;

w->prb_parent = f->prb_parent;
f->prb_parent = w;
if (f->prb_link[1] != NULL)
  f->prb_link[1]->prb_parent = f;
@

@subsubheading Case 3: |w|'s left child is red

The code for case 3 in ordinary RB trees (@pageref{rbdelcase3}) needs
slightly more intricate changes than case 1 or case 2, so the diagram
below may help to clarify:

@center @image{prbdr3}

@<Transform left-side PRB deletion rebalancing case 3 into case 2@> =
struct prb_node *y = w->prb_link[0];
y->prb_color = PRB_BLACK;
w->prb_color = PRB_RED;
w->prb_link[0] = y->prb_link[1];
y->prb_link[1] = w;
if (w->prb_link[0] != NULL)
  w->prb_link[0]->prb_parent = w;
w = f->prb_link[1] = y;
w->prb_link[1]->prb_parent = w;
@

@node Deleting a PRB Node Step 4 - Finish Up, PRB Deletion Symmetric Case, Deleting a PRB Node Step 3 - Rebalance, Deleting from a PRB Tree
@subsection Step 4: Finish Up

@<Step 4: Finish up after PRB deletion@> =
tree->prb_alloc->libavl_free (tree->prb_alloc, p);
tree->prb_count--;
return (void *) item;
@

@node PRB Deletion Symmetric Case,  , Deleting a PRB Node Step 4 - Finish Up, Deleting from a PRB Tree
@subsection Symmetric Case

@<Right-side rebalancing after PRB deletion@> =
struct prb_node *w = f->prb_link[0];

if (w->prb_color == PRB_RED)
  { @
    @<Ensure |w| is black in right-side PRB deletion rebalancing@> @
  }

if ((w->prb_link[0] == NULL @
     || w->prb_link[0]->prb_color == PRB_BLACK)
    && (w->prb_link[1] == NULL @
        || w->prb_link[1]->prb_color == PRB_BLACK)) 
  { @
    @<Case 1 in right-side PRB deletion rebalancing@> @
  }
else @
  {@-
    if (w->prb_link[0] == NULL @
        || w->prb_link[0]->prb_color == PRB_BLACK)
      { @
        @<Transform right-side PRB deletion rebalancing case 3 into case 2@> @
      }

    @<Case 2 in right-side PRB deletion rebalancing@>
    break;
  }@+
@

@<Ensure |w| is black in right-side PRB deletion rebalancing@> =
w->prb_color = PRB_BLACK;
f->prb_color = PRB_RED;

f->prb_link[0] = w->prb_link[1];
w->prb_link[1] = f;
g->prb_link[g->prb_link[0] != f] = w;

w->prb_parent = f->prb_parent;
f->prb_parent = w;

g = w;
w = f->prb_link[0];

w->prb_parent = f;
@

@<Case 1 in right-side PRB deletion rebalancing@> =
w->prb_color = PRB_RED;
@

@<Case 2 in right-side PRB deletion rebalancing@> =
w->prb_color = f->prb_color;
f->prb_color = PRB_BLACK;
w->prb_link[0]->prb_color = PRB_BLACK;

f->prb_link[0] = w->prb_link[1];
w->prb_link[1] = f;
g->prb_link[g->prb_link[0] != f] = w;

w->prb_parent = f->prb_parent;
f->prb_parent = w;
if (f->prb_link[0] != NULL)
  f->prb_link[0]->prb_parent = f;
@

@<Transform right-side PRB deletion rebalancing case 3 into case 2@> =
struct prb_node *y = w->prb_link[1];
y->prb_color = PRB_BLACK;
w->prb_color = PRB_RED;
w->prb_link[1] = y->prb_link[0];
y->prb_link[0] = w;
if (w->prb_link[1] != NULL)
  w->prb_link[1]->prb_parent = w;
w = f->prb_link[0] = y;
w->prb_link[0]->prb_parent = w;
@

@node Testing PRB Trees,  , Deleting from a PRB Tree, Red-Black Trees with Parent Pointers
@section Testing

No comment is necessary.

@(prb-test.c@> =
@<Program License@>
#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include "prb.h"
#include "test.h"

@<BST print function; bst => prb@>
@<BST traverser check function; bst => prb@>
@<Compare two PRB trees for structure and content@>
@<Recursively verify PRB tree structure@>
@<RB tree verify function; rb => prb@>
@<BST test function; bst => prb@>
@<BST overflow test function; bst => prb@>
@

@<Compare two PRB trees for structure and content@> =
@iftangle
/* Compares binary trees rooted at |a| and |b|, @
   making sure that they are identical. */
@end iftangle
static int @
compare_trees (struct prb_node *a, struct prb_node *b) @
{
  int okay;

  if (a == NULL || b == NULL) @
    {@-
      assert (a == NULL && b == NULL);
      return 1;
    }@+

  if (*(int *) a->prb_data != *(int *) b->prb_data
      || ((a->prb_link[0] != NULL) != (b->prb_link[0] != NULL))
      || ((a->prb_link[1] != NULL) != (b->prb_link[1] != NULL))
      || a->prb_color != b->prb_color) @
    {@-
      printf (" Copied nodes differ: a=%d%c b=%d%c a:",
              *(int *) a->prb_data, a->prb_color == PRB_RED ? 'r' : 'b',
              *(int *) b->prb_data, b->prb_color == PRB_RED ? 'r' : 'b');

      if (a->prb_link[0] != NULL) @
        printf ("l");
      if (a->prb_link[1] != NULL) @
        printf ("r");

      printf (" b:");
      if (b->prb_link[0] != NULL) @
        printf ("l");
      if (b->prb_link[1] != NULL) @
        printf ("r");

      printf ("\n");
      return 0;
    }@+

  okay = 1;
  if (a->prb_link[0] != NULL)
    okay &= compare_trees (a->prb_link[0], b->prb_link[0]);
  if (a->prb_link[1] != NULL)
    okay &= compare_trees (a->prb_link[1], b->prb_link[1]);
  return okay;
}

@

@<Recursively verify PRB tree structure@> =
/* Examines the binary tree rooted at |node|.  
   Zeroes |*okay| if an error occurs.  @
   Otherwise, does not modify |*okay|.
   Sets |*count| to the number of nodes in that tree, @
   including |node| itself if |node != NULL|.
   Sets |*bh| to the tree's black-height.
   All the nodes in the tree are verified to be at least |min| @
   but no greater than |max|. */
static void @
recurse_verify_tree (struct prb_node *node, int *okay, size_t *count, 
                     int min, int max, int *bh) @
{
  int d;                /* Value of this node's data. */
  size_t subcount[2];   /* Number of nodes in subtrees. */
  int subbh[2];         /* Black-heights of subtrees. */
  int i;

  if (node == NULL) @
    {@-
      *count = 0;
      *bh = 0;
      return;
    }@+
  d = *(int *) node->prb_data;

  @<Verify binary search tree ordering@>

  recurse_verify_tree (node->prb_link[0], okay, &subcount[0], 
                       min, d - 1, &subbh[0]);
  recurse_verify_tree (node->prb_link[1], okay, &subcount[1], 
                       d + 1, max, &subbh[1]);
  *count = 1 + subcount[0] + subcount[1];
  *bh = (node->prb_color == PRB_BLACK) + subbh[0];

  @<Verify RB node color; rb => prb@>
  @<Verify RB node rule 1 compliance; rb => prb@>
  @<Verify RB node rule 2 compliance; rb => prb@>

  @<Verify PBST node parent pointers; pbst => prb@>
}

@

