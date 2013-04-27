/* Produced by texiweb from libavl.w. */

/* libavl - library for manipulation of binary trees.
   Copyright (C) 1998, 1999, 2000, 2001, 2002, 2004 Free Software
   Foundation, Inc.

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

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "test.h"

/* Node for binary search tree with sentinel. */
struct bsts_node
  {
    struct bsts_node *link[2];
    int data;
  };

/* Binary search tree with sentinel. */
struct bsts_tree
  {
    struct bsts_node *root;
    struct bsts_node sentinel;
    struct libavl_allocator *alloc;
  };

#ifndef LIBAVL_ALLOCATOR
#define LIBAVL_ALLOCATOR
/* Memory allocator. */
struct libavl_allocator
  {
    void *(*libavl_malloc) (struct libavl_allocator *, size_t libavl_size);
    void (*libavl_free) (struct libavl_allocator *, void *libavl_block);
  };
#endif

/* Default memory allocator. */
extern struct libavl_allocator bsts_allocator_default;
void *bsts_malloc (struct libavl_allocator *, size_t);
void bsts_free (struct libavl_allocator *, void *);

/* Allocates |size| bytes of space using |malloc()|.
   Returns a null pointer if allocation fails. */
void *
bsts_malloc (struct libavl_allocator *allocator, size_t size)
{
  assert (allocator != NULL && size > 0);
  return malloc (size);
}

/* Frees |block|. */
void
bsts_free (struct libavl_allocator *allocator, void *block)
{
  assert (allocator != NULL && block != NULL);
  free (block);
}

/* Default memory allocator that uses |malloc()| and |free()|. */
struct libavl_allocator bsts_allocator_default =
  {
    bsts_malloc,
    bsts_free
  };

/* Returns nonzero only if |item| is in |tree|. */
int
bsts_find (struct bsts_tree *tree, int item)
{
  const struct bsts_node *node;

  tree->sentinel.data = item;
  node = tree->root;
  while (item != node->data)
    if (item < node->data)
      node = node->link[0];
    else
      node = node->link[1];
  return node != &tree->sentinel;
}

/* Inserts |item| into |tree|, if it is not already present. */
void
bsts_insert (struct bsts_tree *tree, int item)
{
  struct bsts_node **q = &tree->root;
  struct bsts_node *p = tree->root;

  tree->sentinel.data = item;
  while (item != p->data)
    {
      int dir = item > p->data;
      q = &p->link[dir];
      p = p->link[dir];
    }

  if (p == &tree->sentinel)
    {
      *q = tree->alloc->libavl_malloc (tree->alloc, sizeof **q);
      if (*q == NULL)
        {
          fprintf (stderr, "out of memory\n");
          exit (EXIT_FAILURE);
        }
      (*q)->link[0] = (*q)->link[1] = &tree->sentinel;
      (*q)->data = item;
    }
}

/* Tests BSTS functions.
   |insert| and |delete| must contain some permutation of values
   |0|@dots{}|n - 1|. */
int
test_correctness (struct libavl_allocator *alloc, int *insert,
                  int *delete, int n, int verbosity)
{
  struct bsts_tree tree;
  int okay = 1;
  int i;

  tree.root = &tree.sentinel;
  tree.alloc = alloc;

  for (i = 0; i < n; i++)
    bsts_insert (&tree, insert[i]);

  for (i = 0; i < n; i++)
    if (!bsts_find (&tree, i))
      {
        printf ("%d should be in tree, but isn't\n", i);
        okay = 0;
      }

  return okay;
}

/* Not supported. */
int
test_overflow (struct libavl_allocator *alloc, int order[], int n,
               int verbosity)
{
  return 0;
}
