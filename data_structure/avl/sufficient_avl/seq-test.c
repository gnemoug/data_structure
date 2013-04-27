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

#include <stdio.h>

#define MAX_INPUT 1024

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


int
main (void)
{
  int array[MAX_INPUT];
  int n, i;

  for (n = 0; n < MAX_INPUT; n++)
    if (scanf ("%d", &array[n]) != 1)
      break;

  for (i = 0; i < n; i++)
    {
      int result = seq_search (array, n, array[i]);
      if (result != i)
        printf ("seq_search() returned %d looking for %d - expected %d\n",
                result, array[i], i);
    }

  return 0;
}
