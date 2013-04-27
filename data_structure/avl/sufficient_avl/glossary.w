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

@node Glossary, Answers to All the Exercises, GNU Free Documentation License, Top
@appendix Glossary

@glossdfn{adjacent} Two nodes in a @gloss{binary tree} are adjacent if
one is the child of the other.

@glossdfn{AVL tree} A type of @gloss{balanced tree}, where the AVL
@gloss{balance factor} of each node is limited to |-1|, |0|, or |+1|.

@glossdfn{balance} To rearrange a @gloss{binary search tree} so that
it has its minimum possible @gloss{height}, approximately the binary
logarithm of its number of nodes.

@glossdfn{balance condition} In a @gloss{balanced tree}, the additional
rule or rules that limit the tree's height.

@glossdfn{balance factor} For any node in an @gloss{AVL tree}, the
difference between the @gloss{height} of the node's @gloss{right
subtree} and @gloss{left subtree}.

@glossdfn{balanced tree} A @gloss{binary search tree} along with a rule
that limits the tree's height in order to avoid a @gloss{pathological
case}.  Types of balanced trees: @gloss{AVL tree}, @gloss{red-black
tree}.

@glossdfn{binary search} A technique for searching by comparison of
keys, in which the search space roughly halves in size after each
comparison step.

@glossdfn{binary search tree} A @gloss{binary tree} with the additional
property that the key in each node's left child is less than the node's
key, and that the key in each node's right child is greater than the
node's key.  In @gloss{inorder traversal}, the items in a BST are
visited in sorted order of their keys.

@glossdfn{binary tree} A data structure that is either an @gloss{empty
tree} or consists of a @gloss{root}, a @gloss{left subtree}, and a
@gloss{right subtree}.

@glossdfn{black box} Conceptually, a device whose input and output are
defined but whose principles of internal operation is not specified.

@glossdfn{black-height} In a @gloss{red-black tree}, the number of
black nodes along a simple path from a given node down to a
non-branching node.  Due to @gloss{rule 2}, this is the same
regardless of the path chosen.

@glossdfn{BST} See @gloss{binary search tree}.

@glossdfn{child} In a @gloss{binary tree}, a @gloss{left child} or
@gloss{right child} of a node.

@glossdfn{children} More than one @gloss{child}.

@glossdfn{color} In a @gloss{red-black tree}, a property of a node,
either red or black.  Node colors in a red-black tree are constrained
by @gloss{rule 1} and @gloss{rule 2}

@glossdfn{complete binary tree} A @gloss{binary tree} in which every
@gloss{simple path} from the root down to a leaf has the same length and
every non-leaf node has two children.

@glossdfn{compression} A transformation on a binary search tree used
to @gloss{rebalance} (sense 2).

@glossdfn{deep copy} In making a copy of a complex data structure, it is
often possible to copy upper levels of data without copying lower
levels.  If all levels are copied nonetheless, it is a deep copy.  See
also @gloss{shallow copy}.

@glossdfn{dynamic} 1. When speaking of data, data that can change or (in
some contexts) varies quickly.  2. In C, memory allocation with
|malloc()| and related functions.  See also @gloss{static}.

@glossdfn{empty tree} A binary tree without any nodes.

@glossdfn{height} In a binary tree, the maximum number of nodes that can be
visited starting at the tree's root and moving only downward.  An
an empty tree has height 0.

@glossdfn{idempotent} Having the same effect as if used only once,
even if used multiple times.  C header files are usually designed to
be idempotent.

@glossdfn{inorder predecessor} The node preceding a given node in an
@gloss{inorder traversal}.

@glossdfn{inorder successor} The node following a given node in an
@gloss{inorder traversal}.

@glossdfn{inorder traversal} A type of binary tree @gloss{traversal} where
the root's left subtree is traversed, then the root is visited, then the
root's right subtree is traversed.

@glossdfn{iteration} In C, repeating a sequence of statements without
using recursive function calls, most typically accomplished using a
|for| or |while| loop.  Oppose @gloss{recursion}. 

@glossdfn{key} In a binary search tree, data stored in a @gloss{node} and
used to order nodes.

@glossdfn{leaf} A @gloss{node} whose @gloss{children} are empty.

@glossdfn{left child} In a @gloss{binary tree}, the root of a node's
left subtree, if that subtree is non-empty.  A node that has an empty
left subtree may be said to have no left child.

@glossdfn{left rotation} See @ref{rotation}.

@glossdfn{left subtree} Part of a non-empty @gloss{binary tree}.

@glossdfn{left-threaded tree} A @gloss{binary search tree} augmented
to simplify and speed up traversal in reverse of @gloss{inorder
traversal}, but not traversal in the forward direction.

@glossdfn{literate programming} A philosophy of programming that regards
software as a type of literature, popularized by Donald Knuth through
his works such as @bibref{Knuth 1992}.

@glossdfn{node} The basic element of a binary tree, consisting of a
@gloss{key}, a @gloss{left child}, and a @gloss{right child}.

@glossdfn{non-branching node} A node in a @gloss{binary tree} that has
exactly zero or one non-empty children.

@glossdfn{nonterminal node} A @gloss{node} with at least one nonempty
@gloss{subtree}.

@glossdfn{parent} When one node in a @gloss{binary tree} is the child
of another, the first node.  A node that is not the child of any other
node has no parent.

@glossdfn{parent pointer} A pointer within a node to its
@gloss{parent} node.

@glossdfn{pathological case} In a @gloss{binary search tree} context, a
BST whose @gloss{height} is much greater than the minimum possible.
Avoidable through use of @gloss{balanced tree} techniques.

@glossdfn{path} In a @gloss{binary tree}, a list of nodes such that, for
each pair of nodes appearing adjacent in the list, one of the nodes is
the parent of the other.

@glossdfn{postorder traversal} A type of binary tree @gloss{traversal} where
the root's left subtree is traversed, then the root's right subtree is
traversed, then the root is visited.

@glossdfn{preorder traversal} A type of binary tree @gloss{traversal} where
the root is visited, then the root's left subtree is traversed, then the
root's right subtree is traversed.

@glossdfn{rebalance} 1. After an operation that modifies a
@gloss{balanced tree}, to restore the tree's @gloss{balance
condition}, typically by @gloss{rotation} or, in a @gloss{red-black
tree}, changing the @gloss{color} of one or more nodes. 2. To
reorganize a @gloss{binary search tree} so that its shape more closely
approximates that of a @gloss{complete binary tree}.

@glossdfn{recursion} In C, describes a function that calls itself directly
or indirectly.  See also @gloss{tail recursion}.  Oppose
@gloss{iteration}.

@glossdfn{red-black tree} A form of @gloss{balanced tree} where each
node has a @gloss{color} and these colors are laid out such that they
satisfy @gloss{rule 1} and @gloss{rule 2} for red-black trees.

@glossdfn{right child} In a @gloss{binary tree}, the root of a node's
right subtree, if that subtree is non-empty.  A node that has an empty
right subtree may be said to have no right child.

@glossdfn{right rotation} See @ref{rotation}.

@glossdfn{right subtree} Part of a non-empty @gloss{binary tree}.

@glossdfn{right-threaded tree} A @gloss{binary search tree} augmented
to simplify and speed up @gloss{inorder traversal}, but not traversal
in the reverse order.

@glossdfn{rotation} A particular type of simple transformation on a
@gloss{binary search tree} that changes local structure without
changing @gloss{inorder traversal} ordering.  @xref{BST Rotations},
@ref{TBST Rotations}, @ref{RTBST Rotations}, and @ref{PBST Rotations},
for more details.

@glossdfn{root} A @gloss{node} taken as a @gloss{binary tree} in its own
right.  Every node is the root of a binary tree, but ``root'' is most
often used to refer to a node that is not a @gloss{child} of any other
node.

@glossdfn{rule 1} One of the rules governing layout of node colors in
a @gloss{red-black tree}: no red node may have a red child.  @xref{RB
Balancing Rule}.

@glossdfn{rule 2} One of the rules governing layout of node colors in
a @gloss{red-black tree}: every @gloss{simple path} from a given node
to one of its @gloss{non-branching node} descendants contains the same
number of black nodes.  @xref{RB Balancing Rule}.

@glossdfn{sentinel} In the context of searching in a data structure, a piece
of data used to avoid an explicit test for a null pointer, the end of an
array, etc., typically by setting its value to that of the looked-for
data item.

@glossdfn{sequential search} A technique for searching by comparison of
keys, in which the search space is typically reduced only by one item
for each comparison.

@glossdfn{sequential search with sentinel} A @gloss{sequential search}
in a search space set up with a @gloss{sentinel}.

@glossdfn{shallow copy} In making a copy of a complex data structure, it is
often possible to copy upper levels of data without copying lower
levels.  If lower levels are indeed shared, it is a shallow copy.  See
also @gloss{deep copy}.

@glossdfn{simple path} A @gloss{path} that does not include any node
more than once.

@glossdfn{static} 1. When speaking of data, data that is invariant or (in
some contexts) changes rarely.  2. In C, memory allocation other than
that done with |malloc()| and related functions.  3. In C, a keyword
used for a variety of purposes, some of which are related to sense 2.
See also @gloss{dynamic}.

@glossdfn{subtree} A @gloss{binary tree} that is itself a child of some
@gloss{node}.

@glossdfn{symmetric traversal} @gloss{inorder traversal}.

@glossdfn{tag} A field in a @gloss{threaded tree} node
used to distinguish a @gloss{thread} from a @gloss{child} pointer.

@glossdfn{tail recursion} A form of @gloss{recursion} where a function
calls itself as its last action.  If the function is non-|void|, the
outer call must also return to its caller the value returned by the
inner call in order to be tail recursive.

@glossdfn{terminal node} A node with no @gloss{left child} or
@gloss{right child}.

@glossdfn{thread} In a @gloss{threaded tree}, a pointer
to the predecessor or successor of a @gloss{node}, replacing a child
pointer that would otherwise be null.  Distinguished from an ordinary
child pointer using a @gloss{tag}.

@glossdfn{threaded tree} A form of @gloss{binary search
tree} augmented to simplify @gloss{inorder traversal}.  See also
@gloss{thread}, @gloss{tag}.

@glossdfn{traversal} To @gloss{visit} each of the nodes in a @gloss{binary
tree} according to some scheme based on the tree's structure.  See
@gloss{inorder traversal}, @gloss{preorder traversal}, @gloss{postorder
traversal}.

@glossdfn{undefined behavior} In C, a situation to which the computer's
response is unpredictable.  It is frequently noted that, when undefined
behavior is invoked, it is legal for the compiler to ``make demons fly
out of your nose.''

@glossdfn{value} Often kept in a @gloss{node} along with the @gloss{key}, a
value is auxiliary data not used to determine ordering of nodes.

@glossdfn{vine} A degenerate @gloss{binary tree}, resembling a linked
list, in which each node has at most one child.

@glossdfn{visit} During @gloss{traversal}, to perform an operation on a
node, such as to display its value or free its associated memory.
