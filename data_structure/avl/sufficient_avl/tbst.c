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
#include "tbst.h"

/* Creates and returns a new table
   with comparison function |compare| using parameter |param|
   and memory allocator |allocator|.
   Returns |NULL| if memory allocation failed. */
struct tbst_table *
tbst_create (tbst_comparison_func *compare, void *param,
            struct libavl_allocator *allocator)
{
  struct tbst_table *tree;

  assert (compare != NULL);

  if (allocator == NULL)
    allocator = &tbst_allocator_default;

  tree = allocator->libavl_malloc (allocator, sizeof *tree);
  if (tree == NULL)
    return NULL;

  tree->tbst_root = NULL;
  tree->tbst_compare = compare;
  tree->tbst_param = param;
  tree->tbst_alloc = allocator;
  tree->tbst_count = 0;

  return tree;
}

/* Search |tree| for an item matching |item|, and return it if found.
   Otherwise return |NULL|. */
void *
tbst_find (const struct tbst_table *tree, const void *item)
{
  const struct tbst_node *p;

  assert (tree != NULL && item != NULL);

  p = tree->tbst_root;
  if (p == NULL)
    return NULL;

  for (;;)
    {
      int cmp, dir;

      cmp = tree->tbst_compare (item, p->tbst_data, tree->tbst_param);
      if (cmp == 0)
        return p->tbst_data;

      dir = cmp > 0;
      if (p->tbst_tag[dir] == TBST_CHILD)
        p = p->tbst_link[dir];
      else
        return NULL;
    }
}

/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree,
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
void **
tbst_probe (struct tbst_table *tree, void *item)
{
  struct tbst_node *p; /* Traverses tree to find insertion point. */
  struct tbst_node *n; /* New node. */
  int dir;             /* Side of |p| on which |n| is inserted. */

  assert (tree != NULL && item != NULL);

  if (tree->tbst_root != NULL)
    for (p = tree->tbst_root; ; p = p->tbst_link[dir])
      {
        int cmp = tree->tbst_compare (item, p->tbst_data, tree->tbst_param);
        if (cmp == 0)
          return &p->tbst_data;
        dir = cmp > 0;

        if (p->tbst_tag[dir] == TBST_THREAD)
          break;
      }
  else
    {
      p = (struct tbst_node *) &tree->tbst_root;
      dir = 0;
    }

  n = tree->tbst_alloc->libavl_malloc (tree->tbst_alloc, sizeof *n);
  if (n == NULL)
    return NULL;

  tree->tbst_count++;
  n->tbst_data = item;
  n->tbst_tag[0] = n->tbst_tag[1] = TBST_THREAD;
  n->tbst_link[dir] = p->tbst_link[dir];
  if (tree->tbst_root != NULL)
    {
      p->tbst_tag[dir] = TBST_CHILD;
      n->tbst_link[!dir] = p;
    }
  else
    n->tbst_link[1] = NULL;
  p->tbst_link[dir] = n;

  return &n->tbst_data;
}

/* Inserts |item| into |table|.
   Returns |NULL| if |item| was successfully inserted
   or if a memory allocation error occurred.
   Otherwise, returns the duplicate item. */
void *
tbst_insert (struct tbst_table *table, void *item)
{
  void **p = tbst_probe (table, item);
  return p == NULL || *p == item ? NULL : *p;
}

/* Inserts |item| into |table|, replacing any duplicate item.
   Returns |NULL| if |item| was inserted without replacing a duplicate,
   or if a memory allocation error occurred.
   Otherwise, returns the item that was replaced. */
void *
tbst_replace (struct tbst_table *table, void *item)
{
  void **p = tbst_probe (table, item);
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
tbst_delete (struct tbst_table *tree, const void *item)
{
  struct tbst_node *p;        /* Node to delete. */
  struct tbst_node *q;        /* Parent of |p|. */
  int dir;              /* Index into |q->tbst_link[]| that leads to |p|. */

  assert (tree != NULL && item != NULL);

  if (tree->tbst_root == NULL)
    return NULL;

  p = tree->tbst_root;
  q = (struct tbst_node *) &tree->tbst_root;
  dir = 0;
  for (;;)
    {
      int cmp = tree->tbst_compare (item, p->tbst_data, tree->tbst_param);
      if (cmp == 0)
        break;

      dir = cmp > 0;
      if (p->tbst_tag[dir] == TBST_THREAD)
        return NULL;

      q = p;
      p = p->tbst_link[dir];
    }
  item = p->tbst_data;

  if (p->tbst_tag[1] == TBST_THREAD)
    {
      if (p->tbst_tag[0] == TBST_CHILD)
        {
          struct tbst_node *t = p->tbst_link[0];
          while (t->tbst_tag[1] == TBST_CHILD)
            t = t->tbst_link[1];
          t->tbst_link[1] = p->tbst_link[1];
          q->tbst_link[dir] = p->tbst_link[0];
        }
      else
        {
          q->tbst_link[dir] = p->tbst_link[dir];
          if (q != (struct tbst_node *) &tree->tbst_root)
            q->tbst_tag[dir] = TBST_THREAD;
        }
    }
  else
    {
      struct tbst_node *r = p->tbst_link[1];
      if (r->tbst_tag[0] == TBST_THREAD)
        {
          r->tbst_link[0] = p->tbst_link[0];
          r->tbst_tag[0] = p->tbst_tag[0];
          if (r->tbst_tag[0] == TBST_CHILD)
            {
              struct tbst_node *t = r->tbst_link[0];
              while (t->tbst_tag[1] == TBST_CHILD)
                t = t->tbst_link[1];
              t->tbst_link[1] = r;
            }
          q->tbst_link[dir] = r;
        }
      else
        {
          struct tbst_node *s;

          for (;;)
            {
              s = r->tbst_link[0];
              if (s->tbst_tag[0] == TBST_THREAD)
                break;

              r = s;
            }

          if (s->tbst_tag[1] == TBST_CHILD)
            r->tbst_link[0] = s->tbst_link[1];
          else
            {
              r->tbst_link[0] = s;
              r->tbst_tag[0] = TBST_THREAD;
            }

          s->tbst_link[0] = p->tbst_link[0];
          if (p->tbst_tag[0] == TBST_CHILD)
            {
              struct tbst_node *t = p->tbst_link[0];
              while (t->tbst_tag[1] == TBST_CHILD)
                t = t->tbst_link[1];
              t->tbst_link[1] = s;

              s->tbst_tag[0] = TBST_CHILD;
            }

          s->tbst_link[1] = p->tbst_link[1];
          s->tbst_tag[1] = TBST_CHILD;

          q->tbst_link[dir] = s;
        }
    }

  tree->tbst_alloc->libavl_free (tree->tbst_alloc, p);
  tree->tbst_count--;
  return (void *) item;
}

/* Initializes |trav| for use with |tree|
   and selects the null node. */
void
tbst_t_init (struct tbst_traverser *trav, struct tbst_table *tree)
{
  trav->tbst_table = tree;
  trav->tbst_node = NULL;
}

/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the least value,
   or |NULL| if |tree| is empty. */
void *
tbst_t_first (struct tbst_traverser *trav, struct tbst_table *tree)
{
  assert (tree != NULL && trav != NULL);

  trav->tbst_table = tree;
  trav->tbst_node = tree->tbst_root;
  if (trav->tbst_node != NULL)
    {
      while (trav->tbst_node->tbst_tag[0] == TBST_CHILD)
        trav->tbst_node = trav->tbst_node->tbst_link[0];
      return trav->tbst_node->tbst_data;
    }
  else
    return NULL;
}

/* Initializes |trav| for |tree|.
   Returns data item in |tree| with the greatest value,
   or |NULL| if |tree| is empty. */
void *
tbst_t_last (struct tbst_traverser *trav, struct tbst_table *tree)
{
  assert (tree != NULL && trav != NULL);

  trav->tbst_table = tree;
  trav->tbst_node = tree->tbst_root;
  if (trav->tbst_node != NULL)
    {
      while (trav->tbst_node->tbst_tag[1] == TBST_CHILD)
        trav->tbst_node = trav->tbst_node->tbst_link[1];
      return trav->tbst_node->tbst_data;
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
tbst_t_find (struct tbst_traverser *trav, struct tbst_table *tree, void *item)
{
  struct tbst_node *p;

  assert (trav != NULL && tree != NULL && item != NULL);

  trav->tbst_table = tree;
  trav->tbst_node = NULL;

  p = tree->tbst_root;
  if (p == NULL)
    return NULL;

  for (;;)
    {
      int cmp, dir;

      cmp = tree->tbst_compare (item, p->tbst_data, tree->tbst_param);
      if (cmp == 0)
        {
          trav->tbst_node = p;
          return p->tbst_data;
        }

      dir = cmp > 0;
      if (p->tbst_tag[dir] == TBST_CHILD)
        p = p->tbst_link[dir];
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
tbst_t_insert (struct tbst_traverser *trav,
               struct tbst_table *tree, void *item)
{
  void **p;

  assert (trav != NULL && tree != NULL && item != NULL);

  p = tbst_probe (tree, item);
  if (p != NULL)
    {
      trav->tbst_table = tree;
      trav->tbst_node =
        ((struct tbst_node *)
         ((char *) p - offsetof (struct tbst_node, tbst_data)));
      return *p;
    }
  else
    {
      tbst_t_init (trav, tree);
      return NULL;
    }
}

/* Initializes |trav| to have the same current node as |src|. */
void *
tbst_t_copy (struct tbst_traverser *trav, const struct tbst_traverser *src)
{
  assert (trav != NULL && src != NULL);

  trav->tbst_table = src->tbst_table;
  trav->tbst_node = src->tbst_node;

  return trav->tbst_node != NULL ? trav->tbst_node->tbst_data : NULL;
}

/* Returns the next data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
void *
tbst_t_next (struct tbst_traverser *trav)
{
  assert (trav != NULL);

  if (trav->tbst_node == NULL)
    return tbst_t_first (trav, trav->tbst_table);
  else if (trav->tbst_node->tbst_tag[1] == TBST_THREAD)
    {
      trav->tbst_node = trav->tbst_node->tbst_link[1];
      return trav->tbst_node != NULL ? trav->tbst_node->tbst_data : NULL;
    }
  else
    {
      trav->tbst_node = trav->tbst_node->tbst_link[1];
      while (trav->tbst_node->tbst_tag[0] == TBST_CHILD)
        trav->tbst_node = trav->tbst_node->tbst_link[0];
      return trav->tbst_node->tbst_data;
    }
}

/* Returns the previous data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
void *
tbst_t_prev (struct tbst_traverser *trav)
{
  assert (trav != NULL);

  if (trav->tbst_node == NULL)
    return tbst_t_last (trav, trav->tbst_table);
  else if (trav->tbst_node->tbst_tag[0] == TBST_THREAD)
    {
      trav->tbst_node = trav->tbst_node->tbst_link[0];
      return trav->tbst_node != NULL ? trav->tbst_node->tbst_data : NULL;
    }
  else
    {
      trav->tbst_node = trav->tbst_node->tbst_link[0];
      while (trav->tbst_node->tbst_tag[1] == TBST_CHILD)
        trav->tbst_node = trav->tbst_node->tbst_link[1];
      return trav->tbst_node->tbst_data;
    }
}

/* Returns |trav|'s current item. */
void *
tbst_t_cur (struct tbst_traverser *trav)
{
  assert (trav != NULL);

  return trav->tbst_node != NULL ? trav->tbst_node->tbst_data : NULL;
}

/* Replaces the current item in |trav| by |new| and returns the item replaced.
   |trav| must not have the null item selected.
   The new item must not upset the ordering of the tree. */
void *
tbst_t_replace (struct tbst_traverser *trav, void *new)
{
  void *old;

  assert (trav != NULL && trav->tbst_node != NULL && new != NULL);
  old = trav->tbst_node->tbst_data;
  trav->tbst_node->tbst_data = new;
  return old;
}

/* Creates a new node as a child of |dst| on side |dir|.
   Copies data from |src| into the new node, applying |copy()|, if non-null.
   Returns nonzero only if fully successful.
   Regardless of success, integrity of the tree structure is assured,
   though failure may leave a null pointer in a |tbst_data| member. */
static int
copy_node (struct tbst_table *tree,
           struct tbst_node *dst, int dir,
           const struct tbst_node *src, tbst_copy_func *copy)
{
  struct tbst_node *new =
    tree->tbst_alloc->libavl_malloc (tree->tbst_alloc, sizeof *new);
  if (new == NULL)
    return 0;

  new->tbst_link[dir] = dst->tbst_link[dir];
  new->tbst_tag[dir] = TBST_THREAD;
  new->tbst_link[!dir] = dst;
  new->tbst_tag[!dir] = TBST_THREAD;
  dst->tbst_link[dir] = new;
  dst->tbst_tag[dir] = TBST_CHILD;

  if (copy == NULL)
    new->tbst_data = src->tbst_data;
  else
    {
      new->tbst_data = copy (src->tbst_data, tree->tbst_param);
      if (new->tbst_data == NULL)
        return 0;
    }

  return 1;
}

/* Destroys |new| with |tbst_destroy (new, destroy)|,
   first initializing the right link in |new| that has
   not yet been initialized. */
static void
copy_error_recovery (struct tbst_node *p,
                     struct tbst_table *new, tbst_item_func *destroy)
{
  new->tbst_root = p;
  if (p != NULL)
    {
      while (p->tbst_tag[1] == TBST_CHILD)
        p = p->tbst_link[1];
      p->tbst_link[1] = NULL;
    }
  tbst_destroy (new, destroy);
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
struct tbst_table *
tbst_copy (const struct tbst_table *org, tbst_copy_func *copy,
          tbst_item_func *destroy, struct libavl_allocator *allocator)
{
  struct tbst_table *new;

  const struct tbst_node *p;
  struct tbst_node *q;
  struct tbst_node rp, rq;

  assert (org != NULL);
  new = tbst_create (org->tbst_compare, org->tbst_param,
                     allocator != NULL ? allocator : org->tbst_alloc);
  if (new == NULL)
    return NULL;

  new->tbst_count = org->tbst_count;
  if (new->tbst_count == 0)
    return new;

  p = &rp;
  rp.tbst_link[0] = org->tbst_root;
  rp.tbst_tag[0] = TBST_CHILD;

  q = &rq;
  rq.tbst_link[0] = NULL;
  rq.tbst_tag[0] = TBST_THREAD;

  for (;;)
    {
      if (p->tbst_tag[0] == TBST_CHILD)
        {
          if (!copy_node (new, q, 0, p->tbst_link[0], copy))
            {
              copy_error_recovery (rq.tbst_link[0], new, destroy);
              return NULL;
            }

          p = p->tbst_link[0];
          q = q->tbst_link[0];
        }
      else
        {
          while (p->tbst_tag[1] == TBST_THREAD)
            {
              p = p->tbst_link[1];
              if (p == NULL)
                {
                  q->tbst_link[1] = NULL;
                  new->tbst_root = rq.tbst_link[0];
                  return new;
                }

              q = q->tbst_link[1];
            }

          p = p->tbst_link[1];
          q = q->tbst_link[1];
        }

      if (p->tbst_tag[1] == TBST_CHILD)
        if (!copy_node (new, q, 1, p->tbst_link[1], copy))
          {
            copy_error_recovery (rq.tbst_link[0], new, destroy);
            return NULL;
          }
    }
}

/* Frees storage allocated for |tree|.
   If |destroy != NULL|, applies it to each data item in inorder. */
void
tbst_destroy (struct tbst_table *tree, tbst_item_func *destroy)
{
  struct tbst_node *p; /* Current node. */
  struct tbst_node *n; /* Next node. */

  p = tree->tbst_root;
  if (p != NULL)
    while (p->tbst_tag[0] == TBST_CHILD)
      p = p->tbst_link[0];

  while (p != NULL)
    {
      n = p->tbst_link[1];
      if (p->tbst_tag[1] == TBST_CHILD)
        while (n->tbst_tag[0] == TBST_CHILD)
          n = n->tbst_link[0];

      if (destroy != NULL && p->tbst_data != NULL)
        destroy (p->tbst_data, tree->tbst_param);
      tree->tbst_alloc->libavl_free (tree->tbst_alloc, p);

      p = n;
    }

  tree->tbst_alloc->libavl_free (tree->tbst_alloc, tree);
}

static void
tree_to_vine (struct tbst_table *tree)
{
  struct tbst_node *p;

  if (tree->tbst_root == NULL)
    return;

  p = tree->tbst_root;
  while (p->tbst_tag[0] == TBST_CHILD)
    p = p->tbst_link[0];

  for (;;)
    {
      struct tbst_node *q = p->tbst_link[1];
      if (p->tbst_tag[1] == TBST_CHILD)
        {
          while (q->tbst_tag[0] == TBST_CHILD)
            q = q->tbst_link[0];
          p->tbst_tag[1] = TBST_THREAD;
          p->tbst_link[1] = q;
        }

      if (q == NULL)
        break;

      q->tbst_tag[0] = TBST_CHILD;
      q->tbst_link[0] = p;
      p = q;
    }

  tree->tbst_root = p;
}

/* Performs a nonthreaded compression operation |nonthread| times,
   then a threaded compression operation |thread| times,
   starting at |root|. */
static void
compress (struct tbst_node *root,
          unsigned long nonthread, unsigned long thread)
{
  assert (root != NULL);

  while (nonthread--)
    {
      struct tbst_node *red = root->tbst_link[0];
      struct tbst_node *black = red->tbst_link[0];

      root->tbst_link[0] = black;
      red->tbst_link[0] = black->tbst_link[1];
      black->tbst_link[1] = red;
      root = black;
    }

  while (thread--)
    {
      struct tbst_node *red = root->tbst_link[0];
      struct tbst_node *black = red->tbst_link[0];

      root->tbst_link[0] = black;
      red->tbst_link[0] = black;
      red->tbst_tag[0] = TBST_THREAD;
      black->tbst_tag[1] = TBST_CHILD;
      root = black;
    }
}

/* Converts |tree|, which must be in the shape of a vine, into a balanced
   tree. */
static void
vine_to_tree (struct tbst_table *tree)
{
  unsigned long vine;   /* Number of nodes in main vine. */
  unsigned long leaves; /* Nodes in incomplete bottom level, if any. */
  int height;           /* Height of produced balanced tree. */

  leaves = tree->tbst_count + 1;
  for (;;)
    {
      unsigned long next = leaves & (leaves - 1);
      if (next == 0)
        break;
      leaves = next;
    }
  leaves = tree->tbst_count + 1 - leaves;

  compress ((struct tbst_node *) &tree->tbst_root, 0, leaves);

  vine = tree->tbst_count - leaves;
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

      compress ((struct tbst_node *) &tree->tbst_root, leaves, nonleaves);
      vine /= 2;
      height++;
    }
  while (vine > 1)
    {
      compress ((struct tbst_node *) &tree->tbst_root, vine / 2, 0);
      vine /= 2;
      height++;
    }
}

/* Balances |tree|. */
void
tbst_balance (struct tbst_table *tree)
{
  assert (tree != NULL);

  tree_to_vine (tree);
  vine_to_tree (tree);
}

/* Allocates |size| bytes of space using |malloc()|.
   Returns a null pointer if allocation fails. */
void *
tbst_malloc (struct libavl_allocator *allocator, size_t size)
{
  assert (allocator != NULL && size > 0);
  return malloc (size);
}

/* Frees |block|. */
void
tbst_free (struct libavl_allocator *allocator, void *block)
{
  assert (allocator != NULL && block != NULL);
  free (block);
}

/* Default memory allocator that uses |malloc()| and |free()|. */
struct libavl_allocator tbst_allocator_default =
  {
    tbst_malloc,
    tbst_free
  };

#undef NDEBUG
#include <assert.h>

/* Asserts that |tbst_insert()| succeeds at inserting |item| into |table|. */
void
(tbst_assert_insert) (struct tbst_table *table, void *item)
{
  void **p = tbst_probe (table, item);
  assert (p != NULL && *p == item);
}

/* Asserts that |tbst_delete()| really removes |item| from |table|,
   and returns the removed item. */
void *
(tbst_assert_delete) (struct tbst_table *table, void *item)
{
  void *p = tbst_delete (table, item);
  assert (p != NULL);
  return p;
}

