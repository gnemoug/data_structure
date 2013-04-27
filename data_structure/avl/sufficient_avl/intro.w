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

@node Introduction, The Table ADT, Preface, Top
@chapter Introduction

@libavl{} is a library in ANSI C for manipulation of various types of
binary trees.  This book provides an introduction to binary tree
techniques and presents all of @libavl{}'s source code, along with
annotations and exercises for the reader.  It also includes practical
information on how to use @libavl{} in your programs and discussion of
the larger issues of how to choose efficient data structures and
libraries.  The book concludes with suggestions for further reading,
answers to all the exercises, glossary, and index.

@menu
* Audience::                    
* Reading the Code::            
* Code Conventions::            
* Licenses::                
@end menu

@node Audience, Reading the Code, Introduction, Introduction
@section Audience

This book is intended both for novices interested in finding out about
binary search trees and practicing programmers looking for a cookbook of
algorithms.  It has several features that will be appreciated by both
groups:

@itemize @bullet
@item 
@i{Tested code}: With the exception of code presented as
counterexamples, which are clearly marked, all code presented has been
tested.  Most code comes with a working program for testing or
demonstrating it.

@item 
@i{No pseudo-code}: Pseudo-code can be confusing, so it is not used.

@item 
@i{Motivation}: An important goal is to demonstrate general methods for
programming, not just the particular algorithms being examined.  As a
result, the rationale for design choices is explained carefully.

@item 
@i{Exercises and answers}: To clarify issues raised within the text,
many sections conclude with exercises.  All exercises come with complete
answers in an appendix at the back of the book.

Some exercises are marked with one or more stars (*).  Exercises
without stars are recommended for all readers, but starred exercises
deal with particularly obscure topics or make reference to topics
covered later.

Experienced programmers should find the exercises particularly
interesting, because many of them present alternatives to choices made
in the main text.

@item
@i{Asides}: Occasionally a section is marked as an ``aside''.  Like
exercises, asides often highlight alternatives to techniques in the
main text, but asides are more extensive than most exercises.  Asides
are not essential to comprehension of the main text, so readers not
interested may safely skip over them to the following section.

@item 
@i{Minimal C knowledge assumed}: Basic familiarity with the C language
is assumed, but obscure constructions are briefly explained the first
time they occur.

Those who wish for a review of C language features before beginning
should consult @bibref{Summit 1999}.  This is especially recommended
for novices who feel uncomfortable with pointer and array concepts.

@item 
@i{References}: When appropriate, other texts that cover the same or
related material are referenced at the end of sections.

@item 
@i{Glossary}: Terms are @dfn{emphasized} and defined the first time they
are used.  Definitions for these terms and more are collected into a
glossary at the back of the book.

@item
@i{Catalogue of algorithms}: @xref{Catalogue of Algorithms}, for a handy
list of all the algorithms implemented in this book.
@end itemize

@node Reading the Code, Code Conventions, Audience, Introduction
@section Reading the Code

This book contains all the source code to @libavl{}.  Conversely, much
of the source code presented in this book is part of @libavl{}.

@libavl{} is written in ANSI/ISO C89 using @TexiWEB{}, a @gloss{literate
programming} system.  Literate programming is a philosophy that regards
software as a kind of literature.  The ideas behind literate programming
have been around for a long time, but the term itself was invented by
computer scientist Donald Knuth in 1984, who wrote two of his most
famous programs (@TeX{} and @MF{}) with a literate programming system of
his own design.  That system, called @WEB{}, inspired the form and much
of the syntax of @TexiWEB{}.

A @TexiWEB{} document is a C program that has been cut into sections,
rearranged, and annotated, with the goal to make the program as a whole
as comprehensible as possible to a reader who starts at the beginning
and reads the entire program in order.  Of course, understanding large,
complex programs cannot be trivial, but @TexiWEB{} tries to make it as
easy as possible.

Each section of a @TexiWEB{} program is assigned both a number and a
name.  Section numbers are assigned sequentially, starting from 1 with
the first section, and they are used for cross-references between
sections.  Section names are words or phrases assigned by the @TexiWEB{}
program's author to describe the role of the section's code.

Here's a sample @TexiWEB{} section:

@begincode
@tabalign{}@textinleftmargin{@w{@segno{19} }}@nottex{19. }@value{LANG}Clear hash table entries @smnumber{19}@value{RANG} @value{IS}@cr
@tabalign{}@w{@b{for}} (@cleartabs{}@wtab{}@w{@i{i}} = 0; @w{@i{i}} @math{<} @w{@i{hash}}@value{RARR}@w{@i{m}}; @w{@i{i}}@math{++})@cr
  @tabalign{}@IND{2em}@w{@i{hash}}@value{RARR}@w{@i{entry}}[@cleartabs{}@wtab{}@w{@i{i}}] = @w{@t{NULL}};@cr
@endcode format
@noindent
@little{This code is included in @segno{15}.}

The first line of a section, as shown here, gives the section's name and
its number within angle brackets.  
@ifnottex
The section number is also given at the left margin to make individual
sections easy to find.
@end ifnottex
@iftex
The section number is also printed in the left margin to make individual
sections easy to find.  Looking farther down, at the code itself, the C
operator @code{->} has been replaced by the nicer-looking arrow |->|.
@TexiWEB{} makes an attempt to ``prettify'' C in a few ways like this.
The table below lists most of these substitutions:

@multitable @columnfractions .25 .15 .18 .15
@item @tab -> @tab becomes @tab |->|
@item @tab 0x12ab @tab becomes @tab |0x12ab|
@item @tab 0377 @tab becomes @tab |0377|
@item @tab 1.2e34 @tab becomes @tab |1.2e34|
@end multitable

In addition,| - |and| + |are written as superscripts when used to
indicate sign, as in |-5| or |+10|.
@end iftex

@ifnotinfo
In @TexiWEB{}, C's reserved words are shown like this: |int|, |struct|,
|while|@enddots{} Types defined with |typedef| or with |struct|,
|union|, and |enum| tags are shown the same way.  Identifiers in all
capital letters (often names of macros) are shown like this: |BUFSIZ|,
|EOF|, |ERANGE|@enddots{} Other identifiers are shown like this: |getc|,
|argv|, |strlen|@enddots{}
@end ifnotinfo

@iftex
Sometimes it is desirable to talk about mathematical expressions, as
opposed to C expressions.  When this is done, mathematical operators
@w{(@<=, @>=)} instead of C operators @w{(|<=|, |>=|)} are used.  In
particular, mathematical equality is indicated with @= instead of = in
order to minimize potential confusion.
@end iftex

Code segments often contain references to other code segments, shown as
a section name and number within angle brackets.  These act something
like macros, in that they stand for the corresponding replacement text.
For instance, consider the following segment:

@begincode
@tabalign{}@textinleftmargin{@w{@segno{15} }}@nottex{15. }@value{LANG}Initialize hash table @smnumber{15}@value{RANG} @value{IS}@cr
@tabalign{}@w{@i{hash}}@value{RARR}@w{@i{m}} = 13;@cr
@tabalign{}@value{LANG}Clear hash table entries @smnumber{19}@value{RANG}@cr
@endcode format
@noindent
@little{See also @segno{16}.}

This means that the code for `Clear hash table entries' should be
inserted as part of `Initialize hash table'.  Because the name of a
section explains what it does, it's often unnecessary to know anything
more.  If you do want more detail, the section number @little{19} in
@refcode{Clear hash table entries,19} can easily be used to find the
full text and annotations for `Clear hash table entries'.  
@ifhtml
You can also view the fully expanded code in a code segment by
following the link from the segment name or number (our example does
not include this feature).
@end ifhtml
At the bottom of section 19 you will find a note reading `@little{This
code is included in @segno{15}.}', making it easy to move back to
section 15 that includes it.

There's also a note following the code in the section above:
`@little{See also @segno{16}.}'.  This demonstrates how @TexiWEB{}
handles multiple sections that have the same name.  When a name that
corresponds to multiple sections is referenced, code from all the
sections with that name is substituted, in order of appearance.  The
first section with the name ends with a note listing the numbers of
all other same-named sections.  Later sections show their own numbers
in the left margin, but the number of the first section within angle
brackets, to make the first section easy to find.  For example, here's
another line of code for @refcode{Clear hash table entries,15}:

@begincode
@tabalign{}@textinleftmargin{@w{@segno{16} }}@nottex{16. }@value{LANG}Initialize hash table @smnumber{15}@value{RANG} @math{+}@value{IS}@cr
@tabalign{}@w{@i{hash}}@value{RARR}@w{@i{n}} = 0;@cr
@endcode format

Code segment references have one more feature: the ability to do special
macro replacements within the referenced code.  These replacements are
made on all words within the code segment referenced and recursively
within code segments that the segment references, and so on.  Word
prefixes as well as full words are replaced, as are even occurrences
within comments in the referenced code.  Replacements take place
regardless of case, and the case of the replacement mirrors the case of
the replaced text. This odd feature is useful for adapting a section of
code written for one library having a particular identifier prefix for
use in a different library with another identifier prefix.  For
instance, the reference `@value{LANG}BST types; bst @result{}
avl@value{RANG}' inserts the contents of the segment named `BST types',
replacing `bst' by `avl' wherever the former appears at the beginning of
a word.

When a @TexiWEB{} program is converted to C, conversion conceptually
begins from sections named for files; e.g., @value{LANG}@file{foo.c}
@smnumber{37}@value{RANG}.  Within these sections, all section references
are expanded, then references within those sections are expanded, and so
on.  When expansion is complete, the specified files are written out.

A final resource in reading a @TexiWEB{} is the index, which contains an
entry for the points of declaration of every section name, function,
type, structure, union, global variable, and macro.  Declarations within
functions are not indexed.

@references
@bibref{Knuth 1992}, ``How to read a @WEB{}''.

@node Code Conventions, Licenses, Reading the Code, Introduction
@section Code Conventions

Where possible, the @libavl{} source code complies to the requirements
imposed by ANSI/ISO C89 and C99.  Features present only in C99 are not
used. In addition, most of the GNU Coding Standards are followed.
Indentation style is an exception to the latter: in print, to conserve
vertical space, K&R indentation style is used instead of GNU style.

@references
@bibref{ISO 1990};
@bibref{ISO 1999};
@bibref{FSF 2001}, ``Writing C''.

@node Licenses,  , Code Conventions, Introduction
@section Licenses

This book is licensed under the GNU Free Documentation License,
version 1.2 or later.  The book includes complete source code for the
libavl libraries and related programs, so these are also released
under the GNU Free Documentation License.

The libraries in this book are also released under the following
license:

@<Library License@> =
@iftangle
/* libavl - library for manipulation of binary trees.
   Copyright (C) 1998, 1999, 2000, 2001, 2002, 2004 Free Software
   Foundation, Inc.
@end iftangle
@ifweave
/* GNU @libavl{} - library for manipulation of binary trees.
   Copyright @copyright{} 1998, 1999, 2000, 2001, 2002, 2004 Free
   Software Foundation, Inc.
@end ifweave

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
   02110-1301 USA.
*/

@

The programs in this book are also released under the following
license:

@<Program License@> =
@iftangle
/* libavl - library for manipulation of binary trees.
   Copyright (C) 1998, 1999, 2000, 2001, 2002, 2004 Free Software
   Foundation, Inc.
@end iftangle
@ifweave
/* GNU @libavl{} - library for manipulation of binary trees.
   Copyright @copyright{} 1998, 1999, 2000, 2001, 2002, 2004 Free
   Software Foundation, Inc.
@end ifweave

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along
   with this program; if not, write to the Free Software Foundation, Inc.,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

@
