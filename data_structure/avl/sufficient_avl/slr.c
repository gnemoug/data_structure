/* slr - generates SLR parser for TexiWEB.
   Copyright (C) 2002, 2004 Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 3 of the
   License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.
   
   You should have received a copy of the GNU General Public
   License along with this program; if not, write to: Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301 USA. */

#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* All allusions to algorithms, page numbers, etc., below refer to
   Aho, Sethi, and Ullman, _Compilers: Principles, Techniques, and
   Tools_, Addison-Wesley 1986; ISBN 0201100886. */

/* Grammar rules for the parser.

   grammar[][0]: Specified in the form <nonterminal>=<grammar
   symbol>..., where every terminal and nonterminal is represented by
   a single character.

   grammar[][1]: Optional symbolic name of the corresponding
   reduction, which can be used by the parser to execute semantic
   rules.  If none is needed, specify an empty string. */
static const char *grammar[][2] = 
  {
    /* start => declaration. */
    {"S=s",	""},

    /* declaration => (decl-specifiers declarator-list terminator)... */
    {"s=TDe",	"reduce_declaration"},
    {"s=sTDe",	"reduce_declaration"},

    /* decl-specifiers => decl-specifier... */
    {"T=tT",	""},
    {"T=t",	""},

    /* decl-specifier => "typedef"
                       | ("int" | "void" | ... | typedef-name)
		       | ("struct" | "union" | "enum") tag [struct-defn]
		       | ("const" | "volatile") */
    {"t=1",	"reduce_typedef"},
    {"t=2",	""},
    {"t=3iB",	""},
    {"t=4",	""},

    /* struct-defn => <nothing>
                    | "{" skip-balanced "}" */
    {"B=xa}",	""},
    {"B=",	""},
    {"x={",	"reduce_struct_definition"},

    /* declarator-list => ptr-declarator [, ptr-declarator]... */
    {"D=d,D",	"reduce_declarator"},
    {"D=d",	"reduce_declarator"},

    /* ptr-declarator => "*" ptr-qualifier ptr-declarator
                       | declarator */
    {"d=*Qd",	"reduce_pointer"},
    {"d=E",	""},

    /* ptr-qualifier => <nothing>
                      | ("const" | "volatile") */
    {"Q=Q4",	""},
    {"Q=",	""},

    /* declarator => identifier
                   | "(" declarator ")"
                   | declarator "[" skip-balanced "]"
                   | declarator "(" skip-balanced ")" */
    {"E=I",	""},
    {"E=(d)",	""},
    {"E=E[a]",	"reduce_array"},
    {"E=E(a)",	"reduce_function"},
    {"I=i",	"reduce_identifier"},

    /* skip-balanced => "any non-paired token"
                      | "(" skip-balanced ")"
                      | "[" skip-balanced "]"
                      | "{" skip-balanced "}" */
    {"a=",	""},
    {"a=ab",	""},
    {"b=(a)",	""},
    {"b={a}",	""},
    {"b=[a]",	""},
    {"b=i",	""},
    {"b=o",	""},
    {"b=1",	""},
    {"b=2",	""},
    {"b=3",	""},
    {"b=4",	""},
    {"b=,",	""},
    {"b=*",	""},
    {"b=;",	""},

    /* terminator => ";"
                   | "{" skip-balanced "}" */
    {"e=;",	""},
    {"e=ya}",	""},
    {"y={",	"reduce_function_definition"},
  };

/* Number of grammar rules. */
#define n_grammar ((int) (sizeof grammar / sizeof *grammar))

/* A production compiled from the above specification. */
static struct production
  {
    int left;			/* Left-side nonterminal. */
    int n_right;		/* Number of grammar symbols on right side. */
    int *right;			/* Grammar symbols on right side. */

    const char *ascii;		/* grammar[i][0]: grammar rule as text. */
    const char *reduction;	/* grammar[i][1]: symbolic reduction name. */
  }
G[n_grammar];

/* All the grammar symbols used in the productions above, along with
   their corresponding symbolic names. */
static struct
  {
    int token;
    char *name;
  }
tokens[] = 
  {
    {'i', "lex_identifier"},
    {'1', "lex_typedef"},
    {'2', "lex_type_name"},
    {'3', "lex_struct"},
    {'4', "lex_const"},
    {'(', "lex_lparen"},
    {')', "lex_rparen"},
    {'[', "lex_lbrack"},
    {']', "lex_rbrack"},
    {'{', "lex_lbrace"},
    {'}', "lex_rbrace"},
    {',', "lex_comma"},
    {'*', "lex_pointer"},
    {';', "lex_semicolon"},
    {'o', "lex_other"},
    {'$', "lex_stop"},
  };

/* Number of tokens in tokens[]. */
#define n_tokens ((int) (sizeof tokens / sizeof *tokens))

/* Nonzero value turns on extra debugging output. */
static int debug = 0;

/* Memory allocation utilities. */

/* Allocates a block of AMT bytes and returns a pointer to the
   block. */
static void *
xmalloc (size_t amt)
{
  void *p;

  if (amt == 0)
    return NULL;
  p = malloc (amt);
  if (p == NULL)
    {
      fprintf (stderr, "virtual memory exhausted\n");
      exit (EXIT_FAILURE);
    }
  return p;
}

/* If SIZE is 0, then block PTR is freed and a null pointer is
   returned.
   Otherwise, if PTR is a null pointer, then a new block is allocated
   and returned.
   Otherwise, block PTR is reallocated to be SIZE bytes in size and
   the new location of the block is returned.
   Aborts if unsuccessful. */
static void *
xrealloc (void *ptr, size_t size)
{
  void *vp;
  if (!size)
    {
      if (ptr)
	free (ptr);

      return NULL;
    }

  if (ptr)
    vp = realloc (ptr, size);
  else
    vp = malloc (size);

  if (!vp)
    {
      fprintf (stderr, "virtual memory exhausted\n");
      exit (EXIT_FAILURE);
    }

  return vp;
}

/* Set abstract data type. */

/* A set of grammar symbols. */
struct set
  {
    int n;			/* Number of grammar symbols. */
    int *which;			/* Grammar symbols themselves. */
  };

/* Initializes SET to an empty set. */
static void
set_init (struct set *set)
{
  set->n = 0;
  set->which = NULL;
}

/* Free storage allocated for SET. */
static void
set_free (struct set *set)
{
  free (set->which);
}

/* Returns nonzero if C is in SET. */
static int
set_contains (const struct set *set, int c)
{
  int i;
  
  for (i = 0; i < set->n; i++)
    if (set->which[i] == c)
      return 1;
  return 0;
}

/* Attempts to add C to SET.  Returns 1 if successful, which
   will occur if and only if C was not already in SET.  Otherwise,
   returns 0. */
static int
set_add (struct set *set, int c)
{
  if (set_contains (set, c))
    return 0;

  set->which = xrealloc (set->which, sizeof *set->which * (set->n + 1));
  set->which[set->n++] = c;

  return 1;
}

/* Adds all the members of SRC into DST.  If NULL_ALSO is nonzero,
   then if the null (zero) grammar symbol is in SRC, it is added to
   DST.  If NULL_ALSO is zero, then the null grammar symbol will not
   be added to DST.  Returns the number of symbols actually added to
   DST. */
static int
set_merge (struct set *dst, const struct set *src, int null_also)
{
  int count;
  int i;

  count = 0;
  for (i = 0; i < src->n; i++)
    if (null_also || src->which[i] != 0)
      count += set_add (dst, src->which[i]);

  return count;
}

/* Prints all the members of SET, for debugging purposes. */
static void
set_print (const struct set *set)
{
  int i;
  
  for (i = 0; i < set->n; i++)
    if (set->which[i] != 0)
      putchar (set->which[i]);
    else
      putchar ('0');
}

/* Grammar symbol abstract data type. */

/* A grammar symbol and its properties. */
static struct symbol
  {
    int sym;			/* Character for this symbol. */
    int nonterminal;		/* Nonzero if this is a nonterminal. */
    int nt_index;		/* If nonterminal, then its relative index. */
    struct set first, follow;	/* FIRST and FOLLOW functions. */
  }
symbols[UCHAR_MAX];

/* Number of grammar symbols, number of nonterminals among those
   grammar symbols, and number of terminals among those grammar
   symbols. */
static int n_symbols;
static int n_nonterminals;	/* n_symbols = n_nonterminals + n_terminals */
static int n_terminals;

/* Returns the symbol structure corresponding to the symbol
   represented by character C. */
struct symbol *
find_symbol (int c)
{
  int i;

  for (i = 0; i < n_symbols; i++)
    if (c == symbols[i].sym)
      return &symbols[i];

  abort ();
}

/* Initializes symbols[] from grammar[]. */
static void
find_unique_symbols (void)
{
  unsigned char seen[UCHAR_MAX];
  size_t i;

  n_symbols = n_terminals = n_nonterminals = 0;

  memset (seen, 0, sizeof seen);
  for (i = 0; i < n_grammar; i++)
    {
      const char *p;
      seen[(unsigned char) grammar[i][0][0]] |= 2;
      for (p = grammar[i][0] + 2; *p; p++)
	seen[(unsigned char) *p] |= 1;
    }
  
  for (i = 0; i < UCHAR_MAX; i++)
    if (seen[i])
      {
	struct symbol *sym = &symbols[n_symbols];
	sym->sym = i;
	sym->nonterminal = (seen[i] & 2) != 0;
	sym->nt_index = sym->nonterminal ? n_nonterminals : -1;
	n_symbols++;
	n_nonterminals += sym->nonterminal;
	n_terminals += !sym->nonterminal;
      }
}

/* Item abstract data type. */

/* An item. */
struct item
  {
    int prod;		/* Index into G[]. */
    int dot;		/* Position of dot. */
  };

/* Returns the number of grammar symbols after the dot in ITEM. */
static int
item_n_after_dot (const struct item *item)
{
  assert (item != NULL && item->prod >= 0 && item->prod < (int) n_grammar);
  return G[item->prod].n_right - item->dot;
}

/* Returns the grammar symbol after the dot in ITEM. */
static int
item_symbol_after_dot (const struct item *item)
{
  assert (item_n_after_dot (item) >= 0);
  return G[item->prod].right[item->dot];
}

/* Print textual represenation ITEM on stdout, for debugging
   purposes. */
static void
item_print (const struct item *item)
{
  const struct production *prod;
  int i;
  
  assert (item != NULL && item->prod >= 0 && item->prod < (int) n_grammar);

  prod = &G[item->prod];
  printf ("%c=", prod->left);

  for (i = 0; i < prod->n_right; i++)
    {
      if (i == item->dot)
	putchar ('.');
      putchar (prod->right[i]);
    }
  if (i == item->dot)
    putchar ('.');
}

/* List of items abstract data type. */

/* A list of items. */
struct list
  {
    int n;
    int m;
    struct item *contents;
  };

/* Initialize LIST. */
static void
list_init (struct list *list)
{
  assert (list != NULL);
  list->n = list->m = 0;
  list->contents = NULL;
}

/* Free the contents of LIST. */
static void
list_free (struct list *list)
{
  free (list->contents);
}

/* Returns nonzero if LIST contains an item with production index PROD
   and dot at position DOT, that is, (PROD, DOT). */
static int
list_contains (struct list *list, int prod, int dot)
{
  int i;

  for (i = 0; i < list->n; i++)
    if (list->contents[i].prod == prod
	&& list->contents[i].dot == dot)
      return 1;

  return 0;
}
  
/* Tries to add the item (PROD, DOT) to LIST.  If the item is added,
   returns nonzero.  Otherwise, the item was already in LIST, and zero
   is returned. */
static int
list_add (struct list *list, int prod, int dot)
{
  assert (list != NULL);

  if (list_contains (list, prod, dot))
    return 0;

  if (list->n >= list->m)
    {
      if (list->m == 0)
	list->m = 16;
      else
	list->m *= 2;

      list->contents = xrealloc (list->contents,
				 sizeof *list->contents * list->m);
    }
  assert (list->n < list->m);

  list->contents[list->n].prod = prod;
  list->contents[list->n].dot = dot;
  list->n++;

  return 1;
}

/* Copies list SRC to DST.  DST should not have been initialized
   beforehand. */
static void
list_copy (struct list *dst, const struct list *src)
{
  int i;
  
  dst->n = src->n;
  dst->m = src->m;
  dst->contents = xmalloc (sizeof *dst->contents * dst->m);
  for (i = 0; i < src->n; i++)
    dst->contents[i] = src->contents[i];
}

/* Tests whether A and B contain the same items in the same order.
   Returns nonzero if so, zero otherwise. */
static int
list_equal (const struct list *a, const struct list *b)
{
  int i;
  
  if (a->n != b->n)
    return 0;

  for (i = 0; i < a->n; i++)
    if (a->contents[i].prod != b->contents[i].prod
	|| a->contents[i].dot != b->contents[i].dot)
      return 0;

  return 1;
}

/* Returns the number of items in LIST. */
static int
list_count (const struct list *list)
{
  assert (list != NULL);
  return list->n;
}

/* Returns the INDEX'th item in LIST. */
static const struct item *
list_item (const struct list *list, int index)
{
  assert (list != NULL && index >= 0 && index < list->n);
  return &list->contents[index];
}

/* Prints the contents of LIST on stdout, for debugging purposes. */
static void
list_print (const struct list *list)
{
  int i;

  for (i = 0; i < list->n; i++)
    {
      if (i != 0)
	printf (", ");
      item_print (&list->contents[i]);
    }
}

/* FIRST and FOLLOW functions. */

/* Calculate the value of FIRST for all grammar symbols.  Sets
   symbol[].first. */
static void
precalc_first (void)
{
  int i;

  for (i = 0; i < n_symbols; i++)
    {
      set_init (&symbols[i].first);

      if (symbols[i].nonterminal)
	{
	  size_t j;

	  for (j = 0; j < n_grammar; j++)
	    if (G[j].left == symbols[i].sym
		&& G[j].n_right == 0)
	      {
		set_add (&symbols[i].first, 0);
		break;
	      }
	}
      else
	set_add (&symbols[i].first, symbols[i].sym);
    }
  
  for (;;)
    {
      int added = 0;

      for (i = 0; i < n_grammar; i++)
	{
	  struct production *prod = &G[i];
	  struct symbol *X = find_symbol (prod->left);
	  int j;

	  for (j = 0; j < prod->n_right; j++)
	    {
	      struct symbol *Y;
	      int k;

	      Y = find_symbol (prod->right[j]);
	      for (k = 0; k < Y->first.n; k++)
		if (Y->first.which[k] != 0)
		  added |= set_add (&X->first, Y->first.which[k]);

	      if (!set_contains (&X->first, 0))
		break;
	    }
	  if (j >= prod->n_right)
	    added |= set_add (&X->first, 0);
	}

      if (!added)
	break;
    }

  if (debug)
    {
      printf ("FIRST function:\n");
      for (i = 0; i < n_symbols; i++)
	{
	  struct symbol *sym = &symbols[i];
	
	  printf ("\tFIRST(%c) = ", sym->sym);
	  set_print (&sym->first);
	  putchar ('\n');
	}
    }
}

/* Calculates the value of FIRST for the string of N grammar symbols
   at X.  Sets the result into SET. */
static void
calc_first (struct set *set, int *X, int n)
{
  int i;
  
  set_init (set);
  for (i = 0; i < n; i++)
    {
      const struct set *f = &find_symbol (X[i])->first;

      set_merge (set, f, 0);
      if (!set_contains (f, 0))
	return;
    }

  set_add (set, 0);
}

/* Calculates the value of FOLLOW for all nonterminals (and terminals
   while we're at it, but they're not useful).  Sets
   symbols[].follow. */
static void
precalc_follow (void)
{
  int i;

  for (i = 0; i < n_symbols; i++)
    set_init (&symbols[i].follow);

  set_add (&find_symbol (G[0].left)->follow, '$');

  for (;;)
    {
      int added = 0;
      
      for (i = 0; i < n_grammar; i++)
	{
	  const struct production *prod;
	  struct symbol *A;
	  int j;

	  prod = &G[i];
	  A = find_symbol (prod->left);
	  for (j = 0; j < prod->n_right - 1; j++)
	    {
	      struct symbol *B;
	      struct set first_Beta;

	      B = find_symbol (prod->right[j]);
	      calc_first (&first_Beta,
			  &prod->right[j + 1], prod->n_right - (j + 1));
	      added |= set_merge (&B->follow, &first_Beta, 0);

	      if (set_contains (&first_Beta, 0))
		added |= set_merge (&B->follow, &A->follow, 1);

	      set_free (&first_Beta);
	    }
	  
	  if (prod->n_right > 0)
	    {
	      struct symbol *B = find_symbol (prod->right[prod->n_right - 1]);
	      added |= set_merge (&B->follow, &A->follow, 1);
	    }
	}

      if (!added)
	break;
    }

  if (debug) 
    {
      printf ("FOLLOW function:\n");
      for (i = 0; i < n_symbols; i++)
	{
	  struct symbol *sym = &symbols[i];

	  if (!sym->nonterminal)
	    continue;
	  printf ("\tFOLLOW(%c) = ", sym->sym);
	  set_print (&sym->follow);
	  putchar ('\n');
	}
    }
}

/* Closure and goto functions. */

/* Calculates closure (I), storing the result into J.  I and J may
   specify the same list. */
static void
calc_closure (struct list *J, const struct list *I)
{
  int i;

  if (I != J)
    list_copy (J, I);
  for (i = 0; i < list_count (J); i++)
    {
      const struct item *item = list_item (J, i);
      if (item_n_after_dot (item) > 0)
	{
	  int t = item_symbol_after_dot (item);
	  if (find_symbol (t)->nonterminal)
	    {
	      size_t j;
	      
	      for (j = 0; j < n_grammar; j++)
		if (G[j].left == t)
		  list_add (J, j, 0);
	    }
	}
    }
}

/* Calculates goto (I, X), storing the result into J.  I and J may
   specify the same list. */
static void
calc_goto (struct list *J, struct list *I, int X)
{
  int i;

  if (I != J)
    list_init (J);
  for (i = 0; i < list_count (I); i++)
    {
      const struct item *item = list_item (I, i);
      if (item_n_after_dot (item) > 0
	  && item_symbol_after_dot (item) == X)
	list_add (J, item->prod, item->dot + 1);
    }
  calc_closure (J, J);
}

/* Canonical collection of sets. */

/* Canonical collection of sets. */
#define MAX_LOL_COUNT 256
static struct list C[MAX_LOL_COUNT];
static int nC;

/* Builds the canonical collection of sets into C[] and nC.  Prints
   the sets to stdout if debugging is enabled. */
static void
build_canonical_sets (void)
{
  int i;

  nC = 1;
  list_init (&C[0]);
  list_add (&C[0], 0, 0);
  calc_closure (&C[0], &C[0]);

  for (i = 0; i < nC; i++)
    {
      int X;

      for (X = 0; X < n_symbols; X++)
	{
	  struct list list;

	  calc_goto (&list, &C[i], symbols[X].sym);
	  if (list_count (&list))
	    {
	      int j;

	      for (j = 0; j < nC; j++)
		if (list_equal (&list, &C[j]))
		  break;
	      if (j >= nC)
		{
		  assert (nC < MAX_LOL_COUNT);
		  C[nC++] = list;
		}
	      else
		list_free (&list);
	    }
	  else
	    list_free (&list);
	}
    }

  if (debug)
    {
      printf ("Canonical collection of sets:\n");
      for (i = 0; i < nC; i++)
	{
	  printf ("\tI(%d) = ", i);
	  list_print (&C[i]);
	  putchar ('\n');
	}
    }
}

/* Writes a symbolic name for ACTION into BUF. */
static void
action_name (char buf[16], int action)
{
  if (action == 0)
    strcpy (buf, "0");
  else if (action == 1)
    strcpy (buf, "acc");
  else if (action >= 2 && action < 2 + nC)
    sprintf (buf, "s%d", action - 2);
  else 
    {
      int reduce = action - (2 + nC) + 1;
      
      assert (action >= 2 + nC && action < 2 + nC + n_grammar);
      sprintf (buf, "r%d", reduce);
    }
}

/* Prints a list of the form "ci, ci+1, ..., cj-1, cj" for c == C, i
   == FIRST, and j == LAST. */
static void
print_enum_list (int c, int first, int last)
{
  char string[80];
  int i;

  string[0] = 0;
  for (i = first; i <= last; i++)
    {
      if (strlen (string) > 65)
	{
	  printf ("    %s\n", string);
	  string[0] = 0;
	}

      sprintf (string + strlen (string), "%c%d, ", c, i);
    }

  if (strlen (string) > 0)
    {
      printf ("    %s\n", string);
      string[0] = 0;
    }
}

/* Sets the action in ACTIONS for state STATE and the input symbol
   with index INPUT to VALUE.  If a conflict occurs, prints an error
   message on stderr. */
static void
set_action (unsigned char **actions, int state, int input, int value)
{
  assert (actions != NULL);
  assert (state >= 0 && state < nC);
  assert (input >= 0 && input <= n_symbols);
  if (actions[state][input] != 0
      && actions[state][input] != value)
    {
      char a[16], b[16];

      action_name (a, value);
      action_name (b, actions[state][input]);
      fprintf (stderr, "Conflict for state %d, input %c: %s versus %s\n",
	       state, input < n_symbols ? symbols[input].sym : '$', a, b);
    }

  actions[state][input] = value;
}

/* Builds and outputs to stdout the action table for the parser,
   including enumerated types for actions and lexemes. */
static void
build_action_table (void)
{
  unsigned char **actions;
  int i;

  actions = xmalloc (sizeof *actions * nC);
  for (i = 0; i < nC; i++)
    {
      actions[i] = xmalloc (sizeof **actions * (n_symbols + 1));
      memset (actions[i], 0, sizeof **actions * (n_symbols + 1));
    }

  for (i = 0; i < nC; i++)
    {
      int j;

      for (j = 0; j < list_count (&C[i]); j++)
	{
	  const struct item *item = list_item (&C[i], j);
	  const struct production *prod = &G[item->prod];
	  const struct symbol *A = find_symbol (prod->left);
	  
	  if (item_n_after_dot (item) > 0)
	    {
	      struct symbol *a;

	      a = find_symbol (item_symbol_after_dot (item));
	      if (!a->nonterminal)
		{
		  struct list list;
		  int k;

		  calc_goto (&list, &C[i], a->sym);
		  
		  for (k = 0; k < nC; k++)
		    if (list_equal (&list, &C[k]))
		      set_action (actions, i, a - symbols, 2 + k);

		  list_free (&list);
		}
	    }
	  else if (A->sym != G[0].left)
	    {
	      const struct set *follow_A = &A->follow;
	      int k;

	      for (k = 0; k < follow_A->n; k++)
		{
		  int c;
		  int index;

		  c = follow_A->which[k];
		  if (c == '$')
		    index = n_symbols;
		  else
		    index = find_symbol (c) - symbols;
		  
		  set_action (actions, i, index, 2 + nC + (prod - G));
		}
	    }

	  if (list_contains (&C[i], 0, 1))
	    set_action (actions, i, n_symbols, 1);
	}
    }

  fputs ("/* Actions used in action_table[][] entries. */\n"
	 "enum\n"
	 "  {\n"
	 "    err,\t/* Error. */\n"
	 "    acc,\t/* Accept. */\n"
	 "\n"
	 "    /* Shift actions. */\n", stdout);

  print_enum_list ('s', 0, nC - 1);

  fputs ("\n"
	 "    /* Reduce actions. */\n", stdout);
  print_enum_list ('r', 1, n_grammar);

  printf ("\n"
	  "    n_states = %d,\n"
	  "    n_terminals = %d,\n"
	  "    n_nonterminals = %d,\n"
	  "    n_reductions = %d\n"
	  "  };\n"
	  "\n"
	  "/* Symbolic token names used in parse_table[][] second index. */\n"
	  "enum\n"
	  "  {\n",
	  nC, n_terminals + 1, n_nonterminals, n_grammar);
  
  for (i = 0; i < n_symbols; i++)
    {
      struct symbol *sym = &symbols[i];
      int j;

      if (sym->nonterminal)
	continue;

      for (j = 0; j < n_tokens; j++)
	if (tokens[j].token == sym->sym)
	  break;
      assert (j < n_tokens);
      
      printf ("    %s,%*c/* %c */\n",
	      tokens[j].name, 25 - (int) strlen (tokens[j].name), ' ',
	      sym->sym);
    }

  fputs ("    lex_stop                  /* $ */\n"
	 "  };\n"
	 "\n"
	 "/* Action table.  This is action[][] from Fig. 4.30, \"LR parsing\n"
	 "   program\", in Aho, Sethi, and Ullman. */\n"
	 "static const unsigned char action_table[n_states][n_terminals] =\n"
	 "  {\n"
	 "    /*        ", stdout);
  for (i = 0; i < n_symbols; i++)
    if (!symbols[i].nonterminal)
      printf ("  %c ", symbols[i].sym);
  fputs ("  $ */\n", stdout);
  for (i = 0; i < nC; i++)
    {
      int j;
      
      printf ("    /*%3d */ {", i);
      for (j = 0; j <= n_symbols; j++)
	if (j == n_symbols || !symbols[j].nonterminal)
	  {
	    char buf[16];
	    if (j != 0)
	      putchar (',');

	    action_name (buf, actions[i][j]);
	    printf ("%3s", buf);
	  }
      fputs ("},\n", stdout);
    }
  fputs ("  };\n\n", stdout);
      
  for (i = 0; i < nC; i++)
    free (actions[i]);
  free (actions);
}

/* Builds and prints to stdout the goto table for this parser. */
static void
build_goto_table (void)
{
  unsigned char **gotos;
  int i;

  gotos = xmalloc (sizeof *gotos * nC);
  for (i = 0; i < nC; i++)
    {
      gotos[i] = xmalloc (sizeof **gotos * n_nonterminals);
      memset (gotos[i], 0, sizeof **gotos * n_nonterminals);
    }

  for (i = 0; i < nC; i++)
    {
      int j;

      for (j = 0; j < n_symbols; j++)
	{
	  struct symbol *A;
	  struct list list;

	  A = &symbols[j];
	  if (A->nonterminal)
	    {
	      int k;

	      calc_goto (&list, &C[i], A->sym);
		  
	      for (k = 0; k < nC; k++)
		if (list_equal (&list, &C[k]))
		  {
		    gotos[i][A->nt_index] = k;
		    break;
		  }

	      list_free (&list);
	    }
	}
    }

  fputs ("/* Go to table.  This is goto[][] from Fig. 4.30, \"LR parsing\n"
	 "   program\", in Aho, Sethi, and Ullman. */\n"
	 "static const unsigned char goto_table[n_states][n_nonterminals] =\n"
	 "  {\n"
	 "    /*        ", stdout);
  for (i = 0; i < n_symbols; i++)
    if (symbols[i].nonterminal)
      printf (" %c ", symbols[i].sym);
  fputs ("*/\n", stdout);
  for (i = 0; i < nC; i++)
    {
      int j;
      
      printf ("    /*%3d */ {", i);
      for (j = 0; j < n_symbols; j++)
	{
	  struct symbol *sym = &symbols[j];
	  
	  if (sym->nonterminal)
	    {
	      if (sym->nt_index != 0)
		putchar (',');
	      
	      printf ("%2d", gotos[i][sym->nt_index]);
	    }
	}
  
      fputs ("},\n", stdout);
    }
  fputs ("  };\n\n", stdout);

  for (i = 0; i < nC; i++)
    free (gotos[i]);
  free (gotos);
}

/* Compares the strings pointed to by the pointers at PA and PB and
   returns a strcmp()-type result. */
static int
compare_strings (const void *pa, const void *pb)
{
  const char *a = *((char **) pa);
  const char *b = *((char **) pb);

  return strcmp (a, b);
}

/* Prints a table of reduction rule information, including an
   enumerated type giving symbolic names to reductions. */
static void
print_reduce_table (void)
{
  int i;

  fputs ("/* Reduction rule symbolic names (reduce_table[][2]). */\n"
	 "enum\n"
	 "  {\n"
	 "    reduce_null", stdout);
  
  {
    const char **reductions;
    int count;

    count = 0;
    reductions = xmalloc (sizeof *reductions * n_grammar);
    for (i = 0; i < n_grammar; i++)
      if (*G[i].reduction)
	reductions[count++] = G[i].reduction;

    qsort (reductions, count, sizeof *reductions, compare_strings);

    for (i = 0; i < count; i++)
      {
	if (i > 0 && reductions[i - 1] == reductions[i])
	  continue;

	printf (",\n    %s", reductions[i]);
      }

    free (reductions);
  }

  fputs ("\n"
	 "  };\n"
	 "\n"
	 "/* Reduction table.  First index is reduction number, from\n"
	 "   parse_table[][] above.  Second index is as follows:\n\n"
	 "   reduce_table[r][0]: Number of grammar symbols on right side of\n"
	 "   production.\n\n"
	 "   reduce_table[r][1]: Second index into goto[][] array, "
	 "corresponding\n"
	 "   to the left side of the production.\n\n"
	 "   reduce_table[r][2]: User-specified symbolic name for this\n"
	 "   production. */\n"
	 "static const unsigned char reduce_table[n_reductions][3] = \n"
	 "  {\n",
	 stdout);

  for (i = 0; i < n_grammar; i++)
    {
      struct production *prod = &G[i];
      
      printf ("    {%3d,%3d, %-30s}, /* %s */\n",
	      prod->n_right, find_symbol (prod->left)->nt_index,
	      *prod->reduction ? prod->reduction : "reduce_null",
	      prod->ascii);
    }

  fputs ("  };\n\n", stdout);
}

/* Startup code. */

/* Handle command line arguments. */
static void
parse_command_line (int argc, char **argv)
{
  /* Usage message. */
  static const char help[] = 
    "slr, a program to generate an SLR parser for texiweave\n"
    "\nUsage: %s [OPTION]...\n"
    "  -d, --debug           turn on debugging\n"
    "  -h, --help            print this help, then exit\n"
    "  -v, --version         show version, then exit\n";

  /* Version message. */
  static const char version[] =
    "slr version 1.0\n"
    "\nCopyright (C) 2002, 2004 Free Software Foundation, Inc.\n"
    "This is free software; see the source for copying conditions.  "
    "There is NO\n"
    "WARRANTY; not even for MERCHANTABILITY or FITNESS FOR A "
    "PARTICULAR PURPOSE.\n\n";
  
  const char *short_pgm_name = strrchr (argv[0], '/');
  if (short_pgm_name != NULL)
    short_pgm_name++;
  else
    short_pgm_name = argv[0];

  if (argc == 0)
    return;

  for (;;)
    {
      argc--;
      argv++;
      if (argc == 0)
	return;

      if (!strcmp (*argv, "-d") || !strcmp (*argv, "--debug"))
	debug = 1;
      else if (!strcmp (*argv, "-h") || !strcmp (*argv, "--help"))
	{
	  printf (help, short_pgm_name);
	  exit (EXIT_SUCCESS);
	}
      else if (!strcmp (*argv, "-v") || !strcmp (*argv, "--version"))
	{
	  fputs (version, stdout);
	  exit (EXIT_SUCCESS);
	}
      else
	{
	  printf (help, short_pgm_name);
	  exit (EXIT_FAILURE);
	}
    }
}

/* Initialize G[] from grammar[]. */
static void
initialize_G (void)
{
  size_t i;

  for (i = 0; i < n_grammar; i++)
    {
      int j;

      G[i].left = (unsigned char) grammar[i][0][0];
      G[i].n_right = strlen (grammar[i][0] + 2);
      G[i].right = xmalloc (sizeof *G[i].right * G[i].n_right);
      for (j = 0; j < G[i].n_right; j++)
	G[i].right[j] = (unsigned char) grammar[i][0][j + 2];
      G[i].ascii = grammar[i][0];
      G[i].reduction = grammar[i][1];
    }
}

int
main (int argc, char **argv)
{
  parse_command_line (argc, argv);
  find_unique_symbols ();
  initialize_G ();
  build_canonical_sets ();
  precalc_first ();
  precalc_follow ();
  build_action_table ();
  build_goto_table ();
  print_reduce_table ();

  return 0;
}

/*
  Local Variables:
  compile-command: "gcc -W -Wall -ansi -pedantic slr.c -o slr"
  End:
*/
