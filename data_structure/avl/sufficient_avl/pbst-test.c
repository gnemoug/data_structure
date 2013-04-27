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
#include "pbst.h"
#include "test.h"

/* Prints the structure of |node|,
   which is |level| levels from the top of the tree. */
static void
print_tree_structure (const struct pbst_node *node, int level)
{
  /* You can set the maximum level as high as you like.
     Most of the time, you'll want to debug code using small trees,
     so that a large |level| indicates a ``loop'', which is a bug. */
  if (level > 16)
    {
      printf ("[...]");
      return;
    }

  if (node == NULL)
    return;

  printf ("%d", *(int *) node->pbst_data);
  if (node->pbst_link[0] != NULL || node->pbst_link[1] != NULL)
    {
      putchar ('(');

      print_tree_structure (node->pbst_link[0], level + 1);
      if (node->pbst_link[1] != NULL)
        {
          putchar (',');
          print_tree_structure (node->pbst_link[1], level + 1);
        }

      putchar (')');
    }
}

/* Prints the entire structure of |tree| with the given |title|. */
void
print_whole_tree (const struct pbst_table *tree, const char *title)
{
  printf ("%s: ", title);
  print_tree_structure (tree->pbst_root, 0);
  putchar ('\n');
}

/* Checks that the current item at |trav| is |i|
   and that its previous and next items are as they should be.
   |label| is a name for the traverser used in reporting messages.
   There should be |n| items in the tree numbered |0|@dots{}|n - 1|.
   Returns nonzero only if there is an error. */
static int
check_traverser (struct pbst_traverser *trav, int i, int n, const char *label)
{
  int okay = 1;
  int *cur, *prev, *next;

  prev = pbst_t_prev (trav);
  if ((i == 0 && prev != NULL)
      || (i > 0 && (prev == NULL || *prev != i - 1)))
    {
      printf ("   %s traverser ahead of %d, but should be ahead of %d.\n",
              label, prev != NULL ? *prev : -1, i == 0 ? -1 : i - 1);
      okay = 0;
    }
  pbst_t_next (trav);

  cur = pbst_t_cur (trav);
  if (cur == NULL || *cur != i)
    {
      printf ("   %s traverser at %d, but should be at %d.\n",
              label, cur != NULL ? *cur : -1, i);
      okay = 0;
    }

  next = pbst_t_next (trav);
  if ((i == n - 1 && next != NULL)
      || (i != n - 1 && (next == NULL || *next != i + 1)))
    {
      printf ("   %s traverser behind %d, but should be behind %d.\n",
              label, next != NULL ? *next : -1, i == n - 1 ? -1 : i + 1);
      okay = 0;
    }
  pbst_t_prev (trav);

  return okay;
}

/* Compares binary trees rooted at |a| and |b|,
   making sure that they are identical. */
static int
compare_trees (struct pbst_node *a, struct pbst_node *b)
{
  int okay;

  if (a == NULL || b == NULL)
    {
      assert (a == NULL && b == NULL);
      return 1;
    }

  if (*(int *) a->pbst_data != *(int *) b->pbst_data
      || ((a->pbst_link[0] != NULL) != (b->pbst_link[0] != NULL))
      || ((a->pbst_link[1] != NULL) != (b->pbst_link[1] != NULL))
      || ((a->pbst_parent != NULL) != (b->pbst_parent != NULL))
      || (a->pbst_parent != NULL && b->pbst_parent != NULL
          && a->pbst_parent->pbst_data != b->pbst_parent->pbst_data))
    {
      printf (" Copied nodes differ:\n"
              "  a: %d, parent %d, %s left child, %s right child\n"
              "  b: %d, parent %d, %s left child, %s right child\n",
              *(int *) a->pbst_data,
              a->pbst_parent != NULL ? *(int *) a->pbst_parent : -1,
              a->pbst_link[0] != NULL ? "has" : "no",
              a->pbst_link[1] != NULL ? "has" : "no",
              *(int *) b->pbst_data,
              b->pbst_parent != NULL ? *(int *) b->pbst_parent : -1,
              b->pbst_link[0] != NULL ? "has" : "no",
              b->pbst_link[1] != NULL ? "has" : "no");
      return 0;
    }

  okay = 1;
  if (a->pbst_link[0] != NULL)
    okay &= compare_trees (a->pbst_link[0], b->pbst_link[0]);
  if (a->pbst_link[1] != NULL)
    okay &= compare_trees (a->pbst_link[1], b->pbst_link[1]);
  return okay;
}

/* Examines the binary tree rooted at |node|.
   Zeroes |*okay| if an error occurs.
   Otherwise, does not modify |*okay|.
   Sets |*count| to the number of nodes in that tree,
   including |node| itself if |node != NULL|.
   All the nodes in the tree are verified to be at least |min|
   but no greater than |max|. */
static void
recurse_verify_tree (struct pbst_node *node, int *okay, size_t *count,
                     int min, int max)
{
  int d;                /* Value of this node's data. */
  size_t subcount[2];   /* Number of nodes in subtrees. */
  int i;

  if (node == NULL)
    {
      *count = 0;
      return;
    }
  d = *(int *) node->pbst_data;

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

  recurse_verify_tree (node->pbst_link[0], okay, &subcount[0], min, d - 1);
  recurse_verify_tree (node->pbst_link[1], okay, &subcount[1], d + 1, max);
  *count = 1 + subcount[0] + subcount[1];

  for (i = 0; i < 2; i++)
    {
      if (node->pbst_link[i] != NULL
          && node->pbst_link[i]->pbst_parent != node)
        {
          printf (" Node %d has parent %d (should be %d).\n",
                  *(int *) node->pbst_link[i]->pbst_data,
                  (node->pbst_link[i]->pbst_parent != NULL
                   ? *(int *) node->pbst_link[i]->pbst_parent->pbst_data : -1),
                  d);
          *okay = 0;
        }
    }
}

/* Checks that |tree| is well-formed
   and verifies that the values in |array[]| are actually in |tree|.
   There must be |n| elements in |array[]| and |tree|.
   Returns nonzero only if no errors detected. */
static int
verify_tree (struct pbst_table *tree, int array[], size_t n)
{
  int okay = 1;

  /* Check |tree|'s bst_count against that supplied. */
  if (pbst_count (tree) != n)
    {
      printf (" Tree count is %lu, but should be %lu.\n",
              (unsigned long) pbst_count (tree), (unsigned long) n);
      okay = 0;
    }

  if (okay)
    {
      /* Recursively verify tree structure. */
      size_t count;

      recurse_verify_tree (tree->pbst_root, &okay, &count, 0, INT_MAX);
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
        if (pbst_find (tree, &array[i]) == NULL)
          {
            printf (" Tree does not contain expected value %d.\n", array[i]);
            okay = 0;
          }
    }

  if (okay)
    {
      /* Check that |pbst_t_first()| and |pbst_t_next()| work properly. */
      struct pbst_traverser trav;
      size_t i;
      int prev = -1;
      int *item;

      for (i = 0, item = pbst_t_first (&trav, tree); i < 2 * n && item != NULL;
           i++, item = pbst_t_next (&trav))
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
      /* Check that |pbst_t_last()| and |pbst_t_prev()| work properly. */
      struct pbst_traverser trav;
      size_t i;
      int next = INT_MAX;
      int *item;

      for (i = 0, item = pbst_t_last (&trav, tree); i < 2 * n && item != NULL;
           i++, item = pbst_t_prev (&trav))
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
      /* Check that |pbst_t_init()| works properly. */
      struct pbst_traverser init, first, last;
      int *cur, *prev, *next;

      pbst_t_init (&init, tree);
      pbst_t_first (&first, tree);
      pbst_t_last (&last, tree);

      cur = pbst_t_cur (&init);
      if (cur != NULL)
        {
          printf (" Inited traverser should be null, but is actually %d.\n",
                  *cur);
          okay = 0;
        }

      next = pbst_t_next (&init);
      if (next != pbst_t_cur (&first))
        {
          printf (" Next after null should be %d, but is actually %d.\n",
                  *(int *) pbst_t_cur (&first), *next);
          okay = 0;
        }
      pbst_t_prev (&init);

      prev = pbst_t_prev (&init);
      if (prev != pbst_t_cur (&last))
        {
          printf (" Previous before null should be %d, but is actually %d.\n",
                  *(int *) pbst_t_cur (&last), *prev);
          okay = 0;
        }
      pbst_t_next (&init);
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
  struct pbst_table *tree;
  int okay = 1;
  int i;

  /* Test creating a PBST and inserting into it. */
  tree = pbst_create (compare_ints, NULL, allocator);
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
        void **p = pbst_probe (tree, &insert[i]);
        if (p == NULL)
          {
            if (verbosity >= 0)
              printf ("    Out of memory in insertion.\n");
            pbst_destroy (tree, NULL);
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

  /* Test PBST traversal during modifications. */
  for (i = 0; i < n; i++)
    {
      struct pbst_traverser x, y, z;
      int *deleted;

      if (insert[i] == delete[i])
        continue;

      if (verbosity >= 2)
        printf ("   Checking traversal from item %d...\n", insert[i]);

      if (pbst_t_find (&x, tree, &insert[i]) == NULL)
        {
          printf ("    Can't find item %d in tree!\n", insert[i]);
          continue;
        }

      okay &= check_traverser (&x, insert[i], n, "Predeletion");

      if (verbosity >= 3)
        printf ("    Deleting item %d.\n", delete[i]);

      deleted = pbst_delete (tree, &delete[i]);
      if (deleted == NULL || *deleted != delete[i])
        {
          okay = 0;
          if (deleted == NULL)
            printf ("    Deletion failed.\n");
          else
            printf ("    Wrong node %d returned.\n", *deleted);
        }

      pbst_t_copy (&y, &x);

      if (verbosity >= 3)
        printf ("    Re-inserting item %d.\n", delete[i]);
      if (pbst_t_insert (&z, tree, &delete[i]) == NULL)
        {
          if (verbosity >= 0)
            printf ("    Out of memory re-inserting item.\n");
          pbst_destroy (tree, NULL);
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

      deleted = pbst_delete (tree, &delete[i]);
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
        struct pbst_table *copy = pbst_copy (tree, NULL, NULL, NULL);
        if (copy == NULL)
          {
            if (verbosity >= 0)
              printf ("  Out of memory in copy\n");
            pbst_destroy (tree, NULL);
            return 1;
          }

        okay &= compare_trees (tree->pbst_root, copy->pbst_root);
        pbst_destroy (copy, NULL);
      }
    }

  /* Test destroying the tree. */
  pbst_destroy (tree, NULL);

  /* Test |pbst_balance()|. */
  if (verbosity >= 2)
    printf ("  Testing balancing...\n");

  tree = pbst_create (compare_ints, NULL, allocator);
  if (tree == NULL)
    {
      if (verbosity >= 0)
        printf ("  Out of memory creating tree.\n");
      return 1;
    }

  for (i = 0; i < n; i++)
    {
      void **p = pbst_probe (tree, &insert[i]);
      if (p == NULL)
        {
          if (verbosity >= 0)
            printf ("    Out of memory in insertion.\n");
          pbst_destroy (tree, NULL);
          return 1;
        }
      if (*p != &insert[i])
        printf ("    Duplicate item in tree!\n");
    }

  if (verbosity >= 4)
    print_whole_tree (tree, "    Pre-balance");
  pbst_balance (tree);
  if (verbosity >= 4)
    print_whole_tree (tree, "    Post-balance");

  if (!verify_tree (tree, insert, n))
    return 0;

  pbst_destroy (tree, NULL);

  return okay;
}
static int
test_bst_t_first (struct pbst_table *tree, int n)
{
  struct pbst_traverser trav;
  int *first;

  first = pbst_t_first (&trav, tree);
  if (first == NULL || *first != 0)
    {
      printf ("    First item test failed: expected 0, got %d\n",
              first != NULL ? *first : -1);
      return 0;
    }

  return 1;
}

static int
test_bst_t_last (struct pbst_table *tree, int n)
{
  struct pbst_traverser trav;
  int *last;

  last = pbst_t_last (&trav, tree);
  if (last == NULL || *last != n - 1)
    {
      printf ("    Last item test failed: expected %d, got %d\n",
              n - 1, last != NULL ? *last : -1);
      return 0;
    }

  return 1;
}

static int
test_bst_t_find (struct pbst_table *tree, int n)
{
  int i;

  for (i = 0; i < n; i++)
    {
      struct pbst_traverser trav;
      int *iter;

      iter = pbst_t_find (&trav, tree, &i);
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
test_bst_t_insert (struct pbst_table *tree, int n)
{
  int i;

  for (i = 0; i < n; i++)
    {
      struct pbst_traverser trav;
      int *iter;

      iter = pbst_t_insert (&trav, tree, &i);
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
test_bst_t_next (struct pbst_table *tree, int n)
{
  struct pbst_traverser trav;
  int i;

  pbst_t_init (&trav, tree);
  for (i = 0; i < n; i++)
    {
      int *iter = pbst_t_next (&trav);
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
test_bst_t_prev (struct pbst_table *tree, int n)
{
  struct pbst_traverser trav;
  int i;

  pbst_t_init (&trav, tree);
  for (i = n - 1; i >= 0; i--)
    {
      int *iter = pbst_t_prev (&trav);
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
test_bst_copy (struct pbst_table *tree, int n)
{
  struct pbst_table *copy = pbst_copy (tree, NULL, NULL, NULL);
  int okay = compare_trees (tree->pbst_root, copy->pbst_root);

  pbst_destroy (copy, NULL);

  return okay;
}

/* Tests the tree routines for proper handling of overflows.
   Inserting the |n| elements of |order[]| should produce a tree
   with height greater than |PBST_MAX_HEIGHT|.
   Uses |allocator| as the allocator for tree and node data.
   Use |verbosity| to set the level of chatter on |stdout|. */
int
test_overflow (struct libavl_allocator *allocator,
               int order[], int n, int verbosity)
{
  /* An overflow tester function. */
  typedef int test_func (struct pbst_table *, int n);

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
      struct pbst_table *tree;
      int j;

      if (verbosity >= 2)
        printf ("  Running %s test...\n", i->name);

      tree = pbst_create (compare_ints, NULL, allocator);
      if (tree == NULL)
        {
          printf ("    Out of memory creating tree.\n");
          return 1;
        }

      for (j = 0; j < n; j++)
        {
          void **p = pbst_probe (tree, &order[j]);
          if (p == NULL || *p != &order[j])
            {
              if (p == NULL && verbosity >= 0)
                printf ("    Out of memory in insertion.\n");
              else if (p != NULL)
                printf ("    Duplicate item in tree!\n");
              pbst_destroy (tree, NULL);
              return p == NULL;
            }
        }

      if (i->func (tree, n) == 0)
        return 0;

      if (verify_tree (tree, order, n) == 0)
        return 0;
      pbst_destroy (tree, NULL);
    }

  return 1;
}
