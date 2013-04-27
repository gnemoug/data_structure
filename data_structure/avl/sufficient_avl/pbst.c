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
#include "pbst.h"

/* Creates and returns a new table
   with comparison function |compare| using parameter |param|
   and memory allocator |allocator|.
   Returns |NULL| if memory allocation failed. */
struct pbst_table *
pbst_create (pbst_comparison_func *compare, void *param,
            struct libavl_allocator *allocator)
{
  struct pbst_table *tree;

  assert (compare != NULL);

  if (allocator == NULL)
    allocator = &pbst_allocator_default;

  tree = allocator->libavl_malloc (allocator, sizeof *tree);
  if (tree == NULL)
    return NULL;

  tree->pbst_root = NULL;
  tree->pbst_compare = compare;
  tree->pbst_param = param;
  tree->pbst_alloc = allocator;
  tree->pbst_count = 0;

  return tree;
}

/* Search |tree| for an item matching |item|, and return it if found.
   Otherwise return |NULL|. */
void *
pbst_find (const struct pbst_table *tree, const void *item)
{
  const struct pbst_node *p;

  assert (tree != NULL && item != NULL);
  for (p = tree->pbst_root; p != NULL; )
    {
      int cmp = tree->pbst_compare (item, p->pbst_data, tree->pbst_param);

      if (cmp < 0)
        p = p->pbst_link[0];
      else if (cmp > 0)
        p = p->pbst_link[1];
      else /* |cmp == 0| */
        return p->pbst_data;
    }

  return NULL;
}

/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree,
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
void **
pbst_probe (struct pbst_table *tree, void *item)
{
  struct pbst_node *p, *q; /* Current node in search and its parent. */
  int dir;                 /* Side of |q| on which |p| is located. */
  struct pbst_node *n;     /* Newly inserted node. */

  assert (tree != NULL && item != NULL);

  for (q = NULL, p = tree->pbst_root; p != NULL; q = p, p = p->pbst_link[dir])
    {
      int cmp = tree->pbst_compare (item, p->pbst_data, tree->pbst_param);
      if (cmp == 0)
        return &p->pbst_data;
      dir = cmp > 0;
    }

  n = tree->pbst_alloc->libavl_malloc (tree->pbst_alloc, sizeof *p);
  if (n == NULL)
    return NULL;

  tree->pbst_count++;
  n->pbst_link[0] = n->pbst_link[1] = NULL;
  n->pbst_parent = q;
  n->pbst_data = item;
  if (q != NULL)
    q->pbst_link[dir] = n;
  else
    tree->pbst_root = n;

  return &n->pbst_data;
}

/* Inserts |item| into |table|.
   Returns |NULL| if |item| was successfully inserted
   or if a memory allocation error occurred.
   Otherwise, returns the duplicate item. */
void *
pbst_insert (struct pbst_table *table, void *item)
{
  void **p = pbst_probe (table, item);
  return p == NULL || *p == item ? NULL : *p;
}

/* Inserts |item| into |table|, replacing any duplicate item.
   Returns |NULL| if |item| was inserted without replacing a duplicate,
   or if a memory allocation error occurred.
   Otherwise, returns the item that was replaced. */
void *
pbst_replace (struct pbst_table *table, void *item)
{
  void **p = pbst_probe (table, item);
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
pbst_delete (struct pbst_table *tree, const void *item)
{
  struct pbst_node *p; /* Traverses tree to find node to delete. */
  struct pbst_node *q; /* Parent of |p|. */
  int dir;             /* Side of |q| on which |p| is linked. */

  assert (tree != NULL && item != NULL);

  if (tree->pbst_root == NULL)
    return NULL;

  p = tree->pbst_root;
  for (;;)
    {
      int cmp = tree->pbst_compare (item, p->pbst_data, tree->pbst_param);
      if (cmp == 0)
        break;

      dir = cmp > 0;
      p = p->pbst_link[dir];
      if (p == NULL)
        return NULL;
    }
  item = p->pbst_data;

  q = p->pbst_parent;
  if (q == NULL)
    {
      q = (struct pbst_node *) &tree->pbst_root;
      dir = 0;
    }

  if (p->pbst_link[1] == NULL)
    {
      q->pbst_link[dir] = p->pbst_link[0];
      if (q->pbst_link[dir] != NULL)
        q->pbst_link[dir]->pbst_parent = p->pbst_parent;
    }
  else
    {
      struct pbst_node *r = p->pbst_link[1];
      if (r->pbst_link[0] == NULL)
        {
          r->pbst_link[0] = p->pbst_link[0];
          q->pbst_link[dir] = r;
          r->pbst_parent = p->pbst_parent;
          if (r->pbst_link[0] != NULL)
            r->pbst_link[0]->pbst_parent = r;
        }
      else
        {
          struct pbst_node *s = r->pbst_link[0];
          while (s->pbst_link[0] != NULL)
            s = s->pbst_link[0];
          r = s->pbst_parent;
          r->pbst_link[0] = s->pbst_link[1];
          s->pbst_link[0] = p->pbst_link[0];
          s->pbst_link[1] = p->pbst_link[1];
          q->pbst_link[dir] = s;
          if (s->pbst_link[0] != NULL)
            s->pbst_link[0]->pbst_parent = s;
          s->pbst_link[1]->pbst_parent = s;
          s->pbst_parent = p->pbst_parent;
          if (r->pbst_link[0] != NULL)
            r->pbst_link[0]->pbst_parent = r;
        }
    }

  tree->pbst_alloc->libavl_free (tree->pbst_alloc, p);
  tree->pbst_count--;
  return (void *) item;
}

/* Initializes |trav| for use with |tree|
   and selects the null node. */
void
pbst_t_init (struct pbst_traverser *trav, struct pbst_table *tree)
{
  trav->pbst_table = tree;
  trav->pbst_node = NULL;
}

/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the least value,
   or |NULL| if |tree| is empty. */
void *
pbst_t_first (struct pbst_traverser *trav, struct pbst_table *tree)
{
  assert (tree != NULL && trav != NULL);

  trav->pbst_table = tree;
  trav->pbst_node = tree->pbst_root;
  if (trav->pbst_node != NULL)
    {
      while (trav->pbst_node->pbst_link[0] != NULL)
        trav->pbst_node = trav->pbst_node->pbst_link[0];
      return trav->pbst_node->pbst_data;
    }
  else
    return NULL;
}

/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the greatest value,
   or |NULL| if |tree| is empty. */
void *
pbst_t_last (struct pbst_traverser *trav, struct pbst_table *tree)
{
  assert (tree != NULL && trav != NULL);

  trav->pbst_table = tree;
  trav->pbst_node = tree->pbst_root;
  if (trav->pbst_node != NULL)
    {
      while (trav->pbst_node->pbst_link[1] != NULL)
        trav->pbst_node = trav->pbst_node->pbst_link[1];
      return trav->pbst_node->pbst_data;
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
pbst_t_find (struct pbst_traverser *trav, struct pbst_table *tree, void *item)
{
  struct pbst_node *p;
  int dir;

  assert (trav != NULL && tree != NULL && item != NULL);

  trav->pbst_table = tree;
  for (p = tree->pbst_root; p != NULL; p = p->pbst_link[dir])
    {
      int cmp = tree->pbst_compare (item, p->pbst_data, tree->pbst_param);
      if (cmp == 0)
        {
          trav->pbst_node = p;
          return p->pbst_data;
        }

      dir = cmp > 0;
    }

  trav->pbst_node = NULL;
  return NULL;
}

/* Attempts to insert |item| into |tree|.
   If |item| is inserted successfully, it is returned and |trav| is
   initialized to its location.
   If a duplicate is found, it is returned and |trav| is initialized to
   its location.  No replacement of the item occurs.
   If a memory allocation failure occurs, |NULL| is returned and |trav|
   is initialized to the null item. */
void *
pbst_t_insert (struct pbst_traverser *trav, struct pbst_table *tree,
               void *item)
{
  struct pbst_node *p, *q; /* Current node in search and its parent. */
  int dir;                 /* Side of |q| on which |p| is located. */
  struct pbst_node *n;     /* Newly inserted node. */

  assert (trav != NULL && tree != NULL && item != NULL);

  trav->pbst_table = tree;
  for (q = NULL, p = tree->pbst_root; p != NULL; q = p, p = p->pbst_link[dir])
    {
      int cmp = tree->pbst_compare (item, p->pbst_data, tree->pbst_param);
      if (cmp == 0)
        {
          trav->pbst_node = p;
          return p->pbst_data;
        }
      dir = cmp > 0;
    }

  trav->pbst_node = n =
    tree->pbst_alloc->libavl_malloc (tree->pbst_alloc, sizeof *p);
  if (n == NULL)
    return NULL;

  tree->pbst_count++;
  n->pbst_link[0] = n->pbst_link[1] = NULL;
  n->pbst_parent = q;
  n->pbst_data = item;
  if (q != NULL)
    q->pbst_link[dir] = n;
  else
    tree->pbst_root = n;

  return item;
}

/* Initializes |trav| to have the same current node as |src|. */
void *
pbst_t_copy (struct pbst_traverser *trav, const struct pbst_traverser *src)
{
  assert (trav != NULL && src != NULL);

  trav->pbst_table = src->pbst_table;
  trav->pbst_node = src->pbst_node;

  return trav->pbst_node != NULL ? trav->pbst_node->pbst_data : NULL;
}

/* Returns the next data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
void *
pbst_t_next (struct pbst_traverser *trav)
{
  assert (trav != NULL);

  if (trav->pbst_node == NULL)
    return pbst_t_first (trav, trav->pbst_table);
  else if (trav->pbst_node->pbst_link[1] == NULL)
    {
      struct pbst_node *q, *p; /* Current node and its child. */
      for (p = trav->pbst_node, q = p->pbst_parent; ;
           p = q, q = q->pbst_parent)
        if (q == NULL || p == q->pbst_link[0])
          {
            trav->pbst_node = q;
            return trav->pbst_node != NULL ? trav->pbst_node->pbst_data : NULL;
          }
    }
  else
    {
      trav->pbst_node = trav->pbst_node->pbst_link[1];
      while (trav->pbst_node->pbst_link[0] != NULL)
        trav->pbst_node = trav->pbst_node->pbst_link[0];
      return trav->pbst_node->pbst_data;
    }
}

/* Returns the previous data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
void *
pbst_t_prev (struct pbst_traverser *trav)
{
  assert (trav != NULL);

  if (trav->pbst_node == NULL)
    return pbst_t_last (trav, trav->pbst_table);
  else if (trav->pbst_node->pbst_link[0] == NULL)
    {
      struct pbst_node *q, *p; /* Current node and its child. */
      for (p = trav->pbst_node, q = p->pbst_parent; ;
           p = q, q = q->pbst_parent)
        if (q == NULL || p == q->pbst_link[1])
          {
            trav->pbst_node = q;
            return trav->pbst_node != NULL ? trav->pbst_node->pbst_data : NULL;
          }
    }
  else
    {
      trav->pbst_node = trav->pbst_node->pbst_link[0];
      while (trav->pbst_node->pbst_link[1] != NULL)
        trav->pbst_node = trav->pbst_node->pbst_link[1];
      return trav->pbst_node->pbst_data;
    }
}

/* Returns |trav|'s current item. */
void *
pbst_t_cur (struct pbst_traverser *trav)
{
  assert (trav != NULL);

  return trav->pbst_node != NULL ? trav->pbst_node->pbst_data : NULL;
}

/* Replaces the current item in |trav| by |new| and returns the item replaced.
   |trav| must not have the null item selected.
   The new item must not upset the ordering of the tree. */
void *
pbst_t_replace (struct pbst_traverser *trav, void *new)
{
  void *old;

  assert (trav != NULL && trav->pbst_node != NULL && new != NULL);
  old = trav->pbst_node->pbst_data;
  trav->pbst_node->pbst_data = new;
  return old;
}

/* Destroys |new| with |pbst_destroy (new, destroy)|,
   first initializing right links in |new| that have
   not yet been initialized at time of call. */
static void
copy_error_recovery (struct pbst_node *q,
                     struct pbst_table *new, pbst_item_func *destroy)
{
  assert (q != NULL && new != NULL);

  for (;;)
    {
      struct pbst_node *p = q;
      q = q->pbst_parent;
      if (q == NULL)
        break;

      if (p == q->pbst_link[0])
        q->pbst_link[1] = NULL;
    }

  pbst_destroy (new, destroy);
}

/* Copies |org| to a newly created tree, which is returned.
   If |copy != NULL|, each data item in |org| is first passed to |copy|,
   and the return values are inserted into the tree;
   |NULL| return values are taken as indications of failure.
   On failure, destroys the partially created new tree,
   applying |destroy|, if non-null, to each item in the new tree so far,
   and returns |NULL|.
   If |allocator != NULL|, it is used for allocation in the new tree;
   otherwise, the same allocator used for |org| is used. */
struct pbst_table *
pbst_copy (const struct pbst_table *org, pbst_copy_func *copy,
           pbst_item_func *destroy, struct libavl_allocator *allocator)
{
  struct pbst_table *new;
  const struct pbst_node *x;
  struct pbst_node *y;

  assert (org != NULL);
  new = pbst_create (org->pbst_compare, org->pbst_param,
                    allocator != NULL ? allocator : org->pbst_alloc);
  if (new == NULL)
    return NULL;
  new->pbst_count = org->pbst_count;
  if (new->pbst_count == 0)
    return new;

  x = (const struct pbst_node *) &org->pbst_root;
  y = (struct pbst_node *) &new->pbst_root;
  for (;;)
    {
      while (x->pbst_link[0] != NULL)
        {
          y->pbst_link[0] =
            new->pbst_alloc->libavl_malloc (new->pbst_alloc,
                                            sizeof *y->pbst_link[0]);
          if (y->pbst_link[0] == NULL)
            {
              if (y != (struct pbst_node *) &new->pbst_root)
                {
                  y->pbst_data = NULL;
                  y->pbst_link[1] = NULL;
                }

              copy_error_recovery (y, new, destroy);
              return NULL;
            }
          y->pbst_link[0]->pbst_parent = y;

          x = x->pbst_link[0];
          y = y->pbst_link[0];
        }
      y->pbst_link[0] = NULL;

      for (;;)
        {
          if (copy == NULL)
            y->pbst_data = x->pbst_data;
          else
            {
              y->pbst_data = copy (x->pbst_data, org->pbst_param);
              if (y->pbst_data == NULL)
                {
                  y->pbst_link[1] = NULL;
                  copy_error_recovery (y, new, destroy);
                  return NULL;
                }
            }

          if (x->pbst_link[1] != NULL)
            {
              y->pbst_link[1] =
                new->pbst_alloc->libavl_malloc (new->pbst_alloc,
                                               sizeof *y->pbst_link[1]);
              if (y->pbst_link[1] == NULL)
                {
                  copy_error_recovery (y, new, destroy);
                  return NULL;
                }
              y->pbst_link[1]->pbst_parent = y;

              x = x->pbst_link[1];
              y = y->pbst_link[1];
              break;
            }
          else
            y->pbst_link[1] = NULL;

          for (;;)
            {
              const struct pbst_node *w = x;
              x = x->pbst_parent;
              if (x == NULL)
                {
                  new->pbst_root->pbst_parent = NULL;
                  return new;
                }
              y = y->pbst_parent;

              if (w == x->pbst_link[0])
                break;
            }
        }
    }
}

/* Frees storage allocated for |tree|.
   If |destroy != NULL|, applies it to each data item in inorder. */
void
pbst_destroy (struct pbst_table *tree, pbst_item_func *destroy)
{
  struct pbst_node *p, *q;

  assert (tree != NULL);

  for (p = tree->pbst_root; p != NULL; p = q)
    if (p->pbst_link[0] == NULL)
      {
        q = p->pbst_link[1];
        if (destroy != NULL && p->pbst_data != NULL)
          destroy (p->pbst_data, tree->pbst_param);
        tree->pbst_alloc->libavl_free (tree->pbst_alloc, p);
      }
    else
      {
        q = p->pbst_link[0];
        p->pbst_link[0] = q->pbst_link[1];
        q->pbst_link[1] = p;
      }

  tree->pbst_alloc->libavl_free (tree->pbst_alloc, tree);
}

/* Converts |tree| into a vine. */
static void
tree_to_vine (struct pbst_table *tree)
{
  struct pbst_node *q, *p;

  q = (struct pbst_node *) &tree->pbst_root;
  p = tree->pbst_root;
  while (p != NULL)
    if (p->pbst_link[1] == NULL)
      {
        q = p;
        p = p->pbst_link[0];
      }
    else
      {
        struct pbst_node *r = p->pbst_link[1];
        p->pbst_link[1] = r->pbst_link[0];
        r->pbst_link[0] = p;
        p = r;
        q->pbst_link[0] = r;
      }
}

/* Performs a compression transformation |count| times,
   starting at |root|. */
static void
compress (struct pbst_node *root, unsigned long count)
{
  assert (root != NULL);

  while (count--)
    {
      struct pbst_node *red = root->pbst_link[0];
      struct pbst_node *black = red->pbst_link[0];

      root->pbst_link[0] = black;
      red->pbst_link[0] = black->pbst_link[1];
      black->pbst_link[1] = red;
      root = black;
    }
}

/* Converts |tree|, which must be in the shape of a vine, into a balanced
   tree. */
static void
vine_to_tree (struct pbst_table *tree)
{
  unsigned long vine;      /* Number of nodes in main vine. */
  unsigned long leaves;    /* Nodes in incomplete bottom level, if any. */
  int height;              /* Height of produced balanced tree. */

  leaves = tree->pbst_count + 1;
  for (;;)
    {
      unsigned long next = leaves & (leaves - 1);
      if (next == 0)
        break;
      leaves = next;
    }
  leaves = tree->pbst_count + 1 - leaves;

  compress ((struct pbst_node *) &tree->pbst_root, leaves);

  vine = tree->pbst_count - leaves;
  height = 1 + (leaves > 0);
  while (vine > 1)
    {
      compress ((struct pbst_node *) &tree->pbst_root, vine / 2);
      vine /= 2;
      height++;
    }

}

static void
update_parents (struct pbst_table *tree)
{
  struct pbst_node *p;

  if (tree->pbst_root == NULL)
    return;

  tree->pbst_root->pbst_parent = NULL;
  for (p = tree->pbst_root; ; p = p->pbst_link[1])
    {
      for (; p->pbst_link[0] != NULL; p = p->pbst_link[0])
        p->pbst_link[0]->pbst_parent = p;

      for (; p->pbst_link[1] == NULL; p = p->pbst_parent)
        {
          for (;;)
            {
              if (p->pbst_parent == NULL)
                return;

              if (p == p->pbst_parent->pbst_link[0])
                break;
              p = p->pbst_parent;
            }
        }

      p->pbst_link[1]->pbst_parent = p;
    }
}

/* Balances |tree|.
   Ensures that no simple path from the root to a leaf has more than
   |PBST_MAX_HEIGHT| nodes. */
void
pbst_balance (struct pbst_table *tree)
{
  assert (tree != NULL);

  tree_to_vine (tree);
  vine_to_tree (tree);
  update_parents (tree);
}

/* Allocates |size| bytes of space using |malloc()|.
   Returns a null pointer if allocation fails. */
void *
pbst_malloc (struct libavl_allocator *allocator, size_t size)
{
  assert (allocator != NULL && size > 0);
  return malloc (size);
}

/* Frees |block|. */
void
pbst_free (struct libavl_allocator *allocator, void *block)
{
  assert (allocator != NULL && block != NULL);
  free (block);
}

/* Default memory allocator that uses |malloc()| and |free()|. */
struct libavl_allocator pbst_allocator_default =
  {
    pbst_malloc,
    pbst_free
  };

#undef NDEBUG
#include <assert.h>

/* Asserts that |pbst_insert()| succeeds at inserting |item| into |table|. */
void
(pbst_assert_insert) (struct pbst_table *table, void *item)
{
  void **p = pbst_probe (table, item);
  assert (p != NULL && *p == item);
}

/* Asserts that |pbst_delete()| really removes |item| from |table|,
   and returns the removed item. */
void *
(pbst_assert_delete) (struct pbst_table *table, void *item)
{
  void *p = pbst_delete (table, item);
  assert (p != NULL);
  return p;
}

