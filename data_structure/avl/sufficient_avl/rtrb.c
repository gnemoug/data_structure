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
#include "rtrb.h"

/* Creates and returns a new table
   with comparison function |compare| using parameter |param|
   and memory allocator |allocator|.
   Returns |NULL| if memory allocation failed. */
struct rtrb_table *
rtrb_create (rtrb_comparison_func *compare, void *param,
            struct libavl_allocator *allocator)
{
  struct rtrb_table *tree;

  assert (compare != NULL);

  if (allocator == NULL)
    allocator = &rtrb_allocator_default;

  tree = allocator->libavl_malloc (allocator, sizeof *tree);
  if (tree == NULL)
    return NULL;

  tree->rtrb_root = NULL;
  tree->rtrb_compare = compare;
  tree->rtrb_param = param;
  tree->rtrb_alloc = allocator;
  tree->rtrb_count = 0;

  return tree;
}

/* Search |tree| for an item matching |item|, and return it if found.
   Otherwise return |NULL|. */
void *
rtrb_find (const struct rtrb_table *tree, const void *item)
{
  const struct rtrb_node *p;
  int dir;

  assert (tree != NULL && item != NULL);

  if (tree->rtrb_root == NULL)
    return NULL;

  for (p = tree->rtrb_root; ; p = p->rtrb_link[dir])
    {
      int cmp = tree->rtrb_compare (item, p->rtrb_data, tree->rtrb_param);
      if (cmp == 0)
        return p->rtrb_data;
      dir = cmp > 0;

      if (dir == 0)
        {
          if (p->rtrb_link[0] == NULL)
            return NULL;
        }
      else /* |dir == 1| */
        {
          if (p->rtrb_rtag == RTRB_THREAD)
            return NULL;
        }
    }
}

/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree,
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
void **
rtrb_probe (struct rtrb_table *tree, void *item)
{
  struct rtrb_node *pa[RTRB_MAX_HEIGHT]; /* Nodes on stack. */
  unsigned char da[RTRB_MAX_HEIGHT];   /* Directions moved from stack nodes. */
  int k;                               /* Stack height. */

  struct rtrb_node *p; /* Current node in search. */
  struct rtrb_node *n; /* New node. */
  int dir;             /* Side of |p| on which |p| is located. */

  assert (tree != NULL && item != NULL);

  da[0] = 0;
  pa[0] = (struct rtrb_node *) &tree->rtrb_root;
  k = 1;
  if (tree->rtrb_root != NULL)
    for (p = tree->rtrb_root; ; p = p->rtrb_link[dir])
      {
        int cmp = tree->rtrb_compare (item, p->rtrb_data, tree->rtrb_param);
        if (cmp == 0)
          return &p->rtrb_data;

        pa[k] = p;
        da[k++] = dir = cmp > 0;

        if (dir == 0)
          {
            if (p->rtrb_link[0] == NULL)
              break;
          }
        else /* |dir == 1| */
          {
            if (p->rtrb_rtag == RTRB_THREAD)
              break;
          }
      }
  else
    {
      p = (struct rtrb_node *) &tree->rtrb_root;
      dir = 0;
    }

  n = tree->rtrb_alloc->libavl_malloc (tree->rtrb_alloc, sizeof *n);
  if (n == NULL)
    return NULL;

  tree->rtrb_count++;
  n->rtrb_data = item;
  n->rtrb_link[0] = NULL;
  if (dir == 0)
    {
      if (tree->rtrb_root != NULL)
        n->rtrb_link[1] = p;
      else
        n->rtrb_link[1] = NULL;
    }
  else /* |dir == 1| */
    {
      p->rtrb_rtag = RTRB_CHILD;
      n->rtrb_link[1] = p->rtrb_link[1];
    }
  n->rtrb_rtag = RTRB_THREAD;
  n->rtrb_color = RTRB_RED;
  p->rtrb_link[dir] = n;

  while (k >= 3 && pa[k - 1]->rtrb_color == RTRB_RED)
    {
      if (da[k - 2] == 0)
        {
          struct rtrb_node *y = pa[k - 2]->rtrb_link[1];
          if (pa[k - 2]->rtrb_rtag == RTRB_CHILD && y->rtrb_color == RTRB_RED)
            {
              pa[k - 1]->rtrb_color = y->rtrb_color = RTRB_BLACK;
              pa[k - 2]->rtrb_color = RTRB_RED;
              k -= 2;
            }
          else
            {
              struct rtrb_node *x;

              if (da[k - 1] == 0)
                y = pa[k - 1];
              else
                {
                  x = pa[k - 1];
                  y = x->rtrb_link[1];
                  x->rtrb_link[1] = y->rtrb_link[0];
                  y->rtrb_link[0] = x;
                  pa[k - 2]->rtrb_link[0] = y;

                  if (x->rtrb_link[1] == NULL)
                    {
                      x->rtrb_rtag = RTRB_THREAD;
                      x->rtrb_link[1] = y;
                    }
                }

              x = pa[k - 2];
              x->rtrb_color = RTRB_RED;
              y->rtrb_color = RTRB_BLACK;

              x->rtrb_link[0] = y->rtrb_link[1];
              y->rtrb_link[1] = x;
              pa[k - 3]->rtrb_link[da[k - 3]] = y;

              if (y->rtrb_rtag == RTRB_THREAD)
                {
                  y->rtrb_rtag = RTRB_CHILD;
                  x->rtrb_link[0] = NULL;
                }
              break;
            }
        }
      else
        {
          struct rtrb_node *y = pa[k - 2]->rtrb_link[0];
          if (pa[k - 2]->rtrb_link[0] != NULL && y->rtrb_color == RTRB_RED)
            {
              pa[k - 1]->rtrb_color = y->rtrb_color = RTRB_BLACK;
              pa[k - 2]->rtrb_color = RTRB_RED;
              k -= 2;
            }
          else
            {
              struct rtrb_node *x;

              if (da[k - 1] == 1)
                y = pa[k - 1];
              else
                {
                  x = pa[k - 1];
                  y = x->rtrb_link[0];
                  x->rtrb_link[0] = y->rtrb_link[1];
                  y->rtrb_link[1] = x;
                  pa[k - 2]->rtrb_link[1] = y;

                  if (y->rtrb_rtag == RTRB_THREAD)
                    {
                      y->rtrb_rtag = RTRB_CHILD;
                      x->rtrb_link[0] = NULL;
                    }
                }

              x = pa[k - 2];
              x->rtrb_color = RTRB_RED;
              y->rtrb_color = RTRB_BLACK;

              x->rtrb_link[1] = y->rtrb_link[0];
              y->rtrb_link[0] = x;
              pa[k - 3]->rtrb_link[da[k - 3]] = y;

              if (x->rtrb_link[1] == NULL)
                {
                  x->rtrb_rtag = RTRB_THREAD;
                  x->rtrb_link[1] = y;
                }
              break;
            }
        }
    }
  tree->rtrb_root->rtrb_color = RTRB_BLACK;

  return &n->rtrb_data;
}

/* Inserts |item| into |table|.
   Returns |NULL| if |item| was successfully inserted
   or if a memory allocation error occurred.
   Otherwise, returns the duplicate item. */
void *
rtrb_insert (struct rtrb_table *table, void *item)
{
  void **p = rtrb_probe (table, item);
  return p == NULL || *p == item ? NULL : *p;
}

/* Inserts |item| into |table|, replacing any duplicate item.
   Returns |NULL| if |item| was inserted without replacing a duplicate,
   or if a memory allocation error occurred.
   Otherwise, returns the item that was replaced. */
void *
rtrb_replace (struct rtrb_table *table, void *item)
{
  void **p = rtrb_probe (table, item);
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
rtrb_delete (struct rtrb_table *tree, const void *item)
{
  struct rtrb_node *pa[RTRB_MAX_HEIGHT]; /* Nodes on stack. */
  unsigned char da[RTRB_MAX_HEIGHT];   /* Directions moved from stack nodes. */
  int k;                               /* Stack height. */

  struct rtrb_node *p;

  assert (tree != NULL && item != NULL);

  k = 1;
  da[0] = 0;
  pa[0] = (struct rtrb_node *) &tree->rtrb_root;
  p = tree->rtrb_root;
  if (p == NULL)
    return NULL;

  for (;;)
    {
      int cmp, dir;

      cmp = tree->rtrb_compare (item, p->rtrb_data, tree->rtrb_param);
      if (cmp == 0)
        break;

      dir = cmp > 0;
      if (dir == 0)
        {
          if (p->rtrb_link[0] == NULL)
            return NULL;
        }
      else /* |dir == 1| */
        {
          if (p->rtrb_rtag == RTRB_THREAD)
            return NULL;
        }

      pa[k] = p;
      da[k++] = dir;
      p = p->rtrb_link[dir];
    }
  tree->rtrb_count--;
  item = p->rtrb_data;

  if (p->rtrb_link[0] == NULL)
    {
      if (p->rtrb_rtag == RTRB_CHILD)
        {
          pa[k - 1]->rtrb_link[da[k - 1]] = p->rtrb_link[1];
        }
      else
        {
          pa[k - 1]->rtrb_link[da[k - 1]] = p->rtrb_link[da[k - 1]];
          if (da[k - 1] == 1)
            pa[k - 1]->rtrb_rtag = RTRB_THREAD;
        }
    }
  else
    {
      enum rtrb_color t;
      struct rtrb_node *r = p->rtrb_link[0];

      if (r->rtrb_rtag == RTRB_THREAD)
        {
          r->rtrb_link[1] = p->rtrb_link[1];
          r->rtrb_rtag = p->rtrb_rtag;
          t = r->rtrb_color;
          r->rtrb_color = p->rtrb_color;
          p->rtrb_color = t;
          pa[k - 1]->rtrb_link[da[k - 1]] = r;
          da[k] = 0;
          pa[k++] = r;
        }
      else
        {
          struct rtrb_node *s;
          int j = k++;

          for (;;)
            {
              da[k] = 1;
              pa[k++] = r;
              s = r->rtrb_link[1];
              if (s->rtrb_rtag == RTRB_THREAD)
                break;

              r = s;
            }

          da[j] = 0;
          pa[j] = pa[j - 1]->rtrb_link[da[j - 1]] = s;

          if (s->rtrb_link[0] != NULL)
            r->rtrb_link[1] = s->rtrb_link[0];
          else
            {
              r->rtrb_rtag = RTRB_THREAD;
              r->rtrb_link[1] = s;
            }

          s->rtrb_link[0] = p->rtrb_link[0];
          s->rtrb_link[1] = p->rtrb_link[1];
          s->rtrb_rtag = p->rtrb_rtag;

          t = s->rtrb_color;
          s->rtrb_color = p->rtrb_color;
          p->rtrb_color = t;
        }
    }

  if (p->rtrb_color == RTRB_BLACK)
    {
      for (; k > 1; k--)
        {
          struct rtrb_node *x;
          if (da[k - 1] == 0 || pa[k - 1]->rtrb_rtag == RTRB_CHILD)
            x = pa[k - 1]->rtrb_link[da[k - 1]];
          else
            x = NULL;
          if (x != NULL && x->rtrb_color == RTRB_RED)
            {
              x->rtrb_color = RTRB_BLACK;
              break;
            }

          if (da[k - 1] == 0)
            {
              struct rtrb_node *w = pa[k - 1]->rtrb_link[1];

              if (w->rtrb_color == RTRB_RED)
                {
                  w->rtrb_color = RTRB_BLACK;
                  pa[k - 1]->rtrb_color = RTRB_RED;

                  pa[k - 1]->rtrb_link[1] = w->rtrb_link[0];
                  w->rtrb_link[0] = pa[k - 1];
                  pa[k - 2]->rtrb_link[da[k - 2]] = w;

                  pa[k] = pa[k - 1];
                  da[k] = 0;
                  pa[k - 1] = w;
                  k++;

                  w = pa[k - 1]->rtrb_link[1];
                }

              if ((w->rtrb_link[0] == NULL
                   || w->rtrb_link[0]->rtrb_color == RTRB_BLACK)
                  && (w->rtrb_rtag == RTRB_THREAD
                      || w->rtrb_link[1]->rtrb_color == RTRB_BLACK))
                {
                  w->rtrb_color = RTRB_RED;
                }
              else
                {
                  if (w->rtrb_rtag == RTRB_THREAD
                      || w->rtrb_link[1]->rtrb_color == RTRB_BLACK)
                    {
                      struct rtrb_node *y = w->rtrb_link[0];
                      y->rtrb_color = RTRB_BLACK;
                      w->rtrb_color = RTRB_RED;
                      w->rtrb_link[0] = y->rtrb_link[1];
                      y->rtrb_link[1] = w;
                      w = pa[k - 1]->rtrb_link[1] = y;

                      if (w->rtrb_rtag == RTRB_THREAD)
                        {
                          w->rtrb_rtag = RTRB_CHILD;
                          w->rtrb_link[1]->rtrb_link[0] = NULL;
                        }
                    }

                  w->rtrb_color = pa[k - 1]->rtrb_color;
                  pa[k - 1]->rtrb_color = RTRB_BLACK;
                  w->rtrb_link[1]->rtrb_color = RTRB_BLACK;

                  pa[k - 1]->rtrb_link[1] = w->rtrb_link[0];
                  w->rtrb_link[0] = pa[k - 1];
                  pa[k - 2]->rtrb_link[da[k - 2]] = w;

                  if (w->rtrb_link[0]->rtrb_link[1] == NULL)
                    {
                      w->rtrb_link[0]->rtrb_rtag = RTRB_THREAD;
                      w->rtrb_link[0]->rtrb_link[1] = w;
                    }
                  break;
                }
            }
          else
            {
              struct rtrb_node *w = pa[k - 1]->rtrb_link[0];

              if (w->rtrb_color == RTRB_RED)
                {
                  w->rtrb_color = RTRB_BLACK;
                  pa[k - 1]->rtrb_color = RTRB_RED;

                  pa[k - 1]->rtrb_link[0] = w->rtrb_link[1];
                  w->rtrb_link[1] = pa[k - 1];
                  pa[k - 2]->rtrb_link[da[k - 2]] = w;

                  pa[k] = pa[k - 1];
                  da[k] = 1;
                  pa[k - 1] = w;
                  k++;

                  w = pa[k - 1]->rtrb_link[0];
                }

              if ((w->rtrb_link[0] == NULL
                   || w->rtrb_link[0]->rtrb_color == RTRB_BLACK)
                  && (w->rtrb_rtag == RTRB_THREAD
                      || w->rtrb_link[1]->rtrb_color == RTRB_BLACK))
                {
                  w->rtrb_color = RTRB_RED;
                }
              else
                {
                  if (w->rtrb_link[0] == NULL
                      || w->rtrb_link[0]->rtrb_color == RTRB_BLACK)
                    {
                      struct rtrb_node *y = w->rtrb_link[1];
                      y->rtrb_color = RTRB_BLACK;
                      w->rtrb_color = RTRB_RED;
                      w->rtrb_link[1] = y->rtrb_link[0];
                      y->rtrb_link[0] = w;
                      w = pa[k - 1]->rtrb_link[0] = y;

                      if (w->rtrb_link[0]->rtrb_link[1] == NULL)
                        {
                          w->rtrb_link[0]->rtrb_rtag = RTRB_THREAD;
                          w->rtrb_link[0]->rtrb_link[1] = w;
                        }
                    }

                  w->rtrb_color = pa[k - 1]->rtrb_color;
                  pa[k - 1]->rtrb_color = RTRB_BLACK;
                  w->rtrb_link[0]->rtrb_color = RTRB_BLACK;

                  pa[k - 1]->rtrb_link[0] = w->rtrb_link[1];
                  w->rtrb_link[1] = pa[k - 1];
                  pa[k - 2]->rtrb_link[da[k - 2]] = w;

                  if (w->rtrb_rtag == RTRB_THREAD)
                    {
                      w->rtrb_rtag = RTRB_CHILD;
                      pa[k - 1]->rtrb_link[0] = NULL;
                    }
                  break;
                }
            }
        }

      if (tree->rtrb_root != NULL)
        tree->rtrb_root->rtrb_color = RTRB_BLACK;
    }

  tree->rtrb_alloc->libavl_free (tree->rtrb_alloc, p);
  return (void *) item;
}

/* Initializes |trav| for use with |tree|
   and selects the null node. */
void
rtrb_t_init (struct rtrb_traverser *trav, struct rtrb_table *tree)
{
  trav->rtrb_table = tree;
  trav->rtrb_node = NULL;
}

/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the least value,
   or |NULL| if |tree| is empty. */
void *
rtrb_t_first (struct rtrb_traverser *trav, struct rtrb_table *tree)
{
  assert (tree != NULL && trav != NULL);

  trav->rtrb_table = tree;
  trav->rtrb_node = tree->rtrb_root;
  if (trav->rtrb_node != NULL)
    {
      while (trav->rtrb_node->rtrb_link[0] != NULL)
        trav->rtrb_node = trav->rtrb_node->rtrb_link[0];
      return trav->rtrb_node->rtrb_data;
    }
  else
    return NULL;
}

/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the greatest value,
   or |NULL| if |tree| is empty. */
void *
rtrb_t_last (struct rtrb_traverser *trav, struct rtrb_table *tree)
{
  assert (tree != NULL && trav != NULL);

  trav->rtrb_table = tree;
  trav->rtrb_node = tree->rtrb_root;
  if (trav->rtrb_node != NULL)
    {
      while (trav->rtrb_node->rtrb_rtag == RTRB_CHILD)
        trav->rtrb_node = trav->rtrb_node->rtrb_link[1];
      return trav->rtrb_node->rtrb_data;
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
rtrb_t_find (struct rtrb_traverser *trav, struct rtrb_table *tree,
              void *item)
{
  struct rtrb_node *p;

  assert (trav != NULL && tree != NULL && item != NULL);

  trav->rtrb_table = tree;
  trav->rtrb_node = NULL;

  p = tree->rtrb_root;
  if (p == NULL)
    return NULL;

  for (;;)
    {
      int cmp = tree->rtrb_compare (item, p->rtrb_data, tree->rtrb_param);
      if (cmp == 0)
        {
          trav->rtrb_node = p;
          return p->rtrb_data;
        }

      if (cmp < 0)
        {
          p = p->rtrb_link[0];
          if (p == NULL)
            return NULL;
        }
      else
        {
          if (p->rtrb_rtag == RTRB_THREAD)
            return NULL;
          p = p->rtrb_link[1];
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
rtrb_t_insert (struct rtrb_traverser *trav,
               struct rtrb_table *tree, void *item)
{
  void **p;

  assert (trav != NULL && tree != NULL && item != NULL);

  p = rtrb_probe (tree, item);
  if (p != NULL)
    {
      trav->rtrb_table = tree;
      trav->rtrb_node =
        ((struct rtrb_node *)
         ((char *) p - offsetof (struct rtrb_node, rtrb_data)));
      return *p;
    }
  else
    {
      rtrb_t_init (trav, tree);
      return NULL;
    }
}

/* Initializes |trav| to have the same current node as |src|. */
void *
rtrb_t_copy (struct rtrb_traverser *trav, const struct rtrb_traverser *src)
{
  assert (trav != NULL && src != NULL);

  trav->rtrb_table = src->rtrb_table;
  trav->rtrb_node = src->rtrb_node;

  return trav->rtrb_node != NULL ? trav->rtrb_node->rtrb_data : NULL;
}

/* Returns the next data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
void *
rtrb_t_next (struct rtrb_traverser *trav)
{
  assert (trav != NULL);

  if (trav->rtrb_node == NULL)
    return rtrb_t_first (trav, trav->rtrb_table);
  else if (trav->rtrb_node->rtrb_rtag == RTRB_THREAD)
    {
      trav->rtrb_node = trav->rtrb_node->rtrb_link[1];
      return trav->rtrb_node != NULL ? trav->rtrb_node->rtrb_data : NULL;
    }
  else
    {
      trav->rtrb_node = trav->rtrb_node->rtrb_link[1];
      while (trav->rtrb_node->rtrb_link[0] != NULL)
        trav->rtrb_node = trav->rtrb_node->rtrb_link[0];
      return trav->rtrb_node->rtrb_data;
    }
}

/* Returns the previous data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
void *
rtrb_t_prev (struct rtrb_traverser *trav)
{
  assert (trav != NULL);

  if (trav->rtrb_node == NULL)
    return rtrb_t_last (trav, trav->rtrb_table);
  else if (trav->rtrb_node->rtrb_link[0] == NULL)
    {
      rtrb_comparison_func *cmp = trav->rtrb_table->rtrb_compare;
      void *param = trav->rtrb_table->rtrb_param;
      struct rtrb_node *node = trav->rtrb_node;
      struct rtrb_node *i;

      trav->rtrb_node = NULL;
      for (i = trav->rtrb_table->rtrb_root; i != node; )
        {
          int dir = cmp (node->rtrb_data, i->rtrb_data, param) > 0;
          if (dir == 1)
            trav->rtrb_node = i;
          i = i->rtrb_link[dir];
        }

      return trav->rtrb_node != NULL ? trav->rtrb_node->rtrb_data : NULL;
    }
  else
    {
      trav->rtrb_node = trav->rtrb_node->rtrb_link[0];
      while (trav->rtrb_node->rtrb_rtag == RTRB_CHILD)
        trav->rtrb_node = trav->rtrb_node->rtrb_link[1];
      return trav->rtrb_node->rtrb_data;
    }
}

/* Returns |trav|'s current item. */
void *
rtrb_t_cur (struct rtrb_traverser *trav)
{
  assert (trav != NULL);

  return trav->rtrb_node != NULL ? trav->rtrb_node->rtrb_data : NULL;
}

/* Replaces the current item in |trav| by |new| and returns the item replaced.
   |trav| must not have the null item selected.
   The new item must not upset the ordering of the tree. */
void *
rtrb_t_replace (struct rtrb_traverser *trav, void *new)
{
  void *old;

  assert (trav != NULL && trav->rtrb_node != NULL && new != NULL);
  old = trav->rtrb_node->rtrb_data;
  trav->rtrb_node->rtrb_data = new;
  return old;
}

/* Creates a new node as a child of |dst| on side |dir|.
   Copies data from |src| into the new node, applying |copy()|, if non-null.
   Returns nonzero only if fully successful.
   Regardless of success, integrity of the tree structure is assured,
   though failure may leave a null pointer in a |rtrb_data| member. */
static int
copy_node (struct rtrb_table *tree,
           struct rtrb_node *dst, int dir,
           const struct rtrb_node *src, rtrb_copy_func *copy)
{
  struct rtrb_node *new = tree->rtrb_alloc->libavl_malloc (tree->rtrb_alloc,
                                                             sizeof *new);
  if (new == NULL)
    return 0;

  new->rtrb_link[0] = NULL;
  new->rtrb_rtag = RTRB_THREAD;
  if (dir == 0)
    new->rtrb_link[1] = dst;
  else
    {
      new->rtrb_link[1] = dst->rtrb_link[1];
      dst->rtrb_rtag = RTRB_CHILD;
    }
  dst->rtrb_link[dir] = new;

  new->rtrb_color = src->rtrb_color;

  if (copy == NULL)
    new->rtrb_data = src->rtrb_data;
  else
    {
      new->rtrb_data = copy (src->rtrb_data, tree->rtrb_param);
      if (new->rtrb_data == NULL)
        return 0;
    }

  return 1;
}

/* Destroys |new| with |rtrb_destroy (new, destroy)|,
   first initializing right links in |new| that have
   not yet been initialized at time of call. */
static void
copy_error_recovery (struct rtrb_table *new, rtrb_item_func *destroy)
{
  struct rtrb_node *p = new->rtrb_root;
  if (p != NULL)
    {
      while (p->rtrb_rtag == RTRB_CHILD)
        p = p->rtrb_link[1];
      p->rtrb_link[1] = NULL;
    }
  rtrb_destroy (new, destroy);
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
struct rtrb_table *
rtrb_copy (const struct rtrb_table *org, rtrb_copy_func *copy,
            rtrb_item_func *destroy, struct libavl_allocator *allocator)
{
  struct rtrb_table *new;

  const struct rtrb_node *p;
  struct rtrb_node *q;

  assert (org != NULL);
  new = rtrb_create (org->rtrb_compare, org->rtrb_param,
                     allocator != NULL ? allocator : org->rtrb_alloc);
  if (new == NULL)
    return NULL;

  new->rtrb_count = org->rtrb_count;
  if (new->rtrb_count == 0)
    return new;

  p = (struct rtrb_node *) &org->rtrb_root;
  q = (struct rtrb_node *) &new->rtrb_root;
  for (;;)
    {
      if (p->rtrb_link[0] != NULL)
        {
          if (!copy_node (new, q, 0, p->rtrb_link[0], copy))
            {
              copy_error_recovery (new, destroy);
              return NULL;
            }

          p = p->rtrb_link[0];
          q = q->rtrb_link[0];
        }
      else
        {
          while (p->rtrb_rtag == RTRB_THREAD)
            {
              p = p->rtrb_link[1];
              if (p == NULL)
                {
                  q->rtrb_link[1] = NULL;
                  return new;
                }

              q = q->rtrb_link[1];
            }

          p = p->rtrb_link[1];
          q = q->rtrb_link[1];
        }

      if (p->rtrb_rtag == RTRB_CHILD)
        if (!copy_node (new, q, 1, p->rtrb_link[1], copy))
          {
            copy_error_recovery (new, destroy);
            return NULL;
          }
    }
}

/* Frees storage allocated for |tree|.
   If |destroy != NULL|, applies it to each data item in inorder. */
void
rtrb_destroy (struct rtrb_table *tree, rtrb_item_func *destroy)
{
  struct rtrb_node *p; /* Current node. */
  struct rtrb_node *n; /* Next node. */

  p = tree->rtrb_root;
  if (p != NULL)
    while (p->rtrb_link[0] != NULL)
      p = p->rtrb_link[0];

  while (p != NULL)
    {
      n = p->rtrb_link[1];
      if (p->rtrb_rtag == RTRB_CHILD)
        while (n->rtrb_link[0] != NULL)
          n = n->rtrb_link[0];

      if (destroy != NULL && p->rtrb_data != NULL)
        destroy (p->rtrb_data, tree->rtrb_param);
      tree->rtrb_alloc->libavl_free (tree->rtrb_alloc, p);

      p = n;
    }

  tree->rtrb_alloc->libavl_free (tree->rtrb_alloc, tree);
}

/* Allocates |size| bytes of space using |malloc()|.
   Returns a null pointer if allocation fails. */
void *
rtrb_malloc (struct libavl_allocator *allocator, size_t size)
{
  assert (allocator != NULL && size > 0);
  return malloc (size);
}

/* Frees |block|. */
void
rtrb_free (struct libavl_allocator *allocator, void *block)
{
  assert (allocator != NULL && block != NULL);
  free (block);
}

/* Default memory allocator that uses |malloc()| and |free()|. */
struct libavl_allocator rtrb_allocator_default =
  {
    rtrb_malloc,
    rtrb_free
  };

#undef NDEBUG
#include <assert.h>

/* Asserts that |rtrb_insert()| succeeds at inserting |item| into |table|. */
void
(rtrb_assert_insert) (struct rtrb_table *table, void *item)
{
  void **p = rtrb_probe (table, item);
  assert (p != NULL && *p == item);
}

/* Asserts that |rtrb_delete()| really removes |item| from |table|,
   and returns the removed item. */
void *
(rtrb_assert_delete) (struct rtrb_table *table, void *item)
{
  void *p = rtrb_delete (table, item);
  assert (p != NULL);
  return p;
}

