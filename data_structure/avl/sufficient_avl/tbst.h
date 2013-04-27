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

#ifndef TBST_H
#define TBST_H 1

#include <stddef.h>

/* Function types. */
typedef int tbst_comparison_func (const void *tbst_a, const void *tbst_b,
                                 void *tbst_param);
typedef void tbst_item_func (void *tbst_item, void *tbst_param);
typedef void *tbst_copy_func (void *tbst_item, void *tbst_param);

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
extern struct libavl_allocator tbst_allocator_default;
void *tbst_malloc (struct libavl_allocator *, size_t);
void tbst_free (struct libavl_allocator *, void *);

/* Tree data structure. */
struct tbst_table
  {
    struct tbst_node *tbst_root;        /* Tree's root. */
    tbst_comparison_func *tbst_compare; /* Comparison function. */
    void *tbst_param;                   /* Extra argument to |tbst_compare|. */
    struct libavl_allocator *tbst_alloc; /* Memory allocator. */
    size_t tbst_count;                  /* Number of items in tree. */
  };

/* Characterizes a link as a child pointer or a thread. */
enum tbst_tag
  {
    TBST_CHILD,                     /* Child pointer. */
    TBST_THREAD                     /* Thread. */
  };

/* A threaded binary search tree node. */
struct tbst_node
  {
    struct tbst_node *tbst_link[2]; /* Subtrees. */
    void *tbst_data;                /* Pointer to data. */
    unsigned char tbst_tag[2];      /* Tag fields. */
  };

/* TBST traverser structure. */
struct tbst_traverser
  {
    struct tbst_table *tbst_table;        /* Tree being traversed. */
    struct tbst_node *tbst_node;          /* Current node in tree. */
  };

/* Table functions. */
struct tbst_table *tbst_create (tbst_comparison_func *, void *,
                              struct libavl_allocator *);
struct tbst_table *tbst_copy (const struct tbst_table *, tbst_copy_func *,
                            tbst_item_func *, struct libavl_allocator *);
void tbst_destroy (struct tbst_table *, tbst_item_func *);
void **tbst_probe (struct tbst_table *, void *);
void *tbst_insert (struct tbst_table *, void *);
void *tbst_replace (struct tbst_table *, void *);
void *tbst_delete (struct tbst_table *, const void *);
void *tbst_find (const struct tbst_table *, const void *);
void tbst_assert_insert (struct tbst_table *, void *);
void *tbst_assert_delete (struct tbst_table *, void *);

#define tbst_count(table) ((size_t) (table)->tbst_count)

/* Table traverser functions. */
void tbst_t_init (struct tbst_traverser *, struct tbst_table *);
void *tbst_t_first (struct tbst_traverser *, struct tbst_table *);
void *tbst_t_last (struct tbst_traverser *, struct tbst_table *);
void *tbst_t_find (struct tbst_traverser *, struct tbst_table *, void *);
void *tbst_t_insert (struct tbst_traverser *, struct tbst_table *, void *);
void *tbst_t_copy (struct tbst_traverser *, const struct tbst_traverser *);
void *tbst_t_next (struct tbst_traverser *);
void *tbst_t_prev (struct tbst_traverser *);
void *tbst_t_cur (struct tbst_traverser *);
void *tbst_t_replace (struct tbst_traverser *, void *);

/* Special TBST functions. */
void tbst_balance (struct tbst_table *tree);

#endif /* tbst.h */
