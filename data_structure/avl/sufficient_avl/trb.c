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
#include "trb.h"

/* Creates and returns a new table
   with comparison function |compare| using parameter |param|
   and memory allocator |allocator|.
   Returns |NULL| if memory allocation failed. */
struct trb_table *
trb_create (trb_comparison_func *compare, void *param,
            struct libavl_allocator *allocator)
{
  struct trb_table *tree;

  assert (compare != NULL);

  if (allocator == NULL)
    allocator = &trb_allocator_default;

  tree = allocator->libavl_malloc (allocator, sizeof *tree);
  if (tree == NULL)
    return NULL;

  tree->trb_root = NULL;
  tree->trb_compare = compare;
  tree->trb_param = param;
  tree->trb_alloc = allocator;
  tree->trb_count = 0;

  return tree;
}

/* Search |tree| for an item matching |item|, and return it if found.
   Otherwise return |NULL|. */
void *
trb_find (const struct trb_table *tree, const void *item)
{
  const struct trb_node *p;

  assert (tree != NULL && item != NULL);

  p = tree->trb_root;
  if (p == NULL)
    return NULL;

  for (;;)
    {
      int cmp, dir;

      cmp = tree->trb_compare (item, p->trb_data, tree->trb_param);
      if (cmp == 0)
        return p->trb_data;

      dir = cmp > 0;
      if (p->trb_tag[dir] == TRB_CHILD)
        p = p->trb_link[dir];
      else
        return NULL;
    }
}

/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree,
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
void **
trb_probe (struct trb_table *tree, void *item)
{
  struct trb_node *pa[TRB_MAX_HEIGHT]; /* Nodes on stack. */
  unsigned char da[TRB_MAX_HEIGHT];    /* Directions moved from stack nodes. */
  int k;                               /* Stack height. */

  struct trb_node *p; /* Traverses tree looking for insertion point. */
  struct trb_node *n; /* Newly inserted node. */
  int dir;            /* Side of |p| on which |n| is inserted. */

  assert (tree != NULL && item != NULL);

  da[0] = 0;
  pa[0] = (struct trb_node *) &tree->trb_root;
  k = 1;
  if (tree->trb_root != NULL)
    {
      for (p = tree->trb_root; ; p = p->trb_link[dir])
        {
          int cmp = tree->trb_compare (item, p->trb_data, tree->trb_param);
          if (cmp == 0)
            return &p->trb_data;

          pa[k] = p;
          da[k++] = dir = cmp > 0;

          if (p->trb_tag[dir] == TRB_THREAD)
            break;
        }
    }
  else
    {
      p = (struct trb_node *) &tree->trb_root;
      dir = 0;
    }

  n = tree->trb_alloc->libavl_malloc (tree->trb_alloc, sizeof *n);
  if (n == NULL)
    return NULL;

  tree->trb_count++;
  n->trb_data = item;
  n->trb_tag[0] = n->trb_tag[1] = TRB_THREAD;
  n->trb_link[dir] = p->trb_link[dir];
  if (tree->trb_root != NULL)
    {
      p->trb_tag[dir] = TRB_CHILD;
      n->trb_link[!dir] = p;
    }
  else
    n->trb_link[1] = NULL;
  p->trb_link[dir] = n;
  n->trb_color = TRB_RED;

  while (k >= 3 && pa[k - 1]->trb_color == TRB_RED)
    {
      if (da[k - 2] == 0)
        {
          struct trb_node *y = pa[k - 2]->trb_link[1];
          if (pa[k - 2]->trb_tag[1] == TRB_CHILD && y->trb_color == TRB_RED)
            {
              pa[k - 1]->trb_color = y->trb_color = TRB_BLACK;
              pa[k - 2]->trb_color = TRB_RED;
              k -= 2;
            }
          else
            {
              struct trb_node *x;

              if (da[k - 1] == 0)
                y = pa[k - 1];
              else
                {
                  x = pa[k - 1];
                  y = x->trb_link[1];
                  x->trb_link[1] = y->trb_link[0];
                  y->trb_link[0] = x;
                  pa[k - 2]->trb_link[0] = y;

                  if (y->trb_tag[0] == TRB_THREAD)
                    {
                      y->trb_tag[0] = TRB_CHILD;
                      x->trb_tag[1] = TRB_THREAD;
                      x->trb_link[1] = y;
                    }
                }

              x = pa[k - 2];
              x->trb_color = TRB_RED;
              y->trb_color = TRB_BLACK;

              x->trb_link[0] = y->trb_link[1];
              y->trb_link[1] = x;
              pa[k - 3]->trb_link[da[k - 3]] = y;

              if (y->trb_tag[1] == TRB_THREAD)
                {
                  y->trb_tag[1] = TRB_CHILD;
                  x->trb_tag[0] = TRB_THREAD;
                  x->trb_link[0] = y;
                }
              break;
            }
        }
      else
        {
          struct trb_node *y = pa[k - 2]->trb_link[0];
          if (pa[k - 2]->trb_tag[0] == TRB_CHILD && y->trb_color == TRB_RED)
            {
              pa[k - 1]->trb_color = y->trb_color = TRB_BLACK;
              pa[k - 2]->trb_color = TRB_RED;
              k -= 2;
            }
          else
            {
              struct trb_node *x;

              if (da[k - 1] == 1)
                y = pa[k - 1];
              else
                {
                  x = pa[k - 1];
                  y = x->trb_link[0];
                  x->trb_link[0] = y->trb_link[1];
                  y->trb_link[1] = x;
                  pa[k - 2]->trb_link[1] = y;

                  if (y->trb_tag[1] == TRB_THREAD)
                    {
                      y->trb_tag[1] = TRB_CHILD;
                      x->trb_tag[0] = TRB_THREAD;
                      x->trb_link[0] = y;
                    }
                }

              x = pa[k - 2];
              x->trb_color = TRB_RED;
              y->trb_color = TRB_BLACK;

              x->trb_link[1] = y->trb_link[0];
              y->trb_link[0] = x;
              pa[k - 3]->trb_link[da[k - 3]] = y;

              if (y->trb_tag[0] == TRB_THREAD)
                {
                  y->trb_tag[0] = TRB_CHILD;
                  x->trb_tag[1] = TRB_THREAD;
                  x->trb_link[1] = y;
                }
              break;
            }
        }
    }
  tree->trb_root->trb_color = TRB_BLACK;

  return &n->trb_data;
}

/* Inserts |item| into |table|.
   Returns |NULL| if |item| was successfully inserted
   or if a memory allocation error occurred.
   Otherwise, returns the duplicate item. */
void *
trb_insert (struct trb_table *table, void *item)
{
  void **p = trb_probe (table, item);
  return p == NULL || *p == item ? NULL : *p;
}

/* Inserts |item| into |table|, replacing any duplicate item.
   Returns |NULL| if |item| was inserted without replacing a duplicate,
   or if a memory allocation error occurred.
   Otherwise, returns the item that was replaced. */
void *
trb_replace (struct trb_table *table, void *item)
{
  void **p = trb_probe (table, item);
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
trb_delete (struct trb_table *tree, const void *item)
{
  struct trb_node *pa[TRB_MAX_HEIGHT]; /* Nodes on stack. */
  unsigned char da[TRB_MAX_HEIGHT];    /* Directions moved from stack nodes. */
  int k = 0;                           /* Stack height. */

  struct trb_node *p;
  int cmp, dir;

  assert (tree != NULL && item != NULL);

  if (tree->trb_root == NULL)
    return NULL;

  p = (struct trb_node *) &tree->trb_root;
  for (cmp = -1; cmp != 0;
       cmp = tree->trb_compare (item, p->trb_data, tree->trb_param))
    {
      dir = cmp > 0;
      pa[k] = p;
      da[k++] = dir;

      if (p->trb_tag[dir] == TRB_THREAD)
        return NULL;
      p = p->trb_link[dir];
    }
  item = p->trb_data;

  if (p->trb_tag[1] == TRB_THREAD)
    {
      if (p->trb_tag[0] == TRB_CHILD)
        {
          struct trb_node *t = p->trb_link[0];
          while (t->trb_tag[1] == TRB_CHILD)
            t = t->trb_link[1];
          t->trb_link[1] = p->trb_link[1];
          pa[k - 1]->trb_link[da[k - 1]] = p->trb_link[0];
        }
      else
        {
          pa[k - 1]->trb_link[da[k - 1]] = p->trb_link[da[k - 1]];
          if (pa[k - 1] != (struct trb_node *) &tree->trb_root)
            pa[k - 1]->trb_tag[da[k - 1]] = TRB_THREAD;
        }
    }
  else
    {
      enum trb_color t;
      struct trb_node *r = p->trb_link[1];

      if (r->trb_tag[0] == TRB_THREAD)
        {
          r->trb_link[0] = p->trb_link[0];
          r->trb_tag[0] = p->trb_tag[0];
          if (r->trb_tag[0] == TRB_CHILD)
            {
              struct trb_node *t = r->trb_link[0];
              while (t->trb_tag[1] == TRB_CHILD)
                t = t->trb_link[1];
              t->trb_link[1] = r;
            }
          pa[k - 1]->trb_link[da[k - 1]] = r;
          t = r->trb_color;
          r->trb_color = p->trb_color;
          p->trb_color = t;
          da[k] = 1;
          pa[k++] = r;
        }
      else
        {
          struct trb_node *s;
          int j = k++;

          for (;;)
            {
              da[k] = 0;
              pa[k++] = r;
              s = r->trb_link[0];
              if (s->trb_tag[0] == TRB_THREAD)
                break;

              r = s;
            }

          da[j] = 1;
          pa[j] = s;
          if (s->trb_tag[1] == TRB_CHILD)
            r->trb_link[0] = s->trb_link[1];
          else
            {
              r->trb_link[0] = s;
              r->trb_tag[0] = TRB_THREAD;
            }

          s->trb_link[0] = p->trb_link[0];
          if (p->trb_tag[0] == TRB_CHILD)
            {
              struct trb_node *t = p->trb_link[0];
              while (t->trb_tag[1] == TRB_CHILD)
                t = t->trb_link[1];
              t->trb_link[1] = s;

              s->trb_tag[0] = TRB_CHILD;
            }

          s->trb_link[1] = p->trb_link[1];
          s->trb_tag[1] = TRB_CHILD;

          t = s->trb_color;
          s->trb_color = p->trb_color;
          p->trb_color = t;

          pa[j - 1]->trb_link[da[j - 1]] = s;

        }
    }

  if (p->trb_color == TRB_BLACK)
    {
      for (; k > 1; k--)
        {
          if (pa[k - 1]->trb_tag[da[k - 1]] == TRB_CHILD)
            {
              struct trb_node *x = pa[k - 1]->trb_link[da[k - 1]];
              if (x->trb_color == TRB_RED)
                {
                  x->trb_color = TRB_BLACK;
                  break;
                }
            }

          if (da[k - 1] == 0)
            {
              struct trb_node *w = pa[k - 1]->trb_link[1];

              if (w->trb_color == TRB_RED)
                {
                  w->trb_color = TRB_BLACK;
                  pa[k - 1]->trb_color = TRB_RED;

                  pa[k - 1]->trb_link[1] = w->trb_link[0];
                  w->trb_link[0] = pa[k - 1];
                  pa[k - 2]->trb_link[da[k - 2]] = w;

                  pa[k] = pa[k - 1];
                  da[k] = 0;
                  pa[k - 1] = w;
                  k++;

                  w = pa[k - 1]->trb_link[1];
                }

              if ((w->trb_tag[0] == TRB_THREAD
                   || w->trb_link[0]->trb_color == TRB_BLACK)
                  && (w->trb_tag[1] == TRB_THREAD
                      || w->trb_link[1]->trb_color == TRB_BLACK))
                {
                  w->trb_color = TRB_RED;
                }
              else
                {
                  if (w->trb_tag[1] == TRB_THREAD
                      || w->trb_link[1]->trb_color == TRB_BLACK)
                    {
                      struct trb_node *y = w->trb_link[0];
                      y->trb_color = TRB_BLACK;
                      w->trb_color = TRB_RED;
                      w->trb_link[0] = y->trb_link[1];
                      y->trb_link[1] = w;
                      w = pa[k - 1]->trb_link[1] = y;

                      if (w->trb_tag[1] == TRB_THREAD)
                        {
                          w->trb_tag[1] = TRB_CHILD;
                          w->trb_link[1]->trb_tag[0] = TRB_THREAD;
                          w->trb_link[1]->trb_link[0] = w;
                        }
                    }

                  w->trb_color = pa[k - 1]->trb_color;
                  pa[k - 1]->trb_color = TRB_BLACK;
                  w->trb_link[1]->trb_color = TRB_BLACK;

                  pa[k - 1]->trb_link[1] = w->trb_link[0];
                  w->trb_link[0] = pa[k - 1];
                  pa[k - 2]->trb_link[da[k - 2]] = w;

                  if (w->trb_tag[0] == TRB_THREAD)
                    {
                      w->trb_tag[0] = TRB_CHILD;
                      pa[k - 1]->trb_tag[1] = TRB_THREAD;
                      pa[k - 1]->trb_link[1] = w;
                    }
                  break;
                }
            }
          else
            {
              struct trb_node *w = pa[k - 1]->trb_link[0];

              if (w->trb_color == TRB_RED)
                {
                  w->trb_color = TRB_BLACK;
                  pa[k - 1]->trb_color = TRB_RED;

                  pa[k - 1]->trb_link[0] = w->trb_link[1];
                  w->trb_link[1] = pa[k - 1];
                  pa[k - 2]->trb_link[da[k - 2]] = w;

                  pa[k] = pa[k - 1];
                  da[k] = 1;
                  pa[k - 1] = w;
                  k++;

                  w = pa[k - 1]->trb_link[0];
                }

              if ((w->trb_tag[0] == TRB_THREAD
                   || w->trb_link[0]->trb_color == TRB_BLACK)
                  && (w->trb_tag[1] == TRB_THREAD
                      || w->trb_link[1]->trb_color == TRB_BLACK))
                {
                  w->trb_color = TRB_RED;
                }
              else
                {
                  if (w->trb_tag[0] == TRB_THREAD
                      || w->trb_link[0]->trb_color == TRB_BLACK)
                    {
                      struct trb_node *y = w->trb_link[1];
                      y->trb_color = TRB_BLACK;
                      w->trb_color = TRB_RED;
                      w->trb_link[1] = y->trb_link[0];
                      y->trb_link[0] = w;
                      w = pa[k - 1]->trb_link[0] = y;

                      if (w->trb_tag[0] == TRB_THREAD)
                        {
                          w->trb_tag[0] = TRB_CHILD;
                          w->trb_link[0]->trb_tag[1] = TRB_THREAD;
                          w->trb_link[0]->trb_link[1] = w;
                        }
                    }

                  w->trb_color = pa[k - 1]->trb_color;
                  pa[k - 1]->trb_color = TRB_BLACK;
                  w->trb_link[0]->trb_color = TRB_BLACK;

                  pa[k - 1]->trb_link[0] = w->trb_link[1];
                  w->trb_link[1] = pa[k - 1];
                  pa[k - 2]->trb_link[da[k - 2]] = w;

                  if (w->trb_tag[1] == TRB_THREAD)
                    {
                      w->trb_tag[1] = TRB_CHILD;
                      pa[k - 1]->trb_tag[0] = TRB_THREAD;
                      pa[k - 1]->trb_link[0] = w;
                    }
                  break;
                }
            }
        }

      if (tree->trb_root != NULL)
        tree->trb_root->trb_color = TRB_BLACK;
    }

  tree->trb_alloc->libavl_free (tree->trb_alloc, p);
  tree->trb_count--;
  return (void *) item;
}

/* Initializes |trav| for use with |tree|
   and selects the null node. */
void
trb_t_init (struct trb_traverser *trav, struct trb_table *tree)
{
  trav->trb_table = tree;
  trav->trb_node = NULL;
}

/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the least value,
   or |NULL| if |tree| is empty. */
void *
trb_t_first (struct trb_traverser *trav, struct trb_table *tree)
{
  assert (tree != NULL && trav != NULL);

  trav->trb_table = tree;
  trav->trb_node = tree->trb_root;
  if (trav->trb_node != NULL)
    {
      while (trav->trb_node->trb_tag[0] == TRB_CHILD)
        trav->trb_node = trav->trb_node->trb_link[0];
      return trav->trb_node->trb_data;
    }
  else
    return NULL;
}

/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the greatest value,
   or |NULL| if |tree| is empty. */
void *
trb_t_last (struct trb_traverser *trav, struct trb_table *tree)
{
  assert (tree != NULL && trav != NULL);

  trav->trb_table = tree;
  trav->trb_node = tree->trb_root;
  if (trav->trb_node != NULL)
    {
      while (trav->trb_node->trb_tag[1] == TRB_CHILD)
        trav->trb_node = trav->trb_node->trb_link[1];
      return trav->trb_node->trb_data;
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
trb_t_find (struct trb_traverser *trav, struct trb_table *tree, void *item)
{
  struct trb_node *p;

  assert (trav != NULL && tree != NULL && item != NULL);

  trav->trb_table = tree;
  trav->trb_node = NULL;

  p = tree->trb_root;
  if (p == NULL)
    return NULL;

  for (;;)
    {
      int cmp, dir;

      cmp = tree->trb_compare (item, p->trb_data, tree->trb_param);
      if (cmp == 0)
        {
          trav->trb_node = p;
          return p->trb_data;
        }

      dir = cmp > 0;
      if (p->trb_tag[dir] == TRB_CHILD)
        p = p->trb_link[dir];
      else
        return NULL;
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
trb_t_insert (struct trb_traverser *trav,
               struct trb_table *tree, void *item)
{
  void **p;

  assert (trav != NULL && tree != NULL && item != NULL);

  p = trb_probe (tree, item);
  if (p != NULL)
    {
      trav->trb_table = tree;
      trav->trb_node =
        ((struct trb_node *)
         ((char *) p - offsetof (struct trb_node, trb_data)));
      return *p;
    }
  else
    {
      trb_t_init (trav, tree);
      return NULL;
    }
}

/* Initializes |trav| to have the same current node as |src|. */
void *
trb_t_copy (struct trb_traverser *trav, const struct trb_traverser *src)
{
  assert (trav != NULL && src != NULL);

  trav->trb_table = src->trb_table;
  trav->trb_node = src->trb_node;

  return trav->trb_node != NULL ? trav->trb_node->trb_data : NULL;
}

/* Returns the next data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
void *
trb_t_next (struct trb_traverser *trav)
{
  assert (trav != NULL);

  if (trav->trb_node == NULL)
    return trb_t_first (trav, trav->trb_table);
  else if (trav->trb_node->trb_tag[1] == TRB_THREAD)
    {
      trav->trb_node = trav->trb_node->trb_link[1];
      return trav->trb_node != NULL ? trav->trb_node->trb_data : NULL;
    }
  else
    {
      trav->trb_node = trav->trb_node->trb_link[1];
      while (trav->trb_node->trb_tag[0] == TRB_CHILD)
        trav->trb_node = trav->trb_node->trb_link[0];
      return trav->trb_node->trb_data;
    }
}

/* Returns the previous data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
void *
trb_t_prev (struct trb_traverser *trav)
{
  assert (trav != NULL);

  if (trav->trb_node == NULL)
    return trb_t_last (trav, trav->trb_table);
  else if (trav->trb_node->trb_tag[0] == TRB_THREAD)
    {
      trav->trb_node = trav->trb_node->trb_link[0];
      return trav->trb_node != NULL ? trav->trb_node->trb_data : NULL;
    }
  else
    {
      trav->trb_node = trav->trb_node->trb_link[0];
      while (trav->trb_node->trb_tag[1] == TRB_CHILD)
        trav->trb_node = trav->trb_node->trb_link[1];
      return trav->trb_node->trb_data;
    }
}

/* Returns |trav|'s current item. */
void *
trb_t_cur (struct trb_traverser *trav)
{
  assert (trav != NULL);

  return trav->trb_node != NULL ? trav->trb_node->trb_data : NULL;
}

/* Replaces the current item in |trav| by |new| and returns the item replaced.
   |trav| must not have the null item selected.
   The new item must not upset the ordering of the tree. */
void *
trb_t_replace (struct trb_traverser *trav, void *new)
{
  void *old;

  assert (trav != NULL && trav->trb_node != NULL && new != NULL);
  old = trav->trb_node->trb_data;
  trav->trb_node->trb_data = new;
  return old;
}

/* Creates a new node as a child of |dst| on side |dir|.
   Copies data and |trb_color| from |src| into the new node,
   applying |copy()|, if non-null.
   Returns nonzero only if fully successful.
   Regardless of success, integrity of the tree structure is assured,
   though failure may leave a null pointer in a |trb_data| member. */
static int
copy_node (struct trb_table *tree,
           struct trb_node *dst, int dir,
           const struct trb_node *src, trb_copy_func *copy)
{
  struct trb_node *new =
    tree->trb_alloc->libavl_malloc (tree->trb_alloc, sizeof *new);
  if (new == NULL)
    return 0;

  new->trb_link[dir] = dst->trb_link[dir];
  new->trb_tag[dir] = TRB_THREAD;
  new->trb_link[!dir] = dst;
  new->trb_tag[!dir] = TRB_THREAD;
  dst->trb_link[dir] = new;
  dst->trb_tag[dir] = TRB_CHILD;

  new->trb_color = src->trb_color;
  if (copy == NULL)
    new->trb_data = src->trb_data;
  else
    {
      new->trb_data = copy (src->trb_data, tree->trb_param);
      if (new->trb_data == NULL)
        return 0;
    }

  return 1;
}

/* Destroys |new| with |trb_destroy (new, destroy)|,
   first initializing the right link in |new| that has
   not yet been initialized. */
static void
copy_error_recovery (struct trb_node *p,
                     struct trb_table *new, trb_item_func *destroy)
{
  new->trb_root = p;
  if (p != NULL)
    {
      while (p->trb_tag[1] == TRB_CHILD)
        p = p->trb_link[1];
      p->trb_link[1] = NULL;
    }
  trb_destroy (new, destroy);
}

/* Copies |org| to a newly created tree, which is returned.
   If |copy != NULL|, each data item in |org| is first passed to |copy|,
   and the return values are inserted into the tree,
   with |NULL| return values taken as indications of failure.
   On failure, destroys the partially created new tree,
   applying |destroy|, if non-null, to each item in the new tree so far,
   and returns |NULL|.
   If |allocator != NULL|, it is used for allocation in the new tree.
   Otherwise, the same allocator used for |org| is used. */
struct trb_table *
trb_copy (const struct trb_table *org, trb_copy_func *copy,
          trb_item_func *destroy, struct libavl_allocator *allocator)
{
  struct trb_table *new;

  const struct trb_node *p;
  struct trb_node *q;
  struct trb_node rp, rq;

  assert (org != NULL);
  new = trb_create (org->trb_compare, org->trb_param,
                     allocator != NULL ? allocator : org->trb_alloc);
  if (new == NULL)
    return NULL;

  new->trb_count = org->trb_count;
  if (new->trb_count == 0)
    return new;

  p = &rp;
  rp.trb_link[0] = org->trb_root;
  rp.trb_tag[0] = TRB_CHILD;

  q = &rq;
  rq.trb_link[0] = NULL;
  rq.trb_tag[0] = TRB_THREAD;

  for (;;)
    {
      if (p->trb_tag[0] == TRB_CHILD)
        {
          if (!copy_node (new, q, 0, p->trb_link[0], copy))
            {
              copy_error_recovery (rq.trb_link[0], new, destroy);
              return NULL;
            }

          p = p->trb_link[0];
          q = q->trb_link[0];
        }
      else
        {
          while (p->trb_tag[1] == TRB_THREAD)
            {
              p = p->trb_link[1];
              if (p == NULL)
                {
                  q->trb_link[1] = NULL;
                  new->trb_root = rq.trb_link[0];
                  return new;
                }

              q = q->trb_link[1];
            }

          p = p->trb_link[1];
          q = q->trb_link[1];
        }

      if (p->trb_tag[1] == TRB_CHILD)
        if (!copy_node (new, q, 1, p->trb_link[1], copy))
          {
            copy_error_recovery (rq.trb_link[0], new, destroy);
            return NULL;
          }
    }
}

/* Frees storage allocated for |tree|.
   If |destroy != NULL|, applies it to each data item in inorder. */
void
trb_destroy (struct trb_table *tree, trb_item_func *destroy)
{
  struct trb_node *p; /* Current node. */
  struct trb_node *n; /* Next node. */

  p = tree->trb_root;
  if (p != NULL)
    while (p->trb_tag[0] == TRB_CHILD)
      p = p->trb_link[0];

  while (p != NULL)
    {
      n = p->trb_link[1];
      if (p->trb_tag[1] == TRB_CHILD)
        while (n->trb_tag[0] == TRB_CHILD)
          n = n->trb_link[0];

      if (destroy != NULL && p->trb_data != NULL)
        destroy (p->trb_data, tree->trb_param);
      tree->trb_alloc->libavl_free (tree->trb_alloc, p);

      p = n;
    }

  tree->trb_alloc->libavl_free (tree->trb_alloc, tree);
}

/* Allocates |size| bytes of space using |malloc()|.
   Returns a null pointer if allocation fails. */
void *
trb_malloc (struct libavl_allocator *allocator, size_t size)
{
  assert (allocator != NULL && size > 0);
  return malloc (size);
}

/* Frees |block|. */
void
trb_free (struct libavl_allocator *allocator, void *block)
{
  assert (allocator != NULL && block != NULL);
  free (block);
}

/* Default memory allocator that uses |malloc()| and |free()|. */
struct libavl_allocator trb_allocator_default =
  {
    trb_malloc,
    trb_free
  };

#undef NDEBUG
#include <assert.h>

/* Asserts that |trb_insert()| succeeds at inserting |item| into |table|. */
void
(trb_assert_insert) (struct trb_table *table, void *item)
{
  void **p = trb_probe (table, item);
  assert (p != NULL && *p == item);
}

/* Asserts that |trb_delete()| really removes |item| from |table|,
   and returns the removed item. */
void *
(trb_assert_delete) (struct trb_table *table, void *item)
{
  void *p = trb_delete (table, item);
  assert (p != NULL);
  return p;
}

