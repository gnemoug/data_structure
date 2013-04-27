@c GNU libavl - library for manipulation of binary trees.
@c Copyright (C) 1998, 1999, 2000, 2001, 2002, 2004 Free Software
@c Foundation, Inc.
@c Permission is granted to copy, distribute and/or modify this document
@c under the terms of the GNU Free Documentation License, Version 1.2
@c or any later version published by the Free Software Foundation;
@c with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
@c A copy of the license is included in the section entitled "GNU
@c Free Documentation License".

@<Clear hash table entries@> =
for (i = 0; i < hash->m; i++)
  hash->entry[i] = NULL;
@

@<Initialize hash table@> =
hash->m = 13;
@<Clear hash table entries@>
@

@<Initialize hash table@> +=
hash->n = 0;
@
