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

@deftypedef trb_comparison_func
@deftypedef trb_item_func
@deftypedef trb_copy_func

@node Threaded Red-Black Trees, Right-Threaded Binary Search Trees, Threaded AVL Trees, Top
@chapter Threaded Red-Black Trees

In the last two chapters, we introduced the idea of a threaded binary
search tree, then applied that idea to AVL trees to produce threaded AVL
trees.  In this chapter, we will apply the idea of threading to
red-black trees, resulting in threaded red-black or ``TRB'' trees.

Here's an outline of the table implementation for threaded RB trees,
which use a |trb_| prefix.

@(trb.h@> =
@<Library License@>
#ifndef TRB_H
#define TRB_H 1

#include <stddef.h>

@<Table types; tbl => trb@>
@<RB maximum height; rb => trb@>
@<TBST table structure; tbst => trb@>
@<TRB node structure@>
@<TBST traverser structure; tbst => trb@>
@<Table function prototypes; tbl => trb@>

#endif /* trb.h */
@ 

@(trb.c@> =
@<Library License@>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "trb.h"

@<TRB functions@>
@

@menu
* TRB Data Types::              
* TRB Operations::              
* Inserting into a TRB Tree::   
* Deleting from a TRB Tree::    
* Testing TRB Trees::           
@end menu

@node TRB Data Types, TRB Operations, Threaded Red-Black Trees, Threaded Red-Black Trees
@section Data Types

To make a RB tree node structure into a threaded RB tree node structure,
we just add a pair of tag fields.  We also reintroduce a maximum height
definition here.  It is not used by traversers, only by by the default
versions of |trb_probe()| and |trb_delete()|, for maximum efficiency.

@<TRB node structure@> =
/* Color of a red-black node. */
enum trb_color @
  {@-
    TRB_BLACK,                     /* Black. */
    TRB_RED                        /* Red. */
  };@+

/* Characterizes a link as a child pointer or a thread. */
enum trb_tag @
  {@-
    TRB_CHILD,                     /* Child pointer. */
    TRB_THREAD                     /* Thread. */
  };@+

/* An TRB tree node. */
struct trb_node @
  {@-
    struct trb_node *trb_link[2];  /* Subtrees. */
    void *trb_data;                /* Pointer to data. */
    unsigned char trb_color;       /* Color. */
    unsigned char trb_tag[2];      /* Tag fields. */
  };@+

@

@node TRB Operations, Inserting into a TRB Tree, TRB Data Types, Threaded Red-Black Trees
@section Operations

Now we'll implement all the usual operations for TRB trees.  Here's the
outline.  We can reuse everything from TBSTs except insertion, deletion,
and copy functions.  The copy function is implemented by reusing the
version for TAVL trees, but copying colors instead of balance factors.

@<TRB functions@> =
@<TBST creation function; tbst => trb@>
@<TBST search function; tbst => trb@>
@<TRB item insertion function@>
@<Table insertion convenience functions; tbl => trb@>
@<TRB item deletion function@>
@<TBST traversal functions; tbst => trb@>
@<TAVL copy function; tavl => trb; tavl_balance => trb_color@>
@<TBST destruction function; tbst => trb@>
@<Default memory allocation functions; tbl => trb@>
@<Table assertion functions; tbl => trb@>
@

@node Inserting into a TRB Tree, Deleting from a TRB Tree, TRB Operations, Threaded Red-Black Trees
@section Insertion

The structure of the insertion routine is predictable:

@cat trb Insertion (with stack)
@<TRB item insertion function@> =
@iftangle
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree, 
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
@end iftangle
void **@
trb_probe (struct trb_table *tree, void *item) @
{
  struct trb_node *pa[TRB_MAX_HEIGHT]; /* Nodes on stack. */
  unsigned char da[TRB_MAX_HEIGHT];    /* Directions moved from stack nodes. */
  int k;                               /* Stack height. */

  struct trb_node *p; /* Traverses tree looking for insertion point. */
  struct trb_node *n; /* Newly inserted node. */
  int dir;            /* Side of |p| on which |n| is inserted. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Search TRB tree for insertion point@>
  @<Step 2: Insert TRB node@>
  @<Step 3: Rebalance after TRB insertion@>

  return &n->trb_data;
}

@

@menu
* Steps 1 and 2 in TRB Insertion::  
* Step 3 in TRB Insertion::     
* TRB Insertion Symmetric Case::  
@end menu

@node Steps 1 and 2 in TRB Insertion, Step 3 in TRB Insertion, Inserting into a TRB Tree, Inserting into a TRB Tree
@subsection Steps 1 and 2: Search and Insert

As usual, we search the tree from the root and record parents as we go.

@<Step 1: Search TRB tree for insertion point@> =
da[0] = 0;
pa[0] = (struct trb_node *) &tree->trb_root;
k = 1;
if (tree->trb_root != NULL) @
  {@-
    for (p = tree->trb_root; ; p = p->trb_link[dir]) @
      {@-
        int cmp = tree->trb_compare (item, p->trb_data, tree->trb_param);
        if (cmp == 0)
          return &p->trb_data;

        pa[k] = p;
        da[k++] = dir = cmp > 0;

        if (p->trb_tag[dir] == TRB_THREAD)
          break;
      }@+
  }@+ @
else @
  {@-
    p = (struct trb_node *) &tree->trb_root;
    dir = 0;
  }@+

@

The code for insertion is included within the loop for easy access to
the |dir| variable.

@<Step 2: Insert TRB node@> =
@<Step 2: Insert TBST node; tbst => trb@>
n->trb_color = TRB_RED;

@

@node Step 3 in TRB Insertion, TRB Insertion Symmetric Case, Steps 1 and 2 in TRB Insertion, Inserting into a TRB Tree
@subsection Step 3: Rebalance

The basic rebalancing loop is unchanged from @<Step 3: Rebalance after
RB insertion@>.

@<Step 3: Rebalance after TRB insertion@> =
while (k >= 3 && pa[k - 1]->trb_color == TRB_RED) @
  {@-
    if (da[k - 2] == 0)
      { @
        @<Left-side rebalancing after TRB insertion@> @
      }
    else @
      { @
        @<Right-side rebalancing after TRB insertion@> @
      }
  }@+
tree->trb_root->trb_color = TRB_BLACK;
@

The cases for rebalancing are the same as in @<Left-side rebalancing
after RB insertion@>, too.  We do need to check for threads, instead of
null pointers.

@<Left-side rebalancing after TRB insertion@> =
struct trb_node *y = pa[k - 2]->trb_link[1];
if (pa[k - 2]->trb_tag[1] == TRB_CHILD && y->trb_color == TRB_RED)
  { @
    @<Case 1 in left-side TRB insertion rebalancing@> @
  }
else @
  {@-
    struct trb_node *x;

    if (da[k - 1] == 0)
      y = pa[k - 1];
    else @
      { @
        @<Case 3 in left-side TRB insertion rebalancing@> @
      }

    @<Case 2 in left-side TRB insertion rebalancing@>
    break;
  }@+
@

The rest of this section deals with the individual rebalancing cases,
the same as in unthreaded RB insertion (@pxref{Inserting an RB Node
Step 3 - Rebalance}).  Each iteration deals with a node whose color has
just been changed to red, which is the newly inserted node |n| in the
first trip through the loop.  In the discussion, we'll call this node
|q|.

@subsubheading Case 1: |q|'s uncle is red

If node |q| has an red ``uncle'', then only recoloring is required.
Because no links are changed, no threads need to be updated, and we can
reuse the code for RB insertion without change:

@<Case 1 in left-side TRB insertion rebalancing@> =
@<Case 1 in left-side RB insertion rebalancing; rb => trb@>
@

@subsubheading Case 2: |q| is the left child of its parent

If |q| is the left child of its parent, we rotate right at |q|'s
grandparent, and recolor a few nodes.  Here's the transformation:

@center @image{rbins2}

@noindent
This transformation can only cause thread problems with subtree |c|,
since the other subtrees stay firmly in place.  If |c| is a thread, then
we need to make adjustments after the transformation to account for the
difference between threaded and unthreaded rotation, so that the final
operation looks like this:

@center @image{trbins}

@<Case 2 in left-side TRB insertion rebalancing@> =
@<Case 2 in left-side RB insertion rebalancing; rb => trb@>

if (y->trb_tag[1] == TRB_THREAD) @
  {@-
    y->trb_tag[1] = TRB_CHILD;
    x->trb_tag[0] = TRB_THREAD;
    x->trb_link[0] = y;
  }@+
@

@subsubheading Case 3: |q| is the right child of its parent

The modification to case 3 is the same as the modification to case 2,
but it applies to a left rotation instead of a right rotation.  The
adjusted case looks like this:

@center @image{trbins2}

@<Case 3 in left-side TRB insertion rebalancing@> =
@<Case 3 in left-side RB insertion rebalancing; rb => trb@>

if (y->trb_tag[0] == TRB_THREAD) @
  {@-
    y->trb_tag[0] = TRB_CHILD;
    x->trb_tag[1] = TRB_THREAD;
    x->trb_link[1] = y;
  }@+
@

@node TRB Insertion Symmetric Case,  , Step 3 in TRB Insertion, Inserting into a TRB Tree
@subsection Symmetric Case

@<Right-side rebalancing after TRB insertion@> =
struct trb_node *y = pa[k - 2]->trb_link[0];
if (pa[k - 2]->trb_tag[0] == TRB_CHILD && y->trb_color == TRB_RED)
  { @
    @<Case 1 in right-side TRB insertion rebalancing@> @
  }
else @
  {@-
    struct trb_node *x;

    if (da[k - 1] == 1)
      y = pa[k - 1];
    else @
      { @
        @<Case 3 in right-side TRB insertion rebalancing@> @
      }

    @<Case 2 in right-side TRB insertion rebalancing@>
    break;
  }@+
@

@<Case 1 in right-side TRB insertion rebalancing@> =
@<Case 1 in right-side RB insertion rebalancing; rb => trb@>
@

@<Case 2 in right-side TRB insertion rebalancing@> =
@<Case 2 in right-side RB insertion rebalancing; rb => trb@>

if (y->trb_tag[0] == TRB_THREAD) @
  {@-
    y->trb_tag[0] = TRB_CHILD;
    x->trb_tag[1] = TRB_THREAD;
    x->trb_link[1] = y;
  }@+
@

@<Case 3 in right-side TRB insertion rebalancing@> =
@<Case 3 in right-side RB insertion rebalancing; rb => trb@>

if (y->trb_tag[1] == TRB_THREAD) @
  {@-
    y->trb_tag[1] = TRB_CHILD;
    x->trb_tag[0] = TRB_THREAD;
    x->trb_link[0] = y;
  }@+
@

@exercise
It could be argued that the algorithm here is ``impure'' because it
uses a stack, when elimination of the need for a stack is one of the
reasons originally given for using threaded trees.  Write a version of
|trb_probe()| that avoids the use of a stack.  You can use
|find_parent()| from @<Find parent of a TBST node@> as a substitute.

@answer
For a brief explanation of an algorithm similar to the one here, see
@ref{Inserting into a PRB Tree}.

@cat trb Insertion, without stack
@c tested 2002/1/6
@<TRB item insertion function, without stack@> =
@<Find parent of a TBST node; tbst => trb@>

@iftangle
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree, 
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
@end iftangle
void **@
trb_probe (struct trb_table *tree, void *item) @
{
  struct trb_node *p; /* Traverses tree looking for insertion point. */
  struct trb_node *n; /* Newly inserted node. */
  int dir;            /* Side of |p| on which |n| is inserted. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Search TBST for insertion point; tbst => trb@>
  @<Step 2: Insert TRB node@>
  p = n;
  for (;;) @
    {@-
      struct trb_node *f, *g;

      f = find_parent (tree, p);
      if (f == (struct trb_node *) &tree->trb_root @
          || f->trb_color == TRB_BLACK)
	break;

      g = find_parent (tree, f);
      if (g == (struct trb_node *) &tree->trb_root)
	break;
      
      if (g->trb_link[0] == f) @
	{@-
	  struct trb_node *y = g->trb_link[1];
	  if (g->trb_tag[1] == TRB_CHILD && y->trb_color == TRB_RED) @
	    {@-
	      f->trb_color = y->trb_color = TRB_BLACK;
	      g->trb_color = TRB_RED;
	      p = g;
	    }@+ @
	  else @
	    {@-
	      struct trb_node *c, *x;

	      if (f->trb_link[0] == p)
		y = f;
	      else @
		{@-
		  x = f;
		  y = x->trb_link[1];
		  x->trb_link[1] = y->trb_link[0];
		  y->trb_link[0] = x;
		  g->trb_link[0] = y;

		  if (y->trb_tag[0] == TRB_THREAD) @
		    {@-
		      y->trb_tag[0] = TRB_CHILD;
		      x->trb_tag[1] = TRB_THREAD;
		      x->trb_link[1] = y;
		    }@+
		}@+

	      c = find_parent (tree, g);
	      c->trb_link[c->trb_link[0] != g] = y;

	      x = g;
	      x->trb_color = TRB_RED;
	      y->trb_color = TRB_BLACK;

	      x->trb_link[0] = y->trb_link[1];
	      y->trb_link[1] = x;

	      if (y->trb_tag[1] == TRB_THREAD) @
		{@-
		  y->trb_tag[1] = TRB_CHILD;
		  x->trb_tag[0] = TRB_THREAD;
		  x->trb_link[0] = y;
		}@+
	      break;
	    }@+
	}@+ @
      else @
	{@-
	  struct trb_node *y = g->trb_link[0];
	  if (g->trb_tag[0] == TRB_CHILD && y->trb_color == TRB_RED) @
	    {@-
	      f->trb_color = y->trb_color = TRB_BLACK;
	      g->trb_color = TRB_RED;
	      p = g;
	    }@+ @
	  else @
	    {@-
	      struct trb_node *c, *x;

	      if (f->trb_link[1] == p)
		y = f;
	      else @
		{@-
		  x = f;
		  y = x->trb_link[0];
		  x->trb_link[0] = y->trb_link[1];
		  y->trb_link[1] = x;
		  g->trb_link[1] = y;

		  if (y->trb_tag[1] == TRB_THREAD) @
		    {@-
		      y->trb_tag[1] = TRB_CHILD;
		      x->trb_tag[0] = TRB_THREAD;
		      x->trb_link[0] = y;
		    }@+
		}@+

	      c = find_parent (tree, g);
	      c->trb_link[c->trb_link[0] != g] = y;

	      x = g;
	      x->trb_color = TRB_RED;
	      y->trb_color = TRB_BLACK;

	      x->trb_link[1] = y->trb_link[0];
	      y->trb_link[0] = x;

	      if (y->trb_tag[0] == TRB_THREAD) @
		{@-
		  y->trb_tag[0] = TRB_CHILD;
		  x->trb_tag[1] = TRB_THREAD;
		  x->trb_link[1] = y;
		}@+
	      break;
	    }@+
	}@+
    }@+
  tree->trb_root->trb_color = TRB_BLACK;

  return &n->trb_data;
}
@
@end exercise

@node Deleting from a TRB Tree, Testing TRB Trees, Inserting into a TRB Tree, Threaded Red-Black Trees
@section Deletion

The outline for the deletion function follows the usual pattern.

@cat trb Deletion (with stack)
@c tested 2002/1/6
@<TRB item deletion function@> =
@iftangle
/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
@end iftangle
void *@
trb_delete (struct trb_table *tree, const void *item) @
{
  struct trb_node *pa[TRB_MAX_HEIGHT]; /* Nodes on stack. */
  unsigned char da[TRB_MAX_HEIGHT];    /* Directions moved from stack nodes. */
  int k = 0;                           /* Stack height. */

  struct trb_node *p;
  int cmp, dir;

  assert (tree != NULL && item != NULL);

  @<Step 1: Search TRB tree for item to delete@>
  @<Step 2: Delete item from TRB tree@>
  @<Step 3: Rebalance tree after TRB deletion@>
  @<Step 4: Finish up after TRB deletion@>
}

@

@menu
* Deleting a TRB Node Step 1 - Search::  
* Deleting a TRB Node Step 2 - Delete::  
* Deleting a TRB Node Step 3 - Rebalance::  
* Deleting a TRB Node Step 4 - Finish Up::  
* TRB Deletion Symmetric Case::  
@end menu

@node Deleting a TRB Node Step 1 - Search, Deleting a TRB Node Step 2 - Delete, Deleting from a TRB Tree, Deleting from a TRB Tree
@subsection Step 1: Search

There's nothing new or interesting in the search code.

@<Step 1: Search TRB tree for item to delete@> =
if (tree->trb_root == NULL)
  return NULL;

p = (struct trb_node *) &tree->trb_root;
for (cmp = -1; cmp != 0; @
     cmp = tree->trb_compare (item, p->trb_data, tree->trb_param)) @
  {@-
    dir = cmp > 0;
    pa[k] = p;
    da[k++] = dir;

    if (p->trb_tag[dir] == TRB_THREAD)
      return NULL;
    p = p->trb_link[dir];
  }@+
item = p->trb_data;

@

@node Deleting a TRB Node Step 2 - Delete, Deleting a TRB Node Step 3 - Rebalance, Deleting a TRB Node Step 1 - Search, Deleting from a TRB Tree
@subsection Step 2: Delete

The code for node deletion is a combination of RB deletion
(@pxref{Deleting an RB Node Step 2 - Delete}) and TBST deletion
(@pxref{Deleting from a TBST}).  The node to delete is |p|, and after
deletion the stack contains all the nodes down to where rebalancing
begins.  The cases are the same as for TBST deletion:

@<Step 2: Delete item from TRB tree@> =
if (p->trb_tag[1] == TRB_THREAD) @
  {@-
    if (p->trb_tag[0] == TRB_CHILD)
      { @
        @<Case 1 in TRB deletion@> @
      }
    else @
      { @
        @<Case 2 in TRB deletion@> @
      }
  }@+ @
else @
  {@-
    enum trb_color t;
    struct trb_node *r = p->trb_link[1];

    if (r->trb_tag[0] == TRB_THREAD)
      { @
        @<Case 3 in TRB deletion@> @
      }
    else @
      { @
        @<Case 4 in TRB deletion@> @
      }
  }@+

@

@subsubheading Case 1: |p| has a right thread and a left child

If the node to delete |p| has a right thread and a left child, then we
replace it by its left child.  We also have to chase down the right
thread that pointed to |p|.  The code is almost the same as @<Case 1 in
TBST deletion@>, but we use the stack here instead of a single parent
pointer.

@<Case 1 in TRB deletion@> =
struct trb_node *t = p->trb_link[0];
while (t->trb_tag[1] == TRB_CHILD)
  t = t->trb_link[1];
t->trb_link[1] = p->trb_link[1];
pa[k - 1]->trb_link[da[k - 1]] = p->trb_link[0];
@

@subsubheading Case 2: |p| has a right thread and a left thread

Deleting a leaf node is the same process as for a TBST.  The changes
from @<Case 2 in TBST deletion@> are again due to the use of a stack.

@<Case 2 in TRB deletion@> =
pa[k - 1]->trb_link[da[k - 1]] = p->trb_link[da[k - 1]];
if (pa[k - 1] != (struct trb_node *) &tree->trb_root)
  pa[k - 1]->trb_tag[da[k - 1]] = TRB_THREAD;
@

@subsubheading Case 3: |p|'s right child has a left thread

The code for case 3 merges @<Case 3 in TBST deletion@> with @<Case 2
in RB deletion@>.  First, the node is deleted in the same way used for
a TBST.  Then the colors of |p| and |r| are swapped, and |r| is added
to the stack, in the same way as for RB deletion.

@<Case 3 in TRB deletion@> =
r->trb_link[0] = p->trb_link[0];
r->trb_tag[0] = p->trb_tag[0];
if (r->trb_tag[0] == TRB_CHILD) @
  {@-
    struct trb_node *t = r->trb_link[0];
    while (t->trb_tag[1] == TRB_CHILD)
      t = t->trb_link[1];
    t->trb_link[1] = r;
  }@+
pa[k - 1]->trb_link[da[k - 1]] = r;
t = r->trb_color;
r->trb_color = p->trb_color;
p->trb_color = t;
da[k] = 1;
pa[k++] = r;
@

@subsubheading Case 4: |p|'s right child has a left child

Case 4 is a mix of @<Case 4 in TBST deletion@> and @<Case 3 in RB
deletion@>.  It follows the outline of TBST deletion, but updates the
stack.  After the deletion it also swaps the colors of |p| and |s| as
in RB deletion.

@<Case 4 in TRB deletion@> =
struct trb_node *s;
int j = k++;

for (;;) @
  {@-
    da[k] = 0;
    pa[k++] = r;
    s = r->trb_link[0];
    if (s->trb_tag[0] == TRB_THREAD)
      break;

    r = s;
  }@+

da[j] = 1;
pa[j] = s;
if (s->trb_tag[1] == TRB_CHILD)
  r->trb_link[0] = s->trb_link[1];
else @
  {@-
    r->trb_link[0] = s;
    r->trb_tag[0] = TRB_THREAD;
  }@+

s->trb_link[0] = p->trb_link[0];
if (p->trb_tag[0] == TRB_CHILD) @
  {@-
    struct trb_node *t = p->trb_link[0];
    while (t->trb_tag[1] == TRB_CHILD)
      t = t->trb_link[1];
    t->trb_link[1] = s;

    s->trb_tag[0] = TRB_CHILD;
  }@+

s->trb_link[1] = p->trb_link[1];
s->trb_tag[1] = TRB_CHILD;

t = s->trb_color;
s->trb_color = p->trb_color;
p->trb_color = t;

pa[j - 1]->trb_link[da[j - 1]] = s;

@

@exercise
Rewrite @<Case 4 in TAVL deletion@> to replace the deleted node's
|tavl_data| by its successor, then delete the successor, instead of
shuffling pointers.  (Refer back to @value{modifydata} for an
explanation of why this approach cannot be used in @libavl{}.)

@answer
@cat trb Deletion, with data modification
@c tested 2001/11/10
@<Case 4 in TRB deletion, alternate version@> =
struct trb_node *s;

da[k] = 1;
pa[k++] = p;
for (;;) @
  {@-
    da[k] = 0;
    pa[k++] = r;
    s = r->trb_link[0];
    if (s->trb_tag[0] == TRB_THREAD)
      break;

    r = s;
  }@+

p->trb_data = s->trb_data;

if (s->trb_tag[1] == TRB_THREAD) @
  {@-
    r->trb_tag[0] = TRB_THREAD;
    r->trb_link[0] = p;
  }@+ @
else @
  {@-
    struct trb_node *t = r->trb_link[0] = s->trb_link[1];
    while (t->trb_tag[0] == TRB_CHILD)
      t = t->trb_link[0];
    t->trb_link[0] = p;
  }@+

p = s;
@
@end exercise

@node Deleting a TRB Node Step 3 - Rebalance, Deleting a TRB Node Step 4 - Finish Up, Deleting a TRB Node Step 2 - Delete, Deleting from a TRB Tree
@subsection Step 3: Rebalance

The outline for rebalancing after threaded RB deletion is the same as
for the unthreaded case (@pxref{Deleting an RB Node Step 3 - Rebalance}):

@<Step 3: Rebalance tree after TRB deletion@> =
if (p->trb_color == TRB_BLACK) @
  {@-
    for (; k > 1; k--) @
      {@-
        if (pa[k - 1]->trb_tag[da[k - 1]] == TRB_CHILD) @
          {@-
            struct trb_node *x = pa[k - 1]->trb_link[da[k - 1]];
            if (x->trb_color == TRB_RED) @
              {@-
                x->trb_color = TRB_BLACK;
                break;
              }@+
          }@+

        if (da[k - 1] == 0)
          { @
            @<Left-side rebalancing after TRB deletion@> @
          }
        else @
          { @
            @<Right-side rebalancing after TRB deletion@> @
          }
      }@+

    if (tree->trb_root != NULL)
      tree->trb_root->trb_color = TRB_BLACK;
  }@+

@

The rebalancing cases are the same, too.  We need to check for thread
tags, not for null pointers, though, in some places:

@<Left-side rebalancing after TRB deletion@> =
struct trb_node *w = pa[k - 1]->trb_link[1];

if (w->trb_color == TRB_RED) 
  { @
    @<Ensure |w| is black in left-side TRB deletion rebalancing@> @
  }

if ((w->trb_tag[0] == TRB_THREAD @
     || w->trb_link[0]->trb_color == TRB_BLACK)
    && (w->trb_tag[1] == TRB_THREAD @
        || w->trb_link[1]->trb_color == TRB_BLACK))
  { @
    @<Case 1 in left-side TRB deletion rebalancing@> @
  }
else @
  {@-
    if (w->trb_tag[1] == TRB_THREAD @
        || w->trb_link[1]->trb_color == TRB_BLACK)
      { @
        @<Transform left-side TRB deletion rebalancing case 3 into case 2@> @
      }

    @<Case 2 in left-side TRB deletion rebalancing@>
    break;
  }@+
@

@subsubheading Case Reduction: Ensure |w| is black

This transformation does not move around any subtrees that might be
threads, so there is no need for it to change.

@<Ensure |w| is black in left-side TRB deletion rebalancing@> =
@<Ensure |w| is black in left-side RB deletion rebalancing; rb => trb@>
@

@subsubheading Case 1: |w| has no red children

This transformation just recolors nodes, so it also does not need any
changes.

@<Case 1 in left-side TRB deletion rebalancing@> =
@<Case 1 in left-side RB deletion rebalancing; rb => trb@>
@

@subsubheading Case 2: |w|'s right child is red

If |w| has a red right child and a left thread, then it is necessary to
adjust tags and links after the left rotation at |w| and recoloring, as
shown in this diagram:

@center @image{trbdel}

@<Case 2 in left-side TRB deletion rebalancing@> =
@<Case 2 in left-side RB deletion rebalancing; rb => trb@>

if (w->trb_tag[0] == TRB_THREAD) @
  {@-
    w->trb_tag[0] = TRB_CHILD;
    pa[k - 1]->trb_tag[1] = TRB_THREAD;
    pa[k - 1]->trb_link[1] = w;
  }@+
@

@subsubheading Case 3: |w|'s left child is red

If |w| has a red left child, which has a right thread, then we again need
to adjust tags and links after right rotation at |w| and recoloring, as
shown here:

@center @image{trbdel2}

@<Transform left-side TRB deletion rebalancing case 3 into case 2@> =
@<Transform left-side RB deletion rebalancing case 3 into case 2; rb => trb@>

if (w->trb_tag[1] == TRB_THREAD) @
  {@-
    w->trb_tag[1] = TRB_CHILD;
    w->trb_link[1]->trb_tag[0] = TRB_THREAD;
    w->trb_link[1]->trb_link[0] = w;
  }@+
@

@node Deleting a TRB Node Step 4 - Finish Up, TRB Deletion Symmetric Case, Deleting a TRB Node Step 3 - Rebalance, Deleting from a TRB Tree
@subsection Step 4: Finish Up

All that's left to do is free the node, update the count, and return the
deleted item:

@<Step 4: Finish up after TRB deletion@> =
tree->trb_alloc->libavl_free (tree->trb_alloc, p);
tree->trb_count--;
return (void *) item;
@

@node TRB Deletion Symmetric Case,  , Deleting a TRB Node Step 4 - Finish Up, Deleting from a TRB Tree
@subsection Symmetric Case

@<Right-side rebalancing after TRB deletion@> =
struct trb_node *w = pa[k - 1]->trb_link[0];

if (w->trb_color == TRB_RED) 
  { @
    @<Ensure |w| is black in right-side TRB deletion rebalancing@> @
  }

if ((w->trb_tag[0] == TRB_THREAD @
     || w->trb_link[0]->trb_color == TRB_BLACK)
    && (w->trb_tag[1] == TRB_THREAD @
        || w->trb_link[1]->trb_color == TRB_BLACK))
  { @
    @<Case 1 in right-side TRB deletion rebalancing@> @
  }
else @
  {@-
    if (w->trb_tag[0] == TRB_THREAD @
        || w->trb_link[0]->trb_color == TRB_BLACK)
      { @
        @<Transform right-side TRB deletion rebalancing case 3 into case 2@> @
      }

    @<Case 2 in right-side TRB deletion rebalancing@>
    break;
  }@+
@

@<Ensure |w| is black in right-side TRB deletion rebalancing@> =
@<Ensure |w| is black in right-side RB deletion rebalancing; rb => trb@>
@

@<Case 1 in right-side TRB deletion rebalancing@> =
@<Case 1 in right-side RB deletion rebalancing; rb => trb@>
@

@<Case 2 in right-side TRB deletion rebalancing@> =
@<Case 2 in right-side RB deletion rebalancing; rb => trb@>

if (w->trb_tag[1] == TRB_THREAD) @
  {@-
    w->trb_tag[1] = TRB_CHILD;
    pa[k - 1]->trb_tag[0] = TRB_THREAD;
    pa[k - 1]->trb_link[0] = w;
  }@+
@

@<Transform right-side TRB deletion rebalancing case 3 into case 2@> =
@<Transform right-side RB deletion rebalancing case 3 into case 2; rb => trb@>

if (w->trb_tag[0] == TRB_THREAD) @
  {@-
    w->trb_tag[0] = TRB_CHILD;
    w->trb_link[0]->trb_tag[1] = TRB_THREAD;
    w->trb_link[0]->trb_link[1] = w;
  }@+
@

@exercise
Write another version of |trb_delete()| that does not use a stack.  You
can use @<Find parent of a TBST node@> to find the parent of a node.

@answer
The code used in the rebalancing loop is related to @<Step 3:
Rebalance tree after PRB deletion@>.  Variable |x| is initialized by
step 2 here, though, because otherwise the pseudo-root node would be
required to have a |trb_tag[]| member.

@cat trb Deletion, without stack
@c tested 2001/11/10
@<TRB item deletion function, without stack@> = 
@<Find parent of a TBST node; tbst => trb@>

@iftangle
/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
@end iftangle
void *@
trb_delete (struct trb_table *tree, const void *item) @
{
  struct trb_node *p; /* Node to delete. */
  struct trb_node *q; /* Parent of |p|. */

  struct trb_node *x; /* Node we might want to recolor red (maybe |NULL|). */
  struct trb_node *f; /* Parent of |x|. */
  struct trb_node *g; /* Parent of |f|. */

  int dir, cmp;

  assert (tree != NULL && item != NULL);

  @<Step 1: Search TAVL tree for item to delete; tavl => trb@>
  if (p->trb_tag[1] == TRB_THREAD) @
    {@-
      if (p->trb_tag[0] == TRB_CHILD) @
	{@-
	  struct trb_node *t = p->trb_link[0];
	  while (t->trb_tag[1] == TRB_CHILD)
	    t = t->trb_link[1];
	  t->trb_link[1] = p->trb_link[1];
	  x = q->trb_link[dir] = p->trb_link[0];
	}@+ @
      else @
	{@-
	  q->trb_link[dir] = p->trb_link[dir];
	  if (q != (struct trb_node *) &tree->trb_root)
	    q->trb_tag[dir] = TRB_THREAD;
	  x = NULL;
	}@+
      f = q;
    }@+ @
  else @
    {@-
      enum trb_color t;
      struct trb_node *r = p->trb_link[1];

      if (r->trb_tag[0] == TRB_THREAD) @
	{@-
	  r->trb_link[0] = p->trb_link[0];
	  r->trb_tag[0] = p->trb_tag[0];
	  if (r->trb_tag[0] == TRB_CHILD) @
	    {@-
	      struct trb_node *t = r->trb_link[0];
	      while (t->trb_tag[1] == TRB_CHILD)
		t = t->trb_link[1];
	      t->trb_link[1] = r;
	    }@+
	  q->trb_link[dir] = r;
	  x = r->trb_tag[1] == TRB_CHILD ? r->trb_link[1] : NULL;
	  t = r->trb_color;
	  r->trb_color = p->trb_color;
	  p->trb_color = t;
	  f = r;
	  dir = 1;
	}@+ @
      else @
	{@-
	  struct trb_node *s;

	  for (;;) @
	    {@-
	      s = r->trb_link[0];
	      if (s->trb_tag[0] == TRB_THREAD)
		break;

	      r = s;
	    }@+

	  if (s->trb_tag[1] == TRB_CHILD)
	    x = r->trb_link[0] = s->trb_link[1];
	  else @
	    {@-
	      r->trb_link[0] = s;
	      r->trb_tag[0] = TRB_THREAD;
	      x = NULL;
	    }@+

	  s->trb_link[0] = p->trb_link[0];
	  if (p->trb_tag[0] == TRB_CHILD) @
	    {@-
	      struct trb_node *t = p->trb_link[0];
	      while (t->trb_tag[1] == TRB_CHILD)
		t = t->trb_link[1];
	      t->trb_link[1] = s;

	      s->trb_tag[0] = TRB_CHILD;
	    }@+

	  s->trb_link[1] = p->trb_link[1];
	  s->trb_tag[1] = TRB_CHILD;

	  t = s->trb_color;
	  s->trb_color = p->trb_color;
	  p->trb_color = t;

	  q->trb_link[dir] = s;
	  f = r;
	  dir = 0;
	}@+
    }@+

  if (p->trb_color == TRB_BLACK) @
    {@-
      for (;;)
	{@-
          if (x != NULL && x->trb_color == TRB_RED) @
            {@-
              x->trb_color = TRB_BLACK;
              break;
            }@+
	  if (f == (struct trb_node *) &tree->trb_root)
	    break;

	  g = find_parent (tree, f);

          if (dir == 0) @
	    {@-
	      struct trb_node *w = f->trb_link[1];

	      if (w->trb_color == TRB_RED) @
		{@-
		  w->trb_color = TRB_BLACK;
		  f->trb_color = TRB_RED;

		  f->trb_link[1] = w->trb_link[0];
		  w->trb_link[0] = f;
		  g->trb_link[g->trb_link[0] != f] = w;

		  g = w;
		  w = f->trb_link[1];
		}@+

	      if ((w->trb_tag[0] == TRB_THREAD
		   || w->trb_link[0]->trb_color == TRB_BLACK)
		  && (w->trb_tag[1] == TRB_THREAD
		      || w->trb_link[1]->trb_color == TRB_BLACK)) @
                w->trb_color = TRB_RED;
	      else @
		{@-
		  if (w->trb_tag[1] == TRB_THREAD
		      || w->trb_link[1]->trb_color == TRB_BLACK) @
		    {@-
		      struct trb_node *y = w->trb_link[0];
		      y->trb_color = TRB_BLACK;
		      w->trb_color = TRB_RED;
		      w->trb_link[0] = y->trb_link[1];
		      y->trb_link[1] = w;
		      w = f->trb_link[1] = y;

		      if (w->trb_tag[1] == TRB_THREAD) @
			{@-
			  w->trb_tag[1] = TRB_CHILD;
			  w->trb_link[1]->trb_tag[0] = TRB_THREAD;
			  w->trb_link[1]->trb_link[0] = w;
			}@+
		    }@+

		  w->trb_color = f->trb_color;
		  f->trb_color = TRB_BLACK;
		  w->trb_link[1]->trb_color = TRB_BLACK;

		  f->trb_link[1] = w->trb_link[0];
		  w->trb_link[0] = f;
		  g->trb_link[g->trb_link[0] != f] = w;

		  if (w->trb_tag[0] == TRB_THREAD) @
		    {@-
		      w->trb_tag[0] = TRB_CHILD;
		      f->trb_tag[1] = TRB_THREAD;
		      f->trb_link[1] = w;
		    }@+
		  break;
		}@+
	    }@+ @
	  else @
	    {@-
	      struct trb_node *w = f->trb_link[0];

	      if (w->trb_color == TRB_RED) @
		{@-
		  w->trb_color = TRB_BLACK;
		  f->trb_color = TRB_RED;

		  f->trb_link[0] = w->trb_link[1];
		  w->trb_link[1] = f;
		  g->trb_link[g->trb_link[0] != f] = w;

		  g = w;
		  w = f->trb_link[0];
		}@+

	      if ((w->trb_tag[0] == TRB_THREAD
		   || w->trb_link[0]->trb_color == TRB_BLACK)
		  && (w->trb_tag[1] == TRB_THREAD
		      || w->trb_link[1]->trb_color == TRB_BLACK)) @
                w->trb_color = TRB_RED;
	      else @
		{@-
		  if (w->trb_tag[0] == TRB_THREAD
		      || w->trb_link[0]->trb_color == TRB_BLACK) @
		    {@-
		      struct trb_node *y = w->trb_link[1];
		      y->trb_color = TRB_BLACK;
		      w->trb_color = TRB_RED;
		      w->trb_link[1] = y->trb_link[0];
		      y->trb_link[0] = w;
		      w = f->trb_link[0] = y;

		      if (w->trb_tag[0] == TRB_THREAD) @
			{@-
			  w->trb_tag[0] = TRB_CHILD;
			  w->trb_link[0]->trb_tag[1] = TRB_THREAD;
			  w->trb_link[0]->trb_link[1] = w;
			}@+
		    }@+

		  w->trb_color = f->trb_color;
		  f->trb_color = TRB_BLACK;
		  w->trb_link[0]->trb_color = TRB_BLACK;

		  f->trb_link[0] = w->trb_link[1];
		  w->trb_link[1] = f;
		  g->trb_link[g->trb_link[0] != f] = w;

		  if (w->trb_tag[1] == TRB_THREAD) @
		    {@-
		      w->trb_tag[1] = TRB_CHILD;
		      f->trb_tag[0] = TRB_THREAD;
		      f->trb_link[0] = w;
		    }@+
		  break;
		}@+
	    }@+

	  x = f;
	  f = find_parent (tree, x);
          if (f == (struct trb_node *) &tree->trb_root)
            break;

	  dir = f->trb_link[0] != x;
	}@+
    }@+

  tree->trb_alloc->libavl_free (tree->trb_alloc, p);
  tree->trb_count--;
  return (void *) item;
}

@
@end exercise

@node Testing TRB Trees,  , Deleting from a TRB Tree, Threaded Red-Black Trees
@section Testing

The testing code harbors no surprises.

@(trb-test.c@> =
@<Program License@>
#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include "trb.h"
#include "test.h"

@<TBST print function; tbst => trb@>
@<BST traverser check function; bst => trb@>
@<Compare two TRB trees for structure and content@>
@<Recursively verify TRB tree structure@>
@<RB tree verify function; rb => trb@>
@<BST test function; bst => trb@>
@<BST overflow test function; bst => trb@>
@

@<Compare two TRB trees for structure and content@> =
@iftangle
/* Compares binary trees rooted at |a| and |b|, @
   making sure that they are identical. */
@end iftangle
static int @
compare_trees (struct trb_node *a, struct trb_node *b) @
{
  int okay;

  if (a == NULL || b == NULL) @
    {@-
      if (a != NULL || b != NULL) @
	{@-
	  printf (" a=%d b=%d\n",
		  a ? *(int *) a->trb_data : -1, @
		  b ? *(int *) b->trb_data : -1);
	  assert (0);
	}@+
      return 1;
    }@+
  assert (a != b);

  if (*(int *) a->trb_data != *(int *) b->trb_data
      || a->trb_tag[0] != b->trb_tag[0] @
      || a->trb_tag[1] != b->trb_tag[1]
      || a->trb_color != b->trb_color) @
    {@-
      printf (" Copied nodes differ: a=%d%c b=%d%c a:",
	      *(int *) a->trb_data, a->trb_color == TRB_RED ? 'r' : 'b',
              *(int *) b->trb_data, b->trb_color == TRB_RED ? 'r' : 'b');

      if (a->trb_tag[0] == TRB_CHILD) @
	printf ("l");
      if (a->trb_tag[1] == TRB_CHILD) @
	printf ("r");

      printf (" b:");
      if (b->trb_tag[0] == TRB_CHILD) @
	printf ("l");
      if (b->trb_tag[1] == TRB_CHILD) @
	printf ("r");

      printf ("\n");
      return 0;
    }@+

  if (a->trb_tag[0] == TRB_THREAD)
    assert ((a->trb_link[0] == NULL) != (a->trb_link[0] != b->trb_link[0]));
  if (a->trb_tag[1] == TRB_THREAD)
    assert ((a->trb_link[1] == NULL) != (a->trb_link[1] != b->trb_link[1]));

  okay = 1;
  if (a->trb_tag[0] == TRB_CHILD)
    okay &= compare_trees (a->trb_link[0], b->trb_link[0]);
  if (a->trb_tag[1] == TRB_CHILD)
    okay &= compare_trees (a->trb_link[1], b->trb_link[1]);
  return okay;
}

@

@<Recursively verify TRB tree structure@> =
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
recurse_verify_tree (struct trb_node *node, int *okay, size_t *count, 
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
  d = *(int *) node->trb_data;

  @<Verify binary search tree ordering@>

  subcount[0] = subcount[1] = 0;
  subbh[0] = subbh[1] = 0;
  if (node->trb_tag[0] == TRB_CHILD)
    recurse_verify_tree (node->trb_link[0], okay, &subcount[0], 
                         min, d - 1, &subbh[0]);
  if (node->trb_tag[1] == TRB_CHILD)
    recurse_verify_tree (node->trb_link[1], okay, &subcount[1], 
                         d + 1, max, &subbh[1]);
  *count = 1 + subcount[0] + subcount[1];
  *bh = (node->trb_color == TRB_BLACK) + subbh[0];

  @<Verify RB node color; rb => trb@>
  @<Verify TRB node rule 1 compliance@>
  @<Verify RB node rule 2 compliance; rb => trb@>
}

@

@<Verify TRB node rule 1 compliance@> =
/* Verify compliance with rule 1. */
if (node->trb_color == TRB_RED) @
  {@-
    if (node->trb_tag[0] == TRB_CHILD @
        && node->trb_link[0]->trb_color == TRB_RED) @
      {@-
        printf (" Red node %d has red left child %d\n",
                d, *(int *) node->trb_link[0]->trb_data);
        *okay = 0;
      }@+

    if (node->trb_tag[1] == TRB_CHILD @
        && node->trb_link[1]->trb_color == TRB_RED) @
      {@-
        printf (" Red node %d has red right child %d\n",
                d, *(int *) node->trb_link[1]->trb_data);
        *okay = 0;
      }@+
  }@+

@
