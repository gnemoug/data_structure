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
#include "rtbst.h"

/* Creates and returns a new table
   with comparison function |compare| using parameter |param|
   and memory allocator |allocator|.
   Returns |NULL| if memory allocation failed. */
struct rtbst_table *
rtbst_create (rtbst_comparison_func *compare, void *param,
            struct libavl_allocator *allocator)
{
  struct rtbst_table *tree;

  assert (compare != NULL);

  if (allocator == NULL)
    allocator = &rtbst_allocator_default;

  tree = allocator->libavl_malloc (allocator, sizeof *tree);
  if (tree == NULL)
    return NULL;

  tree->rtbst_root = NULL;
  tree->rtbst_compare = compare;
  tree->rtbst_param = param;
  tree->rtbst_alloc = allocator;
  tree->rtbst_count = 0;

  return tree;
}

/* Search |tree| for an item matching |item|, and return it if found.
   Otherwise return |NULL|. */
void *
rtbst_find (const struct rtbst_table *tree, const void *item)
{
  const struct rtbst_node *p;
  int dir;

  assert (tree != NULL && item != NULL);

  if (tree->rtbst_root == NULL)
    return NULL;

  for (p = tree->rtbst_root; ; p = p->rtbst_link[dir])
    {
      int cmp = tree->rtbst_compare (item, p->rtbst_data, tree->rtbst_param);
      if (cmp == 0)
        return p->rtbst_data;
      dir = cmp > 0;

      if (dir == 0)
        {
          if (p->rtbst_link[0] == NULL)
            return NULL;
        }
      else /* |dir == 1| */
        {
          if (p->rtbst_rtag == RTBST_THREAD)
            return NULL;
        }
    }
}

/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree,
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
void **
rtbst_probe (struct rtbst_table *tree, void *item)
{
  struct rtbst_node *p; /* Current node in search. */
  int dir;              /* Side of |p| on which to insert the new node. */

  struct rtbst_node *n; /* New node. */

  if (tree->rtbst_root != NULL)
    for (p = tree->rtbst_root; ; p = p->rtbst_link[dir])
      {
        int cmp = tree->rtbst_compare (item, p->rtbst_data, tree->rtbst_param);
        if (cmp == 0)
          return &p->rtbst_data;
        dir = cmp > 0;

        if (dir == 0)
          {
            if (p->rtbst_link[0] == NULL)
              break;
          }
        else /* |dir == 1| */
          {
            if (p->rtbst_rtag == RTBST_THREAD)
              break;
          }
      }
  else
    {
      p = (struct rtbst_node *) &tree->rtbst_root;
      dir = 0;
    }

  n = tree->rtbst_alloc->libavl_malloc (tree->rtbst_alloc, sizeof *n);
  if (n == NULL)
    return NULL;

  tree->rtbst_count++;
  n->rtbst_data = item;
  n->rtbst_link[0] = NULL;
  if (dir == 0)
    {
      if (tree->rtbst_root != NULL)
        n->rtbst_link[1] = p;
      else
        n->rtbst_link[1] = NULL;
    }
  else /* |dir == 1| */
    {
      p->rtbst_rtag = RTBST_CHILD;
      n->rtbst_link[1] = p->rtbst_link[1];
    }
  n->rtbst_rtag = RTBST_THREAD;
  p->rtbst_link[dir] = n;

  return &n->rtbst_data;
}

/* Inserts |item| into |table|.
   Returns |NULL| if |item| was successfully inserted
   or if a memory allocation error occurred.
   Otherwise, returns the duplicate item. */
void *
rtbst_insert (struct rtbst_table *table, void *item)
{
  void **p = rtbst_probe (table, item);
  return p == NULL || *p == item ? NULL : *p;
}

/* Inserts |item| into |table|, replacing any duplicate item.
   Returns |NULL| if |item| was inserted without replacing a duplicate,
   or if a memory allocation error occurred.
   Otherwise, returns the item that was replaced. */
void *
rtbst_replace (struct rtbst_table *table, void *item)
{
  void **p = rtbst_probe (table, item);
  if (p == NULL || *p == item)
    return NULL;
  else
    {
      void *r = *p;
      *p = item;
      return r;
    }
}

/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
void *
rtbst_delete (struct rtbst_table *tree, const void *item)
{
  struct rtbst_node *p;        /* Node to delete. */
  struct rtbst_node *q;        /* Parent of |p|. */
  int dir;              /* Index into |q->rtbst_link[]| that leads to |p|. */

  assert (tree != NULL && item != NULL);

  if (tree->rtbst_root == NULL)
    return NULL;

  p = tree->rtbst_root;
  q = (struct rtbst_node *) &tree->rtbst_root;
  dir = 0;
  if (p == NULL)
    return NULL;

  for (;;)
    {
      int cmp = tree->rtbst_compare (item, p->rtbst_data, tree->rtbst_param);
      if (cmp == 0)
        break;

      dir = cmp > 0;
      if (dir == 0)
        {
          if (p->rtbst_link[0] == NULL)
            return NULL;
        }
      else /* |dir == 1| */
        {
          if (p->rtbst_rtag == RTBST_THREAD)
            return NULL;
        }

      q = p;
      p = p->rtbst_link[dir];
    }
  item = p->rtbst_data;

  if (p->rtbst_link[0] == NULL)
    {
      if (p->rtbst_rtag == RTBST_CHILD)
        {
          q->rtbst_link[dir] = p->rtbst_link[1];
        }
      else
        {
          q->rtbst_link[dir] = p->rtbst_link[dir];
          if (dir == 1)
            q->rtbst_rtag = RTBST_THREAD;
        }
    }
  else
    {
      struct rtbst_node *r = p->rtbst_link[0];
      if (r->rtbst_rtag == RTBST_THREAD)
        {
          r->rtbst_link[1] = p->rtbst_link[1];
          r->rtbst_rtag = p->rtbst_rtag;
          q->rtbst_link[dir] = r;
        }
      else
        {
          struct rtbst_node *s;

          for (;;)
            {
              s = r->rtbst_link[1];
              if (s->rtbst_rtag == RTBST_THREAD)
                break;

              r = s;
            }

          if (s->rtbst_link[0] != NULL)
            r->rtbst_link[1] = s->rtbst_link[0];
          else
            {
              r->rtbst_link[1] = s;
              r->rtbst_rtag = RTBST_THREAD;
            }

          s->rtbst_link[0] = p->rtbst_link[0];
          s->rtbst_link[1] = p->rtbst_link[1];
          s->rtbst_rtag = p->rtbst_rtag;

          q->rtbst_link[dir] = s;
        }
    }

  tree->rtbst_alloc->libavl_free (tree->rtbst_alloc, p);
  tree->rtbst_count--;
  return (void *) item;
}

/* Initializes |trav| for use with |tree|
   and selects the null node. */
void
rtbst_t_init (struct rtbst_traverser *trav, struct rtbst_table *tree)
{
  trav->rtbst_table = tree;
  trav->rtbst_node = NULL;
}

/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the least value,
   or |NULL| if |tree| is empty. */
void *
rtbst_t_first (struct rtbst_traverser *trav, struct rtbst_table *tree)
{
  assert (tree != NULL && trav != NULL);

  trav->rtbst_table = tree;
  trav->rtbst_node = tree->rtbst_root;
  if (trav->rtbst_node != NULL)
    {
      while (trav->rtbst_node->rtbst_link[0] != NULL)
        trav->rtbst_node = trav->rtbst_node->rtbst_link[0];
      return trav->rtbst_node->rtbst_data;
    }
  else
    return NULL;
}

/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the greatest value,
   or |NULL| if |tree| is empty. */
void *
rtbst_t_last (struct rtbst_traverser *trav, struct rtbst_table *tree)
{
  assert (tree != NULL && trav != NULL);

  trav->rtbst_table = tree;
  trav->rtbst_node = tree->rtbst_root;
  if (trav->rtbst_node != NULL)
    {
      while (trav->rtbst_node->rtbst_rtag == RTBST_CHILD)
        trav->rtbst_node = trav->rtbst_node->rtbst_link[1];
      return trav->rtbst_node->rtbst_data;
    }
  else
    return NULL;
}

/* Searches for |item| in |tree|.
   If found, initializes |trav| to the item found and returns the item
   as well.
   If there is no matching item, initializes |trav| to the null item
   and returns |NULL|. */
void *
rtbst_t_find (struct rtbst_traverser *trav, struct rtbst_table *tree,
              void *item)
{
  struct rtbst_node *p;

  assert (trav != NULL && tree != NULL && item != NULL);

  trav->rtbst_table = tree;
  trav->rtbst_node = NULL;

  p = tree->rtbst_root;
  if (p == NULL)
    return NULL;

  for (;;)
    {
      int cmp = tree->rtbst_compare (item, p->rtbst_data, tree->rtbst_param);
      if (cmp == 0)
        {
          trav->rtbst_node = p;
          return p->rtbst_data;
        }

      if (cmp < 0)
        {
          p = p->rtbst_link[0];
          if (p == NULL)
            return NULL;
        }
      else
        {
          if (p->rtbst_rtag == RTBST_THREAD)
            return NULL;
          p = p->rtbst_link[1];
        }
    }
}

/* Attempts to insert |item| into |tree|.
   If |item| is inserted successfully, it is returned and |trav| is
   initialized to its location.
   If a duplicate is found, it is returned and |trav| is initialized to
   its location.  No replacement of the item occurs.
   If a memory allocation failure occurs, |NULL| is returned and |trav|
   is initialized to the null item. */
void *
rtbst_t_insert (struct rtbst_traverser *trav,
               struct rtbst_table *tree, void *item)
{
  void **p;

  assert (trav != NULL && tree != NULL && item != NULL);

  p = rtbst_probe (tree, item);
  if (p != NULL)
    {
      trav->rtbst_table = tree;
      trav->rtbst_node =
        ((struct rtbst_node *)
         ((char *) p - offsetof (struct rtbst_node, rtbst_data)));
      return *p;
    }
  else
    {
      rtbst_t_init (trav, tree);
      return NULL;
    }
}

/* Initializes |trav| to have the same current node as |src|. */
void *
rtbst_t_copy (struct rtbst_traverser *trav, const struct rtbst_traverser *src)
{
  assert (trav != NULL && src != NULL);

  trav->rtbst_table = src->rtbst_table;
  trav->rtbst_node = src->rtbst_node;

  return trav->rtbst_node != NULL ? trav->rtbst_node->rtbst_data : NULL;
}

/* Returns the next data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
void *
rtbst_t_next (struct rtbst_traverser *trav)
{
  assert (trav != NULL);

  if (trav->rtbst_node == NULL)
    return rtbst_t_first (trav, trav->rtbst_table);
  else if (trav->rtbst_node->rtbst_rtag == RTBST_THREAD)
    {
      trav->rtbst_node = trav->rtbst_node->rtbst_link[1];
      return trav->rtbst_node != NULL ? trav->rtbst_node->rtbst_data : NULL;
    }
  else
    {
      trav->rtbst_node = trav->rtbst_node->rtbst_link[1];
      while (trav->rtbst_node->rtbst_link[0] != NULL)
        trav->rtbst_node = trav->rtbst_node->rtbst_link[0];
      return trav->rtbst_node->rtbst_data;
    }
}

/* Returns the previous data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
void *
rtbst_t_prev (struct rtbst_traverser *trav)
{
  assert (trav != NULL);

  if (trav->rtbst_node == NULL)
    return rtbst_t_last (trav, trav->rtbst_table);
  else if (trav->rtbst_node->rtbst_link[0] == NULL)
    {
      rtbst_comparison_func *cmp = trav->rtbst_table->rtbst_compare;
      void *param = trav->rtbst_table->rtbst_param;
      struct rtbst_node *node = trav->rtbst_node;
      struct rtbst_node *i;

      trav->rtbst_node = NULL;
      for (i = trav->rtbst_table->rtbst_root; i != node; )
        {
          int dir = cmp (node->rtbst_data, i->rtbst_data, param) > 0;
          if (dir == 1)
            trav->rtbst_node = i;
          i = i->rtbst_link[dir];
        }

      return trav->rtbst_node != NULL ? trav->rtbst_node->rtbst_data : NULL;
    }
  else
    {
      trav->rtbst_node = trav->rtbst_node->rtbst_link[0];
      while (trav->rtbst_node->rtbst_rtag == RTBST_CHILD)
        trav->rtbst_node = trav->rtbst_node->rtbst_link[1];
      return trav->rtbst_node->rtbst_data;
    }
}

/* Returns |trav|'s current item. */
void *
rtbst_t_cur (struct rtbst_traverser *trav)
{
  assert (trav != NULL);

  return trav->rtbst_node != NULL ? trav->rtbst_node->rtbst_data : NULL;
}

/* Replaces the current item in |trav| by |new| and returns the item replaced.
   |trav| must not have the null item selected.
   The new item must not upset the ordering of the tree. */
void *
rtbst_t_replace (struct rtbst_traverser *trav, void *new)
{
  void *old;

  assert (trav != NULL && trav->rtbst_node != NULL && new != NULL);
  old = trav->rtbst_node->rtbst_data;
  trav->rtbst_node->rtbst_data = new;
  return old;
}

/* Creates a new node as a child of |dst| on side |dir|.
   Copies data from |src| into the new node, applying |copy()|, if non-null.
   Returns nonzero only if fully successful.
   Regardless of success, integrity of the tree structure is assured,
   though failure may leave a null pointer in a |rtbst_data| member. */
static int
copy_node (struct rtbst_table *tree,
           struct rtbst_node *dst, int dir,
           const struct rtbst_node *src, rtbst_copy_func *copy)
{
  struct rtbst_node *new =
    tree->rtbst_alloc->libavl_malloc (tree->rtbst_alloc, sizeof *new);
  if (new == NULL)
    return 0;

  new->rtbst_link[0] = NULL;
  new->rtbst_rtag = RTBST_THREAD;
  if (dir == 0)
    new->rtbst_link[1] = dst;
  else
    {
      new->rtbst_link[1] = dst->rtbst_link[1];
      dst->rtbst_rtag = RTBST_CHILD;
    }
  dst->rtbst_link[dir] = new;

  if (copy == NULL)
    new->rtbst_data = src->rtbst_data;
  else
    {
      new->rtbst_data = copy (src->rtbst_data, tree->rtbst_param);
      if (new->rtbst_data == NULL)
        return 0;
    }

  return 1;
}

/* Destroys |new| with |rtbst_destroy (new, destroy)|,
   first initializing right links in |new| that have
   not yet been initialized at time of call. */
static void
copy_error_recovery (struct rtbst_table *new, rtbst_item_func *destroy)
{
  struct rtbst_node *p = new->rtbst_root;
  if (p != NULL)
    {
      while (p->rtbst_rtag == RTBST_CHILD)
        p = p->rtbst_link[1];
      p->rtbst_link[1] = NULL;
    }
  rtbst_destroy (new, destroy);
}

/* Copies |org| to a newly created tree, which is returned.
   If |copy != NULL|, each data item in |org| is first passed to |copy|,
   and the return values are inserted into the tree,
   with |NULL| return values are taken as indications of failure.
   On failure, destroys the partially created new tree,
   applying |destroy|, if non-null, to each item in the new tree so far,
   and returns |NULL|.
   If |allocator != NULL|, it is used for allocation in the new tree.
   Otherwise, the same allocator used for |org| is used. */
struct rtbst_table *
rtbst_copy (const struct rtbst_table *org, rtbst_copy_func *copy,
            rtbst_item_func *destroy, struct libavl_allocator *allocator)
{
  struct rtbst_table *new;

  const struct rtbst_node *p;
  struct rtbst_node *q;

  assert (org != NULL);
  new = rtbst_create (org->rtbst_compare, org->rtbst_param,
                     allocator != NULL ? allocator : org->rtbst_alloc);
  if (new == NULL)
    return NULL;

  new->rtbst_count = org->rtbst_count;
  if (new->rtbst_count == 0)
    return new;

  p = (struct rtbst_node *) &org->rtbst_root;
  q = (struct rtbst_node *) &new->rtbst_root;
  for (;;)
    {
      if (p->rtbst_link[0] != NULL)
        {
          if (!copy_node (new, q, 0, p->rtbst_link[0], copy))
            {
              copy_error_recovery (new, destroy);
              return NULL;
            }

          p = p->rtbst_link[0];
          q = q->rtbst_link[0];
        }
      else
        {
          while (p->rtbst_rtag == RTBST_THREAD)
            {
              p = p->rtbst_link[1];
              if (p == NULL)
                {
                  q->rtbst_link[1] = NULL;
                  return new;
                }

              q = q->rtbst_link[1];
            }

          p = p->rtbst_link[1];
          q = q->rtbst_link[1];
        }

      if (p->rtbst_rtag == RTBST_CHILD)
        if (!copy_node (new, q, 1, p->rtbst_link[1], copy))
          {
            copy_error_recovery (new, destroy);
            return NULL;
          }
    }
}

/* Frees storage allocated for |tree|.
   If |destroy != NULL|, applies it to each data item in inorder. */
void
rtbst_destroy (struct rtbst_table *tree, rtbst_item_func *destroy)
{
  struct rtbst_node *p; /* Current node. */
  struct rtbst_node *n; /* Next node. */

  p = tree->rtbst_root;
  if (p != NULL)
    while (p->rtbst_link[0] != NULL)
      p = p->rtbst_link[0];

  while (p != NULL)
    {
      n = p->rtbst_link[1];
      if (p->rtbst_rtag == RTBST_CHILD)
        while (n->rtbst_link[0] != NULL)
          n = n->rtbst_link[0];

      if (destroy != NULL && p->rtbst_data != NULL)
        destroy (p->rtbst_data, tree->rtbst_param);
      tree->rtbst_alloc->libavl_free (tree->rtbst_alloc, p);

      p = n;
    }

  tree->rtbst_alloc->libavl_free (tree->rtbst_alloc, tree);
}

static void
tree_to_vine (struct rtbst_table *tree)
{
  struct rtbst_node *p;

  if (tree->rtbst_root == NULL)
    return;

  p = tree->rtbst_root;
  while (p->rtbst_link[0] != NULL)
    p = p->rtbst_link[0];

  for (;;)
    {
      struct rtbst_node *q = p->rtbst_link[1];
      if (p->rtbst_rtag == RTBST_CHILD)
        {
          while (q->rtbst_link[0] != NULL)
            q = q->rtbst_link[0];
          p->rtbst_rtag = RTBST_THREAD;
          p->rtbst_link[1] = q;
        }

      if (q == NULL)
        break;

      q->rtbst_link[0] = p;
      p = q;
    }

  tree->rtbst_root = p;
}

/* Performs a compression transformation |count| times,
   starting at |root|. */
static void
compress (struct rtbst_node *root,
          unsigned long nonthread, unsigned long thread)
{
  assert (root != NULL);

  while (nonthread--)
    {
      struct rtbst_node *red = root->rtbst_link[0];
      struct rtbst_node *black = red->rtbst_link[0];

      root->rtbst_link[0] = black;
      red->rtbst_link[0] = black->rtbst_link[1];
      black->rtbst_link[1] = red;
      root = black;
    }

  while (thread--)
    {
      struct rtbst_node *red = root->rtbst_link[0];
      struct rtbst_node *black = red->rtbst_link[0];

      root->rtbst_link[0] = black;
      red->rtbst_link[0] = NULL;
      black->rtbst_rtag = RTBST_CHILD;
      root = black;
    }
}

/* Converts |tree|, which must be in the shape of a vine, into a balanced
   tree. */
static void
vine_to_tree (struct rtbst_table *tree)
{
  unsigned long vine;   /* Number of nodes in main vine. */
  unsigned long leaves; /* Nodes in incomplete bottom level, if any. */
  int height;           /* Height of produced balanced tree. */

  leaves = tree->rtbst_count + 1;
  for (;;)
    {
      unsigned long next = leaves & (leaves - 1);
      if (next == 0)
        break;
      leaves = next;
    }
  leaves = tree->rtbst_count + 1 - leaves;

  compress ((struct rtbst_node *) &tree->rtbst_root, 0, leaves);

  vine = tree->rtbst_count - leaves;
  height = 1 + (leaves > 0);
  if (vine > 1)
    {
      unsigned long nonleaves = vine / 2;
      leaves /= 2;
      if (leaves > nonleaves)
        {
          leaves = nonleaves;
          nonleaves = 0;
        }
      else
        nonleaves -= leaves;

      compress ((struct rtbst_node *) &tree->rtbst_root, leaves, nonleaves);
      vine /= 2;
      height++;
    }
  while (vine > 1)
    {
      compress ((struct rtbst_node *) &tree->rtbst_root, vine / 2, 0);
      vine /= 2;
      height++;
    }
}

/* Balances |tree|. */
void
rtbst_balance (struct rtbst_table *tree)
{
  assert (tree != NULL);

  tree_to_vine (tree);
  vine_to_tree (tree);
}

/* Allocates |size| bytes of space using |malloc()|.
   Returns a null pointer if allocation fails. */
void *
rtbst_malloc (struct libavl_allocator *allocator, size_t size)
{
  assert (allocator != NULL && size > 0);
  return malloc (size);
}

/* Frees |block|. */
void
rtbst_free (struct libavl_allocator *allocator, void *block)
{
  assert (allocator != NULL && block != NULL);
  free (block);
}

/* Default memory allocator that uses |malloc()| and |free()|. */
struct libavl_allocator rtbst_allocator_default =
  {
    rtbst_malloc,
    rtbst_free
  };

#undef NDEBUG
#include <assert.h>

/* Asserts that |rtbst_insert()| succeeds at inserting |item| into |table|. */
void
(rtbst_assert_insert) (struct rtbst_table *table, void *item)
{
  void **p = rtbst_probe (table, item);
  assert (p != NULL && *p == item);
}

/* Asserts that |rtbst_delete()| really removes |item| from |table|,
   and returns the removed item. */
void *
(rtbst_assert_delete) (struct rtbst_table *table, void *item)
{
  void *p = rtbst_delete (table, item);
  assert (p != NULL);
  return p;
}

