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

/* One entry in a binary search tree stored in an array. */
struct binary_tree_entry
  {
    int value;          /* This item in the binary search tree. */
    int smaller;        /* Array index of next item for smaller targets. */
    int larger;         /* Array index of next item for larger targets. */
  };

/* Returns |i| such that |array[i].value == key|,
   or -1 if |key| is not in |array[]|.
   |array[]| is an array of |n| elements forming a binary search tree,
   with its root at |array[n / 2]|,
   and space for an |(n + 1)|th value at the end. */
int
binary_search_tree_array (struct binary_tree_entry array[], int n,
                          int key)
{
  int i = n / 2;

  array[n].value = key;
  for (;;)
    if (key > array[i].value)
      i = array[i].larger;
    else if (key < array[i].value)
      i = array[i].smaller;
    else
      return i != n ? i : -1;
}

/* Initializes |larger| and |smaller| within range |min|@dots{}|max| of
   |array[]|,
   which has |n| real elements plus a |(n + 1)|th sentinel element. */
int
init_binary_tree_array (struct binary_tree_entry array[], int n,
                        int min, int max)
{
  if (min <= max)
    {
      /* The `|+ 1|' is necessary because the tree root must be at |n / 2|,
         and on the first call we have |min == 0| and |max == n - 1|. */
      int i = (min + max + 1) / 2;
      array[i].larger = init_binary_tree_array (array, n, i + 1, max);
      array[i].smaller = init_binary_tree_array (array, n, min, i - 1);
      return i;
    }
  else
    return n;
}

/* Print a helpful usage message and abort execution. */
static void
usage (void)
{
  fputs ("Usage: bin-ary-test <array-size>\n"
         "where <array-size> is the size of the array to test.\n",
         stdout);
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
  struct binary_tree_entry *array;
  int n, i;

  /* Parse command line. */
  if (argc != 2)
    usage ();
  n = stoi (argv[1]);
  if (n < 1)
    usage ();

  /* Allocate memory. */
  array = malloc ((n + 1) * sizeof *array);
  if (array == NULL)
    {
      fprintf (stderr, "out of memory\n");
      return EXIT_FAILURE;
    }

  /* Initialize array. */
  for (i = 0; i < n; i++)
    array[i].value = i;
  init_binary_tree_array (array, n, 0, n - 1);

  /* Test successful and unsuccessful searches. */
  for (i = -1; i < n; i++)
    {
      int result = binary_search_tree_array (array, n, i);
      if (result != i)
        printf ("Searching for %d: expected %d, but received %d\n",
                i, i, result);
    }

  /* Clean up. */
  free (array);

  return EXIT_SUCCESS;
}
