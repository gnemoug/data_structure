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

@node Preface, Introduction, Top, Top
@unnumbered Preface

Early in 1998, I wanted an AVL tree library for use in writing GNU
PSPP.  At the time, few of these were available on the Internet.
Those that were had licenses that were not entirely satisfactory for
inclusion in GNU software.  I resolved to write my own.  I sat down
with Knuth's @cite{The Art of Computer Programming} and did so.  The
result was the earliest version of @libavl{}.  As I wrote it, I
learned valuable lessons about implementing algorithms for binary
search trees, and covered many notebook pages with scribbled diagrams.

Later, I decided that what I really wanted was a similar library for
threaded AVL trees, so I added an implementation to @libavl{}.  Along
the way, I ended up having to relearn many of the lessons I'd already
painstakingly uncovered in my earlier work.  Even later, I had much
the same experience in writing code for right-threaded AVL trees and
red-black trees, which was done as much for my own education as any
intention of using the code in real software.

In late 1999, I contributed a chapter on binary search trees and
balanced trees to a book on programming in C.  This again required a
good deal of duplication of effort as I rediscovered old techniques.
By now I was beginning to see the pattern, so I decided to document
once and for all the algorithms I had chosen and the tradeoffs I had
made.  Along the way, the project expanded in scope several times.

You are looking at the results.  I hope you find that it is as useful
for reading and reference as I found that writing it was enjoyable for
me.  As I wrote later chapters, I referred less and less to my other
reference books and more and more to my own earlier chapters, so I
already know that it can come in handy for me.

Please feel free to copy and distribute this book, in accordance with
the license agreement.  If you make multiple printed copies, consider
contacting me by email first to check whether there are any
late-breaking corrections or new editions in the pipeline.

@menu
* Acknowledgements::            
* Contacting the Author::       
@end menu

@node Acknowledgements, Contacting the Author, Preface, Preface
@section Acknowledgements

@libavl{} has grown into its current state over a period of years.
During that time, many people have contributed advice, bug reports,
and occasional code fragments.  I have attempted to individually
acknowledge all of these people, along with their contributions, in
the @file{NEWS} and @file{ChangeLog} files included with the @libavl{}
source distribution.  Without their help, @libavl{} would not be what
it is today.  If you believe that you should be listed in one of these
files, but are not, please contact me.

Many people have indirectly contributed by providing computer science
background and software infrastructure, without which @libavl{} would
not have been possible at all.  For a partial list, please see
@file{THANKS} in the @libavl{} source distribution.

Special thanks are due to Erik Goodman of the A.@: H.@: Case Center for
Computer-Aided Engineering and Manufacturing at Michigan State
University for making it possible for me to receive MSU honors credit
for rewriting @libavl{} as a literate program, and to Dann Corbit for
his invaluable suggestions during development.

@node Contacting the Author,  , Acknowledgements, Preface
@section Contacting the Author

@libavl{}, including this book, the source code, the TexiWEB software,
and related programs, was written by Ben Pfaff, who welcomes your
feedback.  Please send @libavl{}-related correspondence,
including bug reports and suggestions for improvement, to him at
@email{blp@@gnu.org}.

Ben received his B.S.@: in electrical engineering from Michigan State
University in May 2001.  He is now studying for a Ph.D.@: in computer
science at Stanford University as a Stanford Graduate Fellow.

Ben's personal webpage is at @uref{http://benpfaff.org/}, where you can
find a list of his current projects, including the status of @libavl{}
test releases.  You can also find him hanging out in the Internet
newsgroup @t{comp.lang.c}.
