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

@deftypedef bst_comparison_func
@deftypedef bst_item_func
@deftypedef bst_copy_func

@node Binary Search Trees, AVL Trees, Search Algorithms, Top
@chapter Binary Search Trees

The previous chapter motivated the need for binary search trees.  This
chapter implements a table ADT backed by a binary search tree.  Along
the way, we'll see how binary search trees are constructed and
manipulated in abstract terms as well as in concrete C code.

The library includes a header file @(bst.h@> and an implementation file
@(bst.c@>, outlined below.  We borrow most of the header file from the
generic table headers designed a couple of chapters back, simply
replacing |tbl| by |bst|, the prefix used in this table module.

@(bst.h@> =
@<Library License@>
#ifndef BST_H
#define BST_H 1

#include <stddef.h>

@<Table types; tbl => bst@>
@<BST maximum height@>
@<BST table structure@>
@<BST node structure@>
@<BST traverser structure@>
@<Table function prototypes; tbl => bst@>
@<BST extra function prototypes@>

#endif /* bst.h */

@<Table assertion function control directives; tbl => bst@>
@

@(bst.c@> =
@<Library License@>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "bst.h"

@<BST operations@>
@

@exercise includeguard
What is the purpose of |#ifndef BST_H| @dots{} |#endif| in @(bst.h@>
above?

@answer
This construct makes @(bst.h@> @gloss{idempotent}, that is, including it
many times has the same effect as including it once.  This is important
because some C constructs, such as type definitions with |typedef|, are
erroneous if included in a program multiple times.

Of course, @<Table assertion function control directives@> is included
outside the |#ifndef|-protected part of @(bst.h@>.  This is
intentional (see @value{tblassert} for details).
@end exercise

@menu
* BST Vocabulary::              
* BST Data Types::              
* BST Rotations::               
* BST Operations::              
* Creating a BST::              
* Searching a BST::             
* Inserting into a BST::        
* Deleting from a BST::         
* Traversing a BST::            
* Copying a BST::               
* Destroying a BST::            
* Balancing a BST::             
* Joining BSTs::                
* Testing BST Functions::   
* Additional Exercises for BSTs::  
@end menu

@node BST Vocabulary, BST Data Types, Binary Search Trees, Binary Search Trees
@section Vocabulary

When binary search trees, or BSTs, were introduced in the previous
chapter, the reason that they were called binary search trees wasn't
explained.  The diagram below should help to clear up matters, and
incidentally let us define some BST-related vocabulary:

@center @image{100-114}

This diagram illustrates the binary search tree example from the
previous chapter.  The circle or @gloss{node} at the top, labeled 107,
is the starting point of any search.  As such, it is called the
@gloss{root} of the tree.  The node connected to it below to the left,
labeled 103, is the root's @gloss{left child}, and node 111 to its
lower right is its @gloss{right child}.  A node's left child
corresponds to |smaller| from the array-based BST of the previous
chapter, and a right child corresponds to |larger|.

Some nodes, such as 106 here, don't have any children.  Such a node is
called a @gloss{leaf} or @gloss{terminal node}.  Although not shown
here, it's also possible for a node to have only one child, either on
the left or the right side.  A node with at least one child is called a
@gloss{nonterminal node}.

Each node in a binary search tree is, conceptually, the root of its own
tree.  Such a tree is called a @gloss{subtree} of the tree that contains
it.  The left child of a node and recursively all of that child's
children is a subtree of the node, called the @gloss{left subtree} of
the node.  The term @gloss{right subtree} is defined similarly for the
right side of the node.  For instance, above, nodes 104, 105, and 106
are the right subtree of node 103, with 105 as the subtree's root.

A BST without any nodes is called an @gloss{empty tree}.  Both subtrees
of all even-numbered nodes in the BST above are empty trees.

In a binary search tree, the left child of a node, if it exists, has a
smaller value than the node, and the right child of a node has a larger
value.  The more general term @gloss{binary tree}, on the other hand,
refers to a data structure with the same form as a binary search tree,
but which does not necessarily share this property.  There are also
related, but different, structures simply called ``trees''.

In this book, all our binary trees are binary search trees, and this
book will not discuss plain trees at all.  As a result, we will often
be a bit loose in terminology and use the term ``binary tree'' or
``tree'' when ``binary search tree'' is the proper term.

Although this book discusses binary search trees exclusively, it is
instructive to occasionally display, as a counterexample, a diagram of
a binary tree whose nodes are out of order and therefore not a BST.
Such diagrams are marked |**| to reinforce their non-BST nature to the
casual browser.

@references
@bibref{Knuth 1997}, section 2.3;
@bibref{Knuth 1998b}, section 6.2.2;
@bibref{Cormen 1990}, section 13.1;
@bibref{Sedgewick 1998}, section 5.4.

@menu
* Differing Definitions::       
@end menu

@node Differing Definitions,  , BST Vocabulary, BST Vocabulary
@subsection Aside: Differing Definitions

The definitions in the previous section are the ones used in this
book.  They are the definitions that programmers often use in
designing and implementing real programs.  However, they are slightly
different from the definitions used in formal computer science
textbooks.  This section gives these formal definitions and contrasts
them against our own.

The most important difference is in the definition of a binary tree
itself.  Formally, a binary tree is either an ``external node'' or an
``internal node'' connected to a pair of binary trees called the
internal node's left subtree and right subtree.  Internal nodes
correspond to our notion of nodes, and external nodes correspond
roughly to nodes' empty left or right subtrees.  The generic term
``node'' includes both internal and external nodes.

Every internal node always has exactly two children, although those
children may be external nodes, so we must also revise definitions
that depend on a node's number of children.  Then, a ``leaf'' is an
internal node with two external node children and a ``nonterminal
node'' is an internal node at least one of whose children is an
internal node.  Finally, an ``empty tree'' is a binary tree that
contains of only an external node.

Tree diagrams in books that use these formal definitions show both
internal and external nodes.  Typically, internal nodes are shown as
circles, external nodes as square boxes.  Here's an example BST in the
format used in this book, shown alongside an identical BST in the
format used in formal computer science books:

@center @image{altdef}

@references
@bibref{Sedgewick 1998}, section 5.4.

@node BST Data Types, BST Rotations, BST Vocabulary, Binary Search Trees
@section Data Types

The types for memory allocation and managing data as |void *| pointers
were discussed previously (@pxref{The Table ADT}), but to build a table
implementation using BSTs we must define some additional types.  In
particular, we need |struct bst_node| to represent an individual node
and |struct bst_table| to represent an entire table.  The following
sections take care of this.

@menu
* BST Node Structure::          
* BST Structure::               
* BST Maximum Height::          
@end menu

@node BST Node Structure, BST Structure, BST Data Types, BST Data Types
@subsection Node Structure

When binary search trees were introduced in the last chapter, we used
indexes into an array to reference items' |smaller| and |larger| values.
But in C, BSTs are usually constructed using pointers.  This is a more
general technique, because pointers aren't restricted to references
within a single array.

@<BST node structure@> =
/* A binary search tree node. */
struct bst_node @
  {@-
    struct bst_node *bst_link[2];   /* Subtrees. */
    void *bst_data;                 /* Pointer to data. */
  };@+

@

In |struct bst_node|, |bst_link[0]| takes the place of |smaller|, and
|bst_link[1]| takes the place of |larger|.  If, in our array implementation
of binary search trees, either of these would have pointed to the
sentinel, it instead is assigned |NULL|, the null pointer constant.

In addition, |bst_data| replaces |value|.  We use a |void *| generic pointer
here, instead of |int| as used in the last chapter, to let any kind of
data be stored in the BST.  @xref{Comparison Function}, for more
information on |void *| pointers.

@node BST Structure, BST Maximum Height, BST Node Structure, BST Data Types
@subsection Tree Structure

The |struct bst_table| structure ties together all of the data needed to
keep track of a table implemented as a binary search tree:

@<BST table structure@> =
/* Tree data structure. */
struct bst_table @
  {@-
    struct bst_node *bst_root;          /* Tree's root. */
    bst_comparison_func *bst_compare;   /* Comparison function. */
    void *bst_param;                    /* Extra argument to |bst_compare|. */
    struct libavl_allocator *bst_alloc; /* Memory allocator. */
    size_t bst_count;                   /* Number of items in tree. */
    unsigned long bst_generation;       /* Generation number. */
  };@+

@

Most of |struct bst_table|'s members should be familiar.  Member
|bst_root| points to the root node of the BST.  Together, |bst_compare|
and |bst_param| specify how items are compared (@pxref{Item and Copy
Functions}).  The members of |bst_alloc| specify how to allocate memory
for the BST (@pxref{Memory Allocation}).  The number of items in the BST
is stored in |bst_count| (@pxref{Count}).

The final member, |bst_generation|, is a @dfn{generation number}.  When
a tree is created, it starts out at zero.  After that, it is incremented
every time the tree is modified in a way that might disturb a traverser.
We'll talk more about the generation number later (@pxref{Better
Iterative Traversal}).

@exercise*
Why is it a good idea to include |bst_count| in |struct bst_table|?
Under what circumstances would it be better to omit it?

@answer
Under many circumstances we often want to know how many items are in a
binary tree.  In these cases it's cheaper to keep track of item counts
as we go instead of counting them each time, which requires a full
binary tree traversal.

It would be better to omit it if we never needed to know how many items
were in the tree, or if we only needed to know very seldom.
@end exercise

@node BST Maximum Height,  , BST Structure, BST Data Types
@subsection Maximum Height

For efficiency, some of the BST routines use a stack of a fixed maximum
height.  This maximum height affects the maximum number of nodes that
can be fully supported by @libavl{} in any given tree, because a binary
tree of height |n| contains at most @altmath{2^n - 1, 2**n - 1} nodes.

The |BST_MAX_HEIGHT| macro sets the maximum height of a BST.  The
default value of 64 allows for trees with up to @altmath{2^{64} - 1,
2**64 - 1}.  On today's common 32- and 64-bit computers,
this is hardly a limit,
because memory would be exhausted long before the tree became too big.

The BST routines that use fixed stacks also detect stack overflow and
call a routine to ``balance'' or restructure the tree in order to reduce
its height to the permissible range.  The limit on the BST height is
therefore not a severe restriction.

@<BST maximum height@> =
/* Maximum BST height. */
#ifndef BST_MAX_HEIGHT
#define BST_MAX_HEIGHT 32
#endif

@

@exercise
Suggest a reason why the |BST_MAX_HEIGHT| macro is defined
conditionally.  Are there any potential pitfalls?

@answer
The purpose for conditional definition of |BST_MAX_HEIGHT| is not to
keep it from being redefined if the header file is included multiple
times.  There's a higher-level ``include guard'' for that (see
@value{includeguard}), and, besides, identical definitions of a macro
are okay in C.  Instead, it is to allow the user to set the maximum
height of binary trees by defining that macro before @(bst.h@> is
|#include|d.  The limit can be adjusted upward for larger computers or
downward for smaller ones.

The main pitfall is that a user program will use different values of
|BST_MAX_HEIGHT| in different source files.  This leads to undefined
behavior.  Less of a problem are definitions to invalid values, which
will be caught at compile time by the compiler.
@end exercise

@node BST Rotations, BST Operations, BST Data Types, Binary Search Trees
@section Rotations

Soon we'll jump right in and start implementing the table functions
for BSTs.  But before that, there's one more topic to discuss, because
they'll keep coming up from time to time throughout the rest of the
book.  This topic is the concept of a @gloss{rotation}.  A rotation is
a simple transformation of a binary tree that looks like this:

@center @image{rotation}

In this diagram, |X| and |Y| represent nodes and |a|, |b|, and |c| are
arbitrary binary trees that may be empty.  A rotation that changes a
binary tree of the form shown on the left to the form shown on the
right is called a @gloss{right rotation} on |Y|.  Going the other way,
it is a @gloss{left rotation} on |X|.

This figure also introduces new graphical conventions.  First, the
line leading vertically down to the root explicitly shows that the BST
may be a subtree of a larger tree.
@iftex
Also, (possible empty) subtrees, as opposed to individual nodes, are
indicated by lowercase letters not enclosed by circles.
@end iftex
@ifnottex
Also, the use of both uppercase and lowercase letters emphasizes the
distinction between individual nodes and subtrees: uppercase letters are
nodes, lowercase letters represent (possibly empty) subtrees.
@end ifnottex

A rotation changes the local structure of a binary tree without changing
its ordering as seen through inorder traversal.  That's a subtle
statement, so let's dissect it bit by bit.  Rotations have the following
properties:

@table @asis
@item Rotations change the structure of a binary tree.
In particular, rotations can often, depending on the tree's shape, be
used to change the height of a part of a binary tree.

@item Rotations change the local structure of a binary tree.
Any given rotation only affects the node rotated and its immediate
children.  The node's ancestors and its children's children are
unchanged.

@item Rotations do not change the ordering of a binary tree.
If a binary tree is a binary search tree before a rotation, it is a
binary search tree after a rotation.  So, we can safely use rotations
to rearrange a BST-based structure, without concerns about upsetting
its ordering.
@end table

@references
@bibref{Cormen 1990}, section 14.2;
@bibref{Sedgewick 1998}, section 12.8.

@exercise
For each of the binary search trees below, perform a right rotation at
node 4.

@center @image{bstrot1}

@answer

@center @image{bstrot2}
@end exercise

@exercise bstrotation
Write a pair of functions, one to perform a right rotation at a given
BST node, one to perform a left rotation.  What should be the type of
the functions' parameter?

@answer
The functions need to adjust the pointer from the rotated subtree's
parent, so they take a double-pointer |struct bst_node **|.  An
alternative would be to accept two parameters: the rotated subtree's
parent node and the |bst_link[]| index of the subtree.

@cat bst Rotation, right
@c tested 2002/1/6
@<Anonymous@> =
/* Rotates right at |*yp|. */
static void @
rotate_right (struct bst_node **yp) @
{
  struct bst_node *y = *yp;
  struct bst_node *x = y->bst_link[0];
  y->bst_link[0] = x->bst_link[1];
  x->bst_link[1] = y;
  *yp = x;
}
@

@cat bst Rotation, left
@c tested 2002/1/6
@<Anonymous@> =
/* Rotates left at |*xp|. */
static void @
rotate_left (struct bst_node **xp) @
{
  struct bst_node *x = *xp;
  struct bst_node *y = x->bst_link[1];
  x->bst_link[1] = y->bst_link[0];
  y->bst_link[0] = x;
  *xp = y;
}

@
@end exercise

@node BST Operations, Creating a BST, BST Rotations, Binary Search Trees
@section Operations

Now can start to implement the operations that we'll want to perform
on BSTs.  Here's the outline of the functions we'll implement.  We use
the generic table insertion convenience functions from
@value{genericinsertreplace} to implement |bst_insert()| and
|bst_replace()|, as well the generic assertion function
implementations from @value{genericassertions} to implement
|tbl_assert_insert()| and |tbl_assert_delete()|.  We also include a
copy of the default memory allocation functions for use with BSTs:

@<BST operations@> =
@<BST creation function@>
@<BST search function@>
@<BST item insertion function@>
@<Table insertion convenience functions; tbl => bst@>
@<BST item deletion function@>
@<BST traversal functions@>
@<BST copy function@>
@<BST destruction function@>
@<BST balance function@>
@<Default memory allocation functions; tbl => bst@>
@<Table assertion functions; tbl => bst@>
@

@node Creating a BST, Searching a BST, BST Operations, Binary Search Trees
@section Creation

We need to write |bst_create()| to create an empty BST.  All it takes is
a little bit of memory allocation and initialization:

@cat bst Creation
@<BST creation function@> =
@iftangle
/* Creates and returns a new table
   with comparison function |compare| using parameter |param|
   and memory allocator |allocator|.
   Returns |NULL| if memory allocation failed. */
@end iftangle
struct bst_table *@
bst_create (bst_comparison_func *compare, void *param,
            struct libavl_allocator *allocator) @
{
  struct bst_table *tree;

  assert (compare != NULL);

  if (allocator == NULL)
    allocator = &bst_allocator_default;

  tree = allocator->libavl_malloc (allocator, sizeof *tree);
  if (tree == NULL)
    return NULL;

  tree->bst_root = NULL;
  tree->bst_compare = compare;
  tree->bst_param = param;
  tree->bst_alloc = allocator;
  tree->bst_count = 0;
  tree->bst_generation = 0;

  return tree;
}

@

@node Searching a BST, Inserting into a BST, Creating a BST, Binary Search Trees
@section Search

Searching a binary search tree works just the same way as it did before
when we were doing it inside an array.  We can implement |bst_find()|
immediately:

@cat bst Search
@<BST search function@> =
@iftangle
/* Search |tree| for an item matching |item|, and return it if found.
   Otherwise return |NULL|. */
@end iftangle
void *@
bst_find (const struct bst_table *tree, const void *item) @
{
  const struct bst_node *p;

  assert (tree != NULL && item != NULL);
  for (p = tree->bst_root; p != NULL; ) @
    {@-
      int cmp = tree->bst_compare (item, p->bst_data, tree->bst_param);

      if (cmp < 0) @
        p = p->bst_link[0];
      else if (cmp > 0) @
        p = p->bst_link[1];
      else /* |cmp == 0| */ @
        return p->bst_data;
    }@+

  return NULL;
}

@

@references
@bibref{Knuth 1998b}, section 6.2.2;
@bibref{Cormen 1990}, section 13.2;
@bibref{Kernighan 1988}, section 3.3;
@bibref{Bentley 2000}, chapters 4 and 5, section 9.3, appendix 1;
@bibref{Sedgewick 1998}, program 12.7.

@node Inserting into a BST, Deleting from a BST, Searching a BST, Binary Search Trees
@section Insertion

Inserting new nodes into a binary search tree is easy.  To start out,
we work the same way as in a search, traversing the tree from the top
down, as if we were searching for the item that we're inserting.  If
we find one, the item is already in the tree, and we need not insert
it again.  But if the new item is not in the tree, eventually we
``fall off'' the bottom of the tree.  At this point we graft the new
item as a child of the node that we last examined.

An example is in order.  Consider this binary search tree:

@center @image{preins}

Suppose that we wish to insert a new item, 7, into the tree.  7 is
greater than 5, so examine 5's right child, 8.  7 is less than 8, so
examine 8's left child, 6.  7 is greater than 6, but 6 has no right
child.  So, make 7 the right child of 6:

@center @image{postins}

We cast this in a form compatible with the abstract description as
follows:

@cat bst Insertion (iterative)
@<BST item insertion function@> =
@iftangle
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree, 
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
@end iftangle
void **@
bst_probe (struct bst_table *tree, void *item) @
{
  struct bst_node *p, *q; /* Current node in search and its parent. */
  int dir;                /* Side of |q| on which |p| is located. */
  struct bst_node *n;     /* Newly inserted node. */

  assert (tree != NULL && item != NULL);

  for (q = NULL, p = tree->bst_root; p != NULL; q = p, p = p->bst_link[dir]) @
    {@-
      int cmp = tree->bst_compare (item, p->bst_data, tree->bst_param);
      if (cmp == 0)
	return &p->bst_data;
      dir = cmp > 0;
    }@+
  
  n = tree->bst_alloc->libavl_malloc (tree->bst_alloc, sizeof *p);
  if (n == NULL)
    return NULL;

  tree->bst_count++;
  n->bst_link[0] = n->bst_link[1] = NULL;
  n->bst_data = item;
  if (q != NULL)
    q->bst_link[dir] = n;
  else @
    tree->bst_root = n;

  return &n->bst_data;
}

@

@references
@bibref{Knuth 1998b}, algorithm 6.2.2T;
@bibref{Cormen 1990}, section 13.3;
@bibref{Bentley 2000}, section 13.3;
@bibref{Sedgewick 1998}, program 12.7.

@exercise rootcast
Explain the expression |p = (struct bst_node *) &tree->bst_root|.
Suggest an alternative.

@answer
This is a dirty trick.  The |bst_root| member of |struct bst_table| is
not a |struct bst_node|, but we are pretending that it is by casting its
address to |struct bst_node *|.  We can get away with this only because
the first member of |struct bst_node *| is |bst_link|, whose first
element |bst_link[0]| is a |struct bst_node *|, the same type as
|bst_root|.  ANSI C guarantees that a pointer to a structure is a
pointer to the structure's first member, so this is fine as long as we
never try to access any member of |*p| except |bst_link[0]|.  Trying to
access other members would result in undefined behavior.

The reason that we want to do this at all is that it means that the
tree's root is not a special case.  Otherwise, we have to deal with the
root separately from the rest of the nodes in the tree, because of its
special status as the only node in the tree not pointed to by the
|bst_link[]| member of a |struct bst_node|.

It is a good idea to get used to these kinds of pointer cast, because
they are common in @libavl{}.

As an alternative, we can declare an actual instance of |struct
bst_node|, store the tree's |bst_root| into its |bst_link[0]|, and copy
its possibly updated value back into |bst_root| when done.  This isn't
very elegant, but it works.  This technique is used much later in this
book, in @<TBST main copy function@>.  A different kind of alternative
approach is used in @value{bstprobedblptrbrief}.
@end exercise

@exercise bstprobedblptr
Rewrite |bst_probe()| to use only a single local variable of type
|struct bst_node **|.

@answer
Here, pointer-to-pointer |q| traverses the tree, starting with a pointer
to the root, comparing each node found against |item| while looking for
a null pointer.  If an item equal to |item| is found, it returns a
pointer to the item's data.  Otherwise, |q| receives the address of the
|NULL| pointer that becomes the new node, the new node is created, and a
pointer to its data is returned.

@cat bst Insertion, using pointer to pointer
@c tested 2001/11/19
@<BST item insertion function, alternate version@> =
@iftangle
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree, 
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
@end iftangle
void **@
bst_probe (struct bst_table *tree, void *item) @
{
  struct bst_node **q;
  int cmp;

  assert (tree != NULL && item != NULL);
  
  for (q = &tree->bst_root; *q != NULL; q = &(*q)->bst_link[cmp > 0]) @
    {@-
      cmp = tree->bst_compare (item, (*q)->bst_data, tree->bst_param);
      if (cmp == 0)
        return &(*q)->bst_data;
    }@+

  *q = tree->bst_alloc->libavl_malloc (tree->bst_alloc, sizeof **q);
  if (*q == NULL)
    return NULL;

  (*q)->bst_link[0] = (*q)->bst_link[1] = NULL;
  (*q)->bst_data = item;
  tree->bst_count++;
  return &(*q)->bst_data;
}
@
@end exercise

@exercise copyinsorder
Suppose we want to make a new copy of an existing binary search tree,
preserving the original tree's shape, by inserting items into a new,
currently empty tree.  What constraints are there on the order of item
insertion?

@answer
The first item to be inserted have the value of the original tree's
root.  After that, at each step, we can insert either an item with the
value of either child |x| of any node in the original tree
corresponding to a node |y| already in the copy tree, as long as |x|'s
value is not already in the copy tree.
@end exercise

@exercise levelorder
Write a function that calls a provided |bst_item_func| for each node
in a provided BST in an order suitable for reproducing the original
BST, as discussed in @value{copyinsorderbrief}.

@answer
The function below traverses |tree| in ``level order''.  That is, it
visits the root, then the root's children, then the children of the
root's children, and so on, so that all the nodes at a particular
level in the tree are visited in sequence.

@references
@bibref{Sedgewick 1998}, Program 5.16.

@cat bst Traversal, level order
@c tested 2001/11/10
@<Level-order traversal@> =
/* Calls |visit| for each of the nodes in |tree| in level order.
   Returns nonzero if successful, zero if out of memory. */
static int @
bst_traverse_level_order (struct bst_table *tree, bst_item_func *visit) @
{
  struct bst_node **queue;
  size_t head, tail;

  if (tree->bst_count == 0)
    return 1;
  
  queue = tree->bst_alloc->libavl_malloc (tree->bst_alloc, @
					  sizeof *queue * tree->bst_count);
  if (queue == NULL)
    return 0;

  head = tail = 0;
  queue[head++] = tree->bst_root;
  while (head != tail) @
    {@-
      struct bst_node *cur = queue[tail++];
      visit (cur->bst_data, tree->bst_param);
      if (cur->bst_link[0] != NULL)
	queue[head++] = cur->bst_link[0];
      if (cur->bst_link[1] != NULL)
	queue[head++] = cur->bst_link[1];
    }@+
  tree->bst_alloc->libavl_free (tree->bst_alloc, queue);

  return 1;
}
@
@end exercise

@menu
* Root Insertion in a BST::     
@end menu

@node Root Insertion in a BST,  , Inserting into a BST, Inserting into a BST
@subsection Aside: Root Insertion

One side effect of the usual method for BST insertion, implemented in
the previous section, is that items inserted more recently tend to be
farther from the root, and therefore it takes longer to find them than
items inserted longer ago.  If all items are equally likely to be
requested in a search, this is unimportant, but this is regrettable
for some common usage patterns, where recently inserted items tend to
be searched for more often than older items.

In this section, we examine an alternative scheme for insertion that
addresses this problem, called ``insertion at the root'' or ``root
insertion''.  An insertion with this algorithm always places the new
node at the root of the tree.  Following a series of such insertions,
nodes inserted more recently tend to be nearer the root than other
nodes.

As a first attempt at implementing this idea, we might try simply
making the new node the root and assigning the old root as one of its
children.  Unfortunately, this and similar approaches will not work
because there is no guarantee that nodes in the existing tree have
values all less than or all greater than the new node.

An approach that will work is to perform a conventional insertion as a
leaf node, then use a series of rotations to move the new node to the
root.  For example, the diagram below illustrates rotations to move
node 4 to the root.  A left rotation on 3 changes the first tree into
the second, a right rotation on 5 changes the second into the third,
and finally a left rotation on 1 moves 4 into the root position:

@center @image{rootins}

The general rule follows the pattern above.  If we moved down to the
left from a node |x| during the insertion search, we rotate right at
|x|.  If we moved down to the right, we rotate left.

The implementation is straightforward.  As we search for the insertion
point we keep track of the nodes we've passed through, then after the
insertion we return to each of them in reverse order and perform a
rotation:

@cat bst Insertion, as root
@c tested 2001/11/10
@<BST item insertion function, root insertion version@> =
@iftangle
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree, 
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
@end iftangle
void **@
bst_probe (struct bst_table *tree, void *item) @
{
  @<|rb_probe()| local variables; rb => bst@>

  @<Step 1: Search BST for insertion point, root insertion version@>
  @<Step 2: Insert new BST node, root insertion version@>
  @<Step 3: Move BST node to root@>

  return &n->bst_data;
}
@

@<Step 1: Search BST for insertion point, root insertion version@> =
pa[0] = (struct bst_node *) &tree->bst_root;
da[0] = 0;
k = 1;
for (p = tree->bst_root; p != NULL; p = p->bst_link[da[k - 1]]) @
  {@-
    int cmp = tree->bst_compare (item, p->bst_data, tree->bst_param);
    if (cmp == 0)
      return &p->bst_data;

    if (k >= BST_MAX_HEIGHT) @
      {@-
        bst_balance (tree);
        return bst_probe (tree, item);
      }@+

    pa[k] = p;
    da[k++] = cmp > 0;
  }@+

@

@<Step 2: Insert new BST node, root insertion version@> =
n = pa[k - 1]->bst_link[da[k - 1]] =
  tree->bst_alloc->libavl_malloc (tree->bst_alloc, sizeof *n);
if (n == NULL)
  return NULL;

n->bst_link[0] = n->bst_link[1] = NULL;
n->bst_data = item;
tree->bst_count++;
tree->bst_generation++;

@

@<Step 3: Move BST node to root@> =
for (; k > 1; k--) @
  {@-
    struct bst_node *q = pa[k - 1];

    if (da[k - 1] == 0) @
      {@-
        q->bst_link[0] = n->bst_link[1];
        n->bst_link[1] = q;
      }@+ @
    else /* |da[k - 1] == 1| */ @
      {@-
        q->bst_link[1] = n->bst_link[0];
        n->bst_link[0] = q;
      }@+
    pa[k - 2]->bst_link[da[k - 2]] = n;
  }@+
@
  
@references
@bibref{Sedgewick 1998}, section 12.8.

@exercise rootins1
Root insertion will prove useful later when we write a function to
join a pair of disjoint BSTs (@pxref{Joining BSTs}).  For that
purpose, we need to be able to insert a preallocated node as the root
of an arbitrary tree that may be a subtree of some other tree.  Write
a function to do this matching the following prototype:

@<Anonymous@> =
static int root_insert (struct bst_table *tree, struct bst_node **root,
                        struct bst_node *new_node);
@

@noindent
Your function should insert |new_node| at |*root| using root
insertion, storing |new_node| into |*root|, and return nonzero only if
successful.  The subtree at |*root| is in |tree|.  You may assume that
no node matching |new_node| exists within subtree |root|.

@answer
@c tested 2001/11/10
@cat bst Insertion, as root, of existing node in arbitrary subtree
@<Root insertion of existing node in arbitrary subtree@> =
/* Performs root insertion of |n| at |root| within |tree|.
   Subtree |root| must not contain a node matching |n|.
   Returns nonzero only if successful. */
static int @
root_insert (struct bst_table *tree, struct bst_node **root, 
	     struct bst_node *n) @
{
  struct bst_node *pa[BST_MAX_HEIGHT]; /* Nodes on stack. */
  unsigned char da[BST_MAX_HEIGHT];    /* Directions moved from stack nodes. */
  int k;                               /* Stack height. */

  struct bst_node *p; /* Traverses tree looking for insertion point. */

  assert (tree != NULL && n != NULL);
  
  @<Step 1: Search for insertion point in arbitrary subtree@>
  @<Step 2: Insert |n| into arbitrary subtree@>
  @<Step 3: Move BST node to root@>

  return 1;
}
@

@<Step 1: Search for insertion point in arbitrary subtree@> =
pa[0] = (struct bst_node *) root;
da[0] = 0;
k = 1;
for (p = *root; p != NULL; p = p->bst_link[da[k - 1]]) @
  {@-
    int cmp = tree->bst_compare (n->bst_data, p->bst_data, tree->bst_param);
    assert (cmp != 0);

    if (k >= BST_MAX_HEIGHT)
      return 0;

    pa[k] = p;
    da[k++] = cmp > 0;
  }@+

@

@<Step 2: Insert |n| into arbitrary subtree@> =
pa[k - 1]->bst_link[da[k - 1]] = n;

@

@end exercise

@exercise rootins2
Now implement a root insertion as in @value{rootins1brief}, except
that the function is not allowed to fail, and rebalancing the tree is
not acceptable either.  Use the same prototype with the return type
changed to |void|.

@answer
The idea is to optimize for the common case but allow for fallback to
a slower algorithm that doesn't require a stack when necessary.

@cat bst Insertion, as root, of existing node in arbitrary subtree, robustly
@c tested 2001/11/10
@<Robust root insertion of existing node in arbitrary subtree@> =
/* Performs root insertion of |n| at |root| within |tree|.
   Subtree |root| must not contain a node matching |n|.
   Never fails and will not rebalance |tree|. */
static void @
root_insert (struct bst_table *tree, struct bst_node **root, 
	     struct bst_node *n) @
{
  struct bst_node *pa[BST_MAX_HEIGHT]; /* Nodes on stack. */
  unsigned char da[BST_MAX_HEIGHT];    /* Directions moved from stack nodes. */
  int k;                               /* Stack height. */
  int overflow = 0;                    /* Set nonzero if stack overflowed. */

  struct bst_node *p; /* Traverses tree looking for insertion point. */

  assert (tree != NULL && n != NULL);

  @<Step 1: Robustly search for insertion point in arbitrary subtree@>
  @<Step 2: Insert |n| into arbitrary subtree@>
  @<Step 3: Robustly move BST node to root@>
}
@

If the stack overflows while we're searching for the insertion point,
we stop keeping track of any nodes but the last one and set |overflow|
so that later we know that overflow occurred:

@<Step 1: Robustly search for insertion point in arbitrary subtree@> =
pa[0] = (struct bst_node *) root;
da[0] = 0;
k = 1;
for (p = *root; p != NULL; p = p->bst_link[da[k - 1]]) @
  {@-
    int cmp = tree->bst_compare (n->bst_data, p->bst_data, tree->bst_param);
    assert (cmp != 0);

    if (k >= BST_MAX_HEIGHT) @
      {@-
        overflow = 1;
        k--;
      }@+     

    pa[k] = p;
    da[k++] = cmp > 0;
  }@+

@

Once we've inserted the node, we deal with the rotation in the same
way as before if there was no overflow.  If overflow occurred, we
instead do the rotations one by one, with a full traversal from
|*root| every time:

@<Step 3: Robustly move BST node to root@> =
if (!overflow)
  { @
    @<Step 3: Move BST node to root@> @
  }
else @
  {@-
    while (*root != n) @
      {@-
        struct bst_node **r; /* Link to node to rotate. */
        struct bst_node *q;  /* Node to rotate. */
        int dir;

        for (r = root; ; r = &q->bst_link[dir]) @
          {@-
            q = *r;
            dir = 0 < tree->bst_compare (n->bst_data, q->bst_data, @
                                         tree->bst_param);

            if (q->bst_link[dir] == n)
              break;
          }@+

        if (dir == 0) @
          {@-
            q->bst_link[0] = n->bst_link[1];
            n->bst_link[1] = q;
          }@+ @
        else @
          {@-
            q->bst_link[1] = n->bst_link[0];
            n->bst_link[0] = q;
          }@+
        *r = n;
      }@+
  }@+
@
@end exercise

@exercise*
Suppose that we perform a series of root insertions in an initially
empty BST.  What kinds of insertion orders require a large amount of
stack?

@answer
One insertion order that does @emph{not} require much stack is
ascending order.  If we insert 1@dots{}4 at the root in ascending
order, for instance, we get a BST that looks like this:

@center @image{rootins2}

@noindent
If we then insert node 5, it will immediately be inserted as the right
child of 4, and then a left rotation will make it the root, and we're
back where we started without ever using more than one stack entry.
Other obvious pathological orders such as descending order and
``zig-zag'' order behave similarly.

One insertion order that does require an arbitrary amount of stack
space is to first insert 1@dots{}|n| in ascending order, then the
single item 0.  Each of the first group of insertions requires only
one stack entry (except the first, which does not use any), but the
final insertion uses |n - 1|.

If we're interested in high average consumption of stack space, the
pattern consisting of a series of ascending insertions |(n / 2 +
1)|@dots{}|n| followed by a second ascending series 1@dots{}|(n / 2)|,
for even |n|, is most effective.  For instance, each insertion for
insertion order 6, 7, 8, 9, 10, 1, 2, 3, 4, 5 requires 0, 1, 1, 1, 1,
5, 6, 6, 6, 6 stack entries, respectively, for a total of 33.

These are, incidentally, the best possible results in each category,
as determined by exhaustive search over the |10! @= 3,628,800|
possible root insertion orders for trees of 10 nodes.  (Thanks to
Richard Heathfield for suggesting exhaustive search.)
@end exercise

@node Deleting from a BST, Traversing a BST, Inserting into a BST, Binary Search Trees
@section Deletion

Deleting an item from a binary search tree is a little harder than
inserting one.  Before we write any code, let's consider how to delete
nodes from a binary search tree in an abstract fashion.  Here's a BST
from which we can draw examples during the discussion:

@center @image{bstdel}

It is more difficult to remove some nodes from this tree than to remove
others.  Here, we recognize three distinct cases (@value{bstdelcase15}
offers a fourth), described in detail below in terms of the deletion of
a node designated |p|.

@subsubheading Case 1: |p| has no right child

@anchor{bstdelcase1}
It is trivial to delete a node with no right child, such as node 1, 4,
7, or 8 above.  We replace the pointer leading to |p| by |p|'s left
child, if it has one, or by a null pointer, if not.  In other words,
we replace the deleted node by its left child.  For example, the
process of deleting node 8 looks like this:

@center @image{bstdel2}

@ifinfo
This diagram shows the convention of separating multiple labels on a
single node by a comma: node 8 is also node |p|.
@end ifinfo

@subsubheading Case 2: |p|'s right child has no left child
@anchor{bstdelcase2}

This case deletes any node |p| with a right child |r| that itself has no
left child.  Nodes 2, 3, and 6 in the tree above are examples.  In this
case, we move |r| into |p|'s place, attaching |p|'s former left subtree,
if any, as the new left subtree of |r|.  For instance, to delete node 2
in the tree above, we can replace it by its right child 3, giving node
2's left child 1 to node 3 as its new left child.  The process looks
like this:

@center @image{bstdel3}

@subsubheading Case 3: |p|'s right child has a left child
@anchor{bstdelcase3}

This is the ``hard'' case, where |p|'s right child |r| has a left child.
but if we approach it properly we can make it make sense.  Let |p|'s
@gloss{inorder successor}, that is, the node with the smallest value
greater than |p|, be |s|.  Then, our strategy is to detach |s| from its
position in the tree, which is always an easy thing to do, and put it
into the spot formerly occupied by |p|, which disappears from the tree.
In our example, to delete node 5, we move inorder successor node 6 into
its place, like this:

@center @image{bstdel4}

@anchor{successor}
But how do we know that node |s| exists and that we can delete it
easily?  We know that it exists because otherwise this would be case 1
or case 2 (consider their conditions).  We can easily detach from its
position for a more subtle reason: |s| is the inorder successor of |p|
and is therefore has the smallest value in |p|'s right subtree, so |s|
cannot have a left child.  (If it did, then this left child would have
a smaller value than |s|, so it, rather than |s|, would be |p|'s
inorder successor.)  Because |s| doesn't have a left child, we can
simply replace it by its right child, if any.  This is the mirror
image of case 1.

@subsubheading Implementation

The code for BST deletion closely follows the above discussion.  Let's
start with an outline of the function:

@cat bst Deletion (iterative)
@<BST item deletion function@> =
@iftangle
/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
@end iftangle
void *@
bst_delete (struct bst_table *tree, const void *item) @
{
  struct bst_node *p, *q; /* Node to delete and its parent. */
  int cmp;                /* Comparison between |p->bst_data| and |item|. */
  int dir;                /* Side of |q| on which |p| is located. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Find BST node to delete@>
  @<Step 2: Delete BST node@>
  @<Step 3: Finish up after deleting BST node@>
}

@

We begin by finding the node to delete, in much the same way that
|bst_find()| did.  But, in every case above, we replace the link leading
to the node being deleted by another node or a null pointer.  To do so,
we have to keep track of the pointer that led to the node to be deleted.
This is the purpose of |q| and |dir| in the code below.

@<Step 1: Find BST node to delete@> =
p = (struct bst_node *) &tree->bst_root;
for (cmp = -1; cmp != 0; @
     cmp = tree->bst_compare (item, p->bst_data, tree->bst_param)) @
  {@-
    dir = cmp > 0;
    q = p;
    p = p->bst_link[dir];
    if (p == NULL)
      return NULL;
  }@+
item = p->bst_data;

@

Now we can actually delete the node.  Here is the code to distinguish
between the three cases:

@<Step 2: Delete BST node@> =
@ifweave
if (p->bst_link[1] == NULL) { @<Case 1 in BST deletion@> }
@end ifweave
@iftangle
if (p->bst_link[1] == NULL)
  @<Case 1 in BST deletion@>
@end iftangle
else @
  {@-
    struct bst_node *r = p->bst_link[1];
    if (r->bst_link[0] == NULL) @
      {@-
        @<Case 2 in BST deletion@>
      }@+ @
    else @
      {@-
        @<Case 3 in BST deletion@>
      }@+
  }@+

@

In case 1, we simply replace the node by its left subtree:

@<Case 1 in BST deletion@> =
q->bst_link[dir] = p->bst_link[0];
@

In case 2, we attach the node's left subtree as its right child |r|'s
left subtree, then replace the node by |r|:

@<Case 2 in BST deletion@> =
r->bst_link[0] = p->bst_link[0];
q->bst_link[dir] = r;
@

We begin case 3 by finding |p|'s inorder successor as |s|, and the
parent of |s| as |r|.  Node |p|'s inorder successor is the smallest
value in |p|'s right subtree and that the smallest value in a tree can
be found by descending to the left until a node with no left child is
found:

@<Case 3 in BST deletion@> =
struct bst_node *s;
for (;;) @
  {@-
    s = r->bst_link[0];
    if (s->bst_link[0] == NULL)
      break;

    r = s;
  }@+
@

Case 3 wraps up by adjusting pointers so that |s| moves into |p|'s
place:

@<Case 3 in BST deletion@> +=
r->bst_link[0] = s->bst_link[1];
s->bst_link[0] = p->bst_link[0];
s->bst_link[1] = p->bst_link[1];
q->bst_link[dir] = s;
@

As the final step, we decrement the number of nodes in the tree, free
the node, and return its data:

@<Step 3: Finish up after deleting BST node@> =
tree->bst_alloc->libavl_free (tree->bst_alloc, p);
tree->bst_count--;
tree->bst_generation++;
return (void *) item;
@

@references
@bibref{Knuth 1998b}, algorithm 6.2.2D;
@bibref{Cormen 1990}, section 13.3.

@exercise bstdelcase15
Write code for a case 1.5 which handles deletion of nodes with no left
child.

@answer
Add this before the top-level |else| clause in @<Step 2: Delete BST node@>:

@cat bst Deletion, special case for no left child
@c tested 2001/11/10
@<Case 1.5 in BST deletion@> =
else if (p->bst_link[0] == NULL) @
  q->bst_link[dir] = p->bst_link[1];
@    
@end exercise

@exercise bstaltdel
In the code presented above for case 3, we update pointers to move
|s| into |p|'s position, then free |p|.  An alternate approach
is to replace |p|'s data by |s|'s and delete |s|.  Write code to
use this approach.  Can a similar modification be made to either of the
other cases?

@answer
Be sure to look at @value{modifydatabrief} before actually making this
change.

@cat bst Deletion, with data modification
@c tested 2001/11/10
@<Case 3 in BST deletion, alternate version@> =
struct bst_node *s = r->bst_link[0];
while (s->bst_link[0] != NULL) @
  {@-
    r = s;
    s = r->bst_link[0];
  }@+
p->bst_data = s->bst_data;
r->bst_link[0] = s->bst_link[1];
p = s;
@

We could, indeed, make similar changes to the other cases, but for these
cases the code would become more complicated, not simpler.
@end exercise

@exercise* modifydata
The code in the previous exercise is a few lines shorter than that in
the main text, so it would seem to be preferable.  Explain why the
revised code, and other code based on the same idea, cannot be used in
@libavl{}.  (Hint: consider the semantics of @libavl{} traversers.)

@answer
The semantics for @libavl{} traversers only invalidate traversers with
the deleted item selected, but the revised code would actually free the
node of the successor to that item.  Because |struct bst_traverser|
keeps a pointer to the |struct bst_node| of the current item, attempts
to use a traverser that had selected the successor of the deleted item
would result in undefined behavior.

Some other binary tree libraries have looser semantics on their
traversers, so they can afford to use this technique.
@end exercise

@menu
* Deletion by Merging::         
@end menu

@node Deletion by Merging,  , Deleting from a BST, Deleting from a BST
@subsection Aside: Deletion by Merging

The @libavl{} algorithm for deletion is commonly used, but it is also
seemingly ad-hoc and arbitrary in its approach.  In this section we'll
take a look at another algorithm that may seem a little more uniform.
Unfortunately, though it is conceptually simpler in some ways, in
practice this algorithm is both slower and more difficult to properly
implement.

The idea behind this algorithm is to consider deletion as breaking the
links between the deleted node and its parent and children.  In the
most general case, we end up with three disconnected BSTs, one that
contains the deleted node's parent and two corresponding to the
deleted node's former subtrees.  The diagram below shows how this idea
works out for the deletion of node 5 from the tree on the left:

@center @image{rotdel}

Of course, the problem then becomes to reassemble the pieces into a
single binary search tree.  We can do this by merging the two former
subtrees of the deleted node and attaching them as the right child of
the parent subtree.  As the first step in merging the subtrees, we
take the minimum node |r| in the former right subtree and repeatedly
perform a right rotation on its parent, until it is the root of its
subtree.  The process up to this point looks like this for our
example, showing only the subtree containing |r|:

@center @image{rotdel2}

Now, because |r| is the root and the minimum node in its subtree, |r|
has no left child.  Also, all the nodes in the opposite subtree are
smaller than |r|.  So to merge these subtrees, we simply link the
opposite subtree as |r|'s left child and connect |r| in place of the
deleted node:

@center @image{rotdel3}

The function outline is straightforward:

@cat bst Deletion, by merging
@c tested 2001/11/10
@<BST item deletion function, by merging@> =
@iftangle
/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
@end iftangle
void *@
bst_delete (struct bst_table *tree, const void *item) @
{
  struct bst_node *p;   /* The node to delete, or a node part way to it. */
  struct bst_node *q;	/* Parent of |p|. */
  int cmp, dir;         /* Result of comparison between |item| and |p|. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Find BST node to delete by merging@>
  @<Step 2: Delete BST node by merging@>
  @<Step 3: Finish up after BST deletion by merging@>  

  return (void *) item;
}
@

First we search for the node to delete, storing it as |p| and its
parent as |q|:

@<Step 1: Find BST node to delete by merging@> =
p = (struct bst_node *) &tree->bst_root;
for (cmp = -1; cmp != 0; @
     cmp = tree->bst_compare (item, p->bst_data, tree->bst_param)) @
  {@-
    dir = cmp > 0;
    q = p;
    p = p->bst_link[dir];
    if (p == NULL)
      return NULL;
  }@+

@

The actual deletion process is not as simple.  We handle specially the
case where |p| has no right child.  This is unfortunate for
uniformity, but simplifies the rest of the code considerably.  The
main case starts off with a loop on variable |r| to build a stack of
the nodes in the right subtree of |p| that will need to be rotated.
After the loop, |r| is the minimum value in |p|'s right subtree.  This
will be the new root of the merged subtrees after the rotations, so we
set |r| as |q|'s child on the appropriate side and |r|'s left child as
|p|'s former left child.  After that the only remaining task is the
rotations themselves, so we perform them and we're done:

@<Step 2: Delete BST node by merging@> =
if (p->bst_link[1] != NULL) @
  {@-
    struct bst_node *pa[BST_MAX_HEIGHT]; /* Nodes on stack. */
    unsigned char da[BST_MAX_HEIGHT];    /* Directions moved from stack nodes. */
    int k = 0;                           /* Stack height. */

    struct bst_node *r; /* Iterator; final value is minimum node in subtree. */

    for (r = p->bst_link[1]; r->bst_link[0] != NULL; r = r->bst_link[0]) @
      {@-
        if (k >= BST_MAX_HEIGHT) @
          {@-
            bst_balance (tree);
            return bst_delete (tree, item);
          }@+

        pa[k] = r;
        da[k++] = 0;
      }@+
    q->bst_link[dir] = r;
    r->bst_link[0] = p->bst_link[0];

    for (; k > 0; k--) @
      {@-
        struct bst_node *y = pa[k - 1];
        struct bst_node *x = y->bst_link[0];
        y->bst_link[0] = x->bst_link[1];
        x->bst_link[1] = y;
        if (k > 1)
          pa[k - 2]->bst_link[da[k - 2]] = x;
      }@+
  }@+
else @
  q->bst_link[dir] = p->bst_link[0];

@

Finally, there's a bit of obligatory bookkeeping:

@<Step 3: Finish up after BST deletion by merging@> =
item = p->bst_data;
tree->bst_alloc->libavl_free (tree->bst_alloc, p);
tree->bst_count--;
tree->bst_generation++;
@

@references
@bibref{Sedgewick 1998}, section 12.9.

@node Traversing a BST, Copying a BST, Deleting from a BST, Binary Search Trees
@section Traversal

After we've been manipulating a binary search tree for a while, we will
want to know what items are in it.  The process of enumerating the items
in a binary search tree is called @gloss{traversal}.  @libavl{} provides
the |bst_t_*| functions for a particular kind of traversal called
@gloss{inorder traversal}, so-called because items are enumerated in
sorted order.

In this section we'll implement three algorithms for traversal.  Each of
these algorithms is based on and in some way improves upon the previous
algorithm.  The final implementation is the one used in @libavl{}, so we
will implement all of the |bst_t_*| functions for it.

Before we start looking at particular algorithms, let's consider some
criteria for evaluating traversal algorithms.  The following are not the
only criteria that could be used, but they are indeed
important:@footnote{Some of these terms are not generic BST vocabulary.
Rather, they have been adopted for these particular uses in this text.
You can consider the above to be our working definitions of these
terms.}

@table @b
@item complexity
Is it difficult to describe or to correctly implement the algorithm?
Complex algorithms also tend to take more code than simple ones.

@item efficiency
Does the algorithm make good use of time and memory?  The ideal
traversal algorithm would require time proportional to the number of
nodes traversed and a constant amount of space.  In this chapter we will
meet this ideal time criterion and come close on the space criterion for
the average case.  In future chapters we will be able to do better even
in the worst case.

@item convenience
Is it easy to integrate the traversal functions into other code?
Callback functions are not as easy to use as other methods that can be
used from |for| loops (@pxref{Improving Convenience}).

@item reliability
Are there pathological cases where the algorithm breaks down?  If so, is
it possible to fix these problems using additional time or space?

@item generality
Does the algorithm only allow iteration in a single direction?  Can we
begin traversal at an arbitrary node, or just at the least or greatest
node?

@item resilience
If the tree is modified during a traversal, is it possible to continue
traversal, or does the modification invalidate the traverser?
@end table

The first algorithm we will consider uses recursion.  This algorithm is
worthwhile primarily for its simplicity.  In C, such an algorithm cannot
be made as efficient, convenient, or general as other algorithms without
unacceptable compromises.  It is possible to make it both reliable and
resilient, but we won't bother because of its other drawbacks.

We arrive at our second algorithm through a literal transformation of
the recursion in the first algorithm into iteration.  The use of
iteration lets us improve the algorithm's memory efficiency, and, on
many machines, its time efficiency as well.  The iterative algorithm
also lets us improve the convenience of using the traverser.  We could
also add reliability and resilience to an implementation of this
algorithm, but we'll save that for later.  The only problem with this
algorithm, in fact, lies in its generality: it works best for moving
only in one direction and starting from the least or greatest node.

The importance of generality is what draws us to the third algorithm.
This algorithm is based on ideas from the previous iterative algorithm
along with some simple observations.  This algorithm is no more complex
than the previous one, but it is more general, allowing easily for
iteration in either direction starting anywhere in the tree.  This is
the algorithm used in @libavl{}, so we build an efficient, convenient,
reliable, general, resilient implementation.

@menu
* Recursive Traversal of a BST::  
* Iterative Traversal of a BST::  
* Better Iterative Traversal::  
@end menu

@node Recursive Traversal of a BST, Iterative Traversal of a BST, Traversing a BST, Traversing a BST
@subsection Traversal by Recursion

To figure out how to traverse a binary search tree in inorder, think
about a BST's structure.  A BST consists of a root, a left subtree, and
right subtree.  All the items in the left subtree have smaller values
than the root and all the items in the right subtree have larger values
than the root.

That's good enough right there: we can traverse a BST in inorder by
dealing with its left subtree, then doing with the root whatever it is
we want to do with each node in the tree (generically, @gloss{visit} the
root node), then dealing with its right subtree.  But how do we deal
with the subtrees?  Well, they're BSTs too, so we can do the same thing:
traverse its left subtree, then visit its root, then traverse its right
subtree, and so on.  Eventually the process terminates because at some
point the subtrees are null pointers, and nothing needs to be done to
traverse an empty tree.

Writing the traversal function is almost trivial.  We use
|bst_item_func| to visit a node (@pxref{Item and Copy Functions}):

@cat bst Traversal, recursive
@c tested 2001/6/27
@<Recursive traversal of BST@> =
static void @
traverse_recursive (struct bst_node *node, bst_item_func *action, void *param) @
{
  if (node != NULL) @
    {@-
      traverse_recursive (node->bst_link[0], action, param);
      action (node->bst_data, param);
      traverse_recursive (node->bst_link[1], action, param);
    }@+
}
@

We also want a wrapper function to insulate callers from the existence
of individual tree nodes:

@c tested 2000/7/8
@<Recursive traversal of BST@> +=
void @
walk (struct bst_table *tree, bst_item_func *action, void *param) @
{
  assert (tree != NULL && action != NULL);
  traverse_recursive (tree->bst_root, action, param);
}
@

@references
@bibref{Knuth 1997}, section 2.3.1;
@bibref{Cormen 1990}, section 13.1;
@bibref{Sedgewick 1998}, program 12.8.

@exercise
Instead of checking for a null |node| at the top of
|traverse_recursive()|, would it be better to check before calling in
each place that the function is called?  Why or why not?

@answer
It would probably be faster to check before each call rather than after,
because this way many calls would be avoided.  However, it might be more
difficult to maintain the code, because we would have to remember to
check for a null pointer before every call.  For instance, the call to
|traverse_recursive()| within |walk()| might easily be overlooked.
Which is ``better'' is therefore a toss-up, dependent on a program's
goals and the programmer's esthetic sense.
@end exercise

@exercise
Some languages, such as Pascal, support the concept of @dfn{nested
functions}, that is, functions within functions, but C does not.  Some
algorithms, including recursive tree traversal, can be expressed much
more naturally with this feature.  Rewrite |walk()|, in a hypothetical
C-like language that supports nested functions, as a function that calls
an inner, recursively defined function.  The nested function should only
take a single parameter.  (The GNU C compiler supports nested functions
as a language extension, so you may want to use it to check your code.)

@answer
@cat bst Traversal, recursive; with nested function
@c tested 2001/6/27
@<Recursive traversal of BST, using nested function@> =
void @
walk (struct bst_table *tree, bst_item_func *action, void *param) @
{
  void @
  traverse_recursive (struct bst_node *node) @
  {
    if (node != NULL) @
      {@-
        traverse_recursive (node->bst_link[0]);
        action (node->bst_data, param);
        traverse_recursive (node->bst_link[1]);
      }@+
  }

  assert (tree != NULL && action != NULL);
  traverse_recursive (tree->bst_root);
}
@
@end exercise

@node Iterative Traversal of a BST, Better Iterative Traversal, Recursive Traversal of a BST, Traversing a BST
@subsection Traversal by Iteration

The recursive approach of the previous section is one valid way to
traverse a binary search tree in sorted order.  This method has the
advantages of being simple and ``obviously correct''.  But it does have
problems with efficiency, because each call to |traverse_recursive()|
receives its own duplicate copies of arguments |action| and |param|, and
with convenience, because writing a new callback function for each
traversal is unpleasant.  It has other problems, too, as already
discussed, but these are the ones to be addressed immediately.

Unfortunately, neither problem can be solved acceptably in C using a
recursive method, the first because the traversal function has to
somehow know the action function and the parameter to pass to it, and
the second because there is simply no way to jump out of and then back
into recursive calls in C.@footnote{This is possible in some other
languages, such as Scheme, that support ``coroutines'' as well as
subroutines.}  Our only option is to use an algorithm that does not
involve recursion.

The simplest way to eliminate recursion is by a literal conversion of
the recursion to iteration.  This is the topic of this section.
Later, we will consider a slightly different, and in some ways
superior, iterative solution.

Converting recursion into iteration is an interesting problem.
There are two main ways to do it:

@table @b
@item tail recursion elimination
If a recursive call is the last action taken in a function, then it is
equivalent to a |goto| back to the beginning of the function, possibly
after modifying argument values.  (If the function has a return value
then the recursive call must be a |return| statement returning the value
received from the nested call.)  This form of recursion is called
@gloss{tail recursion}.

@item save-and-restore recursion elimination
In effect, a recursive function call saves a copy of argument values and
local variables, modifies the arguments, then executes a |goto| to the
beginning of the function.  Accordingly, the return from the nested call
is equivalent to restoring the saved arguments and local variables, then
executing a |goto| back to the point where the call was made.
@end table

We can make use of both of these rules in converting
|traverse_recursive()| to iterative form.  First, does
|traverse_recursive()| ever call itself as its last action?  The answer
is yes, so we can convert that to an assignment plus a |goto| statement:

@c tested 2001/6/27
@<Iterative traversal of BST, take 1@> =
static void @
traverse_iterative (struct bst_node *node, bst_item_func *action, void *param) @
{
start:
  if (node != NULL) @
    {@-
      traverse_iterative (node->bst_link[0], action, param);
      action (node->bst_data, param);
      node = node->bst_link[1];
      goto start;
    }@+
}
@

Sensible programmers are not fond of |goto|.  Fortunately, it is easy to
eliminate by rephrasing in terms of a |while| loop:

@c tested 2001/6/27
@<Iterative traversal of BST, take 2@> =
static void @
traverse_iterative (struct bst_node *node, bst_item_func *action, void *param) @
{
  while (node != NULL) @
    {@-
      traverse_iterative (node->bst_link[0], action, param);
      action (node->bst_data, param);
      node = node->bst_link[1];
    }@+
}
@

This still leaves another recursive call, one that is not tail
recursive.  This one must be eliminated by saving and restoring
values.  A stack is ideal for this purpose.  For now, we use a stack
of fixed size |BST_MAX_HEIGHT| and deal with stack overflow by
aborting.  Later, we'll handle overflow more gracefully.  Here's the
code:

@c tested 2001/6/27
@<Iterative traversal of BST, take 3@> =
static void @
traverse_iterative (struct bst_node *node, bst_item_func *action, void *param) @
{
  struct bst_node *stack[BST_MAX_HEIGHT];
  size_t height = 0;

start:
  while (node != NULL) @
    {@-
      if (height >= BST_MAX_HEIGHT) @
        {@-
          fprintf (stderr, "tree too deep\n");
          exit (EXIT_FAILURE);
        }@+
      stack[height++] = node;
      node = node->bst_link[0];
      goto start;

    resume:
      action (node->bst_data, param);
      node = node->bst_link[1];
    }@+
  
  if (height > 0) @
    {@-
      node = stack[--height];
      goto resume;
    }@+
}
@

This code, an ugly mash of statements, is a prime example of why |goto|
statements are discouraged, but its relationship with the earlier code
is clear.  To make it acceptable for real use, we must rephrase it.
First, we can eliminate label |resume| by recognizing that it can only
be reached from the corresponding |goto| statement, then moving its code
appropriately:

@c tested 2001/6/27
@<Iterative traversal of BST, take 4@> =
static void @
traverse_iterative (struct bst_node *node, bst_item_func *action, void *param) @
{
  struct bst_node *stack[BST_MAX_HEIGHT];
  size_t height = 0;

start:
  while (node != NULL) @
    {@-
      if (height >= BST_MAX_HEIGHT) @
        {@-
          fprintf (stderr, "tree too deep\n");
          exit (EXIT_FAILURE);
        }@+
      stack[height++] = node;
      node = node->bst_link[0];
      goto start;
    }@+
  
  if (height > 0) @
    {@-
      node = stack[--height];
      action (node->bst_data, param);
      node = node->bst_link[1];
      goto start;
    }@+
}
@

The first remaining |goto| statement can be eliminated without any other
change, because it is redundant; the second, by enclosing the whole
function body in an ``infinite loop'':

@cat bst Traversal, iterative
@c tested 2001/6/27
@<Iterative traversal of BST, take 5@> =
static void @
traverse_iterative (struct bst_node *node, bst_item_func *action, void *param) @
{
  struct bst_node *stack[BST_MAX_HEIGHT];
  size_t height = 0;

  for (;;) @
    {@-
      while (node != NULL) @
        {@-
          if (height >= BST_MAX_HEIGHT) @
            {@-
              fprintf (stderr, "tree too deep\n");
              exit (EXIT_FAILURE);
            }@+
          stack[height++] = node;
          node = node->bst_link[0];
        }@+

      if (height == 0)
        break;

      node = stack[--height];
      action (node->bst_data, param);
      node = node->bst_link[1];
    }@+
}
@

This initial iterative version takes care of the efficiency problem.

@exercise
Function |traverse_iterative()| relies on |stack[]|, a stack of nodes
yet to be visited, which as allocated can hold up to |BST_MAX_HEIGHT|
nodes.  Consider the following questions concerning |stack[]|:

@enumerate a
@item 
What is the maximum height this stack will attain in traversing a binary
search tree containing |n| nodes, if the binary tree has minimum
possible height?

@item
What is the maximum height this stack can attain in traversing any
binary tree of |n| nodes?  The minimum height?

@item
Under what circumstances is it acceptable to use a fixed-size stack as
in the example code?

@item
Rewrite |traverse_iterative()| to dynamically expand |stack[]| in case
of overflow.

@item
Does |traverse_recursive()| also have potential for running out of
``stack'' or ``memory''?  If so, more or less than
|traverse_iterative()| as modified by the previous part?
@end enumerate

@answer a
First of all, a minimal-height binary tree of |n| nodes has a
@gloss{height} of about
@tex
$\log_2n$,
@end tex
@ifnottex
log2(n),
@end ifnottex
that is, starting from the root and moving only downward, you can visit
at most |n| nodes (including the root) without running out of nodes.
Examination of the code should reveal to you that only moving down to
the left pushes nodes on the stack and only moving upward pops nodes
off.  What's more, the first thing the code does is move as far down to
the left as it can.  So, the maximum height of the stack in a
minimum-height binary tree of |n| nodes is the binary tree's height, or,
again, about
@tex
$\log_2n$.
@end tex
@ifnottex
log2(n).
@end ifnottex

@answer b
If a binary tree has only left children, as does the BST on the left
below, the stack will grow as tall as the tree, to a height of |n|.
Conversely, if a binary tree has only right children, as does the BST on
the right below, no nodes will be pushed onto the stack at all.

@center @image{patholog1}

@answer c
It's only acceptable if it's known that the stack will not exceed the
fixed maximum height (or if the program aborting with an error is itself
acceptable).  Otherwise, you should use a recursive method (but see part
(e) below), or a dynamically extended stack, or a balanced binary tree
library.

@answer d
Keep in mind this is not the only way or necessarily the best way to
handle stack overflow.  Our final code for tree traversal will rebalance
the tree when it grows too tall.

@cat bst Traversal, iterative; with dynamic stack
@c tested 2001/6/27
@<Iterative traversal of BST, with dynamically allocated stack@> =
static void @
traverse_iterative (struct bst_node *node, bst_item_func *action, void *param) @
{
  struct bst_node **stack = NULL;
  size_t height = 0;
  size_t max_height = 0;

  for (;;) @
    {@-
      while (node != NULL) @
        {@-
          if (height >= max_height) @
            {@-
              max_height = max_height * 2 + 8;
              stack = realloc (stack, sizeof *stack * max_height);
              if (stack == NULL) @
                {@-
                  fprintf (stderr, "out of memory\n");
                  exit (EXIT_FAILURE);
                }@+
            }@+

          stack[height++] = node;
          node = node->bst_link[0];
        }@+

      if (height == 0)
        break;

      node = stack[--height];
      action (node->bst_data, param);
      node = node->bst_link[1];
    }@+

  free (stack);
}
@

@answer e
Yes, |traverse_recursive()| can run out of memory, because its arguments
must be stored somewhere by the compiler.  Given typical compilers, it
will consume more memory per call than |traverse_iterative()| will per
item on the stack, because each call includes two arguments not pushed
on |traverse_iterative()|'s stack, plus any needed compiler-specific
bookkeeping information.
@end exercise

@menu
* Improving Convenience::       
@end menu

@node Improving Convenience,  , Iterative Traversal of a BST, Iterative Traversal of a BST
@subsubsection Improving Convenience

Now we can work on improving the convenience of our traversal function.
But, first, perhaps it's worthwhile to demonstrate how inconvenient it
really can be to use |walk()|, regardless of how it's implemented
internally.

Suppose that we have a BST of character strings and, for whatever
reason, want to know the total length of all the strings in it.  We
could do it like this using |walk()|:

@c tested 2001/6/27
@<Summing string lengths with |walk()|@> = 
static void @
process_node (void *data, void *param) @
{
  const char *string = data;
  size_t *total = param;

  *total += strlen (string);
}

size_t @
total_length (struct bst_table *tree) @
{
  size_t total = 0;
  walk (tree, process_node, &total);
  return total;
}
@

@noindent 
With the functions |first_item()| and |next_item()| that we'll write in
this section, we can rewrite these functions as the single function
below:

@c tested 2001/6/27
@<Summing string lengths with |next_item()|@> =
size_t @
total_length (struct bst_table *tree) @
{
  struct traverser t;
  const char *string;
  size_t total = 0;

  for (string = first_item (tree, &t); string != NULL; string = next_item (&t))
    total += strlen (string);
  return total;
}
@

You're free to make your own assessment, of course, but many programmers
prefer the latter because of its greater brevity and fewer ``unsafe''
conversions to and from |void| pointers.

Now to actually write the code.  Our task is to modify
|traverse_iterative()| so that, instead of calling |action|, it returns
|node->bst_data|.  But first, some infrastructure.  We define a structure to
contain the state of the traversal, equivalent to the relevant argument
and local variables in |traverse_iterative()|.  To emphasize that this
is not our final version of this structure or the related code, we will call it
|struct traverser|, without any name prefix:

@cat bst Traversal, iterative; convenient
@c tested 2001/6/27
@<Iterative traversal of BST, take 6@> =
struct traverser @
  {@-
    struct bst_table *table;                  /* Tree being traversed. */
    struct bst_node *node;                    /* Current node in tree. */
    struct bst_node *stack[BST_MAX_HEIGHT];   /* Parent nodes to revisit. */
    size_t height;                            /* Number of nodes in |stack|. */
  };@+

@

Function |first_item()| just initializes a |struct traverser| and
returns the first item in the tree, deferring most of its work to
|next_item()|:

@<Iterative traversal of BST, take 6@> +=
/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the smallest value, @
   or |NULL| if |tree| is empty.
   In the former case, |next_item()| may be called with |trav|
   to retrieve additional data items. */
void *@
first_item (struct bst_table *tree, struct traverser *trav) @
{
  assert (tree != NULL && trav != NULL);
  trav->table = tree;
  trav->node = tree->bst_root;
  trav->height = 0;
  return next_item (trav);
}

@

Function |next_item()| is, for the most part, a simple modification of
|traverse_iterative()|:

@<Iterative traversal of BST, take 6@> +=
/* Returns the next data item in inorder @
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. 
   In the former case |next_item()| may be called again @
   to retrieve the next item. */
void *@
next_item (struct traverser *trav) @
{
  struct bst_node *node;

  assert (trav != NULL);
  node = trav->node;
  while (node != NULL) @
    {@-
      if (trav->height >= BST_MAX_HEIGHT) @
        {@-
          fprintf (stderr, "tree too deep\n");
          exit (EXIT_FAILURE);
        }@+

      trav->stack[trav->height++] = node;
      node = node->bst_link[0];
    }@+

  if (trav->height == 0)
    return NULL;

  node = trav->stack[--trav->height];
  trav->node = node->bst_link[1];
  return node->bst_data;
}

@

@references
@bibref{Knuth 1997}, algorithm 2.3.1T;
@bibref{Knuth 1992}, p. 50--54, section ``Recursion Elimination'' within
article ``Structured Programming with @b{go to} statements''.

@exercise
Make |next_item()| reliable by providing alternate code to execute on
stack overflow.  This code will work by calling |bst_balance()| to
``balance'' the tree, reducing its height such that it can be
traversed with the small stack that we use.  We will develop
|bst_balance()| later.  For now, consider it a ``black box'' that
simply needs to be invoked with the tree to balance as an argument.
Don't forget to adjust the traverser structure so that later calls
will work properly, too.

@answer
After calling |bst_balance()|, the structure of the binary tree may have
changed completely, so we need to ``find our place'' again by setting up
the traverser structure as if the traversal had been done on the
rebalanced tree all along.  Specifically, members |node|,
|stack[]|, and |height| of |struct traverser| need to be
updated.

It is easy to set up |struct traverser| in this way, given the
previous node in inorder traversal, which we'll call |prev|.  Simply
search the tree from the new root to find this node.  Along the way,
because the stack is used to record nodes whose left subtree we are
examining, push nodes onto the stack as we move left down the tree.
Member |node| receives |prev->bst_link[1]|, just as it would have if
no overflow had occurred.

A small problem with this approach is that it requires knowing the
previous node in inorder, which is neither explicitly noted in |struct
traverser| nor easy to find out.  But it @emph{is} easy to find out
the next node: it is the smallest-valued node in the binary tree rooted
at the node we were considering when the stack overflowed.  (If you need
convincing, refer to the code for |next_item()| above: the |while| loop
descends to the left, pushing nodes as it goes, until it hits a |NULL|
pointer, then the node pushed last is popped and returned.)  So we can
return this as the next node in inorder while setting up the traverser
to return the nodes after it.

Here's the code:

@cat bst Traversal, iterative; convenient, reliable
@c tested 2001/6/27
@<Handle stack overflow during BST traversal@> =
struct bst_node *prev, *iter;

prev = node;
while (prev->bst_link[0] != NULL)
  prev = prev->bst_link[0];

bst_balance (trav->table);

trav->height = 0;
for (iter = trav->table->bst_root; iter != prev; )
  if (trav->table->bst_compare (prev->bst_data, iter->bst_data, @
                                trav->table->bst_param) < 0) @
    {@-
      trav->stack[trav->height++] = iter;
      iter = iter->bst_link[0];
    }@+
  else @
    iter = iter->bst_link[1];

trav->node = iter->bst_link[1];
return prev->bst_data;
@

Without this code, it is not necessary to have member |table| in |struct
traverser|.
@end exercise

@exercise
Without modifying |next_item()| or |first_item()|, can a function
|prev_item()| be written that will move to and return the previous item
in the tree in inorder?

@answer
It is possible to write |prev_item()| given our current |next_item()|, but
the result is not very efficient, for two reasons, both related to the
way that |struct traverser| is used.  First, the structure doesn't
contain a pointer to the current item.  Second, its stack doesn't
contain pointers to trees that must be descended to the left to find a
predecessor node, only those that must be descended to the right to find
a successor node.

The next section will develop an alternate, more general method for
traversal that avoids these problems.
@end exercise

@node Better Iterative Traversal,  , Iterative Traversal of a BST, Traversing a BST
@subsection Better Iterative Traversal

We have developed an efficient, convenient function for traversing a
binary tree.  In the exercises, we made it reliable, and it is possible
to make it resilient as well.  But its algorithm makes it difficult to
add generality.  In order to do that in a practical way, we will have to
use a new algorithm.

Let us start by considering how to understand how to find the successor
or predecessor of any node in general, as opposed to just blindly
transforming code as we did in the previous section.  Back when we wrote
|bst_delete()|, we already solved half of the problem, by figuring out
how to find the successor of a node that has a right child: take the
least-valued node in the right subtree of the node (@pxref{successor, ,
Deletion Case 3}).

The other half is the successor of a node that doesn't have a right
child.  Take a look at the code for one of the previous traversal
functions---recursive or iterative, whichever you better
understand---and mentally work out the relationship between the current
node and its successor for a node without a right child.  What happens
is that we move up the tree, from a node to its parent, one node at a
time, until it turns out that we moved up to the right (as opposed to up
to the left) and that is the successor node.  Think of it this way: if
we move up to the left, then the node we started at has a lesser value
than where we ended up, so we've already visited it, but if we move up
to the right, then we're moving to a node with a greater value, so we've
found the successor.

Using these instructions, we can find the predecessor of a node, too,
just by exchanging ``left'' and ``right''.  This suggests that all we
have to do in order to generalize our traversal function is to keep
track of all the nodes above the current node, not just the ones that
are up and to the left.  This in turn suggests our final implementation
of |struct bst_traverser|, with appropriate comments:

@<BST traverser structure@> =
/* BST traverser structure. */
struct bst_traverser @
  {@-
    struct bst_table *bst_table;        /* Tree being traversed. */
    struct bst_node *bst_node;          /* Current node in tree. */
    struct bst_node *bst_stack[BST_MAX_HEIGHT]; @
                                        /* All the nodes above |bst_node|. */
    size_t bst_height;                  /* Number of nodes in |bst_parent|. */
    unsigned long bst_generation;       /* Generation number. */
  };@+

@

Because user code is expected to declare actual instances of |struct
bst_traverser|, |struct bst_traverser| must be defined in @(bst.h@> and
therefore all of its member names are prefixed by |bst_| for safety.

The only surprise in |struct bst_traverser| is member |bst_generation|,
the traverser's generation number.  This member is set equal to its
namesake in |struct bst_table| when a traverser is initialized.  After
that, the two values are compared whenever the stack of parent pointers
must be accessed.  Any change in the tree that could disturb the action
of a traverser will cause their generation numbers to differ, which in
turn triggers an update to the stack.  This is what allows this final
implementation to be resilient.

We need a utility function to actually update the stack of parent
pointers when differing generation numbers are detected.  This is easy
to write:

@cat bst Refreshing of a traverser (general)
@<BST traverser refresher@> =
/* Refreshes the stack of parent pointers in |trav|
   and updates its generation number. */
static void @
trav_refresh (struct bst_traverser *trav) @
{
  assert (trav != NULL);
  
  trav->bst_generation = trav->bst_table->bst_generation;

  if (trav->bst_node != NULL) @
    {@-
      bst_comparison_func *cmp = trav->bst_table->bst_compare;
      void *param = trav->bst_table->bst_param;
      struct bst_node *node = trav->bst_node;
      struct bst_node *i;

      trav->bst_height = 0;
      for (i = trav->bst_table->bst_root; i != node; ) @
	{@-
          assert (trav->bst_height < BST_MAX_HEIGHT);
	  assert (i != NULL);

	  trav->bst_stack[trav->bst_height++] = i;
	  i = i->bst_link[cmp (node->bst_data, i->bst_data, param) > 0];
	}@+
    }@+
}

@

The following sections will implement all of the traverser functions
|bst_t_*()|.  @xref{Traversers}, for descriptions of the purpose of each
of these functions.

The traversal functions are collected together into @<BST traversal
functions@>:

@<BST traversal functions@> =
@<BST traverser refresher@>
@<BST traverser null initializer@>
@<BST traverser least-item initializer@>
@<BST traverser greatest-item initializer@>
@<BST traverser search initializer@>
@<BST traverser insertion initializer@>
@<BST traverser copy initializer@>
@<BST traverser advance function@>
@<BST traverser back up function@>
@<BST traverser current item function@>
@<BST traverser replacement function@>
@

@exercise probegeneration
The |bst_probe()| function doesn't change the tree's generation number.
Why not?

@answer
The |bst_probe()| function can't disturb any traversals.  A change in
the tree is only problematic for a traverser if it deletes the currently
selected node (which is explicitly undefined: @pxref{Traversers}) or if
it shuffles around any of the nodes that are on the traverser's stack.
An insertion into a tree only creates new leaves, so it can't cause
either of those problems, and there's no need to increment the
generation number.

The same logic applies to |bst_t_insert()|, presented later.

On the other hand, an insertion into the AVL and red-black trees
discussed in the next two chapters can cause restructuring of the tree
and thus potentially disturb ongoing traversals.  For this reason, the
insertion functions for AVL and red-black trees @emph{will} increment
the tree's generation number.
@end exercise

@exercise*
The main loop in |trav_refresh()| contains the assertion

@<Anonymous@> =
      assert (trav->bst_height < BST_MAX_HEIGHT);
@

@noindent
Prove that this assertion is always true.

@answer
First, |trav_refresh()| is only called from |bst_t_next()| and
|bst_t_prev()|, and these functions are mirrors of each other, so we
need only show it for one of them.

Second, all of the traverser functions check the stack height, so these
will not cause an item to be initialized at too high a height, nor will
|bst_t_next()| or |bst_t_prev()| increase the stack height above its
limit.

Since the traverser functions won't force a too-tall stack directly,
this leaves the other functions.  Only functions that modify the tree
could cause problems, by pushing an item farther down in the tree.

There are only four functions that modify a tree.  The insertion
functions |bst_probe()| and |bst_t_insert()| can't cause problems,
because they add leaves but never move around nodes.  The deletion
function |bst_delete()| does move around nodes in case 3, but it always
moves them higher in the tree, never lower.  Finally, |bst_balance()|
always ensures that all nodes in the resultant tree are within the
tree's height limit.
@end exercise

@exercise
In |trav_refresh()|, it is tempting to avoid calls to the user-supplied
comparison function by comparing the nodes on the stack to the current
state of the tree; e.g., move up the stack, starting from the bottom,
and for each node verify that it is a child of the previous one on the
stack, falling back to the general algorithm at the first mismatch.  Why
won't this work?

@answer
This won't work because the stack may contain pointers to nodes that
have been deleted and whose memory have been freed.  In ANSI C89 and
C99, any use of a pointer to an object after the end of its lifetime
results in undefined behavior, even seemingly innocuous uses such as
pointer comparisons.  What's worse, the memory for the node may already
have been recycled for use for another, different node elsewhere in the
tree.

This approach does work if there are never any deletions in the tree,
or if we use some kind of generation number for each node that we
store along with each stack entry.  The latter would be overkill
unless comparisons are very expensive and the traversals in changing
trees are common.  Another possibility would be to somehow only select
this behavior if there have been no deletions in the binary tree since
the traverser was last used.  This could be done, for instance, with a
second generation number in the binary tree incremented only on
deletions, with a corresponding number kept in the traverser.

The following reimplements |trav_refresh()| to include this
optimization.  As noted, it will not work if there are any deletions in
the tree.  It does work for traversers that must be refreshed due to,
e.g., rebalancing.

@cat bst Refreshing of a traverser, optimized
@c tested 2001/11/10
@<BST traverser refresher, with caching@> =
/* Refreshes the stack of parent pointers in |trav|
   and updates its generation number.
   Will *not* work if any deletions have occurred in the tree. */
static void @
trav_refresh (struct bst_traverser *trav) @
{
  assert (trav != NULL);

  trav->bst_generation = trav->bst_table->bst_generation;

  if (trav->bst_node != NULL) @
    {@-
      bst_comparison_func *cmp = trav->bst_table->bst_compare;
      void *param = trav->bst_table->bst_param;
      struct bst_node *node = trav->bst_node;
      struct bst_node *i = trav->bst_table->bst_root;
      size_t height = 0;
      
      if (trav->bst_height > 0 && i == trav->bst_stack[0])
	for (; height < trav->bst_height; height++) @
	  {@-
	    struct bst_node *next = trav->bst_stack[height + 1];
	    if (i->bst_link[0] != next && i->bst_link[1] != next)
	      break;
	    i = next;
	  }@+

      while (i != node) @
	{@-
	  assert (height < BST_MAX_HEIGHT);
	  assert (i != NULL);

	  trav->bst_stack[height++] = i;
	  i = i->bst_link[cmp (node->bst_data, i->bst_data, param) > 0];
	}@+

      trav->bst_height = height;
    }@+
}
@
@end exercise

@menu
* BST Traverser Null Initialization::  
* BST Traverser First Initialization::  
* BST Traverser Last Initialization::  
* BST Traverser Find Initialization::  
* BST Traverser Insert Initialization::  
* BST Traverser Copying::       
* BST Traverser Advancing::     
* BST Traverser Retreating::    
* BST Traversal Current Item::  
* BST Traversal Replacing the Current Item::  
@end menu

@node BST Traverser Null Initialization, BST Traverser First Initialization, Better Iterative Traversal, Better Iterative Traversal
@subsubsection Starting at the Null Node

The |trav_t_init()| function just initializes a traverser to the null
item, indicated by a null pointer for |bst_node|.

@cat bst Initialization of traverser to null item
@<BST traverser null initializer@> =
@iftangle
/* Initializes |trav| for use with |tree| @
   and selects the null node. */
@end iftangle
void @
bst_t_init (struct bst_traverser *trav, struct bst_table *tree) @
{
  trav->bst_table = tree;
  trav->bst_node = NULL;
  trav->bst_height = 0;
  trav->bst_generation = tree->bst_generation;
}

@

@node BST Traverser First Initialization, BST Traverser Last Initialization, BST Traverser Null Initialization, Better Iterative Traversal
@subsubsection Starting at the First Node

To initialize a traverser to start at the least valued node, we simply
descend from the root as far down and left as possible, recording the
parent pointers on the stack as we go.  If the stack overflows, then we
balance the tree and start over.

@cat bst Initialization of traverser to least item
@<BST traverser least-item initializer@> =
@iftangle
/* Initializes |trav| for |tree| @
   and selects and returns a pointer to its least-valued item.
   Returns |NULL| if |tree| contains no nodes. */
@end iftangle
void *@
bst_t_first (struct bst_traverser *trav, struct bst_table *tree) @
{
  struct bst_node *x;
  
  assert (tree != NULL && trav != NULL);

  trav->bst_table = tree;
  trav->bst_height = 0;
  trav->bst_generation = tree->bst_generation;

  x = tree->bst_root;
  if (x != NULL)
    while (x->bst_link[0] != NULL) @
      {@-
	if (trav->bst_height >= BST_MAX_HEIGHT) @
	  {@-
	    bst_balance (tree);
	    return bst_t_first (trav, tree);
	  }@+
	  
	trav->bst_stack[trav->bst_height++] = x;
	x = x->bst_link[0];
      }@+
  trav->bst_node = x;

  return x != NULL ? x->bst_data : NULL;
}

@

@exercise*
Show that |bst_t_first()| will never make more than one recursive call
to itself at a time.

@answer
It only calls itself if it runs out of stack space.  Its call to
|bst_balance()| right before the recursive call ensures that the tree is
short enough to fit within the stack, so the recursive call cannot
overflow.
@end exercise

@node BST Traverser Last Initialization, BST Traverser Find Initialization, BST Traverser First Initialization, Better Iterative Traversal
@subsubsection Starting at the Last Node

The code to start from the greatest node in the tree is analogous to
that for starting from the least node.  The only difference is that we
descend to the right instead:

@cat bst Initialization of traverser to greatest item
@<BST traverser greatest-item initializer@> =
@iftangle
/* Initializes |trav| for |tree| @
   and selects and returns a pointer to its greatest-valued item.
   Returns |NULL| if |tree| contains no nodes. */
@end iftangle
void *@
bst_t_last (struct bst_traverser *trav, struct bst_table *tree) @
{
  struct bst_node *x;
  
  assert (tree != NULL && trav != NULL);

  trav->bst_table = tree;
  trav->bst_height = 0;
  trav->bst_generation = tree->bst_generation;

  x = tree->bst_root;
  if (x != NULL)
    while (x->bst_link[1] != NULL) @
      {@-
	if (trav->bst_height >= BST_MAX_HEIGHT) @
	  {@-
	    bst_balance (tree);
	    return bst_t_last (trav, tree);
	  }@+
	  
	trav->bst_stack[trav->bst_height++] = x;
	x = x->bst_link[1];
      }@+
  trav->bst_node = x;

  return x != NULL ? x->bst_data : NULL;
}

@

@node BST Traverser Find Initialization, BST Traverser Insert Initialization, BST Traverser Last Initialization, Better Iterative Traversal
@subsubsection Starting at a Found Node

Sometimes it is convenient to begin a traversal at a particular item in
a tree.  This function works in the same was as |bst_find()|, but
records parent pointers in the traverser structure as it descends the
tree.

@cat bst Initialization of traverser to found item
@<BST traverser search initializer@> =
@iftangle
/* Searches for |item| in |tree|.
   If found, initializes |trav| to the item found and returns the item @
   as well.
   If there is no matching item, initializes |trav| to the null item @
   and returns |NULL|. */
@end iftangle
void *@
bst_t_find (struct bst_traverser *trav, struct bst_table *tree, void *item) @
{
  struct bst_node *p, *q;

  assert (trav != NULL && tree != NULL && item != NULL);
  trav->bst_table = tree;
  trav->bst_height = 0;
  trav->bst_generation = tree->bst_generation;
  for (p = tree->bst_root; p != NULL; p = q) @
    {@-
      int cmp = tree->bst_compare (item, p->bst_data, tree->bst_param);

      if (cmp < 0) @
	q = p->bst_link[0];
      else if (cmp > 0) @
	q = p->bst_link[1];
      else /* |cmp == 0| */ @
	{@-
	  trav->bst_node = p;
	  return p->bst_data;
	}@+

      if (trav->bst_height >= BST_MAX_HEIGHT) @
	{@-
	  bst_balance (trav->bst_table);
	  return bst_t_find (trav, tree, item);
	}@+
      trav->bst_stack[trav->bst_height++] = p;
    }@+

  trav->bst_height = 0;
  trav->bst_node = NULL;
  return NULL;
}

@

@node BST Traverser Insert Initialization, BST Traverser Copying, BST Traverser Find Initialization, Better Iterative Traversal
@subsubsection Starting at an Inserted Node

Another operation that can be useful is to insert a new node and
construct a traverser to the inserted node in a single operation.  The
following code does this:

@cat bst Initialization of traverser to inserted item
@<BST traverser insertion initializer@> =
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
bst_t_insert (struct bst_traverser *trav, struct bst_table *tree, void *item) @
{
  struct bst_node **q;

  assert (tree != NULL && item != NULL);

  trav->bst_table = tree;
  trav->bst_height = 0;

  q = &tree->bst_root;
  while (*q != NULL) @
    {@-
      int cmp = tree->bst_compare (item, (*q)->bst_data, tree->bst_param);
      if (cmp == 0) @
	{@-
	  trav->bst_node = *q;
          trav->bst_generation = tree->bst_generation;
	  return (*q)->bst_data;
	}@+

      if (trav->bst_height >= BST_MAX_HEIGHT) @
	{@-
	  bst_balance (tree);
	  return bst_t_insert (trav, tree, item);
	}@+
      trav->bst_stack[trav->bst_height++] = *q;

      q = &(*q)->bst_link[cmp > 0];
    }@+

  trav->bst_node = *q = tree->bst_alloc->libavl_malloc (tree->bst_alloc, @
                                                        sizeof **q);
  if (*q == NULL) @
    {@-
      trav->bst_node = NULL;
      trav->bst_generation = tree->bst_generation;
      return NULL;
    }@+

  (*q)->bst_link[0] = (*q)->bst_link[1] = NULL;
  (*q)->bst_data = item;
  tree->bst_count++;
  trav->bst_generation = tree->bst_generation;
  return (*q)->bst_data;
}
  
@

@node BST Traverser Copying, BST Traverser Advancing, BST Traverser Insert Initialization, Better Iterative Traversal
@subsubsection Initialization by Copying

This function copies one traverser to another.  It only copies the stack
of parent pointers if they are up-to-date:

@cat bst Initialization of traverser as copy
@<BST traverser copy initializer@> =
@iftangle
/* Initializes |trav| to have the same current node as |src|. */
@end iftangle
void *@
bst_t_copy (struct bst_traverser *trav, const struct bst_traverser *src) @
{
  assert (trav != NULL && src != NULL);

  if (trav != src) @
    {@-
      trav->bst_table = src->bst_table;
      trav->bst_node = src->bst_node;
      trav->bst_generation = src->bst_generation;
      if (trav->bst_generation == trav->bst_table->bst_generation) @
        {@-
          trav->bst_height = src->bst_height;
          memcpy (trav->bst_stack, (const void *) src->bst_stack,
                  sizeof *trav->bst_stack * trav->bst_height);
        }@+
    }@+

  return trav->bst_node != NULL ? trav->bst_node->bst_data : NULL;
}

@

@exercise
Without the check that |trav != src| before copying |src| into |trav|,
what might happen?

@answer
The assignment statements are harmless, but |memcpy()| of overlapping
regions produces undefined behavior.
@end exercise

@node BST Traverser Advancing, BST Traverser Retreating, BST Traverser Copying, Better Iterative Traversal
@subsubsection Advancing to the Next Node

The algorithm of |bst_t_next()|, the function for finding a successor,
divides neatly into three cases.  Two of these are the ones that we
discussed earlier in the introduction to this kind of traverser
(@pxref{Better Iterative Traversal}).  The third case occurs when the
last node returned was |NULL|, in which case we return the least node in
the table, in accordance with the semantics for @libavl{} tables.  The
function outline is this:

@cat bst Traversal (iterative; convenient, reliable)
@cat bst Advancing a traverser
@<BST traverser advance function@> =
@iftangle
/* Returns the next data item in inorder @
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
@end iftangle
void *@
bst_t_next (struct bst_traverser *trav) @
{
  struct bst_node *x;

  assert (trav != NULL);
  
  if (trav->bst_generation != trav->bst_table->bst_generation)
    trav_refresh (trav);
  
  x = trav->bst_node;
  if (x == NULL) @
    {@-
      return bst_t_first (trav, trav->bst_table);
    }@+ @
  else if (x->bst_link[1] != NULL) @
    {@-
      @<Handle case where |x| has a right child@>
    }@+ @
  else @
    {@-
      @<Handle case where |x| has no right child@>
    }@+
  trav->bst_node = x;

  return x->bst_data;
}

@

The case where the current node has a right child is accomplished by
stepping to the right, then to the left until we can't go any farther,
as discussed in detail earlier.  The only difference is that we must
check for stack overflow.  When stack overflow does occur, we recover by
calling |trav_balance()|, then restarting |bst_t_next()| using a
tail-recursive call.  The tail recursion will never happen more than
once, because |trav_balance()| ensures that the tree's height is small
enough that the stack cannot overflow again:

@<Handle case where |x| has a right child@> =
if (trav->bst_height >= BST_MAX_HEIGHT) @
  {@-
    bst_balance (trav->bst_table);
    return bst_t_next (trav);
  }@+

trav->bst_stack[trav->bst_height++] = x;
x = x->bst_link[1];

while (x->bst_link[0] != NULL) @
  {@-
    if (trav->bst_height >= BST_MAX_HEIGHT) @
      {@-
        bst_balance (trav->bst_table);
        return bst_t_next (trav);
      }@+

    trav->bst_stack[trav->bst_height++] = x;
    x = x->bst_link[0];
  }@+
@

In the case where the current node has no right child, we move upward in
the tree based on the stack of parent pointers that we saved, as
described before.  When the stack underflows, we know that we've run out
of nodes in the tree:

@<Handle case where |x| has no right child@> =
struct bst_node *y;

do @
  {@-
    if (trav->bst_height == 0) @
      {@-
        trav->bst_node = NULL;
        return NULL;
      }@+

    y = x;
    x = trav->bst_stack[--trav->bst_height];
  }@+ @
while (y == x->bst_link[1]);
@

@node BST Traverser Retreating, BST Traversal Current Item, BST Traverser Advancing, Better Iterative Traversal
@subsubsection Backing Up to the Previous Node

Moving to the previous node is analogous to moving to the next node.
The only difference, in fact, is that directions are reversed from left
to right.

@cat bst Backing up a traverser
@<BST traverser back up function@> =
@iftangle
/* Returns the previous data item in inorder @
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
@end iftangle
void *@
bst_t_prev (struct bst_traverser *trav) @
{
  struct bst_node *x;

  assert (trav != NULL);

  if (trav->bst_generation != trav->bst_table->bst_generation)
    trav_refresh (trav);
  
  x = trav->bst_node;
  if (x == NULL) @
    {@-
      return bst_t_last (trav, trav->bst_table);
    }@+ @
  else if (x->bst_link[0] != NULL) @
    {@-
      if (trav->bst_height >= BST_MAX_HEIGHT) @
	{@-
	  bst_balance (trav->bst_table);
	  return bst_t_prev (trav);
	}@+

      trav->bst_stack[trav->bst_height++] = x;
      x = x->bst_link[0];

      while (x->bst_link[1] != NULL) @
	{@-
	  if (trav->bst_height >= BST_MAX_HEIGHT) @
	    {@-
	      bst_balance (trav->bst_table);
	      return bst_t_prev (trav);
	    }@+
	  
	  trav->bst_stack[trav->bst_height++] = x;
	  x = x->bst_link[1];
	}@+
    }@+ @
  else @
    {@-
      struct bst_node *y;

      do @
	{@-
	  if (trav->bst_height == 0) @
	    {@-
	      trav->bst_node = NULL;
	      return NULL;
	    }@+
	
	  y = x;
	  x = trav->bst_stack[--trav->bst_height];
	}@+ @
      while (y == x->bst_link[0]);
    }@+
  trav->bst_node = x;

  return x->bst_data;
}

@

@node BST Traversal Current Item, BST Traversal Replacing the Current Item, BST Traverser Retreating, Better Iterative Traversal
@subsubsection Getting the Current Item

@cat bst Getting the current item in a traverser
@<BST traverser current item function@> =
@iftangle
/* Returns |trav|'s current item. */
@end iftangle
void *@
bst_t_cur (struct bst_traverser *trav) @
{
  assert (trav != NULL);

  return trav->bst_node != NULL ? trav->bst_node->bst_data : NULL;
}

@

@node BST Traversal Replacing the Current Item,  , BST Traversal Current Item, Better Iterative Traversal
@subsubsection Replacing the Current Item

@cat bst Replacing the current item in a traverser
@<BST traverser replacement function@> =
@iftangle
/* Replaces the current item in |trav| by |new| and returns the item replaced.
   |trav| must not have the null item selected.
   The new item must not upset the ordering of the tree. */
@end iftangle
void *@
bst_t_replace (struct bst_traverser *trav, void *new) @
{
  void *old;

  assert (trav != NULL && trav->bst_node != NULL && new != NULL);
  old = trav->bst_node->bst_data;
  trav->bst_node->bst_data = new;
  return old;
}

@

@node Copying a BST, Destroying a BST, Traversing a BST, Binary Search Trees
@section Copying

In this section, we're going to write function |bst_copy()| to make a
copy of a binary tree.  This is the most complicated function of all
those needed for BST functionality, so pay careful attention as we
proceed.

@menu
* Copying a BST Recursively::   
* Copying a BST Iteratively::   
* Handling Errors in Iterative BST Copying::  
@end menu

@node Copying a BST Recursively, Copying a BST Iteratively, Copying a BST, Copying a BST
@subsection Recursive Copying

The ``obvious'' way to copy a binary tree is recursive.  Here's a basic
recursive copy, hard-wired to allocate memory with |malloc()| for
simplicity:

@cat bst Copying, recursive
@c tested 2001/6/27
@<Recursive copy of BST, take 1@> =
/* Makes and returns a new copy of tree rooted at |x|. */
static struct bst_node *@
bst_copy_recursive_1 (struct bst_node *x) @
{
  struct bst_node *y;
  
  if (x == NULL)
    return NULL;

  y = malloc (sizeof *y);
  if (y == NULL)
    return NULL;

  y->bst_data = x->bst_data;
  y->bst_link[0] = bst_copy_recursive_1 (x->bst_link[0]);
  y->bst_link[1] = bst_copy_recursive_1 (x->bst_link[1]);
  return y;
}
@

But, again, it would be nice to rewrite this iteratively, both because
the iterative version is likely to be faster and for the sheer mental
exercise of it.  Recall, from our earlier discussion of inorder
traversal, that tail recursion (recursion where a function calls itself
as its last action) is easier to convert to iteration than other types.
Unfortunately, neither of the recursive calls above are tail-recursive.

Fortunately, we can rewrite it so that it is, if we change the way we
allocate data:

@c tested 2001/11/10
@<Recursive copy of BST, take 2@> =
/* Copies tree rooted at |x| to |y|, which latter is allocated but not @
   yet initialized. */
static void @
bst_copy_recursive_2 (struct bst_node *x, struct bst_node *y) @
{
  y->bst_data = x->bst_data;

  if (x->bst_link[0] != NULL) @
    {@-
      y->bst_link[0] = malloc (sizeof *y->bst_link[0]);
      bst_copy_recursive_2 (x->bst_link[0], y->bst_link[0]);
    }@+
  else @
    y->bst_link[0] = NULL;

  if (x->bst_link[1] != NULL) @
    {@-
      y->bst_link[1] = malloc (sizeof *y->bst_link[1]);
      bst_copy_recursive_2 (x->bst_link[1], y->bst_link[1]);
    }@+
  else @
    y->bst_link[1] = NULL;
}
@

@exercise
When |malloc()| returns a null pointer, |bst_copy_recursive_1()| fails
``silently'', that is, without notifying its caller about the error, and
the output is a partial copy of the original tree.  Without removing the
recursion, implement two different ways to propagate such errors upward
to the function's caller:

@enumerate a
@item 
Change the function's prototype to:

@<Anonymous@> =
    static int bst_robust_copy_recursive_1 (struct bst_node *, @
                                            struct bst_node **);
@

@item 
Without changing the function's prototype.  (Hint: use a |static|ally
declared |struct bst_node|).
@end enumerate

@noindent
In each case make sure that any allocated memory is safely freed if an
allocation error occurs.

@answer a
Notice the use of |&| instead of |&&| below.  This ensures that both
link fields get initialized, so that deallocation can be done in a
simple way.  If |&&| were used instead then we wouldn't have any way to
tell whether |(*y)->bst_link[1]| had been initialized.

@cat bst Copying, recursive; robust, version 1
@c tested 2001/6/27
@<Robust recursive copy of BST, take 1@> =
/* Stores in |*y| a new copy of tree rooted at |x|. 
   Returns nonzero if successful, or zero if memory was exhausted.*/
static int @
bst_robust_copy_recursive_1 (struct bst_node *x, struct bst_node **y) @
{
  if (x != NULL) @
    {@-
      *y = malloc (sizeof **y);
      if (*y == NULL)
        return 0;

      (*y)->bst_data = x->bst_data;
      if (!(bst_robust_copy_recursive_1 (x->bst_link[0], &(*y)->bst_link[0])
            & bst_robust_copy_recursive_1 (x->bst_link[1], @
					   &(*y)->bst_link[1]))) @
        {@-
          bst_deallocate_recursive (*y);
	  *y = NULL;
          return 0;
        }@+
    }@+
  else @
    *y = NULL;

  return 1;
}
@

Here's a needed auxiliary function:

@c tested 2001/6/27
@<Recursive deallocation function@> =
static void @
bst_deallocate_recursive (struct bst_node *node) @
{
  if (node == NULL)
    return;

  bst_deallocate_recursive (node->bst_link[0]);
  bst_deallocate_recursive (node->bst_link[1]);
  free (node);
}
@

@answer b
@cat bst Copying, recursive; robust, version 2
@c tested 2001/6/27
@<Robust recursive copy of BST, take 2@> =
static struct bst_node error_node;

/* Makes and returns a new copy of tree rooted at |x|.
   If an allocation error occurs, returns |&error_node|. */
static struct bst_node *@
bst_robust_copy_recursive_2 (struct bst_node *x) @
{
  struct bst_node *y;

  if (x == NULL)
    return NULL;

  y = malloc (sizeof *y);
  if (y == NULL)
    return &error_node;

  y->bst_data = x->bst_data;
  y->bst_link[0] = bst_robust_copy_recursive_2 (x->bst_link[0]);
  y->bst_link[1] = bst_robust_copy_recursive_2 (x->bst_link[1]);
  if (y->bst_link[0] == &error_node || y->bst_link[1] == &error_node) @
    {@-
      bst_deallocate_recursive (y);
      return &error_node;
    }@+

  return y;
}
@    
@end exercise

@exercise
|bst_copy_recursive_2()| is even worse than |bst_copy_recursive_1()|
at handling allocation failure.  It actually invokes undefined
behavior when an allocation fails.  Fix this, changing it to return an
|int|, with nonzero return values indicating success.  Be careful not
to leak memory.

@answer
Here's one way to do it, which is simple but perhaps not the fastest
possible.

@cat bst Copying, recursive; robust, version 3
@c tested 2001/6/27
@<Robust recursive copy of BST, take 3@> =
/* Copies tree rooted at |x| to |y|, which latter is allocated but not @
   yet initialized. 
   Returns one if successful, zero if memory was exhausted. 
   In the latter case |y| is not freed but any partially allocated
   subtrees are. */
static int @
bst_robust_copy_recursive_3 (struct bst_node *x, struct bst_node *y) @
{
  y->bst_data = x->bst_data;

  if (x->bst_link[0] != NULL) @
    {@-
      y->bst_link[0] = malloc (sizeof *y->bst_link[0]);
      if (y->bst_link[0] == NULL)
        return 0;
      if (!bst_robust_copy_recursive_3 (x->bst_link[0], y->bst_link[0])) @
        {@-
          free (y->bst_link[0]);
          return 0;
        }@+
    }@+
  else @
    y->bst_link[0] = NULL;
      
  if (x->bst_link[1] != NULL) @
    {@-
      y->bst_link[1] = malloc (sizeof *y->bst_link[1]);
      if (y->bst_link[1] == NULL)
        return 0;
      if (!bst_robust_copy_recursive_3 (x->bst_link[1], y->bst_link[1])) @
        {@-
          bst_deallocate_recursive (y->bst_link[0]);
          free (y->bst_link[1]);
          return 0;
        }@+
    }@+
  else @
    y->bst_link[1] = NULL;

  return 1;      
}
@
@end exercise

@node Copying a BST Iteratively, Handling Errors in Iterative BST Copying, Copying a BST Recursively, Copying a BST
@subsection Iterative Copying

Now we can factor out the recursion, starting with the tail recursion.
This process is very similar to what we did with the traversal code, so
the details are left for @value{copystepbrief}.  Let's look at the
results part by part:

@cat bst Copying, iterative
@c tested 2001/6/27
@<Iterative copy of BST@> =
/* Copies |org| to a newly created tree, which is returned. */
struct bst_table *@
bst_copy_iterative (const struct bst_table *org) @
{
  struct bst_node *stack[2 * (BST_MAX_HEIGHT + 1)]; @
                                     /* Stack. */
  int height = 0;                    /* Stack height. */
@

This time, our stack will have two pointers added to it at a time, one
from the original tree and one from the copy.  Thus, the stack needs to
be twice as big.  In addition, we'll see below that there'll be an extra
item on the stack representing the pointer to the tree's root, so our
stack needs room for an extra pair of items, which is the reason for the
``|+ 1|'' in |stack[]|'s size.

@<Iterative copy of BST@> +=
  struct bst_table *new;             /* New tree. */
  const struct bst_node *x;          /* Node currently being copied. */
  struct bst_node *y;                /* New node being copied from |x|. */

  new = bst_create (org->bst_compare, org->bst_param, org->bst_alloc);
  new->bst_count = org->bst_count;
  if (new->bst_count == 0)
    return new;

  x = (const struct bst_node *) &org->bst_root;
  y = (struct bst_node *) &new->bst_root;
@

This is the same kind of ``dirty trick'' already described in @value{rootcast}.

@<Iterative copy of BST@> +=
  for (;;) @
    {@-
      while (x->bst_link[0] != NULL) @
        {@-
          y->bst_link[0] @
            = org->bst_alloc->libavl_malloc (org->bst_alloc,
                                             sizeof *y->bst_link[0]);
          stack[height++] = (struct bst_node *) x;
          stack[height++] = y;
          x = x->bst_link[0];
          y = y->bst_link[0];
        }@+
      y->bst_link[0] = NULL;
@

This code moves |x| down and to the left in the tree until it runs out
of nodes, allocating space in the new tree for left children and pushing
nodes from the original tree and the copy onto the stack as it goes.
The cast on |x| suppresses a warning or error due to |x|, a pointer to a
|const| structure, being stored into a non-constant pointer in
|stack[]|.  We won't ever try to store into the pointer that we store in
there, so this is legitimate.

We've switched from using |malloc()| to using the allocation function
provided by the user.  This is easy now because we have the tree
structure to work with.  To do this earlier, we would have had to
somehow pass the tree structure to each recursive call of the copy
function, wasting time and space.

@<Iterative copy of BST@> += 
      for (;;) @
        {@-
          y->bst_data = x->bst_data;

          if (x->bst_link[1] != NULL) @
            {@-
              y->bst_link[1] = @
                org->bst_alloc->libavl_malloc (org->bst_alloc,
                                              sizeof *y->bst_link[1]);
              x = x->bst_link[1];
              y = y->bst_link[1];
              break;
            }@+
          else @
            y->bst_link[1] = NULL;

          if (height <= 2)
            return new;

          y = stack[--height];
          x = stack[--height];
        }@+
    }@+
}
@

We do not pop the bottommost pair of items off the stack because these
items contain the fake |struct bst_node| pointer that is actually the
address of |bst_root|.  When we get down to these items, we're done
copying and can return the new tree.

@references
@bibref{Knuth 1997}, algorithm 2.3.1C;
@bibref{ISO 1990}, section 6.5.2.1.

@exercise copystep
Suggest a step between |bst_copy_recursive_2()| and
|bst_copy_iterative()|.

@answer
Here is one possibility.

@c tested 2001/6/27
@<Intermediate step between |bst_copy_recursive_2()| and |bst_copy_iterative()|@> =
/* Copies |org| to a newly created tree, which is returned. */
struct bst_table *@
bst_copy_iterative (const struct bst_table *org) @
{
  struct bst_node *stack[2 * (BST_MAX_HEIGHT + 1)];
  int height = 0;

  struct bst_table *new;
  const struct bst_node *x;
  struct bst_node *y;

  new = bst_create (org->bst_compare, org->bst_param, org->bst_alloc);
  new->bst_count = org->bst_count;
  if (new->bst_count == 0)
    return new;

  x = (const struct bst_node *) &org->bst_root;
  y = (struct bst_node *) &new->bst_root;
  for (;;) @
    {@-
      while (x->bst_link[0] != NULL) @
        {@-
          y->bst_link[0] = @
            org->bst_alloc->libavl_malloc (org->bst_alloc,
                                           sizeof *y->bst_link[0]);
          stack[height++] = (struct bst_node *) x;
          stack[height++] = y;
          x = x->bst_link[0];
          y = y->bst_link[0];
        }@+
      y->bst_link[0] = NULL;

      for (;;) @
        {@-
          y->bst_data = x->bst_data;

          if (x->bst_link[1] != NULL) @
            {@-
              y->bst_link[1] = @
                org->bst_alloc->libavl_malloc (org->bst_alloc,
                                               sizeof *y->bst_link[1]);
              x = x->bst_link[1];
              y = y->bst_link[1];
              break;
            }@+
          else @
            y->bst_link[1] = NULL;

          if (height <= 2)
            return new;

          y = stack[--height];
          x = stack[--height];
        }@+
    }@+
}
@
@end exercise

@node Handling Errors in Iterative BST Copying,  , Copying a BST Iteratively, Copying a BST
@subsection Error Handling

So far, outside the exercises, we've ignored the question of handling
memory allocation errors during copying.  In our other routines, we've
been careful to implement to handle allocation failures by cleaning up
and returning an error indication to the caller.  Now we will apply this
same policy to tree copying, as @libavl{} semantics require
(@pxref{Creation and Destruction}): a memory allocation error causes the
partially copied tree to be destroyed and returns a null pointer to the
caller.

This is a little harder to do than recovering after a single operation,
because there are potentially many nodes that have to be freed, and each
node might include additional user data that also has to be freed.  The
new BST might have as-yet-uninitialized pointer fields as well, and we
must be careful to avoid reading from these fields as we destroy the
tree.

We could use a number of strategies to destroy the partially copied tree
while avoiding uninitialized pointers.  The strategy that we will
actually use is to initialize these pointers to |NULL|, then call the
general tree destruction routine |bst_destroy()|.  We haven't yet
written |bst_destroy()|, so for now we'll treat it as a @gloss{black
box} that does what we want, even if we don't understand how.

Next question: @emph{which} pointers in the tree are not initialized?
The answer is simple: during the copy, we will not revisit nodes not
currently on the stack, so only pointers in the current node (|y|) and
on the stack can be uninitialized.  For its part, depending on what
we're doing to it, |y| might not have any of its fields initialized.  As
for the stack, nodes are pushed onto it because we have to come back
later and build their right subtrees, so we must set their right child
pointers to |NULL|.

We will need this error recovery code in a number of places, so it is
worth making it into a small helper function:

@<BST copy error helper function@> =
@iftangle
/* Destroys |new| with |bst_destroy (new, destroy)|,
   first setting right links of nodes in |stack| within |new|
   to null pointers to avoid touching uninitialized data. */
@end iftangle
static void @
copy_error_recovery (struct bst_node **stack, int height, 
                     struct bst_table *new, bst_item_func *destroy) @
{
  assert (stack != NULL && height >= 0 && new != NULL);

  for (; height > 2; height -= 2)
    stack[height - 1]->bst_link[1] = NULL;
  bst_destroy (new, destroy);
}
@

Another problem that can arise in copying a binary tree is stack
overflow.  We will handle stack overflow by destroying the partial copy,
balancing the original tree, and then restarting the copy.  The balanced
tree is guaranteed to have small enough height that it will not overflow
the stack.

The code below for our final version of |bst_copy()| takes three new
parameters: two function pointers and a memory allocator.  The meaning
of these parameters was explained earlier (@pxref{Creation and
Destruction}).  Their use within the function should be
self-explanatory.

@cat bst Copying (iterative; robust)
@<BST copy function@> =
@<BST copy error helper function@>

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
struct bst_table *@
bst_copy (const struct bst_table *org, bst_copy_func *copy,
	  bst_item_func *destroy, struct libavl_allocator *allocator) @
{
  struct bst_node *stack[2 * (BST_MAX_HEIGHT + 1)];
  int height = 0;

  struct bst_table *new;
  const struct bst_node *x;
  struct bst_node *y;

  assert (org != NULL);
  new = bst_create (org->bst_compare, org->bst_param, 
                    allocator != NULL ? allocator : org->bst_alloc);
  if (new == NULL)
    return NULL;
  new->bst_count = org->bst_count;
  if (new->bst_count == 0)
    return new;

  x = (const struct bst_node *) &org->bst_root;
  y = (struct bst_node *) &new->bst_root;
  for (;;) @
    {@-
      while (x->bst_link[0] != NULL) @
	{@-
	  if (height >= 2 * (BST_MAX_HEIGHT + 1)) @
	    {@-
	      y->bst_data = NULL;
	      y->bst_link[0] = y->bst_link[1] = NULL;
	      copy_error_recovery (stack, height, new, destroy);

	      bst_balance ((struct bst_table *) org);
	      return bst_copy (org, copy, destroy, allocator);
	    }@+
	  
	  y->bst_link[0] = @
            new->bst_alloc->libavl_malloc (new->bst_alloc,
                                           sizeof *y->bst_link[0]);
	  if (y->bst_link[0] == NULL) @
	    {@-
	      if (y != (struct bst_node *) &new->bst_root) @
		{@-
		  y->bst_data = NULL;
		  y->bst_link[1] = NULL;
		}@+

	      copy_error_recovery (stack, height, new, destroy);
	      return NULL;
	    }@+

	  stack[height++] = (struct bst_node *) x;
	  stack[height++] = y;
	  x = x->bst_link[0];
	  y = y->bst_link[0];
	}@+
      y->bst_link[0] = NULL;

      for (;;) @
	{@-
	  if (copy == NULL) 
	    y->bst_data = x->bst_data;
	  else @
	    {@-
	      y->bst_data = copy (x->bst_data, org->bst_param);
	      if (y->bst_data == NULL) @
		{@-
		  y->bst_link[1] = NULL;
		  copy_error_recovery (stack, height, new, destroy);
		  return NULL;
		}@+
	    }@+

	  if (x->bst_link[1] != NULL) @
	    {@-
	      y->bst_link[1] = @
                new->bst_alloc->libavl_malloc (new->bst_alloc,
                                               sizeof *y->bst_link[1]);
	      if (y->bst_link[1] == NULL) @
		{@-
		  copy_error_recovery (stack, height, new, destroy);
		  return NULL;
		}@+

	      x = x->bst_link[1];
	      y = y->bst_link[1];
	      break;
	    }@+
	  else @
	    y->bst_link[1] = NULL;

	  if (height <= 2)
	    return new;

	  y = stack[--height];
	  x = stack[--height];
	}@+
    }@+
}

@

@node Destroying a BST, Balancing a BST, Copying a BST, Binary Search Trees
@section Destruction

Eventually, we'll want to get rid of the trees we've spent all this time
constructing.  When this happens, it's time to destroy them by freeing
their memory.

@menu
* Destroying a BST by Rotation::  
* Destroying a BST Recursively::  
* Destroying a BST Iteratively::  
@end menu

@node Destroying a BST by Rotation, Destroying a BST Recursively, Destroying a BST, Destroying a BST
@subsection Destruction by Rotation

The method actually used in @libavl{} for destruction of binary trees
is somewhat novel.  This section will cover this method.  Later
sections will cover more conventional techniques using recursive or
iterative @gloss{postorder traversal}.

To destroy a binary tree, we must visit and free each node.  We have
already covered one way to traverse a tree (inorder traversal) and used
this technique for traversing and copying a binary tree.  But, both
times before, we were subject to both the explicit constraint that we
had to visit the nodes in sorted order and the implicit constraint that
we were not to change the structure of the tree, or at least not to
change it for the worse.

Neither of these constraints holds for destruction of a binary tree.  As
long as the tree finally ends up freed, it doesn't matter how much it is
mangled in the process.  In this case, ``the end justifies the means''
and we are free to do it however we like.

So let's consider why we needed a stack before.  It was to keep track of
nodes whose left subtree we were currently visiting, in order to go back
later and visit them and their right subtrees.  Hmm@dots{}what if we
rearranged nodes so that they @emph{didn't have} any left subtrees?
Then we could just descend to the right, without need to keep track of
anything on a stack.

We can do this.  For the case where the current node |p| has a left
child |q|, consider the transformation below where we rotate right at
|p|:

@center @image{destroy}

@noindent where |a|, |b|, and |c| are arbitrary subtrees or even empty 
trees.  This transformation shifts nodes from the left to the right
side of the root (which is now |q|).  If it is performed enough times,
the root node will no longer have a left child.  After the
transformation, |q| becomes the current node.

For the case where the current node has no left child, we can just
destroy the current node and descend to its right.  Because the
transformation used does not change the tree's ordering, we end up
destroying nodes in inorder.  It is instructive to verify this by
simulating with paper and pencil the destruction of a few trees this
way.

The code to implement destruction in this manner is brief and
straightforward:

@cat bst Destruction (by rotation)
@<BST destruction function@> =
@iftangle
/* Frees storage allocated for |tree|.
   If |destroy != NULL|, applies it to each data item in inorder. */
@end iftangle
void @
bst_destroy (struct bst_table *tree, bst_item_func *destroy) @
{
  struct bst_node *p, *q;

  assert (tree != NULL);

  for (p = tree->bst_root; p != NULL; p = q)
    if (p->bst_link[0] == NULL) @
      {@-
	q = p->bst_link[1];
	if (destroy != NULL && p->bst_data != NULL) 
	  destroy (p->bst_data, tree->bst_param);
	tree->bst_alloc->libavl_free (tree->bst_alloc, p);
      }@+ @
    else @
      {@-
	q = p->bst_link[0];
	p->bst_link[0] = q->bst_link[1];
	q->bst_link[1] = p;
      }@+

  tree->bst_alloc->libavl_free (tree->bst_alloc, tree);
}

@

@references
@bibref{Stout 1986}, |tree_to_vine| procedure.

@exercise
Before calling |destroy()| above, we first test that we are not passing
it a |NULL| pointer, because we do not want |destroy()| to have to deal
with this case.  How can such a pointer get into the tree in the first
place, since |bst_probe()| refuses to insert such a pointer into a tree?

@answer
|bst_copy()| can set |bst_data| to |NULL| when memory allocation fails.
@end exercise

@node Destroying a BST Recursively, Destroying a BST Iteratively, Destroying a BST by Rotation, Destroying a BST
@subsection Aside: Recursive Destruction

The algorithm used in the previous section is easy and fast, but it is
not the most common method for destroying a tree.  The usual way is to
perform a traversal of the tree, in much the same way we did for tree
traversal and copying.  Once again, we'll start from a recursive
implementation, because these are so easy to write.  The only tricky
part is that subtrees have to be freed @emph{before} the root.  This
code is hard-wired to use |free()| for simplicity:

@cat bst Destruction, recursive
@c tested 2000/7/8
@<Destroy a BST recursively@> =
static void @
bst_destroy_recursive (struct bst_node *node) @
{
  if (node == NULL)
    return;

  bst_destroy_recursive (node->bst_link[0]);
  bst_destroy_recursive (node->bst_link[1]);
  free (node);
}
@

@node Destroying a BST Iteratively,  , Destroying a BST Recursively, Destroying a BST
@subsection Aside: Iterative Destruction

As we've done before for other algorithms, we can factor the recursive
destruction algorithm into an equivalent iteration.  In this case,
neither recursive call is tail recursive, and we can't easily modify
the code so that it is.  We could still factor out the recursion by
our usual methods, although it would be more difficult, but this
problem is simple enough to figure out from first principles.  Let's
do it that way, instead, this time.

The idea is that, for the tree's root, we traverse its left subtree,
then its right subtree, then free the root.  This pattern is called a
@gloss{postorder traversal}.

Let's think about how much state we need to keep track of.  When we're
traversing the root's left subtree, we still need to remember the root,
in order to come back to it later.  The same is true while traversing
the root's right subtree, because we still need to come back to free the
root.  What's more, we need to keep track of what state we're in: have
we traversed the root's left subtree or not, have we traversed the
root's right subtree or not?

This naturally suggests a stack that holds two-part items |(root,
state)|, where |root| is the root of the tree or subtree and |state| is
the state of the traversal at that node.  We start by selecting the
tree's root as our current node |p|, then pushing |(p, 0)| onto the
stack and moving down to the left as far as we can, pushing as we go.
Then we start popping off the stack into |(p, state)| and notice that
|state| is 0, which tells us that we've traversed |p|'s left subtree but
not its right.  So, we push |(p, 1)| back onto the stack, then we
traverse |p|'s right subtree.  When, later, we pop off that same node
back off the stack, the 1 tells us that we've already traversed both
subtrees, so we free the node and keep popping.  The pattern follows as
we continue back up the tree.

That sounds pretty complicated, so let's work through an example to help
clarify.  Consider this binary search tree:

@center @image{traversal}

Abstractly speaking, we start with 4 as |p| and an empty stack.  First,
we work our way down the left-child pointers, pushing onto the stack as
we go.  We push |(4, 0)|, then |(2, 0)|, then |(1, 0)|, and then |p| is
|NULL| and we've fallen off the bottom of the tree.  We pop the top item
off the stack into |(p, state)|, getting |(1, 0)|.  Noticing that we
have 0 for |state|, we push |(1, 1)| on the stack and traverse 1's right
subtree, but it is empty so there is nothing to do.  We pop again and
notice that |state| is 1, meaning that we've fully traversed 1's
subtrees, so we free node 1.  We pop again, getting 2 for |p| and 0 for
|state|.  Because |state| is |0|, we push |(2, 1)| and traverse 2's
right subtree, which means that we push |(3, 0)|.  We traverse 3's null
right subtree (again, it is empty so there is nothing to do), pushing
and popping |(3, 1)|, then free node 3, then move back up to 2.  Because
we've traversed 2's right subtree, |state| is 1 and |p| is 2, and we
free node 2.  You should be able to figure out how 4 and 5 get freed.

A straightforward implementation of this approach looks like this:

@cat bst Destruction, iterative
@c tested 2001/6/27
@<Destroy a BST iteratively@> =
@iftangle
/* Frees storage allocated for |tree|.
   If |destroy != NULL|, applies it to each data item in indeterminate @
   order. */
@end iftangle
void @
bst_destroy (struct bst_table *tree, bst_item_func *destroy) @
{
  struct bst_node *stack[BST_MAX_HEIGHT];
  unsigned char state[BST_MAX_HEIGHT];
  int height = 0;

  struct bst_node *p;

  assert (tree != NULL);
  p = tree->bst_root;
  for (;;) @
    {@-
      while (p != NULL) @
        {@-
          if (height >= BST_MAX_HEIGHT) @
            {@-
              fprintf (stderr, "tree too deep\n");
              exit (EXIT_FAILURE);
            }@+
          stack[height] = p;
          state[height] = 0;
          height++;

          p = p->bst_link[0];
        }@+

      for (;;) @
        {@-
          if (height == 0) @
            {@-
              tree->bst_alloc->libavl_free (tree->bst_alloc, tree);
              return;
            }@+

          height--;
          p = stack[height];
          if (state[height] == 0) @
            {@-
              state[height++] = 1;
              p = p->bst_link[1];
              break;
            } @
          else @
            {
              if (destroy != NULL && p->bst_data != NULL)
                destroy (p->bst_data, tree->bst_param);
              tree->bst_alloc->libavl_free (tree->bst_alloc, p);
            }@+
        }@+
    }@+
}
@

@c FIXME: Exercise benchmarking difference in speed.

@c FIXME: Exercise adding code to handle stack overflow?

@references
@bibref{Knuth 1997}, exercise 13 in section 2.3.1.

@node Balancing a BST, Joining BSTs, Destroying a BST, Binary Search Trees
@section Balance

Sometimes binary trees can grow to become much taller than their optimum
height.  For example, the following binary tree was one of the tallest
from a sample of 100 15-node trees built by inserting nodes in random
order:

@center @image{bal1}

The average number of comparisons required to find a random node in this
tree is @altmath{(1 + 2 + (3 \times 2) + (4 \times 4) + (5 \times 4) + 6 + 7 +
8) / 15 = 4.4, (1 + 2 + (3 * 2) + (4 * 4) + (5 * 4) + 6 + 7 + 8) / 15 = 4.4}
comparisons.  In contrast, the corresponding optimal binary tree, shown
below, requires only @altmath{(1 + (2 \times 2) + (3 \times 4) + (4 \times
8))/15 = 3.3, (1 + (2 * 2) + (3 * 4) + (4 * 8))/15 = 3.3} comparisons, on
average.  Moreover, the optimal tree requires a maximum of 4, as opposed
to 8, comparisons for any search:

@center @image{bal2}

Besides this inefficiency in time, trees that grow too tall can cause
inefficiency in space, leading to an overflow of the stack in
|bst_t_next()|, |bst_copy()|, or other functions.  For both reasons, it
is helpful to have a routine to rearrange a tree to its minimum possible
height, that is, to @gloss{balance} the tree.

The algorithm we will use for balancing proceeds in two stages.  In the
first stage, the binary tree is ``flattened'' into a pathological,
linear binary tree, called a ``vine.''  In the second stage, binary tree
structure is restored by repeatedly ``compressing'' the vine into a
minimal-height binary tree.

Here's a top-level view of the balancing function:

@cat bst Balancing
@<BST balance function@> =
@<BST to vine function@>
@<Vine to balanced BST function@>

@iftangle
/* Balances |tree|.
   Ensures that no simple path from the root to a leaf has more than
   |BST_MAX_HEIGHT| nodes. */
@end iftangle
void @
bst_balance (struct bst_table *tree) @
{
  assert (tree != NULL);

  tree_to_vine (tree);
  vine_to_tree (tree);
  tree->bst_generation++;
}

@

@<BST extra function prototypes@> =

/* Special BST functions. */
void bst_balance (struct bst_table *tree);
@

@references
@bibref{Stout 1986}, |rebalance| procedure.

@menu
* Transforming a BST into a Vine::  
* Transforming a Vine into a Balanced BST::  
@end menu

@node Transforming a BST into a Vine, Transforming a Vine into a Balanced BST, Balancing a BST, Balancing a BST
@subsection From Tree to Vine

The first stage of balancing converts a binary tree into a linear
structure resembling a linked list, called a @gloss{vine}.  The vines we
will create have the greatest value in the binary tree at the root and
decrease descending to the left.  Any binary search tree that contains a
particular set of values, no matter its shape, corresponds to the same
vine of this type.  For instance, all binary search trees of the
integers 0@dots{}4 will be transformed into the following vine:

@center @image{vine}

The method for transforming a tree into a vine of this type is similar
to that used for destroying a tree by rotation (@pxref{Destroying a BST
by Rotation}).  We step pointer |p| through the tree, starting at the
root of the tree, maintaining pointer |q| as |p|'s parent.  (Because
we're building a vine, |p| is always the left child of |q|.)  At each
step, we do one of two things:

@itemize @bullet
@item
If |p| has no right child, then this part of the tree is already the
shape we want it to be.  We step |p| and |q| down to the left and
continue.

@item
If |p| has a right child |r|, then we rotate left at |p|, performing
the following transformation:

@center @image{tree2vine}

where |a|, |b|, and |c| are arbitrary subtrees or empty trees.  Node
|r| then becomes the new |p|.  If |c| is an empty tree, then, in the
next step, we will continue down the tree.  Otherwise, the right
subtree of |p| is smaller (contains fewer nodes) than previously, so
we're on the right track.
@end itemize

This is all it takes:

@cat bst Vine from tree
@<BST to vine function@> =
/* Converts |tree| into a vine. */
static void @
tree_to_vine (struct bst_table *tree) @
{
  struct bst_node *q, *p;

  q = (struct bst_node *) &tree->bst_root;
  p = tree->bst_root;
  while (p != NULL)
    if (p->bst_link[1] == NULL) @
      {@-
	q = p;
	p = p->bst_link[0];
      }@+
    else @
      {@-
	struct bst_node *r = p->bst_link[1];
	p->bst_link[1] = r->bst_link[0];
	r->bst_link[0] = p;
	p = r;
	q->bst_link[0] = r;
      }@+
}

@

@references
@bibref{Stout 1986}, |tree_to_vine| procedure.

@node Transforming a Vine into a Balanced BST,  , Transforming a BST into a Vine, Balancing a BST
@subsection From Vine to Balanced Tree

Converting the vine, once we have it, into a balanced tree is the
interesting and clever part of the balancing operation.  However, at
first it may be somewhat less than obvious how this is actually done.
We will tackle the subject by presenting an example, then the
generalized form.

Suppose we have a vine, as above, with @altmath{2^n - 1, 2**n - 1} nodes
for positive integer @math{n}.  For the sake of example, take @math{n =
4}, corresponding to a tree with 15 nodes.  We convert this vine into a
balanced tree by performing three successive @gloss{compression}
operations.

To perform the first compression, move down the vine, starting at the
root.  Conceptually assign each node a ``color'', alternating between
red and black and starting with red at the root.@footnote{These colors
are for the purpose of illustration only.  They are not stored in the
nodes and are not related to those used in a @gloss{red-black tree}.}
Then, take each red node, except the bottommost, and remove it from the
vine, making it the child of its black former child node.

After this transformation, we have something that looks a little more
like a tree.  Instead of a 15-node vine, we have a 7-node black vine
with a 7-node red vine as its right children and a single red node as
its left child.  Graphically, this first compression step on a 15-node
vine looks like this:

@center @image{vine2tree}

To perform the second compression, recolor all the red nodes to white,
then change the color of alternate black nodes to red, starting at the
root.  As before, extract each red node, except the bottommost, and
reattach it as the child of its black former child node.  Attach each
black node's right subtree as the left subtree of the corresponding red
node.  Thus, we have the following:

@center @image{vine2tree2}

The third compression is the same as the first two.  Nodes 12 and 4 are
recolored red, then node 12 is removed and reattached as the right
child of its black former child node 8, receiving node 8's right subtree
as its left subtree:

@center @image{vine2tree3}

The result is a fully balanced tree.

@menu
* Balancing General Trees::     
* Balancing Implementation::    
* Implementing Compression::   
@end menu

@node Balancing General Trees, Balancing Implementation, Transforming a Vine into a Balanced BST, Transforming a Vine into a Balanced BST
@subsubsection General Trees

A compression is the repeated application of a right rotation, called
in this context a ``compression transformation'', once for each black
node, like so:

@center @image{compress}

@noindent 
So far, all of the compressions we've performed have involved all
@altmath{2^k - 1, 2**k - 1} nodes composing the ``main vine.''  This
works out well for an initial vine of exactly @altmath{2^n - 1, 2**n -
1} nodes.  In this case, a total of @math{n - 1} compressions are
required, where for successive compressions @math{k = n, n - 1,
@dots{}, 2}.

For trees that do not have exactly one fewer than a power of two nodes,
we need to begin with a compression that does not involve all of the
nodes in the vine.  Suppose that our vine has @math{m} nodes, where
@altmath{2^n - 1 < m < 2^{n+1} - 1, 2**n - 1 < m < 2**(n+1) - 1} for
some value of @math{n}.  Then, by applying the compression
transformation shown above @altmath{m - (2^n - 1), m - (2**n - 1)}
times, we reduce the length of the main vine to exactly @altmath{2^n -
1, 2**n - 1} nodes.  After that, we can treat the problem in the same
way as the former case.  The result is a balanced tree with @math{n}
full levels of nodes, and a bottom level containing @altmath{m - (2^n -
1), m - (2**n - 1)} nodes and @altmath{(2^{n + 1} - 1) - m, (2**(n + 1)
- 1) - m} vacancies.

An example is indicated.  Suppose that the vine contains |m @= 9| nodes
numbered from 1 to 9.  Then |n @= 3| since we have @altmath{2^3 - 1
\equiv 7 < 9 < 15 \equiv 2^4 - 1, 2**3 - 1 = 7 < 9 < 15 = 2**4 - 1}, and
we must perform the compression transformation shown above @altmath{9 -
(2^3 - 1) \equiv 2, 9 - (2**3 - 1) = 2} times initially, reducing the
main vine's length to 7 nodes.  Afterward, we treat the problem the same
way as for a tree that started off with only 7 nodes, performing one
compression with |k @= 3| and one with |k @= 2|.  The entire sequence,
omitting the initial vine, looks like this:

@center @image{balance9}

Now we have a general technique that can be applied to a vine of any
size.

@node Balancing Implementation, Implementing Compression, Balancing General Trees, Transforming a Vine into a Balanced BST
@subsubsection Implementation

Implementing this algorithm is more or less straightforward.  Let's
start from an outline:

@cat bst Vine to balanced tree
@<Vine to balanced BST function@> =
@<BST compression function@>

/* Converts |tree|, which must be in the shape of a vine, into a balanced @
   tree. */
static void @
vine_to_tree (struct bst_table *tree) @
{
  unsigned long vine;   /* Number of nodes in main vine. */
  unsigned long leaves; /* Nodes in incomplete bottom level, if any. */
  int height;           /* Height of produced balanced tree. */

  @<Calculate |leaves|@>
  @<Reduce vine general case to special case@>
  @<Make special case vine into balanced tree and count height@>
  @<Check for tree height in range@>
}
@

The first step is to calculate the number of compression transformations
necessary to reduce the general case of a tree with @math{m} nodes to
the special case of exactly @altmath{2^n - 1, 2**n - 1} nodes, i.e.,
calculate @altmath{m - (2^n - 1), m - (2**n - 1)}, and store it in
variable |leaves|.  We are given only the value of @math{m}, as
|tree->bst_count|.  Rewriting the calculation as the equivalent
@altmath{m + 1 - 2^n, m + 1 - 2**n}, one way to calculate it is evident
from looking at the pattern in binary:

@tex
\global\def\hf{\hskip 1pt plus1fill}
\global\def\binary#1{$#1_2$}
@end tex
@ifnottex
@macro hf {}
@end macro
@macro binary {BITS}
\BITS\
@end macro
@end ifnottex

@need 750
@multitable @columnfractions .195 .06 .06 .17 .16 .16
@item @tab @hf{}@math{m}
@tab @hf{}@math{n}
@tab @hf{}@w{  }@math{m + 1}@hf{}
@tab @hf{}@w{  }@altmath{2^n, 2**n}@hf{}
@tab @hf{}@altmath{m + 1 - 2^n, m + 1 - 2**n}@hf{}

@item @tab @hf{}1
@tab @hf{}1
@tab @hf{}@w{ }2 = @binary{00010}
@tab @hf{}2 = @binary{00010}
@tab @hf{}0 = @binary{00000}

@item @tab @hf{}2
@tab @hf{}1
@tab @hf{}@w{ }3 = @binary{00011}
@tab @hf{}2 = @binary{00010}
@tab @hf{}1 = @binary{00001}

@item @tab @hf{}3
@tab @hf{}2
@tab @hf{}@w{ }4 = @binary{00100}
@tab @hf{}4 = @binary{00100}
@tab @hf{}0 = @binary{00000}

@item @tab @hf{}4
@tab @hf{}2
@tab @hf{}@w{ }5 = @binary{00101}
@tab @hf{}4 = @binary{00100}
@tab @hf{}1 = @binary{00001}

@item @tab @hf{}5
@tab @hf{}2
@tab @hf{}@w{ }6 = @binary{00110}
@tab @hf{}4 = @binary{00100}
@tab @hf{}2 = @binary{00010}

@item @tab @hf{}6
@tab @hf{}2
@tab @hf{}@w{ }7 = @binary{00111}
@tab @hf{}4 = @binary{00100}
@tab @hf{}3 = @binary{00011}

@item @tab @hf{}7
@tab @hf{}3
@tab @hf{}@w{ }8 = @binary{01000}
@tab @hf{}8 = @binary{01000}
@tab @hf{}0 = @binary{00000}

@item @tab @hf{}8
@tab @hf{}3
@tab @hf{}@w{ }9 = @binary{01001}
@tab @hf{}8 = @binary{01000}
@tab @hf{}1 = @binary{00000}

@item @tab @hf{}9
@tab @hf{}3
@tab @hf{}10 = @binary{01001}
@tab @hf{}8 = @binary{01000}
@tab @hf{}2 = @binary{00000}

@end multitable

See the pattern?  It's simply that @altmath{m + 1 - 2^n, m + 1 - 2**n}
is @math{m} with the leftmost 1-bit turned off.  So, if we can find the
leftmost 1-bit in @altmath{m + 1}, we can figure out the number of
leaves.

In turn, there are numerous ways to find the leftmost 1-bit in a number.
The one used here is based on the principle that, if |x| is a positive
integer, then |x & (x - 1)| is |x| with its rightmost 1-bit turned off.

Here's the code that calculates the number of leaves and stores it in
|leaves|:

@<Calculate |leaves|@> =
leaves = tree->bst_count + 1;
for (;;) @
  {@-
    unsigned long next = leaves & (leaves - 1);
    if (next == 0)
      break;
    leaves = next;
  }@+
leaves = tree->bst_count + 1 - leaves;

@

Once we have the number of leaves, we perform a compression composed of
|leaves| compression transformations.  That's all it takes to reduce the
general case to the @altmath{2^n - 1, 2**n - 1} special case.  We'll
write the |compress()| function itself later:

@<Reduce vine general case to special case@> =
compress ((struct bst_node *) &tree->bst_root, leaves);

@

The heart of the function is the compression of the vine into the
tree.  Before each compression, |vine| contains the number of nodes in
the main vine of the tree.  The number of compression transformations
necessary for the compression is |vine / 2|; e.g., when the main vine
contains 7 nodes, @math{7 / 2 = 3} transformations are necessary.  The
number of nodes in the vine afterward is the same number
(@pageref{Transforming a Vine into a Balanced BST}).

At the same time, we keep track of the height of the balanced tree.  The
final tree always has height at least 1.  Each compression step means
that it is one level taller than that.  If the tree needed
general-to-special-case transformations, that is, |leaves > 0|, then
it's one more than that.

@<Make special case vine into balanced tree and count height@> =
vine = tree->bst_count - leaves;
height = 1 + (leaves > 0);
while (vine > 1) @
  {@-
    compress ((struct bst_node *) &tree->bst_root, vine / 2);
    vine /= 2;
    height++;
  }@+

@

Finally, we make sure that the height of the tree is within range for
what the functions that use stacks can handle.  Otherwise, we could end
up with an infinite loop, with |bst_t_next()| (for example) calling
|bst_balance()| repeatedly to balance the tree in order to reduce its
height to the acceptable range.

@<Check for tree height in range@> =
if (height > BST_MAX_HEIGHT) @
  {@-
    fprintf (stderr, "libavl: Tree too big (%lu nodes) to handle.",
             (unsigned long) tree->bst_count);
    exit (EXIT_FAILURE);
  }@+
@

@node Implementing Compression,  , Balancing Implementation, Transforming a Vine into a Balanced BST
@subsubsection Implementing Compression

The final bit of code we need is that for performing a compression.  The
following code performs a compression consisting of |count| applications
of the compression transformation starting at |root|:

@cat bst Vine compression
@<BST compression function@> =
/* Performs a compression transformation |count| times, @
   starting at |root|. */
static void @
compress (struct bst_node *root, unsigned long count) @
{
  assert (root != NULL);

  while (count--) @
    {@-
      struct bst_node *red = root->bst_link[0];
      struct bst_node *black = red->bst_link[0];

      root->bst_link[0] = black;
      red->bst_link[0] = black->bst_link[1];
      black->bst_link[1] = red;
      root = black;
    }@+
}
@

The operation of |compress()| should be obvious, given the discussion
earlier.  @xref{Balancing General Trees}, above, for a review.

@references
@bibref{Stout 1986}, |vine_to_tree| procedure.

@node Joining BSTs, Testing BST Functions, Balancing a BST, Binary Search Trees
@section Aside: Joining BSTs

Occasionally we may want to take a pair of BSTs and merge or ``join''
their contents, forming a single BST that contains all the items in
the two original BSTs.  It's easy to do this with a series of calls to
|bst_insert()|, but we can optimize the process if we write a function
exclusively for the purpose.  We'll write such a function in this
section.

There are two restrictions on the trees to be joined.  First, the
BSTs' contents must be disjoint.  That is, no item in one may match
any item in the other.  Second, the BSTs must have compatible
comparison functions.  Typically, they are the same.  Speaking more
precisely, if |f()| and |g()| are the comparison functions, |p| and
|q| are nodes in either BST, and |r| and |s| are the BSTs'
user-provided extra comparison parameters, then the expressions
@w{|f(p, q, r)|}, @w{|f(p, q, s)|}, @w{|g(p, q, r)|}, and @w{|g(p, q,
s)|} must all have the same value for all possible choices of |p| and
|q|.

Suppose we're trying to join the trees shown below:

@center @image{bstjoin}

@noindent
Our first inclination is to try a ``divide and conquer'' approach by
reducing the problem of joining |a| and |b| to the subproblems of
joining |a|'s left subtree with |b|'s left subtree and joining |a|'s
right subtree with |b|'s right subtree.  Let us postulate for the
moment that we are able to solve these subproblems and that the
solutions that we come up with are the following:

@center @image{bstjoin2}

@noindent
To convert this partial solution into a full solution we must combine
these two subtrees into a single tree and at the same time reintroduce
the nodes |a| and |b| into the combined tree.  It is easy enough to do
this by making |a| (or |b|) the root of the combined tree with these
two subtrees as its children, then inserting |b| (or |a|) into the
combined tree.  Unfortunately, in neither case will this actually work
out properly for our example.  The diagram below illustrates one
possibility, the result of combining the two subtrees as the child of
node 4, then inserting node 7 into the final tree.  As you can see,
nodes 4 and 5 are out of order:@footnote{The |**| notation in the
diagram emphasizes that this is a counterexample.}

@center @image{bstjoin3}

Now let's step back and analyze why this attempt failed.  It was
essentially because, when we recombined the subtrees, a node in the
combined tree's left subtree had a value larger than the root.  If we
trace it back to the original trees to be joined, we see that this was
because node 5 in the left subtree of |b| is greater than |a|.  (If we
had chosen 7 as the root of the combined tree we would have found
instead node 6 in the right subtree of |b| to be the culprit.)

On the other hand, if every node in the left subtree of |a| had a
value less than |b|'s value, and every node in the right subtree of
|a| had a value greater than |b|'s value, there would be no problem.
Hey, wait a second@dots{} we can force that condition.  If we perform
a root insertion (@pxref{Root Insertion in a BST}) of |b| into subtree
|a|, then we end up with one pair of subtrees whose node values are
all less than 7 (the new and former left subtrees of node 7) and one
pair of subtrees whose node values are all greater than 7 (the new and
former right subtrees of node 7).  Conceptually it looks like this,
although in reality we would need to remove node 7 from the tree on
the right as we inserted it into the tree on the left:

@center @image{bstjoin4}

@noindent
We can then combine the two subtrees with values less than 7 with each
other, and similarly for the ones with values greater than 7, using
the same algorithm recursively, and safely set the resulting subtrees
as the left and right subtrees of node 7, respectively.  The final
product is a correctly joined binary tree:

@center @image{bstjoin5}

Of course, since we've defined a join recursively in terms of itself,
there must be some maximum depth to the recursion, some simple case
that can be defined without further recursion.  This is easy: the join
of an empty tree with another tree is the second tree.

@subsubheading Implementation

It's easy to implement this algorithm recursively.  The only
nonobvious part of the code below is the treatment of node |b|.  We
want to insert node |b|, but not |b|'s children, into the subtree
rooted at |a|.  However, we still need to keep track of |b|'s
children.  So we temporarily save |b|'s children as |b0| and |b1| and
set its child pointers to |NULL| before the root insertion.

This code makes use of |root_insert()| from @<Robust root insertion of
existing node in arbitrary subtree@>.

@cat bst Join, recursive
@c tested 2001/11/10
@<BST join function, recursive version@> =
/* Joins |a| and |b|, which are subtrees of |tree|, @
   and returns the resulting tree. */
static struct bst_node *@
join (struct bst_table *tree, struct bst_node *a, struct bst_node *b) @
{
  if (b == NULL)
    return a;
  else if (a == NULL)
    return b;
  else @
    {@-
      struct bst_node *b0 = b->bst_link[0];
      struct bst_node *b1 = b->bst_link[1];
      b->bst_link[0] = b->bst_link[1] = NULL;
      root_insert (tree, &a, b);
      a->bst_link[0] = join (tree, b0, a->bst_link[0]);
      a->bst_link[1] = join (tree, b1, a->bst_link[1]);
      return a;
    }@+
}

/* Joins |a| and |b|, which must be disjoint and have compatible @
   comparison functions.
   |b| is destroyed in the process. */
void @
bst_join (struct bst_table *a, struct bst_table *b) @
{
  a->bst_root = join (a, a->bst_root, b->bst_root);
  a->bst_count += b->bst_count;
  free (b);
}
@

@references
@bibref{Sedgewick 1998}, program 12.16.

@exercise
Rewrite |bst_join()| to avoid use of recursion.

@answer
Factoring out recursion is troublesome in this case.  Writing the loop
with an explicit stack exposes more explicitly the issue of stack
overflow.  Failure on stack overflow is not acceptable, because it
would leave both trees in disarray, so we handle it by dropping back
to a slower algorithm that does not require a stack.

This code also makes use of |root_insert()| from @<Robust root
insertion of existing node in arbitrary subtree@>.

@cat bst Join, iterative
@c tested 2001/11/10
@<BST join function, iterative version@> =
/* Adds to |tree| all the nodes in the tree rooted at |p|. */
static void @
fallback_join (struct bst_table *tree, struct bst_node *p) @
{
  struct bst_node *q;

  for (; p != NULL; p = q)
    if (p->bst_link[0] == NULL) @
      {@-
        q = p->bst_link[1];
	p->bst_link[0] = p->bst_link[1] = NULL;
	root_insert (tree, &tree->bst_root, p);
      }@+
    else @
      {@-
        q = p->bst_link[0];
        p->bst_link[0] = q->bst_link[1];
        q->bst_link[1] = p;
      }@+
}

/* Joins |a| and |b|, which must be disjoint and have compatible @
   comparison functions.
   |b| is destroyed in the process. */
void @
bst_join (struct bst_table *ta, struct bst_table *tb) @
{
  size_t count = ta->bst_count + tb->bst_count;
  
  if (ta->bst_root == NULL)
    ta->bst_root = tb->bst_root;
  else if (tb->bst_root != NULL) @
    {@-
      struct bst_node **pa[BST_MAX_HEIGHT];
      struct bst_node *qa[BST_MAX_HEIGHT];
      int k = 0;

      pa[k] = &ta->bst_root;
      qa[k++] = tb->bst_root;
      while (k > 0) @
	{@-
	  struct bst_node **a = pa[--k];
	  struct bst_node *b = qa[k];

	  for (;;) @
	    {@-
	      struct bst_node *b0 = b->bst_link[0];
	      struct bst_node *b1 = b->bst_link[1];
	      b->bst_link[0] = b->bst_link[1] = NULL;
	      root_insert (ta, a, b);

	      if (b1 != NULL) @
		{@-
		  if (k < BST_MAX_HEIGHT) @
		    {@-
		      pa[k] = &(*a)->bst_link[1];
		      qa[k] = b1;
		      if (*pa[k] != NULL)
			k++;
		      else @
			*pa[k] = qa[k];
		    }@+ @
		  else @
		    {@-
		      int j;

		      fallback_join (ta, b0);
		      fallback_join (ta, b1);
		      for (j = 0; j < k; j++)
			fallback_join (ta, qa[j]);

		      ta->bst_count = count;
		      free (tb);
		      bst_balance (ta);
		      return;
		    }@+
		}@+
	      
	      a = &(*a)->bst_link[0];
	      b = b0;
	      if (*a == NULL) @
		{@-
		  *a = b;
		  break;
		}@+ @
	      else if (b == NULL)
		break;
	    }@+
	}@+
    }@+

  ta->bst_count = count;
  free (tb);
}
@
@end exercise

@node Testing BST Functions, Additional Exercises for BSTs, Joining BSTs, Binary Search Trees
@section Testing

Whew!  We're finally done with building functions for performing BST
operations.  But we haven't tested any of our code.  Testing is an
essential step in writing programs, because untested software cannot be
assumed to work.

Let's build a test program that exercises all of the functions we wrote.
We'll also do our best to make parts of it generic, so that we can reuse
test code in later chapters when we want to test other BST-based
structures.

The first step is to figure out how to test the code.  One goal in
testing is to exercise as much of the code as possible.  Ideally, every
line of code would be executed sometime during testing.  Often, this is
difficult or impossible, but the principle remains valid, with the goal
modified to testing as much of the code as possible.

In applying this principle to the BST code, we have to consider why each
line of code is executed.  If we look at the code for most functions in
@(bst.c@>, we can see that, if we execute them for any BST of reasonable
size, most or all of their code will be tested.

This is encouraging.  It means that we can just construct some trees and
try out the BST functions on them, check that the results make sense,
and have a pretty good idea that they work.  Moreover, if we build trees
in a random fashion, and delete their nodes in a random order, and do it
several times, we'll even have a good idea that the |bst_probe()| and
|bst_delete()| cases have all come up and worked properly.  (If you want
to be sure, then you can insert |printf()| calls for each case to record
when they trip.)  This is not the same as a proof of correctness, but
proofs of correctness can only be constructed by computer scientists
with fancy degrees, not by mere clever programmers.

There are three notably missing pieces of code coverage if we just do
the above.  These are stack overflow handling, memory allocation failure
handling, and traverser code to deal with modified trees.  But we can
mop up these extra problems with a little extra effort:@footnote{Some
might scoff at this amount of detail, calling it wasted effort, but this
thorough testing in fact revealed a number of subtle bugs during
development of @libavl{} that had otherwise gone unnoticed.}

@itemize @bullet
@item 
Stack overflow handling can be tested by forcing the stack to overflow.
Stack overflow can occur in many places, so for best effect we must test
each possible spot.  We will write special tests for these problems.

@item
Memory allocation failure handling can be tested by simulating memory
allocation failures.  We will write a replacement memory allocator that
``fails'' after a specified number of calls.  This allocator will also
allow for memory leak detection.

@item
Traverser code to deal with modified trees.  This can be tested by
modifying trees during traversal and making sure that the traversal
functions still work as expected.
@end itemize

The testing code can be broken into the following groups of functions:

@table @b
@item Testing and verification
These functions actually try out the BST routines and do their best to
make sure that their results are correct.

@item Test set generation
Generates the order of node insertion and deletion, for use during
testing.

@item Memory manager
Handles memory issues, including memory leak detection and failure
simulation.

@item User interaction
Figures out what the user wants to test in this run.

@item Main program
Glues everything else together by calling functions in the proper order.

@item Utilities
Miscellaneous routines that don't fit comfortably into another category.
@end table

Most of the test code will also work nicely for testing other binary
tree-based structures.  This code is grouped into a single file,
@(test.c@>, which has the following structure:

@(test.c@> =
@<Program License@>
#include <assert.h>
#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "test.h"

@<Test declarations@>
@<Test utility functions@>
@<Memory tracker@>
@<Option parser@>
@<Command line parser@>
@<Insertion and deletion order generation@>
@<Random number seeding@>
@<Test main program@>
@

The code specifically for testing BSTs goes into @(bst-test.c@>,
outlined like this:

@(bst-test.c@> =
@<Program License@>
#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include "bst.h"
#include "test.h"

@<BST print function@>
@<BST traverser check function@>
@<Compare two BSTs for structure and content@>
@<Recursively verify BST structure@>
@<BST verify function@>
@<BST test function@>
@<BST overflow test function@>
@

The interface between @(test.c@> and @(bst-test.c@> is contained
in @(test.h@>:

@(test.h@> =
@<Program License@>
#ifndef TEST_H
#define TEST_H 1

@<Memory allocator@>
@<Test prototypes@>

#endif /* test.h */
@

Although much of the test program code is nontrivial, only some of the
interesting parts fall within the scope of this book.  The remainder
will be listed without comment or relegated to the exercises.  The most
tedious code is listed in an appendix (@pxref{Supplementary Code}).

@menu
* Testing BSTs::                
* Test Set Generation::         
* Testing Overflow::            
* Memory Manager::              
* User Interaction::            
* Utility Functions::           
* Main Program::                
@end menu

@node Testing BSTs, Test Set Generation, Testing BST Functions, Testing BST Functions
@subsection Testing BSTs

As suggested above, the main way we will test the BST routines is by
using them and checking the results, with checks performed by slow but
simple routines.  The idea is that bugs in the BST routines are unlikely
to be mirrored in the check routines, and vice versa.  This way,
identical results from the BST and checks tend to indicate that both
implementations are correct.

The main test routine is designed to exercise as many of the BST
functions as possible.  It starts by creating a BST and inserting nodes
into it, then deleting the nodes.  Midway, various traversals are
tested, including the ability to traverse a tree while its content is
changing.  After each operation that modifies the tree, its structure
and content are verified for correspondence with expectations.  The
function for copying a BST is also tested.  This function, |test()|, has
the following outline:

@<BST test function@> =
/* Tests tree functions.  
   |insert[]| and |delete[]| must contain some permutation of values @
   |0|@dots{}|n - 1|.
   Uses |allocator| as the allocator for tree and node data.
   Higher values of |verbosity| produce more debug output. */
int @
test_correctness (struct libavl_allocator *allocator,
                  int insert[], int delete[], int n, int verbosity) @
{
  struct bst_table *tree;
  int okay = 1;
  int i;

  @<Test creating a BST and inserting into it@>
  @<Test BST traversal during modifications@>
  @<Test deleting nodes from the BST and making copies of it@>
  @<Test deleting from an empty tree@>
  @<Test destroying the tree@>

  return okay;
}

@

@<Test prototypes@> =
int test_correctness (struct libavl_allocator *allocator,
                      int insert[], int delete[], int n, int verbosity);
@

The first step is to create a BST and insert items into it in the order
specified by the caller.  We use the comparison function
|compare_ints()| from @<Comparison function for |int|s@> to put the
tree's items into ordinary numerical order.  After each insertion we
call |verify_tree()|, which we'll write later and which checks that the
tree actually contains the items that it should:

@<Test creating a BST and inserting into it@> =
@iftangle
/* Test creating a BST and inserting into it. */
@end iftangle
tree = bst_create (compare_ints, NULL, allocator);
if (tree == NULL) @
  {@-
    if (verbosity >= 0) @
      printf ("  Out of memory creating tree.\n");
    return 1;
  }@+

for (i = 0; i < n; i++) @
  {@-
    if (verbosity >= 2) @
      printf ("  Inserting %d...\n", insert[i]);

    /* Add the |i|th element to the tree. */
    {
      void **p = bst_probe (tree, &insert[i]);
      if (p == NULL) @
        {@-
          if (verbosity >= 0) @
            printf ("    Out of memory in insertion.\n");
          bst_destroy (tree, NULL);
          return 1;
        }@+
      if (*p != &insert[i]) @
        printf ("    Duplicate item in tree!\n");
    }

    if (verbosity >= 3) @
      print_whole_tree (tree, "    Afterward");

    if (!verify_tree (tree, insert, i + 1))
      return 0;
  }@+

@

If the tree is being modified during traversal, that causes a little
more stress on the tree routines, so we should test this specially.  We
initialize one traverser, |x|, at a selected item, then delete and
reinsert a different item in order to invalidate that traverser.  We
make a copy, |y|, of the traverser in order to check that |bst_t_copy()|
works properly and initialize a third traverser, |z|, with the inserted
item.  After the deletion and reinsertion we check that all three of the
traversers behave properly.

@<Test BST traversal during modifications@> =
@iftangle
/* Test BST traversal during modifications. */
@end iftangle
for (i = 0; i < n; i++) @
  {@-
    struct bst_traverser x, y, z;
    int *deleted;

    if (insert[i] == delete[i])
      continue;

    if (verbosity >= 2)
      printf ("   Checking traversal from item %d...\n", insert[i]);

    if (bst_t_find (&x, tree, &insert[i]) == NULL) @
      {@-
        printf ("    Can't find item %d in tree!\n", insert[i]);
        continue;
      }@+

    okay &= check_traverser (&x, insert[i], n, "Predeletion");

    if (verbosity >= 3) @
      printf ("    Deleting item %d.\n", delete[i]);

    deleted = bst_delete (tree, &delete[i]);
    if (deleted == NULL || *deleted != delete[i]) @
      {@-
        okay = 0;
        if (deleted == NULL)
          printf ("    Deletion failed.\n");
        else @
          printf ("    Wrong node %d returned.\n", *deleted);
      }@+

    bst_t_copy (&y, &x);

    if (verbosity >= 3) @
      printf ("    Re-inserting item %d.\n", delete[i]);
    if (bst_t_insert (&z, tree, &delete[i]) == NULL) @
      {@-
        if (verbosity >= 0) @
          printf ("    Out of memory re-inserting item.\n");
        bst_destroy (tree, NULL);
        return 1;
      }@+

    okay &= check_traverser (&x, insert[i], n, "Postdeletion");
    okay &= check_traverser (&y, insert[i], n, "Copied");
    okay &= check_traverser (&z, delete[i], n, "Insertion");

    if (!verify_tree (tree, insert, n))
      return 0;
  }@+

@

The |check_traverser()| function used above checks that a traverser
behaves properly, by checking that the traverser is at the correct item
and that the previous and next items are correct as well.

@<BST traverser check function@> =
/* Checks that the current item at |trav| is |i|
   and that its previous and next items are as they should be.
   |label| is a name for the traverser used in reporting messages.
   There should be |n| items in the tree numbered |0|@dots{}|n - 1|.
   Returns nonzero only if there is an error. */
static int @
check_traverser (struct bst_traverser *trav, int i, int n, const char *label) @
{
  int okay = 1;
  int *cur, *prev, *next;

  prev = bst_t_prev (trav);
  if ((i == 0 && prev != NULL) @
      || (i > 0 && (prev == NULL || *prev != i - 1))) @
    {@-
      printf ("   %s traverser ahead of %d, but should be ahead of %d.\n",
	      label, prev != NULL ? *prev : -1, i == 0 ? -1 : i - 1);
      okay = 0;
    }@+
  bst_t_next (trav);

  cur = bst_t_cur (trav);
  if (cur == NULL || *cur != i) @
    {@-
      printf ("   %s traverser at %d, but should be at %d.\n",
	      label, cur != NULL ? *cur : -1, i);
      okay = 0;
    }@+

  next = bst_t_next (trav);
  if ((i == n - 1 && next != NULL)
      || (i != n - 1 && (next == NULL || *next != i + 1))) @
    {@-
      printf ("   %s traverser behind %d, but should be behind %d.\n",
	      label, next != NULL ? *next : -1, i == n - 1 ? -1 : i + 1);
      okay = 0;
    }@+
  bst_t_prev (trav);

  return okay;
}

@

We also need to test deleting nodes from the tree and making copies of a
tree.  Here's the code to do that:

@<Test deleting nodes from the BST and making copies of it@> =
@iftangle
/* Test deleting nodes from the tree and making copies of it. */
@end iftangle
for (i = 0; i < n; i++) @
  {@-
    int *deleted;

    if (verbosity >= 2) @
      printf ("  Deleting %d...\n", delete[i]);

    deleted = bst_delete (tree, &delete[i]);
    if (deleted == NULL || *deleted != delete[i]) @
      {@-
        okay = 0;
        if (deleted == NULL)
          printf ("    Deletion failed.\n");
        else @
          printf ("    Wrong node %d returned.\n", *deleted);
      }@+

    if (verbosity >= 3) @
      print_whole_tree (tree, "    Afterward");

    if (!verify_tree (tree, delete + i + 1, n - i - 1))
      return 0;

    if (verbosity >= 2) @
      printf ("  Copying tree and comparing...\n");

    /* Copy the tree and make sure it's identical. */
    {
      struct bst_table *copy = bst_copy (tree, NULL, NULL, NULL);
      if (copy == NULL) @
        {@-
          if (verbosity >= 0) @
            printf ("  Out of memory in copy\n");
          bst_destroy (tree, NULL);
          return 1;
        }@+

      okay &= compare_trees (tree->bst_root, copy->bst_root);
      bst_destroy (copy, NULL);
    }
  }@+

@

The actual comparison of trees is done recursively for simplicity:

@<Compare two BSTs for structure and content@> =
/* Compares binary trees rooted at |a| and |b|, @
   making sure that they are identical. */
static int @
compare_trees (struct bst_node *a, struct bst_node *b) @
{
  int okay;

  if (a == NULL || b == NULL) @
    {@-
      assert (a == NULL && b == NULL);
      return 1;
    }@+

  if (*(int *) a->bst_data != *(int *) b->bst_data
      || ((a->bst_link[0] != NULL) != (b->bst_link[0] != NULL))
      || ((a->bst_link[1] != NULL) != (b->bst_link[1] != NULL))) @
    {@-
      printf (" Copied nodes differ: a=%d b=%d a:",
	      *(int *) a->bst_data, *(int *) b->bst_data);

      if (a->bst_link[0] != NULL) @
	printf ("l");
      if (a->bst_link[1] != NULL) @
	printf ("r");

      printf (" b:");
      if (b->bst_link[0] != NULL) @
	printf ("l");
      if (b->bst_link[1] != NULL) @
	printf ("r");

      printf ("\n");
      return 0;
    }@+

  okay = 1;
  if (a->bst_link[0] != NULL) @
    okay &= compare_trees (a->bst_link[0], b->bst_link[0]);
  if (a->bst_link[1] != NULL) @
    okay &= compare_trees (a->bst_link[1], b->bst_link[1]);
  return okay;
}

@

As a simple extra check, we make sure that attempting to delete from
an empty tree fails in the expected way:

@<Test deleting from an empty tree@> =
if (bst_delete (tree, &insert[0]) != NULL) @
  {@-
    printf (" Deletion from empty tree succeeded.\n");
    okay = 0;
  }@+

@

Finally, we're done with the tree and can get rid of it.

@<Test destroying the tree@> =
/* Test destroying the tree. */
bst_destroy (tree, NULL);
@

@exercise
Which functions in @(bst.c@> are not exercised by |test()|?

@answer
Functions not used at all are |bst_insert()|, |bst_replace()|,
|bst_t_replace()|, |bst_malloc()|, and |bst_free()|.

Functions used explicitly within |test()| or functions that it calls are
|bst_create()|, |bst_find()|, |bst_probe()|, |bst_delete()|,
|bst_t_init()|, |bst_t_first()|, |bst_t_last()|, 
|bst_t_insert()|, |bst_t_find()|, |bst_t_copy()|, |bst_t_next()|, |bst_t_prev()|,
|bst_t_cur()|, |bst_copy()|, and |bst_destroy()|.

The |trav_refresh()| function is called indirectly by modifying the tree
during traversal.

The |copy_error_recovery()| function is called if a memory allocation
error occurs during |bst_copy()|.  The |bst_balance()| function, and
therefore also |tree_to_vine()|, |vine_to_tree()|, and |compress()|, are
called if a stack overflow occurs. It is possible to force both these
behaviors with command-line options to the test program.
@end exercise

@exercise
Some errors within |test()| just set the |okay| flag to zero, whereas
others cause an immediate unsuccessful return to the caller without
performing any cleanup.  A third class of errors causes cleanup followed
by a successful return.  Why and how are these distinguished?

@answer
Some kinds of errors mean that we can keep going and test other parts
of the code.  Other kinds of errors mean that something is deeply
wrong, and returning without cleanup is the safest action short of
terminating the program entirely.  The third category is memory
allocation errors.  In our test program these are always caused
intentionally in order to test out the BST functions' error recovery
abilities, so a memory allocation error is not really an error at all,
and we clean up and return successfully.  (A real memory allocation
error will cause the program to abort in the memory allocator.  See
the definition of |mt_allocate()| within @<Memory tracker@>.)
@end exercise

@menu
* BST Verification::            
* Displaying BST Structures::   
@end menu

@node BST Verification, Displaying BST Structures, Testing BSTs, Testing BSTs
@subsubsection BST Verification

After each change to the tree in the testing program, we call
|verify_tree()| to check that the tree's structure and content are what
we think they should be.  This function runs through a full gamut of
checks, with the following outline:

@<BST verify function@> =
/* Checks that |tree| is well-formed
   and verifies that the values in |array[]| are actually in |tree|.  
   There must be |n| elements in |array[]| and |tree|.
   Returns nonzero only if no errors detected. */
static int @
verify_tree (struct bst_table *tree, int array[], size_t n) @
{
  int okay = 1;

  @<Check |tree->bst_count| is correct@>

  if (okay) @
    { @
      @<Check BST structure@> @
    }

  if (okay) @
    { @
      @<Check that the tree contains all the elements it should@> @
    }

  if (okay) @
    { @
      @<Check that forward traversal works@> @
    }

  if (okay) @
    { @
      @<Check that backward traversal works@> @
    }

  if (okay) @
    { @
      @<Check that traversal from the null element works@> @
    }

  return okay;
}

@

The first step just checks that the number of items passed in as |n| is
the same as @w{|tree->bst_count|}.

@<Check |tree->bst_count| is correct@> =
/* Check |tree|'s bst_count against that supplied. */
if (bst_count (tree) != n) @
  {@-
    printf (" Tree count is %lu, but should be %lu.\n",
            (unsigned long) bst_count (tree), (unsigned long) n);
    okay = 0;
  }@+
@

Next, we verify that the BST has proper structure and that it has the
proper number of items.  We'll do this recursively because that's
easiest and most obviously correct way.  Function
|recurse_verify_tree()| for this returns the number of nodes in the BST.
After it returns, we verify that this is the expected number.

@<Check BST structure@> =
/* Recursively verify tree structure. */
size_t count;

recurse_verify_tree (tree->bst_root, &okay, &count, 0, INT_MAX);
@<Check counted nodes@>
@

@<Check counted nodes@> =
if (count != n) @
  {@-
    printf (" Tree has %lu nodes, but should have %lu.\n", 
            (unsigned long) count, (unsigned long) n);
    okay = 0;
  }@+
@

The function |recurse_verify_tree()| does the recursive verification.
It checks that nodes' values increase down to the right and decrease
down to the left.  We also use it to count the number of nodes actually
in the tree:

@<Recursively verify BST structure@> =
/* Examines the binary tree rooted at |node|.  
   Zeroes |*okay| if an error occurs.  @
   Otherwise, does not modify |*okay|.
   Sets |*count| to the number of nodes in that tree, @
   including |node| itself if |node != NULL|.
   All the nodes in the tree are verified to be at least |min| @
   but no greater than |max|. */
static void @
recurse_verify_tree (struct bst_node *node, int *okay, size_t *count, 
                     int min, int max) @
{
  int d;                /* Value of this node's data. */
  size_t subcount[2];   /* Number of nodes in subtrees. */

  if (node == NULL) @
    {@-
      *count = 0;
      return;
    }@+
  d = *(int *) node->bst_data;

  @<Verify binary search tree ordering@>

  recurse_verify_tree (node->bst_link[0], okay, &subcount[0], min, d - 1);
  recurse_verify_tree (node->bst_link[1], okay, &subcount[1], d + 1, max);
  *count = 1 + subcount[0] + subcount[1];
}

@

@<Verify binary search tree ordering@> =
if (min > max) @
  {@-
    printf (" Parents of node %d constrain it to empty range %d...%d.\n",
            d, min, max);
    *okay = 0;
  }@+ @
else if (d < min || d > max) @
  {@-
    printf (" Node %d is not in range %d...%d implied by its parents.\n",
            d, min, max);
    *okay = 0;
  }@+
@

The third step is to check that the BST indeed contains all of the items
that it should:

@<Check that the tree contains all the elements it should@> =
/* Check that all the values in |array[]| are in |tree|. */
size_t i;

for (i = 0; i < n; i++)
  if (bst_find (tree, &array[i]) == NULL) @
    {@-
      printf (" Tree does not contain expected value %d.\n", array[i]);
      okay = 0;
    }@+
@

The final steps all check traversal of the BST, first by traversing in
forward order from the beginning to the end, then in reverse order, then
by checking that the null item behaves correctly.  The forward traversal
checks that the proper number of items are in the BST.  It could appear
to have too few items if the tree's pointers are screwed up in one way,
or it could appear to have too many items if they are screwed up in
another way.  We try to figure out how many items actually appear in the
tree during traversal, but give up if the count gets to be more than
twice that expected, assuming that this indicates a ``loop'' that will
cause traversal to never terminate.

@<Check that forward traversal works@> =
/* Check that |bst_t_first()| and |bst_t_next()| work properly. */
struct bst_traverser trav;
size_t i;
int prev = -1;
int *item;

for (i = 0, item = bst_t_first (&trav, tree); i < 2 * n && item != NULL;
     i++, item = bst_t_next (&trav)) @
  {@-
    if (*item <= prev) @
      {@-
        printf (" Tree out of order: %d follows %d in traversal\n", @
                *item, prev);
        okay = 0;
      }@+

    prev = *item;
  }@+

if (i != n) @
  {@-
    printf (" Tree should have %lu items, but has %lu in traversal\n",
            (unsigned long) n, (unsigned long) i);
    okay = 0;
  }@+
@

We do a similar traversal in the reverse order:

@<Check that backward traversal works@> =
/* Check that |bst_t_last()| and |bst_t_prev()| work properly. */
struct bst_traverser trav;
size_t i;
int next = INT_MAX;
int *item;

for (i = 0, item = bst_t_last (&trav, tree); i < 2 * n && item != NULL;
     i++, item = bst_t_prev (&trav)) @
  {@-
    if (*item >= next) @
      {@-
        printf (" Tree out of order: %d precedes %d in traversal\n", @
                *item, next);
        okay = 0;
      }@+

    next = *item;
  }@+

if (i != n) @
  {@-
    printf (" Tree should have %lu items, but has %lu in reverse\n",
            (unsigned long) n, (unsigned long) i);
    okay = 0;
  }@+
@

The final check to perform on the traverser is to make sure that the
traverser null item works properly.  We start out a traverser at the
null item with |bst_t_init()|, then make sure that the next item after
that, as reported by |bst_t_next()|, is the same as the item returned by
|bst_t_init()|, and similarly for the previous item:

@<Check that traversal from the null element works@> =
/* Check that |bst_t_init()| works properly. */
struct bst_traverser init, first, last;
int *cur, *prev, *next;

bst_t_init (&init, tree);
bst_t_first (&first, tree);
bst_t_last (&last, tree);

cur = bst_t_cur (&init);
if (cur != NULL) @
  {@-
    printf (" Inited traverser should be null, but is actually %d.\n", @
            *cur);
    okay = 0;
  }@+

next = bst_t_next (&init);
if (next != bst_t_cur (&first)) @
  {@-
    printf (" Next after null should be %d, but is actually %d.\n",
            *(int *) bst_t_cur (&first), *next);
    okay = 0;
  }@+
bst_t_prev (&init);

prev = bst_t_prev (&init);
if (prev != bst_t_cur (&last)) @
  {@-
    printf (" Previous before null should be %d, but is actually %d.\n",
            *(int *) bst_t_cur (&last), *prev);
    okay = 0;
  }@+
bst_t_next (&init);
@

@exercise
Many of the segments of code in this section cast |size_t| arguments to
|printf()| to |unsigned long|.  Why?

@answer
The definition of |size_t| differs from one compiler to the next.  All
we know about it for sure is that it's an unsigned type appropriate for
representing the size of an object.  So we must convert it to some known
type in order to pass it to |printf()|, because |printf()|, having a
variable number of arguments, does not know what type to convert it
into.

Incidentally, C99 solves this problem by providing a @samp{z} modifier
for |printf()| conversions, so that we could use |"%zu"| to print out
|size_t| values without the need for a cast.

@references
@bibref{ISO 1999}, section 7.19.6.1.
@end exercise

@exercise
Does |test()| work properly for testing trees with only one item in
them?  Zero items?

@answer
Yes.
@end exercise

@node Displaying BST Structures,  , BST Verification, Testing BSTs
@subsubsection Displaying BST Structures

The |print_tree_structure()| function below can be useful for debugging,
but it is not used very much by the testing code.  It prints out the
structure of a tree, with the root first, then its children in
parentheses separated by a comma, and their children in inner
parentheses, and so on.  This format is easy to print but difficult to
visualize, so it's a good idea to have a notebook on hand to sketch out
the shape of the tree.  Alternatively, this output is in the right
format to feed directly into the @code{texitree} program used to draw
the tree diagrams in this book, which can produce output in plain text
or PostScript form.

@<BST print function@> =
/* Prints the structure of |node|, @
   which is |level| levels from the top of the tree. */
static void @
print_tree_structure (const struct bst_node *node, int level) @
{
  /* You can set the maximum level as high as you like.
     Most of the time, you'll want to debug code using small trees,
     so that a large |level| indicates a ``loop'', which is a bug. */
  if (level > 16) @
    {@-
      printf ("[...]");
      return;
    }@+

  if (node == NULL)
    return;

  printf ("%d", *(int *) node->bst_data);
  if (node->bst_link[0] != NULL || node->bst_link[1] != NULL) @
    {@-
      putchar ('(');

      print_tree_structure (node->bst_link[0], level + 1);
      if (node->bst_link[1] != NULL) @
	{@-
	  putchar (',');
	  print_tree_structure (node->bst_link[1], level + 1);
	}@+

      putchar (')');
    }@+
}

@

A function |print_whole_tree()| is also provided as a convenient wrapper
for printing an entire BST's structure.

@<BST print function@> +=
/* Prints the entire structure of |tree| with the given |title|. */
void @
print_whole_tree (const struct bst_table *tree, const char *title) @
{
  printf ("%s: ", title);
  print_tree_structure (tree->bst_root, 0);
  putchar ('\n');
}

@

@node Test Set Generation, Testing Overflow, Testing BSTs, Testing BST Functions
@subsection Test Set Generation

We need code to generate a random permutation of numbers to order
insertion and deletion of items.  We will support some other orders
besides random permutation as well for completeness and to allow for
overflow testing.  Here is the complete list:

@<Test declarations@> =
/* Insertion order. */
enum insert_order @
  {@-
    INS_RANDOM,			/* Random order. */
    INS_ASCENDING,		/* Ascending order. */
    INS_DESCENDING,		/* Descending order. */
    INS_BALANCED,		/* Balanced tree order. */
    INS_ZIGZAG,			/* Zig-zag order. */
    INS_ASCENDING_SHIFTED,      /* Ascending from middle, then beginning. */
    INS_CUSTOM,			/* Custom order. */

    INS_CNT                     /* Number of insertion orders. */
  };@+

/* Deletion order. */
enum delete_order @
  {@-
    DEL_RANDOM,			/* Random order. */
    DEL_REVERSE,		/* Reverse of insertion order. */
    DEL_SAME,			/* Same as insertion order. */
    DEL_CUSTOM,			/* Custom order. */

    DEL_CNT                     /* Number of deletion orders. */
  };@+

@

@noindent
The code to actually generate these orderings is left to the exercises.

@exercise
Write a function to generate a random permutation of the |n| |int|s
between |0| and |n - 1| into a provided array.

@answer
@<Generate random permutation of integers@> =
/* Fills the |n| elements of |array[]| with a random permutation of the
   integers between |0| and |n - 1|. */
static void @
permuted_integers (int array[], size_t n) @
{
  size_t i;
  
  for (i = 0; i < n; i++)
    array[i] = i;

  for (i = 0; i < n; i++) @
    {@-
      size_t j = i + (unsigned) rand () / (RAND_MAX / (n - i) + 1);
      int t = array[j];
      array[j] = array[i];
      array[i] = t;
    }@+
}

@
@end exercise

@exercise*
Write a function to generate an ordering of |int|s that, when inserted
into a binary tree, produces a balanced tree of the integers from |min| to
|max| inclusive.  (Hint: what kind of recursive traversal makes this
easy?)

@answer
All it takes is a preorder traversal.  If the code below is confusing,
try looking back at @<Initialize |smaller| and |larger| within binary
search tree@>.

@<Generate permutation for balanced tree@> =
/* Generates a list of integers that produce a balanced tree when
   inserted in order into a binary tree in the usual way.
   |min| and |max| inclusively bound the values to be inserted.
   Output is deposited starting at |*array|. */
static void @
gen_balanced_tree (int min, int max, int **array) @
{
  int i;
  
  if (min > max)
    return;

  i = (min + max + 1) / 2;
  *(*array)++ = i;
  gen_balanced_tree (min, i - 1, array);
  gen_balanced_tree (i + 1, max, array);
}

@
@end exercise

@exercise
Write one function to generate an insertion order of |n| integers into a
provided array based on an |enum insert_order| and the functions written
in the previous two exercises.  Write a second function to generate a
deletion order using similar parameters plus the order of insertion.

@answer
@<Insertion and deletion order generation@> =
@<Generate random permutation of integers@>
@<Generate permutation for balanced tree@>

/* Generates a permutation of the integers |0| to |n - 1| into
   |insert[]| according to |insert_order|. */
static void @
gen_insertions (size_t n, enum insert_order insert_order, int insert[]) @
{
  size_t i;

  switch (insert_order) @
    {
    case INS_RANDOM:
      permuted_integers (insert, n);
      break;

    case INS_ASCENDING:
      for (i = 0; i < n; i++)
	insert[i] = i;
      break;

    case INS_DESCENDING:
      for (i = 0; i < n; i++)
	insert[i] = n - i - 1;
      break;

    case INS_BALANCED:
      gen_balanced_tree (0, n - 1, &insert);
      break;

    case INS_ZIGZAG:
      for (i = 0; i < n; i++)
	if (i % 2 == 0) @
	  insert[i] = i / 2;
	else @
	  insert[i] = n - i / 2 - 1;
      break;

    case INS_ASCENDING_SHIFTED:
      for (i = 0; i < n; i++) @
        {@-
           insert[i] = i + n / 2;
           if ((size_t) insert[i] >= n)
             insert[i] -= n;
        }@+
      break;

    case INS_CUSTOM:
      for (i = 0; i < n; i++)
	if (scanf ("%d", &insert[i]) == 0)
	  fail ("error reading insertion order from stdin");
      break;
      
    default:
      assert (0);
    }
}

/* Generates a permutation of the integers |0| to |n - 1| into
   |delete[]| according to |delete_order| and |insert[]|. */
static void @
gen_deletions (size_t n, enum delete_order delete_order,
	       const int *insert, int *delete) @
{
  size_t i;
  
  switch (delete_order) @
    {
    case DEL_RANDOM:
      permuted_integers (delete, n);
      break;

    case DEL_REVERSE:
      for (i = 0; i < n; i++)
	delete[i] = insert[n - i - 1];
      break;

    case DEL_SAME:
      for (i = 0; i < n; i++)
	delete[i] = insert[i];
      break;

    case DEL_CUSTOM:
      for (i = 0; i < n; i++)
	if (scanf ("%d", &delete[i]) == 0)
	  fail ("error reading deletion order from stdin");
      break;

    default:
      assert (0);
    }
}

@
@end exercise

@exercise*
By default, the C random number generator produces the same sequence
every time the program is run.  In order to generate different
sequences, it has to be ``seeded'' using |srand()| with a unique value.
Write a function to select a random number seed based on the current
time.

@answer
The function below is carefully designed.  It uses |time()| to obtain
the current time.  The alternative |clock()| is a poor choice because
it measures CPU time used, which is often more or less constant among
runs.  The actual value of a |time_t| is not portable, so it computes
a ``hash'' of the bytes in it using a multiply-and-add technique.  The
factor used for multiplication normally comes out as 257, a prime and
therefore a good candidate.

@references
@bibref{Knuth 1998a}, section 3.2.1;
@bibref{Aho 1986}, section 7.6.

@<Random number seeding@> =
/* Choose and return an initial random seed based on the current time.
   Based on code by Lawrence Kirby <fred@@genesis.demon.co.uk>. */
unsigned @
time_seed (void) @
{
  time_t timeval;	/* Current time. */
  unsigned char *ptr;	/* Type punned pointed into timeval. */
  unsigned seed;	/* Generated seed. */
  size_t i;

  timeval = time (NULL);
  ptr = (unsigned char *) &timeval;

  seed = 0;
  for (i = 0; i < sizeof timeval; i++)
    seed = seed * (UCHAR_MAX + 2u) + ptr[i];

  return seed;
}

@
@end exercise

@node Testing Overflow, Memory Manager, Test Set Generation, Testing BST Functions
@subsection Testing Overflow

Testing for overflow requires an entirely different set of test
functions.  The idea is to create a too-tall tree using one of the
pathological insertion orders (ascending, descending, zig-zag,
shifted ascending), then try out each of the functions that can
overflow on it and make sure that they behave as they should.

There is a separate test function for each function that can overflow a
stack but which is not tested by |test()|.  These functions are called
by driver function |test_overflow()|, which also takes care of creating,
populating, and destroying the tree.

@<BST overflow test function@> =
@<Overflow testers@>

/* Tests the tree routines for proper handling of overflows.
   Inserting the |n| elements of |order[]| should produce a tree
   with height greater than |BST_MAX_HEIGHT|.
   Uses |allocator| as the allocator for tree and node data.
   Use |verbosity| to set the level of chatter on |stdout|. */
int @
test_overflow (struct libavl_allocator *allocator, @
               int order[], int n, int verbosity) @
{
  /* An overflow tester function. */
  typedef int test_func (struct bst_table *, int n);

  /* An overflow tester. */
  struct test @
    {@-
      test_func *func;                  /* Tester function. */
      const char *name;                 /* Test name. */
    };@+

  /* All the overflow testers. */
  static const struct test test[] = @
    {@-
      {test_bst_t_first, "first item"},
      {test_bst_t_last, "last item"},
      {test_bst_t_find, "find item"},
      {test_bst_t_insert, "insert item"},
      {test_bst_t_next, "next item"},
      {test_bst_t_prev, "previous item"},
      {test_bst_copy, "copy tree"},
    };@+

  const struct test *i;                 /* Iterator. */

  /* Run all the overflow testers. */
  for (i = test; i < test + sizeof test / sizeof *test; i++) @
    {@-
      struct bst_table *tree;
      int j;

      if (verbosity >= 2) @
	printf ("  Running %s test...\n", i->name);

      tree = bst_create (compare_ints, NULL, allocator);
      if (tree == NULL) @
        {@-
          printf ("    Out of memory creating tree.\n");
          return 1;
        }@+

      for (j = 0; j < n; j++) @
        {@-
          void **p = bst_probe (tree, &order[j]);
          if (p == NULL || *p != &order[j]) @
            {@-
              if (p == NULL && verbosity >= 0)
                printf ("    Out of memory in insertion.\n");
              else if (p != NULL) @
                printf ("    Duplicate item in tree!\n");              
              bst_destroy (tree, NULL);
              return p == NULL;
            }@+
        }@+
          
      if (i->func (tree, n) == 0)
	return 0;

      if (verify_tree (tree, order, n) == 0)
	return 0;
      bst_destroy (tree, NULL);
    }@+

  return 1;
}
@

@<Test prototypes@> +=
int test_overflow (struct libavl_allocator *, int order[], int n, @
                   int verbosity);
@

There is an overflow tester for almost every function that can overflow.
Here is one example:

@<Overflow testers@> =
static int @
test_bst_t_first (struct bst_table *tree, int n) @
{
  struct bst_traverser trav;
  int *first;

  first = bst_t_first (&trav, tree);
  if (first == NULL || *first != 0) @
    {@-
      printf ("    First item test failed: expected 0, got %d\n",
	      first != NULL ? *first : -1);
      return 0;
    }@+

  return 1;
}

@

@exercise
Write the rest of the overflow tester functions.  (The |test_overflow()|
function lists all of them.)

@answer
@<Overflow testers@> +=
static int @
test_bst_t_last (struct bst_table *tree, int n) @
{
  struct bst_traverser trav;
  int *last;

  last = bst_t_last (&trav, tree);
  if (last == NULL || *last != n - 1) @
    {@-
      printf ("    Last item test failed: expected %d, got %d\n",
	      n - 1, last != NULL ? *last : -1);
      return 0;
    }@+

  return 1;
}

static int @
test_bst_t_find (struct bst_table *tree, int n) @
{
  int i;

  for (i = 0; i < n; i++) @
    {@-
      struct bst_traverser trav;
      int *iter;

      iter = bst_t_find (&trav, tree, &i);
      if (iter == NULL || *iter != i) @
	{@-
	  printf ("    Find item test failed: looked for %d, got %d\n",
		  i, iter != NULL ? *iter : -1);
	  return 0;
	}@+
    }@+

  return 1;
}

static int @
test_bst_t_insert (struct bst_table *tree, int n) @
{
  int i;

  for (i = 0; i < n; i++) @
    {@-
      struct bst_traverser trav;
      int *iter;

      iter = bst_t_insert (&trav, tree, &i);
      if (iter == NULL || iter == &i || *iter != i) @
	{@-
	  printf ("    Insert item test failed: inserted dup %d, got %d\n",
		  i, iter != NULL ? *iter : -1);
	  return 0;
	}@+
    }@+

  return 1;
}

static int @
test_bst_t_next (struct bst_table *tree, int n) @
{
  struct bst_traverser trav;
  int i;

  bst_t_init (&trav, tree);
  for (i = 0; i < n; i++) @
    {@-
      int *iter = bst_t_next (&trav);
      if (iter == NULL || *iter != i) @
	{@-
	  printf ("    Next item test failed: expected %d, got %d\n",
		  i, iter != NULL ? *iter : -1);
	  return 0;
	}@+
    }@+

  return 1;
}

static int @
test_bst_t_prev (struct bst_table *tree, int n) @
{
  struct bst_traverser trav;
  int i;

  bst_t_init (&trav, tree);
  for (i = n - 1; i >= 0; i--) @
    {@-
      int *iter = bst_t_prev (&trav);
      if (iter == NULL || *iter != i) @
	{@-
	  printf ("    Previous item test failed: expected %d, got %d\n",
		  i, iter != NULL ? *iter : -1);
	  return 0;
	}@+
    }@+

  return 1;
}

static int @
test_bst_copy (struct bst_table *tree, int n) @
{
  struct bst_table *copy = bst_copy (tree, NULL, NULL, NULL);
  int okay = compare_trees (tree->bst_root, copy->bst_root);

  bst_destroy (copy, NULL);

  return okay;
}
@
@end exercise

@node Memory Manager, User Interaction, Testing Overflow, Testing BST Functions
@subsection Memory Manager

We want to test our code to make sure that it always releases allocated
memory and that it behaves robustly when memory allocations fail.  We
can do the former by building our own memory manager that keeps tracks
of blocks as they are allocated and freed.  The memory manager can also
disallow allocations according to a policy set by the user, taking care
of the latter.  

The available policies are:

@<Test declarations@> +=
/* Memory tracking policy. */
enum mt_policy @
  {@-
    MT_TRACK,			/* Track allocation for leak detection. */
    MT_NO_TRACK,		/* No leak detection. */
    MT_FAIL_COUNT,      	/* Fail allocations after a while. */
    MT_FAIL_PERCENT,		/* Fail allocations randomly. */
    MT_SUBALLOC                 /* Suballocate from larger blocks. */
  };@+

@

@noindent
|MT_TRACK| and |MT_NO_TRACK| should be self-explanatory.
|MT_FAIL_COUNT| takes an argument specifying after how many allocations
further allocations should always fail.  |MT_FAIL_PERCENT| takes an
argument specifying an integer percentage of allocations to randomly
fail.  

|MT_SUBALLOC| causes small blocks to be carved out of larger ones
allocated with |malloc()|.  This is a good idea for two reasons:
|malloc()| can be slow and |malloc()| can waste a lot of space dealing
with the small blocks that @libavl{} uses for its node.  Suballocation
cannot be implemented in an entirely portable way because of alignment
issues, but the test program here requires the user to specify the
alignment needed, and its use is optional anyhow.

The memory manager keeps track of allocated blocks using |struct block|:

@<Memory tracker@> =
/* Memory tracking allocator. */

/* A memory block. */
struct block @
  {@-
    struct block *next;                 /* Next in linked list. */

    int idx;                            /* Allocation order index number. */
    size_t size;                        /* Size in bytes. */
    size_t used;                        /* MT_SUBALLOC: amount used so far. */
    void *content;                      /* Allocated region. */
  };@+

@

@noindent
The |next| member of |struct block| is used to keep a linked list of all
the currently allocated blocks.  Searching this list is inefficient, but
there are at least two reasons to do it this way, instead of using a
more efficient data structure, such as a binary tree.  First, this code
is for testing binary tree routines---using a binary tree data structure
to do it is a strange idea!  Second, the ISO C standard says that, with
few exceptions, using the relational operators (|<|, |<=|, |>|, |>=|) to
compare pointers that do not point inside the same array produces
undefined behavior, but allows use of the equality operators (|==|, |!=|)
for a larger class of pointers.

We also need a data structure to keep track of settings and a list of
blocks.  This memory manager uses the technique discussed in
@value{moreargs} to provide this structure to the allocator.

@<Memory tracker@> +=
/* Indexes into |arg[]| within |struct mt_allocator|. */
enum mt_arg_index @
  {@-
    MT_COUNT = 0,      /* |MT_FAIL_COUNT|: Remaining successful allocations. */
    MT_PERCENT = 0,    /* |MT_FAIL_PERCENT|: Failure percentage. */
    MT_BLOCK_SIZE = 0, /* |MT_SUBALLOC|: Size of block to suballocate. */
    MT_ALIGN = 1       /* |MT_SUBALLOC|: Alignment of suballocated blocks. */
  }@+;

/* Memory tracking allocator. */
struct mt_allocator @
  {@-
    struct libavl_allocator allocator;  /* Allocator.  Must be first member. */

    /* Settings. */
    enum mt_policy policy;              /* Allocation policy. */
    int arg[2];                         /* Policy arguments. */
    int verbosity;                      /* Message verbosity level. */

    /* Current state. */
    struct block *head, *tail;          /* Head and tail of block list. */
    int alloc_idx;                      /* Number of allocations so far. */
    int block_cnt;                      /* Number of still-allocated blocks. */
  };@+

@

Function |mt_create()| creates a new instance of the memory tracker.  It
takes an allocation policy and policy argument, as well as a number
specifying how verbose it should be in reporting information.  It uses
utility function |xmalloc()|, a simple wrapper for |malloc()| that
aborts the program on failure.  Here it is:

@<Memory tracker@> +=
static void *mt_allocate (struct libavl_allocator *, size_t);
static void mt_free (struct libavl_allocator *, void *);

/* Initializes the memory manager for use 
   with allocation policy |policy| and policy arguments |arg[]|,
   at verbosity level |verbosity|, where 0 is a ``normal'' value. */
struct mt_allocator *@
mt_create (enum mt_policy policy, int arg[2], int verbosity) @
{
  struct mt_allocator *mt = xmalloc (sizeof *mt);

  mt->allocator.libavl_malloc = mt_allocate;
  mt->allocator.libavl_free = mt_free;

  mt->policy = policy;
  mt->arg[0] = arg[0];
  mt->arg[1] = arg[1];
  mt->verbosity = verbosity;

  mt->head = mt->tail = NULL;
  mt->alloc_idx = 0;
  mt->block_cnt = 0;

  return mt;
}

@

After allocations and deallocations are done, the memory manager must be
freed with |mt_destroy()|, which also reports any memory leaks.  Blocks
are removed from the block list as they are freed, so any remaining
blocks must be leaked memory:

@<Memory tracker@> +=
/* Frees and destroys memory tracker |mt|, @
   reporting any memory leaks. */
void @
mt_destroy (struct mt_allocator *mt) @
{
  assert (mt != NULL);

  if (mt->block_cnt == 0) @
    {@-
      if (mt->policy != MT_NO_TRACK && mt->verbosity >= 1)
	printf ("  No memory leaks.\n");
    }@+ @
  else @
    {@-
      struct block *iter, *next;

      if (mt->policy != MT_SUBALLOC) @
        printf ("  Memory leaks detected:\n");
      for (iter = mt->head; iter != NULL; iter = next) @
        {@-
          if (mt->policy != MT_SUBALLOC) 
            printf ("    block #%d: %lu bytes\n",
                    iter->idx, (unsigned long) iter->size);

          next = iter->next;
          free (iter->content);
          free (iter);
        }@+
    }@+

  free (mt);
}

@

For the sake of good encapsulation, |mt_allocator()| returns the |struct
libavl_allocator| associated with a given memory tracker:

@<Memory tracker@> +=
/* Returns the |struct libavl_allocator| associated with |mt|. */
void *@
mt_allocator (struct mt_allocator *mt) @
{
  return &mt->allocator;
}

@

The allocator function |mt_allocate()| is in charge of implementing the
selected allocation policy.  It delegates most of the work to a pair of
helper functions |new_block()| and |reject_request()| and makes use of
utility function |xmalloc()|, a simple wrapper for |malloc()| that
aborts the program on failure.  The implementation is straightforward:

@<Memory tracker@> +=
/* Creates a new |struct block| containing |size| bytes of content
   and returns a pointer to content. */
static void *@
new_block (struct mt_allocator *mt, size_t size) @
{
  struct block *new;

  /* Allocate and initialize new |struct block|. */
  new = xmalloc (sizeof *new);
  new->next = NULL;
  new->idx = mt->alloc_idx++;
  new->size = size;
  new->used = 0;
  new->content = xmalloc (size);

  /* Add block to linked list. */
  if (mt->head == NULL)
    mt->head = new;
  else @
    mt->tail->next = new;
  mt->tail = new;

  /* Alert user. */
  if (mt->verbosity >= 3) 
    printf ("    block #%d: allocated %lu bytes\n",
	    new->idx, (unsigned long) size);

  /* Finish up and return. */
  mt->block_cnt++;
  return new->content;
}

/* Prints a message about a rejected allocation if appropriate. */
static void @
reject_request (struct mt_allocator *mt, size_t size) @
{
  if (mt->verbosity >= 2)
    printf ("    block #%d: rejected request for %lu bytes\n",
	    mt->alloc_idx++, (unsigned long) size);
}

/* Allocates and returns a block of |size| bytes. */
static void *@
mt_allocate (struct libavl_allocator *allocator, size_t size) @
{
  struct mt_allocator *mt = (struct mt_allocator *) allocator;

  /* Special case. */  
  if (size == 0)
    return NULL;

  switch (mt->policy) @
    {
    case MT_TRACK: @
      return new_block (mt, size);
      
    case MT_NO_TRACK: @
      return xmalloc (size);

    case MT_FAIL_COUNT:
      if (mt->arg[MT_COUNT] == 0) @
	{@-
	  reject_request (mt, size);
	  return NULL;
	}@+
      mt->arg[MT_COUNT]--;
      return new_block (mt, size);

    case MT_FAIL_PERCENT:
      if (rand () / (RAND_MAX / 100 + 1) < mt->arg[MT_PERCENT]) @
	{@-
	  reject_request (mt, size);
	  return NULL;
	}@+
      else @
	return new_block (mt, size);

    case MT_SUBALLOC:
      if (mt->tail == NULL
          || mt->tail->used + size > (size_t) mt->arg[MT_BLOCK_SIZE])
        new_block (mt, mt->arg[MT_BLOCK_SIZE]);
      if (mt->tail->used + size <= (size_t) mt->arg[MT_BLOCK_SIZE]) @
	{@-
	  void *p = (char *) mt->tail->content + mt->tail->used;
	  size = ((size + mt->arg[MT_ALIGN] - 1)
                  / mt->arg[MT_ALIGN] * mt->arg[MT_ALIGN]);
	  mt->tail->used += size;
	  if (mt->verbosity >= 3)
	    printf ("    block #%d: suballocated %lu bytes\n",
		    mt->tail->idx, (unsigned long) size);
	  return p;
	}@+
      else @
	fail ("blocksize %lu too small for %lu-byte allocation",
	      (unsigned long) mt->tail->size, (unsigned long) size);

    default: @
      assert (0);
    }
}

@

The corresponding function |mt_free()| searches the block list for the
specified block, removes it, and frees the associated memory.  It
reports an error if the block is not in the list:

@<Memory tracker@> +=
/* Releases |block| previously returned by |mt_allocate()|. */
static void @
mt_free (struct libavl_allocator *allocator, void *block) @
{
  struct mt_allocator *mt = (struct mt_allocator *) allocator;
  struct block *iter, *prev;

  /* Special cases. */
  if (block == NULL || mt->policy == MT_NO_TRACK) @
    {@-
      free (block);
      return;
    }@+
  if (mt->policy == MT_SUBALLOC)
    return;

  /* Search for |block| within the list of allocated blocks. */
  for (prev = NULL, iter = mt->head; iter; prev = iter, iter = iter->next) @
    {@-
      if (iter->content == block) @
	{@-
          /* Block found.  Remove it from the list. */
	  struct block *next = iter->next;
	
	  if (prev == NULL)
	    mt->head = next;
	  else @
	    prev->next = next;
	  if (next == NULL) @
	    mt->tail = prev;

          /* Alert user. */
	  if (mt->verbosity >= 4)
	    printf ("    block #%d: freed %lu bytes\n",
		    iter->idx, (unsigned long) iter->size);

          /* Free block. */
	  free (iter->content);
	  free (iter);

          /* Finish up and return. */	  
	  mt->block_cnt--;
	  return;
	}@+
    }@+
  
  /* Block not in list. */
  printf ("    attempt to free unknown block %p (already freed?)\n", block);
}

@

@references
@bibref{ISO 1990}, sections 6.3.8 and 6.3.9.

@exercise
As its first action, |mt_allocate()| checks for and special-cases a
|size| of 0.  Why?

@answer
Attempting to apply an allocation policy to allocations of zero-byte
blocks is silly.  How could a failure be indicated, given that one of
the successful results for an allocation of 0 bytes is |NULL|?  At any
rate, @libavl{} never calls |bst_allocate()| with a |size| argument of
0.

@references
@bibref{ISO 1990}, section 7.10.3.
@end exercise

@node User Interaction, Utility Functions, Memory Manager, Testing BST Functions
@subsection User Interaction

This section briefly discusses @libavl{}'s data structures and functions
for parsing command-line arguments.  For more information on the
command-line arguments accepted by the testing program, refer to the
@libavl{} reference manual.

The main way that the test program receives instructions from the user
is through the set of arguments passed to |main()|.  The program assumes
that these arguments can be controlled easily by the user, presumably
through some kind of command-based ``shell'' program.  It allows for two
kinds of options: traditional UNIX ``short options'' that take the form
@samp{-o} and GNU-style ``long options'' of the form @samp{--option}.
Either kind of option may take an argument.

Options are specified using an array of |struct option|, terminated by
an all-zero structure:

@<Test declarations@> +=
/* A single command-line option. */
struct option @
  {@-
    const char *long_name;	/* Long name (|"--name"|). */
    int short_name;		/* Short name (|"-n"|); value returned. */
    int has_arg;		/* Has a required argument? */
  };@+
    
@

There are two public functions in the option parser:

@table @asis
@item |struct option_state *option_init (struct option *options, char **args)|
Creates and returns a |struct option_state|, initializing it based on
the array of arguments passed in.  This structure is used to keep track
of the option parsing state.  Sets |options| as the set of options to
parse.

@item |int option_get (struct option_state *state, char **argp)|
Parses the next option from |state| and returns the value of the
|short_name| member from its |struct option|.  Sets |*argp| to the
option's argument or |NULL| if none.  Returns |-1| and destroys |state|
if no options remain.
@end table

These functions' implementation are not too interesting for our
purposes, so they are relegated to an appendix.  @xref{Option Parser},
for the full story.

The option parser provides a lot of support for parsing the command
line, but of course the individual options have to be handled once
they are retrieved by |option_get()|.  The |parse_command_line()|
function takes care of the whole process:

@table @asis
@item |void parse_command_line (char **args, struct test_options *options)|
Parses the command-line arguments in |args[]|, which must be terminated
with an element set to all zeros, using |option_init()| and
|option_get()|.  Sets up |options| appropriately to correspond.
@end table

@xref{Command-Line Parser}, for source code.  The |struct test_options|
initialized by |parse_command_line()| is described in detail below.

@node Utility Functions, Main Program, User Interaction, Testing BST Functions
@subsection Utility Functions

The first utility function is |compare_ints()|.  This function is not
used by @(test.c@> but it is included there because it is used by the
test modules for all the individual tree structures.  

@<Test utility functions@> =
/* Utility functions. */

@<Comparison function for |int|s@>
@

It is prototyped in @(test.h@>:

@<Test prototypes@> +=
int compare_ints (const void *pa, const void *pb, void *param);
@

The |fail()| function prints a provided error message to |stderr|,
formatting it as with |printf()|, and terminates the program
unsuccessfully:

@<Test utility functions@> +=
/* Prints |message| on |stderr|, which is formatted as for |printf()|, 
   and terminates the program unsuccessfully. */
static void @
fail (const char *message, ...) @
{
  va_list args;

  fprintf (stderr, "%s: ", pgm_name);

  va_start (args, message);
  vfprintf (stderr, message, args);
  va_end (args);

  putchar ('\n');

  exit (EXIT_FAILURE);
}

@

Finally, the |xmalloc()| function is a |malloc()| wrapper that aborts
the program if allocation fails:

@<Test utility functions@> +=
/* Allocates and returns a pointer to |size| bytes of memory.
   Aborts if allocation fails. */
static void *@
xmalloc (size_t size) @
{
  void *block = malloc (size);
  if (block == NULL && size != 0)
    fail ("out of memory");
  return block;
}

@

@node Main Program,  , Utility Functions, Testing BST Functions
@subsection Main Program

Everything comes together in the main program.  The test itself
(default or overflow) is selected with |enum test|:

@<Test declarations@> +=
/* Test to perform. */
enum test @
  {@-
    TST_CORRECTNESS,		/* Default tests. */
    TST_OVERFLOW,		/* Stack overflow test. */
    TST_NULL                    /* No test, just overhead. */
  };@+

@

The program's entire behavior is controlled by |struct test_options|,
defined as follows:

@<Test declarations@> +=
/* Program options. */
struct test_options @
  {@-
    enum test test;                     /* Test to perform. */
    enum insert_order insert_order;     /* Insertion order. */
    enum delete_order delete_order;     /* Deletion order. */

    enum mt_policy alloc_policy;        /* Allocation policy. */
    int alloc_arg[2];                   /* Policy arguments. */
    int alloc_incr; /* Amount to increment |alloc_arg| each iteration. */

    int node_cnt;                       /* Number of nodes in tree. */
    int iter_cnt;                       /* Number of runs. */

    int seed_given;                     /* Seed provided on command line? */
    unsigned seed;                      /* Random number seed. */

    int verbosity;                      /* Verbosity level, 0=default. */
    int nonstop;                        /* Don't stop after one error? */
  };@+

@

The |main()| function for the test program is perhaps a bit long, but
simple.  It begins by parsing the command line and allocating memory,
then repeats a loop once for each repetition of the test.  Within the
loop, an insertion and a deletion order are selected, the memory tracker
is set up, and test function (either |test()| or |test_overflow()|) is
called.

@<Test main program@> =
int @
main (int argc, char *argv[]) @
{
  struct test_options opts;	/* Command-line options. */
  int *insert, *delete;		/* Insertion and deletion orders. */
  int success;                  /* Everything okay so far? */

  /* Initialize |pgm_name|, using |argv[0]| if sensible. */
  pgm_name = argv[0] != NULL && argv[0][0] != '\0' ? argv[0] : "bst-test";

  /* Parse command line into |options|. */
  parse_command_line (argv, &opts);

  if (opts.verbosity >= 0)
    fputs ("bst-test for GNU libavl 2.0.3; use --help to get help.\n", stdout);
  
  if (!opts.seed_given) @
    opts.seed = time_seed () % 32768u;

  insert = xmalloc (sizeof *insert * opts.node_cnt);
  delete = xmalloc (sizeof *delete * opts.node_cnt);

  /* Run the tests. */
  success = 1;
  while (opts.iter_cnt--) @
    {@-
      struct mt_allocator *alloc;

      if (opts.verbosity >= 0) @
	{@-
	  printf ("Testing seed=%u", opts.seed);
	  if (opts.alloc_incr) @
	    printf (", alloc arg=%d", opts.alloc_arg[0]);
	  printf ("...\n");
	  fflush (stdout);
	}@+

      /* Generate insertion and deletion order.
         Seed them separately to ensure deletion order is
         independent of insertion order. */
      srand (opts.seed);
      gen_insertions (opts.node_cnt, opts.insert_order, insert);

      srand (++opts.seed);
      gen_deletions (opts.node_cnt, opts.delete_order, insert, delete);

      if (opts.verbosity >= 1) @
	{@-
	  int i;
	  
	  printf ("  Insertion order:");
	  for (i = 0; i < opts.node_cnt; i++)
	    printf (" %d", insert[i]);
	  printf (".\n");

	  if (opts.test == TST_CORRECTNESS) @
	    {@-
	      printf ("Deletion order:");
	      for (i = 0; i < opts.node_cnt; i++)
		printf (" %d", delete[i]);
	      printf (".\n");
	    }@+
	}@+

      alloc = mt_create (opts.alloc_policy, opts.alloc_arg, opts.verbosity);
      
      {
	int okay;
        struct libavl_allocator *a = mt_allocator (alloc);

	switch (opts.test) @
	  {
	  case TST_CORRECTNESS:
	    okay = test_correctness (a, insert, delete, opts.node_cnt, @
				     opts.verbosity);
	    break;

	  case TST_OVERFLOW:
	    okay = test_overflow (a, insert, opts.node_cnt, opts.verbosity);
	    break;

	  case TST_NULL: @
	    okay = 1; @
	    break;

	  default: @
	    assert (0);
	  }

	if (okay) @
	  {@-
	    if (opts.verbosity >= 1)
	      printf ("  No errors.\n");
	  }@+ @
	else @
	  {@-
	    success = 0;
	    printf ("  Error!\n");
	  }@+
      }

      mt_destroy (alloc);
      opts.alloc_arg[0] += opts.alloc_incr;
      
      if (!success && !opts.nonstop)
	break;
    }@+

  free (delete);
  free (insert);

  return success ? EXIT_SUCCESS : EXIT_FAILURE;
}
@

The main program initializes our single global variable, |pgm_name|,
which receives the name of the program at start of execution:

@<Test declarations@> +=
/* Program name. */
char *pgm_name;

@

@node Additional Exercises for BSTs,  , Testing BST Functions, Binary Search Trees
@section Additional Exercises

@exercise bstsentinel
Sentinels were a main theme of the chapter before this one.  Figure
out how to apply sentinel techniques to binary search trees.  Write
routines for search and insertion in such a binary search tree with
sentinel.  Test your functions.  (You need not make your code fully
generic; e.g., it is acceptable to ``hard-code'' the data type stored
in the tree.)

@answer
We'll use |bsts_|, short for ``binary search tree with sentinel'', as
the prefix for these functions.  First, we need node and tree
structures:

@c tested 2001/6/27
@<BSTS structures@> =
/* Node for binary search tree with sentinel. */
struct bsts_node @
  {@-
    struct bsts_node *link[2];
    int data;
  };@+

/* Binary search tree with sentinel. */
struct bsts_tree @
  {@-
    struct bsts_node *root;
    struct bsts_node sentinel;
    struct libavl_allocator *alloc;
  };@+

@

Searching is simple:

@c tested 2001/6/27
@<BSTS functions@> =
/* Returns nonzero only if |item| is in |tree|. */
int @
bsts_find (struct bsts_tree *tree, int item) @
{
  const struct bsts_node *node;

  tree->sentinel.data = item;
  node = tree->root;
  while (item != node->data)
    if (item < node->data) @
      node = node->link[0];
    else @
      node = node->link[1];
  return node != &tree->sentinel;
}

@

Insertion is just a little more complex, because we have to keep track
of the link that we just came from (alternately, we could divide the
function into multiple cases):

@c tested 2001/6/27
@<BSTS functions@> +=
/* Inserts |item| into |tree|, if it is not already present. */
void @
bsts_insert (struct bsts_tree *tree, int item) @
{
  struct bsts_node **q = &tree->root;
  struct bsts_node *p = tree->root;

  tree->sentinel.data = item;
  while (item != p->data) @
    {@-
      int dir = item > p->data;
      q = &p->link[dir];
      p = p->link[dir];
    }@+

  if (p == &tree->sentinel) @
    {@-
      *q = tree->alloc->libavl_malloc (tree->alloc, sizeof **q);
      if (*q == NULL) @
        {@-
          fprintf (stderr, "out of memory\n");
          exit (EXIT_FAILURE);
        }@+
      (*q)->link[0] = (*q)->link[1] = &tree->sentinel;
      (*q)->data = item;
    }@+
}

@

Our test function will just insert a collection of integers, then make
sure that all of them are in the resulting tree.  This is not as
thorough as it could be, and it doesn't bother to free what it
allocates, but it is good enough for now:

@c tested 2001/6/27
@<BSTS test@> =
/* Tests BSTS functions.  
   |insert| and |delete| must contain some permutation of values
   |0|@dots{}|n - 1|. */
int @
test_correctness (struct libavl_allocator *alloc, int *insert, 
                  int *delete, int n, int verbosity) @
{
  struct bsts_tree tree;
  int okay = 1;
  int i;

  tree.root = &tree.sentinel;
  tree.alloc = alloc;

  for (i = 0; i < n; i++)
    bsts_insert (&tree, insert[i]);

  for (i = 0; i < n; i++)
    if (!bsts_find (&tree, i)) @
      {@-
        printf ("%d should be in tree, but isn't\n", i);
        okay = 0;
      }@+

  return okay;
}

/* Not supported. */
int @
test_overflow (struct libavl_allocator *alloc, int order[], int n, @
               int verbosity) @
{
  return 0;
}
@

Function |test()| doesn't free allocated nodes, resulting in a memory
leak.  You should fix this if you are concerned about it.

Here's the whole program:

@c tested 2001/6/27
@(bsts.c@> = 
@<Library License@>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "test.h"

@<BSTS structures@>
@<Memory allocator; tbl => bsts@>
@<Default memory allocator header; tbl => bsts@>
@<Default memory allocation functions; tbl => bsts@>
@<BSTS functions@>
@<BSTS test@>
@

@references
@bibref{Bentley 2000}, exercise 7 in chapter 13.
@end exercise
