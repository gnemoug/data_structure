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

@deftypedef pbst_comparison_func
@deftypedef pbst_item_func
@deftypedef pbst_copy_func

@node BSTs with Parent Pointers, AVL Trees with Parent Pointers, Right-Threaded Red-Black Trees, Top
@chapter BSTs with Parent Pointers

The preceding six chapters introduced two different forms of threaded
trees, which simplified traversal by eliminating the need for a stack.
There is another way to accomplish the same purpose: add to each node
a @gloss{parent pointer}, a link from the node to its parent.  A
binary search tree so augmented is called a BST with parent pointers,
or PBST for short.@footnote{This abbreviation might be thought of as
expanding to ``parented BST'' or ``parental BST'', but those are not
proper terms.}  In this chapter, we show how to add parent pointers to
binary trees.  The next two chapters will add them to AVL trees and
red-black trees.

Parent pointers and threads have equivalent power.  That is, given a
node within a threaded tree, we can find the node's parent, and given
a node within a tree with parent pointers, we can determine the
targets of any threads that the node would have in a similar threaded
tree.

Parent pointers have some advantages over threads.  In particular,
parent pointers let us more efficiently eliminate the stack for
insertion and deletion in balanced trees.  Rebalancing during these
operations requires us to locate the parents of nodes.  In our
implementations of threaded balanced trees, we wrote code to do this,
but it took a relatively complicated and slow helper function.  Parent
pointers make it much faster and easier.  It is also easier to search
a tree with parent pointers than a threaded tree, because there is no
need to check tags.  Outside of purely technical issues, many people
find the use of parent pointers more intuitive than threads.

On the other hand, to traverse a tree with parent pointers in inorder
we may have to follow several parent pointers instead of a single
thread.  What's more, parent pointers take extra space for a third
pointer field in every node, whereas the tag fields in threaded
balanced trees often fit into node structures without taking up
additional room (see @value{tavlnodesize}).  Finally, maintaining
parent pointers on insertion and deletion takes time.  In fact, we'll
see that it takes more operations (and thus, all else being equal,
time) than maintaining threads.

In conclusion, a general comparison of parent pointers with threads
reveals no clear winner.  Further discussion of the merits of parent
pointers versus those of threads will be postponed until later in this
book.  For now, we'll stick to the problems of parent pointer
implementation.

Here's the outline of the PBST code.  We're using the prefix |pbst_|
this time:

@(pbst.h@> =
@<Library License@>
#ifndef PBST_H
#define PBST_H 1

#include <stddef.h>

@<Table types; tbl => pbst@>
@<TBST table structure; tbst => pbst@>
@<PBST node structure@>
@<TBST traverser structure; tbst => pbst@>
@<Table function prototypes; tbl => pbst@>
@<BST extra function prototypes; bst => pbst@>

#endif /* pbst.h */
@ 

@(pbst.c@> =
@<Library License@>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "pbst.h"

@<PBST functions@>
@

@menu
* PBST Data Types::             
* PBST Operations::             
* Inserting into a PBST::       
* Deleting from a PBST::        
* Traversing a PBST::           
* Copying a PBST::              
* Balancing a PBST::            
* Testing PBSTs::               
@end menu

@node PBST Data Types, PBST Operations, BSTs with Parent Pointers, BSTs with Parent Pointers
@section Data Types

For PBSTs we reuse TBST table and traverser structures.  In fact, the
only data type that needs revision is the node structure.  We take the
basic form of a node and add a member |pbst_parent| to point to its
parent node:

@<PBST node structure@> =
/* A binary search tree with parent pointers node. */
struct pbst_node @
  {@-
    struct pbst_node *pbst_link[2];   /* Subtrees. */
    struct pbst_node *pbst_parent;    /* Parent. */
    void *pbst_data;                  /* Pointer to data. */
  };@+

@

There is one special case: what should be the value of |pbst_parent|
for a node that has no parent, that is, in the tree's root?  There are
two reasonable choices.  

First, |pbst_parent| could be |NULL| in the root.  This makes it easy
to check whether a node is the tree's root.  On the other hand, we
often follow a parent pointer in order to change the link down from
the parent, and |NULL| as the root node's |pbst_parent| requires a
special case.

We can eliminate this special case if the root's |pbst_parent| is the
tree's pseudo-root node, that is, |(struct pbst_node *)
&tree->pbst_root|.  The downside of this choice is that it becomes
uglier, and perhaps slower, to check whether a node is the tree's
root, because a comparison must be made against a non-constant
expression instead of simply |NULL|.

In this book, we make the former choice, so |pbst_parent| is |NULL|
in the tree's root node.

@references
@bibref{Cormen 1990}, section 11.4.

@node PBST Operations, Inserting into a PBST, PBST Data Types, BSTs with Parent Pointers
@section Operations

When we added parent pointers to BST nodes, we did not change the
interpretation of any of the node members.  This means that any
function that examines PBSTs without modifying them will work without
change.  We take advantage of that for tree search.  We also get away
with it for destruction, since there's no problem with failing to
update parent pointers in that case.  Although we could, technically,
do the same for traversal, that would negate much of the advantage of
parent pointers, so we reimplement them.  Here is the overall outline:

@<PBST functions@> =
@<TBST creation function; tbst => pbst@>
@<BST search function; bst => pbst@>
@<PBST item insertion function@>
@<Table insertion convenience functions; tbl => pbst@>
@<PBST item deletion function@>
@<PBST traversal functions@>
@<PBST copy function@>
@<BST destruction function; bst => pbst@>
@<PBST balance function@>
@<Default memory allocation functions; tbl => pbst@>
@<Table assertion functions; tbl => pbst@>
@

@node Inserting into a PBST, Deleting from a PBST, PBST Operations, BSTs with Parent Pointers
@section Insertion

The only difference between this code and @<BST item insertion
function@> is that we set |n|'s parent pointer after insertion.

@cat pbst Insertion
@<PBST item insertion function@> =
@iftangle
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree, 
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
@end iftangle
void **@
pbst_probe (struct pbst_table *tree, void *item) @
{
  struct pbst_node *p, *q; /* Current node in search and its parent. */
  int dir;                 /* Side of |q| on which |p| is located. */
  struct pbst_node *n;     /* Newly inserted node. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Search PBST tree for insertion point@>
  @<Step 2: Insert PBST node@>

  return &n->pbst_data;
}

@

@<Step 1: Search PBST tree for insertion point@> =
for (q = NULL, p = tree->pbst_root; p != NULL; q = p, p = p->pbst_link[dir]) @
  {@-
    int cmp = tree->pbst_compare (item, p->pbst_data, tree->pbst_param);
    if (cmp == 0)
      return &p->pbst_data;
    dir = cmp > 0;
  }@+

@

@<Step 2: Insert PBST node@> =
n = tree->pbst_alloc->libavl_malloc (tree->pbst_alloc, sizeof *p);
if (n == NULL)
  return NULL;

tree->pbst_count++;
n->pbst_link[0] = n->pbst_link[1] = NULL;
n->pbst_parent = q;
n->pbst_data = item;
if (q != NULL)
  q->pbst_link[dir] = n;
else @
  tree->pbst_root = n;
@

@references
@bibref{Cormen 1990}, section 13.3.

@node Deleting from a PBST, Traversing a PBST, Inserting into a PBST, BSTs with Parent Pointers
@section Deletion

The new aspect of deletion in a PBST is that we must properly adjust
parent pointers.  The outline is the same as usual:

@cat pbst Deletion
@<PBST item deletion function@> =
@iftangle
/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
@end iftangle
void *@
pbst_delete (struct pbst_table *tree, const void *item) @
{
  struct pbst_node *p; /* Traverses tree to find node to delete. */
  struct pbst_node *q; /* Parent of |p|. */
  int dir;             /* Side of |q| on which |p| is linked. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Find PBST node to delete@>
  @<Step 2: Delete PBST node@>
  @<Step 3: Finish up after deleting PBST node@>
}

@

We find the node to delete by using |p| to search for |item|.  For the
first time in implementing a deletion routine, we do not keep track of
the current node's parent, because we can always find it out later
with little effort:

@<Step 1: Find PBST node to delete@> =
if (tree->pbst_root == NULL)
  return NULL;

p = tree->pbst_root;
for (;;) @
  {@-
    int cmp = tree->pbst_compare (item, p->pbst_data, tree->pbst_param);
    if (cmp == 0)
      break;

    dir = cmp > 0;
    p = p->pbst_link[dir];
    if (p == NULL)
      return NULL;
  }@+
item = p->pbst_data;

@

Now we've found the node to delete, |p|.  The first step in deletion
is to find the parent of |p| as |q|.  Node |p| is |q|'s child on side
|dir|.  Deletion of the root is a special case:

@<Step 1: Find PBST node to delete@> +=
q = p->pbst_parent;
if (q == NULL) @
  {@-
    q = (struct pbst_node *) &tree->pbst_root;
    dir = 0;
  }@+

@

The remainder of the deletion follows the usual outline:

@<Step 2: Delete PBST node@> =
if (p->pbst_link[1] == NULL)
  { @
    @<Case 1 in PBST deletion@> @
  }
else @
  {@-
    struct pbst_node *r = p->pbst_link[1];
    if (r->pbst_link[0] == NULL)
      { @
        @<Case 2 in PBST deletion@> @
      }
    else @
      { @
        @<Case 3 in PBST deletion@> @
      }
  }@+

@

@subsubheading Case 1: |p| has no right child
@anchor{pbstdel1}

If |p| has no right child, then we can replace it by its left child,
if any.  If |p| does have a left child then we must update its parent
to be |p|'s former parent.

@<Case 1 in PBST deletion@> =
q->pbst_link[dir] = p->pbst_link[0];
if (q->pbst_link[dir] != NULL)
  q->pbst_link[dir]->pbst_parent = p->pbst_parent;
@

@subsubheading Case 2: |p|'s right child has no left child
@anchor{pbstdel2}

When we delete a node with a right child that in turn has no left
child, the operation looks like this:

@center @image{pbstdel1}

The key points to notice are that node |r|'s parent changes and so
does the parent of |r|'s new left child, if there is one.  We update
these in deletion:

@<Case 2 in PBST deletion@> =
r->pbst_link[0] = p->pbst_link[0];
q->pbst_link[dir] = r;
r->pbst_parent = p->pbst_parent;
if (r->pbst_link[0] != NULL)
  r->pbst_link[0]->pbst_parent = r;
@

@subsubheading Case 3: |p|'s right child has a left child
@anchor{pbstdel3}

If |p|'s right child has a left child, then we replace |p| by its
successor, as usual.  Finding the successor |s| and its parent |r| is
a little simpler than usual, because we can move up the tree so
easily.  We know that |s| has a non-null parent so there is no need to
handle that special case:

@<Case 3 in PBST deletion@> =
struct pbst_node *s = r->pbst_link[0];
while (s->pbst_link[0] != NULL)
  s = s->pbst_link[0];
r = s->pbst_parent;
@

The only other change here is that we must update parent pointers.
It is easy to pick out the ones that must be changed by looking at a
diagram of the deletion:

@center @image{pbstdel2}

@noindent
Node |s|'s parent changes, as do the parents of its new right child
|x| and, if it has one, its left child |a|.  Perhaps less obviously,
if |s| originally had a right child, it becomes the new left child of
|r|, so its new parent is |r|:

@<Case 3 in PBST deletion@> +=
r->pbst_link[0] = s->pbst_link[1];
s->pbst_link[0] = p->pbst_link[0];
s->pbst_link[1] = p->pbst_link[1];
q->pbst_link[dir] = s;
if (s->pbst_link[0] != NULL)
  s->pbst_link[0]->pbst_parent = s;
s->pbst_link[1]->pbst_parent = s;
s->pbst_parent = p->pbst_parent;
if (r->pbst_link[0] != NULL)
  r->pbst_link[0]->pbst_parent = r;
@

Finally, we free the deleted node |p| and return its data:

@<Step 3: Finish up after deleting PBST node@> =
tree->pbst_alloc->libavl_free (tree->pbst_alloc, p);
tree->pbst_count--;
return (void *) item;
@

@references
@bibref{Cormen 1990}, section 13.3.

@exercise
In case 1, can we change the right side of the assignment in the |if|
statement's consequent from |p->pbst_parent| to |q|?

@answer
No.  It would work, except for the important special case where |q| is
the pseudo-root but |p->pbst_parent| is |NULL|.
@end exercise

@node Traversing a PBST, Copying a PBST, Deleting from a PBST, BSTs with Parent Pointers
@section Traversal

The traverser for a PBST is just like that for a TBST, so we can reuse
a couple of the TBST functions.  Besides that and a couple of
completely generic functions, we have to reimplement the traversal
functions.

@<PBST traversal functions@> =
@<TBST traverser null initializer; tbst => pbst@>
@<PBST traverser first initializer@>
@<PBST traverser last initializer@>
@<PBST traverser search initializer@>
@<PBST traverser insertion initializer@>
@<TBST traverser copy initializer; tbst => pbst@>
@<PBST traverser advance function@>
@<PBST traverser back up function@>
@<BST traverser current item function; bst => pbst@>
@<BST traverser replacement function; bst => pbst@>
@

@menu
* PBST Traverser First Initialization::  
* PBST Traverser Last Initialization::  
* PBST Traverser Find Initialization::  
* PBST Traverser Insert Initialization::  
* PBST Traverser Advancing::    
* PBST Traverser Retreating::   
@end menu

@node PBST Traverser First Initialization, PBST Traverser Last Initialization, Traversing a PBST, Traversing a PBST
@subsection Starting at the First Node

Finding the smallest node in the tree is just a matter of starting
from the root and descending as far to the left as we can.

@cat pbst Initialization of traverser to least item
@<PBST traverser first initializer@> =
@iftangle
/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the least value, @
   or |NULL| if |tree| is empty. */
@end iftangle
void *@
pbst_t_first (struct pbst_traverser *trav, struct pbst_table *tree) @
{
  assert (tree != NULL && trav != NULL);

  trav->pbst_table = tree;
  trav->pbst_node = tree->pbst_root;
  if (trav->pbst_node != NULL) @
    {@-
      while (trav->pbst_node->pbst_link[0] != NULL)
        trav->pbst_node = trav->pbst_node->pbst_link[0];
      return trav->pbst_node->pbst_data;
    }@+
  else @
    return NULL;
}

@

@node PBST Traverser Last Initialization, PBST Traverser Find Initialization, PBST Traverser First Initialization, Traversing a PBST
@subsection Starting at the Last Node

This is the same as starting from the least item, except that we
descend to the right.

@cat pbst Initialization of traverser to greatest item
@<PBST traverser last initializer@> =
@iftangle
/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the greatest value, @
   or |NULL| if |tree| is empty. */
@end iftangle
void *@
pbst_t_last (struct pbst_traverser *trav, struct pbst_table *tree) @
{
  assert (tree != NULL && trav != NULL);

  trav->pbst_table = tree;
  trav->pbst_node = tree->pbst_root;
  if (trav->pbst_node != NULL) @
    {@-
      while (trav->pbst_node->pbst_link[1] != NULL)
        trav->pbst_node = trav->pbst_node->pbst_link[1];
      return trav->pbst_node->pbst_data;
    }@+
  else @
    return NULL;
}

@

@node PBST Traverser Find Initialization, PBST Traverser Insert Initialization, PBST Traverser Last Initialization, Traversing a PBST
@subsection Starting at a Found Node

To start from a particular item, we search for it in the tree.  If it
exists then we initialize the traverser to it.  Otherwise, we
initialize the traverser to the null item and return a null pointer.
There are no surprises here.

@cat pbst Initialization of traverser to found item
@<PBST traverser search initializer@> =
@iftangle
/* Searches for |item| in |tree|.
   If found, initializes |trav| to the item found and returns the item @
   as well.
   If there is no matching item, initializes |trav| to the null item @
   and returns |NULL|. */
@end iftangle
void *@
pbst_t_find (struct pbst_traverser *trav, struct pbst_table *tree, void *item) @
{
  struct pbst_node *p;
  int dir;

  assert (trav != NULL && tree != NULL && item != NULL);

  trav->pbst_table = tree;
  for (p = tree->pbst_root; p != NULL; p = p->pbst_link[dir]) @
    {@-
      int cmp = tree->pbst_compare (item, p->pbst_data, tree->pbst_param);
      if (cmp == 0) @
        {@-
          trav->pbst_node = p;
          return p->pbst_data;
        }@+

      dir = cmp > 0;
    }@+

  trav->pbst_node = NULL;
  return NULL;
}

@

@node PBST Traverser Insert Initialization, PBST Traverser Advancing, PBST Traverser Find Initialization, Traversing a PBST
@subsection Starting at an Inserted Node

This function combines the functionality of search and insertion with
initialization of a traverser.

@cat pbst Initialization of traverser to inserted item
@<PBST traverser insertion initializer@> =
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
pbst_t_insert (struct pbst_traverser *trav, struct pbst_table *tree, @
               void *item) @
{
  struct pbst_node *p, *q; /* Current node in search and its parent. */
  int dir;                 /* Side of |q| on which |p| is located. */
  struct pbst_node *n;     /* Newly inserted node. */

  assert (trav != NULL && tree != NULL && item != NULL);

  trav->pbst_table = tree;
  for (q = NULL, p = tree->pbst_root; p != NULL; q = p, p = p->pbst_link[dir]) @
    {@-
      int cmp = tree->pbst_compare (item, p->pbst_data, tree->pbst_param);
      if (cmp == 0) @
        {@-
          trav->pbst_node = p;
          return p->pbst_data;
        }@+
      dir = cmp > 0;
    }@+
  
  trav->pbst_node = n = @
    tree->pbst_alloc->libavl_malloc (tree->pbst_alloc, sizeof *p);
  if (n == NULL) @
    return NULL;

  tree->pbst_count++;
  n->pbst_link[0] = n->pbst_link[1] = NULL;
  n->pbst_parent = q;
  n->pbst_data = item;
  if (q != NULL)
    q->pbst_link[dir] = n;
  else @
    tree->pbst_root = n;

  return item;
}

@

@node PBST Traverser Advancing, PBST Traverser Retreating, PBST Traverser Insert Initialization, Traversing a PBST
@subsection Advancing to the Next Node

There are the same three cases for advancing a traverser as the other
types of binary trees that we've already looked at.  Two of the cases,
the ones where we're starting from the null item or a node that has a
right child, are unchanged.

The third case, where the node that we're starting from has no right
child, is the case that must be revised.  We can use the same
algorithm that we did for ordinary BSTs without threads or parent
pointers, described earlier (@pxref{Better Iterative Traversal}).
Simply put, we move upward in the tree until we move up to the right
(or until we move off the top of the tree).

The code uses |q| to move up the tree and |p| as |q|'s child, so the
termination condition is when |p| is |q|'s left child or |q| becomes a
null pointer.  There is a non-null successor in the former case, where
the situation looks like this:

@center @image{pbstsucc}

@cat pbst Advancing a traverser
@<PBST traverser advance function@> =
@iftangle
/* Returns the next data item in inorder @
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
@end iftangle
void *@
pbst_t_next (struct pbst_traverser *trav) @
{
  assert (trav != NULL);

  if (trav->pbst_node == NULL)
    return pbst_t_first (trav, trav->pbst_table);
  else if (trav->pbst_node->pbst_link[1] == NULL) @
    {@-
      struct pbst_node *q, *p; /* Current node and its child. */
      for (p = trav->pbst_node, q = p->pbst_parent; ; @
           p = q, q = q->pbst_parent) 
	if (q == NULL || p == q->pbst_link[0]) @
	  {@-
	    trav->pbst_node = q;
	    return trav->pbst_node != NULL ? trav->pbst_node->pbst_data : NULL;
	  }@+
    }@+ @
  else @
    {@-
      trav->pbst_node = trav->pbst_node->pbst_link[1];
      while (trav->pbst_node->pbst_link[0] != NULL)
        trav->pbst_node = trav->pbst_node->pbst_link[0];
      return trav->pbst_node->pbst_data;
    }@+
}

@

@references
@bibref{Cormen 1990}, section 13.2.

@node PBST Traverser Retreating,  , PBST Traverser Advancing, Traversing a PBST
@subsection Backing Up to the Previous Node

This is the same as advancing a traverser, except that we reverse the
directions.

@cat pbst Backing up a traverser
@<PBST traverser back up function@> =
@iftangle
/* Returns the previous data item in inorder @
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
@end iftangle
void *@
pbst_t_prev (struct pbst_traverser *trav) @
{
  assert (trav != NULL);

  if (trav->pbst_node == NULL)
    return pbst_t_last (trav, trav->pbst_table);
  else if (trav->pbst_node->pbst_link[0] == NULL) @
    {@-
      struct pbst_node *q, *p; /* Current node and its child. */
      for (p = trav->pbst_node, q = p->pbst_parent; ; @
           p = q, q = q->pbst_parent)
	if (q == NULL || p == q->pbst_link[1]) @
	  {@-
	    trav->pbst_node = q;
	    return trav->pbst_node != NULL ? trav->pbst_node->pbst_data : NULL;
	  }@+
    }@+ @
  else @
    {@-
      trav->pbst_node = trav->pbst_node->pbst_link[0];
      while (trav->pbst_node->pbst_link[1] != NULL)
        trav->pbst_node = trav->pbst_node->pbst_link[1];
      return trav->pbst_node->pbst_data;
    }@+
}

@

@references
@bibref{Cormen 1990}, section 13.2.

@node Copying a PBST, Balancing a PBST, Traversing a PBST, BSTs with Parent Pointers
@section Copying

To copy BSTs with parent pointers, we use a simple adaptation of our
original algorithm for copying BSTs, as implemented in @<BST copy
function@>.  That function used a stack to keep track of the nodes
that need to be revisited to have their right subtrees copies.  We can
eliminate that by using the parent pointers.  Instead of popping a
pair of nodes off the stack, we ascend the tree until we moved up to
the left:

@cat pbst Copying
@<PBST copy function@> =
@<PBST copy error helper function@>

@iftangle
/* Copies |org| to a newly created tree, which is returned.
   If |copy != NULL|, each data item in |org| is first passed to |copy|,
   and the return values are inserted into the tree;
   |NULL| return values are taken as indications of failure.
   On failure, destroys the partially created new tree,
   applying |destroy|, if non-null, to each item in the new tree so far, @
   and returns |NULL|.
   If |allocator != NULL|, it is used for allocation in the new tree;
   otherwise, the same allocator used for |org| is used. */
@end iftangle
struct pbst_table *@
pbst_copy (const struct pbst_table *org, pbst_copy_func *copy,
           pbst_item_func *destroy, struct libavl_allocator *allocator) @
{
  struct pbst_table *new;
  const struct pbst_node *x;
  struct pbst_node *y;

  assert (org != NULL);
  new = pbst_create (org->pbst_compare, org->pbst_param,
                    allocator != NULL ? allocator : org->pbst_alloc);
  if (new == NULL)
    return NULL;
  new->pbst_count = org->pbst_count;
  if (new->pbst_count == 0)
    return new;

  x = (const struct pbst_node *) &org->pbst_root;
  y = (struct pbst_node *) &new->pbst_root;
  for (;;) @
    {@-
      while (x->pbst_link[0] != NULL) @
        {@-
          y->pbst_link[0] = @
            new->pbst_alloc->libavl_malloc (new->pbst_alloc,
					    sizeof *y->pbst_link[0]);
          if (y->pbst_link[0] == NULL) @
            {@-
              if (y != (struct pbst_node *) &new->pbst_root) @
                {@-
                  y->pbst_data = NULL;
                  y->pbst_link[1] = NULL;
                }@+

              copy_error_recovery (y, new, destroy);
              return NULL;
            }@+
	  y->pbst_link[0]->pbst_parent = y;

          x = x->pbst_link[0];
          y = y->pbst_link[0];
        }@+
      y->pbst_link[0] = NULL;

      for (;;) @
        {@-
          if (copy == NULL)
            y->pbst_data = x->pbst_data;
          else @
            {@-
              y->pbst_data = copy (x->pbst_data, org->pbst_param);
              if (y->pbst_data == NULL) @
                {@-
                  y->pbst_link[1] = NULL;
                  copy_error_recovery (y, new, destroy);
                  return NULL;
                }@+
            }@+

          if (x->pbst_link[1] != NULL) @
            {@-
              y->pbst_link[1] = @
                new->pbst_alloc->libavl_malloc (new->pbst_alloc,
                                               sizeof *y->pbst_link[1]);
              if (y->pbst_link[1] == NULL) @
                {@-
                  copy_error_recovery (y, new, destroy);
                  return NULL;
                }@+
	      y->pbst_link[1]->pbst_parent = y;

              x = x->pbst_link[1];
              y = y->pbst_link[1];
              break;
            }@+
          else @
            y->pbst_link[1] = NULL;

	  for (;;) @
	    {@-
	      const struct pbst_node *w = x;
	      x = x->pbst_parent;
	      if (x == NULL) @
		{@-
		  new->pbst_root->pbst_parent = NULL;
		  return new;
		}@+
	      y = y->pbst_parent;

	      if (w == x->pbst_link[0])
		break;
	    }@+
        }@+
    }@+
}

@

Recovering from an error changes in the same way.  We ascend from the
node where we were copying when memory ran out and set the right
children of the nodes where we ascended to the right to null pointers,
then destroy the fixed-up tree:

@<PBST copy error helper function@> =
@iftangle
/* Destroys |new| with |pbst_destroy (new, destroy)|,
   first initializing right links in |new| that have
   not yet been initialized at time of call. */
@end iftangle
static void @
copy_error_recovery (struct pbst_node *q,
                     struct pbst_table *new, pbst_item_func *destroy) @
{
  assert (q != NULL && new != NULL);

  for (;;) @
    {@-
      struct pbst_node *p = q;
      q = q->pbst_parent;
      if (q == NULL)
	break;

      if (p == q->pbst_link[0])
	q->pbst_link[1] = NULL;
    }@+
  
  pbst_destroy (new, destroy);
}
@

@node Balancing a PBST, Testing PBSTs, Copying a PBST, BSTs with Parent Pointers
@section Balance

We can balance a PBST in the same way that we would balance a BST
without parent pointers.  In fact, we'll use the same code, with the
only change omitting only the maximum height check.  This code doesn't
set parent pointers, so afterward we traverse the tree to take care of
that.

Here are the pieces of the core code that need to be repeated:

@cat pbst Balancing (with later parent updates)
@<PBST balance function@> =
@<BST to vine function; bst => pbst@>
@<Vine to balanced PBST function@>
@<Update parent pointers function@>

@iftangle
/* Balances |tree|.
   Ensures that no simple path from the root to a leaf has more than
   |PBST_MAX_HEIGHT| nodes. */
@end iftangle
void @
pbst_balance (struct pbst_table *tree) @
{
  assert (tree != NULL);

  tree_to_vine (tree);
  vine_to_tree (tree);
  update_parents (tree);
}

@

@cat pbst Vine to balanced tree (without parent updates)
@<Vine to balanced PBST function@> =
@<BST compression function; bst => pbst@>

@iftangle
/* Converts |tree|, which must be in the shape of a vine, into a balanced @
   tree. */
@end iftangle
static void @
vine_to_tree (struct pbst_table *tree) @
{
  unsigned long vine;      /* Number of nodes in main vine. */
  unsigned long leaves;    /* Nodes in incomplete bottom level, if any. */
  int height;              /* Height of produced balanced tree. */

  @<Calculate |leaves|; bst => pbst@>
  @<Reduce vine general case to special case; bst => pbst@>
  @<Make special case vine into balanced tree and count height; bst => pbst@>
}

@

@<PBST extra function prototypes@> =

/* Special PBST functions. */
void pbst_balance (struct pbst_table *tree);
@

@subsubheading Updating Parent Pointers

The procedure for rebalancing a binary tree leaves the nodes' parent
pointers pointing every which way.  Now we'll fix them.  Incidentally,
this is a general procedure, so the same code could be used in other
situations where we have a tree to which we want to add parent
pointers.

The procedure takes the same form as an inorder traversal, except that
there is nothing to do in the place where we would normally visit the
node.  Instead, every time we move down to the left or the right, we
set the parent pointer of the node we move to.

The code is straightforward enough.  The basic strategy is to always
move down to the left when possible; otherwise, move down to the right
if possible; otherwise, repeatedly move up until we've moved up to the
left to arrive at a node with a right child, then move to that right
child.

@cat pbst Update parent pointers
@<Update parent pointers function@> =
static void @
update_parents (struct pbst_table *tree) @
{
  struct pbst_node *p;

  if (tree->pbst_root == NULL)
    return;
  
  tree->pbst_root->pbst_parent = NULL;
  for (p = tree->pbst_root; ; p = p->pbst_link[1]) @
    {@-
      for (; p->pbst_link[0] != NULL; p = p->pbst_link[0])
        p->pbst_link[0]->pbst_parent = p;

      for (; p->pbst_link[1] == NULL; p = p->pbst_parent) @
        {@-
          for (;;) @
            {@-
              if (p->pbst_parent == NULL)
                return;

              if (p == p->pbst_parent->pbst_link[0])
                break;
              p = p->pbst_parent;
            }@+
        }@+

      p->pbst_link[1]->pbst_parent = p;
    }@+
}
@

@exercise
There is another approach to updating parent pointers: we can do it
during the compressions.  Implement this approach.  Make sure not to
miss any pointers.

@answer
@cat pbst Balancing, with integrated parent updates
@c tested 2001/11/20
@<PBST balance function, with integrated parent updates@> =
@<BST to vine function; bst => pbst@>
@<Vine to balanced PBST function, with parent updates@>

@iftangle
/* Balances |tree|.
   Ensures that no simple path from the root to a leaf has more than
   |PBST_MAX_HEIGHT| nodes. */
@end iftangle
void @
pbst_balance (struct pbst_table *tree) @
{
  assert (tree != NULL);

  tree_to_vine (tree);
  vine_to_tree (tree);
}

@

@cat pbst Vine to balanced tree, with parent updates
@c tested 2002/1/6
@<Vine to balanced PBST function, with parent updates@> =
@<PBST compression function@>

@iftangle
/* Converts |tree|, which must be in the shape of a vine, into a balanced @
   tree. */
@end iftangle
static void @
vine_to_tree (struct pbst_table *tree) @
{
  unsigned long vine;      /* Number of nodes in main vine. */
  unsigned long leaves;    /* Nodes in incomplete bottom level, if any. */
  int height;              /* Height of produced balanced tree. */
  struct pbst_node *p, *q; /* Current visited node and its parent. */

  @<Calculate |leaves|; bst => pbst@>
  @<Reduce vine general case to special case; bst => pbst@>
  @<Make special case vine into balanced tree and count height; bst => pbst@>
  @<Set parents of main vine@>
}
@

@<Set parents of main vine@> =
for (q = NULL, p = tree->pbst_root; p != NULL; q = p, p = p->pbst_link[0])
  p->pbst_parent = q;
@

@cat pbst Vine compression (with parent updates)
@<PBST compression function@> =
@iftangle
/* Performs a compression transformation |count| times, @
   starting at |root|. */
@end iftangle
static void @
compress (struct pbst_node *root, unsigned long count) @
{
  assert (root != NULL);

  while (count--) @
    {@-
      struct pbst_node *red = root->pbst_link[0];
      struct pbst_node *black = red->pbst_link[0];

      root->pbst_link[0] = black;
      red->pbst_link[0] = black->pbst_link[1];
      black->pbst_link[1] = red;
      red->pbst_parent = black;
      if (red->pbst_link[0] != NULL)
        red->pbst_link[0]->pbst_parent = red;
      root = black;
    }@+
}
@
@end exercise

@node Testing PBSTs,  , Balancing a PBST, BSTs with Parent Pointers
@section Testing

@(pbst-test.c@> =
@<Program License@>
#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include "pbst.h"
#include "test.h"

@<BST print function; bst => pbst@>
@<BST traverser check function; bst => pbst@>
@<Compare two PBSTs for structure and content@>
@<Recursively verify PBST structure@>
@<BST verify function; bst => pbst@>
@<TBST test function; tbst => pbst@>
@<BST overflow test function; bst => pbst@>
@

@<Compare two PBSTs for structure and content@> =
@iftangle
/* Compares binary trees rooted at |a| and |b|,
   making sure that they are identical. */
@end iftangle
static int @
compare_trees (struct pbst_node *a, struct pbst_node *b) @
{
  int okay;

  if (a == NULL || b == NULL) @
    {@-
      assert (a == NULL && b == NULL);
      return 1;
    }@+

  if (*(int *) a->pbst_data != *(int *) b->pbst_data
      || ((a->pbst_link[0] != NULL) != (b->pbst_link[0] != NULL))
      || ((a->pbst_link[1] != NULL) != (b->pbst_link[1] != NULL))
      || ((a->pbst_parent != NULL) != (b->pbst_parent != NULL))
      || (a->pbst_parent != NULL && b->pbst_parent != NULL
	  && a->pbst_parent->pbst_data != b->pbst_parent->pbst_data)) @
    {@-
      printf (" Copied nodes differ:\n"
	      "  a: %d, parent %d, %s left child, %s right child\n"
	      "  b: %d, parent %d, %s left child, %s right child\n",
              *(int *) a->pbst_data,
	      a->pbst_parent != NULL ? *(int *) a->pbst_parent : -1,
	      a->pbst_link[0] != NULL ? "has" : "no",
	      a->pbst_link[1] != NULL ? "has" : "no",
	      *(int *) b->pbst_data,
	      b->pbst_parent != NULL ? *(int *) b->pbst_parent : -1,
	      b->pbst_link[0] != NULL ? "has" : "no",
	      b->pbst_link[1] != NULL ? "has" : "no");
      return 0;
    }@+

  okay = 1;
  if (a->pbst_link[0] != NULL)
    okay &= compare_trees (a->pbst_link[0], b->pbst_link[0]);
  if (a->pbst_link[1] != NULL)
    okay &= compare_trees (a->pbst_link[1], b->pbst_link[1]);
  return okay;
}

@

@<Recursively verify PBST structure@> =
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
recurse_verify_tree (struct pbst_node *node, int *okay, size_t *count, 
                     int min, int max) @
{
  int d;                /* Value of this node's data. */
  size_t subcount[2];   /* Number of nodes in subtrees. */
  int i;

  if (node == NULL) @
    {@-
      *count = 0;
      return;
    }@+
  d = *(int *) node->pbst_data;

  @<Verify binary search tree ordering@>

  recurse_verify_tree (node->pbst_link[0], okay, &subcount[0], min, d - 1);
  recurse_verify_tree (node->pbst_link[1], okay, &subcount[1], d + 1, max);
  *count = 1 + subcount[0] + subcount[1];

  @<Verify PBST node parent pointers@>
}

@

@<Verify PBST node parent pointers@> =
for (i = 0; i < 2; i++) @
  {@-
    if (node->pbst_link[i] != NULL @
        && node->pbst_link[i]->pbst_parent != node) @
      {@-
        printf (" Node %d has parent %d (should be %d).\n",
                *(int *) node->pbst_link[i]->pbst_data,
                (node->pbst_link[i]->pbst_parent != NULL
                 ? *(int *) node->pbst_link[i]->pbst_parent->pbst_data : -1),
                d);
        *okay = 0;
      }@+
  }@+
@
