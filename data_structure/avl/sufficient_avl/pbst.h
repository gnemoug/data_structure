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

#ifndef PBST_H
#define PBST_H 1

#include <stddef.h>

/* Function types. */
typedef int pbst_comparison_func (const void *pbst_a, const void *pbst_b,
                                 void *pbst_param);
typedef void pbst_item_func (void *pbst_item, void *pbst_param);
typedef void *pbst_copy_func (void *pbst_item, void *pbst_param);

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
extern struct libavl_allocator pbst_allocator_default;
void *pbst_malloc (struct libavl_allocator *, size_t);
void pbst_free (struct libavl_allocator *, void *);

/* Tree data structure. */
struct pbst_table
  {
    struct pbst_node *pbst_root;        /* Tree's root. */
    pbst_comparison_func *pbst_compare; /* Comparison function. */
    void *pbst_param;                   /* Extra argument to |pbst_compare|. */
    struct libavl_allocator *pbst_alloc; /* Memory allocator. */
    size_t pbst_count;                  /* Number of items in tree. */
  };

/* A binary search tree with parent pointers node. */
struct pbst_node
  {
    struct pbst_node *pbst_link[2];   /* Subtrees. */
    struct pbst_node *pbst_parent;    /* Parent. */
    void *pbst_data;                  /* Pointer to data. */
  };

/* PBST traverser structure. */
struct pbst_traverser
  {
    struct pbst_table *pbst_table;        /* Tree being traversed. */
    struct pbst_node *pbst_node;          /* Current node in tree. */
  };

/* Table functions. */
struct pbst_table *pbst_create (pbst_comparison_func *, void *,
                              struct libavl_allocator *);
struct pbst_table *pbst_copy (const struct pbst_table *, pbst_copy_func *,
                            pbst_item_func *, struct libavl_allocator *);
void pbst_destroy (struct pbst_table *, pbst_item_func *);
void **pbst_probe (struct pbst_table *, void *);
void *pbst_insert (struct pbst_table *, void *);
void *pbst_replace (struct pbst_table *, void *);
void *pbst_delete (struct pbst_table *, const void *);
void *pbst_find (const struct pbst_table *, const void *);
void pbst_assert_insert (struct pbst_table *, void *);
void *pbst_assert_delete (struct pbst_table *, void *);

#define pbst_count(table) ((size_t) (table)->pbst_count)

/* Table traverser functions. */
void pbst_t_init (struct pbst_traverser *, struct pbst_table *);
void *pbst_t_first (struct pbst_traverser *, struct pbst_table *);
void *pbst_t_last (struct pbst_traverser *, struct pbst_table *);
void *pbst_t_find (struct pbst_traverser *, struct pbst_table *, void *);
void *pbst_t_insert (struct pbst_traverser *, struct pbst_table *, void *);
void *pbst_t_copy (struct pbst_traverser *, const struct pbst_traverser *);
void *pbst_t_next (struct pbst_traverser *);
void *pbst_t_prev (struct pbst_traverser *);
void *pbst_t_cur (struct pbst_traverser *);
void *pbst_t_replace (struct pbst_traverser *, void *);

/* Special PBST functions. */
void pbst_balance (struct pbst_table *tree);

#endif /* pbst.h */
