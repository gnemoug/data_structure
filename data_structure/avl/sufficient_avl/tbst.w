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

@deftypedef tbst_comparison_func
@deftypedef tbst_item_func
@deftypedef tbst_copy_func

@node Threaded Binary Search Trees, Threaded AVL Trees, Red-Black Trees, Top
@chapter Threaded Binary Search Trees

Traversal in inorder, as done by @libavl{} traversers, is a common
operation in a binary tree.  To do this efficiently in an ordinary
binary search tree or balanced tree, we need to maintain a list of the
nodes above the current node, or at least a list of nodes still to be
visited.  This need leads to the stack used in |struct bst_traverser|
and friends.

It's really too bad that we need such stacks for traversal.  First,
they take up space.  Second, they're fragile: if an item is inserted
into or deleted from the tree during traversal, or if the tree is
balanced, we have to rebuild the traverser's stack.  In addition, it
can sometimes be difficult to know in advance how tall the stack will
need to be, as demonstrated by the code that we wrote to handle stack
overflow.

These problems are important enough that, in this book, we'll look at
two different solutions.  This chapter looks at the first of these,
which adds special pointers, each called a @gloss{thread}, to nodes,
producing what is called a threaded binary search tree,
@gloss{threaded tree}, or simply a TBST.@footnote{This usage of
``thread'' has nothing to do with the idea of a program with multiple
``threads of excecution'', a form of multitasking within a single
program.}  Later in the book, we'll examine an alternate and more
general solution using a @gloss{parent pointer} in each node.

Here's the outline of the TBST code.  We're using the prefix |tbst_|
this time:

@(tbst.h@> =
@<Library License@>
#ifndef TBST_H
#define TBST_H 1

#include <stddef.h>

@<Table types; tbl => tbst@>
@<TBST table structure@>
@<TBST node structure@>
@<TBST traverser structure@>
@<Table function prototypes; tbl => tbst@>
@<BST extra function prototypes; bst => tbst@>

#endif /* tbst.h */
@ 

@(tbst.c@> =
@<Library License@>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "tbst.h"

@<TBST functions@>
@

@menu
* Threads::                     
* TBST Data Types::             
* TBST Operations::             
* Creating a TBST::             
* Searching a TBST::            
* Inserting into a TBST::       
* Deleting from a TBST::        
* Traversing a TBST::           
* Copying a TBST::              
* Destroying a TBST::           
* Balancing a TBST::            
* Testing TBSTs::               
@end menu

@node Threads, TBST Data Types, Threaded Binary Search Trees, Threaded Binary Search Trees
@section Threads

In an ordinary binary search tree or balanced tree, a lot of the pointer
fields go more-or-less unused.  Instead of pointing to somewhere useful,
they are used to store null pointers.  In a sense, they're wasted.  What
if we were to instead use these fields to point elsewhere in the tree?

This is the idea behind a threaded tree.  In a threaded tree, a node's
left child pointer field, if it would otherwise be a null pointer, is
used to point to the node's inorder predecessor.  An otherwise-null
right child pointer field points to the node's successor.  The
least-valued node in a threaded tree has a null pointer for its left
thread, and the greatest-valued node similarly has a null right
thread.  These two are the only null pointers in a threaded tree.

Here's a sample threaded tree:

@center @image{tbst1}

@ifnotinfo
@noindent This diagram illustrates the convention used for threads in
this book, arrowheads attached to dotted lines.  Null threads in the
least and greatest nodes are shown as arrows pointing into space.
This kind of arrow is also used to show threads that point to nodes
not shown in the diagram.
@end ifnotinfo
@ifinfo
@noindent This diagram illustrates the convention used for threads in
text: thread links are designated by surrounding the node name or value
with square brackets.  Null threads in the least and greatest nodes are
shown as @code{[0]}, which is also used to show threads up to nodes not
shown in the diagram.  This notation is unfortunate, but less visually
confusing than trying to include additional arrows in text art tree
diagrams.
@end ifinfo

There are some disadvantages to threaded trees.  Each node in an
unthreaded tree has only one pointer that leads to it, either from the
tree structure or its parent node, but in a threaded tree some nodes
have as many as three pointers leading to them: one from the root or
parent, one from its predecessor's right thread, and one from its
successor's left thread.  This means that, although traversing a
threaded tree is simpler, building and maintaining a threaded tree is
more complicated.

As we learned earlier, any node that has a right child has a successor
in its right subtree, and that successor has no left child.  So, a
node in an threaded tree has a left thread pointing back to it if and
only if the node has a right child.  Similarly, a node has a right
thread pointing to it if and only if the node has a left child.  Take
a look at the sample tree above and check these statements for
yourself for some of its nodes.

@references
@bibref{Knuth 1997}, section 2.3.1.

@node TBST Data Types, TBST Operations, Threads, Threaded Binary Search Trees
@section Data Types

We need two extra fields in the node structure to keep track of whether
each link is a child pointer or a thread.  Each of these fields is
called a @gloss{tag}.  The revised |struct tbst_node|, along with |enum
tbst_tag| for tags, looks like this:

@<TBST node structure@> =
/* Characterizes a link as a child pointer or a thread. */
enum tbst_tag @
  {@-
    TBST_CHILD,                     /* Child pointer. */
    TBST_THREAD                     /* Thread. */
  };@+

/* A threaded binary search tree node. */
struct tbst_node @
  {@-
    struct tbst_node *tbst_link[2]; /* Subtrees. */
    void *tbst_data;                /* Pointer to data. */
    unsigned char tbst_tag[2];      /* Tag fields. */
  };@+

@

@noindent
Each element of |tbst_tag[]| is set to |TBST_CHILD| if the corresponding
|tbst_link[]| element is a child pointer, or to |TBST_THREAD| if it is a
thread.  The other members of |struct tbst_node| should be familiar.

We also want a revised table structure, because traversers in threaded
trees do not need a generation number:

@<TBST table structure@> =
/* Tree data structure. */
struct tbst_table @
  {@-
    struct tbst_node *tbst_root;        /* Tree's root. */
    tbst_comparison_func *tbst_compare; /* Comparison function. */
    void *tbst_param;                   /* Extra argument to |tbst_compare|. */
    struct libavl_allocator *tbst_alloc; /* Memory allocator. */
    size_t tbst_count;                  /* Number of items in tree. */
  };@+

@

There is no need to define a maximum height for TBST trees because none
of the TBST functions use a stack.

@exercise
We defined |enum tbst_tag| for distinguishing threads from child
pointers, but declared the actual tag members as |unsigned char|
instead.  Why?

@answer
An enumerated type is compatible with some C integer type, but the
particular type is up to the C compiler.  Many C compilers will always
pick |int| as the type of an enumeration type.  But we want to
conserve space in the structure (see @value{tavlnodesizebrief}), so we
specify |unsigned char| explicitly as the type.

@references
@bibref{ISO 1990}, section 6.5.2.2;
@bibref{ISO 1999}, section 6.7.2.2.
@end exercise

@node TBST Operations, Creating a TBST, TBST Data Types, Threaded Binary Search Trees
@section Operations

Now that we've changed the basic form of our binary trees, we have to
rewrite most of the tree functions.  A function designed for use with
unthreaded trees will get hopelessly lost in a threaded tree, because
it will follow threads that it thinks are child pointers.  The only
functions we can keep are the totally generic functions defined in
terms of other table functions.

@<TBST functions@> =
@<TBST creation function@>
@<TBST search function@>
@<TBST item insertion function@>
@<Table insertion convenience functions; tbl => tbst@>
@<TBST item deletion function@>
@<TBST traversal functions@>
@<TBST copy function@>
@<TBST destruction function@>
@<TBST balance function@>
@<Default memory allocation functions; tbl => tbst@>
@<Table assertion functions; tbl => tbst@>
@

@node Creating a TBST, Searching a TBST, TBST Operations, Threaded Binary Search Trees
@section Creation

Function |tbst_create()| is the same as |bst_create()| except that a
|struct tbst_table| has no generation number to fill in.

@cat tbst Creation
@<TBST creation function@> =
@iftangle
/* Creates and returns a new table
   with comparison function |compare| using parameter |param|
   and memory allocator |allocator|.
   Returns |NULL| if memory allocation failed. */
@end iftangle
struct tbst_table *@
tbst_create (tbst_comparison_func *compare, void *param,
            struct libavl_allocator *allocator) @
{
  struct tbst_table *tree;

  assert (compare != NULL);

  if (allocator == NULL)
    allocator = &tbst_allocator_default;

  tree = allocator->libavl_malloc (allocator, sizeof *tree);
  if (tree == NULL)
    return NULL;

  tree->tbst_root = NULL;
  tree->tbst_compare = compare;
  tree->tbst_param = param;
  tree->tbst_alloc = allocator;
  tree->tbst_count = 0;

  return tree;
}

@

@node Searching a TBST, Inserting into a TBST, Creating a TBST, Threaded Binary Search Trees
@section Search

In searching a TBST we just have to be careful to distinguish threads
from child pointers.  If we hit a thread link, then we've run off the
bottom of the tree and the search is unsuccessful.  Other that that, a
search in a TBST works the same as in any other binary search tree.

@cat tbst Search
@<TBST search function@> =
@iftangle
/* Search |tree| for an item matching |item|, and return it if found.
   Otherwise return |NULL|. */
@end iftangle
void *@
tbst_find (const struct tbst_table *tree, const void *item) @
{
  const struct tbst_node *p;

  assert (tree != NULL && item != NULL);

  p = tree->tbst_root;
  if (p == NULL)
    return NULL;

  for (;;) @
    {@-
      int cmp, dir;

      cmp = tree->tbst_compare (item, p->tbst_data, tree->tbst_param);
      if (cmp == 0)
        return p->tbst_data;

      dir = cmp > 0;
      if (p->tbst_tag[dir] == TBST_CHILD)
        p = p->tbst_link[dir];
      else @
        return NULL;
    }@+
}

@

@node Inserting into a TBST, Deleting from a TBST, Searching a TBST, Threaded Binary Search Trees
@section Insertion

It take a little more effort to insert a new node into a threaded BST
than into an unthreaded one, but not much more.  The only difference is
that we now have to set up the new node's left and right threads to
point to its predecessor and successor, respectively.  

Fortunately, these are easy to figure out.  Suppose that new node |n| is
the right child of its parent |p| (the other case is symmetric).  This
means that |p| is |n|'s predecessor, because |n| is the least node in
|p|'s right subtree.  Moreover, |n|'s successor is the node that was
|p|'s successor before |n| was inserted, that is to say, it is the same
as |p|'s former right thread.

Here's an example that may help to clear up the description.  When new
node 3 is inserted as the right child of 2, its left thread points to 2 and
its right thread points where 2's right thread formerly did, to 4:

@center @image{tbstins}

The following code unifies the left-side and right-side cases using
|dir|, which takes the value 1 for a right-side insertion, 0 for a
left-side insertion.  The side opposite |dir| can then be expressed
simply as |!dir|.

@cat tbst Insertion
@<TBST item insertion function@> =
@iftangle
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree, 
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
@end iftangle
void **@
tbst_probe (struct tbst_table *tree, void *item) @
{
  struct tbst_node *p; /* Traverses tree to find insertion point. */
  struct tbst_node *n; /* New node. */
  int dir;             /* Side of |p| on which |n| is inserted. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Search TBST for insertion point@>
  @<Step 2: Insert TBST node@>

  return &n->tbst_data;
}

@

@<Step 1: Search TBST for insertion point@> =
if (tree->tbst_root != NULL)
  for (p = tree->tbst_root; ; p = p->tbst_link[dir]) @
    {@-
      int cmp = tree->tbst_compare (item, p->tbst_data, tree->tbst_param);
      if (cmp == 0)
        return &p->tbst_data;
      dir = cmp > 0;

      if (p->tbst_tag[dir] == TBST_THREAD)
        break;
    }@+
else @
  {@-
    p = (struct tbst_node *) &tree->tbst_root;
    dir = 0;
  }@+

@

@<Step 2: Insert TBST node@> =
n = tree->tbst_alloc->libavl_malloc (tree->tbst_alloc, sizeof *n);
if (n == NULL)
  return NULL;

tree->tbst_count++;
n->tbst_data = item;
n->tbst_tag[0] = n->tbst_tag[1] = TBST_THREAD;
n->tbst_link[dir] = p->tbst_link[dir];
if (tree->tbst_root != NULL) @
  {@-
    p->tbst_tag[dir] = TBST_CHILD;
    n->tbst_link[!dir] = p;
  }@+
else @
  n->tbst_link[1] = NULL;
p->tbst_link[dir] = n;
@

@references
@bibref{Knuth 1997}, algorithm 2.3.1I.

@exercise
What happens if we reverse the order of the final |if| statement above
and the following assignment?

@answer
When we add a node to a formerly empty tree, this statement will set
|tree->tbst_root|, thereby breaking the |if| statement's test.
@end exercise

@node Deleting from a TBST, Traversing a TBST, Inserting into a TBST, Threaded Binary Search Trees
@section Deletion

When we delete a node from a threaded tree, we have to update one or two
more pointers than if it were an unthreaded BST.  What's more, we
sometimes have to go to a bit of effort to track down what pointers
these are, because they are in the predecessor and successor of the node
being deleted.

The outline is the same as for deleting a BST node:

@cat tbst Deletion (parent tracking)
@<TBST item deletion function@> =
@iftangle
/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
@end iftangle
void *@
tbst_delete (struct tbst_table *tree, const void *item) @
{
  struct tbst_node *p;	/* Node to delete. */
  struct tbst_node *q;	/* Parent of |p|. */
  int dir;              /* Index into |q->tbst_link[]| that leads to |p|. */

  assert (tree != NULL && item != NULL);

  @<Find TBST node to delete@>
  @<Delete TBST node@>
  @<Finish up after deleting TBST node@>
}

@

We search down the tree to find the item to delete, |p|.  As we do it we
keep track of its parent |q| and the direction |dir| that we descended
from it.  The initial value of |q| and |dir| use the trick seen
originally in copying a BST (@pxref{Copying a BST Iteratively}).

There are nicer ways to do the same thing, though they are not
necessarily as efficient.  See the exercises for one possibility.

@<Find TBST node to delete@> =
if (tree->tbst_root == NULL)
  return NULL;

p = tree->tbst_root;
q = (struct tbst_node *) &tree->tbst_root;
dir = 0;
for (;;) @
  {@-
    int cmp = tree->tbst_compare (item, p->tbst_data, tree->tbst_param);
    if (cmp == 0) 
      break;

    dir = cmp > 0;
    if (p->tbst_tag[dir] == TBST_THREAD)
      return NULL;

    q = p;
    p = p->tbst_link[dir];
  }@+
item = p->tbst_data;

@

The cases for deletion from a threaded tree are a bit different from
those for an unthreaded tree.  The key point to keep in mind is that a
node with |n| children has |n| threads pointing to it that must be
updated when it is deleted.  Let's look at the cases in detail now.

Here's the outline:

@<Delete TBST node@> =
if (p->tbst_tag[1] == TBST_THREAD) @
  {@-
    if (p->tbst_tag[0] == TBST_CHILD)
      { @
        @<Case 1 in TBST deletion@> @
      }
    else @
      { @
        @<Case 2 in TBST deletion@> @
      }
  }@+ @
else @
  {@-
    struct tbst_node *r = p->tbst_link[1];
    if (r->tbst_tag[0] == TBST_THREAD)
      { @
        @<Case 3 in TBST deletion@> @
      }
    else @
      { @
        @<Case 4 in TBST deletion@> @
      }
  }@+

@

@subsubheading Case 1: |p| has a right thread and a left child

If |p| has a right thread and a left child, then we replace it by its
left child.  We also replace its predecessor |t|'s right thread by
|p|'s right thread.  In the most general subcase, the whole operation
looks something like this:

@center @image{tbstdel1}

@noindent
On the other hand, it can be as simple as this:

@center @image{tbstdel1triv}

@noindent
Both of these subcases, and subcases in between them in complication,
are handled by the same code:

@<Case 1 in TBST deletion@> =
struct tbst_node *t = p->tbst_link[0];
while (t->tbst_tag[1] == TBST_CHILD)
  t = t->tbst_link[1];
t->tbst_link[1] = p->tbst_link[1];
q->tbst_link[dir] = p->tbst_link[0];
@

@subsubheading Case 2: |p| has a right thread and a left thread

If |p| is a leaf, then no threads point to it, but we must change its
parent |q|'s pointer to |p| to a thread, pointing to the same place that
the corresponding thread of |p| pointed.  This is easy, and typically
looks something like this:

@center @image{tbstdel2}

@noindent
There is one special case, which comes up when |q| is the pseudo-node
used for the parent of the root.  We can't access |tbst_tag[]| in this
``node''.  Here's the code:

@<Case 2 in TBST deletion@> =
q->tbst_link[dir] = p->tbst_link[dir];
if (q != (struct tbst_node *) &tree->tbst_root)
  q->tbst_tag[dir] = TBST_THREAD;
@

@subsubheading Case 3: |p|'s right child has a left thread

If |p| has a right child |r|, and |r| itself has a left thread, then
we delete |p| by moving |r| into its place.  Here's an example where
the root node is deleted:

@center @image{tbstdel3}

This just involves changing |q|'s right link to point to |r|, copying
|p|'s left link and tag into |r|, and fixing any thread that pointed to
|p| so that it now points to |r|.  The code is straightforward:

@<Case 3 in TBST deletion@> =
r->tbst_link[0] = p->tbst_link[0];
r->tbst_tag[0] = p->tbst_tag[0];
if (r->tbst_tag[0] == TBST_CHILD) @
  {@-
    struct tbst_node *t = r->tbst_link[0];
    while (t->tbst_tag[1] == TBST_CHILD)
      t = t->tbst_link[1];
    t->tbst_link[1] = r;
  }@+
q->tbst_link[dir] = r;
@

@subsubheading Case 4: |p|'s right child has a left child

If |p| has a right child, which in turn has a left child, we arrive at
the most complicated case.  It corresponds to case 3 in deletion from
an unthreaded BST.  The solution is to find |p|'s successor |s| and
move it in place of |p|.  In this case, |r| is |s|'s parent node, not
necessarily |p|'s right child.

There are two subcases here.  In the first, |s| has a right child.  In
that subcase, |s|'s own successor's left thread already points to |s|,
so we need not adjust any threads.  Here's an example of this subcase.
Notice how the left thread of node 3, |s|'s successor, already points
to |s|.

@center @image{tbstdel4}

The second subcase comes up when |s| has a right thread.  Because |s|
also has a left thread, this means that |s| is a leaf.  This subcase
requires us to change |r|'s left link to a thread to its predecessor,
which is now |s|.  Here's a continuation of the previous example,
showing deletion of the new root, node 2:

@center @image{tbstdel4-2}

The first part of the code handles finding |r| and |s|:

@<Case 4 in TBST deletion@> =
struct tbst_node *s;

for (;;) @
  {@-
    s = r->tbst_link[0];
    if (s->tbst_tag[0] == TBST_THREAD)
      break;

    r = s;
  }@+

@

Next, we update |r|, handling each of the subcases:

@<Case 4 in TBST deletion@> +=
if (s->tbst_tag[1] == TBST_CHILD)
  r->tbst_link[0] = s->tbst_link[1];
else @
  {@-
    r->tbst_link[0] = s;
    r->tbst_tag[0] = TBST_THREAD;
  }@+

@

Finally, we copy |p|'s links and tags into |s| and chase down and update
any right thread in |s|'s left subtree, then replace the pointer from
|q| down to |s|:

@<Case 4 in TBST deletion@> +=
s->tbst_link[0] = p->tbst_link[0];
if (p->tbst_tag[0] == TBST_CHILD) @
  {@-
    struct tbst_node *t = p->tbst_link[0];
    while (t->tbst_tag[1] == TBST_CHILD)
      t = t->tbst_link[1];
    t->tbst_link[1] = s;

    s->tbst_tag[0] = TBST_CHILD;
  }@+

s->tbst_link[1] = p->tbst_link[1];
s->tbst_tag[1] = TBST_CHILD;

q->tbst_link[dir] = s;    
@

We finish up by deallocating the node, decrementing the tree's item
count, and returning the deleted item's data:

@<Finish up after deleting TBST node@> =
tree->tbst_alloc->libavl_free (tree->tbst_alloc, p);
tree->tbst_count--;
return (void *) item;
@

@exercise* tbstparent
In a threaded BST, there is an efficient algorithm to find the parent of
a given node.  Use this algorithm to reimplement @<Find TBST node to
delete@>.

@answer
@xref{Finding the Parent of a TBST Node}.  Function |find_parent()| is
implemented in @<Find parent of a TBST node@>.

@cat tbst Deletion, with parent node algorithm
@c tested 2001/11/10
@<Find TBST node to delete, with parent node algorithm@> =
p = tree->tbst_root;
if (p == NULL)
  return NULL;

for (;;) @
  {@-
    int cmp = tree->tbst_compare (item, p->tbst_data, tree->tbst_param);
    if (cmp == 0) 
      break;

    p = p->tbst_link[cmp > 0];
  }@+

q = find_parent (tree, p);
dir = q->tbst_link[0] != p;

@

@references
@bibref{Knuth 1997}, exercise 2.3.1-19.
@end exercise

@exercise ptrtaglink
In case 2, we must handle |q| as the pseudo-root as a special case.  Can
we rearrange the TBST data structures to avoid this?

@answer
Yes.  We can bind a pointer and a tag into a single structure, then use
that structure for our links and for the root in the table structure.

@c tested 2001/7/16
@<Anonymous@> =
/* A tagged link. */
struct tbst_link @
  {@-
    struct tbst_node *tbst_ptr;     /* Child pointer or thread. */
    unsigned char tbst_tag;         /* Tag. */
  };@+

/* A threaded binary search tree node. */
struct tbst_node @
  {@-
    struct tbst_link tbst_link[2];  /* Links. */
    void *tbst_data;                /* Pointer to data. */
  };@+

/* Tree data structure. */
struct tbst_table @
  {@-
    struct tbst_link tbst_root;         /* Tree's root; tag is unused. */
    tbst_comparison_func *tbst_compare; /* Comparison function. */
    void *tbst_param;                   /* Extra argument to |tbst_compare|. */
    struct libavl_allocator *tbst_alloc; /* Memory allocator. */
    size_t tbst_count;                  /* Number of items in tree. */
  };@+

@

The main disadvantage of this approach is in storage space: many
machines have alignment restrictions for pointers, so the
nonadjacent |unsigned char|s cause space to be wasted.  Alternatively,
we could keep the current arrangement of the node structure and change
|tbst_root| in |struct tbst_table| from a pointer to an instance of
|struct tbst_node|.
@end exercise

@exercise
Rewrite case 4 to replace the deleted node's |tbst_data| by its
successor and actually delete the successor, instead of moving around
pointers.  (Refer back to @value{modifydata} for an explanation of why
this approach cannot be used in @libavl{}.)

@answer
Much simpler than the implementation given before:

@cat tbst Deletion, with data modification
@c tested 2001/11/10
@<Case 4 in TBST deletion, alternate version@> =
struct tbst_node *s = r->tbst_link[0];
while (s->tbst_tag[0] == TBST_CHILD) @
  {@-
    r = s;
    s = r->tbst_link[0];
  }@+

p->tbst_data = s->tbst_data;

if (s->tbst_tag[1] == TBST_THREAD) @
  {@-
    r->tbst_tag[0] = TBST_THREAD;
    r->tbst_link[0] = p;
  }@+ @
else @
  {@-
    q = r->tbst_link[0] = s->tbst_link[1];
    while (q->tbst_tag[0] == TBST_CHILD)
      q = q->tbst_link[0];
    q->tbst_link[0] = p;
  }@+

p = s;
@
@end exercise

@exercise* tbstthreadsearch
Many of the cases in deletion from a TBST require searching down the
tree for the nodes with threads to the deleted node.  Show that this
adds only a constant number of operations to the deletion of a randomly
selected node, compared to a similar deletion in an unthreaded tree.

@answer
If all the possible deletions from a given TBST are considered, then
no link will be followed more than once to update a left thread, and
similarly for right threads.  Averaged over all the possible
deletions, this is a constant.  For example, take the following TBST:

@center @image{tbstdel6}

@noindent
Consider right threads that must be updated on deletion.  Nodes 2, 3, 5,
and 6 have right threads pointing to them.  To update the right thread
to node 2, we follow the link to node 1; to update node 3's, we move to
0, then 2; for node 5, we move to node 4; and for node 6, we move to 3,
then 5.  No link is followed more than once.  Here's a summary table:

@multitable @columnfractions .25 .1 .2 .2
@item 
@tab Node
@tab Right Thread @* Follows
@tab Left Thread @* Follows

@item
@tab 0:
@tab (none)
@tab 2, 1

@item
@tab 1:
@tab (none)
@tab (none)

@item
@tab 2:
@tab 1
@tab (none)

@item
@tab 3:
@tab 0, 2
@tab 5, 4

@item
@tab 4:
@tab (none)
@tab (none)

@item
@tab 5:
@tab 4
@tab (none)

@item
@tab 6:
@tab 3, 5
@tab 7

@item
@tab 7:
@tab (none)
@tab (none)
@end multitable

The important point here is that no number appears twice within a
column.
@end exercise

@node Traversing a TBST, Copying a TBST, Deleting from a TBST, Threaded Binary Search Trees
@section Traversal

Traversal in a threaded BST is much simpler than in an unthreaded one.
This is, indeed, much of the point to threading our trees.  This section
implements all of the @libavl{} traverser functions for threaded trees.

Suppose we wish to find the successor of an arbitrary node in a threaded
tree.  If the node has a right child, then the successor is the smallest
item in the node's right subtree.  Otherwise, the node has a right
thread, and its sucessor is simply the node to which the right thread
points.  If the right thread is a null pointer, then the node is the
largest in the tree.  We can find the node's predecessor in a similar
manner.

We don't ever need to know the parent of a node to traverse the
threaded tree, so there's no need to keep a stack.  Moreover, because
a traverser has no stack to be corrupted by changes to its tree, there
is no need to keep or compare generation numbers.  Therefore, this is
all we need for a TBST traverser structure:

@<TBST traverser structure@> =
/* TBST traverser structure. */
struct tbst_traverser @
  {@-
    struct tbst_table *tbst_table;        /* Tree being traversed. */
    struct tbst_node *tbst_node;          /* Current node in tree. */
  };@+

@

The traversal functions are collected together here.  A few of the
functions are implemented directly in terms of their unthreaded BST
counterparts, but most must be reimplemented:

@<TBST traversal functions@> =
@<TBST traverser null initializer@>
@<TBST traverser first initializer@>
@<TBST traverser last initializer@>
@<TBST traverser search initializer@>
@<TBST traverser insertion initializer@>
@<TBST traverser copy initializer@>
@<TBST traverser advance function@>
@<TBST traverser back up function@>
@<BST traverser current item function; bst => tbst@>
@<BST traverser replacement function; bst => tbst@>
@

@references
@bibref{Knuth 1997}, algorithm 2.3.1S.

@menu
* TBST Traverser Null Initialization::  
* TBST Traverser First Initialization::  
* TBST Traverser Last Initialization::  
* TBST Traverser Find Initialization::  
* TBST Traverser Insert Initialization::  
* TBST Traverser Copying::      
* TBST Traverser Advancing::    
* TBST Traverser Retreating::   
@end menu

@node TBST Traverser Null Initialization, TBST Traverser First Initialization, Traversing a TBST, Traversing a TBST
@subsection Starting at the Null Node

@cat tbst Initialization of traverser to null item
@<TBST traverser null initializer@> =
@iftangle
/* Initializes |trav| for use with |tree| @
   and selects the null node. */
@end iftangle
void @
tbst_t_init (struct tbst_traverser *trav, struct tbst_table *tree) @
{
  trav->tbst_table = tree;
  trav->tbst_node = NULL;
}

@

@node TBST Traverser First Initialization, TBST Traverser Last Initialization, TBST Traverser Null Initialization, Traversing a TBST
@subsection Starting at the First Node

@cat tbst Initialization of traverser to least item
@<TBST traverser first initializer@> =
@iftangle
/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the least value, @
   or |NULL| if |tree| is empty. */
@end iftangle
void *@
tbst_t_first (struct tbst_traverser *trav, struct tbst_table *tree) @
{
  assert (tree != NULL && trav != NULL);

  trav->tbst_table = tree;
  trav->tbst_node = tree->tbst_root;
  if (trav->tbst_node != NULL) @
    {@-
      while (trav->tbst_node->tbst_tag[0] == TBST_CHILD)
        trav->tbst_node = trav->tbst_node->tbst_link[0];
      return trav->tbst_node->tbst_data;
    }@+
  else @
    return NULL;
}

@

@node TBST Traverser Last Initialization, TBST Traverser Find Initialization, TBST Traverser First Initialization, Traversing a TBST
@subsection Starting at the Last Node

@cat tbst Initialization of traverser to greatest item
@<TBST traverser last initializer@> =
@iftangle
/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the greatest value, @
   or |NULL| if |tree| is empty. */
@end iftangle
void *@
tbst_t_last (struct tbst_traverser *trav, struct tbst_table *tree) @
{
  assert (tree != NULL && trav != NULL);

  trav->tbst_table = tree;
  trav->tbst_node = tree->tbst_root;
  if (trav->tbst_node != NULL) @
    {@-
      while (trav->tbst_node->tbst_tag[1] == TBST_CHILD)
        trav->tbst_node = trav->tbst_node->tbst_link[1];
      return trav->tbst_node->tbst_data;
    }@+
  else @
    return NULL;
}

@

@node TBST Traverser Find Initialization, TBST Traverser Insert Initialization, TBST Traverser Last Initialization, Traversing a TBST
@subsection Starting at a Found Node

The code for this function is derived with few changes from 
@<TBST search function@>.

@cat tbst Initialization of traverser to found item
@<TBST traverser search initializer@> =
@iftangle
/* Searches for |item| in |tree|.
   If found, initializes |trav| to the item found and returns the item @
   as well.
   If there is no matching item, initializes |trav| to the null item @
   and returns |NULL|. */
@end iftangle
void *@
tbst_t_find (struct tbst_traverser *trav, struct tbst_table *tree, void *item) @
{
  struct tbst_node *p;

  assert (trav != NULL && tree != NULL && item != NULL);

  trav->tbst_table = tree;
  trav->tbst_node = NULL;

  p = tree->tbst_root;
  if (p == NULL)
    return NULL;

  for (;;) @
    {@-
      int cmp, dir;

      cmp = tree->tbst_compare (item, p->tbst_data, tree->tbst_param);
      if (cmp == 0) @
        {@-
          trav->tbst_node = p;
          return p->tbst_data;
        }@+

      dir = cmp > 0;
      if (p->tbst_tag[dir] == TBST_CHILD)
        p = p->tbst_link[dir];
      else @
        return NULL;
    }@+
}

@

@node TBST Traverser Insert Initialization, TBST Traverser Copying, TBST Traverser Find Initialization, Traversing a TBST
@subsection Starting at an Inserted Node

This implementation is a trivial adaptation of @<AVL traverser insertion
initializer@>.  In particular, management of generation numbers has
been removed.

@cat tbst Initialization of traverser to inserted item
@<TBST traverser insertion initializer@> =
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
tbst_t_insert (struct tbst_traverser *trav, @
               struct tbst_table *tree, void *item) @
{
  void **p;

  assert (trav != NULL && tree != NULL && item != NULL);

  p = tbst_probe (tree, item);
  if (p != NULL) @
    {@-
      trav->tbst_table = tree;
      trav->tbst_node =
        ((struct tbst_node *) @
         ((char *) p - offsetof (struct tbst_node, tbst_data)));
      return *p;
    }@+ @
  else @
    {@-
      tbst_t_init (trav, tree);
      return NULL;
    }@+
}
  
@

@node TBST Traverser Copying, TBST Traverser Advancing, TBST Traverser Insert Initialization, Traversing a TBST
@subsection Initialization by Copying

@cat tbst Initialization of traverser as copy
@<TBST traverser copy initializer@> =
@iftangle
/* Initializes |trav| to have the same current node as |src|. */
@end iftangle
void *@
tbst_t_copy (struct tbst_traverser *trav, const struct tbst_traverser *src) @
{
  assert (trav != NULL && src != NULL);

  trav->tbst_table = src->tbst_table;
  trav->tbst_node = src->tbst_node;

  return trav->tbst_node != NULL ? trav->tbst_node->tbst_data : NULL;
}

@

@node TBST Traverser Advancing, TBST Traverser Retreating, TBST Traverser Copying, Traversing a TBST
@subsection Advancing to the Next Node

Despite the earlier discussion (@pxref{Traversing a TBST}), there are
actually three cases, not two, in advancing within a threaded binary
tree.  The extra case turns up when the current node is the null item.
We deal with that case by calling out to |tbst_t_first()|.

Notice also that, below, in the case of following a thread we must check
for a null node, but not in the case of following a child pointer.

@cat tbst Advancing a traverser
@<TBST traverser advance function@> =
@iftangle
/* Returns the next data item in inorder @
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
@end iftangle
void *@
tbst_t_next (struct tbst_traverser *trav) @
{
  assert (trav != NULL);
  
  if (trav->tbst_node == NULL)
    return tbst_t_first (trav, trav->tbst_table);
  else if (trav->tbst_node->tbst_tag[1] == TBST_THREAD) @
    {@-
      trav->tbst_node = trav->tbst_node->tbst_link[1];
      return trav->tbst_node != NULL ? trav->tbst_node->tbst_data : NULL;
    }@+ @
  else @
    {@-
      trav->tbst_node = trav->tbst_node->tbst_link[1];
      while (trav->tbst_node->tbst_tag[0] == TBST_CHILD)
	trav->tbst_node = trav->tbst_node->tbst_link[0];
      return trav->tbst_node->tbst_data;
    }@+
}

@

@references
@bibref{Knuth 1997}, algorithm 2.3.1S.

@node TBST Traverser Retreating,  , TBST Traverser Advancing, Traversing a TBST
@subsection Backing Up to the Previous Node

@cat tbst Backing up a traverser
@<TBST traverser back up function@> =
@iftangle
/* Returns the previous data item in inorder @
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
@end iftangle
void *@
tbst_t_prev (struct tbst_traverser *trav) @
{
  assert (trav != NULL);
  
  if (trav->tbst_node == NULL)
    return tbst_t_last (trav, trav->tbst_table);
  else if (trav->tbst_node->tbst_tag[0] == TBST_THREAD) @
    {@-
      trav->tbst_node = trav->tbst_node->tbst_link[0];
      return trav->tbst_node != NULL ? trav->tbst_node->tbst_data : NULL;
    }@+ @
  else @
    {@-
      trav->tbst_node = trav->tbst_node->tbst_link[0];
      while (trav->tbst_node->tbst_tag[1] == TBST_CHILD)
	trav->tbst_node = trav->tbst_node->tbst_link[1];
      return trav->tbst_node->tbst_data;
    }@+
}

@

@node Copying a TBST, Destroying a TBST, Traversing a TBST, Threaded Binary Search Trees
@section Copying

We can use essentially the same algorithm to copy threaded BSTs as
unthreaded (see @<BST copy function@>).  Some modifications are
necessary, of course.  The most obvious change is that the threads
must be set up.  This is not hard.  We can do it the same way that
|tbst_probe()| does.

Less obvious is the way to get rid of the stack.  In |bst_copy()|, the
stack was used to keep track of as yet incompletely processed parents of
the current node.  When we came back to one of these nodes, we did the
actual copy of the node data, then visited the node's right subtree, if
non-empty.

In a threaded tree, we can replace the use of the stack by the use of
threads.  Instead of popping an item off the stack when we can't move
down in the tree any further, we follow the node's right thread.  This
brings us up to an ancestor (parent, grandparent, @dots{}) of the node,
which we can then deal with in the same way as before.

This diagram shows the threads that would be followed to find parents in
copying a couple of different threaded binary trees.  Of course, the
TBSTs would have complete sets of threads, but only the ones that are
followed are shown:

@center @image{tbstcopy}

Why does following the right thread from a node bring us to one of the
node's ancestors?  Consider the algorithm for finding the successor of
a node with no right child, described earlier (@pxref{Better Iterative
Traversal}).  This algorithm just moves up the tree from a node to its
parent, grandparent, etc., guaranteeing that the successor will be a
ancestor of the original node.

How do we know that following the right thread won't take us too far up
the tree and skip copying some subtree?  Because we only move up to the
right one time using that same algorithm.  When we move up to the left,
we're going back to some binary tree whose right subtree we've already
dealt with (we are currently in the right subtree of that binary tree,
so of course we've dealt with it).

In conclusion, following the right thread always takes us to just the
node whose right subtree we want to copy next.  Of course, if that node
happens to have an empty right subtree, then there is nothing to do, so
we just continue along the next right thread, and so on.

The first step is to build a function to copy a single node.  The
following function |copy_node()| does this, creating a new node as the
child of an existing node:

@cat tbst Copying a node
@<TBST node copy function@> =
/* Creates a new node as a child of |dst| on side |dir|.
   Copies data from |src| into the new node, applying |copy()|, if non-null.
   Returns nonzero only if fully successful.
   Regardless of success, integrity of the tree structure is assured,
   though failure may leave a null pointer in a |tbst_data| member. */
static int @
copy_node (struct tbst_table *tree, @
           struct tbst_node *dst, int dir,
           const struct tbst_node *src, tbst_copy_func *copy) @
{
  struct tbst_node *new = @
    tree->tbst_alloc->libavl_malloc (tree->tbst_alloc, sizeof *new);
  if (new == NULL)
    return 0;

  new->tbst_link[dir] = dst->tbst_link[dir];
  new->tbst_tag[dir] = TBST_THREAD;
  new->tbst_link[!dir] = dst;
  new->tbst_tag[!dir] = TBST_THREAD;
  dst->tbst_link[dir] = new;
  dst->tbst_tag[dir] = TBST_CHILD;

  if (copy == NULL)
    new->tbst_data = src->tbst_data;
  else @
    {@-
      new->tbst_data = copy (src->tbst_data, tree->tbst_param);
      if (new->tbst_data == NULL)
        return 0;
    }@+

  return 1;
}

@

Using the node copy function above, constructing the tree copy function
is easy.  In fact, the code is considerably easier to read than our
original function to iteratively copy an unthreaded binary tree
(@pxref{Handling Errors in Iterative BST Copying}), because this
function is not as heavily optimized.

One tricky part is getting the copy started.  We can't use the dirty
trick from |bst_copy()| of casting the address of a |bst_root| to a
node pointer, because we need access to the first tag as well as the
first link (see @value{ptrtaglinkbrief} for a way to sidestep this
problem).  So instead we use a couple of ``pseudo-root'' nodes |rp|
and |rq|, allocated locally.

@cat tbst Copying
@<TBST copy function@> =
@<TBST node copy function@>
@<TBST copy error helper function@>
@<TBST main copy function@>
@

@<TBST main copy function@> =
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
struct tbst_table *@
tbst_copy (const struct tbst_table *org, tbst_copy_func *copy,
	  tbst_item_func *destroy, struct libavl_allocator *allocator) @
{
  struct tbst_table *new;

  const struct tbst_node *p;
  struct tbst_node *q;
  struct tbst_node rp, rq;

  assert (org != NULL);
  new = tbst_create (org->tbst_compare, org->tbst_param,
                     allocator != NULL ? allocator : org->tbst_alloc);
  if (new == NULL)
    return NULL;
  
  new->tbst_count = org->tbst_count;
  if (new->tbst_count == 0)
    return new;

  p = &rp;
  rp.tbst_link[0] = org->tbst_root;
  rp.tbst_tag[0] = TBST_CHILD;

  q = &rq;
  rq.tbst_link[0] = NULL;
  rq.tbst_tag[0] = TBST_THREAD;

  for (;;) @
    {@-
      if (p->tbst_tag[0] == TBST_CHILD) @
	{@-
          if (!copy_node (new, q, 0, p->tbst_link[0], copy)) @
            {@-
              copy_error_recovery (rq.tbst_link[0], new, destroy);
              return NULL;
            }@+

          p = p->tbst_link[0];
          q = q->tbst_link[0];
	}@+ @
      else @
	{@-
	  while (p->tbst_tag[1] == TBST_THREAD) @
	    {@-
	      p = p->tbst_link[1];
	      if (p == NULL) @
		{@-
                  q->tbst_link[1] = NULL;
		  new->tbst_root = rq.tbst_link[0];
		  return new;
		}@+
	      
	      q = q->tbst_link[1];
	    }@+

	  p = p->tbst_link[1];
	  q = q->tbst_link[1];
	}@+

      if (p->tbst_tag[1] == TBST_CHILD)
        if (!copy_node (new, q, 1, p->tbst_link[1], copy)) @
          {@-
            copy_error_recovery (rq.tbst_link[0], new, destroy);
            return NULL;
          }@+
    }@+
}

@

A sensitive issue in the code above is treatment of the final thread.
The initial call to |copy_node()| causes a right thread to point to
|rq|, but it needs to be a null pointer.  We need to perform this kind
of transformation:

@center @image{tbstcopy2}

When the copy is successful, this is just a matter of setting the final
|q|'s right child pointer to |NULL|, but when it is unsuccessful we have
to find the pointer in question, which is in the greatest node in the
tree so far (to see this, try constructing a few threaded BSTs by hand
on paper).  Function |copy_error_recovery()| does this, as well as
destroying the tree.  It also handles the case of failure when no nodes
have yet been added to the tree:

@<TBST copy error helper function@> =
@iftangle
/* Destroys |new| with |tbst_destroy (new, destroy)|,
   first initializing the right link in |new| that has
   not yet been initialized. */
@end iftangle
static void @
copy_error_recovery (struct tbst_node *p,
                     struct tbst_table *new, tbst_item_func *destroy) @
{
  new->tbst_root = p;
  if (p != NULL) @
    {@-
      while (p->tbst_tag[1] == TBST_CHILD)
        p = p->tbst_link[1];
      p->tbst_link[1] = NULL;
    }@+
  tbst_destroy (new, destroy);
}

@

@exercise
In the diagram above that shows examples of threads followed while
copying a TBST, all right threads in the TBSTs are shown.  Explain how
this is not just a coincidence.

@answer
Suppose a node has a right thread.  If the node has no left subtree,
then the thread will be followed immediately when the node is reached.
If the node does have a left subtree, then the left subtree will be
traversed, and when the traversal is finished the node's predecessor's
right thread will be followed back to the node, then its right thread
will be followed.  The node cannot be skipped, because all the nodes in
its left subtree are less than it, so none of the right threads in its
left subtree can skip beyond it.
@end exercise

@exercise
Suggest some optimization possibilities for |tbst_copy()|.

@answer
The biggest potential for optimization probably comes from
|tbst_copy()|'s habit of always keeping the TBST fully consistent as it
builds it, which causes repeated assignments to link fields in order to
keep threads correct at all times.  The unthreaded BST copy function
|bst_copy()| waited to initialize fields until it was ready for them.
It may be possible, though difficult, to do this in |tbst_copy()| as
well.

Inlining and specializing |copy_node()| is a cheaper potential speedup.
@end exercise

@node Destroying a TBST, Balancing a TBST, Copying a TBST, Threaded Binary Search Trees
@section Destruction

Destroying a threaded binary tree is easy.  We can simply traverse the
tree in inorder in the usual way.  We always have a way to get to the
next node without having to go back up to any of the nodes we've already
destroyed.  (We do, however, have to make sure to go find the next node
before destroying the current one, in order to avoid reading data from
freed memory.)  Here's all it takes:

@cat tbst Destruction
@<TBST destruction function@> =
@iftangle
/* Frees storage allocated for |tree|.
   If |destroy != NULL|, applies it to each data item in inorder. */
@end iftangle
void @
tbst_destroy (struct tbst_table *tree, tbst_item_func *destroy) @
{
  struct tbst_node *p; /* Current node. */
  struct tbst_node *n; /* Next node. */

  p = tree->tbst_root;
  if (p != NULL)
    while (p->tbst_tag[0] == TBST_CHILD)
      p = p->tbst_link[0];

  while (p != NULL) @
    {@-
      n = p->tbst_link[1];
      if (p->tbst_tag[1] == TBST_CHILD)
	while (n->tbst_tag[0] == TBST_CHILD)
	  n = n->tbst_link[0];

      if (destroy != NULL && p->tbst_data != NULL) 
	destroy (p->tbst_data, tree->tbst_param);
      tree->tbst_alloc->libavl_free (tree->tbst_alloc, p);
      
      p = n;
    }@+

  tree->tbst_alloc->libavl_free (tree->tbst_alloc, tree);
}

@

@node Balancing a TBST, Testing TBSTs, Destroying a TBST, Threaded Binary Search Trees
@section Balance

Just like their unthreaded cousins, threaded binary trees can become
degenerate, leaving their good performance characteristics behind.  When
this happened in a unthreaded BST, stack overflow often made it
necessary to rebalance the tree.  This doesn't happen in our
implementation of threaded BSTs, because none of the routines uses a
stack.  It is still useful to have a rebalance routine for performance
reasons, so we will implement one, in this section, anyway.

There is no need to change the basic algorithm.  As before, we convert
the tree to a linear ``vine'', then the vine to a balanced binary search
tree.  @xref{Balancing a BST}, for a review of the balancing algorithm.

Here is the outline and prototype for |tbst_balance()|.

@cat tbst Balancing
@<TBST balance function@> =
@<TBST tree-to-vine function@>
@<TBST vine compression function@>
@<TBST vine-to-tree function@>
@<TBST main balance function@>
@

@<TBST main balance function@> =
/* Balances |tree|. */
void @
tbst_balance (struct tbst_table *tree) @
{
  assert (tree != NULL);

  tree_to_vine (tree);
  vine_to_tree (tree);
}

@

@menu
* Transforming a TBST into a Vine::  
* Transforming a Vine into a Balanced TBST::  
@end menu

@node Transforming a TBST into a Vine, Transforming a Vine into a Balanced TBST, Balancing a TBST, Balancing a TBST
@subsection From Tree to Vine

We could transform a threaded binary tree into a vine in the same way we
did for unthreaded binary trees, by use of rotations
(@pxref{Transforming a BST into a Vine}).  But one of the reasons we did
it that way was to avoid use of a stack, which is no longer a
problem.  It's now simpler to rearrange nodes by inorder
traversal.

We start by finding the minimum node in the tree as |p|, which will step
through the tree in inorder.  During each trip through the main loop,
we find |p|'s successor as |q| and make |p| the left child of |q|.  We
also have to make sure that |p|'s right thread points to |q|.  That's
all there is to it.

@cat tbst Vine from tree
@<TBST tree-to-vine function@> =
static void @
tree_to_vine (struct tbst_table *tree) @
{
  struct tbst_node *p;

  if (tree->tbst_root == NULL)
    return;

  p = tree->tbst_root;
  while (p->tbst_tag[0] == TBST_CHILD)
    p = p->tbst_link[0];

  for (;;) @
    {@-
      struct tbst_node *q = p->tbst_link[1];
      if (p->tbst_tag[1] == TBST_CHILD) @
	{@-
	  while (q->tbst_tag[0] == TBST_CHILD)
	    q = q->tbst_link[0];
	  p->tbst_tag[1] = TBST_THREAD;
	  p->tbst_link[1] = q;
	}@+

      if (q == NULL)
	break;

      q->tbst_tag[0] = TBST_CHILD;
      q->tbst_link[0] = p;
      p = q;
    }@+

  tree->tbst_root = p;
}

@

Sometimes one trip through the main loop above will put the TBST into
an inconsistent state, where two different nodes are the parent of a
third node.  Such an inconsistency is always corrected in the next
trip through the loop.  An example is warranted.  Suppose the original
threaded binary tree looks like this, with nodes |p| and |q| for the
initial iteration of the loop as marked:

@center @image{tbstbal1}

@noindent
The first trip through the loop makes |p|, 1, the child of |q|, 2, but
|p|'s former parent's left child pointer still points to |p|.  We now
have a situation where node 1 has two parents: both 2 and 3.  This
diagram tries to show the situation by omitting the line that would
otherwise lead down from 3 to 2:

@center @image{tbstbal2}

@noindent
On the other hand, node 2's right thread still points to 3, so on the
next trip through the loop there is no trouble finding the new |p|'s
successor.  Node 3 is made the parent of 2 and all is well.  This
diagram shows the new |p| and |q|, then the fixed-up vine.  The only
difference is that node 3 now, correctly, has 2 as its left child:

@center @image{tbstbal3}

@node Transforming a Vine into a Balanced TBST,  , Transforming a TBST into a Vine, Balancing a TBST
@subsection From Vine to Balanced Tree

Transforming a vine into a balanced threaded BST is similar to the same
operation on an unthreaded BST.  We can use the same algorithm,
adjusting it for presence of the threads.  The following outline is
similar to @<BST balance function@>.  In fact, we entirely reuse
@<Calculate |leaves|@>, just changing |bst| to |tbst|.  We omit the
final check on the tree's height, because none of the TBST functions are
height-limited.

@cat tbst Vine to balanced tree
@<TBST vine-to-tree function@> =
@iftangle
/* Converts |tree|, which must be in the shape of a vine, into a balanced @
   tree. */
@end iftangle
static void @
vine_to_tree (struct tbst_table *tree) @
{
  unsigned long vine;   /* Number of nodes in main vine. */
  unsigned long leaves; /* Nodes in incomplete bottom level, if any. */
  int height;           /* Height of produced balanced tree. */

  @<Calculate |leaves|; bst => tbst@>
  @<Reduce TBST vine general case to special case@>
  @<Make special case TBST vine into balanced tree and count height@>
}

@

Not many changes are needed to adapt the algorithm to handle threads.
Consider the basic right rotation transformation used during a
compression:

@center @image{compress}

The rotation does not disturb |a| or |c|, so the only node that can
cause trouble is |b|.  If |b| is a real child node, then there's no need
to do anything differently.  But if |b| is a thread, then we have to
swap around the direction of the thread, like this:

@center @image{tbstcmp}

@noindent
After a rotation that involves a thread, the next rotation on |B| will
not involve a thread.  So after we perform a rotation that adjusts a
thread in one place, the next one in the same place will not require a
thread adjustment.

Every node in the vine we start with has a thread as its right link.
This means that during the first pass along the main vine we must
perform thread adjustments at every node, but subsequent passes along
the vine must not perform any adjustments.

This simple idea is complicated by the initial partial compression pass
in trees that do not have exactly one fewer than a power of two nodes.
After a partial compression pass, the nodes at the top of the main vine
no longer have right threads, but the ones farther down still do.

We deal with this complication by defining the |compress()| function so
it can handle a mixture of rotations with and without right threads.
The rotations that need thread adjustments will always be below the ones
that do not, so this function simply takes a pair of parameters, the
first specifying how many rotations without thread adjustment to
perform, the next how many with thread adjustment.  Compare this code
to that for unthreaded BSTs:

@cat tbst Vine compression
@<TBST vine compression function@> =
/* Performs a nonthreaded compression operation |nonthread| times,
   then a threaded compression operation |thread| times, @
   starting at |root|. */
static void @
compress (struct tbst_node *root,
          unsigned long nonthread, unsigned long thread) @
{
  assert (root != NULL);

  while (nonthread--) @
    {@-
      struct tbst_node *red = root->tbst_link[0];
      struct tbst_node *black = red->tbst_link[0];

      root->tbst_link[0] = black;
      red->tbst_link[0] = black->tbst_link[1];
      black->tbst_link[1] = red;
      root = black;
    }@+

  while (thread--) @
    {@-
      struct tbst_node *red = root->tbst_link[0];
      struct tbst_node *black = red->tbst_link[0];

      root->tbst_link[0] = black;
      red->tbst_link[0] = black;
      red->tbst_tag[0] = TBST_THREAD;
      black->tbst_tag[1] = TBST_CHILD;
      root = black;
    }@+
}

@

When we reduce the general case to the @altmath{2^n - 1, 2**n - 1}
special case, all of the rotations adjust threads:

@<Reduce TBST vine general case to special case@> =
compress ((struct tbst_node *) &tree->tbst_root, 0, leaves);

@

We deal with the first compression specially, in order to clean up any
remaining unadjusted threads:

@<Make special case TBST vine into balanced tree and count height@> =
vine = tree->tbst_count - leaves;
height = 1 + (leaves > 0);
if (vine > 1) @
  {@-
    unsigned long nonleaves = vine / 2;
    leaves /= 2;
    if (leaves > nonleaves) @
      {@-
        leaves = nonleaves;
        nonleaves = 0;
      }@+
    else @
      nonleaves -= leaves;

    compress ((struct tbst_node *) &tree->tbst_root, leaves, nonleaves);
    vine /= 2;
    height++;
  }@+
@

After this, all the remaining compressions use only rotations without
thread adjustment, and we're done:

@<Make special case TBST vine into balanced tree and count height@> +=
while (vine > 1) @
  {@-
    compress ((struct tbst_node *) &tree->tbst_root, vine / 2, 0);
    vine /= 2;
    height++;
  }@+
@

@node Testing TBSTs,  , Balancing a TBST, Threaded Binary Search Trees
@section Testing

There's little new in the testing code.  We do add an test for
|tbst_balance()|, because none of the existing tests exercise it.  This
test doesn't check that |tbst_balance()| actually balances the tree, it
just verifies that afterwards the tree contains the items it should, so
to be certain that balancing is correct, turn up the verbosity and look
at the trees printed.

Function |print_tree_structure()| prints thread node numbers preceded
by @samp{>}, with null threads indicated by @samp{>>}.  This notation
is compatible with the plain text output format of the @code{texitree}
program used to draw the binary trees in this book.  (It will cause
errors for PostScript output because it omits node names.)

@(tbst-test.c@> =
@<Program License@>
#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include "tbst.h"
#include "test.h"

@<TBST print function@>
@<BST traverser check function; bst => tbst@>
@<Compare two TBSTs for structure and content@>
@<Recursively verify TBST structure@>
@<TBST verify function@>
@<TBST test function@>
@<BST overflow test function; bst => tbst@>
@

@<TBST print function@> =
@iftangle
/* Prints the structure of |node|, @
   which is |level| levels from the top of the tree. */
@end iftangle
void @
print_tree_structure (struct tbst_node *node, int level) @
{
  int i;

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

  printf ("%d(", node->tbst_data ? *(int *) node->tbst_data : -1);

  for (i = 0; i <= 1; i++) @
    {@-
      if (node->tbst_tag[i] == TBST_CHILD) @
        {@-
          if (node->tbst_link[i] == node) @
            printf ("loop");
          else @
            print_tree_structure (node->tbst_link[i], level + 1);
        }@+
      else if (node->tbst_link[i] != NULL)
        printf (">%d", @
                (node->tbst_link[i]->tbst_data
                ? *(int *) node->tbst_link[i]->tbst_data : -1));
      else @
        printf (">>");

      if (i == 0) @
        fputs (", ", stdout);
    }@+

  putchar (')');
}

@iftangle
/* Prints the entire structure of |tree| with the given |title|. */
@end iftangle
void @
print_whole_tree (const struct tbst_table *tree, const char *title) @
{
  printf ("%s: ", title);
  print_tree_structure (tree->tbst_root, 0);
  putchar ('\n');
}

@

@<Compare two TBSTs for structure and content@> =
@iftangle
/* Compares binary trees rooted at |a| and |b|, @
   making sure that they are identical. */
@end iftangle
static int @
compare_trees (struct tbst_node *a, struct tbst_node *b) @
{
  int okay;

  if (a == NULL || b == NULL) @
    {@-
      if (a != NULL || b != NULL) @
	{@-
	  printf (" a=%d b=%d\n",
		  a ? *(int *) a->tbst_data : -1, @
		  b ? *(int *) b->tbst_data : -1);
	  assert (0);
	}@+
      return 1;
    }@+
  assert (a != b);

  if (*(int *) a->tbst_data != *(int *) b->tbst_data
      || a->tbst_tag[0] != b->tbst_tag[0] @
      || a->tbst_tag[1] != b->tbst_tag[1]) @
    {@-
      printf (" Copied nodes differ: a=%d b=%d a:",
	      *(int *) a->tbst_data, *(int *) b->tbst_data);

      if (a->tbst_tag[0] == TBST_CHILD) @
	printf ("l");
      if (a->tbst_tag[1] == TBST_CHILD) @
	printf ("r");

      printf (" b:");
      if (b->tbst_tag[0] == TBST_CHILD) @
	printf ("l");
      if (b->tbst_tag[1] == TBST_CHILD) @
	printf ("r");

      printf ("\n");
      return 0;
    }@+

  if (a->tbst_tag[0] == TBST_THREAD)
    assert ((a->tbst_link[0] == NULL) != (a->tbst_link[0] != b->tbst_link[0]));
  if (a->tbst_tag[1] == TBST_THREAD)
    assert ((a->tbst_link[1] == NULL) != (a->tbst_link[1] != b->tbst_link[1]));

  okay = 1;
  if (a->tbst_tag[0] == TBST_CHILD)
    okay &= compare_trees (a->tbst_link[0], b->tbst_link[0]);
  if (a->tbst_tag[1] == TBST_CHILD)
    okay &= compare_trees (a->tbst_link[1], b->tbst_link[1]);
  return okay;
}

@

@<Recursively verify TBST structure@> =
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
recurse_verify_tree (struct tbst_node *node, int *okay, size_t *count, 
                     int min, int max) @
{
  int d;                /* Value of this node's data. */
  size_t subcount[2];   /* Number of nodes in subtrees. */

  if (node == NULL) @
    {@-
      *count = 0;
      return;
    }@+
  d = *(int *) node->tbst_data;

  @<Verify binary search tree ordering@>

  subcount[0] = subcount[1] = 0;
  if (node->tbst_tag[0] == TBST_CHILD)
    recurse_verify_tree (node->tbst_link[0], okay, &subcount[0], min, d - 1);
  if (node->tbst_tag[1] == TBST_CHILD)
    recurse_verify_tree (node->tbst_link[1], okay, &subcount[1], d + 1, max);
  *count = 1 + subcount[0] + subcount[1];
}

@

@<TBST verify function@> =
@iftangle
/* Checks that |tree| is well-formed
   and verifies that the values in |array[]| are actually in |tree|.  
   There must be |n| elements in |array[]| and |tree|.
   Returns nonzero only if no errors detected. */
@end iftangle
static int @
verify_tree (struct tbst_table *tree, int array[], size_t n) @
{
  int okay = 1;

  @<Check |tree->bst_count| is correct; bst => tbst@>

  if (okay) @
    { @
      @<Check BST structure; bst => tbst@> @
    }

  if (okay) @
    { @
      @<Check that the tree contains all the elements it should; bst => tbst@> @
    }

  if (okay) @
    { @
      @<Check that forward traversal works; bst => tbst@> @
    }

  if (okay) @
    { @
      @<Check that backward traversal works; bst => tbst@> @
    }

  if (okay) @
    { @
      @<Check that traversal from the null element works; bst => tbst@> @
    }

  return okay;
}

@

@<TBST test function@> =
@iftangle
/* Tests tree functions.  
   |insert[]| and |delete[]| must contain some permutation of values @
   |0|@dots{}|n - 1|.
   Uses |allocator| as the allocator for tree and node data.
   Higher values of |verbosity| produce more debug output. */
@end iftangle
int @
test_correctness (struct libavl_allocator *allocator,
                 int insert[], int delete[], int n, int verbosity) @
{
  struct tbst_table *tree;
  int okay = 1;
  int i;

  @<Test creating a BST and inserting into it; bst => tbst@>
  @<Test BST traversal during modifications; bst => tbst@>
  @<Test deleting nodes from the BST and making copies of it; bst => tbst@>
  @<Test destroying the tree; bst => tbst@>

  @<Test TBST balancing@>

  return okay;
}
@

@<Test TBST balancing@> =
/* Test |tbst_balance()|. */
if (verbosity >= 2) @
  printf ("  Testing balancing...\n");

tree = tbst_create (compare_ints, NULL, allocator);
if (tree == NULL) @
  {@-
    if (verbosity >= 0) @
      printf ("  Out of memory creating tree.\n");
    return 1;
  }@+

for (i = 0; i < n; i++) @
  {@-
    void **p = tbst_probe (tree, &insert[i]);
    if (p == NULL) @
      {@-
        if (verbosity >= 0) @
          printf ("    Out of memory in insertion.\n");
        tbst_destroy (tree, NULL);
        return 1;
      }@+
    if (*p != &insert[i]) @
      printf ("    Duplicate item in tree!\n");
  }@+

if (verbosity >= 4) @
  print_whole_tree (tree, "    Pre-balance");
tbst_balance (tree);
if (verbosity >= 4) @
  print_whole_tree (tree, "    Post-balance");

if (!verify_tree (tree, insert, n))
  return 0;

tbst_destroy (tree, NULL);
@

