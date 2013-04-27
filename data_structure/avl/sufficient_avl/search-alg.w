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

@node Search Algorithms, Binary Search Trees, The Table ADT, Top
@chapter Search Algorithms

In @libavl{}, we are primarily concerned with binary search trees and
balanced binary trees.  If you're already familiar with these concepts,
then you can move right into the code, starting from the next chapter.
But if you're not, then a little motivation and an explanation of
exactly what a binary search tree is can't hurt.  That's the goal of
this chapter.

More particularly, this chapter concerns itself with algorithms for
searching.  Searching is one of the core problems in organizing a table.
As it will turn out, arranging a table for fast searching also
facilitates some other table features.

@menu
* Sequential Search::           
* Sequential Search with Sentinel::  
* Sequential Search of Ordered Array::  
* Sequential Search of Ordered Array with Sentinel::  
* Binary Search of Ordered Array::  
* Binary Search Tree in Array::  
* Dynamic Lists::               
@end menu

@node Sequential Search, Sequential Search with Sentinel, Search Algorithms, Search Algorithms
@section Sequential Search

Suppose that you have a bunch of things (books, magazines, CDs, @dots{})
in a pile, and you're looking for one of them.  You'd probably start by
looking at the item at the top of the pile to check whether it was the
one you were looking for.  If it wasn't, you'd check the next item down
the pile, and so on, until you either found the one you wanted or ran
out of items.

In computer science terminology, this is a @gloss{sequential search}.
It is easy to implement sequential search for an array or a linked list.
If, for the moment, we limit ourselves to items of type |int|, we can
write a function to sequentially search an array like this:

@<Sequentially search an array of |int|s@> =
/* Returns the smallest |i| such that |array[i] == key|, @
   or |-1| if |key| is not in |array[]|. 
   |array[]| must be an array of |n int|s. */
int @
seq_search (int array[], int n, int key) @
{
  int i;

  for (i = 0; i < n; i++)
    if (array[i] == key)
      return i;
  return -1;
}

@

We can hardly hope to improve on the data requirements, space, or
complexity of simple sequential search, as they're about as good as we
can want.  But the speed of sequential search leaves something to be
desired.  The next section describes a simple modification of the
sequential search algorithm that can sometimes lead to big
improvements in performance.

@references
@bibref{Knuth 1998b}, algorithm 6.1S;
@bibref{Kernighan 1976}, section 8.2;
@bibref{Cormen 1990}, section 11.2;
@bibref{Bentley 2000}, sections 9.2 and 13.2, appendix 1.

@exercise
Write a simple test framework for |seq_search()|.  It should read sample
data from |stdin| and collect them into an array, then search for each
item in the array in turn and compare the results to those expected,
reporting any discrepancies on |stdout| and exiting with an appropriate
return value.  You need not allow for the possibility of duplicate input
values and may limit the maximum number of input values.

@answer
The following program can be improved in many ways.  However, we will
implement a much better testing framework later, so this is fine for
now.

@(seq-test.c@> =
@<Program License@>
#include <stdio.h>

#define MAX_INPUT 1024

@<Sequentially search an array of |int|s@>

int @
main (void) @
{
  int array[MAX_INPUT];
  int n, i;

  for (n = 0; n < MAX_INPUT; n++)
    if (scanf ("%d", &array[n]) != 1)
      break;
  
  for (i = 0; i < n; i++) @
    {@-
      int result = seq_search (array, n, array[i]);
      if (result != i)
        printf ("seq_search() returned %d looking for %d - expected %d\n",
                result, array[i], i);
    }@+

  return 0;
}
@
@end exercise

@node Sequential Search with Sentinel, Sequential Search of Ordered Array, Sequential Search, Search Algorithms
@section Sequential Search with Sentinel

Try to think of some ways to improve the speed of sequential search.  It
should be clear that, to speed up a program, it pays to concentrate on
the parts that use the most time to begin with.  In this case, it's the
loop.

Consider what happens each time through the loop:

@enumerate 1
@item
The loop counter |i| is incremented and compared against |n|.

@item
|array[i]| is compared against |key|.
@end enumerate

If we could somehow eliminate one of these comparisons, the loop might
be a lot faster.  So, let's try@dots{} why do we need step 1?  It's
because, otherwise, we might run off the end of |array[]|, causing
undefined behavior, which is in turn because we aren't sure that |key|
is in |array[]|.  If we knew that |key| was in |array[]|, then we could
skip step 1.

But, hey!@: we @emph{can} ensure that the item we're looking for is in
the array.  How?  By putting a copy of it at the end of the array.  This
copy is called a @gloss{sentinel}, and the search technique as a whole is
called @gloss{sequential search with sentinel}.  Here's the code:

@<Sequentially search an array of |int|s using a sentinel@> =
/* Returns the smallest |i| such that |array[i] == key|, @
   or |-1| if |key| is not in |array[]|. 
   |array[]| must be an modifiable array of |n int|s @
   with room for a |(n + 1)|th element. */
int @
seq_sentinel_search (int array[], int n, int key) @
{
  int *p;

  array[n] = key;
  for (p = array; *p != key; p++)
    /* Nothing to do. */;
  return p - array < n ? p - array : -1;
}

@

Notice how the code above uses a pointer, |int *p|, rather than a
counter |i| as in @<Sequentially search an array of |int|s@> earlier.
For the most part, this is simply a style preference: for iterating
through an array, C programmers usually prefer pointers to array
indexes.  Under older compilers, code using pointers often compiled into
faster code as well, but modern C compilers usually produce the same
code whether pointers or indexes are used.

The |return| statement in this function uses two somewhat advanced
features of C: the conditional or ``ternary'' operator |?:| and
pointer arithmetic.  The former is a bit like an expression form of an
|if| statement.  The expression |a ? b : c| first evaluates |a|.
Then, if @w{|a != 0|}, |b| is evaluated and the expression takes that
value.  Otherwise, |a == 0|, |c| is evaluated, and the result is the
expression's value.

Pointer arithmetic is used in two ways here.  First, the expression
|p++| acts to advance |p| to point to the next |int| in |array|.  This
is analogous to the way that |i++| would increase the value of an
integer or floating point variable |i| by one.  Second, the expression
|p - array| results in the ``difference'' between |p| and |array|, i.e.,
the number of |int| elements between the locations to which they point.
For more information on these topics, please consult a good C reference,
such as @bibref{Kernighan 1988}.

Searching with a sentinel requires that the array be modifiable and
large enough to hold an extra element.  Sometimes these are inherently
problematic---the array may not be modifiable or it might be too
small---and sometimes they are problems because of external
circumstances.  For instance, a program with more than one concurrent
@gloss{thread} cannot modify a shared array for sentinel search
without expensive locking.

Sequential sentinel search is an improvement on ordinary sequential
search, but as it turns out there's still room for
improvement---especially in the runtime for unsuccessful searches, which
still always take |n| comparisons.  In the next section, we'll see one
technique that can reduce the time required for unsuccessful searches,
at the cost of longer runtime for successful searches.

@references
@bibref{Knuth 1998b}, algorithm 6.1Q;
@bibref{Cormen 1990}, section 11.2;
@bibref{Bentley 2000}, section 9.2.

@node Sequential Search of Ordered Array, Sequential Search of Ordered Array with Sentinel, Sequential Search with Sentinel, Search Algorithms
@section Sequential Search of Ordered Array

Let's jump back to the pile-of-things analogy from the beginning of this
chapter (@pxref{Sequential Search}).  This time, suppose that instead of
being in random order, the pile you're searching through is ordered on
the property that you're examining; e.g., magazines sorted by
publication date, if you're looking for, say, the July 1988 issue.

Think about how this would simplify searching through the pile.  Now you
can sometimes tell that the magazine you're looking for isn't in the
pile before you get to the bottom, because it's not between the
magazines that it otherwise would be.  On the other hand, you still
might have to go through the entire pile if the magazine you're looking
for is newer than the newest magazine in the pile (or older than the
oldest, depending on the ordering that you chose).

Back in the world of computers, we can apply the same idea to searching
a sorted array:

@<Sequentially search a sorted array of |int|s@> =
/* Returns the smallest |i| such that |array[i] == key|, @
   or |-1| if |key| is not in |array[]|. 
   |array[]| must be an array of |n| |int|s sorted in ascending order. */
int @
seq_sorted_search (int array[], int n, int key) @
{
  int i;

  for (i = 0; i < n; i++)
    if (key <= array[i])
      return key == array[i] ? i : -1;

  return -1;
}

@

At first it might be a little tricky to see exactly how
|seq_sorted_search()| works, so we'll work through a few examples.
Suppose that |array[]| has the four elements |{3, 5, 6, 8}|, so that |n|
is 4.  If |key| is 6, then the first time through the loop the |if|
condition is |6 <= 3|, or false, so the loop repeats with |i == 1|.  The
second time through the loop we again have a false condition, |6 <= 5|,
and the loop repeats again.  The third time the |if| condition, |6 <=
6|, is true, so control passes to the |if| statement's dependent
|return|.  This |return| verifies that |6 == 6| and returns |i|, or |2|,
as the function's value.

On the other hand, suppose |key| is 4, a value not in |array[]|.  For
the first iteration, when |i| is 0, the |if| condition, |4 <= 3|, is
false, but in the second iteration we have |4 <= 5|, which is true.
However, this time |key == array[i]| is |4 == 5|, or false, so |-1| is
returned.

@references
@bibref{Sedgewick 1998}, program 12.4.

@node Sequential Search of Ordered Array with Sentinel, Binary Search of Ordered Array, Sequential Search of Ordered Array, Search Algorithms
@section Sequential Search of Ordered Array with Sentinel

When we implemented sequential search in a sorted array, we lost the
benefits of having a sentinel.  But we can reintroduce a sentinel in the
same way we did before, and obtain some of the same benefits.  It's
pretty clear how to proceed:

@<Sequentially search a sorted array of |int|s using a sentinel@> =
/* Returns the smallest |i| such that |array[i] == key|, @
   or |-1| if |key| is not in |array[]|.  
   |array[]| must be an modifiable array of |n int|s, @
   sorted in ascending order,
   with room for a |(n + 1)|th element at the end. */
int @
seq_sorted_sentinel_search (int array[], int n, int key) @
{
  int *p;

  array[n] = key;
  for (p = array; *p < key; p++)
    /* Nothing to do. */;
  return p - array < n && *p == key ? p - array : -1;
}

@

With a bit of additional cleverness we can eliminate one objection to
this sentinel approach.  Suppose that instead of using the value being
searched for as the sentinel value, we used the maximum possible value
for the type in question.  If we did this, then we could use almost the
same code for searching the array.

The advantage of this approach is that there would be no need to modify
the array in order to search for different values, because the sentinel
is the same value for all searches.  This eliminates the potential
problem of searching an array in multiple contexts, due to nested
searches, threads, or signals, for instance.  (In the code below, we
will still put the sentinel into the array, because our generic test
program won't know to put it in for us in advance, but in real-world
code we could avoid the assignment.)

We can easily write code for implementation of this technique:

@<Sequentially search a sorted array of |int|s using a sentinel (2)@> =
/* Returns the smallest |i| such that |array[i] == key|, @
   or |-1| if |key| is not in |array[]|.  
   |array[]| must be an array of |n int|s, @
   sorted in ascending order, 
   with room for an |(n + 1)|th element to set to |INT_MAX|. */
int @
seq_sorted_sentinel_search_2 (int array[], int n, int key) @
{
  int *p;

  array[n] = INT_MAX;
  for (p = array; *p < key; p++)
    /* Nothing to do. */;
  return p - array < n && *p == key ? p - array : -1;
}

@

@exercise
When can't the largest possible value for the type be used as a sentinel?

@answer
Some types don't have a largest possible value; e.g., arbitrary-length
strings.
@end exercise

@node Binary Search of Ordered Array, Binary Search Tree in Array, Sequential Search of Ordered Array with Sentinel, Search Algorithms
@section Binary Search of Ordered Array

At this point we've squeezed just about all the performance we can out
of sequential search in portable C.  For an algorithm that searches
faster than our final refinement of sequential search, we'll have to
reconsider our entire approach.

What's the fundamental idea behind sequential search?  It's that we
examine array elements in order.  That's a fundamental limitation: if
we're looking for an element in the middle of the array, we have to
examine every element that comes before it.  If a search algorithm is
going to be faster than sequential search, it will have to look at fewer
elements.

One way to look at search algorithms based on repeated comparisons is to
consider what we learn about the array's content at each step.  Suppose
that |array[]| has |n| elements in sorted order, without duplicates,
that |array[j]| contains |key|, and that we are trying to learn the
value |j|.  In sequential search, we learn only a little about the data
set from each comparison with |array[i]|: either |key == array[i]| so
that |i == j|, or |key != array[i]| so that |i != j| and therefore |j >
i|.  As a result, we eliminate only one possibility at each step.

Suppose that we haven't made any comparisons yet, so that we know
nothing about the contents of |array[]|.  If we compare |key| to
|array[i]| for arbitrary |i| such that |0 @<= i < n|, what do we learn?  There are three possibilities:

@itemize @bullet
@item
|key < array[i]|: Now we know that |key < array[i] < array[i + 1] < |
@math{@cdots{}} | < |@w{|array[n - 1]|.}@footnote{This sort of notation
means very different things in C and mathematics.  In mathematics,
writing |a < b < c| asserts both of the relations |a < b| and |b < c|,
whereas in C, it expresses the evaluation of |a < b|, then the
comparison of the 0 or 1 result to the value of |c|.  In mathematics
this notation is invaluable, but in C it is rarely meaningful.  As a
result, this book uses this notation only in the mathematical sense.}
Therefore, |0 @<= j < i|.

@item 
|key == array[i]|: We're done: |j == i|.

@item
|key > array[i]|: Now we know that |key > array[i] > array[i - 1] > |
@math{@cdots{}} | > array[0]|.  Therefore, |i < j < n|.
@end itemize

So, after one step, if we're not done, we know that |j > i| or that |j <
i|.  If we're equally likely to be looking for each element in
|array[]|, then the best choice of |i| is |n / 2|: for that value, we
eliminate about half of the possibilities either way.  (If |n| is odd,
we'll round down.)

After the first step, we're back to essentially the same situation: we
know that |key| is in |array[j]| for some |j| in a range of about
|n / 2|.  So we can repeat the same process.  Eventually, we will either
find |key| and thus |j|, or we will eliminate all the possibilities.

Let's try an example.  For simplicity, let |array[]| contain the values
100 through 114 in numerical order, so that |array[i]| is |100 + i| and
|n| is |15|.  Suppose further that |key| is 110.  The steps that we'd go
through to find |j| are described below.  At each step, the facts are
listed: the known range that |j| can take, the selected value of |i|,
the results of comparing |key| to |array[i]|, and what was learned from
the comparison.

@enumerate
@item 
|0 @<= j @<= 14|: |i| becomes |(0 + 14) / 2 @= 7|. |110 > array[i] @=
107|, so now we know that |j > 7|.

@item 
|8 @<= j @<= 14|: |i| becomes |(8 + 14) / 2 @= 11|. |110 < array[i] @=
111|, so now we know that @w{|j < 11|}.

@item
|8 @<= j @<= 10|: |i| becomes |(8 + 10) / 2 @= 9|. |110 > array[i] @=
109|, so now we know that |j > 9|.

@item
|10 @<= j @<= 10|: |i| becomes |(10 + 10) / 2 @= 10|.  |110 @= array[i]
@= 110|, so we're done and @w{|i @= j @= 10|}.
@end enumerate

In case you hadn't yet figured it out, this technique is called
@gloss{binary search}.  We can make an initial C implementation pretty
easily:

@<Binary search of ordered array@> =
/* Returns the offset within |array[]| of an element equal to |key|, @
   or |-1| if |key| is not in |array[]|.  
   |array[]| must be an array of |n| |int|s sorted in ascending order. */
int @
binary_search (int array[], int n, int key) @
{
  int min = 0;
  int max = n - 1;

  while (max >= min) @
    {@-
      int i = (min + max) / 2;
      if (key < array[i]) @
        max = i - 1;
      else if (key > array[i]) @
        min = i + 1;
      else @
        return i;
    }@+

  return -1;
}

@

The maximum number of comparisons for a binary search in an array of |n|
elements is about
@tex 
$\log_2n$, 
@end tex
@ifnottex 
log2(n), 
@end ifnottex
as opposed to a maximum of |n| comparisons for sequential search.  For
moderate to large values of |n|, this is a lot better.  

On the other hand, for small values of |n|, binary search may actually
be slower because it is more complicated than sequential search.  We
also have to put our array in sorted order before we can use binary
search.  Efficiently sorting an |n|-element array takes time
proportional to
@tex 
$n\log_2n$ 
@end tex
@ifnottex 
n * log2(n) 
@end ifnottex
for large |n|.  So binary search is preferred if |n| is large enough
(see the answer to @value{benchmarkbrief} for one typical value) and if
we are going to do enough searches to justify the cost of the initial
sort.

Further small refinements are possible on binary search of an ordered
array.  Try some of the exercises below for more information.

@c FIXME: exercise: assembly instructions for linear search

@references
@bibref{Knuth 1998b}, algorithm 6.2.1B;
@bibref{Kernighan 1988}, section 3.3;
@bibref{Bentley 2000}, chapters 4 and 5, section 9.3, appendix 1;
@bibref{Sedgewick 1998}, program 12.6.

@exercise
Function |binary_search()| above uses three local variables: |min| and
|max| for the ends of the remaining search range and |i| for its
midpoint.  Write and test a binary search function that uses only two
variables: |i| for the midpoint as before and |m| representing the
width of the range on either side of |i|.  You may require the
existence of a dummy element just before the beginning of the array.
Be sure, if so, to specify what its value should be.

@answer
Knuth's name for this procedure is ``uniform binary search.''  The code
below is an almost-literal implementation of his Algorithm U.  The fact
that Knuth's arrays are 1-based, but C arrays are 0-based, accounts for
most of the differences.

The code below uses |for (;;)| to assemble an ``infinite'' loop, a
common C idiom.

@<Uniform binary search of ordered array@> =
/* Returns the offset within |array[]| of an element equal to |key|, @
   or |-1| if |key| is not in |array[]|.  
   |array[]| must be an array of |n| |int|s sorted in ascending order, @
   with |array[-1]| modifiable. */
int @
uniform_binary_search (int array[], int n, int key) @
{
  int i = (n + 1) / 2 - 1;
  int m = n / 2;

  array[-1] = INT_MIN;
  for (;;) @
    {@-
      if (key < array[i]) @
        {@-
          if (m == 0)
            return -1;
          i -= (m + 1) / 2;
          m /= 2;
        }@+
      else if (key > array[i]) @
        {@-
          if (m == 0)
            return -1;
          i += (m + 1) / 2;
          m /= 2;
        }@+
      else @
        return i >= 0 ? i : -1;
    }@+
}

@

@references
@bibref{Knuth 1998b}, section 6.2.1, Algorithm U.
@end exercise

@exercise
The standard C library provides a function, |bsearch()|, for searching
ordered arrays.  Commonly, |bsearch()| is implemented as a binary
search, though ANSI C does not require it.  Do the following:

@enumerate a
@item 
Write a function compatible with the interface for |binary_search()|
that uses |bsearch()| ``under the hood.''  You'll also have to write an
additional callback function for use by |bsearch()|.

@item
Write and test your own version of |bsearch()|, implementing it using a
binary search.  (Use a different name to avoid conflicts with the C
library.)
@end enumerate

@answer a
This actually uses |blp_bsearch()|, implemented in part (b) below, in
order to allow that function to be tested.  You can replace the
reference to |blp_bsearch()| by |bsearch()| without problem.

@<Binary search using |bsearch()|@> =
@<blp's implementation of |bsearch()|@>

/* Compares the |int|s pointed to by |pa| and |pb| and returns positive
   if |*pa > *pb|, negative if |*pa < *pb|, or zero if |*pa == *pb|. */
static int @
compare_ints (const void *pa, const void *pb) @
{
  const int *a = pa;
  const int *b = pb;

  if (*a > *b) @
    return 1;
  else if (*a < *b) @
    return -1;
  else @
    return 0;
}

/* Returns the offset within |array[]| of an element equal to |key|, @
   or |-1| if |key| is not in |array[]|.  
   |array[]| must be an array of |n| |int|s sorted in ascending order. */
static int @
binary_search_bsearch (int array[], int n, int key) @
{
  int *p = blp_bsearch (&key, array, n, sizeof *array, compare_ints);
  return p != NULL ? p - array : -1;
}

@

@answer b
This function is named using the author of this book's initials.  Note
that the implementation below assumes that |count|, a |size_t|, won't
exceed the range of an |int|.  Some systems provide a type called
@b{ssize_t} for this purpose, but we won't assume that here.  (|long| is
perhaps a better choice than |int|.)

@<blp's implementation of |bsearch()|@> =
/* Plug-compatible with standard C library |bsearch()|. */
static void *@
blp_bsearch (const void *key, const void *array, size_t count,
             size_t size, int (*compare) (const void *, const void *)) @
{
  int min = 0;
  int max = count;

  while (max >= min) @
    {@-
      int i = (min + max) / 2;
      void *item = ((char *) array) + size * i;
      int cmp = compare (key, item);

      if (cmp < 0) @
        max = i - 1;
      else if (cmp > 0) @
        min = i + 1;
      else @
        return item;
    }@+

  return NULL;
}
@

@end exercise

@exercise
An earlier exercise presented a simple test framework for
|seq_search()|, but now we have more search functions.  Write a test
framework that will handle all of them presented so far.  Add code for
timing successful and unsuccessful searches.  Let the user specify, on
the command line, the algorithm to use, the size of the array to search,
and the number of search iterations to run.

@answer
Here's an outline of the entire program:

@(srch-test.c@> =
@<Program License@>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

@<Search functions@>
@<Array of search functions@>

@<Timer functions@>
@<Search test functions@>
@<Search test main program@>
@

We need to include all the search functions we're going to use:

@<Search functions@> =
@<Sequentially search an array of |int|s@>
@<Sequentially search an array of |int|s using a sentinel@>
@<Sequentially search a sorted array of |int|s@>
@<Sequentially search a sorted array of |int|s using a sentinel@>
@<Sequentially search a sorted array of |int|s using a sentinel (2)@>
@<Binary search of ordered array@>
@<Uniform binary search of ordered array@>
@<Binary search using |bsearch()|@>
@<Cheating search@>
@

We need to make a list of the search functions.  We start by defining
the array's element type:

@<Array of search functions@> =
/* Description of a search function. */
struct search_func @
  {@-
    const char *name;
    int (*search) (int array[], int n, int key);
  };@+

@

Then we define the list as an array:

@<Array of search functions@> +=
/* Array of all the search functions we know. */
struct search_func search_func_tab[] = @
  {@-
    {"seq_search()", seq_search},
    {"seq_sentinel_search()", seq_sentinel_search},
    {"seq_sorted_search()", seq_sorted_search},
    {"seq_sorted_sentinel_search()", seq_sorted_sentinel_search},
    {"seq_sorted_sentinel_search_2()", seq_sorted_sentinel_search_2},
    {"binary_search()", binary_search},
    {"uniform_binary_search()", uniform_binary_search},
    {"binary_search_bsearch()", binary_search_bsearch},
    {"cheat_search()", cheat_search},
  };@+

/* Number of search functions. */
const size_t n_search_func = sizeof search_func_tab / sizeof *search_func_tab;
@

We've added previously unseen function |cheat_search()| to the array.
This is a function that ``cheats'' on the search because it knows that
we are only going to search in a array such that |array[i] == i|.  The
purpose of |cheat_search()| is to allow us to find out how much of the
search time is overhead imposed by the framework and the function
calls and how much is actual search time.  Here's |cheat_search()|:

@<Cheating search@> =
/* Cheating search function that knows that |array[i] == i|.
   |n| must be the array size and |key| the item to search for.
   |array[]| is not used.
   Returns the index in |array[]| where |key| is found, @
   or |-1| if |key| is not in |array[]|. */
int @
cheat_search (int array[], int n, int key) @
{
  return key >= 0 && key < n ? key : -1;
}

@

We're going to need some functions for timing operations.  First, a
function to ``start'' a timer:

@<Timer functions@> =
/* ``Starts'' a timer by recording the current time in |*t|. */
static void @
start_timer (clock_t *t) @
{
  clock_t now = clock ();
  while (now == clock ())
    /* Do nothing. */;
  *t = clock ();
}

@

Function |start_timer()| waits for the value returned by |clock()| to
change before it records the value.  On systems with a slow timer
(such as PCs running MS-DOS, where the clock ticks only 18.2 times per
second), this gives more stable timing results because it means that
timing always starts near the beginning of a clock tick.

We also need a function to ``stop'' the timer and report the results:

@<Timer functions@> +=
/* Prints the elapsed time since |start|, set by |start_timer()|. */
static void @
stop_timer (clock_t start) @
{
  clock_t end = clock ();
  
  printf ("%.2f seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
}

@

The value reported by |clock()| can ``wrap around'' to zero from a
large value.  |stop_timer()| does not allow for this possibility.

We will write three tests for the search functions.  The first of these
just checks that the search function works properly:

@<Search test functions@> =
/* Tests that |f->search| returns |expect| when called to search for @
   |key| within |array[]|, 
   which has |n| elements such that |array[i] == i|. */
static void @
test_search_func_at (struct search_func *f, int array[], int n,
                     int key, int expect) @
{
  int result = f->search (array, n, key);
  if (result != expect)
    printf ("%s returned %d looking for %d - expected %d\n",
            f->name, result, key, expect);
}

/* Tests searches for each element in |array[]| having |n| elements such that @
   |array[i] == i|,
   and some unsuccessful searches too, all using function |f->search|. */
static void @
test_search_func (struct search_func *f, int array[], int n) @
{
  static const int shouldnt_find[] = {INT_MIN, -20, -1, INT_MAX};
  int i;

  printf ("Testing integrity of %s...  ", f->name);
  fflush (stdout);
  
  /* Verify that the function finds values that it should. */
  for (i = 0; i < n; i++)
    test_search_func_at (f, array, n, i, i);

  /* Verify that the function doesn't find values it shouldn't. */
  for (i = 0; i < (int) (sizeof shouldnt_find / sizeof *shouldnt_find); i++)
    test_search_func_at (f, array, n, shouldnt_find[i], -1);

  printf ("done\n");
}

@

The second test function finds the time required for searching for
elements in the array:

@<Search test functions@> +=
/* Times a search for each element in |array[]| having |n| elements such that
   |array[i] == i|, repeated |n_iter| times, using function |f->search|. */
static void @
time_successful_search (struct search_func *f, int array[], int n, int n_iter) @
{
  clock_t timer;

  printf ("Timing %d sets of successful searches...  ", n_iter);
  fflush (stdout);

  start_timer (&timer);
  while (n_iter-- > 0) @
    {@-
      int i;

      for (i = 0; i < n; i++)
        f->search (array, n, i);
    }@+
  stop_timer (timer);
}

@

The last test function finds the time required for searching for
values that don't appear in the array:

@<Search test functions@> +=
/* Times |n| search for elements not in |array[]| having |n| elements such that
   |array[i] == i|, repeated |n_iter| times, using function |f->search|. */
static void @
time_unsuccessful_search (struct search_func *f, int array[], @
                          int n, int n_iter) @
{
  clock_t timer;

  printf ("Timing %d sets of unsuccessful searches...  ", n_iter);
  fflush (stdout);

  start_timer (&timer);
  while (n_iter-- > 0) @
    {@-
      int i;

      for (i = 0; i < n; i++)
        f->search (array, n, -i);
    }@+
  stop_timer (timer);
}

@

Here's the main program:

@<Search test main program@> =
@<Usage printer for search test program@>

@<String to integer function |stoi()|@>

int @
main (int argc, char *argv[]) @
{
  struct search_func *f;        /* Search function. */
  int *array, n;                /* Array and its size. */
  int n_iter;                   /* Number of iterations. */

  @<Parse search test command line@>
  @<Initialize search test array@>
  @<Run search tests@>
  @<Clean up after search tests@>

  return 0;
}
@

@<Parse search test command line@> =
if (argc != 4) @
  usage ();

{
  long algorithm = stoi (argv[1]) - 1;
  if (algorithm < 0 || algorithm > (long) n_search_func) @
    usage ();
  f = &search_func_tab[algorithm];
}

n = stoi (argv[2]);
n_iter = stoi (argv[3]);
if (n < 1 || n_iter < 1) @
  usage ();

@

@<String to integer function |stoi()|@> =
/* |s| should point to a decimal representation of an integer.
   Returns the value of |s|, if successful, or 0 on failure. */
static int @
stoi (const char *s) @
{
  long x = strtol (s, NULL, 10);
  return x >= INT_MIN && x <= INT_MAX ? x : 0;
}

@

When reading the code below, keep in mind that some of our algorithms
use a sentinel at the end and some use a sentinel at the beginning, so
we allocate two extra integers and take the middle part.

@<Initialize search test array@> =
array = malloc ((n + 2) * sizeof *array);
if (array == NULL) @
  {@-
    fprintf (stderr, "out of memory\n");
    exit (EXIT_FAILURE);
  }@+
array++;

{
  int i;

  for (i = 0; i < n; i++)
    array[i] = i;
}

@

@<Run search tests@> =
test_search_func (f, array, n);
time_successful_search (f, array, n, n_iter);
time_unsuccessful_search (f, array, n, n_iter);

@

@<Clean up after search tests@> =
free (array - 1);
@

@<Usage printer for search test program@> =
/* Prints a message to the console explaining how to use this program. */
static void @
usage (void) @
{
  size_t i;

  fputs ("usage: srch-test <algorithm> <array-size> <n-iterations>\n"
         "where <algorithm> is one of the following:\n", stdout);

  for (i = 0; i < n_search_func; i++) 
    printf ("        %u for %s\n", (unsigned) i + 1, search_func_tab[i].name);

  fputs ("      <array-size> is the size of the array to search, and\n"
         "      <n-iterations> is the number of times to iterate.\n", stdout);

  exit (EXIT_FAILURE);
}
@
@end exercise

@exercise benchmark
Run the test framework from the previous exercise on your own system for
each algorithm.  Try different array sizes and compiler optimization
levels.  Be sure to use enough iterations to make the searches take at
least a few seconds each.  Analyze the results: do they make sense?
Try to explain any apparent discrepancies.

@answer
Here are the results on the author's computer, a Pentium II at 233 MHz,
using GNU C 2.95.2, for 1024 iterations using arrays of size 1024 with
no optimization.  All values are given in seconds rounded to tenths.

@multitable @columnfractions .33 .33 .33
@item @strong{Function}
@tab @strong{Successful searches}
@tab @strong{Unsuccessful searches}

@item |seq_search()|                    @tab 18.4       @tab 36.3
@item |seq_sentinel_search()|           @tab 16.5       @tab 32.8
@item |seq_sorted_search()|             @tab 18.6       @tab  0.1
@item |seq_sorted_sentinel_search()|    @tab 16.4       @tab  0.2
@item |seq_sorted_sentinel_search_2()|  @tab 16.6       @tab  0.2
@item |binary_search()|                 @tab  1.3       @tab  1.2
@item |uniform_binary_search()|         @tab  1.1       @tab  1.1
@item |binary_search_bsearch()|         @tab  2.6       @tab  2.4
@item |cheat_search()|                  @tab  0.1       @tab  0.1
@end multitable

Results of similar tests using full optimization were as follows:

@multitable @columnfractions .33 .33 .33
@item @strong{Function}
@tab @strong{Successful searches}
@tab @strong{Unsuccessful searches}

@item |seq_search()|                    @tab 6.3        @tab 12.4
@item |seq_sentinel_search()|           @tab 4.8        @tab 9.4
@item |seq_sorted_search()|             @tab 9.3        @tab 0.1
@item |seq_sorted_sentinel_search()|    @tab 4.8        @tab 0.2
@item |seq_sorted_sentinel_search_2()|  @tab 4.8        @tab 0.2
@item |binary_search()|                 @tab 0.7        @tab 0.5
@item |uniform_binary_search()|         @tab 0.7        @tab 0.6
@item |binary_search_bsearch()|         @tab 1.5        @tab 1.2
@item |cheat_search()|                  @tab 0.1        @tab 0.1
@end multitable

Observations:

@itemize @bullet
@item
In general, the times above are about what we might expect them to be:
they decrease as we go down the table.  

@item
Within sequential searches, the sentinel-based searches have better
search times than non-sentinel searches, and other search
characteristics (whether the array was sorted, for instance) had little
impact on performance.

@item 
Unsuccessful searches were very fast for sorted sequential searches,
but the particular test set used always allowed such searches to
terminate after a single comparison.  For other test sets one might
expect these numbers to be similar to those for unordered sequential
search.

@item
Either of the first two forms of binary search had the best overall
performance.  They also have the best performance for successful
searches and might be expected to have the best performance for
unsuccessful searches in other test sets, for the reason given before.

@item
Binary search using the general interface |bsearch()| was significantly
slower than either of the other binary searches, probably because of the
cost of the extra function calls.  Items that are more expensive to
compare (for instance, long text strings) might be expected to show less
of a penalty.
@end itemize

Here are the results on the same machine for 1,048,576 iterations on arrays of
size 8 with full optimization:

@multitable @columnfractions .33 .33 .33
@item @strong{Function}
@tab @strong{Successful searches}
@tab @strong{Unsuccessful searches}

@item |seq_search()|                    @tab 1.7        @tab 2.0
@item |seq_sentinel_search()|           @tab 1.7        @tab 2.0
@item |seq_sorted_search()|             @tab 2.0        @tab 1.1
@item |seq_sorted_sentinel_search()|    @tab 1.9        @tab 1.1
@item |seq_sorted_sentinel_search_2()|  @tab 1.8        @tab 1.2
@item |binary_search()|                 @tab 2.5        @tab 1.9
@item |uniform_binary_search()|         @tab 2.4        @tab 2.3
@item |binary_search_bsearch()|         @tab 4.5        @tab 3.9
@item |cheat_search()|                  @tab 0.7        @tab 0.7
@end multitable

For arrays this small, simple algorithms are the clear winners.  The
additional complications of binary search make it slower.  Similar
patterns can be expected on most architectures, although the ``break
even'' array size where binary search and sequential search are equally
fast can be expected to differ.
@end exercise

@node Binary Search Tree in Array, Dynamic Lists, Binary Search of Ordered Array, Search Algorithms
@section Binary Search Tree in Array

Binary search is pretty fast.  Suppose that we wish to speed it up
anyhow.  Then, the obvious speed-up targets in @<Binary search of
ordered array@> above are the |while| condition and the calculations
determining values of |i|, |min|, and |max|.  If we could eliminate these,
we'd have an incrementally faster technique, all else being equal.  And,
as it turns out, we @emph{can} eliminate both of them, the former by use
of a sentinel and the latter by precalculation.

Let's consider precalculating |i|, |min|, and |max| first.  Think about
the nature of the choices that binary search makes at each step.
Specifically, in @<Binary search of ordered array@> above, consider the
dependence of |min| and |max| upon |i|.  Is it ever possible for |min|
and |max| to have different values for the same |i| and |n|?

The answer is no.  For any given |i| and |n|, |min| and |max| are fixed.
This is important because it means that we can represent the entire
``state'' of a binary search of an |n|-element array by the single
variable |i|.  In other words, if we know |i| and |n|, we know all the
choices that have been made to this point and we know the two possible
choices of |i| for the next step.

This is the key insight in eliminating calculations.  We can use an
array in which the items are labeled with the next two possible choices.

An example is indicated.  Let's continue with our example of an array
containing the 16 integers 100 to 115.  We define an entry in the array
to contain the item value and the array index of the item to examine next
for search values smaller and larger than the item:

@<Binary search tree entry@> =
/* One entry in a binary search tree stored in an array. */
struct binary_tree_entry @
  {@-
    int value;          /* This item in the binary search tree. */
    int smaller;        /* Array index of next item for smaller targets. */
    int larger;         /* Array index of next item for larger targets. */
  };@+

@

Of course, it's necessary to fill in the values for |smaller| and
|larger|.  A few moments' reflection should allow you to figure out one
method for doing so.  Here's the full array, for reference:

@<Anonymous@> =
const struct binary_tree_entry bins[16] = @
  {@-
    {100, 15, 15}, @
    {101, 0, 2}, @
    {102, 15, 15}, @
    {103, 1, 5}, @
    {104, 15, 15},
    {105, 4, 6}, @
    {106, 15, 15}, @
    {107, 3, 11}, @
    {108, 15, 15}, @
    {109, 8, 10},
    {110, 15, 15}, @
    {111, 9, 13}, @
    {112, 15, 15}, @
    {113, 12, 14}, @
    {114, 15, 15},
    {0, 0, 0},
  };@+
@

For now, consider only |bins[]|'s first 15 rows.  Within these rows,
the first column is |value|, the item value, and the second and third
columns are |smaller| and |larger|, respectively.  Values 0 through 14
for |smaller| and |larger| indicate the index of the next element of
|bins[]| to examine.  Value 15 indicates ``element not found''.
Element |array[15]| is not used for storing data.

Try searching for |key == 110| in |bins[]|, starting from element 7,
the midpoint:

@enumerate 
@item
|i == 7: 110 > bins[i].value == 107|, so let |i = bins[i].larger|, or
11.

@item
|i == 11: 110 < bins[i].value == 111|, so let |i = bins[i].smaller|,
or 10.

@item
|i == 10: 110 == bins[i].value == 110|, so we're done.
@end enumerate

We can implement this search in C code.  The function uses the common C
idiom of writing |for (;;)| for an ``infinite'' loop:

@<Search of binary search tree stored as array@> =
/* Returns |i| such that |array[i].value == key|, @
   or -1 if |key| is not in |array[]|. 
   |array[]| is an array of |n| elements forming a binary search tree, 
   with its root at |array[n / 2]|, @
   and space for an |(n + 1)|th value at the end. */
int @
binary_search_tree_array (struct binary_tree_entry array[], int n, @
                          int key) @
{
  int i = n / 2;

  array[n].value = key;
  for (;;)
    if (key > array[i].value) @
      i = array[i].larger;
    else if (key < array[i].value) @
      i = array[i].smaller;
    else @
      return i != n ? i : -1;
}

@

Examination of the code above should reveal the purpose of |bins[15]|.
It is used as a sentinel value, allowing the search to always terminate
without the use of an extra test on each loop iteration.

The result of augmenting binary search with ``pointer'' values like
|smaller| and |larger| is called a @gloss{binary search tree}.

@exercise
Write a function to automatically initialize |smaller| and |larger|
within |bins[]|.

@answer
Here is one easy way to do it:

@<Initialize |smaller| and |larger| within binary search tree@> =
/* Initializes |larger| and |smaller| within range |min|@dots{}|max| of @
   |array[]|, 
   which has |n| real elements plus a |(n + 1)|th sentinel element. */
int @
init_binary_tree_array (struct binary_tree_entry array[], int n, @
                        int min, int max) @
{
  if (min <= max) @
    {@-
      /* The `|+ 1|' is necessary because the tree root must be at |n / 2|,
         and on the first call we have |min == 0| and |max == n - 1|. */
      int i = (min + max + 1) / 2;
      array[i].larger = init_binary_tree_array (array, n, i + 1, max);
      array[i].smaller = init_binary_tree_array (array, n, min, i - 1);
      return i;
    }@+
  else @
    return n;
}

@
@end exercise

@exercise
Write a simple automatic test program for |binary_search_tree_array()|.
Let the user specify the size of the array to test on the command line.
You may want to use your results from the previous exercise.

@answer
@(bin-ary-test.c@> = 
@<Program License@>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>

@<Binary search tree entry@>
@<Search of binary search tree stored as array@>
@<Initialize |smaller| and |larger| within binary search tree@>
@<Show @file{bin-ary-test} usage message@>
@<String to integer function |stoi()|@>
@<Main program to test |binary_search_tree_array()|@>
@

@<Main program to test |binary_search_tree_array()|@> =
int @
main (int argc, char *argv[]) @
{
  struct binary_tree_entry *array;
  int n, i;

  /* Parse command line. */
  if (argc != 2) @
    usage ();
  n = stoi (argv[1]);
  if (n < 1) @
    usage ();

  /* Allocate memory. */
  array = malloc ((n + 1) * sizeof *array);
  if (array == NULL) @
    {@-
      fprintf (stderr, "out of memory\n");
      return EXIT_FAILURE;
    }@+

  /* Initialize array. */
  for (i = 0; i < n; i++)
    array[i].value = i;
  init_binary_tree_array (array, n, 0, n - 1);

  /* Test successful and unsuccessful searches. */
  for (i = -1; i < n; i++) @
    {@-
      int result = binary_search_tree_array (array, n, i);
      if (result != i)
        printf ("Searching for %d: expected %d, but received %d\n",
                i, i, result);
    }@+

  /* Clean up. */
  free (array);

  return EXIT_SUCCESS;
}
@

@<Show @file{bin-ary-test} usage message@> =
/* Print a helpful usage message and abort execution. */
static void @
usage (void) @
{
  fputs ("Usage: bin-ary-test <array-size>\n"
         "where <array-size> is the size of the array to test.\n",
         stdout);
  exit (EXIT_FAILURE);
}

@
@end exercise

@node Dynamic Lists,  , Binary Search Tree in Array, Search Algorithms
@section Dynamic Lists

Up until now, we've considered only lists whose contents are fixed and
unchanging, that is, @gloss{static} lists.  But in real programs, many
lists are @gloss{dynamic}, with their contents changing rapidly and
unpredictably.  For the case of dynamic lists, we need to reconsider
some of the attributes of the types of lists that we've
examined.@footnote{These uses of the words ``static'' and ``dynamic''
are different from their meanings in the phrases ``static allocation''
and ``dynamic allocation.''  @xref{Glossary}, for more details.}

Specifically, we want to know how long it takes to insert a new element
into a list and to remove an existing element from a list.  Think about
it for each type of list examined so far:

@c FIXME: Dann Corbit:
@c Mention heaps, skip lists, hash tables.

@table @b
@item Unordered array

Adding items to the list is easy and fast, unless the array grows too
large for the block and has to be copied into a new area of memory. Just
copy the new item to the end of the list and increase the size by one.

Removing an item from the list is almost as simple. If the item to
delete happens to be located at the very end of the array, just reduce
the size of the list by one. If it's located at any other spot, you must
also copy the element that is located at the very end onto the location
that the deleted element used to occupy.

@item Ordered array

In terms of inserting and removing elements, ordered arrays are
mechanically the same as unordered arrays.  The difference is that
insertions and deletions can only be at one end of the array if the item
in question is the largest or smallest in the list.  The practical
upshot is that dynamic ordered arrays are only efficient if items are
added and removed in sorted order.

@item Binary search tree

Insertions and deletions are where binary search trees have their chance
to shine.  Insertions and deletions are efficient in binary search trees
whether they're made at the beginning, middle, or end of the lists.
@end table

Clearly, binary search trees are superior to ordered or unordered arrays
in situations that require insertion and deletion in random positions.
But insertion and deletion operations in binary search trees require a
bit of explanation if you've never seen them before.  This is what the
next chapter is for, so read on.
