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
#include "rtbst.h"
#include "test.h"

/* Prints the structure of |node|,
   which is |level| levels from the top of the tree. */
void
print_tree_structure (struct rtbst_node *node, int level)
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
    {
      printf ("<nil>");
      return;
    }

  printf ("%d(", node->rtbst_data ? *(int *) node->rtbst_data : -1);

  if (node->rtbst_link[0] != NULL)
    print_tree_structure (node->rtbst_link[0], level + 1);

  fputs (", ", stdout);

  if (node->rtbst_rtag == RTBST_CHILD)
    {
      if (node->rtbst_link[1] == node)
        printf ("loop");
      else
        print_tree_structure (node->rtbst_link[1], level + 1);
    }
  else if (node->rtbst_link[1] != NULL)
    printf (">%d",
            (node->rtbst_link[1]->rtbst_data
             ? *(int *) node->rtbst_link[1]->rtbst_data : -1));
  else
    printf (">>");

  putchar (')');
}

/* Prints the entire structure of |tree| with the given |title|. */
void
print_whole_tree (const struct rtbst_table *tree, const char *title)
{
  printf ("%s: ", title);
  print_tree_structure (tree->rtbst_root, 0);
  putchar ('\n');
}

/* Checks that the current item at |trav| is |i|
   and that its previous and next items are as they should be.
   |label| is a name for the traverser used in reporting messages.
   There should be |n| items in the tree numbered |0|@dots{}|n - 1|.
   Returns nonzero only if there is an error. */
static int
check_traverser (struct rtbst_traverser *trav, int i, int n, const char *label)
{
  int okay = 1;
  int *cur, *prev, *next;

  prev = rtbst_t_prev (trav);
  if ((i == 0 && prev != NULL)
      || (i > 0 && (prev == NULL || *prev != i - 1)))
    {
      printf ("   %s traverser ahead of %d, but should be ahead of %d.\n",
              label, prev != NULL ? *prev : -1, i == 0 ? -1 : i - 1);
      okay = 0;
    }
  rtbst_t_next (trav);

  cur = rtbst_t_cur (trav);
  if (cur == NULL || *cur != i)
    {
      printf ("   %s traverser at %d, but should be at %d.\n",
              label, cur != NULL ? *cur : -1, i);
      okay = 0;
    }

  next = rtbst_t_next (trav);
  if ((i == n - 1 && next != NULL)
      || (i != n - 1 && (next == NULL || *next != i + 1)))
    {
      printf ("   %s traverser behind %d, but should be behind %d.\n",
              label, next != NULL ? *next : -1, i == n - 1 ? -1 : i + 1);
      okay = 0;
    }
  rtbst_t_prev (trav);

  return okay;
}

/* Compares binary trees rooted at |a| and |b|,
   making sure that they are identical. */
static int
compare_trees (struct rtbst_node *a, struct rtbst_node *b)
{
  int okay;

  if (a == NULL || b == NULL)
    {
      if (a != NULL || b != NULL)
        {
          printf (" a=%d b=%d\n",
                  a ? *(int *) a->rtbst_data : -1,
                  b ? *(int *) b->rtbst_data : -1);
          assert (0);
        }
      return 1;
    }
  assert (a != b);

  if (*(int *) a->rtbst_data != *(int *) b->rtbst_data
      || a->rtbst_rtag != b->rtbst_rtag)
    {
      printf (" Copied nodes differ: a=%d b=%d a:",
              *(int *) a->rtbst_data, *(int *) b->rtbst_data);

      if (a->rtbst_rtag == RTBST_CHILD)
        printf ("r");

      printf (" b:");
      if (b->rtbst_rtag == RTBST_CHILD)
        printf ("r");

      printf ("\n");
      return 0;
    }

  if (a->rtbst_rtag == RTBST_THREAD)
    assert ((a->rtbst_link[1] == NULL)
            != (a->rtbst_link[1] != b->rtbst_link[1]));

  okay = compare_trees (a->rtbst_link[0], b->rtbst_link[0]);
  if (a->rtbst_rtag == RTBST_CHILD)
    okay &= compare_trees (a->rtbst_link[1], b->rtbst_link[1]);
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
recurse_verify_tree (struct rtbst_node *node, int *okay, size_t *count,
                     int min, int max)
{
  int d;                /* Value of this node's data. */
  size_t subcount[2];   /* Number of nodes in subtrees. */

  if (node == NULL)
    {
      *count = 0;
      return;
    }
  d = *(int *) node->rtbst_data;

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
  recurse_verify_tree (node->rtbst_link[0], okay, &subcount[0], min, d - 1);
  if (node->rtbst_rtag == RTBST_CHILD)
    recurse_verify_tree (node->rtbst_link[1], okay, &subcount[1], d + 1, max);
  *count = 1 + subcount[0] + subcount[1];
}

/* Checks that |tree| is well-formed
   and verifies that the values in |array[]| are actually in |tree|.
   There must be |n| elements in |array[]| and |tree|.
   Returns nonzero only if no errors detected. */
static int
verify_tree (struct rtbst_table *tree, int array[], size_t n)
{
  int okay = 1;

  /* Check |tree|'s bst_count against that supplied. */
  if (rtbst_count (tree) != n)
    {
      printf (" Tree count is %lu, but should be %lu.\n",
              (unsigned long) rtbst_count (tree), (unsigned long) n);
      okay = 0;
    }

  if (okay)
    {
      /* Recursively verify tree structure. */
      size_t count;

      recurse_verify_tree (tree->rtbst_root, &okay, &count, 0, INT_MAX);
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
        if (rtbst_find (tree, &array[i]) == NULL)
          {
            printf (" Tree does not contain expected value %d.\n", array[i]);
            okay = 0;
          }
    }

  if (okay)
    {
      /* Check that |rtbst_t_first()| and |rtbst_t_next()| work properly. */
      struct rtbst_traverser trav;
      size_t i;
      int prev = -1;
      int *item;

      for (i = 0, item = rtbst_t_first (&trav, tree); i < 2 * n && item != NULL;
           i++, item = rtbst_t_next (&trav))
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
      /* Check that |rtbst_t_last()| and |rtbst_t_prev()| work properly. */
      struct rtbst_traverser trav;
      size_t i;
      int next = INT_MAX;
      int *item;

      for (i = 0, item = rtbst_t_last (&trav, tree); i < 2 * n && item != NULL;
           i++, item = rtbst_t_prev (&trav))
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
      /* Check that |rtbst_t_init()| works properly. */
      struct rtbst_traverser init, first, last;
      int *cur, *prev, *next;

      rtbst_t_init (&init, tree);
      rtbst_t_first (&first, tree);
      rtbst_t_last (&last, tree);

      cur = rtbst_t_cur (&init);
      if (cur != NULL)
        {
          printf (" Inited traverser should be null, but is actually %d.\n",
                  *cur);
          okay = 0;
        }

      next = rtbst_t_next (&init);
      if (next != rtbst_t_cur (&first))
        {
          printf (" Next after null should be %d, but is actually %d.\n",
                  *(int *) rtbst_t_cur (&first), *next);
          okay = 0;
        }
      rtbst_t_prev (&init);

      prev = rtbst_t_prev (&init);
      if (prev != rtbst_t_cur (&last))
        {
          printf (" Previous before null should be %d, but is actually %d.\n",
                  *(int *) rtbst_t_cur (&last), *prev);
          okay = 0;
        }
      rtbst_t_next (&init);
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
  struct rtbst_table *tree;
  int okay = 1;
  int i;

  /* Test creating a RTBST and inserting into it. */
  tree = rtbst_create (compare_ints, NULL, allocator);
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
        void **p = rtbst_probe (tree, &insert[i]);
        if (p == NULL)
          {
            if (verbosity >= 0)
              printf ("    Out of memory in insertion.\n");
            rtbst_destroy (tree, NULL);
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

  /* Test RTBST traversal during modifications. */
  for (i = 0; i < n; i++)
    {
      struct rtbst_traverser x, y, z;
      int *deleted;

      if (insert[i] == delete[i])
        continue;

      if (verbosity >= 2)
        printf ("   Checking traversal from item %d...\n", insert[i]);

      if (rtbst_t_find (&x, tree, &insert[i]) == NULL)
        {
          printf ("    Can't find item %d in tree!\n", insert[i]);
          continue;
        }

      okay &= check_traverser (&x, insert[i], n, "Predeletion");

      if (verbosity >= 3)
        printf ("    Deleting item %d.\n", delete[i]);

      deleted = rtbst_delete (tree, &delete[i]);
      if (deleted == NULL || *deleted != delete[i])
        {
          okay = 0;
          if (deleted == NULL)
            printf ("    Deletion failed.\n");
          else
            printf ("    Wrong node %d returned.\n", *deleted);
        }

      rtbst_t_copy (&y, &x);

      if (verbosity >= 3)
        printf ("    Re-inserting item %d.\n", delete[i]);
      if (rtbst_t_insert (&z, tree, &delete[i]) == NULL)
        {
          if (verbosity >= 0)
            printf ("    Out of memory re-inserting item.\n");
          rtbst_destroy (tree, NULL);
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

      deleted = rtbst_delete (tree, &delete[i]);
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
        struct rtbst_table *copy = rtbst_copy (tree, NULL, NULL, NULL);
        if (copy == NULL)
          {
            if (verbosity >= 0)
              printf ("  Out of memory in copy\n");
            rtbst_destroy (tree, NULL);
            return 1;
          }

        okay &= compare_trees (tree->rtbst_root, copy->rtbst_root);
        rtbst_destroy (copy, NULL);
      }
    }

  /* Test destroying the tree. */
  rtbst_destroy (tree, NULL);

  /* Test |rtbst_balance()|. */
  if (verbosity >= 2)
    printf ("  Testing balancing...\n");

  tree = rtbst_create (compare_ints, NULL, allocator);
  if (tree == NULL)
    {
      if (verbosity >= 0)
        printf ("  Out of memory creating tree.\n");
      return 1;
    }

  for (i = 0; i < n; i++)
    {
      void **p = rtbst_probe (tree, &insert[i]);
      if (p == NULL)
        {
          if (verbosity >= 0)
            printf ("    Out of memory in insertion.\n");
          rtbst_destroy (tree, NULL);
          return 1;
        }
      if (*p != &insert[i])
        printf ("    Duplicate item in tree!\n");
    }

  if (verbosity >= 4)
    print_whole_tree (tree, "    Pre-balance");
  rtbst_balance (tree);
  if (verbosity >= 4)
    print_whole_tree (tree, "    Post-balance");

  if (!verify_tree (tree, insert, n))
    return 0;

  rtbst_destroy (tree, NULL);

  return okay;
}
static int
test_bst_t_first (struct rtbst_table *tree, int n)
{
  struct rtbst_traverser trav;
  int *first;

  first = rtbst_t_first (&trav, tree);
  if (first == NULL || *first != 0)
    {
      printf ("    First item test failed: expected 0, got %d\n",
              first != NULL ? *first : -1);
      return 0;
    }

  return 1;
}

static int
test_bst_t_last (struct rtbst_table *tree, int n)
{
  struct rtbst_traverser trav;
  int *last;

  last = rtbst_t_last (&trav, tree);
  if (last == NULL || *last != n - 1)
    {
      printf ("    Last item test failed: expected %d, got %d\n",
              n - 1, last != NULL ? *last : -1);
      return 0;
    }

  return 1;
}

static int
test_bst_t_find (struct rtbst_table *tree, int n)
{
  int i;

  for (i = 0; i < n; i++)
    {
      struct rtbst_traverser trav;
      int *iter;

      iter = rtbst_t_find (&trav, tree, &i);
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
test_bst_t_insert (struct rtbst_table *tree, int n)
{
  int i;

  for (i = 0; i < n; i++)
    {
      struct rtbst_traverser trav;
      int *iter;

      iter = rtbst_t_insert (&trav, tree, &i);
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
test_bst_t_next (struct rtbst_table *tree, int n)
{
  struct rtbst_traverser trav;
  int i;

  rtbst_t_init (&trav, tree);
  for (i = 0; i < n; i++)
    {
      int *iter = rtbst_t_next (&trav);
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
test_bst_t_prev (struct rtbst_table *tree, int n)
{
  struct rtbst_traverser trav;
  int i;

  rtbst_t_init (&trav, tree);
  for (i = n - 1; i >= 0; i--)
    {
      int *iter = rtbst_t_prev (&trav);
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
test_bst_copy (struct rtbst_table *tree, int n)
{
  struct rtbst_table *copy = rtbst_copy (tree, NULL, NULL, NULL);
  int okay = compare_trees (tree->rtbst_root, copy->rtbst_root);

  rtbst_destroy (copy, NULL);

  return okay;
}

/* Tests the tree routines for proper handling of overflows.
   Inserting the |n| elements of |order[]| should produce a tree
   with height greater than |RTBST_MAX_HEIGHT|.
   Uses |allocator| as the allocator for tree and node data.
   Use |verbosity| to set the level of chatter on |stdout|. */
int
test_overflow (struct libavl_allocator *allocator,
               int order[], int n, int verbosity)
{
  /* An overflow tester function. */
  typedef int test_func (struct rtbst_table *, int n);

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
      struct rtbst_table *tree;
      int j;

      if (verbosity >= 2)
        printf ("  Running %s test...\n", i->name);

      tree = rtbst_create (compare_ints, NULL, allocator);
      if (tree == NULL)
        {
          printf ("    Out of memory creating tree.\n");
          return 1;
        }

      for (j = 0; j < n; j++)
        {
          void **p = rtbst_probe (tree, &order[j]);
          if (p == NULL || *p != &order[j])
            {
              if (p == NULL && verbosity >= 0)
                printf ("    Out of memory in insertion.\n");
              else if (p != NULL)
                printf ("    Duplicate item in tree!\n");
              rtbst_destroy (tree, NULL);
              return p == NULL;
            }
        }

      if (i->func (tree, n) == 0)
        return 0;

      if (verify_tree (tree, order, n) == 0)
        return 0;
      rtbst_destroy (tree, NULL);
    }

  return 1;
}
