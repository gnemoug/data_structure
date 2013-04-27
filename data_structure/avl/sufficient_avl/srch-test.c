/* Produced by texiweb from libavl.w. */

/* libavl - library for manipulation of binary trees.
   Copyright (C) 1998, 1999, 2000, 2001, 2002, 2004 Free Software
   Foundation, Inc.

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

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

/* Returns the smallest |i| such that |array[i] == key|,
   or |-1| if |key| is not in |array[]|.
   |array[]| must be an array of |n int|s. */
int
seq_search (int array[], int n, int key)
{
  int i;

  for (i = 0; i < n; i++)
    if (array[i] == key)
      return i;
  return -1;
}

/* Returns the smallest |i| such that |array[i] == key|,
   or |-1| if |key| is not in |array[]|.
   |array[]| must be an modifiable array of |n int|s
   with room for a |(n + 1)|th element. */
int
seq_sentinel_search (int array[], int n, int key)
{
  int *p;

  array[n] = key;
  for (p = array; *p != key; p++)
    /* Nothing to do. */;
  return p - array < n ? p - array : -1;
}

/* Returns the smallest |i| such that |array[i] == key|,
   or |-1| if |key| is not in |array[]|.
   |array[]| must be an array of |n| |int|s sorted in ascending order. */
int
seq_sorted_search (int array[], int n, int key)
{
  int i;

  for (i = 0; i < n; i++)
    if (key <= array[i])
      return key == array[i] ? i : -1;

  return -1;
}

/* Returns the smallest |i| such that |array[i] == key|,
   or |-1| if |key| is not in |array[]|.
   |array[]| must be an modifiable array of |n int|s,
   sorted in ascending order,
   with room for a |(n + 1)|th element at the end. */
int
seq_sorted_sentinel_search (int array[], int n, int key)
{
  int *p;

  array[n] = key;
  for (p = array; *p < key; p++)
    /* Nothing to do. */;
  return p - array < n && *p == key ? p - array : -1;
}

/* Returns the smallest |i| such that |array[i] == key|,
   or |-1| if |key| is not in |array[]|.
   |array[]| must be an array of |n int|s,
   sorted in ascending order,
   with room for an |(n + 1)|th element to set to |INT_MAX|. */
int
seq_sorted_sentinel_search_2 (int array[], int n, int key)
{
  int *p;

  array[n] = INT_MAX;
  for (p = array; *p < key; p++)
    /* Nothing to do. */;
  return p - array < n && *p == key ? p - array : -1;
}

/* Returns the offset within |array[]| of an element equal to |key|,
   or |-1| if |key| is not in |array[]|.
   |array[]| must be an array of |n| |int|s sorted in ascending order. */
int
binary_search (int array[], int n, int key)
{
  int min = 0;
  int max = n - 1;

  while (max >= min)
    {
      int i = (min + max) / 2;
      if (key < array[i])
        max = i - 1;
      else if (key > array[i])
        min = i + 1;
      else
        return i;
    }

  return -1;
}

/* Returns the offset within |array[]| of an element equal to |key|,
   or |-1| if |key| is not in |array[]|.
   |array[]| must be an array of |n| |int|s sorted in ascending order,
   with |array[-1]| modifiable. */
int
uniform_binary_search (int array[], int n, int key)
{
  int i = (n + 1) / 2 - 1;
  int m = n / 2;

  array[-1] = INT_MIN;
  for (;;)
    {
      if (key < array[i])
        {
          if (m == 0)
            return -1;
          i -= (m + 1) / 2;
          m /= 2;
        }
      else if (key > array[i])
        {
          if (m == 0)
            return -1;
          i += (m + 1) / 2;
          m /= 2;
        }
      else
        return i >= 0 ? i : -1;
    }
}

/* Plug-compatible with standard C library |bsearch()|. */
static void *
blp_bsearch (const void *key, const void *array, size_t count,
             size_t size, int (*compare) (const void *, const void *))
{
  int min = 0;
  int max = count;

  while (max >= min)
    {
      int i = (min + max) / 2;
      void *item = ((char *) array) + size * i;
      int cmp = compare (key, item);

      if (cmp < 0)
        max = i - 1;
      else if (cmp > 0)
        min = i + 1;
      else
        return item;
    }

  return NULL;
}

/* Compares the |int|s pointed to by |pa| and |pb| and returns positive
   if |*pa > *pb|, negative if |*pa < *pb|, or zero if |*pa == *pb|. */
static int
compare_ints (const void *pa, const void *pb)
{
  const int *a = pa;
  const int *b = pb;

  if (*a > *b)
    return 1;
  else if (*a < *b)
    return -1;
  else
    return 0;
}

/* Returns the offset within |array[]| of an element equal to |key|,
   or |-1| if |key| is not in |array[]|.
   |array[]| must be an array of |n| |int|s sorted in ascending order. */
static int
binary_search_bsearch (int array[], int n, int key)
{
  int *p = blp_bsearch (&key, array, n, sizeof *array, compare_ints);
  return p != NULL ? p - array : -1;
}

/* Cheating search function that knows that |array[i] == i|.
   |n| must be the array size and |key| the item to search for.
   |array[]| is not used.
   Returns the index in |array[]| where |key| is found,
   or |-1| if |key| is not in |array[]|. */
int
cheat_search (int array[], int n, int key)
{
  return key >= 0 && key < n ? key : -1;
}

/* Description of a search function. */
struct search_func
  {
    const char *name;
    int (*search) (int array[], int n, int key);
  };

/* Array of all the search functions we know. */
struct search_func search_func_tab[] =
  {
    {"seq_search()", seq_search},
    {"seq_sentinel_search()", seq_sentinel_search},
    {"seq_sorted_search()", seq_sorted_search},
    {"seq_sorted_sentinel_search()", seq_sorted_sentinel_search},
    {"seq_sorted_sentinel_search_2()", seq_sorted_sentinel_search_2},
    {"binary_search()", binary_search},
    {"uniform_binary_search()", uniform_binary_search},
    {"binary_search_bsearch()", binary_search_bsearch},
    {"cheat_search()", cheat_search},
  };

/* Number of search functions. */
const size_t n_search_func = sizeof search_func_tab / sizeof *search_func_tab;

/* ``Starts'' a timer by recording the current time in |*t|. */
static void
start_timer (clock_t *t)
{
  clock_t now = clock ();
  while (now == clock ())
    /* Do nothing. */;
  *t = clock ();
}

/* Prints the elapsed time since |start|, set by |start_timer()|. */
static void
stop_timer (clock_t start)
{
  clock_t end = clock ();

  printf ("%.2f seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
}

/* Tests that |f->search| returns |expect| when called to search for
   |key| within |array[]|,
   which has |n| elements such that |array[i] == i|. */
static void
test_search_func_at (struct search_func *f, int array[], int n,
                     int key, int expect)
{
  int result = f->search (array, n, key);
  if (result != expect)
    printf ("%s returned %d looking for %d - expected %d\n",
            f->name, result, key, expect);
}

/* Tests searches for each element in |array[]| having |n| elements such that
   |array[i] == i|,
   and some unsuccessful searches too, all using function |f->search|. */
static void
test_search_func (struct search_func *f, int array[], int n)
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

/* Times a search for each element in |array[]| having |n| elements such that
   |array[i] == i|, repeated |n_iter| times, using function |f->search|. */
static void
time_successful_search (struct search_func *f, int array[], int n, int n_iter)
{
  clock_t timer;

  printf ("Timing %d sets of successful searches...  ", n_iter);
  fflush (stdout);

  start_timer (&timer);
  while (n_iter-- > 0)
    {
      int i;

      for (i = 0; i < n; i++)
        f->search (array, n, i);
    }
  stop_timer (timer);
}

/* Times |n| search for elements not in |array[]| having |n| elements such that
   |array[i] == i|, repeated |n_iter| times, using function |f->search|. */
static void
time_unsuccessful_search (struct search_func *f, int array[],
                          int n, int n_iter)
{
  clock_t timer;

  printf ("Timing %d sets of unsuccessful searches...  ", n_iter);
  fflush (stdout);

  start_timer (&timer);
  while (n_iter-- > 0)
    {
      int i;

      for (i = 0; i < n; i++)
        f->search (array, n, -i);
    }
  stop_timer (timer);
}

/* Prints a message to the console explaining how to use this program. */
static void
usage (void)
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

/* |s| should point to a decimal representation of an integer.
   Returns the value of |s|, if successful, or 0 on failure. */
static int
stoi (const char *s)
{
  long x = strtol (s, NULL, 10);
  return x >= INT_MIN && x <= INT_MAX ? x : 0;
}


int
main (int argc, char *argv[])
{
  struct search_func *f;        /* Search function. */
  int *array, n;                /* Array and its size. */
  int n_iter;                   /* Number of iterations. */

  if (argc != 4)
    usage ();

  {
    long algorithm = stoi (argv[1]) - 1;
    if (algorithm < 0 || algorithm > (long) n_search_func)
      usage ();
    f = &search_func_tab[algorithm];
  }

  n = stoi (argv[2]);
  n_iter = stoi (argv[3]);
  if (n < 1 || n_iter < 1)
    usage ();

  array = malloc ((n + 2) * sizeof *array);
  if (array == NULL)
    {
      fprintf (stderr, "out of memory\n");
      exit (EXIT_FAILURE);
    }
  array++;

  {
    int i;

    for (i = 0; i < n; i++)
      array[i] = i;
  }

  test_search_func (f, array, n);
  time_successful_search (f, array, n, n_iter);
  time_unsuccessful_search (f, array, n, n_iter);

  free (array - 1);

  return 0;
}
