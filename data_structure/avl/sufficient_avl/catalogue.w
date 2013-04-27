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

@tex
\gdef\catentryleaders{\leaders\hbox to 1em{\hss.\hss}\hfill}
\gdef\catentry#1#2{\noindent #2\catentryleaders{}\refx{#1-pg}\*}
@end tex
@ifnottex
@macro catentry{ANCHOR, TITLE}
@noindent \TITLE\:
@flushright 
@ref{\ANCHOR\}
@end flushright
@end macro
@end ifnottex

@node Catalogue of Algorithms, Index, Answers to All the Exercises, Top
@appendix Catalogue of Algorithms

This appendix lists all of the algorithms described and implemented in
this book, along with page number references.  Each algorithm is
listed under the least-specific type of tree to which it applies,
which is not always the same as the place where it is introduced.  For
instance, rotations on threaded trees can be used in any threaded
tree, so they appear under ``Threaded Binary Search Tree Algorithms'',
despite their formal introduction later within the threaded AVL tree
chapter.

Sometimes multiple algorithms for accomplishing the same task are
listed.  In this case, the different algorithms are qualified by a few
descriptive words.  For the algorithm used in @libavl{}, the
description is enclosed by parentheses, and the description of each
alternative algorithm is set off by a comma.

@unnumberedsec Binary Search Tree Algorithms
@printcatalogue bst

@unnumberedsec AVL Tree Algorithms
@printcatalogue avl

@unnumberedsec Red-Black Tree Algorithms
@printcatalogue rb

@unnumberedsec Threaded Binary Search Tree Algorithms
@printcatalogue tbst

@unnumberedsec Threaded AVL Tree Algorithms
@printcatalogue tavl

@unnumberedsec Threaded Red-Black Tree Algorithms
@printcatalogue trb

@unnumberedsec Right-Threaded Binary Search Tree Algorithms
@printcatalogue rtbst

@unnumberedsec Right-Threaded AVL Tree Algorithms
@printcatalogue rtavl

@unnumberedsec Right-Threaded Red-Black Tree Algorithms
@printcatalogue rtrb

@unnumberedsec Binary Search Tree with Parent Pointers Algorithms
@printcatalogue pbst

@unnumberedsec AVL Tree with Parent Pointers Algorithms
@printcatalogue pavl

@unnumberedsec Red-Black Tree with Parent Pointers Algorithms
@printcatalogue prb
