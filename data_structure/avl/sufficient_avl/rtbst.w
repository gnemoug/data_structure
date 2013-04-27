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

@deftypedef rtbst_comparison_func
@deftypedef rtbst_item_func
@deftypedef rtbst_copy_func

@node Right-Threaded Binary Search Trees, Right-Threaded AVL Trees, Threaded Red-Black Trees, Top
@chapter Right-Threaded Binary Search Trees

We originally introduced threaded trees to allow for traversal without
maintaining a stack explicitly.  This worked out well, so we implemented
tables using threaded BSTs and AVL and RB trees.  However, maintaining
the threads can take some time.  It would be nice if we could have the
advantages of threads without so much of the overhead.

In one common special case, we can.  Threaded trees are symmetric:
there are left threads for moving to node predecessors and right
threads for move to node successors.  But traversals are not
symmetric: many algorithms that traverse table entries only from least
to greatest, never backing up.  This suggests a matching asymmetric
tree structure that has only right threads.

We can do this.  In this chapter, we will develop a table
implementation for a new kind of binary tree, called a right-threaded
binary search tree, @gloss{right-threaded tree}, or simply ``RTBST'',
that has threads only on the right side of nodes.  Construction and
modification of such trees can be faster and simpler than threaded
trees because there is no need to maintain the left threads.

There isn't anything fundamentally new here, but just for completeness,
here's an example of a right-threaded tree:

@center @image{rtbst1}

Keep in mind that although it is not efficient, it is still possible to
traverse a right-threaded tree in order from greatest to
least.@footnote{It can be efficient if we use a stack to do it, but that
kills the advantage of threading the tree.  It would be possible to
implement two sets of traversers for right-threaded trees, one with a
stack, one without, but in that case it's probably better to just use a
threaded tree.}  If it were not possible at all, then we could not build
a complete table implementation based on right-threaded trees, because
the definition of a table includes the ability to traverse it in either
direction (@pxref{Manipulators}).

Here's the outline of the RTBST code, which uses the prefix |rtbst_|:

@(rtbst.h@> =
@<Library License@>
#ifndef RTBST_H
#define RTBST_H 1

#include <stddef.h>

@<Table types; tbl => rtbst@>
@<TBST table structure; tbst => rtbst@>
@<RTBST node structure@>
@<TBST traverser structure; tbst => rtbst@>
@<Table function prototypes; tbl => rtbst@>
@<BST extra function prototypes; bst => rtbst@>

#endif /* rtbst.h */
@ 

@(rtbst.c@> =
@<Library License@>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "rtbst.h"

@<RTBST functions@>
@

@references
@bibref{Knuth 1997}, section 2.3.1.

@exercise
We can define a @gloss{left-threaded tree} in a way analogous to a
right-threaded tree, as a binary search tree with threads only on
the left sides of nodes.  Is this a useful thing to do?

@answer
If we already have right-threaded trees, then we can get the benefits of
a left-threaded tree just by reversing the sense of the comparison
function, so there is no additional benefit to left-threaded trees.
@end exercise

@menu
* RTBST Data Types::            
* RTBST Operations::            
* Searching an RTBST::          
* Inserting into an RTBST::     
* Deleting from an RTBST::      
* Traversing an RTBST::         
* Copying an RTBST::            
* Destroying an RTBST::         
* Balancing an RTBST::          
* Testing RTBSTs::              
@end menu

@node RTBST Data Types, RTBST Operations, Right-Threaded Binary Search Trees, Right-Threaded Binary Search Trees
@section Data Types

@<RTBST node structure@> =
/* Characterizes a link as a child pointer or a thread. */
enum rtbst_tag @
  {@-
    RTBST_CHILD,                     /* Child pointer. */
    RTBST_THREAD                     /* Thread. */
  };@+

/* A threaded binary search tree node. */
struct rtbst_node @
  {@-
    struct rtbst_node *rtbst_link[2]; /* Subtrees. */
    void *rtbst_data;                 /* Pointer to data. */
    unsigned char rtbst_rtag;         /* Tag field. */
  };@+

@

@node RTBST Operations, Searching an RTBST, RTBST Data Types, Right-Threaded Binary Search Trees
@section Operations

@<RTBST functions@> =
@<TBST creation function; tbst => rtbst@>
@<RTBST search function@>
@<RTBST item insertion function@>
@<Table insertion convenience functions; tbl => rtbst@>
@<RTBST item deletion function@>
@<RTBST traversal functions@>
@<RTBST copy function@>
@<RTBST destruction function@>
@<RTBST balance function@>
@<Default memory allocation functions; tbl => rtbst@>
@<Table assertion functions; tbl => rtbst@>
@

@node Searching an RTBST, Inserting into an RTBST, RTBST Operations, Right-Threaded Binary Search Trees
@section Search

A right-threaded tree is inherently asymmetric, so many of the
algorithms on it will necessarily be asymmetric as well.  The search
function is the simplest demonstration of this.  For descent to the
left, we test for a null left child with |rtbst_link[0]|; for descent
to the right, we test for a right thread with |rtbst_rtag|.
Otherwise, the code is familiar:

@cat rtbst Search
@<RTBST search function@> =
@iftangle
/* Search |tree| for an item matching |item|, and return it if found.
   Otherwise return |NULL|. */
@end iftangle
void *@
rtbst_find (const struct rtbst_table *tree, const void *item) @
{
  const struct rtbst_node *p;
  int dir;

  assert (tree != NULL && item != NULL);

  if (tree->rtbst_root == NULL)
    return NULL;

  for (p = tree->rtbst_root; ; p = p->rtbst_link[dir]) @
    {@-
      int cmp = tree->rtbst_compare (item, p->rtbst_data, tree->rtbst_param);
      if (cmp == 0)
	return p->rtbst_data;
      dir = cmp > 0;

      if (dir == 0) @
	{@-
	  if (p->rtbst_link[0] == NULL)
	    return NULL;
	}@+ @
      else /* |dir == 1| */ @
        {@-
          if (p->rtbst_rtag == RTBST_THREAD)
            return NULL;
        }@+
    }@+
}

@

@node Inserting into an RTBST, Deleting from an RTBST, Searching an RTBST, Right-Threaded Binary Search Trees
@section Insertion

Regardless of the kind of binary tree we're dealing with, adding a new
node requires setting three pointer fields: the parent pointer and the
two child pointers of the new node.  On the other hand, we do save a
tiny bit on tags: we set either 1 or 2 tags here as opposed to a
constant of 3 in @<TBST item insertion function@>.

Here is the outline:

@cat rtbst Insertion
@<RTBST item insertion function@> =
@iftangle
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree, 
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
@end iftangle
void **@
rtbst_probe (struct rtbst_table *tree, void *item) @
{
  struct rtbst_node *p; /* Current node in search. */
  int dir;              /* Side of |p| on which to insert the new node. */

  struct rtbst_node *n; /* New node. */
  
  @<Step 1: Search RTBST for insertion point@>
  @<Step 2: Insert new node into RTBST tree@>
}

@

The code to search for the insertion point is not unusual:

@<Step 1: Search RTBST for insertion point@> =
if (tree->rtbst_root != NULL)
  for (p = tree->rtbst_root; ; p = p->rtbst_link[dir]) @
    {@-
      int cmp = tree->rtbst_compare (item, p->rtbst_data, tree->rtbst_param);
      if (cmp == 0)
        return &p->rtbst_data;
      dir = cmp > 0;

      if (dir == 0) @
        {@-
          if (p->rtbst_link[0] == NULL)
            break;
        }@+ @
      else /* |dir == 1| */ @
        {@-
          if (p->rtbst_rtag == RTBST_THREAD)
            break;
        }@+
    }@+
else @
  {@-
    p = (struct rtbst_node *) &tree->rtbst_root;
    dir = 0;
  }@+

@

Now for the insertion code.  An insertion to the left of a node |p| in
a right-threaded tree replaces the left link by the new node |n|.  The
new node in turn has a null left child and a right thread pointing
back to |p|:

@center @image{rtbstins}

An insertion to the right of |p| replaces the right thread by the new
child node |n|.  The new node has a null left child and a right thread
that points where |p|'s right thread formerly pointed:

@center @image{rtbstins2}

We can handle both of these cases in one code segment.  The difference
is in the treatment of |n|'s right child and |p|'s right tag.
Insertion into an empty tree is handled as a special case as well:

@<Step 2: Insert new node into RTBST tree@> =
n = tree->rtbst_alloc->libavl_malloc (tree->rtbst_alloc, sizeof *n);
if (n == NULL)
  return NULL;

tree->rtbst_count++;
n->rtbst_data = item;
n->rtbst_link[0] = NULL;
if (dir == 0) @
  {@-
    if (tree->rtbst_root != NULL)
      n->rtbst_link[1] = p;
    else @
      n->rtbst_link[1] = NULL;
  }@+ @
else /* |dir == 1| */ @
  {@-
    p->rtbst_rtag = RTBST_CHILD;
    n->rtbst_link[1] = p->rtbst_link[1];
  }@+
n->rtbst_rtag = RTBST_THREAD;
p->rtbst_link[dir] = n;

return &n->rtbst_data;
@

@node Deleting from an RTBST, Traversing an RTBST, Inserting into an RTBST, Right-Threaded Binary Search Trees
@section Deletion

Deleting a node from an RTBST can be done using the same ideas as for
other kinds of trees we've seen.  However, as it turns out, a variant of
this usual technique allows for faster code.  In this section, we will
implement the usual method, then the improved version.  The latter is
actually used in @libavl{}.

Here is the outline of the function.  Step 2 is the only part that
varies between versions:

@<RTBST item deletion function@> =
@iftangle
/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
@end iftangle
void *@
rtbst_delete (struct rtbst_table *tree, const void *item) @
{
  struct rtbst_node *p;	/* Node to delete. */
  struct rtbst_node *q;	/* Parent of |p|. */
  int dir;              /* Index into |q->rtbst_link[]| that leads to |p|. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Find RTBST node to delete@>
  @<Step 2: Delete RTBST node, left-looking@>
  @<Step 3: Finish up after deleting RTBST node@>
}

@

The first step just finds the node to delete.  After it executes, |p| is
the node to delete and |q| and |dir| are set such that
|q->rtbst_link[dir] == p|.

@<Step 1: Find RTBST node to delete@> =
if (tree->rtbst_root == NULL)
  return NULL;

p = tree->rtbst_root;
q = (struct rtbst_node *) &tree->rtbst_root;
dir = 0;
if (p == NULL)
  return NULL;

for (;;) @
  {@-
    int cmp = tree->rtbst_compare (item, p->rtbst_data, tree->rtbst_param);
    if (cmp == 0) 
      break;

    dir = cmp > 0;
    if (dir == 0) @
      {@-
        if (p->rtbst_link[0] == NULL)
          return NULL;
      }@+ @
    else /* |dir == 1| */ @
      {@-
        if (p->rtbst_rtag == RTBST_THREAD)
          return NULL;
      }@+

    q = p;
    p = p->rtbst_link[dir];
  }@+
item = p->rtbst_data;

@

The final step is also common.  We just clean up and return:

@<Step 3: Finish up after deleting RTBST node@> =
tree->rtbst_alloc->libavl_free (tree->rtbst_alloc, p);
tree->rtbst_count--;
return (void *) item;
@

@menu
* Right-Looking Deletion in a RTBST::  
* Left-Looking Deletion in an RTBST::  
* Comparing Deletion Algorithms::  
@end menu

@node Right-Looking Deletion in a RTBST, Left-Looking Deletion in an RTBST, Deleting from an RTBST, Deleting from an RTBST
@subsection Right-Looking Deletion

Our usual algorithm for deletion looks at the right subtree of the node
to be deleted, so we call it ``right-looking.''  The outline for this
kind of deletion is the same as in TBST deletion (@pxref{Deleting from a
TBST}):

@cat rtbst Deletion, right-looking
@c tested 2001/11/10
@<Step 2: Delete RTBST node, right-looking@> =
if (p->rtbst_rtag == RTBST_THREAD) @
  {@-
    if (p->rtbst_link[0] != NULL)
      { @
        @<Case 1 in right-looking RTBST deletion@> @
      }
    else @
      { @
        @<Case 2 in right-looking RTBST deletion@> @
      }
  }@+ @
else @
  {@-
    struct rtbst_node *r = p->rtbst_link[1];
    if (r->rtbst_link[0] == NULL)
      { @
        @<Case 3 in right-looking RTBST deletion@> @
      }
    else @
      { @
        @<Case 4 in right-looking RTBST deletion@> @
      }
  }@+

@

Each of the four cases, presented below, is closely analogous to the
same case in TBST deletion.

@subsubheading Case 1: |p| has a right thread and a left child

In this case, node |p| has a right thread and a left child.  As in a
TBST, this means that after deleting |p| we must update the right thread
in |p|'s former left subtree to point to |p|'s replacement.  The only
difference from @<Case 1 in TBST deletion@> is in structure members:

@<Case 1 in right-looking RTBST deletion@> =
struct rtbst_node *t = p->rtbst_link[0];
while (t->rtbst_rtag == RTBST_CHILD)
  t = t->rtbst_link[1];
t->rtbst_link[1] = p->rtbst_link[1];
q->rtbst_link[dir] = p->rtbst_link[0];
@

@subsubheading Case 2: |p| has a right thread and no left child

If node |p| is a leaf, then there are two subcases, according to whether
|p| is a left child or a right child of its parent |q|.  If |dir| is 0,
then |p| is a left child and the pointer from its parent must be set to
|NULL|.  If |dir| is 1, then |p| is a right child and the link from its
parent must be changed to a thread to its successor.

In either of these cases we must set |q->rtbst_link[dir]|: if |dir| is
0, we set it to |NULL|, otherwise |dir| is 1 and we set it to
|p->rtbst_link[1]|.  However, we know that |p->rtbst_link[0]| is |NULL|,
because |p| is a leaf, so we can instead unconditionally assign
|p->rtbst_link[dir]|.  In addition, if |dir| is 1, then we must tag
|q|'s right link as a thread.

If |q| is the pseudo-root, then |dir| is 0 and everything works out fine
with no need for a special case.

@<Case 2 in right-looking RTBST deletion@> =
q->rtbst_link[dir] = p->rtbst_link[dir];
if (dir == 1)
  q->rtbst_rtag = RTBST_THREAD;
@

@subsubheading Case 3: |p|'s right child has no left child

Code for this case, where |p| has a right child |r| that itself has no
left child, is almost identical to @<Case 3 in TBST deletion@>.  There
is no left tag to copy, but it is still necessary to chase down the
right thread in |r|'s new left subtree (the same as |p|'s former left
subtree):

@<Case 3 in right-looking RTBST deletion@> =
r->rtbst_link[0] = p->rtbst_link[0];
if (r->rtbst_link[0] != NULL) @
  {@-
    struct rtbst_node *t = r->rtbst_link[0];
    while (t->rtbst_rtag == RTBST_CHILD)
      t = t->rtbst_link[1];
    t->rtbst_link[1] = r;
  }@+
q->rtbst_link[dir] = r;
@

@subsubheading Case 4: |p|'s right child has a left child

Code for case 4, the most general case, is very similar to @<Case 4 in
TBST deletion@>.  The only notable difference is in the subcase where
|s| has a right thread: in that case we just set |r|'s left link to
|NULL| instead of having to set it up as a thread.

@<Case 4 in right-looking RTBST deletion@> =
struct rtbst_node *s;

for (;;) @
  {@-
    s = r->rtbst_link[0];
    if (s->rtbst_link[0] == NULL)
      break;

    r = s;
  }@+

if (s->rtbst_rtag == RTBST_CHILD)
  r->rtbst_link[0] = s->rtbst_link[1];
else @
  r->rtbst_link[0] = NULL;

s->rtbst_link[0] = p->rtbst_link[0];
if (p->rtbst_link[0] != NULL) @
  {@-
    struct rtbst_node *t = p->rtbst_link[0];
    while (t->rtbst_rtag == RTBST_CHILD)
      t = t->rtbst_link[1];
    t->rtbst_link[1] = s;
  }@+

s->rtbst_link[1] = p->rtbst_link[1];
s->rtbst_rtag = RTBST_CHILD;

q->rtbst_link[dir] = s;    
@

@exercise
Rewrite @<Case 4 in right-looking RTBST deletion@> to replace the
deleted node's |rtavl_data| by its successor, then delete the successor,
instead of shuffling pointers.  (Refer back to @value{modifydata} for an
explanation of why this approach cannot be used in @libavl{}.)

@answer
@cat rtbst Deletion, with data modification, right-looking
@c tested 2002/1/6
@<Case 4 in right-looking RTBST deletion, alternate version@> =
struct rtbst_node *s = r->rtbst_link[0];
while (s->rtbst_link[0] != NULL) @
  {@-
    r = s;
    s = r->rtbst_link[0];
  }@+

p->rtbst_data = s->rtbst_data;

if (s->rtbst_rtag == RTBST_THREAD)
  r->rtbst_link[0] = NULL;
else @
  r->rtbst_link[0] = s->rtbst_link[1];

p = s;
@
@end exercise

@node Left-Looking Deletion in an RTBST, Comparing Deletion Algorithms, Right-Looking Deletion in a RTBST, Deleting from an RTBST
@subsection Left-Looking Deletion

The previous section implemented the ``right-looking'' form of
deletion used elsewhere in @libavl{}.  Compared to deletion in a fully
threaded binary tree, the benefits to using an RTBST with this kind of
deletion are minimal:

@itemize @bullet
@item
Cases 1 and 2 are similar code in both TBST and RTBST deletion.

@item
Case 3 in an RTBST avoids one tag copy required in TBST deletion.

@item
One subcase of case 4 in an RTBST avoids one tag assignment required in
the same subcase of TBST deletion.
@end itemize

This is hardly worth it.  We saved at most one assignment per call.  We
need something better if it's ever going to be worthwhile to use
right-threaded trees.

Fortunately, there is a way that we can save a little more.  This is
by changing our right-looking deletion into left-looking deletion, by
switching the use of left and right children in the algorithm.  In a
BST or TBST, this symmetrical change in the algorithm would have no
effect, because the BST and TBST node structures are themselves
symmetric.  But in an asymmetric RTBST even a symmetric change can
have a significant effect on an algorithm, as we'll see.

The cases for left-looking deletion are outlined in the same way as for
right-looking deletion:

@cat rtbst Deletion (left-looking)
@<Step 2: Delete RTBST node, left-looking@> =
if (p->rtbst_link[0] == NULL) @
  {@-
    if (p->rtbst_rtag == RTBST_CHILD)
      { @
        @<Case 1 in left-looking RTBST deletion@> @
      }
    else @
      { @
        @<Case 2 in left-looking RTBST deletion@> @
      }
  }@+ @
else @
  {@-
    struct rtbst_node *r = p->rtbst_link[0];
    if (r->rtbst_rtag == RTBST_THREAD)
      { @
        @<Case 3 in left-looking RTBST deletion@> @
      }
    else @
      { @
        @<Case 4 in left-looking RTBST deletion@> @
      }
  }@+

@

@subsubheading Case 1: |p| has a right child but no left child

If the node to delete |p| has a right child but no left child, we can
just replace it by its right child.  There is no right thread to update
in |p|'s left subtree because |p| has no left child, and there is no
left thread to update because a right-threaded tree has no left threads.

The deletion looks like this if |p|'s right child is designated |x|:

@center @image{rtbstdel}

@<Case 1 in left-looking RTBST deletion@> =
q->rtbst_link[dir] = p->rtbst_link[1];
@

@subsubheading Case 2: |p| has a right thread and no left child

This case is analogous to case 2 in right-looking deletion covered
earlier.  The same discussion applies.

@<Case 2 in left-looking RTBST deletion@> =
q->rtbst_link[dir] = p->rtbst_link[dir];
if (dir == 1)
  q->rtbst_rtag = RTBST_THREAD;
@

@subsubheading Case 3: |p|'s left child has a right thread

If |p| has a left child |r| that itself has a right thread, then we
replace |p| by |r|.  Node |r| receives |p|'s former right link, as shown
here:

@center @image{rtbstdel2}

There is no need to fiddle with threads.  If |r| has a right thread
then it gets replaced by |p|'s right child or thread anyhow.  Any
right thread within |r|'s left subtree either points within that
subtree or to |r|.  Finally, |r|'s right subtree cannot cause
problems.

@<Case 3 in left-looking RTBST deletion@> =
r->rtbst_link[1] = p->rtbst_link[1];
r->rtbst_rtag = p->rtbst_rtag;
q->rtbst_link[dir] = r;
@

@subsubheading Case 4: |p|'s left child has a right child

The final case handles deletion of a node |p| with a left child |r|
that in turn has a right child.  The code here follows the same
pattern as @<Case 4 in TBST deletion@> (see the discussion there for
details).  The first step is to find the predecessor |s| of node |p|:

@<Case 4 in left-looking RTBST deletion@> =
struct rtbst_node *s;

for (;;) @
  {@-
    s = r->rtbst_link[1];
    if (s->rtbst_rtag == RTBST_THREAD)
      break;

    r = s;
  }@+

@

Next, we update |r|, handling two subcases depending on whether |s| has
a left child:

@<Case 4 in left-looking RTBST deletion@> +=
if (s->rtbst_link[0] != NULL)
  r->rtbst_link[1] = s->rtbst_link[0];
else @
  {@-
    r->rtbst_link[1] = s;
    r->rtbst_rtag = RTBST_THREAD;
  }@+

@

The final step is to copy |p|'s fields into |s|, then set |q|'s child
pointer to point to |s| instead of |p|.  There is no need to chase down
any threads.

@<Case 4 in left-looking RTBST deletion@> +=
s->rtbst_link[0] = p->rtbst_link[0];
s->rtbst_link[1] = p->rtbst_link[1];
s->rtbst_rtag = p->rtbst_rtag;

q->rtbst_link[dir] = s;    
@

@exercise
Rewrite @<Case 4 in left-looking RTBST deletion@> to replace the deleted
node's |rtavl_data| by its predecessor, then delete the predecessor,
instead of shuffling pointers.  (Refer back to @value{modifydata} for an
explanation of why this approach cannot be used in @libavl{}.)

@answer
This alternate version is not really an improvement: it runs up against
the same problem as right-looking deletion, so it sometimes needs to
search for a predecessor.

@cat rtbst Deletion, with data modification, left-looking
@c tested 2001/11/10
@<Case 4 in left-looking RTBST deletion, alternate version@> =
struct rtbst_node *s = r->rtbst_link[1];
while (s->rtbst_rtag == RTBST_CHILD) @
  {@-
    r = s;
    s = r->rtbst_link[1];
  }@+

p->rtbst_data = s->rtbst_data;

if (s->rtbst_link[0] != NULL) @
  {@-
    struct rtbst_node *t = s->rtbst_link[0];
    while (t->rtbst_rtag == RTBST_CHILD)
      t = t->rtbst_link[1];
    t->rtbst_link[1] = p;
    r->rtbst_link[1] = s->rtbst_link[0];
  }@+ @
else @
  {@-
    r->rtbst_link[1] = p;
    r->rtbst_rtag = RTBST_THREAD;
  }@+

p = s;
@
@end exercise

@node Comparing Deletion Algorithms,  , Left-Looking Deletion in an RTBST, Deleting from an RTBST
@subsection Aside: Comparison of Deletion Algorithms

This book has presented algorithms for deletion from BSTs, TBSTs, and
RTBSTs.  In fact, we implemented two algorithms for RTBSTs.  Each of
these four algorithms has slightly different performance
characteristics.  The following table summarizes the behavior of all
of the cases in these algorithms.  Each cell describes the actions
that take place: ``link'' is the number of link fields set, ``tag''
the number of tag fields set, and ``succ/pred'' the number of general
successor or predecessors found during the case.

@multitable @columnfractions .05 .15 .2 .2 .2 .2
@item
@tab
@tab BST*
@tab TBST
@tab Right-Looking @* TBST
@tab Left-Looking @* TBST @* @w{ }

@item
@tab Case 1
@tab 1 link
@tab 2 links @* 1 succ/pred @* @w{ }
@tab 2 links @* 1 succ/pred
@tab 1 link

@item
@tab Case 2
@tab 1 link
@tab 1 link @* 1 tag @* @w{ }
@tab 1 link @* 1 tag
@tab 1 link @* 1 tag

@item
@tab Case 3
@tab 2 links
@tab 3 links @* 1 tag @* 1 succ/pred @* @w{ }
@tab 3 links @* @w{ } @* 1 succ/pred
@tab 2 links @* 1 tag

@item 
@tab Case 4 @* subcase 1
@tab 4 links @* @w{ } @* 1 succ/pred
@tab 5 links @* 2 tags @* 2 succ/pred @* @w{ }
@tab 5 links @* 1 tag @* 2 succ/pred
@tab 4 links @* 1 tag @* 1 succ/pred

@item
@tab Case 4 @* subcase 2
@tab 4 links @* @w{ } @* 1 succ/pred
@tab 5 links @* 2 tags @* 2 succ/pred @* @w{ }
@tab 5 links @* 1 tag @* 2 succ/pred
@tab 4 links @* 1 tag @* 1 succ/pred
@end multitable

@quotation
@little{* Listed cases 1 and 2 both correspond to BST deletion case 1,
and listed cases 3 and 4 to BST deletion cases 2 and 3, respectively.
BST deletion does not have any subcases in its case 3 (listed case 4),
so it also saves a test to distinguish subcases.}
@end quotation

As you can see, the penalty for left-looking deletion from a RTBST,
compared to a plain BST, is at most one tag assignment in any given
case, except for the need to distinguish subcases of case 4.  In this
sense at least, left-looking deletion from an RTBST is considerably
faster than deletion from a TBST or right-looking deletion from a
RTBST.  This means that it can indeed be worthwhile to implement
right-threaded trees instead of BSTs or TBSTs.

@node Traversing an RTBST, Copying an RTBST, Deleting from an RTBST, Right-Threaded Binary Search Trees
@section Traversal

Traversal in an RTBST is unusual due to its asymmetry.  Moving from
smaller nodes to larger nodes is easy: we do it with the same algorithm
used in a TBST.  Moving the other way is more difficult and inefficient
besides: we have neither a stack of parent nodes to fall back on nor
left threads to short-circuit.

RTBSTs use the same traversal structure as TBSTs, so we can reuse some
of the functions from TBST traversers.  We also get a few directly from
the implementations for BSTs.  Other than that, everything has to be
written anew here:

@<RTBST traversal functions@> =
@<TBST traverser null initializer; tbst => rtbst@>
@<RTBST traverser first initializer@>
@<RTBST traverser last initializer@>
@<RTBST traverser search initializer@>
@<TBST traverser insertion initializer; tbst => rtbst@>
@<TBST traverser copy initializer; tbst => rtbst@>
@<RTBST traverser advance function@>
@<RTBST traverser back up function@>
@<BST traverser current item function; bst => rtbst@>
@<BST traverser replacement function; bst => rtbst@>
@

@menu
* RTBST Traverser First Initialization::  
* RTBST Traverser Last Initialization::  
* RTBST Traverser Find Initialization::  
* RTBST Traverser Advancing::   
* RTBST Traverser Retreating::  
@end menu

@node RTBST Traverser First Initialization, RTBST Traverser Last Initialization, Traversing an RTBST, Traversing an RTBST
@subsection Starting at the First Node

To find the first (least) item in the tree, we just descend all the way
to the left, as usual.  In an RTBST, as in a BST, this involves checking
for null pointers.

@cat rtbst Initialization of traverser to least item
@<RTBST traverser first initializer@> =
@iftangle
/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the least value, @
   or |NULL| if |tree| is empty. */
@end iftangle
void *@
rtbst_t_first (struct rtbst_traverser *trav, struct rtbst_table *tree) @
{
  assert (tree != NULL && trav != NULL);

  trav->rtbst_table = tree;
  trav->rtbst_node = tree->rtbst_root;
  if (trav->rtbst_node != NULL) @
    {@-
      while (trav->rtbst_node->rtbst_link[0] != NULL)
	trav->rtbst_node = trav->rtbst_node->rtbst_link[0];
      return trav->rtbst_node->rtbst_data;
    }@+
  else @
    return NULL;
}

@

@node RTBST Traverser Last Initialization, RTBST Traverser Find Initialization, RTBST Traverser First Initialization, Traversing an RTBST
@subsection Starting at the Last Node

To start at the last (greatest) item in the tree, we descend all the way
to the right.  In an RTBST, as in a TBST, this involves checking for
thread links.

@cat rtbst Initialization of traverser to greatest item
@<RTBST traverser last initializer@> =
@iftangle
/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the greatest value, @
   or |NULL| if |tree| is empty. */
@end iftangle
void *@
rtbst_t_last (struct rtbst_traverser *trav, struct rtbst_table *tree) @
{
  assert (tree != NULL && trav != NULL);

  trav->rtbst_table = tree;
  trav->rtbst_node = tree->rtbst_root;
  if (trav->rtbst_node != NULL) @
    {@-
      while (trav->rtbst_node->rtbst_rtag == RTBST_CHILD)
	trav->rtbst_node = trav->rtbst_node->rtbst_link[1];
      return trav->rtbst_node->rtbst_data;
    }@+
  else @
    return NULL;
}

@

@node RTBST Traverser Find Initialization, RTBST Traverser Advancing, RTBST Traverser Last Initialization, Traversing an RTBST
@subsection Starting at a Found Node

To start from an item found in the tree, we use the same algorithm as
|rtbst_find()|.

@cat rtbst Initialization of traverser to found item
@<RTBST traverser search initializer@> =
@iftangle
/* Searches for |item| in |tree|.
   If found, initializes |trav| to the item found and returns the item @
   as well.
   If there is no matching item, initializes |trav| to the null item @
   and returns |NULL|. */
@end iftangle
void *@
rtbst_t_find (struct rtbst_traverser *trav, struct rtbst_table *tree, @
              void *item) @
{
  struct rtbst_node *p;

  assert (trav != NULL && tree != NULL && item != NULL);

  trav->rtbst_table = tree;
  trav->rtbst_node = NULL;

  p = tree->rtbst_root;
  if (p == NULL)
    return NULL;

  for (;;) @
    {@-
      int cmp = tree->rtbst_compare (item, p->rtbst_data, tree->rtbst_param);
      if (cmp == 0) @
	{@-
	  trav->rtbst_node = p;
	  return p->rtbst_data;
	}@+

      if (cmp < 0) @
	{@-
	  p = p->rtbst_link[0];
	  if (p == NULL)
	    return NULL;
	}@+ @
      else @
	{@-
	  if (p->rtbst_rtag == RTBST_THREAD)
	    return NULL;
	  p = p->rtbst_link[1];
	}@+
    }@+
}

@

@node RTBST Traverser Advancing, RTBST Traverser Retreating, RTBST Traverser Find Initialization, Traversing an RTBST
@subsection Advancing to the Next Node

We use the same algorithm to advance an RTBST traverser as for TBST
traversers.  The only important difference between this code and @<TBST
traverser advance function@> is the substitution of |rtbst_rtag| for
|tbst_tag[1]|.

@cat rtbst Advancing a traverser
@<RTBST traverser advance function@> =
@iftangle
/* Returns the next data item in inorder @
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
@end iftangle
void *@
rtbst_t_next (struct rtbst_traverser *trav) @
{
  assert (trav != NULL);

  if (trav->rtbst_node == NULL)
    return rtbst_t_first (trav, trav->rtbst_table);
  else if (trav->rtbst_node->rtbst_rtag == RTBST_THREAD) @
    {@-
      trav->rtbst_node = trav->rtbst_node->rtbst_link[1];
      return trav->rtbst_node != NULL ? trav->rtbst_node->rtbst_data : NULL;
    }@+ @
  else @
    {@-
      trav->rtbst_node = trav->rtbst_node->rtbst_link[1];
      while (trav->rtbst_node->rtbst_link[0] != NULL)
	trav->rtbst_node = trav->rtbst_node->rtbst_link[0];
      return trav->rtbst_node->rtbst_data;
    }@+
}

@

@node RTBST Traverser Retreating,  , RTBST Traverser Advancing, Traversing an RTBST
@subsection Backing Up to the Previous Node

Moving an RTBST traverser backward has the same cases as in the other
ways of finding an inorder predecessor that we've already discussed.
The two main cases are distinguished on whether the current item has a
left child; the third case comes up when there is no current item,
implemented simply by delegation to |rtbst_t_last()|:

@cat rtbst Backing up a traverser
@<RTBST traverser back up function@> =
@iftangle
/* Returns the previous data item in inorder @
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
@end iftangle
void *@
rtbst_t_prev (struct rtbst_traverser *trav) @
{
  assert (trav != NULL);

  if (trav->rtbst_node == NULL)
    return rtbst_t_last (trav, trav->rtbst_table);
  else if (trav->rtbst_node->rtbst_link[0] == NULL) @
    {@-
      @<Find predecessor of RTBST node with no left child@>
    }@+ @
  else @
    {@-
      @<Find predecessor of RTBST node with left child@>
    }@+
}

@

The novel case is where the node |p| whose predecessor we want has no
left child.  In this case, we use a modified version of the algorithm
originally specified for finding a node's successor in an unthreaded
tree (@pxref{Better Iterative Traversal}).  We take the idea of
moving up until we've moved up to the left, and turn it upside down (to
avoid need for a parent stack) and reverse it (to find the predecessor
instead of the successor).

The idea here is to trace |p|'s entire direct ancestral line.  Starting
from the root of the tree, we repeatedly compare each node's data with
|p|'s and use the result to move downward, until we encounter node |p|
itself.  Each time we move down from a node |x| to its right child, we
record |x| as the potential predecessor of |p|.  When we finally arrive
at |p|, the last node so selected is the actual predecessor, or if none
was selected then |p| is the least node in the tree and we select the
null item as its predecessor.

Consider this algorithm in the context of the tree shown here:

@center @image{rtbstprev}

@noindent
To find the predecessor of node 8, we trace the path from the root
down to it: 3-9-5-7-8.  The last time we move down to the right is
from 7 to 8, so 7 is node 8's predecessor.  To find the predecessor of
node 6, we trace the path 3-9-5-7-6 and notice that we last move down
to the right from 5 to 7, so 5 is node 6's predecessor.  Finally, node
0 has the null item as its predecessor because path 3-1-0 does not
involve any rightward movement.

Here is the code to implement this case:

@<Find predecessor of RTBST node with no left child@> =
rtbst_comparison_func *cmp = trav->rtbst_table->rtbst_compare;
void *param = trav->rtbst_table->rtbst_param;
struct rtbst_node *node = trav->rtbst_node;
struct rtbst_node *i;

trav->rtbst_node = NULL;
for (i = trav->rtbst_table->rtbst_root; i != node; ) @
  {@-
    int dir = cmp (node->rtbst_data, i->rtbst_data, param) > 0;
    if (dir == 1)
      trav->rtbst_node = i;
    i = i->rtbst_link[dir];
  }@+

return trav->rtbst_node != NULL ? trav->rtbst_node->rtbst_data : NULL;
@

The other case, where the node whose predecessor we want has a left
child, is nothing new.  We just find the largest node in the node's left
subtree:

@<Find predecessor of RTBST node with left child@> =
trav->rtbst_node = trav->rtbst_node->rtbst_link[0];
while (trav->rtbst_node->rtbst_rtag == RTBST_CHILD)
  trav->rtbst_node = trav->rtbst_node->rtbst_link[1];
return trav->rtbst_node->rtbst_data;
@

@node Copying an RTBST, Destroying an RTBST, Traversing an RTBST, Right-Threaded Binary Search Trees
@section Copying

The algorithm that we used for copying a TBST makes use of threads, but
only right threads, so we can apply this algorithm essentially
unmodified to RTBSTs.  

We will make one change that superficially simplifies and improves the
elegance of the algorithm.  Function |tbst_copy()| in @<TBST main copy
function@> uses a pair of local variables |rp| and |rq| to store
pointers to the original and new tree's root, because accessing the tag
field of a cast ``pseudo-root'' pointer produces undefined behavior.
However, in an RTBST there is no tag for a node's left subtree.  During
a TBST copy, only the left tags of the root nodes are accessed, so this
means that we can use the pseudo-roots in the RTBST copy, with no need
for |rp| or |rq|.

@<RTBST main copy function@> =
@iftangle
/* Copies |org| to a newly created tree, which is returned.
   If |copy != NULL|, each data item in |org| is first passed to |copy|,
   and the return values are inserted into the tree,
   with |NULL| return values are taken as indications of failure.
   On failure, destroys the partially created new tree,
   applying |destroy|, if non-null, to each item in the new tree so far, 
   and returns |NULL|.
   If |allocator != NULL|, it is used for allocation in the new tree.
   Otherwise, the same allocator used for |org| is used. */
@end iftangle
struct rtbst_table *@
rtbst_copy (const struct rtbst_table *org, rtbst_copy_func *copy,
            rtbst_item_func *destroy, struct libavl_allocator *allocator)
{
  struct rtbst_table *new;

  const struct rtbst_node *p;
  struct rtbst_node *q;

  assert (org != NULL);
  new = rtbst_create (org->rtbst_compare, org->rtbst_param,
		     allocator != NULL ? allocator : org->rtbst_alloc);
  if (new == NULL)
    return NULL;

  new->rtbst_count = org->rtbst_count;
  if (new->rtbst_count == 0)
    return new;

  p = (struct rtbst_node *) &org->rtbst_root;
  q = (struct rtbst_node *) &new->rtbst_root;
  for (;;) @
    {@-
      if (p->rtbst_link[0] != NULL) @
	{@-
	  if (!copy_node (new, q, 0, p->rtbst_link[0], copy)) @
	    {@-
	      copy_error_recovery (new, destroy);
	      return NULL;
	    }@+

	  p = p->rtbst_link[0];
	  q = q->rtbst_link[0];
	}@+ @
      else @
	{@-
	  while (p->rtbst_rtag == RTBST_THREAD) @
	    {@-
	      p = p->rtbst_link[1];
	      if (p == NULL) @
		{@-
		  q->rtbst_link[1] = NULL;
		  return new;
		}@+

	      q = q->rtbst_link[1];
	    }@+

	  p = p->rtbst_link[1];
	  q = q->rtbst_link[1];
	}@+

      if (p->rtbst_rtag == RTBST_CHILD)
	if (!copy_node (new, q, 1, p->rtbst_link[1], copy)) @
	  {@-
	    copy_error_recovery (new, destroy);
	    return NULL;
	  }@+
    }@+
}

@

The code to copy a node must be modified to deal with the asymmetrical
nature of insertion in an RTBST:

@cat rtbst Copying a node
@<RTBST node copy function@> =
@iftangle
/* Creates a new node as a child of |dst| on side |dir|.
   Copies data from |src| into the new node, applying |copy()|, if non-null.
   Returns nonzero only if fully successful.
   Regardless of success, integrity of the tree structure is assured,
   though failure may leave a null pointer in a |rtbst_data| member. */
@end iftangle
static int @
copy_node (struct rtbst_table *tree, @
	   struct rtbst_node *dst, int dir,
	   const struct rtbst_node *src, rtbst_copy_func *copy) @
{
  struct rtbst_node *new = @
    tree->rtbst_alloc->libavl_malloc (tree->rtbst_alloc, sizeof *new);
  if (new == NULL)
    return 0;

  new->rtbst_link[0] = NULL;
  new->rtbst_rtag = RTBST_THREAD;
  if (dir == 0)
    new->rtbst_link[1] = dst;
  else @
    {@-
      new->rtbst_link[1] = dst->rtbst_link[1];
      dst->rtbst_rtag = RTBST_CHILD;
    }@+
  dst->rtbst_link[dir] = new;

  if (copy == NULL)
    new->rtbst_data = src->rtbst_data;
  else @
    {@-
      new->rtbst_data = copy (src->rtbst_data, tree->rtbst_param);
      if (new->rtbst_data == NULL)
	return 0;
    }@+

  return 1;
}

@

The error recovery function for copying is a bit simpler now, because
the use of the pseudo-root means that no assignment to the new tree's
root need take place, eliminating the need for one of the function's
parameters:

@<RTBST copy error helper function@> =
@iftangle
/* Destroys |new| with |rtbst_destroy (new, destroy)|,
   first initializing right links in |new| that have
   not yet been initialized at time of call. */
@end iftangle
static void @
copy_error_recovery (struct rtbst_table *new, rtbst_item_func *destroy) @
{
  struct rtbst_node *p = new->rtbst_root;
  if (p != NULL) @
    {@-
      while (p->rtbst_rtag == RTBST_CHILD)
	p = p->rtbst_link[1];
      p->rtbst_link[1] = NULL;
    }@+
  rtbst_destroy (new, destroy);
}

@

@cat rtbst Copying
@<RTBST copy function@> =
@<RTBST node copy function@>
@<RTBST copy error helper function@>
@<RTBST main copy function@>
@

@node Destroying an RTBST, Balancing an RTBST, Copying an RTBST, Right-Threaded Binary Search Trees
@section Destruction

The destruction algorithm for TBSTs makes use only of right threads, so
we can easily adapt it for RTBSTs.

@cat rtbst Destruction
@<RTBST destruction function@> =
@iftangle
/* Frees storage allocated for |tree|.
   If |destroy != NULL|, applies it to each data item in inorder. */
@end iftangle
void @
rtbst_destroy (struct rtbst_table *tree, rtbst_item_func *destroy) @
{
  struct rtbst_node *p; /* Current node. */
  struct rtbst_node *n; /* Next node. */

  p = tree->rtbst_root;
  if (p != NULL)
    while (p->rtbst_link[0] != NULL)
      p = p->rtbst_link[0];

  while (p != NULL) @
    {@-
      n = p->rtbst_link[1];
      if (p->rtbst_rtag == RTBST_CHILD)
	while (n->rtbst_link[0] != NULL)
	  n = n->rtbst_link[0];

      if (destroy != NULL && p->rtbst_data != NULL) 
	destroy (p->rtbst_data, tree->rtbst_param);
      tree->rtbst_alloc->libavl_free (tree->rtbst_alloc, p);

      p = n;
    }@+

  tree->rtbst_alloc->libavl_free (tree->rtbst_alloc, tree);
}

@

@node Balancing an RTBST, Testing RTBSTs, Destroying an RTBST, Right-Threaded Binary Search Trees
@section Balance

As for so many other operations, we can reuse most of the TBST balancing
code to rebalance RTBSTs.  Some of the helper functions can be
completely recycled:

@cat rtbst Balancing
@<RTBST balance function@> =
@<RTBST tree-to-vine function@>
@<RTBST vine compression function@>
@<TBST vine-to-tree function; tbst => rtbst@>
@<TBST main balance function; tbst => rtbst@>
@

The only substantative difference for the remaining two functions is
that there is no need to set nodes' left tags (since they don't have
any):

@cat rtbst Vine from tree
@<RTBST tree-to-vine function@> =
static void @
tree_to_vine (struct rtbst_table *tree) @
{
  struct rtbst_node *p;

  if (tree->rtbst_root == NULL)
    return;

  p = tree->rtbst_root;
  while (p->rtbst_link[0] != NULL)
    p = p->rtbst_link[0];

  for (;;) @
    {@-
      struct rtbst_node *q = p->rtbst_link[1];
      if (p->rtbst_rtag == RTBST_CHILD) @
	{@-
	  while (q->rtbst_link[0] != NULL)
	    q = q->rtbst_link[0];
	  p->rtbst_rtag = RTBST_THREAD;
	  p->rtbst_link[1] = q;
	}@+

      if (q == NULL)
	break;

      q->rtbst_link[0] = p;
      p = q;
    }@+

  tree->rtbst_root = p;
}

@

@cat rtbst Vine compression
@<RTBST vine compression function@> =
/* Performs a compression transformation |count| times, @
   starting at |root|. */
static void @
compress (struct rtbst_node *root,
          unsigned long nonthread, unsigned long thread) @
{
  assert (root != NULL);

  while (nonthread--) @
    {@-
      struct rtbst_node *red = root->rtbst_link[0];
      struct rtbst_node *black = red->rtbst_link[0];

      root->rtbst_link[0] = black;
      red->rtbst_link[0] = black->rtbst_link[1];
      black->rtbst_link[1] = red;
      root = black;
    }@+

  while (thread--) @
    {@-
      struct rtbst_node *red = root->rtbst_link[0];
      struct rtbst_node *black = red->rtbst_link[0];

      root->rtbst_link[0] = black;
      red->rtbst_link[0] = NULL;
      black->rtbst_rtag = RTBST_CHILD;
      root = black;
    }@+
}

@

@node Testing RTBSTs,  , Balancing an RTBST, Right-Threaded Binary Search Trees
@section Testing

There's nothing new or interesting in the test code.

@(rtbst-test.c@> =
@<Program License@>
#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include "rtbst.h"
#include "test.h"

@<RTBST print function@>
@<BST traverser check function; bst => rtbst@>
@<Compare two RTBSTs for structure and content@>
@<Recursively verify RTBST structure@>
@<BST verify function; bst => rtbst@>
@<TBST test function; tbst => rtbst@>
@<BST overflow test function; bst => rtbst@>
@

@<RTBST print function@> =
@iftangle
/* Prints the structure of |node|, @
   which is |level| levels from the top of the tree. */
@end iftangle
void @
print_tree_structure (struct rtbst_node *node, int level) @
{
@iftangle
  /* You can set the maximum level as high as you like.
     Most of the time, you'll want to debug code using small trees,
     so that a large |level| indicates a ``loop'', which is a bug. */
@end iftangle
  if (level > 16) @
    {@-
      printf ("[...]");
      return;
    }@+

  if (node == NULL) @
    {@-
      printf ("<nil>");
      return;
    }@+

  printf ("%d(", node->rtbst_data ? *(int *) node->rtbst_data : -1);

  if (node->rtbst_link[0] != NULL)
    print_tree_structure (node->rtbst_link[0], level + 1);

  fputs (", ", stdout);
  
  if (node->rtbst_rtag == RTBST_CHILD) @
    {@-
      if (node->rtbst_link[1] == node) 
	printf ("loop");
      else @
	print_tree_structure (node->rtbst_link[1], level + 1);
    }@+ 
  else if (node->rtbst_link[1] != NULL) @
    printf (">%d", @
	    (node->rtbst_link[1]->rtbst_data
	     ? *(int *) node->rtbst_link[1]->rtbst_data : -1));
  else @
    printf (">>");

  putchar (')');
}

@iftangle
/* Prints the entire structure of |tree| with the given |title|. */
@end iftangle
void @
print_whole_tree (const struct rtbst_table *tree, const char *title) @
{
  printf ("%s: ", title);
  print_tree_structure (tree->rtbst_root, 0);
  putchar ('\n');
}

@

@<Compare two RTBSTs for structure and content@> =
@iftangle
/* Compares binary trees rooted at |a| and |b|, 
   making sure that they are identical. */
@end iftangle
static int @
compare_trees (struct rtbst_node *a, struct rtbst_node *b) @
{
  int okay;

  if (a == NULL || b == NULL) @
    {@-
      if (a != NULL || b != NULL) @
	{@-
	  printf (" a=%d b=%d\n",
		  a ? *(int *) a->rtbst_data : -1, 
		  b ? *(int *) b->rtbst_data : -1);
	  assert (0);
	}@+
      return 1;
    }@+
  assert (a != b);

  if (*(int *) a->rtbst_data != *(int *) b->rtbst_data
      || a->rtbst_rtag != b->rtbst_rtag) @
    {@-
      printf (" Copied nodes differ: a=%d b=%d a:",
	      *(int *) a->rtbst_data, *(int *) b->rtbst_data);

      if (a->rtbst_rtag == RTBST_CHILD) @
	printf ("r");

      printf (" b:");
      if (b->rtbst_rtag == RTBST_CHILD) @
	printf ("r");

      printf ("\n");
      return 0;
    }@+

  if (a->rtbst_rtag == RTBST_THREAD)
    assert ((a->rtbst_link[1] == NULL)
	    != (a->rtbst_link[1] != b->rtbst_link[1]));

  okay = compare_trees (a->rtbst_link[0], b->rtbst_link[0]);
  if (a->rtbst_rtag == RTBST_CHILD)
    okay &= compare_trees (a->rtbst_link[1], b->rtbst_link[1]);
  return okay;
}

@

@<Recursively verify RTBST structure@> =
@iftangle
/* Examines the binary tree rooted at |node|.  
   Zeroes |*okay| if an error occurs.  @
   Otherwise, does not modify |*okay|.
   Sets |*count| to the number of nodes in that tree, @
   including |node| itself if |node != NULL|.
   All the nodes in the tree are verified to be at least |min| @
   but no greater than |max|. */
@end iftangle
static void @
recurse_verify_tree (struct rtbst_node *node, int *okay, size_t *count, 
                     int min, int max) @
{
  int d;                /* Value of this node's data. */
  size_t subcount[2];   /* Number of nodes in subtrees. */

  if (node == NULL) @
    {@-
      *count = 0;
      return;
    }@+
  d = *(int *) node->rtbst_data;

  @<Verify binary search tree ordering@>

  subcount[0] = subcount[1] = 0;
  recurse_verify_tree (node->rtbst_link[0], okay, &subcount[0], min, d - 1);
  if (node->rtbst_rtag == RTBST_CHILD)
    recurse_verify_tree (node->rtbst_link[1], okay, &subcount[1], d + 1, max);
  *count = 1 + subcount[0] + subcount[1];
}

@
