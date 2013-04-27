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

#ifndef RTAVL_H
#define RTAVL_H 1

#include <stddef.h>

/* Function types. */
typedef int rtavl_comparison_func (const void *rtavl_a, const void *rtavl_b,
                                 void *rtavl_param);
typedef void rtavl_item_func (void *rtavl_item, void *rtavl_param);
typedef void *rtavl_copy_func (void *rtavl_item, void *rtavl_param);

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
extern struct libavl_allocator rtavl_allocator_default;
void *rtavl_malloc (struct libavl_allocator *, size_t);
void rtavl_free (struct libavl_allocator *, void *);

/* Maximum RTAVL height. */
#ifndef RTAVL_MAX_HEIGHT
#define RTAVL_MAX_HEIGHT 32
#endif

/* Tree data structure. */
struct rtavl_table
  {
    struct rtavl_node *rtavl_root;        /* Tree's root. */
    rtavl_comparison_func *rtavl_compare; /* Comparison function. */
    void *rtavl_param;                   /* Extra argument to |rtavl_compare|. */
    struct libavl_allocator *rtavl_alloc; /* Memory allocator. */
    size_t rtavl_count;                  /* Number of items in tree. */
  };

/* Characterizes a link as a child pointer or a thread. */
enum rtavl_tag
  {
    RTAVL_CHILD,                     /* Child pointer. */
    RTAVL_THREAD                     /* Thread. */
  };

/* A threaded binary search tree node. */
struct rtavl_node
  {
    struct rtavl_node *rtavl_link[2]; /* Subtrees. */
    void *rtavl_data;                 /* Pointer to data. */
    unsigned char rtavl_rtag;         /* Tag field. */
    signed char rtavl_balance;        /* Balance factor. */
  };

/* RTAVL traverser structure. */
struct rtavl_traverser
  {
    struct rtavl_table *rtavl_table;        /* Tree being traversed. */
    struct rtavl_node *rtavl_node;          /* Current node in tree. */
  };

/* Table functions. */
struct rtavl_table *rtavl_create (rtavl_comparison_func *, void *,
                              struct libavl_allocator *);
struct rtavl_table *rtavl_copy (const struct rtavl_table *, rtavl_copy_func *,
                            rtavl_item_func *, struct libavl_allocator *);
void rtavl_destroy (struct rtavl_table *, rtavl_item_func *);
void **rtavl_probe (struct rtavl_table *, void *);
void *rtavl_insert (struct rtavl_table *, void *);
void *rtavl_replace (struct rtavl_table *, void *);
void *rtavl_delete (struct rtavl_table *, const void *);
void *rtavl_find (const struct rtavl_table *, const void *);
void rtavl_assert_insert (struct rtavl_table *, void *);
void *rtavl_assert_delete (struct rtavl_table *, void *);

#define rtavl_count(table) ((size_t) (table)->rtavl_count)

/* Table traverser functions. */
void rtavl_t_init (struct rtavl_traverser *, struct rtavl_table *);
void *rtavl_t_first (struct rtavl_traverser *, struct rtavl_table *);
void *rtavl_t_last (struct rtavl_traverser *, struct rtavl_table *);
void *rtavl_t_find (struct rtavl_traverser *, struct rtavl_table *, void *);
void *rtavl_t_insert (struct rtavl_traverser *, struct rtavl_table *, void *);
void *rtavl_t_copy (struct rtavl_traverser *, const struct rtavl_traverser *);
void *rtavl_t_next (struct rtavl_traverser *);
void *rtavl_t_prev (struct rtavl_traverser *);
void *rtavl_t_cur (struct rtavl_traverser *);
void *rtavl_t_replace (struct rtavl_traverser *, void *);

#endif /* rtavl.h */
