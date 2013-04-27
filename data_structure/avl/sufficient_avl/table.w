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

@node The Table ADT, Search Algorithms, Introduction, Top
@chapter The Table ADT

Most of the chapters in this book implement a table structure as some
kind of binary tree, so it is important to understand what a table is
before we begin.  That is this chapter's purpose.

This chapter begins with a brief definition of the meaning of ``table''
for the purposes of this book, then moves on to describe in a more
formal way the interface of a table used by all of the tables in this
book.  The next chapter motivates the basic idea of a binary tree
starting from simple, everyday concepts.  Experienced programmers may
skip these chapters after skimming through the definitions below.

@menu
* Informal Definition::         
* Identifiers::                 
* Comparison Function::         
* Item and Copy Functions::     
* Memory Allocation::           
* Creation and Destruction::    
* Count::                       
* Insertion and Deletion::      
* Assertions::                  
* Traversers::                  
* Table Headers::               
* Additional Exercises for Tables::  
@end menu

@node Informal Definition, Identifiers, The Table ADT, The Table ADT
@section Informal Definition

If you've written even a few programs, you've probably noticed the
necessity for searchable collections of data.  Compilers search their
symbol tables for identifiers and network servers often search tables to
match up data with users.  Many applications with graphical user
interfaces deal with mouse and keyboard activity by searching a table of
possible actions.  In fact, just about every nontrivial program,
regardless of application domain, needs to maintain and search tables of
some kind.

In this book, the term ``table'' does not refer to any particular data
structure.  Rather, it is the name for a abstract data structure or ADT,
defined in terms of the operations that can be performed on it.  A table
ADT can be implemented in any number of ways.  Later chapters will show
how to implement tables in terms of various binary tree data structures.

The purpose of a table is to keep track of a collection of items, all of
the same type.  Items can be inserted into and deleted from a table,
with no arbitrary limit on the number of items in the table.  We can
also search a table for items that match a given item.

Other operations are supported, too.  Traversal is the most important of
these: all of the items in a table can be visited, in sorted order from
smallest to largest, or from largest to smallest.  Traversals can also
start from an item in the middle, or a newly inserted item, and move in
either direction.

The data in a table may be of any C type, but all the items in a table
must be of the same type.  Structure types are common.  Often, only part
of each data item is used in item lookup, with the rest for storage of
auxiliary information.  A table that contains two-part data items like
this is called a ``dictionary'' or an ``associative array''.  The part
of table data used for lookup, whether the table is a dictionary or not,
is the @dfn{key}.  In a dictionary, the remainder is the @dfn{value}.

Our tables cannot contain duplicates.  An attempt to insert an item into
a table that already contains a matching item will fail.

@exercise
Suggest a way to simulate the ability to insert duplicate items in a
table.

@answer
If the table is not a dictionary, then we can just include a count along
with each item recording the number of copies of it that would otherwise
be included in the table.  If the table is a dictionary, then each data
item can include a single key and possibly multiple values.
@end exercise

@node Identifiers, Comparison Function, Informal Definition, The Table ADT
@section Identifiers

In C programming it is necessary to be careful if we expect to avoid
clashes between our own names and those used by others.  Any identifiers
that we pick might also be used by others.  The usual solution is to
adopt a prefix that is applied to the beginning of every identifier that
can be visible in code outside a single source file.  In particular,
most identifiers in a library's public header files must be prefixed.

@libavl{} is a collection of mostly independent modules, each of which
implements the table ADT.  Each module has its own, different identifier
prefix.  Identifiers that begin with this prefix are reserved for any
use in source files that |#include| the module header file.  Also
reserved (for use as macro names) are identifiers that begin with the
all-uppercase version of the prefix.  Both sets of identifiers are also
reserved as external names@footnote{External names are identifiers
visible outside a single source file.  These are, mainly, non-|static|
functions and variables declared outside a function.} throughout any
program that uses the module.

In addition, all identifiers that begin with |libavl_| or |LIBAVL_| are
reserved for any use in source files that |#include| any @libavl{}
module.  Likewise, these identifiers are reserved as external names in
any program that uses any @libavl{} module.  This is primarily to allow
for future expansion, but see @ref{Memory Allocation} and
@value{libavlallocator} for a sample use.

The prefix used in code samples in this chapter is |tbl_|, short for
``table''.  This can be considered a generic substitute for the prefix
used by any of the table implementation.  All of the statements about
these functions here apply equally to all of the table implementation in
later chapters, except that the |tbl_| prefix must be replaced by the
prefix used by the chapter's table implementation.

@exercise
The following kinds of identifiers are among those that might appear in
a header file.  Which of them can be safely appear unprefixed?  Why?

@enumerate a
@item
Parameter names within function prototypes.

@item
Macro parameter names.

@item
Structure and union tags.

@item
Structure and union member names.
@end enumerate

@answer
Only macro parameter names can safely appear prefixless.  Macro
parameter names are significant only in a scope from their declaration
to the end of the macro definition.  Macro parameters may even be named
as otherwise reserved C keywords such as |int| and |while|, although
this is a bad idea.

The main reason that the other kinds of identifiers must be prefixed is
the possibility of a macro having the same name.  A surprise macro
expansion in the midst of a function prototype can lead to puzzling
compiler diagnostics.
@end exercise

@exercise
Suppose that we create a module for reporting errors.  Why is |err_| a
poorly chosen prefix for the module's identifiers?

@answer
The capitalized equivalent is |ERR_|, which is a reserved identifier.
All identifiers that begin with an uppercase @samp{E} followed by a
digit or capital letter are reserved in many contexts.  It is best to
avoid them entirely.  There are other identifiers to avoid, too.  The
article cited below has a handy list.

@references
@bibref{Brown 2001}.
@end exercise

@node Comparison Function, Item and Copy Functions, Identifiers, The Table ADT
@section Comparison Function

The C language provides the |void *| generic pointer for dealing with
data of unknown type.  We will use this type to allow our tables to
contain a wide range of data types.  This flexibility does keep the
table from working directly with its data.  Instead, the table's user
must provide means to operate on data items.  This section describes
the user-provided functions for comparing items, and the next section
describes two other kinds of user-provided functions.

There is more than one kind of generic algorithm for searching.  We can
search by comparison of keys, by digital properties of the keys, or by
computing a function of the keys.  In this book, we are only interested
in the first possibility, so we need a way to compare data items.  This
is done with a user-provided function compatible with
|tbl_comparison_func|, declared as follows:

@<Table function types@> = 
/* Function types. */
typedef int tbl_comparison_func (const void *tbl_a, const void *tbl_b, @
                                 void *tbl_param);
@

A comparison function takes two pointers to data items, here called |a|
and |b|, and compares their keys.  It returns a negative value if |a <
b|, zero if |a == b|, or a positive value if |a > b|.  It takes a third
parameter, here called |param|, which is user-provided.

A comparison function must work more or less like an arithmetic
comparison within the domain of the data.  This could be alphabetical
ordering for strings, a set of nested sort orders (e.g., sort first by
last name, with duplicates by first name), or any other comparison
function that behaves in a ``natural'' way.  A comparison function in
the exact class of those acceptable is called a @dfn{strict weak
ordering}, for which the exact rules are explained in
@value{strictweakorderingbrief}.

Here's a function that can be used as a comparison function for the case
that the @w{|void *|} pointers point to single |int|s:

@<Comparison function for |int|s@> =
/* Comparison function for pointers to |int|s. @
   |param| is not used. */
int @
compare_ints (const void *pa, const void *pb, void *param) @
{
  const int *a = pa;
  const int *b = pb;
  
  if (*a < *b) @
    return -1;
  else if (*a > *b) @
    return +1;
  else @
    return 0;
}

@

Here's another comparison function for data items that point to ordinary
C strings:

@c tested 2001/6/27
@<Anonymous@> =
/* Comparison function for strings. @
   |param| is not used. */
int @
compare_strings (const void *pa, const void *pb, void *param) @
{
  return strcmp (pa, pb);
}
@

@references
@bibref{FSF 1999}, node ``Defining the Comparison Function'';
@bibref{ISO 1998}, section 25.3, ``Sorting and related operations'';
@bibref{SGI 1993}, section ``Strict Weak Ordering''.

@exercise
In C, integers may be cast to pointers, including |void *|, and vice
versa.  Explain why it is not a good idea to use an integer cast to
|void *| as a data item.  When would such a technique would be
acceptable?

@answer
C does not guarantee that an integer cast to a pointer and back retains
its value.  In addition, there's a chance that an integer cast to a
pointer becomes the null pointer value.  This latter is not limited to
integers with value 0.  On the other hand, a nonconstant integer with
value 0 is not guaranteed to become a null pointer when cast.

Such a technique is only acceptable when the machine that the code is to
run on is known in advance.  At best it is inelegant.  At worst, it will
cause erroneous behavior.

@references
@bibref{Summit 1999}, section 5;
@bibref{ISO 1990}, sections 6.2.2.3 and 6.3.4;
@bibref{ISO 1999}, section 6.3.2.3.
@end exercise

@exercise
When would the following be an acceptable alternate definition for
|compare_ints()|?

@c tested 2000/7/8
@<Anonymous@> =
int @
compare_ints (const void *pa, const void *pb, void *param) @
{
  return *((int *) pa) - *((int *) pb);
}
@

@answer
This definition would only cause problems if the subtraction overflowed.
It would be acceptable if it was known that the values to be compared
would always be in a small enough range that overflow would never occur.

Here are two more ``clever'' definitions for |compare_ints()| that work
in all cases:

@c tested 2000/7/8
@<Anonymous@> =
@iftangle
/* Comparison function for pointers to |int|s. @
   |param| is not used. */
@end iftangle
/* Credit: GNU C library reference manual. */
int @
compare_ints (const void *pa, const void *pb, void *param) @
{
  const int *a = pa;
  const int *b = pb;
  
  return (*a > *b) - (*a < *b);
}
@

@c tested 2000/12/13
@<Anonymous@> =
int @
compare_ints (const void *pa, const void *pb, void *param) @
{
  const int *a = pa;
  const int *b = pb;
  
  return (*a < *b) ? -1 : (*a > *b);
}
@
@end exercise

@exercise
Could |strcmp()|, suitably cast, be used in place of
|compare_strings()|?

@answer
No.  Not only does |strcmp()| take parameters of different types (|const
char *|s instead of |const void *|s), our comparison functions take an
additional parameter.  Functions |strcmp()| and |compare_strings()|
are not compatible.
@end exercise

@exercise
Write a comparison function for data items that, in any particular
table, are character arrays of fixed length.  Among different tables,
the length may differ, so the third parameter to the function points to
a |size_t| specifying the length for a given table.

@answer
@c tested 2000/12/13
@<Anonymous@> =
int @
compare_fixed_strings (const void *pa, const void *pb, void *param) @
{
  return memcmp (pa, pb, *(size_t *) param);
}
@
@end exercise

@exercise* strictweakordering
For a comparison function |f()| to be a strict weak ordering, the
following must hold for all possible data items |a|, |b|, and |c|:

@itemize @bullet
@item
@emph{Irreflexivity:} For every |a|, |f(a, a) == 0|.

@item
@emph{Antisymmetry}: If |f(a, b) > 0|, then |f(b, a) < 0|.

@item
@emph{Transitivity}: If |f(a, b) > 0| and |f(b, c) > 0|, then |f(a, c) >
0|.

@item
@emph{Transitivity of equivalence}: If |f(a, b) == 0| and |f(b, c) ==
0|, then |f(a, c) == 0|.
@end itemize

@noindent
Consider the following questions that explore the definition of a strict
weak ordering.

@enumerate a
@item
Explain how |compare_ints()| above satisfies each point of the
definition.

@item
Can the standard C library function |strcmp()| be used for a strict weak
ordering?

@item
Propose an irreflexive, antisymmetric, transitive function that lacks
transitivity of equivalence.
@end enumerate

@answer a
Here's the blow-by-blow rundown:

@itemize @bullet
@item
Irreflexivity: |a == a| is always true for integers.

@item
Antisymmetry: If |a > b| then |b < a| for integers.

@item
Transitivity: If |a > b| and |b > c| then |a > c| for integers.

@item
Transitivity of equivalence: If |a == b| and |b == c|, then |a == c| for
integers.
@end itemize

@answer b
Yes, |strcmp()| satisfies all of the points above.

@answer c
Consider the domain of pairs of integers |(x0,x1)| with |x1 @>= x0|.
Pair |x|, composed of |(x0,x1)|, is less than pair |y|, composed of
|(y0,y1)|, if |x1 < y0|.  Alternatively, pair |x| is greater than pair
|y| if |x0 > y1|.  Otherwise, the pairs are equal.

This rule is irreflexive: for any given pair |a|, neither |a1 < a0| nor
|a0 > a1|, so |a == a|.  It is antisymmetic: |a > b| implies |a0 > b1|,
therefore |b1 < a0|, and therefore |b < a|.  It is transitive: |a > b|
implies |a0 > b1|, |b > c| implies |b0 > c1|, and we know that |b1 >
b0|, so |a0 > b1 > b0 > c1| and |a > c|.  It does not have transitivity
of equivalence: suppose that we have |a @= (1,2), b @= (2,3), c @=
(3,4)|.  Then, |a == b| and |b == c|, but not |a == c|.

A form of augmented binary search tree, called an ``interval tree'',
@emph{can} be used to efficiently handle this data type.  The
references have more details.

@references
@bibref{Cormen 1990}, section 15.3.
@end exercise

@exercise* ternarycompare
@libavl{} uses a ternary comparison function that returns a negative
value for |<|, zero for |@=|, positive for |>|.  Other libraries use
binary comparison functions that return nonzero for |<| or zero for
|@>=|.  Consider these questions about the differences:

@enumerate a
@item
Write a C expression, in terms of a binary comparison function |f()| and
two items |a| and |b|, that is nonzero if and only if |a == b| as
defined by |f()|.  Write a similar expression for |a > b|.

@item 
Write a binary comparison function ``wrapper'' for a @libavl{}
comparison function.

@item
Rewrite |bst_find()| based on a binary comparison function.  (You can
use the wrapper from above to simulate a binary comparison function.)
@end enumerate

@answer a
|!f(a, b) && !f(b, a)| and |!f(a, b) && f(b, a)|.

@answer b
@<Anonymous@> =
static int @
bin_cmp (const void *a, const void *b, void *param, bst_comparison_func tern) @
{
  return tern (a, b, param) < 0;
}
@

@answer c
This problem presents an interesting tradeoff.  We must choose between
sometimes calling the comparison function twice per item to convert our
|@>=| knowledge into |>| or |@=|, or always traversing all the way to a
leaf node, then making a final call to decide on equality.  The former
choice doesn't provide any new insight, so we choose the latter here.

In the code below, |p| traverses the tree and |q| keeps track of the
current candidate for a match to |item|.  If the item in |p| is less
than |item|, then the matching item, if any, must be in the left
subtree of |p|, and we leave |q| as it was.  Otherwise, the item in
|p| is greater than or equal to |p| and then matching item, if any, is
either |p| itself or in its right subtree, so we set |q| to the
potential match.  When we run off the bottom of the tree, we check
whether |q| is really a match by making one additional comparison.

@<Anonymous@> =
void *@
bst_find (const struct bst_table *tree, const void *item) @
{
  const struct bst_node *p;
  void *q;

  assert (tree != NULL && item != NULL);

  p = tree->bst_root;
  q = NULL;
  while (p != NULL)
    if (!bin_cmp (p->bst_data, item, tree->bst_param, tree->bst_compare)) @
      {@-
        q = p->bst_data;
        p = p->bst_link[0];
      }@+
    else @
      p = p->bst_link[1];

  if (q != NULL && !bin_cmp (item, q, tree->bst_param, tree->bst_compare))
    return q;
  else @
    return NULL;
}
@

@end exercise

@node Item and Copy Functions, Memory Allocation, Comparison Function, The Table ADT
@section Item and Copy Functions

Besides |tbl_comparison_func|, there are two kinds of functions used in
@libavl{} to manipulate item data:

@<Table function types@> +=
typedef void tbl_item_func (void *tbl_item, void *tbl_param);
typedef void *tbl_copy_func (void *tbl_item, void *tbl_param);

@

@noindent
Both of these function types receive a table item as their first
argument |tbl_item| and the |tbl_param| associated with the table as
their second argument.  This |tbl_param| is the same one passed as the
third argument to |tbl_comparison_func|.  @libavl{} will never pass a
null pointer as |tbl_item| to either kind of function.

A |tbl_item_func| performs some kind of action on |tbl_item|.  The
particular action that it should perform depends on the context in which
it is used and the needs of the calling program.

A |tbl_copy_func| creates and returns a new copy of |tbl_item|.  If
copying fails, then it returns a null pointer.

@node Memory Allocation, Creation and Destruction, Item and Copy Functions, The Table ADT
@section Memory Allocation

The standard C library functions |malloc()| and |free()| are the usual
way to obtain and release memory for dynamic data structures like
tables.  Most users will be satisfied if @libavl{} uses these routines
for memory management.  On the other hand, some users will want to
supply their own methods for allocating and freeing memory, perhaps even
different methods from table to table.  For these users' benefit, each
table is associated with a memory allocator, which provides functions
for memory allocation and deallocation.  This allocator has the same
form in each table implementation.  It looks like this:

@<Memory allocator@> =
#ifndef LIBAVL_ALLOCATOR
#define LIBAVL_ALLOCATOR
/* Memory allocator. */
struct libavl_allocator @
  {@-
    void *(*libavl_malloc) (struct libavl_allocator *, size_t libavl_size);
    void (*libavl_free) (struct libavl_allocator *, void *libavl_block);
  };@+
#endif

@

Members of |struct libavl_allocator| have the same interfaces as the
like-named standard C library functions, except that they are each
additionally passed a pointer to the |struct libavl_allocator *| itself
as their first argument.  The table implementations never call
|tbl_malloc()| with a zero size or |tbl_free()| with a null pointer
block.

The |struct libavl_allocator| type is shared between all of @libavl{}'s
modules, so its name begins with |libavl_|, not with the specific module
prefix that we've been representing generically here as |tbl_|.  This
makes it possible for a program to use a single allocator with multiple
@libavl{} table modules, without the need to declare instances of
different structures.

The default allocator is just a wrapper around |malloc()| and |free()|.
Here it is:

@<Default memory allocation functions@> =
/* Allocates |size| bytes of space using |malloc()|. @
   Returns a null pointer if allocation fails. */
void *@
tbl_malloc (struct libavl_allocator *allocator, size_t size) @
{
  assert (allocator != NULL && size > 0);
  return malloc (size);
}

/* Frees |block|. */
void @
tbl_free (struct libavl_allocator *allocator, void *block) @
{
  assert (allocator != NULL && block != NULL);
  free (block);
}

/* Default memory allocator that uses |malloc()| and |free()|. */
struct libavl_allocator tbl_allocator_default = @
  {@
    tbl_malloc, @
    tbl_free@
  };

@

The default allocator comes along with header file declarations:

@<Default memory allocator header@> =
/* Default memory allocator. */
extern struct libavl_allocator tbl_allocator_default;
void *tbl_malloc (struct libavl_allocator *, size_t);
void tbl_free (struct libavl_allocator *, void *);

@

@references
@bibref{FSF 1999}, nodes ``Malloc Examples'' and ``Changing Block
Size''.

@exercise libavlallocator
This structure is named with a |libavl_| prefix because it is shared
among all of @libavl{}'s module.  Other types are shared among @libavl{}
modules, too, such as |tbl_item_func|.  Why don't the names of these
other types also begin with |libavl_|?

@answer
It's not necessary, for reasons of the C definition of type
compatibility.  Within a C source file (more technically, a
``translation unit''), two structures are compatible only if they are
the same structure, regardless of how similar their members may be, so
hypothetical structures |struct bst_allocator| and |struct
avl_allocator| couldn't be mixed together without nasty-smelling casts.
On the other hand, prototyped function types are compatible if they have
compatible return types and compatible parameter types, so
|bst_item_func| and |avl_item_func| (say) are interchangeable.
@end exercise

@exercise tblallocatorabort
Supply an alternate allocator, still using |malloc()| and |free()|, that
prints an error message to |stderr| and aborts program execution when
memory allocation fails.

@answer
This allocator uses the same function |tbl_free()| as
|tbl_allocator_default|.

@c tested 2001/6/27
@<Aborting allocator@> =
/* Allocates |size| bytes of space using |malloc()|.  
   Aborts if out of memory. */
void *@
tbl_malloc_abort (struct libavl_allocator *allocator, size_t size) @
{
  void *block;

  assert (allocator != NULL && size > 0);

  block = malloc (size);
  if (block != NULL)
    return block;

  fprintf (stderr, "out of memory\n");
  exit (EXIT_FAILURE);
}

struct libavl_allocator tbl_allocator_abort = @
  {
    tbl_malloc_abort, @
    tbl_free@
  };
@
@end exercise

@exercise* moreargs
Some kinds of allocators may need additional arguments.  For instance,
if memory for each table is taken from a separate Apache-style ``memory
pool'', then a pointer to the pool structure is needed.  Show how this
can be done without modifying existing types.

@answer
Define a wrapper structure with |struct libavl_allocator| as its first
member.  For instance, a hypothetical pool allocator might look like
this:

@<Anonymous@> =
struct pool_allocator @
  {@-
    struct libavl_allocator suballocator;
    struct pool *pool;
  };@+

@

@noindent
Because a pointer to the first member of a structure is a pointer to the
structure itself, and vice versa, the allocate and free functions can
use a cast to access the larger |struct pool_allocator| given a pointer
to |struct libavl_allocator|.  If we assume the existence of functions
|pool_malloc()| and |pool_free()| to allocate and free memory within a
pool, then we can define the functions for |struct pool_allocator|'s
|suballocator| like this:

@<Anonymous@> =
void *@
pool_allocator_malloc (struct libavl_allocator *allocator, size_t size) @
{
  struct pool_allocator *pa = (struct pool_allocator *) allocator;
  return pool_malloc (pa->pool, size);
}

void @
pool_allocator_free (struct libavl_allocator *allocator, void *ptr) @
{
  struct pool_allocator *pa = (struct pool_allocator *) allocator;
  pool_free (pa->pool, ptr);
}

@

Finally, we want to actually allocate a table inside a pool.  The
following function does this.  Notice the way that it uses the pool to
store the |struct pool_allocator| as well; this trick comes in handy
sometimes.

@<Anonymous@> =
struct tbl_table *@
pool_allocator_tbl_create (struct tbl_pool *pool) @
{
  struct pool_allocator *pa = pool_malloc (pool, sizeof *pa);
  if (pa == NULL)
    return NULL;

  pa->suballocator.tbl_malloc = pool_allocator_malloc;
  pa->suballocator.tbl_free = pool_allocator_free;
  pa->pool = pool;
  return tbl_create (compare_ints, NULL, &pa->suballocator);
}
@
@end exercise

@node Creation and Destruction, Count, Memory Allocation, The Table ADT
@section Creation and Destruction

This section describes the functions that create and destroy tables.

@<Table creation function prototypes@> =
/* Table functions. */
struct tbl_table *tbl_create (tbl_comparison_func *, void *, @
                              struct libavl_allocator *);
struct tbl_table *tbl_copy (const struct tbl_table *, tbl_copy_func *,
                            tbl_item_func *, struct libavl_allocator *);
void tbl_destroy (struct tbl_table *, tbl_item_func *);
@

@itemize @bullet
@item 
|tbl_create()|: Creates and returns a new, empty table as a @w{|struct
tbl_table *|}.  The table is associated with the given arguments.  The
|void *| argument is passed as the third argument to the comparison
function when it is called.  If the allocator is a null pointer, then
|tbl_allocator_default| is used.

@item 
|tbl_destroy()|: Destroys a table.  During destruction, the
|tbl_item_func| provided, if non-null, is called once for every item in
the table, in no particular order.  The function, if provided, must not
invoke any table function or macro on the table being destroyed.

@item 
|tbl_copy()|: Creates and returns a new table with the same contents as
the existing table passed as its first argument. Its other three
arguments may all be null pointers.  

If a |tbl_copy_func| is provided, then it is used to make a copy of
each table item as it is inserted into the new table, in no particular
order (a @gloss{deep copy}).  Otherwise, the @w{|void *|} table items
are copied verbatim (a @gloss{shallow copy}).

If the table copy fails, either due to memory allocation failure or a
null pointer returned by the |tbl_copy_func|, |tbl_copy()| returns a
null pointer.  In this case, any provided |tbl_item_func| is called once
for each new item already copied, in no particular order.  

By default, the new table uses the same memory allocator as the existing
one.  If non-null, the |struct libavl_allocator *| given is used instead
as the new memory allocator.  To use the |tbl_allocator_default|
allocator, specify |&tbl_allocator_default| explicitly.
@end itemize

@node Count, Insertion and Deletion, Creation and Destruction, The Table ADT
@section Count

This function returns the number of items currently in a table.

@<Table count function prototype@> =
size_t tbl_count (const struct tbl_table *);
@

@noindent
The actual tables instead use a macro for implementation.

@exercise tblcount
Implement |tbl_count()| as a macro, on the assumption that |struct
tbl_table| keeps the number of items in the table in a |size_t| member
named |tbl_count|.

@answer 
Notice the cast to |size_t| in the macro definition below.  This
prevents the result of |tbl_count()| from being used as an lvalue (that
is, on the left side of an assignment operator), because the result of a
cast is never an lvalue.
 
@<Table count macro@> =
#define tbl_count(table) ((size_t) (table)->tbl_count)

@

Another way to get the same effect is to use the unary |+| operator,
like this:

@<Anonymous@> =
#define tbl_count(table) (+(table)->tbl_count)

@

@references
@bibref{ISO 1990}, section 6.3.4;
@bibref{Kernighan 1988}, section A7.5.
@end exercise 

@node Insertion and Deletion, Assertions, Count, The Table ADT
@section Insertion and Deletion

These functions insert and delete items in tables.  There is also a
function for searching a table without modifying it.

The design behind the insertion functions takes into account a couple of
important issues:

@itemize @bullet
@item 
What should happen if there is a matching item already in the tree?  If
the items contain only keys and no values, then there's no point in
doing anything.  If the items do contain values, then we might want to
leave the existing item or replace it, depending on the particular
circumstances.  The |tbl_insert()| and |tbl_replace()| functions are
handy in simple cases like these.

@item 
Occasionally it is convenient to insert one item into a table, then
immediately replace it by a different item that has identical key data.
For instance, if there is a good chance that a data item already exists
within a table, then it might make sense to insert data allocated as a
local variable into a table, then replace it by a dynamically allocated
copy if it turned out that the item wasn't already in the table.  That
way, we save the time required to make an additional copy of the item to
insert.  The |tbl_probe()| function allows for this kind of flexibility.
@end itemize

@<Table insertion and deletion function prototypes@> =
void **tbl_probe (struct tbl_table *, void *);
void *tbl_insert (struct tbl_table *, void *);
void *tbl_replace (struct tbl_table *, void *);
void *tbl_delete (struct tbl_table *, const void *);
void *tbl_find (const struct tbl_table *, const void *);
@

@noindent
Each of these functions takes a table to manipulate as its first
argument and a table item as its second argument, here called |table|
and |item|, respectively.  Both arguments must be non-null in all cases.
All but |tbl_probe()| return a table item or a null pointer.

@itemize @bullet
@item 
|tbl_probe()|: Searches in |table| for an item matching |item|.
If found, a pointer to the @w{|void *|} data item is returned.  Otherwise,
|item| is inserted into the table and a pointer to the copy within
the table is returned.  Memory allocation failure causes a null pointer
to be returned.

The pointer returned can be used to replace the item found or inserted
by a different item.  This must only be done if the replacement item has
the same position relative to the other items in the table as did the
original item.  That is, for existing item |e|, replacement item |r|,
and the table's comparison function |f()|, the return values of @w{|f(e,
x)|} and |f(r, x)| must have the same sign for every other item |x|
currently in the table.  Calling any other table function invalidates
the pointer returned and it must not be referenced subsequently.

@item
|tbl_insert()|: Inserts |item| into |table|, but not if a
matching item exists.  Returns a null pointer if successful or if a
memory allocation error occurs.  If a matching item already exists in
the table, returns that item.

@item
|tbl_replace()|: Inserts |item| into |table|, replacing and
returning any matching item.  Returns a null pointer if the item was
inserted but there was no matching item to replace, or if a memory
allocation error occurs.

@item
|tbl_delete()|: Removes from |table| and returns an item matching
|item|.  Returns a null pointer if no matching item exists in the
table.

@item
|tbl_find()|: Searches |table| for an item matching |item| and
returns any item found.  Returns a null pointer if no matching item
exists in the table.
@end itemize

@exercise nullinsert
Functions |tbl_insert()| and |tbl_replace()| return |NULL| in two very
different situations: an error or successful insertion.  Why is this not
necessarily a design mistake?

@answer
If a memory allocation function that never returns a null pointer is
used, then it is reasonable to use these functions.  For instance,
|tbl_allocator_abort| from @value{tblallocatorabort} is such an
allocator.
@end exercise

@exercise
Suggest a reason for disallowing insertion of a null item.

@answer
Among other reasons, |tbl_find()| returns a null pointer to indicate
that no matching item was found in the table.  Null pointers in the
table could therefore lead to confusing results.  It is better to
entirely prevent them from being inserted.
@end exercise

@exercise genericinsertreplace
Write generic implementations of |tbl_insert()| and |tbl_replace()| in
terms of |tbl_probe()|.

@answer
@<Table insertion convenience functions@> =
@iftangle
/* Inserts |item| into |table|.
   Returns |NULL| if |item| was successfully inserted @
   or if a memory allocation error occurred.
   Otherwise, returns the duplicate item. */
@end iftangle
void *@
tbl_insert (struct tbl_table *table, void *item) @
{
  void **p = tbl_probe (table, item);
  return p == NULL || *p == item ? NULL : *p;
}

@iftangle
/* Inserts |item| into |table|, replacing any duplicate item.
   Returns |NULL| if |item| was inserted without replacing a duplicate,
   or if a memory allocation error occurred.
   Otherwise, returns the item that was replaced. */
@end iftangle
void *@
tbl_replace (struct tbl_table *table, void *item) @
{
  void **p = tbl_probe (table, item);
  if (p == NULL || *p == item)
    return NULL;
  else @
    {@-
      void *r = *p;
      *p = item;
      return r;
    }@+
}

@
@end exercise

@node Assertions, Traversers, Insertion and Deletion, The Table ADT
@section Assertions

Sometimes an insertion or deletion must succeed because it is known in
advance that there is no way that it can fail.  For instance, we might
be inserting into a table from a list of items known to be unique, using
a memory allocator that cannot return a null pointer.  In this case, we
want to make sure that the operation succeeded, and abort if not,
because that indicates a program bug.  We also would like to be able to
turn off these tests for success in our production versions, because we
don't want them slowing down the code.

@<Table assertion function prototypes@> =
void tbl_assert_insert (struct tbl_table *, void *);
void *tbl_assert_delete (struct tbl_table *, void *);

@

These functions provide assertions for |tbl_insert()| and
|tbl_delete()|.  They expand, via macros, directly into calls to those
functions when |NDEBUG|, the same symbol used to turn off |assert()|
checks, is declared.  As for the standard C header
@value{LANG}assert.h@value{RANG}, header files for tables may be
included multiple times in order to turn these assertions on or off.

@exercise tblassert
Write a set of preprocessor directives for a table header file that
implement the behavior described in the final paragraph above.

@answer
Keep in mind that these directives have to be processed every time the
header file is included.  (Typical header file are designed to be
``idempotent'', i.e., processed by the compiler only on first
inclusion and skipped on any later inclusions, because some C
constructs cause errors if they are encountered twice during a
compilation.)

@<Table assertion function control directives@> =
/* Table assertion functions. */
#ifndef NDEBUG
#undef tbl_assert_insert
#undef tbl_assert_delete
#else
#define tbl_assert_insert(table, item) tbl_insert (table, item)
#define tbl_assert_delete(table, item) tbl_delete (table, item)
#endif
@

@references
@bibref{Summit 1999}, section 10.7.
@end exercise

@exercise genericassertions
Write a generic implementation of |tbl_assert_insert()| and
|tbl_assert_delete()| in terms of existing table functions.  Consider
the base functions carefully.  Why must we make sure that assertions are
always enabled for these functions?

@answer
|tbl_assert_insert()| must be based on |tbl_probe()|, because
|tbl_insert()| does not distinguish in its return value between
successful insertion and memory allocation errors.

Assertions must be enabled for these functions because we want them to
verify success if assertions were enabled at the point from which they
were called, not if assertions were enabled when the table was compiled.

Notice the parentheses around the assertion function names before.  The
parentheses prevent the macros by the same name from being expanded.  A
function-like macro is only expanded when its name is followed by a left
parenthesis, and the extra set of parentheses prevents this from being
the case.  Alternatively |#undef| directives could be used to achieve
the same effect.

@<Table assertion functions@> =
#undef NDEBUG
#include <assert.h>

@iftangle
/* Asserts that |tbl_insert()| succeeds at inserting |item| into |table|. */
@end iftangle
void @
(tbl_assert_insert) (struct tbl_table *table, void *item) @
{
  void **p = tbl_probe (table, item);
  assert (p != NULL && *p == item);
}

@iftangle
/* Asserts that |tbl_delete()| really removes |item| from |table|,
   and returns the removed item. */
@end iftangle
void *@
(tbl_assert_delete) (struct tbl_table *table, void *item) @
{
  void *p = tbl_delete (table, item);
  assert (p != NULL);
  return p;
}

@
@end exercise

@exercise
Why must |tbl_assert_insert()| not be used if the table's memory
allocator can fail?  (See also @value{nullinsert}.)

@answer
The |assert()| macro is meant for testing for design errors and
``impossible'' conditions, not runtime errors like disk input/output
errors or memory allocation failures.  If the memory allocator can fail,
then the |assert()| call in |tbl_assert_insert()| effectively does this.

@references
@bibref{Summit 1999}, section 20.24b.
@end exercise

@node Traversers, Table Headers, Assertions, The Table ADT
@section Traversers

A |struct tbl_traverser| is a table ``traverser'' that allows the items
in a table to be examined.  With a traverser, the items within a table
can be enumerated in sorted ascending or descending order, starting from
either end or from somewhere in the middle.

The user of the traverser declares its own instance of |struct
tbl_traverser|, typically as a local variable.  One of the traverser
constructor functions described below can be used to initialize it.
Until then, the traverser is invalid.  An invalid traverser must not be
passed to any traverser function other than a constructor.

Seen from the viewpoint of a table user, a traverser has only one
attribute: the current item.  The current item is either an item in the
table or the ``null item'', represented by a null pointer and not
associated with any item.

Traversers continue to work when their tables are modified.  Any number
of insertions and deletions may occur in the table without affecting the
current item selected by a traverser, with only a few exceptions:

@itemize @bullet
@item
Deleting a traverser's current item from its table invalidates the
traverser (even if the item is later re-inserted).

@item
Using the return value of |tbl_probe()| to replace an item in the table
invalidates all traversers with that item current, unless the
replacement item has the same key data as the original item (that is,
the table's comparison function returns 0 when the two items are
compared).

@item
Similarly, |tbl_t_replace()| invalidates all @emph{other} traversers
with the same item selected, unless the replacement item has the same
key data.

@item 
Destroying a table with |tbl_destroy()| invalidates all of that table's
traversers.
@end itemize

There is no need to destroy a traverser that is no longer needed.  An
unneeded traverser can simply be abandoned.

@menu
* Constructors::                
* Manipulators::                
@end menu

@node Constructors, Manipulators, Traversers, Traversers
@subsection Constructors

These functions initialize traversers.  A traverser must be initialized
with one of these functions before it is passed to any other traverser
function.

@<Traverser constructor function prototypes@> =
/* Table traverser functions. */
void tbl_t_init (struct tbl_traverser *, struct tbl_table *);
void *tbl_t_first (struct tbl_traverser *, struct tbl_table *);
void *tbl_t_last (struct tbl_traverser *, struct tbl_table *);
void *tbl_t_find (struct tbl_traverser *, struct tbl_table *, void *);
void *tbl_t_insert (struct tbl_traverser *, struct tbl_table *, void *);
void *tbl_t_copy (struct tbl_traverser *, const struct tbl_traverser *);
@

@noindent
All of these functions take a traverser to initialize as their first
argument, and most take a table to associate the traverser with as their
second argument.  These arguments are here called |trav| and |table|.
All, except |tbl_t_init()|, return the item to which |trav| is
initialized, using a null pointer to represent the null item.  None of
the arguments to these functions may ever be a null pointer.

@itemize @bullet
@item
|tbl_t_init()|: Initializes |trav| to the null item in |table|.

@item
|tbl_t_first()|: Initializes |trav| to the least-valued item in |table|.
If the table is empty, then |trav| is initialized to the null item.

@item
|tbl_t_last()|: Same as |tbl_t_first()|, for the greatest-valued item in
|table|.

@item
|tbl_t_find()|: Searches |table| for an item matching the one given.  If
one is found, initializes |trav| with it.  If none is found, initializes
|trav| to the null item.

@item
|tbl_t_insert()|: Attempts to insert the given item into |table|.  If it
is inserted succesfully, |trav| is initialized to its location.  If it
cannot be inserted because of a duplicate, the duplicate item is set as
|trav|'s current item.  If there is a memory allocation error, |trav| is
initialized to the null item.

@item
|tbl_t_copy()|: Initializes |trav| to the same table and item as a
second valid traverser.  Both arguments pointing to the same valid
traverser is valid and causes no change in either.
@end itemize

@node Manipulators,  , Constructors, Traversers
@subsection Manipulators

These functions manipulate valid traversers.

@<Traverser manipulator function prototypes@> =
void *tbl_t_next (struct tbl_traverser *);
void *tbl_t_prev (struct tbl_traverser *);
void *tbl_t_cur (struct tbl_traverser *);
void *tbl_t_replace (struct tbl_traverser *, void *);
@

Each of these functions takes a valid traverser, here called |trav|, as
its first argument, and returns a data item.  All but |tbl_t_replace()|
can also return a null pointer that represents the null item.  All
arguments to these functions must be non-null pointers.

@itemize @bullet
@item
|tbl_t_next()|: Advances |trav| to the next larger item in its table.
If |trav| was at the null item in a nonempty table, then the smallest
item in the table becomes current. If |trav| was already at the greatest
item in its table or the table is empty, the null item becomes current.
Returns the new current item.

@item
|tbl_t_prev()|: Advances |trav| to the next smaller item in its table.
If |trav| was at the null item in a nonempty table, then the greatest
item in the table becomes current. If |trav| was already at the lowest
item in the table or the table is empty, the null item becomes current.
Returns the new current item.

@item
|tbl_t_cur()|: Returns |trav|'s current item.

@item
|tbl_t_replace()|: Replaces the data item currently selected in |trav|
by the one provided.  The replacement item is subject to the same
restrictions as for the same replacement using |tbl_probe()|.  The item
replaced is returned.  If the null item is current, the behavior is
undefined.
@end itemize

Seen from the outside, the traverser treats the table as a circular
arrangement of
@ifnotinfo
items:

@center @image{trav-circ}

@noindent
@end ifnotinfo
@ifinfo
items, with the null item at the top of the circle and the least-valued
item just clockwise of it, then the next-lowest-valued item, and so on
until the greatest-valued item is just counterclockwise of the null
item.
@end ifinfo
Moving clockwise in the circle is equivalent, under our traverser, to
moving to the next item with |tbl_t_next()|.  Moving counterclockwise
is equivalent to moving to the previous item with |tbl_t_prev()|.

An equivalent view is that the traverser treats the table as a linear
arrangement of nodes:

@center @image{trav-line}

@noindent From this perspective, nodes are arranged from least to
greatest in left to right order, and the null node lies in the middle as
a connection between the least and greatest nodes.  Moving to the next
node is the same as moving to the right and moving to the previous node
is motion to the left, except where the null node is concerned.

@node Table Headers, Additional Exercises for Tables, Traversers, The Table ADT
@section Table Headers

Here we gather together in one place all of the types and prototypes for
a generic table.

@<Table types@> =
@<Table function types@>
@<Memory allocator@>
@<Default memory allocator header@>
@

@<Table function prototypes@> =
@<Table creation function prototypes@>
@<Table insertion and deletion function prototypes@>
@<Table assertion function prototypes@>
@<Table count macro@>
@<Traverser constructor function prototypes@>
@<Traverser manipulator function prototypes@>
@

@noindent
All of our tables fit the specification given in @value{tblcount}, so
@<Table count macro@> is directly included above.

@node Additional Exercises for Tables,  , Table Headers, The Table ADT
@section Additional Exercises

@exercise*
Compare and contrast the design of @libavl{}'s tables with that of the
|set| container in the C++ Standard Template Library.

@answer
Both tables and |set|s store sorted arrangements of unique items.  Both
require a strict weak ordering on the items that they contain.
@libavl{} uses ternary comparison functions whereas the STL uses binary
comparison functions (see @value{ternarycompare}).

The description of tables here doesn't list any particular speed
requirements for operations, whereas STL |set|s are constrained in the
complexity of their operations.  It's worth noting, however, that the
@libavl{} implementation of AVL and RB trees meet all of the STL
complexity requirements, for their equivalent operations, except one.
The exception is that |set| methods |begin()| and |rbegin()| must have
constant-time complexity, whereas the equivalent @libavl{} functions
|*_t_first()| and |*_t_last()| on AVL and RB trees have logarithmic complexity.

@libavl{} traversers and STL iterators have similar semantics.  Both
remain valid if new items are inserted, and both remain valid if old
items are deleted, unless it's the iterator's current item that's
deleted.

The STL has a more complete selection of methods than @libavl{} does
of table functions, but many of the additional ones (e.g.,
|distance()| or |erase()| each with two iterators as arguments) can be
implemented easily in terms of existing @libavl{} functions.  These
might benefit from optimization possible with specialized
implementations, but may not be worth it.  The SGI/HP implementation
of the STL does not contain any such optimization.

@references
@bibref{ISO 1998}, sections 23.1, 23.1.2, and 23.3.3.
@end exercise

@exercise
What is the smallest set of table routines such that all of the other
routines can be implemented in terms of the interfaces of that set as
defined above?

@answer
The nonessential functions are:

@itemize @bullet
@item
|tbl_probe()|, |tbl_insert()|, and |tbl_replace()|, which can be
implemented in terms of |tbl_t_insert()| and |tbl_t_replace()|.

@item
|tbl_find()|, which can be implemented in terms of |tbl_t_find()|.

@item
|tbl_assert_insert()| and |tbl_assert_delete()|.

@item
|tbl_t_first()| and |tbl_t_last()|, which can be implemented with
|tbl_t_init()| and |tbl_t_next()|.
@end itemize

If we allow it to know what allocator was used for the original table,
which is, strictly speaking, cheating, then we can also implement
|tbl_copy()| in terms of |tbl_create()|, |tbl_t_insert()|, and
|tbl_destroy()|.  Under similar restrictions we can also implement
|tbl_t_prev()| and |tbl_t_copy()| in terms of |tbl_t_init()| and
|tbl_t_next()|, though in a very inefficient way.
@end exercise
