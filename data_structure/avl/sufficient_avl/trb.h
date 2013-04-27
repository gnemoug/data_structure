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

#ifndef TRB_H
#define TRB_H 1

#include <stddef.h>

/* Function types. */
typedef int trb_comparison_func (const void *trb_a, const void *trb_b,
                                 void *trb_param);
typedef void trb_item_func (void *trb_item, void *trb_param);
typedef void *trb_copy_func (void *trb_item, void *trb_param);

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
extern struct libavl_allocator trb_allocator_default;
void *trb_malloc (struct libavl_allocator *, size_t);
void trb_free (struct libavl_allocator *, void *);

/* Maximum TRB height. */
#ifndef TRB_MAX_HEIGHT
#define TRB_MAX_HEIGHT 128
#endif

/* Tree data structure. */
struct trb_table
  {
    struct trb_node *trb_root;        /* Tree's root. */
    trb_comparison_func *trb_compare; /* Comparison function. */
    void *trb_param;                   /* Extra argument to |trb_compare|. */
    struct libavl_allocator *trb_alloc; /* Memory allocator. */
    size_t trb_count;                  /* Number of items in tree. */
  };

/* Color of a red-black node. */
enum trb_color
  {
    TRB_BLACK,                     /* Black. */
    TRB_RED                        /* Red. */
  };

/* Characterizes a link as a child pointer or a thread. */
enum trb_tag
  {
    TRB_CHILD,                     /* Child pointer. */
    TRB_THREAD                     /* Thread. */
  };

/* An TRB tree node. */
struct trb_node
  {
    struct trb_node *trb_link[2];  /* Subtrees. */
    void *trb_data;                /* Pointer to data. */
    unsigned char trb_color;       /* Color. */
    unsigned char trb_tag[2];      /* Tag fields. */
  };

/* TRB traverser structure. */
struct trb_traverser
  {
    struct trb_table *trb_table;        /* Tree being traversed. */
    struct trb_node *trb_node;          /* Current node in tree. */
  };

/* Table functions. */
struct trb_table *trb_create (trb_comparison_func *, void *,
                              struct libavl_allocator *);
struct trb_table *trb_copy (const struct trb_table *, trb_copy_func *,
                            trb_item_func *, struct libavl_allocator *);
void trb_destroy (struct trb_table *, trb_item_func *);
void **trb_probe (struct trb_table *, void *);
void *trb_insert (struct trb_table *, void *);
void *trb_replace (struct trb_table *, void *);
void *trb_delete (struct trb_table *, const void *);
void *trb_find (const struct trb_table *, const void *);
void trb_assert_insert (struct trb_table *, void *);
void *trb_assert_delete (struct trb_table *, void *);

#define trb_count(table) ((size_t) (table)->trb_count)

/* Table traverser functions. */
void trb_t_init (struct trb_traverser *, struct trb_table *);
void *trb_t_first (struct trb_traverser *, struct trb_table *);
void *trb_t_last (struct trb_traverser *, struct trb_table *);
void *trb_t_find (struct trb_traverser *, struct trb_table *, void *);
void *trb_t_insert (struct trb_traverser *, struct trb_table *, void *);
void *trb_t_copy (struct trb_traverser *, const struct trb_traverser *);
void *trb_t_next (struct trb_traverser *);
void *trb_t_prev (struct trb_traverser *);
void *trb_t_cur (struct trb_traverser *);
void *trb_t_replace (struct trb_traverser *, void *);

#endif /* trb.h */
