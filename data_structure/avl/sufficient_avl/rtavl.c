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
#include "rtavl.h"

/* Creates and returns a new table
   with comparison function |compare| using parameter |param|
   and memory allocator |allocator|.
   Returns |NULL| if memory allocation failed. */
struct rtavl_table *
rtavl_create (rtavl_comparison_func *compare, void *param,
            struct libavl_allocator *allocator)
{
  struct rtavl_table *tree;

  assert (compare != NULL);

  if (allocator == NULL)
    allocator = &rtavl_allocator_default;

  tree = allocator->libavl_malloc (allocator, sizeof *tree);
  if (tree == NULL)
    return NULL;

  tree->rtavl_root = NULL;
  tree->rtavl_compare = compare;
  tree->rtavl_param = param;
  tree->rtavl_alloc = allocator;
  tree->rtavl_count = 0;

  return tree;
}

/* Search |tree| for an item matching |item|, and return it if found.
   Otherwise return |NULL|. */
void *
rtavl_find (const struct rtavl_table *tree, const void *item)
{
  const struct rtavl_node *p;
  int dir;

  assert (tree != NULL && item != NULL);

  if (tree->rtavl_root == NULL)
    return NULL;

  for (p = tree->rtavl_root; ; p = p->rtavl_link[dir])
    {
      int cmp = tree->rtavl_compare (item, p->rtavl_data, tree->rtavl_param);
      if (cmp == 0)
        return p->rtavl_data;
      dir = cmp > 0;

      if (dir == 0)
        {
          if (p->rtavl_link[0] == NULL)
            return NULL;
        }
      else /* |dir == 1| */
        {
          if (p->rtavl_rtag == RTAVL_THREAD)
            return NULL;
        }
    }
}

/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree,
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
void **
rtavl_probe (struct rtavl_table *tree, void *item)
{
  struct rtavl_node *y, *z; /* Top node to update balance factor, and parent. */
  struct rtavl_node *p, *q; /* Iterator, and parent. */
  struct rtavl_node *n;     /* Newly inserted node. */
  struct rtavl_node *w;     /* New root of rebalanced subtree. */
  int dir;                /* Direction to descend. */

  unsigned char da[RTAVL_MAX_HEIGHT]; /* Cached comparison results. */
  int k = 0;              /* Number of cached results. */

  assert (tree != NULL && item != NULL);

  z = (struct rtavl_node *) &tree->rtavl_root;
  y = tree->rtavl_root;
  if (tree->rtavl_root != NULL)
    for (q = z, p = y; ; q = p, p = p->rtavl_link[dir])
      {
        int cmp = tree->rtavl_compare (item, p->rtavl_data, tree->rtavl_param);
        if (cmp == 0)
          return &p->rtavl_data;

        if (p->rtavl_balance != 0)
          z = q, y = p, k = 0;
        da[k++] = dir = cmp > 0;

        if (dir == 0)
          {
            if (p->rtavl_link[0] == NULL)
              break;
          }
        else /* |dir == 1| */
          {
            if (p->rtavl_rtag == RTAVL_THREAD)
              break;
          }
      }
  else
    {
      p = (struct rtavl_node *) &tree->rtavl_root;
      dir = 0;
    }
  n = tree->rtavl_alloc->libavl_malloc (tree->rtavl_alloc, sizeof *n);
  if (n == NULL)
    return NULL;

  tree->rtavl_count++;
  n->rtavl_data = item;
  n->rtavl_link[0] = NULL;
  if (dir == 0)
    n->rtavl_link[1] = p;
  else /* |dir == 1| */
    {
      p->rtavl_rtag = RTAVL_CHILD;
      n->rtavl_link[1] = p->rtavl_link[1];
    }
  n->rtavl_rtag = RTAVL_THREAD;
  n->rtavl_balance = 0;
  p->rtavl_link[dir] = n;
  if (y == NULL)
    {
      n->rtavl_link[1] = NULL;
      return &n->rtavl_data;
    }

  for (p = y, k = 0; p != n; p = p->rtavl_link[da[k]], k++)
    if (da[k] == 0)
      p->rtavl_balance--;
    else
      p->rtavl_balance++;

  if (y->rtavl_balance == -2)
    {
      struct rtavl_node *x = y->rtavl_link[0];
      if (x->rtavl_balance == -1)
        {
          w = x;
          if (x->rtavl_rtag == RTAVL_THREAD)
            {
              x->rtavl_rtag = RTAVL_CHILD;
              y->rtavl_link[0] = NULL;
            }
          else
            y->rtavl_link[0] = x->rtavl_link[1];
          x->rtavl_link[1] = y;
          x->rtavl_balance = y->rtavl_balance = 0;
        }
      else
        {
          assert (x->rtavl_balance == +1);
          w = x->rtavl_link[1];
          x->rtavl_link[1] = w->rtavl_link[0];
          w->rtavl_link[0] = x;
          y->rtavl_link[0] = w->rtavl_link[1];
          w->rtavl_link[1] = y;
          if (w->rtavl_balance == -1)
            x->rtavl_balance = 0, y->rtavl_balance = +1;
          else if (w->rtavl_balance == 0)
            x->rtavl_balance = y->rtavl_balance = 0;
          else /* |w->rtavl_balance == +1| */
            x->rtavl_balance = -1, y->rtavl_balance = 0;
          w->rtavl_balance = 0;
          if (x->rtavl_link[1] == NULL)
            {
              x->rtavl_rtag = RTAVL_THREAD;
              x->rtavl_link[1] = w;
            }
          if (w->rtavl_rtag == RTAVL_THREAD)
            {
              y->rtavl_link[0] = NULL;
              w->rtavl_rtag = RTAVL_CHILD;
            }
        }
    }
  else if (y->rtavl_balance == +2)
    {
      struct rtavl_node *x = y->rtavl_link[1];
      if (x->rtavl_balance == +1)
        {
          w = x;
          if (x->rtavl_link[0] == NULL)
            {
              y->rtavl_rtag = RTAVL_THREAD;
              y->rtavl_link[1] = x;
            }
          else
            y->rtavl_link[1] = x->rtavl_link[0];
          x->rtavl_link[0] = y;
          x->rtavl_balance = y->rtavl_balance = 0;
        }
      else
        {
          assert (x->rtavl_balance == -1);
          w = x->rtavl_link[0];
          x->rtavl_link[0] = w->rtavl_link[1];
          w->rtavl_link[1] = x;
          y->rtavl_link[1] = w->rtavl_link[0];
          w->rtavl_link[0] = y;
          if (w->rtavl_balance == +1)
            x->rtavl_balance = 0, y->rtavl_balance = -1;
          else if (w->rtavl_balance == 0)
            x->rtavl_balance = y->rtavl_balance = 0;
          else /* |w->rtavl_balance == -1| */
            x->rtavl_balance = +1, y->rtavl_balance = 0;
          w->rtavl_balance = 0;
          if (y->rtavl_link[1] == NULL)
            {
              y->rtavl_rtag = RTAVL_THREAD;
              y->rtavl_link[1] = w;
            }
          if (w->rtavl_rtag == RTAVL_THREAD)
            {
              x->rtavl_link[0] = NULL;
              w->rtavl_rtag = RTAVL_CHILD;
            }
        }
    }
  else
    return &n->rtavl_data;

  z->rtavl_link[y != z->rtavl_link[0]] = w;
  return &n->rtavl_data;
}

/* Inserts |item| into |table|.
   Returns |NULL| if |item| was successfully inserted
   or if a memory allocation error occurred.
   Otherwise, returns the duplicate item. */
void *
rtavl_insert (struct rtavl_table *table, void *item)
{
  void **p = rtavl_probe (table, item);
  return p == NULL || *p == item ? NULL : *p;
}

/* Inserts |item| into |table|, replacing any duplicate item.
   Returns |NULL| if |item| was inserted without replacing a duplicate,
   or if a memory allocation error occurred.
   Otherwise, returns the item that was replaced. */
void *
rtavl_replace (struct rtavl_table *table, void *item)
{
  void **p = rtavl_probe (table, item);
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
rtavl_delete (struct rtavl_table *tree, const void *item)
{
  /* Stack of nodes. */
  struct rtavl_node *pa[RTAVL_MAX_HEIGHT]; /* Nodes. */
  unsigned char da[RTAVL_MAX_HEIGHT];     /* |rtavl_link[]| indexes. */
  int k;                                  /* Stack pointer. */

  struct rtavl_node *p; /* Traverses tree to find node to delete. */

  assert (tree != NULL && item != NULL);

  k = 1;
  da[0] = 0;
  pa[0] = (struct rtavl_node *) &tree->rtavl_root;
  p = tree->rtavl_root;
  if (p == NULL)
    return NULL;

  for (;;)
    {
      int cmp, dir;

      cmp = tree->rtavl_compare (item, p->rtavl_data, tree->rtavl_param);
      if (cmp == 0)
        break;

      dir = cmp > 0;
      if (dir == 0)
        {
          if (p->rtavl_link[0] == NULL)
            return NULL;
        }
      else /* |dir == 1| */
        {
          if (p->rtavl_rtag == RTAVL_THREAD)
            return NULL;
        }

      pa[k] = p;
      da[k++] = dir;
      p = p->rtavl_link[dir];
    }
  tree->rtavl_count--;
  item = p->rtavl_data;

  if (p->rtavl_link[0] == NULL)
    {
      if (p->rtavl_rtag == RTAVL_CHILD)
        {
          pa[k - 1]->rtavl_link[da[k - 1]] = p->rtavl_link[1];
        }
      else
        {
          pa[k - 1]->rtavl_link[da[k - 1]] = p->rtavl_link[da[k - 1]];
          if (da[k - 1] == 1)
            pa[k - 1]->rtavl_rtag = RTAVL_THREAD;
        }
    }
  else
    {
      struct rtavl_node *r = p->rtavl_link[0];
      if (r->rtavl_rtag == RTAVL_THREAD)
        {
          r->rtavl_link[1] = p->rtavl_link[1];
          r->rtavl_rtag = p->rtavl_rtag;
          r->rtavl_balance = p->rtavl_balance;
          pa[k - 1]->rtavl_link[da[k - 1]] = r;
          da[k] = 0;
          pa[k++] = r;
        }
      else
        {
          struct rtavl_node *s;
          int j = k++;

          for (;;)
            {
              da[k] = 1;
              pa[k++] = r;
              s = r->rtavl_link[1];
              if (s->rtavl_rtag == RTAVL_THREAD)
                break;

              r = s;
            }

          da[j] = 0;
          pa[j] = pa[j - 1]->rtavl_link[da[j - 1]] = s;

          if (s->rtavl_link[0] != NULL)
            r->rtavl_link[1] = s->rtavl_link[0];
          else
            {
              r->rtavl_rtag = RTAVL_THREAD;
              r->rtavl_link[1] = s;
            }

          s->rtavl_balance = p->rtavl_balance;
          s->rtavl_link[0] = p->rtavl_link[0];
          s->rtavl_link[1] = p->rtavl_link[1];
          s->rtavl_rtag = p->rtavl_rtag;
        }
    }

  tree->rtavl_alloc->libavl_free (tree->rtavl_alloc, p);

  assert (k > 0);
  while (--k > 0)
    {
      struct rtavl_node *y = pa[k];

      if (da[k] == 0)
        {
          y->rtavl_balance++;
          if (y->rtavl_balance == +1)
            break;
          else if (y->rtavl_balance == +2)
            {
              struct rtavl_node *x = y->rtavl_link[1];

              assert (x != NULL);
              if (x->rtavl_balance == -1)
                {
                  struct rtavl_node *w;

                  assert (x->rtavl_balance == -1);
                  w = x->rtavl_link[0];
                  x->rtavl_link[0] = w->rtavl_link[1];
                  w->rtavl_link[1] = x;
                  y->rtavl_link[1] = w->rtavl_link[0];
                  w->rtavl_link[0] = y;
                  if (w->rtavl_balance == +1)
                    x->rtavl_balance = 0, y->rtavl_balance = -1;
                  else if (w->rtavl_balance == 0)
                    x->rtavl_balance = y->rtavl_balance = 0;
                  else /* |w->rtavl_balance == -1| */
                    x->rtavl_balance = +1, y->rtavl_balance = 0;
                  w->rtavl_balance = 0;
                  if (y->rtavl_link[1] == NULL)
                    {
                      y->rtavl_rtag = RTAVL_THREAD;
                      y->rtavl_link[1] = w;
                    }
                  if (w->rtavl_rtag == RTAVL_THREAD)
                    {
                      x->rtavl_link[0] = NULL;
                      w->rtavl_rtag = RTAVL_CHILD;
                    }
                  pa[k - 1]->rtavl_link[da[k - 1]] = w;
                }
              else
                {
                  pa[k - 1]->rtavl_link[da[k - 1]] = x;
                  if (x->rtavl_balance == 0)
                    {
                      y->rtavl_link[1] = x->rtavl_link[0];
                      x->rtavl_link[0] = y;
                      x->rtavl_balance = -1;
                      y->rtavl_balance = +1;
                      break;
                    }
                  else /* |x->rtavl_balance == +1| */
                    {
                      if (x->rtavl_link[0] != NULL)
                        y->rtavl_link[1] = x->rtavl_link[0];
                      else
                        y->rtavl_rtag = RTAVL_THREAD;
                      x->rtavl_link[0] = y;
                      y->rtavl_balance = x->rtavl_balance = 0;
                    }
                }
            }
        }
      else
        {
          y->rtavl_balance--;
          if (y->rtavl_balance == -1)
            break;
          else if (y->rtavl_balance == -2)
            {
              struct rtavl_node *x = y->rtavl_link[0];

              assert (x != NULL);
              if (x->rtavl_balance == +1)
                {
                  struct rtavl_node *w;

                  assert (x->rtavl_balance == +1);
                  w = x->rtavl_link[1];
                  x->rtavl_link[1] = w->rtavl_link[0];
                  w->rtavl_link[0] = x;
                  y->rtavl_link[0] = w->rtavl_link[1];
                  w->rtavl_link[1] = y;
                  if (w->rtavl_balance == -1)
                    x->rtavl_balance = 0, y->rtavl_balance = +1;
                  else if (w->rtavl_balance == 0)
                    x->rtavl_balance = y->rtavl_balance = 0;
                  else /* |w->rtavl_balance == +1| */
                    x->rtavl_balance = -1, y->rtavl_balance = 0;
                  w->rtavl_balance = 0;
                  if (x->rtavl_link[1] == NULL)
                    {
                      x->rtavl_rtag = RTAVL_THREAD;
                      x->rtavl_link[1] = w;
                    }
                  if (w->rtavl_rtag == RTAVL_THREAD)
                    {
                      y->rtavl_link[0] = NULL;
                      w->rtavl_rtag = RTAVL_CHILD;
                    }
                  pa[k - 1]->rtavl_link[da[k - 1]] = w;
                }
              else
                {
                  pa[k - 1]->rtavl_link[da[k - 1]] = x;
                  if (x->rtavl_balance == 0)
                    {
                      y->rtavl_link[0] = x->rtavl_link[1];
                      x->rtavl_link[1] = y;
                      x->rtavl_balance = +1;
                      y->rtavl_balance = -1;
                      break;
                    }
                  else /* |x->rtavl_balance == -1| */
                    {
                      if (x->rtavl_rtag == RTAVL_CHILD)
                        y->rtavl_link[0] = x->rtavl_link[1];
                      else
                        {
                          y->rtavl_link[0] = NULL;
                          x->rtavl_rtag = RTAVL_CHILD;
                        }
                      x->rtavl_link[1] = y;
                      y->rtavl_balance = x->rtavl_balance = 0;
                    }
                }
            }
        }
    }

  return (void *) item;
}

/* Initializes |trav| for use with |tree|
   and selects the null node. */
void
rtavl_t_init (struct rtavl_traverser *trav, struct rtavl_table *tree)
{
  trav->rtavl_table = tree;
  trav->rtavl_node = NULL;
}

/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the least value,
   or |NULL| if |tree| is empty. */
void *
rtavl_t_first (struct rtavl_traverser *trav, struct rtavl_table *tree)
{
  assert (tree != NULL && trav != NULL);

  trav->rtavl_table = tree;
  trav->rtavl_node = tree->rtavl_root;
  if (trav->rtavl_node != NULL)
    {
      while (trav->rtavl_node->rtavl_link[0] != NULL)
        trav->rtavl_node = trav->rtavl_node->rtavl_link[0];
      return trav->rtavl_node->rtavl_data;
    }
  else
    return NULL;
}

/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the greatest value,
   or |NULL| if |tree| is empty. */
void *
rtavl_t_last (struct rtavl_traverser *trav, struct rtavl_table *tree)
{
  assert (tree != NULL && trav != NULL);

  trav->rtavl_table = tree;
  trav->rtavl_node = tree->rtavl_root;
  if (trav->rtavl_node != NULL)
    {
      while (trav->rtavl_node->rtavl_rtag == RTAVL_CHILD)
        trav->rtavl_node = trav->rtavl_node->rtavl_link[1];
      return trav->rtavl_node->rtavl_data;
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
rtavl_t_find (struct rtavl_traverser *trav, struct rtavl_table *tree,
              void *item)
{
  struct rtavl_node *p;

  assert (trav != NULL && tree != NULL && item != NULL);

  trav->rtavl_table = tree;
  trav->rtavl_node = NULL;

  p = tree->rtavl_root;
  if (p == NULL)
    return NULL;

  for (;;)
    {
      int cmp = tree->rtavl_compare (item, p->rtavl_data, tree->rtavl_param);
      if (cmp == 0)
        {
          trav->rtavl_node = p;
          return p->rtavl_data;
        }

      if (cmp < 0)
        {
          p = p->rtavl_link[0];
          if (p == NULL)
            return NULL;
        }
      else
        {
          if (p->rtavl_rtag == RTAVL_THREAD)
            return NULL;
          p = p->rtavl_link[1];
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
rtavl_t_insert (struct rtavl_traverser *trav,
               struct rtavl_table *tree, void *item)
{
  void **p;

  assert (trav != NULL && tree != NULL && item != NULL);

  p = rtavl_probe (tree, item);
  if (p != NULL)
    {
      trav->rtavl_table = tree;
      trav->rtavl_node =
        ((struct rtavl_node *)
         ((char *) p - offsetof (struct rtavl_node, rtavl_data)));
      return *p;
    }
  else
    {
      rtavl_t_init (trav, tree);
      return NULL;
    }
}

/* Initializes |trav| to have the same current node as |src|. */
void *
rtavl_t_copy (struct rtavl_traverser *trav, const struct rtavl_traverser *src)
{
  assert (trav != NULL && src != NULL);

  trav->rtavl_table = src->rtavl_table;
  trav->rtavl_node = src->rtavl_node;

  return trav->rtavl_node != NULL ? trav->rtavl_node->rtavl_data : NULL;
}

/* Returns the next data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
void *
rtavl_t_next (struct rtavl_traverser *trav)
{
  assert (trav != NULL);

  if (trav->rtavl_node == NULL)
    return rtavl_t_first (trav, trav->rtavl_table);
  else if (trav->rtavl_node->rtavl_rtag == RTAVL_THREAD)
    {
      trav->rtavl_node = trav->rtavl_node->rtavl_link[1];
      return trav->rtavl_node != NULL ? trav->rtavl_node->rtavl_data : NULL;
    }
  else
    {
      trav->rtavl_node = trav->rtavl_node->rtavl_link[1];
      while (trav->rtavl_node->rtavl_link[0] != NULL)
        trav->rtavl_node = trav->rtavl_node->rtavl_link[0];
      return trav->rtavl_node->rtavl_data;
    }
}

/* Returns the previous data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
void *
rtavl_t_prev (struct rtavl_traverser *trav)
{
  assert (trav != NULL);

  if (trav->rtavl_node == NULL)
    return rtavl_t_last (trav, trav->rtavl_table);
  else if (trav->rtavl_node->rtavl_link[0] == NULL)
    {
      rtavl_comparison_func *cmp = trav->rtavl_table->rtavl_compare;
      void *param = trav->rtavl_table->rtavl_param;
      struct rtavl_node *node = trav->rtavl_node;
      struct rtavl_node *i;

      trav->rtavl_node = NULL;
      for (i = trav->rtavl_table->rtavl_root; i != node; )
        {
          int dir = cmp (node->rtavl_data, i->rtavl_data, param) > 0;
          if (dir == 1)
            trav->rtavl_node = i;
          i = i->rtavl_link[dir];
        }

      return trav->rtavl_node != NULL ? trav->rtavl_node->rtavl_data : NULL;
    }
  else
    {
      trav->rtavl_node = trav->rtavl_node->rtavl_link[0];
      while (trav->rtavl_node->rtavl_rtag == RTAVL_CHILD)
        trav->rtavl_node = trav->rtavl_node->rtavl_link[1];
      return trav->rtavl_node->rtavl_data;
    }
}

/* Returns |trav|'s current item. */
void *
rtavl_t_cur (struct rtavl_traverser *trav)
{
  assert (trav != NULL);

  return trav->rtavl_node != NULL ? trav->rtavl_node->rtavl_data : NULL;
}

/* Replaces the current item in |trav| by |new| and returns the item replaced.
   |trav| must not have the null item selected.
   The new item must not upset the ordering of the tree. */
void *
rtavl_t_replace (struct rtavl_traverser *trav, void *new)
{
  void *old;

  assert (trav != NULL && trav->rtavl_node != NULL && new != NULL);
  old = trav->rtavl_node->rtavl_data;
  trav->rtavl_node->rtavl_data = new;
  return old;
}

/* Creates a new node as a child of |dst| on side |dir|.
   Copies data from |src| into the new node, applying |copy()|, if non-null.
   Returns nonzero only if fully successful.
   Regardless of success, integrity of the tree structure is assured,
   though failure may leave a null pointer in a |rtavl_data| member. */
static int
copy_node (struct rtavl_table *tree,
           struct rtavl_node *dst, int dir,
           const struct rtavl_node *src, rtavl_copy_func *copy)
{
  struct rtavl_node *new = tree->rtavl_alloc->libavl_malloc (tree->rtavl_alloc,
                                                             sizeof *new);
  if (new == NULL)
    return 0;

  new->rtavl_link[0] = NULL;
  new->rtavl_rtag = RTAVL_THREAD;
  if (dir == 0)
    new->rtavl_link[1] = dst;
  else
    {
      new->rtavl_link[1] = dst->rtavl_link[1];
      dst->rtavl_rtag = RTAVL_CHILD;
    }
  dst->rtavl_link[dir] = new;

  new->rtavl_balance = src->rtavl_balance;

  if (copy == NULL)
    new->rtavl_data = src->rtavl_data;
  else
    {
      new->rtavl_data = copy (src->rtavl_data, tree->rtavl_param);
      if (new->rtavl_data == NULL)
        return 0;
    }

  return 1;
}

/* Destroys |new| with |rtavl_destroy (new, destroy)|,
   first initializing right links in |new| that have
   not yet been initialized at time of call. */
static void
copy_error_recovery (struct rtavl_table *new, rtavl_item_func *destroy)
{
  struct rtavl_node *p = new->rtavl_root;
  if (p != NULL)
    {
      while (p->rtavl_rtag == RTAVL_CHILD)
        p = p->rtavl_link[1];
      p->rtavl_link[1] = NULL;
    }
  rtavl_destroy (new, destroy);
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
struct rtavl_table *
rtavl_copy (const struct rtavl_table *org, rtavl_copy_func *copy,
            rtavl_item_func *destroy, struct libavl_allocator *allocator)
{
  struct rtavl_table *new;

  const struct rtavl_node *p;
  struct rtavl_node *q;

  assert (org != NULL);
  new = rtavl_create (org->rtavl_compare, org->rtavl_param,
                     allocator != NULL ? allocator : org->rtavl_alloc);
  if (new == NULL)
    return NULL;

  new->rtavl_count = org->rtavl_count;
  if (new->rtavl_count == 0)
    return new;

  p = (struct rtavl_node *) &org->rtavl_root;
  q = (struct rtavl_node *) &new->rtavl_root;
  for (;;)
    {
      if (p->rtavl_link[0] != NULL)
        {
          if (!copy_node (new, q, 0, p->rtavl_link[0], copy))
            {
              copy_error_recovery (new, destroy);
              return NULL;
            }

          p = p->rtavl_link[0];
          q = q->rtavl_link[0];
        }
      else
        {
          while (p->rtavl_rtag == RTAVL_THREAD)
            {
              p = p->rtavl_link[1];
              if (p == NULL)
                {
                  q->rtavl_link[1] = NULL;
                  return new;
                }

              q = q->rtavl_link[1];
            }

          p = p->rtavl_link[1];
          q = q->rtavl_link[1];
        }

      if (p->rtavl_rtag == RTAVL_CHILD)
        if (!copy_node (new, q, 1, p->rtavl_link[1], copy))
          {
            copy_error_recovery (new, destroy);
            return NULL;
          }
    }
}

/* Frees storage allocated for |tree|.
   If |destroy != NULL|, applies it to each data item in inorder. */
void
rtavl_destroy (struct rtavl_table *tree, rtavl_item_func *destroy)
{
  struct rtavl_node *p; /* Current node. */
  struct rtavl_node *n; /* Next node. */

  p = tree->rtavl_root;
  if (p != NULL)
    while (p->rtavl_link[0] != NULL)
      p = p->rtavl_link[0];

  while (p != NULL)
    {
      n = p->rtavl_link[1];
      if (p->rtavl_rtag == RTAVL_CHILD)
        while (n->rtavl_link[0] != NULL)
          n = n->rtavl_link[0];

      if (destroy != NULL && p->rtavl_data != NULL)
        destroy (p->rtavl_data, tree->rtavl_param);
      tree->rtavl_alloc->libavl_free (tree->rtavl_alloc, p);

      p = n;
    }

  tree->rtavl_alloc->libavl_free (tree->rtavl_alloc, tree);
}

/* Allocates |size| bytes of space using |malloc()|.
   Returns a null pointer if allocation fails. */
void *
rtavl_malloc (struct libavl_allocator *allocator, size_t size)
{
  assert (allocator != NULL && size > 0);
  return malloc (size);
}

/* Frees |block|. */
void
rtavl_free (struct libavl_allocator *allocator, void *block)
{
  assert (allocator != NULL && block != NULL);
  free (block);
}

/* Default memory allocator that uses |malloc()| and |free()|. */
struct libavl_allocator rtavl_allocator_default =
  {
    rtavl_malloc,
    rtavl_free
  };

#undef NDEBUG
#include <assert.h>

/* Asserts that |rtavl_insert()| succeeds at inserting |item| into |table|. */
void
(rtavl_assert_insert) (struct rtavl_table *table, void *item)
{
  void **p = rtavl_probe (table, item);
  assert (p != NULL && *p == item);
}

/* Asserts that |rtavl_delete()| really removes |item| from |table|,
   and returns the removed item. */
void *
(rtavl_assert_delete) (struct rtavl_table *table, void *item)
{
  void *p = rtavl_delete (table, item);
  assert (p != NULL);
  return p;
}

