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

@deftypedef rb_comparison_func
@deftypedef rb_item_func
@deftypedef rb_copy_func

@node Red-Black Trees, Threaded Binary Search Trees, AVL Trees, Top
@chapter Red-Black Trees

The last chapter saw us implementing a library for one particular type
of balanced trees.  Red-black trees were invented by R.@: Bayer and
studied at length by L.@: J.@: Guibas and R.@: Sedgewick.  This
chapter will implement a library for another kind of balanced tree,
called a @gloss{red-black tree}.  For brevity, we'll often abbreviate
``red-black'' to RB.

Insertion and deletion operations on red-black trees are more complex
to describe or to code than the same operations on AVL trees.
Red-black trees also have a higher maximum height than AVL trees for a
given number of nodes.  The primary advantage of red-black trees is
that, in AVL trees, deleting one node from a tree containing |n| nodes
may require @altmath{\log_2n, |log2 (n)|} rotations, but deletion in a
red-black tree never requires more than three rotations.

The functions for RB trees in this chapter are analogous to those that
we developed for use with AVL trees in the previous chapter.  Here's an
outline of the red-black code:

@(rb.h@> =
@<Library License@>
#ifndef RB_H
#define RB_H 1

#include <stddef.h>

@<Table types; tbl => rb@>
@<RB maximum height@>
@<BST table structure; bst => rb@>
@<RB node structure@>
@<BST traverser structure; bst => rb@>
@<Table function prototypes; tbl => rb@>

#endif /* rb.h */
@

@(rb.c@> =
@<Library License@>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "rb.h"

@<RB functions@>
@

@references
@bibref{Cormen 1990}, chapter 14, ``Chapter notes.''

@menu
* RB Balancing Rule::           
* RB Data Types::               
* Operations in an RB Tree::    
* Inserting into an RB Tree::   
* Deleting from an RB Tree::    
* Testing RB Trees::            
@end menu

@node RB Balancing Rule, RB Data Types, Red-Black Trees, Red-Black Trees
@section Balancing Rule

To most clearly express the red-black balancing rule, we need a few
new vocabulary terms.  First, define a @dfn{non-branching node} as a
node that does not ``branch'' the binary tree in different directions,
i.e., a node with exactly zero or one children.

Second, a @dfn{path} is a list of one or more nodes in a binary tree
where every node in the list (except the last node, of course) is
@gloss{adjacent} in the tree to the one after it.  Two nodes in a tree
are considered to be adjacent for this purpose if one is the child of
the other.  Furthermore, a @dfn{simple path} is a path that does not
contain any given node more than once.

Finally, a node |p| is a @dfn{descendant} of a second node |q| if both
|p| and |q| are the same node, or if |p| is located in one of the
subtrees of |q|.

With these definitions in mind, a red-black tree is a binary search
tree in which every node has been labeled with a @gloss{color}, either
``red'' or ``black'', with those colors distributed according to these
two simple rules, which are called the ``red-black balancing rules''
and often referenced by number:

@enumerate
@item
No red node has a red child.

@item
Every simple path from a given node to one of its non-branching node
descendants contains the same number of black nodes.
@end enumerate

Any binary search tree that conforms to these rules is a red-black tree.
Additionally, all red-black trees in @libavl{} share a simple additional
property: their roots are black.  This property is not essential, but it
does slightly simplify insertion and deletion operations.

To aid in digestion of all these definitions, here are some red-black
trees that might be produced by @libavl{}:

@center @image{rbex}

@noindent
@ifnotinfo
In this book, black nodes are colored black and red nodes are colored
gray, as shown here.
@end ifnotinfo
@ifinfo
In this book, black nodes are marked `b' and red nodes marked `r', as
shown here.
@end ifinfo

The three colored BSTs below are @strong{not} red-black trees.  The
one on the left violates rule 1, because red node 2 is a child of red
node 4.  The one in the middle violates rule 2, because one path from
the root has two black nodes (4-2-3) and the other paths from the root
down to a non-branching node (4-2-1, 4-5, 4-5-6) have only one black node.
The one on the right violates rule 2, because the path consisting of
only node 1 has only one black node but path 1-2 has two black nodes.

@center @image{rbctrex}

@references
@bibref{Cormen 1990}, section 14.1;
@bibref{Sedgewick 1998}, definitions 13.3 and 13.4.

@exercise*
A red-black tree contains only black nodes.  Describe the tree's shape.

@answer
It must be a @gloss{complete binary tree} of exactly
@altmath{2^n - 1, |pow (2|@comma{}| n) - 1|} nodes.

If a red-black tree contains only red nodes, on the other hand, it
cannot have more than one node, because of rule 1.
@end exercise

@exercise blackenroot
Suppose that a red-black tree's root is red.  How can it be transformed
into a equivalent red-black tree with a black root?  Does a similar
procedure work for changing a RB's root from black to red?

@answer
If a red-black tree's root is red, then we can transform it into an
equivalent red-black tree with a black root simply by recoloring the
root.  This cannot violate rule 1, because it does not introduce a red
node.  It cannot violate rule 2 because it only affects the number of
black nodes along paths that pass through the root, and it affects all
of those paths equally, by increasing the number of black nodes along
them by one.

If, on the other hand, a red-black tree has a black root, we cannot in
general recolor it to red, because this causes a violation of rule 1 if
the root has a red child.
@end exercise

@exercise
Suppose we have a perfectly balanced red-black tree with exactly
@altmath{2^n - 1, |pow (2|@comma{}| n) - 1|} nodes and a black root.  Is
it possible there is another way to arrange colors in a tree of the
same shape that obeys the red-black rules while keeping the root
black?  Is it possible if we drop the requirement that the tree be
balanced?

@answer
Yes and yes:

@center @image{rbunique}
@end exercise

@menu
* Analysis of Red-Black Balancing Rule::  
@end menu

@node Analysis of Red-Black Balancing Rule,  , RB Balancing Rule, RB Balancing Rule
@subsection Analysis

As we were for AVL trees, we're interested in what the red-black
balancing rule guarantees about performance.  Again, we'll simply state
the results:

@quotation
A red-black tree with @altmath{n, |n|} nodes has height at least
@altmath{\log_2(n+1), |log2 (n + 1)|} but no more than
@altmath{2\log_2(n+1), |2 * log2 (n + 1)|}.  A red-black tree with
height @altmath{h, |h|} has at least @altmath{2^{h/2} - 1, |pow
(2|@comma{}| h / 2) - 1|} nodes but no more than @altmath{2^h - 1, |pow
(2|@comma{}| h) - 1|}.

For comparison, an optimally balanced BST with |n| nodes has height
@altmath{\lceil\log_2{(n+1)}\rceil, |ceil (log2 (n + 1))|}.  An
optimally balanced BST with height |h| has between @altmath{2^{h - 1},
|pow (2|@comma{}| h - 1)|} and @altmath{2^h - 1, |pow (2|@comma{}| h) - 1|}
nodes.
@end quotation

@references
@bibref{Cormen 1990}, lemma 14.1;
@bibref{Sedgewick 1998}, property 13.8.

@node RB Data Types, Operations in an RB Tree, RB Balancing Rule, Red-Black Trees
@section Data Types

Red-black trees need their own data structure.  Otherwise, there's no
appropriate place to store each node's color.  Here's a C type for a
color and a structure for an RB node, using the |rb_| prefix that we've
adopted for this module:

@<RB node structure@> =
/* Color of a red-black node. */
enum rb_color @
  {@-
    RB_BLACK,   /* Black. */
    RB_RED      /* Red. */
  };@+

/* A red-black tree node. */
struct rb_node @
  {@-
    struct rb_node *rb_link[2];   /* Subtrees. */
    void *rb_data;                /* Pointer to data. */
    unsigned char rb_color;       /* Color. */
  };@+

@

The maximum height for an RB tree is higher than for an AVL tree,
because in the worst case RB trees store nodes less efficiently:

@<RB maximum height@> =
/* Maximum RB height. */
#ifndef RB_MAX_HEIGHT
#define RB_MAX_HEIGHT 128
#endif

@

The other data structures for RB trees are the same as for BSTs or AVL
trees.

@exercise
Why is it okay to have both an enumeration type and a structure member
named |rb_color|?

@answer
C has a number of different namespaces.  One of these is the namespace
that contains |struct|, |union|, and |enum| tags.  Names of structure
members are in a namespace separate from this tag namespace, so it is
okay to give an |enum| and a structure member the same name.  On the
other hand, it would be an error to give, e.g., a |struct| and an |enum|
the same name.
@end exercise

@node Operations in an RB Tree, Inserting into an RB Tree, RB Data Types, Red-Black Trees
@section Operations

Now we'll implement for RB trees all the operations that we did for
BSTs.  Everything but the insertion and deletion function can be
borrowed either from our BST or AVL tree functions.  The copy function
is an unusual case: we need it to copy colors, instead of balance
factors, between nodes, so we replace |avl_balance| by |rb_color| in
the macro expansion.

@<RB functions@> =
@<BST creation function; bst => rb@>
@<BST search function; bst => rb@>
@<RB item insertion function@>
@<Table insertion convenience functions; tbl => rb@>
@<RB item deletion function@>
@<AVL traversal functions; avl => rb@>
@<AVL copy function; avl => rb; avl_balance => rb_color@>
@<BST destruction function; bst => rb@>
@<Default memory allocation functions; tbl => rb@>
@<Table assertion functions; tbl => rb@>
@

@node Inserting into an RB Tree, Deleting from an RB Tree, Operations in an RB Tree, Red-Black Trees
@section Insertion

The steps for insertion into a red-black tree are similar to those for
insertion into an AVL tree:

@enumerate 1
@item @strong{Search} for the location to insert the new item.

@item @strong{Insert} the item.

@item @strong{Rebalance} the tree as necessary to satisfy the red-black
balance condition.
@end enumerate

Red-black node colors don't need to be updated in the way that AVL
balance factors do, so there is no separate step for updating colors.

Here's the outline of the function, expressed as code:

@cat rb Insertion (iterative)
@<RB item insertion function@> =
@iftangle
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree,
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
@end iftangle
void **@
rb_probe (struct rb_table *tree, void *item) @
{
  @<|rb_probe()| local variables@>

  @<Step 1: Search RB tree for insertion point@>
  @<Step 2: Insert RB node@>
  @<Step 3: Rebalance after RB insertion@>

  return &n->rb_data;
}

@

@<|rb_probe()| local variables@> =
struct rb_node *pa[RB_MAX_HEIGHT]; /* Nodes on stack. */
unsigned char da[RB_MAX_HEIGHT];   /* Directions moved from stack nodes. */
int k;                             /* Stack height. */

struct rb_node *p; /* Traverses tree looking for insertion point. */
struct rb_node *n; /* Newly inserted node. */

assert (tree != NULL && item != NULL);
@

@references
@bibref{Cormen 1990}, section 14.3;
@bibref{Sedgewick 1998}, program 13.6.

@menu
* Inserting an RB Node Step 1 - Search::  
* Inserting an RB Node Step 2 - Insert::  
* Inserting an RB Node Step 3 - Rebalance::  
* RB Insertion Symmetric Case::  
* Initial Black Insertion in an RB Tree::  
@end menu

@node Inserting an RB Node Step 1 - Search, Inserting an RB Node Step 2 - Insert, Inserting into an RB Tree, Inserting into an RB Tree
@subsection Step 1: Search

The first thing to do is to search for the point to insert the new
node.  In a manner similar to AVL deletion, we keep a stack of nodes
tracking the path followed to arrive at the insertion point, so that
later we can move up the tree in rebalancing.

@<Step 1: Search RB tree for insertion point@> =
pa[0] = (struct rb_node *) &tree->rb_root;
da[0] = 0;
k = 1;
for (p = tree->rb_root; p != NULL; p = p->rb_link[da[k - 1]]) @
  {@-
    int cmp = tree->rb_compare (item, p->rb_data, tree->rb_param);
    if (cmp == 0)
      return &p->rb_data;

    pa[k] = p;
    da[k++] = cmp > 0;
  }@+

@

@node Inserting an RB Node Step 2 - Insert, Inserting an RB Node Step 3 - Rebalance, Inserting an RB Node Step 1 - Search, Inserting into an RB Tree
@subsection Step 2: Insert

@<Step 2: Insert RB node@> =
n = pa[k - 1]->rb_link[da[k - 1]] =
  tree->rb_alloc->libavl_malloc (tree->rb_alloc, sizeof *n);
if (n == NULL)
  return NULL;

n->rb_data = item;
n->rb_link[0] = n->rb_link[1] = NULL;
n->rb_color = RB_RED;
tree->rb_count++;
tree->rb_generation++;

@

@exercise
Why are new nodes colored red, instead of black?

@answer
Inserting a red node can sometimes be done without breaking any rules.
Inserting a black node will always break rule 2.
@end exercise

@node Inserting an RB Node Step 3 - Rebalance, RB Insertion Symmetric Case, Inserting an RB Node Step 2 - Insert, Inserting into an RB Tree
@subsection Step 3: Rebalance

The code in step 2 that inserts a node always colors the new node red.
This means that rule 2 is always satisfied afterward (as long as it
was satisfied before we began).  On the other hand, rule 1 is broken
if the newly inserted node's parent was red.  In this latter case we
must rearrange or recolor the BST so that it is again an RB tree.

This is what rebalancing does.  At each step in rebalancing, we have
the invariant that we just colored a node |p| red and that |p|'s
parent, the node at the top of the stack, is also red, a rule 1
violation.  The rebalancing step may either clear up the violation
entirely, without introducing any other violations, in which case we
are done, or, if that is not possible, it reduces the violation to a
similar violation of rule 1 higher up in the tree, in which case we go
around again.

In no case can we allow the rebalancing step to introduce a rule 2
violation, because the loop is not prepared to repair that kind of
problem: it does not fit the invariant.  If we allowed rule 2
violations to be introduced, we would have to write additional code to
recognize and repair those violations.  This extra code would be a
waste of space, because we can do just fine without it.
(Incidentally, there is nothing magical about using a rule 1 violation
as our rebalancing invariant.  We could use a rule 2 violation as our
invariant instead, and in fact we will later write an alternate
implementation that does that, in order to show how it would be done.)

Here is the rebalancing loop.  At each rebalancing step, it checks
that we have a rule 1 violation by checking the color of |pa[k - 1]|,
the node on the top of the stack, and then divides into two cases, one
for rebalancing an insertion in |pa[k - 1]|'s left subtree and a
symmetric case for the right subtree.  After rebalancing it recolors
the root of the tree black just in case the loop changed it to red:

@<Step 3: Rebalance after RB insertion@> =
while (k >= 3 && pa[k - 1]->rb_color == RB_RED) @
  {@-
    if (da[k - 2] == 0)
      { @
        @<Left-side rebalancing after RB insertion@> @
      }
    else @
      { @
        @<Right-side rebalancing after RB insertion@> @
      }
  }@+
tree->rb_root->rb_color = RB_BLACK;

@

Now for the real work.  We'll look at the left-side insertion case
only.  Consider the node that was just recolored red in the last
rebalancing step, or if this is the first rebalancing step, the newly
inserted node |n|.  The code does not name this node, but we will
refer to it here as |q|.  We know that |q| is red and, because the
loop condition was met, that its parent @w{|pa[k - 1]|} is red.
Therefore, due to rule 1, |q|'s grandparent, @w{|pa[k - 2]|}, must be
black.  After this, we have three cases, distinguished by the
following code:

@<Left-side rebalancing after RB insertion@> =
struct rb_node *y = pa[k - 2]->rb_link[1];
if (y != NULL && y->rb_color == RB_RED)
  { @
    @<Case 1 in left-side RB insertion rebalancing@> @
  }
else @
  {@-
    struct rb_node *x;

    if (da[k - 1] == 0)
      y = pa[k - 1];
    else @
      { @
        @<Case 3 in left-side RB insertion rebalancing@> @
      }

    @<Case 2 in left-side RB insertion rebalancing@>
    break;
  }@+
@

@subsubheading Case 1: |q|'s uncle is red
@anchor{rbinscase1}

If |q| has an ``uncle'' |y|, that is, its grandparent has a child on the
side opposite |q|, and |y| is red, then rearranging the tree's color
scheme is all that needs to be done, like this:

@center @image{rbins1}

Notice the neat way that this preserves the @gloss{black-height}, or the
number of black nodes in any simple path from a given node down to a
node with 0 or 1 children, at |pa[k - 2]|.  This ensures that rule 2 is
not violated.

After the transformation, if node |pa[k - 2]|'s parent exists and is red,
then we have to move up the tree and try again.  The |while| loop
condition takes care of this test, so adjusting the stack is all that has
to be done in this code segment:

@<Case 1 in left-side RB insertion rebalancing@> =
pa[k - 1]->rb_color = y->rb_color = RB_BLACK;
pa[k - 2]->rb_color = RB_RED;
k -= 2;
@

@subsubheading Case 2: |q| is the left child of |pa[k - 1]|
@anchor{rbinscase2}

If |q| is the left child of its parent, then we can perform a right
rotation at |q|'s grandparent, which we'll call |x|, and recolor a
couple of nodes.  Then we're all done, because we've satisfied both
rules.  Here's a diagram of what's happened:

@center @image{rbins2}

There's no need to progress farther up the tree, because neither the
subtree's black-height nor its root's color have changed.  Here's the
corresponding code.  Bear in mind that the |break| statement is in the
enclosing code segment:

@<Case 2 in left-side RB insertion rebalancing@> =
x = pa[k - 2];
x->rb_color = RB_RED;
y->rb_color = RB_BLACK;

x->rb_link[0] = y->rb_link[1];
y->rb_link[1] = x;
pa[k - 3]->rb_link[da[k - 3]] = y;
@

@subsubheading Case 3: |q| is the right child of |pa[k - 1]|
@anchor{rbinscase3}

The final case, where |q| is a right child, is really just a small
variant of case 2, so we can handle it by transforming it into case 2
and sharing code for that case.  To transform case 2 to case 3, we just
rotate left at |q|'s parent, which is then treated as |q|.

The diagram below shows the transformation from case 3 into case 2.
After this transformation, |x| is relabeled |q| and |y|'s parent is
labeled |x|, then rebalancing continues as shown in the diagram for
case 2, with the exception that |pa[k - 1]| is not updated to
correspond to |y| as shown in that diagram.  That's okay because
variable |y| has already been set to point to the proper node.

@center @image{rbins3}

@<Case 3 in left-side RB insertion rebalancing@> =
x = pa[k - 1];
y = x->rb_link[1];
x->rb_link[1] = y->rb_link[0];
y->rb_link[0] = x;
pa[k - 2]->rb_link[0] = y;
@

@exercise mink3
Why is the test |k >= 3| on the |while| loop valid?  (Hint: read the
code for step 4, below, first.)

@answer
We can't have |k == 1|, because then the new node would be the root,
and the root doesn't have a parent that could be red.  We don't need
to rebalance |k == 2|, because the new node is a direct child of the
root, and the root is always black.
@end exercise

@exercise
Consider rebalancing case 2 and, in particular, what would happen if
the root of subtree |d| were red.  Wouldn't the rebalancing
transformation recolor |x| as red and thus cause a rule 1 violation?

@answer
Yes, it would, but if |d| has a red node as its root, case 1 will be
selected instead.
@end exercise

@node RB Insertion Symmetric Case, Initial Black Insertion in an RB Tree, Inserting an RB Node Step 3 - Rebalance, Inserting into an RB Tree
@subsection Symmetric Case

@<Right-side rebalancing after RB insertion@> =
struct rb_node *y = pa[k - 2]->rb_link[0];
if (y != NULL && y->rb_color == RB_RED)
  { @
    @<Case 1 in right-side RB insertion rebalancing@> @
  }
else @
  {@-
    struct rb_node *x;

    if (da[k - 1] == 1)
      y = pa[k - 1];
    else @
      { @
        @<Case 3 in right-side RB insertion rebalancing@> @
      }

    @<Case 2 in right-side RB insertion rebalancing@>
    break;
  }@+
@

@<Case 1 in right-side RB insertion rebalancing@> =
@<Case 1 in left-side RB insertion rebalancing@>
@

@<Case 2 in right-side RB insertion rebalancing@> =
x = pa[k - 2];
x->rb_color = RB_RED;
y->rb_color = RB_BLACK;

x->rb_link[1] = y->rb_link[0];
y->rb_link[0] = x;
pa[k - 3]->rb_link[da[k - 3]] = y;
@

@<Case 3 in right-side RB insertion rebalancing@> =
x = pa[k - 1];
y = x->rb_link[0];
x->rb_link[0] = y->rb_link[1];
y->rb_link[1] = x;
pa[k - 2]->rb_link[1] = y;
@

@node Initial Black Insertion in an RB Tree,  , RB Insertion Symmetric Case, Inserting into an RB Tree
@subsection Aside: Initial Black Insertion

The traditional algorithm for insertion in an RB tree colors new nodes
red.  This is a good choice, because it often means that no
rebalancing is necessary, but it is not the only possible choice.
This section implements an alternate algorithm for insertion into an
RB tree that colors new nodes black.

The outline is the same as for initial-red insertion.  We change the
newly inserted node from red to black and replace the rebalancing
algorithm:

@cat rb Insertion, initial black
@c tested 2001/11/10
@<RB item insertion function, initial black@> =
@iftangle
/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree,
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
@end iftangle
void **@
rb_probe (struct rb_table *tree, void *item) @
{
  @<|rb_probe()| local variables@>

  @<Step 1: Search RB tree for insertion point@>
  @<Step 2: Insert RB node; RB_RED => RB_BLACK@>
  @<Step 3: Rebalance after initial-black RB insertion@>

  return &n->rb_data;
}

@

The remaining task is to devise the rebalancing algorithm.
Rebalancing is always necessary, unless the tree was empty before
insertion, because insertion of a black node into a nonempty tree
always violates rule 2.  Thus, our invariant is that we have a rule 2
violation to fix.  

More specifically, the invariant, as implemented, is that at the top
of each trip through the loop, stack |pa[]| contains the chain of
ancestors of a node that is the black root of a subtree whose
black-height is 1 more than it should be.  We give that node the name
|q|.  There is one easy rebalancing special case: if node |q| has a
black parent, we can just recolor |q| as red, and we're done.  Here's
the loop:

@<Step 3: Rebalance after initial-black RB insertion@> =
while (k >= 2) @
  {@-
    struct rb_node *q = pa[k - 1]->rb_link[da[k - 1]];

    if (pa[k - 1]->rb_color == RB_BLACK) @
      {@-
        q->rb_color = RB_RED;
        break;
      }@+

    if (da[k - 2] == 0)
      { @
        @<Left-side rebalancing after initial-black RB insertion@> @
      }
    else @
      { @
        @<Right-side rebalancing after initial-black RB insertion@> @
      }
  }@+
@

Consider rebalancing where insertion was on the left side of |q|'s
grandparent.  We know that |q| is black and its parent |pa[k - 1]| is
red.  Then, we can divide rebalancing into three cases, described
below in detail.  (For additional insight, compare these cases to the
corresponding cases for initial-red insertion.)

@<Left-side rebalancing after initial-black RB insertion@> =
struct rb_node *y = pa[k - 2]->rb_link[1];

if (y != NULL && y->rb_color == RB_RED)
  { @
    @<Case 1 in left-side initial-black RB insertion rebalancing@> @
  }
else @
  {@-
    struct rb_node *x;

    if (da[k - 1] == 0)
      y = pa[k - 1];
    else @
      { @
        @<Case 3 in left-side initial-black RB insertion rebalancing@> @
      }

    @<Case 2 in left-side initial-black RB insertion rebalancing@>
  }@+
@

@subsubheading Case 1: |q|'s uncle is red

If |q| has an red ``uncle'' |y|, then we recolor |q| red and |pa[k -
1]| and |y| black.  This fixes the immediate problem, making the
black-height of |q| equal to its sibling's, but increases the
black-height of |pa[k - 2]|, so we must repeat the rebalancing process
farther up the tree:

@center @image{rbib1}

@<Case 1 in left-side initial-black RB insertion rebalancing@> =
pa[k - 1]->rb_color = y->rb_color = RB_BLACK;
q->rb_color = RB_RED;
k -= 2;
@

@subsubheading Case 2: |q| is the left child of |pa[k - 1]|

If |q| is a left child, then call |q|'s parent |y| and its grandparent
|x|, rotate right at |x|, and recolor |q|, |y|, and |x|.  The effect
is that the black-heights of all three subtrees is the same as before
|q| was inserted, so we're done, and |break| out of the loop.

@center @image{rbib2}

@<Case 2 in left-side initial-black RB insertion rebalancing@> =
x = pa[k - 2];
x->rb_color = q->rb_color = RB_RED;
y->rb_color = RB_BLACK;

x->rb_link[0] = y->rb_link[1];
y->rb_link[1] = x;
pa[k - 3]->rb_link[da[k - 3]] = y;
break;
@

@subsubheading Case 3: |q| is the right child of |pa[k - 1]|

If |q| is a right child, then we rotate left at its parent, which we
here call |x|.  The result is in the form for application of case 2,
so after the rotation, we relabel the nodes to be consistent with that
case.

@center @image{rbib3}

@<Case 3 in left-side initial-black RB insertion rebalancing@> =
x = pa[k - 1];
y = pa[k - 2]->rb_link[0] = q;
x->rb_link[1] = y->rb_link[0];
q = y->rb_link[0] = x;
@

@subsubsection Symmetric Case

@<Right-side rebalancing after initial-black RB insertion@> =
struct rb_node *y = pa[k - 2]->rb_link[0];

if (y != NULL && y->rb_color == RB_RED)
  { @
    @<Case 1 in right-side initial-black RB insertion rebalancing@> @
  }
else @
  {@-
    struct rb_node *x;

    if (da[k - 1] == 1)
      y = pa[k - 1];
    else @
      { @
        @<Case 3 in right-side initial-black RB insertion rebalancing@> @
      }

    @<Case 2 in right-side initial-black RB insertion rebalancing@>
  }@+
@

@<Case 1 in right-side initial-black RB insertion rebalancing@> =
@<Case 1 in left-side initial-black RB insertion rebalancing@>
@

@<Case 2 in right-side initial-black RB insertion rebalancing@> =
x = pa[k - 2];
x->rb_color = q->rb_color = RB_RED;
y->rb_color = RB_BLACK;

x->rb_link[1] = y->rb_link[0];
y->rb_link[0] = x;
pa[k - 3]->rb_link[da[k - 3]] = y;
break;
@

@<Case 3 in right-side initial-black RB insertion rebalancing@> =
x = pa[k - 1];
y = pa[k - 2]->rb_link[1] = q;
x->rb_link[0] = y->rb_link[1];
q = y->rb_link[1] = x;
@

@node Deleting from an RB Tree, Testing RB Trees, Inserting into an RB Tree, Red-Black Trees
@section Deletion

The process of deletion from an RB tree is very much in line with the
other algorithms for balanced trees that we've looked at already.  This
time, the steps are:

@enumerate 1
@item @strong{Search} for the item to delete.

@item @strong{Delete} the item.

@item @strong{Rebalance} the tree as necessary.

@item @strong{Finish up} and return.
@end enumerate

Here's an outline of the code.  Step 1 is already done for us, because
we can reuse the search code from AVL deletion.

@cat rb Deletion (iterative)
@<RB item deletion function@> =
@iftangle
/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
@end iftangle
void *@
rb_delete (struct rb_table *tree, const void *item) @
{
  struct rb_node *pa[RB_MAX_HEIGHT]; /* Nodes on stack. */
  unsigned char da[RB_MAX_HEIGHT];   /* Directions moved from stack nodes. */
  int k;                             /* Stack height. */

  struct rb_node *p;    /* The node to delete, or a node part way to it. */
  int cmp;              /* Result of comparison between |item| and |p|. */

  assert (tree != NULL && item != NULL);

  @<Step 1: Search AVL tree for item to delete; avl => rb@>
  @<Step 2: Delete item from RB tree@>
  @<Step 3: Rebalance tree after RB deletion@>
  @<Step 4: Finish up after RB deletion@>
}

@

@references
@bibref{Cormen 1990}, section 14.4.

@menu
* Deleting an RB Node Step 2 - Delete::  
* Deleting an RB Node Step 3 - Rebalance::  
* Deleting an RB Node Step 4 - Finish Up::  
* RB Deletion Symmetric Case::  
@end menu

@node Deleting an RB Node Step 2 - Delete, Deleting an RB Node Step 3 - Rebalance, Deleting from an RB Tree, Deleting from an RB Tree
@subsection Step 2: Delete

At this point, |p| is the node to be deleted and the stack contains
all of the nodes on the simple path from the tree's root down to |p|.
The immediate task is to delete |p|.  We break deletion down into the
familiar three cases (@pxref{Deleting from a BST}), but before we dive
into the code, let's think about the situation.

In red-black insertion, we were able to limit the kinds of violation
that could occur to rule 1 or rule 2, at our option, by choosing the
new node's color.  No such luxury is available in deletion, because
colors have already been assigned to all of the nodes.  In fact, a
naive approach to deletion can lead to multiple violations in widely
separated parts of a tree.  Consider the effects of deletion of node 3
from the following red-black tree tree, supposing that it is a subtree
of some larger tree:

@center @image{rbdeln1}

If we performed this deletion in a literal-minded fashion, we would
end up with the tree below, with the following violations: rule 1,
between node 6 and its child; rule 2, at node 6; rule 2, at node 4, because
the black-height of the subtree as a whole has increased (ignoring the
rule 2 violation at node 6); and rule 1, at node 4, only if the
subtree's parent is red.  The result is difficult to rebalance in
general because we have two problem areas to deal with, one at node 4,
one at node 6.

@center @image{rbdeln2}

Fortunately, we can make things easier for ourselves.  We can
eliminate the problem area at node 4 simply by recoloring it red, the
same color as the node it replaced, as shown below.  Then all we have
to deal with are the violations at node 6:

@center @image{rbdeln3}

@anchor{rbcolorswap}
This idea holds in general.  So, when we replace the deleted node |p|
by a different node |q|, we set |q|'s color to |p|'s.  Besides that,
as an implementation detail, we need to keep track of the color of the
node that was moved, i.e., node |q|'s former color.  We do this here
by saving it temporarily in |p|.  In other words, when we replace one
node by another during deletion, we swap their colors.

Now we know enough to begin the implementation.  While reading this
code, keep in mind that after deletion, regardless of the case
selected, the stack contains a list of the nodes where rebalancing may
be required, and |da[k - 1]| indicates the side of |pa[k - 1]| from
which a node of color |p->rb_color| was deleted.  Here's an outline of
the meat of the code:

@<Step 2: Delete item from RB tree@> =
if (p->rb_link[1] == NULL)
@ifweave
  { @<Case 1 in RB deletion@> }
@end ifweave
@iftangle
  @<Case 1 in RB deletion@>
@end iftangle
else @
  {@-
    enum rb_color t;
    struct rb_node *r = p->rb_link[1];

    if (r->rb_link[0] == NULL)
      { @
        @<Case 2 in RB deletion@> @
      }
    else @
      { @
        @<Case 3 in RB deletion@> @
      }
  }@+

@

@subsubheading Case 1: |p| has no right child
@anchor{rbdel1}

In case 1, |p| has no right child, so we replace it by its left
subtree.  As a very special case, there is no need to do any swapping
of colors (see @value{noswapcolorsbrief} for details).

@<Case 1 in RB deletion@> =
pa[k - 1]->rb_link[da[k - 1]] = p->rb_link[0];
@

@subsubheading Case 2: |p|'s right child has no left child
@anchor{rbdel2}

In this case, |p| has a right child |r|, which in turn has no left
child.  We replace |p| by |r|, swap the colors of nodes |p| and |r|,
and add |r| to the stack because we may need to rebalance there.
Here's a pre- and post-deletion diagram that shows one possible set of
colors out of the possibilities.  Node |p| is shown detached after
deletion to make it clear that the colors are swapped:

@center @image{rbdelcase2}

@<Case 2 in RB deletion@> =
r->rb_link[0] = p->rb_link[0];
t = r->rb_color;
r->rb_color = p->rb_color;
p->rb_color = t;
pa[k - 1]->rb_link[da[k - 1]] = r;
da[k] = 1;
pa[k++] = r;
@

@subsubheading Case 3: |p|'s right child has a left child
@anchor{rbdel3}

In this case, |p|'s right child has a left child.  The code here is
basically the same as for AVL deletion.  We replace |p| by its inorder
successor |s| and swap their node colors.  Because they may require
rebalancing, we also add all of the nodes we visit to the stack.
Here's a diagram to clear up matters, again with arbitrary colors:

@center @image{rbdelcase3}

@<Case 3 in RB deletion@> =
struct rb_node *s;
int j = k++;

for (;;) @
  {@-
    da[k] = 0;
    pa[k++] = r;
    s = r->rb_link[0];
    if (s->rb_link[0] == NULL)
      break;

    r = s;
  }@+

da[j] = 1;
pa[j] = s;
pa[j - 1]->rb_link[da[j - 1]] = s;

s->rb_link[0] = p->rb_link[0];
r->rb_link[0] = s->rb_link[1];
s->rb_link[1] = p->rb_link[1];

t = s->rb_color;
s->rb_color = p->rb_color;
p->rb_color = t;
@

@exercise* noswapcolors
In case 1, why is it unnecessary to swap the colors of |p| and the
node that replaces it?

@answer
If |p| has no left child, that is, it is a leaf, then obviously we
cannot swap colors.  Now consider only the case where |p| does have a
non-null left child |x|.  Clearly, |x| must be red, because otherwise
rule 2 would be violated at |p|.  This means that |p| must be black to
avoid a rule 1 violation.  So the deletion will eliminate a black
node, causing a rule 2 violation.  This is exactly the sort of problem
that the rebalancing step is designed to deal with, so we can
rebalance starting from node |x|.
@end exercise

@exercise
Rewrite @<Step 2: Delete item from RB tree@> to replace the deleted
node's |rb_data| by its successor, then delete the successor, instead of
shuffling pointers.  (Refer back to @value{modifydata} for an
explanation of why this approach cannot be used in @libavl{}.)

@answer
There are two cases in this algorithm, which uses a new |struct
avl_node *| variable named |x|.  Regardless of which one is chosen,
|x| has the same meaning afterward: it is the node that replaced one
of the children of the node at top of stack, and may be |NULL| if the
node removed was a leaf.

Case 1: If one of |p|'s child pointers is |NULL|, then |p| can be
replaced by the other child, or by |NULL| if both children are |NULL|:

@cat rb Deletion, with data modification
@c tested 2001/11/10
@<Step 2: Delete item from RB tree, alternate version@> =
if (p->rb_link[0] == NULL || p->rb_link[1] == NULL) @
  {@-
    x = p->rb_link[0];
    if (x == NULL)
      x = p->rb_link[1];
  }@+
@

Case 2: If both of |p|'s child pointers are non-null, then we find |p|'s
successor and replace |p|'s data by the successor's data, then delete
the successor instead:

@<Step 2: Delete item from RB tree, alternate version@> +=
else @
  {@-
    struct rb_node *y;

    pa[k] = p;
    da[k++] = 1;

    y = p->rb_link[1];
    while (y->rb_link[0] != NULL) @
      {@-
        pa[k] = y;
        da[k++] = 0;
        y = y->rb_link[0];
      }@+

    x = y->rb_link[1];
    p->rb_data = y->rb_data;
    p = y;
  }@+
@

In either case, we need to update the node above the deleted node to
point to |x|.

@<Step 2: Delete item from RB tree, alternate version@> +=
pa[k - 1]->rb_link[da[k - 1]] = x;
@

@references
@bibref{Cormen 1990}, section 14.4.
@end exercise

@node Deleting an RB Node Step 3 - Rebalance, Deleting an RB Node Step 4 - Finish Up, Deleting an RB Node Step 2 - Delete, Deleting from an RB Tree
@subsection Step 3: Rebalance

At this point, node |p| has been removed from |tree| and |p->rb_color|
indicates the color of the node that was removed from the tree.  Our
first step is to handle one common special case: if we deleted a red
node, no rebalancing is necessary, because deletion of a red node
cannot violate either rule.  Here is the code to avoid rebalancing in
this special case:

@<Step 3: Rebalance tree after RB deletion@> =
if (p->rb_color == RB_BLACK)
  { @
    @<Rebalance after RB deletion@> @
  }

@

On the other hand, if a black node was deleted, then we have more work
to do.  At the least, we have a violation of rule 2.  If the deletion
brought together two red nodes, as happened in the example in the
previous section, there is also a violation of rule 1.

We must now fix both of these problems by rebalancing.  This time, the
rebalancing loop invariant is that the black-height of |pa[k - 1]|'s
subtree on side |da[k - 1]| is 1 less than the black-height of its
other subtree, a rule 2 violation.

There may also be a rule 2 violation, such |pa[k - 1]| and its child
on side |da[k - 1]|, which we will call |x|, are both red.  (In the
first iteration of the rebalancing loop, node |x| is the node labeled
as such in the diagrams in the previous section.)  If this is the
case, then the fix for rule 2 is simple: just recolor |x| black.  This
increases the black-height and fixes any rule 1 violation as well.  If
we can do this, we're all done.  Otherwise, we have more work to do.

Here's the rebalancing loop:

@<Rebalance after RB deletion@> =
for (;;) @
  {@-
    struct rb_node *x = pa[k - 1]->rb_link[da[k - 1]];
    if (x != NULL && x->rb_color == RB_RED) @
      {@-
        x->rb_color = RB_BLACK;
        break;
      }@+
    if (k < 2)
      break;

    if (da[k - 1] == 0)
      { @
        @<Left-side rebalancing after RB deletion@> @
      }
    else @
      { @
        @<Right-side rebalancing after RB deletion@> @
      }

    k--;
  }@+

@

Now we'll take a detailed look at the rebalancing algorithm.  As
before, we'll only examine the case where the deleted node was in its
parent's left subtree, that is, where |da[k - 1]| is 0.  The other
case is similar.

Recall that |x| is |pa[k - 1]->rb_link[da[k - 1]]| and that it may be
a null pointer.  In the left-side deletion case, |x| is |pa[k - 1]|'s
left child.  We now designate |x|'s ``sibling'', the right child of
|pa[k - 1]|, as |w|.  Jumping right in, here's an outline of the
rebalancing code:

@<Left-side rebalancing after RB deletion@> =
struct rb_node *w = pa[k - 1]->rb_link[1];

if (w->rb_color == RB_RED)
  { @
    @<Ensure |w| is black in left-side RB deletion rebalancing@> @
  }

if ((w->rb_link[0] == NULL @
     || w->rb_link[0]->rb_color == RB_BLACK)
    && (w->rb_link[1] == NULL @
        || w->rb_link[1]->rb_color == RB_BLACK))
@iftangle
  @<Case 1 in left-side RB deletion rebalancing@>
@end iftangle
@ifweave
  { @<Case 1 in left-side RB deletion rebalancing@> }
@end ifweave
else @
  {@-
    if (w->rb_link[1] == NULL @
        || w->rb_link[1]->rb_color == RB_BLACK)
      { @
        @<Transform left-side RB deletion rebalancing case 3 into case 2@> @
      }

    @<Case 2 in left-side RB deletion rebalancing@>
    break;
  }@+
@

@subsubheading Case Reduction: Ensure |w| is black
@anchor{rbdcr}

We know, at this point, that |x| is a black node or an empty tree.
Node |w| may be red or black.  If |w| is red, we perform a left
rotation at the common parent of |x| and |w|, labeled @i{A} in the
diagram below, and recolor @i{A} and its own newly acquired parent
@i{C}.  Then we reassign |w| as the new sibling of |x|.  The effect is
to ensure that |w| is also black, in order to reduce the number of
cases:

@center @image{rbdel1}

@noindent
Node |w| must have children because |x| is black, in order to
satisfy rule 2, and |w|'s children must be black because of rule 1.

Here is the code corresponding to this transformation.  Because the
ancestors of node |x| change, |pa[]| and |da[]| are updated as well as
|w|.

@<Ensure |w| is black in left-side RB deletion rebalancing@> =
w->rb_color = RB_BLACK;
pa[k - 1]->rb_color = RB_RED;

pa[k - 1]->rb_link[1] = w->rb_link[0];
w->rb_link[0] = pa[k - 1];
pa[k - 2]->rb_link[da[k - 2]] = w;

pa[k] = pa[k - 1];
da[k] = 0;
pa[k - 1] = w;
k++;

w = pa[k - 1]->rb_link[1];
@

Now we can take care of the three rebalancing cases one by one.
Remember that the situation is a deleted black node in the subtree
designated |x| and the goal is to correct a rule 2 violation.
Although subtree |x| may be an empty tree, the diagrams below show it
as a black node.  That's okay because the code itself never refers to
|x|.  The label is supplied for the reader's benefit only.

@subsubheading Case 1: |w| has no red children
@anchor{rbdelcase1}

If |w| doesn't have any red children, then it can be recolored red.
When we do that, the black-height of the subtree rooted at |w| has
decreased, so we must move up the tree, with |pa[k - 1]| becoming the
new |x|, to rebalance at |w| and |x|'s parent.

The parent, labeled @i{B} in the diagram below, may be red or black.
Its color is not changed within the code for this case.  If it is red,
then the next iteration of the rebalancing loop will recolor it as red
immediately and exit.  In particular, @i{B} will be red if the
transformation to make |x| black was performed earlier.  If, on the
other hand, @i{B} is black, the loop will continue as usual.

@center @image{rbdel2}

@<Case 1 in left-side RB deletion rebalancing@> =
w->rb_color = RB_RED;
@

@subsubheading Case 2: |w|'s right child is red
@anchor{rbdelcase2}

If |w|'s right child is red, we can perform a left rotation at |pa[k -
1]| and recolor some nodes, and thereby satisfy both of the red-black
rules.  The loop is then complete.  The transformation looks like
this:

@center @image{rbdel3}

The corresponding code is below.  The |break| is supplied by the
enclosing code segment @<Left-side rebalancing after RB deletion@>:

@<Case 2 in left-side RB deletion rebalancing@> =
w->rb_color = pa[k - 1]->rb_color;
pa[k - 1]->rb_color = RB_BLACK;
w->rb_link[1]->rb_color = RB_BLACK;

pa[k - 1]->rb_link[1] = w->rb_link[0];
w->rb_link[0] = pa[k - 1];
pa[k - 2]->rb_link[da[k - 2]] = w;
@

@subsubheading Case 3: |w|'s left child is red
@anchor{rbdelcase3}

Because the conditions for neither case 1 nor case 2 apply, the only
remaining possibility is that |w| has a red left child.  When this is
the case, we can transform it into case 2 by rotating right at |w|.
This causes |w| to move to the node that was previously |w|'s left
child, in this way:

@center @image{rbdel4}

@<Transform left-side RB deletion rebalancing case 3 into case 2@> =
struct rb_node *y = w->rb_link[0];
y->rb_color = RB_BLACK;
w->rb_color = RB_RED;
w->rb_link[0] = y->rb_link[1];
y->rb_link[1] = w;
w = pa[k - 1]->rb_link[1] = y;
@

@node Deleting an RB Node Step 4 - Finish Up, RB Deletion Symmetric Case, Deleting an RB Node Step 3 - Rebalance, Deleting from an RB Tree
@subsection Step 4: Finish Up

All that's left to do is free the node, update counters, and return the
deleted item:

@<Step 4: Finish up after RB deletion@> =
tree->rb_alloc->libavl_free (tree->rb_alloc, p);
tree->rb_count--;
tree->rb_generation++;
return (void *) item;
@

@node RB Deletion Symmetric Case,  , Deleting an RB Node Step 4 - Finish Up, Deleting from an RB Tree
@subsection Symmetric Case

@<Right-side rebalancing after RB deletion@> =
struct rb_node *w = pa[k - 1]->rb_link[0];

if (w->rb_color == RB_RED)
  { @
    @<Ensure |w| is black in right-side RB deletion rebalancing@> @
  }

if ((w->rb_link[0] == NULL @
     || w->rb_link[0]->rb_color == RB_BLACK)
    && (w->rb_link[1] == NULL @
        || w->rb_link[1]->rb_color == RB_BLACK))
@iftangle
  @<Case 1 in right-side RB deletion rebalancing@>
@end iftangle
@ifweave
  { @<Case 1 in right-side RB deletion rebalancing@> }
@end ifweave
else @
  {@-
    if (w->rb_link[0] == NULL @
        || w->rb_link[0]->rb_color == RB_BLACK)
      { @
        @<Transform right-side RB deletion rebalancing case 3 into case 2@> @
      }

    @<Case 2 in right-side RB deletion rebalancing@>
    break;
  }@+
@

@<Ensure |w| is black in right-side RB deletion rebalancing@> =
w->rb_color = RB_BLACK;
pa[k - 1]->rb_color = RB_RED;

pa[k - 1]->rb_link[0] = w->rb_link[1];
w->rb_link[1] = pa[k - 1];
pa[k - 2]->rb_link[da[k - 2]] = w;

pa[k] = pa[k - 1];
da[k] = 1;
pa[k - 1] = w;
k++;

w = pa[k - 1]->rb_link[0];
@

@<Case 1 in right-side RB deletion rebalancing@> =
w->rb_color = RB_RED;
@

@<Transform right-side RB deletion rebalancing case 3 into case 2@> =
struct rb_node *y = w->rb_link[1];
y->rb_color = RB_BLACK;
w->rb_color = RB_RED;
w->rb_link[1] = y->rb_link[0];
y->rb_link[0] = w;
w = pa[k - 1]->rb_link[0] = y;
@

@<Case 2 in right-side RB deletion rebalancing@> =
w->rb_color = pa[k - 1]->rb_color;
pa[k - 1]->rb_color = RB_BLACK;
w->rb_link[0]->rb_color = RB_BLACK;

pa[k - 1]->rb_link[0] = w->rb_link[1];
w->rb_link[1] = pa[k - 1];
pa[k - 2]->rb_link[da[k - 2]] = w;
@

@node Testing RB Trees,  , Deleting from an RB Tree, Red-Black Trees
@section Testing

Now we'll present a test program to demonstrate that our code works,
using the same framework that has been used in past chapters.  The
additional code needed is straightforward:

@(rb-test.c@> =
@<Program License@>
#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include "rb.h"
#include "test.h"

@<BST print function; bst => rb@>
@<BST traverser check function; bst => rb@>
@<Compare two RB trees for structure and content@>
@<Recursively verify RB tree structure@>
@<RB tree verify function@>
@<BST test function; bst => rb@>
@<BST overflow test function; bst => rb@>
@

@<Compare two RB trees for structure and content@> =
@iftangle
/* Compares binary trees rooted at |a| and |b|,
   making sure that they are identical. */
@end iftangle
static int @
compare_trees (struct rb_node *a, struct rb_node *b) @
{
  int okay;

  if (a == NULL || b == NULL) @
    {@-
      assert (a == NULL && b == NULL);
      return 1;
    }@+

  if (*(int *) a->rb_data != *(int *) b->rb_data
      || ((a->rb_link[0] != NULL) != (b->rb_link[0] != NULL))
      || ((a->rb_link[1] != NULL) != (b->rb_link[1] != NULL))
      || a->rb_color != b->rb_color) @
    {@-
      printf (" Copied nodes differ: a=%d%c b=%d%c a:",
              *(int *) a->rb_data, a->rb_color == RB_RED ? 'r' : 'b',
              *(int *) b->rb_data, b->rb_color == RB_RED ? 'r' : 'b');

      if (a->rb_link[0] != NULL) @
	printf ("l");
      if (a->rb_link[1] != NULL) @
	printf ("r");

      printf (" b:");
      if (b->rb_link[0] != NULL) @
	printf ("l");
      if (b->rb_link[1] != NULL) @
	printf ("r");

      printf ("\n");
      return 0;
    }@+

  okay = 1;
  if (a->rb_link[0] != NULL) @
    okay &= compare_trees (a->rb_link[0], b->rb_link[0]);
  if (a->rb_link[1] != NULL) @
    okay &= compare_trees (a->rb_link[1], b->rb_link[1]);
  return okay;
}

@

@<Recursively verify RB tree structure@> =
/* Examines the binary tree rooted at |node|.  
   Zeroes |*okay| if an error occurs.  @
   Otherwise, does not modify |*okay|.
   Sets |*count| to the number of nodes in that tree, @
   including |node| itself if |node != NULL|.
   Sets |*bh| to the tree's black-height.
   All the nodes in the tree are verified to be at least |min| @
   but no greater than |max|. */
static void @
recurse_verify_tree (struct rb_node *node, int *okay, size_t *count, 
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
  d = *(int *) node->rb_data;

  @<Verify binary search tree ordering@>

  recurse_verify_tree (node->rb_link[0], okay, &subcount[0], 
                       min, d - 1, &subbh[0]);
  recurse_verify_tree (node->rb_link[1], okay, &subcount[1], 
                       d + 1, max, &subbh[1]);
  *count = 1 + subcount[0] + subcount[1];
  *bh = (node->rb_color == RB_BLACK) + subbh[0];

  @<Verify RB node color@>
  @<Verify RB node rule 1 compliance@>
  @<Verify RB node rule 2 compliance@>
}

@

@<Verify RB node color@> =
if (node->rb_color != RB_RED && node->rb_color != RB_BLACK) @
  {@-
    printf (" Node %d is neither red nor black (%d).\n", @
            d, node->rb_color);
    *okay = 0;
  }@+

@

@<Verify RB node rule 1 compliance@> =
/* Verify compliance with rule 1. */
if (node->rb_color == RB_RED) @
  {@-
    if (node->rb_link[0] != NULL && node->rb_link[0]->rb_color == RB_RED) @
      {@-
        printf (" Red node %d has red left child %d\n",
                d, *(int *) node->rb_link[0]->rb_data);
        *okay = 0;
      }@+

    if (node->rb_link[1] != NULL && node->rb_link[1]->rb_color == RB_RED) @
      {@-
        printf (" Red node %d has red right child %d\n",
                d, *(int *) node->rb_link[1]->rb_data);
        *okay = 0;
      }@+
  }@+

@

@<Verify RB node rule 2 compliance@> =
/* Verify compliance with rule 2. */
if (subbh[0] != subbh[1]) @
  {@-
    printf (" Node %d has two different black-heights: left bh=%d, "
            "right bh=%d\n", d, subbh[0], subbh[1]);
    *okay = 0;
  }@+
@

@<RB tree verify function@> =
@iftangle
/* Checks that |tree| is well-formed
   and verifies that the values in |array[]| are actually in |tree|.
   There must be |n| elements in |array[]| and |tree|.
   Returns nonzero only if no errors detected. */
@end iftangle
static int @
verify_tree (struct rb_table *tree, int array[], size_t n) @
{
  int okay = 1;

  @<Check |tree->bst_count| is correct; bst => rb@>

  if (okay) @
    { @
      @<Check root is black@> @
    }

  if (okay) @
    { @
      @<Check RB tree structure@> @
    }

  if (okay) @
    { @
      @<Check that the tree contains all the elements it should; bst => rb@> @
    }

  if (okay) @
    { @
      @<Check that forward traversal works; bst => rb@> @
    }

  if (okay) @
    { @
      @<Check that backward traversal works; bst => rb@> @
    }

  if (okay) @
    { @
      @<Check that traversal from the null element works; bst => rb@> @
    }

  return okay;
}

@

@<Check root is black@> =
if (tree->rb_root != NULL && tree->rb_root->rb_color != RB_BLACK) @
  {@-
    printf (" Tree's root is not black.\n");
    okay = 0;
  }@+
@

@<Check RB tree structure@> =
/* Recursively verify tree structure. */
size_t count;
int bh;

recurse_verify_tree (tree->rb_root, &okay, &count, 0, INT_MAX, &bh);
@<Check counted nodes@>
@
