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

#ifndef RTRB_H
#define RTRB_H 1

#include <stddef.h>

/* Function types. */
typedef int rtrb_comparison_func (const void *rtrb_a, const void *rtrb_b,
                                 void *rtrb_param);
typedef void rtrb_item_func (void *rtrb_item, void *rtrb_param);
typedef void *rtrb_copy_func (void *rtrb_item, void *rtrb_param);

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
extern struct libavl_allocator rtrb_allocator_default;
void *rtrb_malloc (struct libavl_allocator *, size_t);
void rtrb_free (struct libavl_allocator *, void *);

/* Maximum RTRB height. */
#ifndef RTRB_MAX_HEIGHT
#define RTRB_MAX_HEIGHT 128
#endif

/* Tree data structure. */
struct rtrb_table
  {
    struct rtrb_node *rtrb_root;        /* Tree's root. */
    rtrb_comparison_func *rtrb_compare; /* Comparison function. */
    void *rtrb_param;                   /* Extra argument to |rtrb_compare|. */
    struct libavl_allocator *rtrb_alloc; /* Memory allocator. */
    size_t rtrb_count;                  /* Number of items in tree. */
  };

/* Color of a red-black node. */
enum rtrb_color
  {
    RTRB_BLACK,                     /* Black. */
    RTRB_RED                        /* Red. */
  };

/* Characterizes a link as a child pointer or a thread. */
enum rtrb_tag
  {
    RTRB_CHILD,                     /* Child pointer. */
    RTRB_THREAD                     /* Thread. */
  };

/* A threaded binary search tree node. */
struct rtrb_node
  {
    struct rtrb_node *rtrb_link[2]; /* Subtrees. */
    void *rtrb_data;                /* Pointer to data. */
    unsigned char rtrb_color;       /* Color. */
    unsigned char rtrb_rtag;        /* Tag field. */
  };

/* RTRB traverser structure. */
struct rtrb_traverser
  {
    struct rtrb_table *rtrb_table;        /* Tree being traversed. */
    struct rtrb_node *rtrb_node;          /* Current node in tree. */
  };

/* Table functions. */
struct rtrb_table *rtrb_create (rtrb_comparison_func *, void *,
                              struct libavl_allocator *);
struct rtrb_table *rtrb_copy (const struct rtrb_table *, rtrb_copy_func *,
                            rtrb_item_func *, struct libavl_allocator *);
void rtrb_destroy (struct rtrb_table *, rtrb_item_func *);
void **rtrb_probe (struct rtrb_table *, void *);
void *rtrb_insert (struct rtrb_table *, void *);
void *rtrb_replace (struct rtrb_table *, void *);
void *rtrb_delete (struct rtrb_table *, const void *);
void *rtrb_find (const struct rtrb_table *, const void *);
void rtrb_assert_insert (struct rtrb_table *, void *);
void *rtrb_assert_delete (struct rtrb_table *, void *);

#define rtrb_count(table) ((size_t) (table)->rtrb_count)

/* Table traverser functions. */
void rtrb_t_init (struct rtrb_traverser *, struct rtrb_table *);
void *rtrb_t_first (struct rtrb_traverser *, struct rtrb_table *);
void *rtrb_t_last (struct rtrb_traverser *, struct rtrb_table *);
void *rtrb_t_find (struct rtrb_traverser *, struct rtrb_table *, void *);
void *rtrb_t_insert (struct rtrb_traverser *, struct rtrb_table *, void *);
void *rtrb_t_copy (struct rtrb_traverser *, const struct rtrb_traverser *);
void *rtrb_t_next (struct rtrb_traverser *);
void *rtrb_t_prev (struct rtrb_traverser *);
void *rtrb_t_cur (struct rtrb_traverser *);
void *rtrb_t_replace (struct rtrb_traverser *, void *);

#endif /* rtrb.h */
