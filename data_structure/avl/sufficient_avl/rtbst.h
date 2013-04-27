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

#ifndef RTBST_H
#define RTBST_H 1

#include <stddef.h>

/* Function types. */
typedef int rtbst_comparison_func (const void *rtbst_a, const void *rtbst_b,
                                 void *rtbst_param);
typedef void rtbst_item_func (void *rtbst_item, void *rtbst_param);
typedef void *rtbst_copy_func (void *rtbst_item, void *rtbst_param);

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
extern struct libavl_allocator rtbst_allocator_default;
void *rtbst_malloc (struct libavl_allocator *, size_t);
void rtbst_free (struct libavl_allocator *, void *);

/* Tree data structure. */
struct rtbst_table
  {
    struct rtbst_node *rtbst_root;        /* Tree's root. */
    rtbst_comparison_func *rtbst_compare; /* Comparison function. */
    void *rtbst_param;                   /* Extra argument to |rtbst_compare|. */
    struct libavl_allocator *rtbst_alloc; /* Memory allocator. */
    size_t rtbst_count;                  /* Number of items in tree. */
  };

/* Characterizes a link as a child pointer or a thread. */
enum rtbst_tag
  {
    RTBST_CHILD,                     /* Child pointer. */
    RTBST_THREAD                     /* Thread. */
  };

/* A threaded binary search tree node. */
struct rtbst_node
  {
    struct rtbst_node *rtbst_link[2]; /* Subtrees. */
    void *rtbst_data;                 /* Pointer to data. */
    unsigned char rtbst_rtag;         /* Tag field. */
  };

/* RTBST traverser structure. */
struct rtbst_traverser
  {
    struct rtbst_table *rtbst_table;        /* Tree being traversed. */
    struct rtbst_node *rtbst_node;          /* Current node in tree. */
  };

/* Table functions. */
struct rtbst_table *rtbst_create (rtbst_comparison_func *, void *,
                              struct libavl_allocator *);
struct rtbst_table *rtbst_copy (const struct rtbst_table *, rtbst_copy_func *,
                            rtbst_item_func *, struct libavl_allocator *);
void rtbst_destroy (struct rtbst_table *, rtbst_item_func *);
void **rtbst_probe (struct rtbst_table *, void *);
void *rtbst_insert (struct rtbst_table *, void *);
void *rtbst_replace (struct rtbst_table *, void *);
void *rtbst_delete (struct rtbst_table *, const void *);
void *rtbst_find (const struct rtbst_table *, const void *);
void rtbst_assert_insert (struct rtbst_table *, void *);
void *rtbst_assert_delete (struct rtbst_table *, void *);

#define rtbst_count(table) ((size_t) (table)->rtbst_count)

/* Table traverser functions. */
void rtbst_t_init (struct rtbst_traverser *, struct rtbst_table *);
void *rtbst_t_first (struct rtbst_traverser *, struct rtbst_table *);
void *rtbst_t_last (struct rtbst_traverser *, struct rtbst_table *);
void *rtbst_t_find (struct rtbst_traverser *, struct rtbst_table *, void *);
void *rtbst_t_insert (struct rtbst_traverser *, struct rtbst_table *, void *);
void *rtbst_t_copy (struct rtbst_traverser *, const struct rtbst_traverser *);
void *rtbst_t_next (struct rtbst_traverser *);
void *rtbst_t_prev (struct rtbst_traverser *);
void *rtbst_t_cur (struct rtbst_traverser *);
void *rtbst_t_replace (struct rtbst_traverser *, void *);

/* Special RTBST functions. */
void rtbst_balance (struct rtbst_table *tree);

#endif /* rtbst.h */
