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

#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include "trb.h"
#include "test.h"

/* Prints the structure of |node|,
   which is |level| levels from the top of the tree. */
void
print_tree_structure (struct trb_node *node, int level)
{
  int i;

  /* You can set the maximum level as high as you like.
     Most of the time, you'll want to debug code using small trees,
     so that a large |level| indicates a ``loop'', which is a bug. */
  if (level > 16)
    {
      printf ("[...]");
      return;
    }

  if (node == NULL)
    {
      printf ("<nil>");
      return;
    }

  printf ("%d(", node->trb_data ? *(int *) node->trb_data : -1);

  for (i = 0; i <= 1; i++)
    {
      if (node->trb_tag[i] == TRB_CHILD)
        {
          if (node->trb_link[i] == node)
            printf ("loop");
          else
            print_tree_structure (node->trb_link[i], level + 1);
        }
      else if (node->trb_link[i] != NULL)
        printf (">%d",
                (node->trb_link[i]->trb_data
                ? *(int *) node->trb_link[i]->trb_data : -1));
      else
        printf (">>");

      if (i == 0)
        fputs (", ", stdout);
    }

  putchar (')');
}

/* Prints the entire structure of |tree| with the given |title|. */
void
print_whole_tree (const struct trb_table *tree, const char *title)
{
  printf ("%s: ", title);
  print_tree_structure (tree->trb_root, 0);
  putchar ('\n');
}

/* Checks that the current item at |trav| is |i|
   and that its previous and next items are as they should be.
   |label| is a name for the traverser used in reporting messages.
   There should be |n| items in the tree numbered |0|@dots{}|n - 1|.
   Returns nonzero only if there is an error. */
static int
check_traverser (struct trb_traverser *trav, int i, int n, const char *label)
{
  int okay = 1;
  int *cur, *prev, *next;

  prev = trb_t_prev (trav);
  if ((i == 0 && prev != NULL)
      || (i > 0 && (prev == NULL || *prev != i - 1)))
    {
      printf ("   %s traverser ahead of %d, but should be ahead of %d.\n",
              label, prev != NULL ? *prev : -1, i == 0 ? -1 : i - 1);
      okay = 0;
    }
  trb_t_next (trav);

  cur = trb_t_cur (trav);
  if (cur == NULL || *cur != i)
    {
      printf ("   %s traverser at %d, but should be at %d.\n",
              label, cur != NULL ? *cur : -1, i);
      okay = 0;
    }

  next = trb_t_next (trav);
  if ((i == n - 1 && next != NULL)
      || (i != n - 1 && (next == NULL || *next != i + 1)))
    {
      printf ("   %s traverser behind %d, but should be behind %d.\n",
              label, next != NULL ? *next : -1, i == n - 1 ? -1 : i + 1);
      okay = 0;
    }
  trb_t_prev (trav);

  return okay;
}

/* Compares binary trees rooted at |a| and |b|,
   making sure that they are identical. */
static int
compare_trees (struct trb_node *a, struct trb_node *b)
{
  int okay;

  if (a == NULL || b == NULL)
    {
      if (a != NULL || b != NULL)
        {
          printf (" a=%d b=%d\n",
                  a ? *(int *) a->trb_data : -1,
                  b ? *(int *) b->trb_data : -1);
          assert (0);
        }
      return 1;
    }
  assert (a != b);

  if (*(int *) a->trb_data != *(int *) b->trb_data
      || a->trb_tag[0] != b->trb_tag[0]
      || a->trb_tag[1] != b->trb_tag[1]
      || a->trb_color != b->trb_color)
    {
      printf (" Copied nodes differ: a=%d%c b=%d%c a:",
              *(int *) a->trb_data, a->trb_color == TRB_RED ? 'r' : 'b',
              *(int *) b->trb_data, b->trb_color == TRB_RED ? 'r' : 'b');

      if (a->trb_tag[0] == TRB_CHILD)
        printf ("l");
      if (a->trb_tag[1] == TRB_CHILD)
        printf ("r");

      printf (" b:");
      if (b->trb_tag[0] == TRB_CHILD)
        printf ("l");
      if (b->trb_tag[1] == TRB_CHILD)
        printf ("r");

      printf ("\n");
      return 0;
    }

  if (a->trb_tag[0] == TRB_THREAD)
    assert ((a->trb_link[0] == NULL) != (a->trb_link[0] != b->trb_link[0]));
  if (a->trb_tag[1] == TRB_THREAD)
    assert ((a->trb_link[1] == NULL) != (a->trb_link[1] != b->trb_link[1]));

  okay = 1;
  if (a->trb_tag[0] == TRB_CHILD)
    okay &= compare_trees (a->trb_link[0], b->trb_link[0]);
  if (a->trb_tag[1] == TRB_CHILD)
    okay &= compare_trees (a->trb_link[1], b->trb_link[1]);
  return okay;
}

/* Examines the binary tree rooted at |node|.
   Zeroes |*okay| if an error occurs.
   Otherwise, does not modify |*okay|.
   Sets |*count| to the number of nodes in that tree,
   including |node| itself if |node != NULL|.
   Sets |*bh| to the tree's black-height.
   All the nodes in the tree are verified to be at least |min|
   but no greater than |max|. */
static void
recurse_verify_tree (struct trb_node *node, int *okay, size_t *count,
                     int min, int max, int *bh)
{
  int d;                /* Value of this node's data. */
  size_t subcount[2];   /* Number of nodes in subtrees. */
  int subbh[2];         /* Black-heights of subtrees. */

  if (node == NULL)
    {
      *count = 0;
      *bh = 0;
      return;
    }
  d = *(int *) node->trb_data;

  if (min > max)
    {
      printf (" Parents of node %d constrain it to empty range %d...%d.\n",
              d, min, max);
      *okay = 0;
    }
  else if (d < min || d > max)
    {
      printf (" Node %d is not in range %d...%d implied by its parents.\n",
              d, min, max);
      *okay = 0;
    }

  subcount[0] = subcount[1] = 0;
  subbh[0] = subbh[1] = 0;
  if (node->trb_tag[0] == TRB_CHILD)
    recurse_verify_tree (node->trb_link[0], okay, &subcount[0],
                         min, d - 1, &subbh[0]);
  if (node->trb_tag[1] == TRB_CHILD)
    recurse_verify_tree (node->trb_link[1], okay, &subcount[1],
                         d + 1, max, &subbh[1]);
  *count = 1 + subcount[0] + subcount[1];
  *bh = (node->trb_color == TRB_BLACK) + subbh[0];

  if (node->trb_color != TRB_RED && node->trb_color != TRB_BLACK)
    {
      printf (" Node %d is neither red nor black (%d).\n",
              d, node->trb_color);
      *okay = 0;
    }

  /* Verify compliance with rule 1. */
  if (node->trb_color == TRB_RED)
    {
      if (node->trb_tag[0] == TRB_CHILD
          && node->trb_link[0]->trb_color == TRB_RED)
        {
          printf (" Red node %d has red left child %d\n",
                  d, *(int *) node->trb_link[0]->trb_data);
          *okay = 0;
        }

      if (node->trb_tag[1] == TRB_CHILD
          && node->trb_link[1]->trb_color == TRB_RED)
        {
          printf (" Red node %d has red right child %d\n",
                  d, *(int *) node->trb_link[1]->trb_data);
          *okay = 0;
        }
    }

  /* Verify compliance with rule 2. */
  if (subbh[0] != subbh[1])
    {
      printf (" Node %d has two different black-heights: left bh=%d, "
              "right bh=%d\n", d, subbh[0], subbh[1]);
      *okay = 0;
    }
}

/* Checks that |tree| is well-formed
   and verifies that the values in |array[]| are actually in |tree|.
   There must be |n| elements in |array[]| and |tree|.
   Returns nonzero only if no errors detected. */
static int
verify_tree (struct trb_table *tree, int array[], size_t n)
{
  int okay = 1;

  /* Check |tree|'s bst_count against that supplied. */
  if (trb_count (tree) != n)
    {
      printf (" Tree count is %lu, but should be %lu.\n",
              (unsigned long) trb_count (tree), (unsigned long) n);
      okay = 0;
    }

  if (okay)
    {
      if (tree->trb_root != NULL && tree->trb_root->trb_color != TRB_BLACK)
        {
          printf (" Tree's root is not black.\n");
          okay = 0;
        }
    }

  if (okay)
    {
      /* Recursively verify tree structure. */
      size_t count;
      int bh;

      recurse_verify_tree (tree->trb_root, &okay, &count, 0, INT_MAX, &bh);
      if (count != n)
        {
          printf (" Tree has %lu nodes, but should have %lu.\n",
                  (unsigned long) count, (unsigned long) n);
          okay = 0;
        }
    }

  if (okay)
    {
      /* Check that all the values in |array[]| are in |tree|. */
      size_t i;

      for (i = 0; i < n; i++)
        if (trb_find (tree, &array[i]) == NULL)
          {
            printf (" Tree does not contain expected value %d.\n", array[i]);
            okay = 0;
          }
    }

  if (okay)
    {
      /* Check that |trb_t_first()| and |trb_t_next()| work properly. */
      struct trb_traverser trav;
      size_t i;
      int prev = -1;
      int *item;

      for (i = 0, item = trb_t_first (&trav, tree); i < 2 * n && item != NULL;
           i++, item = trb_t_next (&trav))
        {
          if (*item <= prev)
            {
              printf (" Tree out of order: %d follows %d in traversal\n",
                      *item, prev);
              okay = 0;
            }

          prev = *item;
        }

      if (i != n)
        {
          printf (" Tree should have %lu items, but has %lu in traversal\n",
                  (unsigned long) n, (unsigned long) i);
          okay = 0;
        }
    }

  if (okay)
    {
      /* Check that |trb_t_last()| and |trb_t_prev()| work properly. */
      struct trb_traverser trav;
      size_t i;
      int next = INT_MAX;
      int *item;

      for (i = 0, item = trb_t_last (&trav, tree); i < 2 * n && item != NULL;
           i++, item = trb_t_prev (&trav))
        {
          if (*item >= next)
            {
              printf (" Tree out of order: %d precedes %d in traversal\n",
                      *item, next);
              okay = 0;
            }

          next = *item;
        }

      if (i != n)
        {
          printf (" Tree should have %lu items, but has %lu in reverse\n",
                  (unsigned long) n, (unsigned long) i);
          okay = 0;
        }
    }

  if (okay)
    {
      /* Check that |trb_t_init()| works properly. */
      struct trb_traverser init, first, last;
      int *cur, *prev, *next;

      trb_t_init (&init, tree);
      trb_t_first (&first, tree);
      trb_t_last (&last, tree);

      cur = trb_t_cur (&init);
      if (cur != NULL)
        {
          printf (" Inited traverser should be null, but is actually %d.\n",
                  *cur);
          okay = 0;
        }

      next = trb_t_next (&init);
      if (next != trb_t_cur (&first))
        {
          printf (" Next after null should be %d, but is actually %d.\n",
                  *(int *) trb_t_cur (&first), *next);
          okay = 0;
        }
      trb_t_prev (&init);

      prev = trb_t_prev (&init);
      if (prev != trb_t_cur (&last))
        {
          printf (" Previous before null should be %d, but is actually %d.\n",
                  *(int *) trb_t_cur (&last), *prev);
          okay = 0;
        }
      trb_t_next (&init);
    }

  return okay;
}

/* Tests tree functions.
   |insert[]| and |delete[]| must contain some permutation of values
   |0|@dots{}|n - 1|.
   Uses |allocator| as the allocator for tree and node data.
   Higher values of |verbosity| produce more debug output. */
int
test_correctness (struct libavl_allocator *allocator,
                  int insert[], int delete[], int n, int verbosity)
{
  struct trb_table *tree;
  int okay = 1;
  int i;

  /* Test creating a TRB and inserting into it. */
  tree = trb_create (compare_ints, NULL, allocator);
  if (tree == NULL)
    {
      if (verbosity >= 0)
        printf ("  Out of memory creating tree.\n");
      return 1;
    }

  for (i = 0; i < n; i++)
    {
      if (verbosity >= 2)
        printf ("  Inserting %d...\n", insert[i]);

      /* Add the |i|th element to the tree. */
      {
        void **p = trb_probe (tree, &insert[i]);
        if (p == NULL)
          {
            if (verbosity >= 0)
              printf ("    Out of memory in insertion.\n");
            trb_destroy (tree, NULL);
            return 1;
          }
        if (*p != &insert[i])
          printf ("    Duplicate item in tree!\n");
      }

      if (verbosity >= 3)
        print_whole_tree (tree, "    Afterward");

      if (!verify_tree (tree, insert, i + 1))
        return 0;
    }

  /* Test TRB traversal during modifications. */
  for (i = 0; i < n; i++)
    {
      struct trb_traverser x, y, z;
      int *deleted;

      if (insert[i] == delete[i])
        continue;

      if (verbosity >= 2)
        printf ("   Checking traversal from item %d...\n", insert[i]);

      if (trb_t_find (&x, tree, &insert[i]) == NULL)
        {
          printf ("    Can't find item %d in tree!\n", insert[i]);
          continue;
        }

      okay &= check_traverser (&x, insert[i], n, "Predeletion");

      if (verbosity >= 3)
        printf ("    Deleting item %d.\n", delete[i]);

      deleted = trb_delete (tree, &delete[i]);
      if (deleted == NULL || *deleted != delete[i])
        {
          okay = 0;
          if (deleted == NULL)
            printf ("    Deletion failed.\n");
          else
            printf ("    Wrong node %d returned.\n", *deleted);
        }

      trb_t_copy (&y, &x);

      if (verbosity >= 3)
        printf ("    Re-inserting item %d.\n", delete[i]);
      if (trb_t_insert (&z, tree, &delete[i]) == NULL)
        {
          if (verbosity >= 0)
            printf ("    Out of memory re-inserting item.\n");
          trb_destroy (tree, NULL);
          return 1;
        }

      okay &= check_traverser (&x, insert[i], n, "Postdeletion");
      okay &= check_traverser (&y, insert[i], n, "Copied");
      okay &= check_traverser (&z, delete[i], n, "Insertion");

      if (!verify_tree (tree, insert, n))
        return 0;
    }

  /* Test deleting nodes from the tree and making copies of it. */
  for (i = 0; i < n; i++)
    {
      int *deleted;

      if (verbosity >= 2)
        printf ("  Deleting %d...\n", delete[i]);

      deleted = trb_delete (tree, &delete[i]);
      if (deleted == NULL || *deleted != delete[i])
        {
          okay = 0;
          if (deleted == NULL)
            printf ("    Deletion failed.\n");
          else
            printf ("    Wrong node %d returned.\n", *deleted);
        }

      if (verbosity >= 3)
        print_whole_tree (tree, "    Afterward");

      if (!verify_tree (tree, delete + i + 1, n - i - 1))
        return 0;

      if (verbosity >= 2)
        printf ("  Copying tree and comparing...\n");

      /* Copy the tree and make sure it's identical. */
      {
        struct trb_table *copy = trb_copy (tree, NULL, NULL, NULL);
        if (copy == NULL)
          {
            if (verbosity >= 0)
              printf ("  Out of memory in copy\n");
            trb_destroy (tree, NULL);
            return 1;
          }

        okay &= compare_trees (tree->trb_root, copy->trb_root);
        trb_destroy (copy, NULL);
      }
    }

  if (trb_delete (tree, &insert[0]) != NULL)
    {
      printf (" Deletion from empty tree succeeded.\n");
      okay = 0;
    }

  /* Test destroying the tree. */
  trb_destroy (tree, NULL);

  return okay;
}

static int
test_bst_t_first (struct trb_table *tree, int n)
{
  struct trb_traverser trav;
  int *first;

  first = trb_t_first (&trav, tree);
  if (first == NULL || *first != 0)
    {
      printf ("    First item test failed: expected 0, got %d\n",
              first != NULL ? *first : -1);
      return 0;
    }

  return 1;
}

static int
test_bst_t_last (struct trb_table *tree, int n)
{
  struct trb_traverser trav;
  int *last;

  last = trb_t_last (&trav, tree);
  if (last == NULL || *last != n - 1)
    {
      printf ("    Last item test failed: expected %d, got %d\n",
              n - 1, last != NULL ? *last : -1);
      return 0;
    }

  return 1;
}

static int
test_bst_t_find (struct trb_table *tree, int n)
{
  int i;

  for (i = 0; i < n; i++)
    {
      struct trb_traverser trav;
      int *iter;

      iter = trb_t_find (&trav, tree, &i);
      if (iter == NULL || *iter != i)
        {
          printf ("    Find item test failed: looked for %d, got %d\n",
                  i, iter != NULL ? *iter : -1);
          return 0;
        }
    }

  return 1;
}

static int
test_bst_t_insert (struct trb_table *tree, int n)
{
  int i;

  for (i = 0; i < n; i++)
    {
      struct trb_traverser trav;
      int *iter;

      iter = trb_t_insert (&trav, tree, &i);
      if (iter == NULL || iter == &i || *iter != i)
        {
          printf ("    Insert item test failed: inserted dup %d, got %d\n",
                  i, iter != NULL ? *iter : -1);
          return 0;
        }
    }

  return 1;
}

static int
test_bst_t_next (struct trb_table *tree, int n)
{
  struct trb_traverser trav;
  int i;

  trb_t_init (&trav, tree);
  for (i = 0; i < n; i++)
    {
      int *iter = trb_t_next (&trav);
      if (iter == NULL || *iter != i)
        {
          printf ("    Next item test failed: expected %d, got %d\n",
                  i, iter != NULL ? *iter : -1);
          return 0;
        }
    }

  return 1;
}

static int
test_bst_t_prev (struct trb_table *tree, int n)
{
  struct trb_traverser trav;
  int i;

  trb_t_init (&trav, tree);
  for (i = n - 1; i >= 0; i--)
    {
      int *iter = trb_t_prev (&trav);
      if (iter == NULL || *iter != i)
        {
          printf ("    Previous item test failed: expected %d, got %d\n",
                  i, iter != NULL ? *iter : -1);
          return 0;
        }
    }

  return 1;
}

static int
test_bst_copy (struct trb_table *tree, int n)
{
  struct trb_table *copy = trb_copy (tree, NULL, NULL, NULL);
  int okay = compare_trees (tree->trb_root, copy->trb_root);

  trb_destroy (copy, NULL);

  return okay;
}

/* Tests the tree routines for proper handling of overflows.
   Inserting the |n| elements of |order[]| should produce a tree
   with height greater than |TRB_MAX_HEIGHT|.
   Uses |allocator| as the allocator for tree and node data.
   Use |verbosity| to set the level of chatter on |stdout|. */
int
test_overflow (struct libavl_allocator *allocator,
               int order[], int n, int verbosity)
{
  /* An overflow tester function. */
  typedef int test_func (struct trb_table *, int n);

  /* An overflow tester. */
  struct test
    {
      test_func *func;                  /* Tester function. */
      const char *name;                 /* Test name. */
    };

  /* All the overflow testers. */
  static const struct test test[] =
    {
      {test_bst_t_first, "first item"},
      {test_bst_t_last, "last item"},
      {test_bst_t_find, "find item"},
      {test_bst_t_insert, "insert item"},
      {test_bst_t_next, "next item"},
      {test_bst_t_prev, "previous item"},
      {test_bst_copy, "copy tree"},
    };

  const struct test *i;                 /* Iterator. */

  /* Run all the overflow testers. */
  for (i = test; i < test + sizeof test / sizeof *test; i++)
    {
      struct trb_table *tree;
      int j;

      if (verbosity >= 2)
        printf ("  Running %s test...\n", i->name);

      tree = trb_create (compare_ints, NULL, allocator);
      if (tree == NULL)
        {
          printf ("    Out of memory creating tree.\n");
          return 1;
        }

      for (j = 0; j < n; j++)
        {
          void **p = trb_probe (tree, &order[j]);
          if (p == NULL || *p != &order[j])
            {
              if (p == NULL && verbosity >= 0)
                printf ("    Out of memory in insertion.\n");
              else if (p != NULL)
                printf ("    Duplicate item in tree!\n");
              trb_destroy (tree, NULL);
              return p == NULL;
            }
        }

      if (i->func (tree, n) == 0)
        return 0;

      if (verify_tree (tree, order, n) == 0)
        return 0;
      trb_destroy (tree, NULL);
    }

  return 1;
}
