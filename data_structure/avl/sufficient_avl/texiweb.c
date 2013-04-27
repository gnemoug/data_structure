/* texiweb - translates TexiWEB into Texinfo and C
   Copyright (C) 2002, 2004 Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 3 of the
   License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to: Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 
   02110-1301 USA. */

/* TODO:

   - Index names of structure members.

   - When a code fragment requires headers, we should be able to
     indicate it.  Some kind of "dependencies" kind of mechanism would
     be nice.

   - Generate Makefile fragments for include files, images, and source
     files.

   - @example's and similar should not be processed; e.g., there are
     problems if | is in an example.

   - Parenthesis nesting doesn't work quite right:
       x[1] = func (y,
         z);
     Dammit.

*/

#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Recent GNU C versions support declaring certain function
   attributes.  Allow less cool compilers to ignore these
   attributes. */
#ifdef __GNUC__
#define ATTRIBUTE(X) __attribute__ (X)
#else
#define ATTRIBUTE(X)
#endif
#define NO_RETURN ATTRIBUTE ((noreturn))
#define PRINTF_FORMAT(FMT, START) ATTRIBUTE ((format (printf, FMT, START)))

/* This program is not really i18n'd, but it thinks that it is. */
#define gettext(STRING) STRING
#define _(STRING) STRING
#define N_(STRING) STRING

/* Short name of this program. */
static char *short_pgm_name;

/* tangle, weave: What this program is supposed to do this run. */
enum operation
  {
    OP_NONE,		/* No operation yet specified. */
    OP_WEAVE,		/* Weave TexiWEB into Texinfo. */
    OP_TANGLE		/* Tangle TexiWEB into C. */
  }
operation;

/* -l, --line: Emit #line directives for tangle? */
int opt_line;

/* -f, --filenames: Only print list of .c files included in .w? */
int filenames_only;

/* -s, --segments: Print all segments to directory `out_file_name'. */
int print_all_segments;

/* -u, --unused: Print list of unused sections? */
int print_unused;

/* -c, --catalogues: Print list of unused catalogues? */
int print_catalogues;

/* -a, --unanswered: Print list of unanswered exercises? */
int print_unanswered;

/* -n, --nonzero-indent: Warn at nonzero indent adjust between blocks? */
int warn_nonzero_indent;

/* Input and output. */

struct input_file
  {
    struct input_file *outer;
    char *name;
    FILE *file;
    int line;
  };

/* Input and output files. */
static char *in_file_name, *out_file_name;
static char *answer_file_name, *header_file_name;
static FILE *out_file, *answer_file, *header_file;
static struct input_file *in_file;

/* Prototypes. */

static void emitf (const char *format, ...) PRINTF_FORMAT (1, 2);

static void input_start_pass (void);
static int input_read_line (char **line, size_t *line_size);

struct symbol;
static struct symbol *symbol_find (const char *name, size_t len, int add);
static void symbol_init (void);

/* State types. */
enum state
  {
    TEXT,		/* Text. */
    CODE,		/* Code. */
    COMMENT,		/* Text within a comment. */
    CONTROL		/* Control text within code or text. */
  };

/* Texinfo styles used for various C lexical elements. */
#define STRUCT_TAG_STYLE	"@b"	/* struct, union, and enum tags. */
#define TYPEDEF_STYLE		"@b"	/* typedef names. */

/* Number of spaces added to current line indentation. */
static int indent_adjust;

/* Sectioning levels. */
enum section_level
  {
    LEVEL_CHAPTER,
    LEVEL_SECTION,
    LEVEL_SUBSECTION,
    LEVEL_SUBSUBSECTION,
    LEVEL_EXERCISE,

    LEVEL_CNT
  };

/* A section. */
struct section
  {
    short level[LEVEL_CNT];
  };

/* The section we're reading. */
struct section cur_section;

/* Maximum length of a Texinfo command name. */
#define CMD_LEN_MAX 31

static void state_init (void);
static int state_cnt (void);
static int state_is (enum state);
static int state_was (enum state);
static void state_push (enum state);
static void state_pop (void);

struct segment;
static struct segment *segment_find (const char *name, int create);
static void segment_select (struct segment *segment);
static int segment_selected_p (void);
static int segment_piece_cnt (void);
static int segment_number (void);
static int segment_first_piece (void);
static int segment_inside_indentation (struct segment *segment);
static void segment_next_piece (void);
static void segment_print_number (struct segment *segment);
static void segment_add_line (const char *line);
static char *segment_make_filename (const struct segment *);

static void piece_create (struct segment *s, int operation);
static void piece_references (struct segment *reference, int indentation);
static void piece_print_trailer (void);

static void print_filename (const char *);
static struct symbol *print_identifier (const char *text, int len);
static void print_piece_header (const char *segment_name, int type,
				int operation);
static void open_header_file (char *line);
static void close_header_file (void);

static void exercise_begin (char *line, int pass);
static int exercise_end (const char *cmd, char *line, int pass);
static void exercise_answer (char *line, int pass);
static void exercise_close_answer_file (void);
static void exercise_open_answer_file (char *line, int pass);
static int exercise_process (const char *cmd, char *line, int pass);
static void exercise_anchor (struct section *section, char name[64]);
static void exercise_emit_answer_menu (void);
static void exercise_menu_add_node (const char *node_name);

static int parse_at_cmd (const char *line, char cmd[CMD_LEN_MAX + 1]);

static void add_control (const char *text, size_t len);
static char *parse_control_text (char *start, char **tail);

struct token;
static const char *token_get (const char *s, struct token *token);
static const char *token_parse (const char *cp, struct token *token);
static int token_space_p (struct token *token);

static void weave_pass_one (void);
static char *segment_definition_line (char *line,
                                      int *operation, int *is_file);
static void enforce_references_ordering (void);

static void weave_pass_two (void);
static void transition (enum state);
static int indent_amount (const char *cp, const char **const end);
static int print_line (const char *cp, int flags);
static int print (const char *cp, int flags);
static void flush_blank_lines ();

static void tangle (void);

struct engine_state;
static void init_engine_state (struct engine_state *s);
static int lr_engine (struct engine_state *engine, struct token *token);
static void declaration_engine (const char *cp, int indentation);

static void parse_cmd_line (int argc, char **argv);
static void usage (int exit_code) NO_RETURN;

/* Error flags. */
enum
  {
    SRC = 001,		/* Print source file name and line number. */
    FTL = 002		/* Fatal error. */
  };

static void error (int flags, const char *message, ...) PRINTF_FORMAT (2, 3);

static void *xmalloc (size_t amt);
static void *xrealloc (void *ptr, size_t size);
static char *xstrndup (const char *buf, size_t len);
static char *xstrdup (const char *string);

static int empty_string (const char *string);
static void trim_whitespace (char **bp, char **ep);
static int find_argument (char *line, char **bp, char **ep);
static int find_optional_argument (char *line, char **bp, char **ep);
#if 0
static void copy_argument (char *line);
#endif

/* Main program. */

int
main (int argc, char **argv)
{
  parse_cmd_line (argc, argv);
  symbol_init ();

  switch (operation)
    {
    case OP_WEAVE:
      weave_pass_one ();
      weave_pass_two ();
      break;

    case OP_TANGLE:
      tangle ();
      break;

    default:
      assert (0);
    }

  return EXIT_SUCCESS;
}

/* Input directives @iftangle and @ifweave. */

/* Maximum number of nested input directives. */
#define DIR_MAX 16

/* Represents an @iftangle or @ifweave directive. */
static struct dir_directive
  {
    enum operation include;		/* OP_TANGLE or OP_WEAVE. */
    char *name;				/* File where directive appeared. */
    int line;				/* Line number of directive. */
  }
dir_stack[DIR_MAX];

/* Active input directives. */
static int dir_stack_height;

/* Number of active directives causing input to be ignored. */
static int dir_ignore;

/* Pushes (INCLUDE, in_file->name, in_file->line) onto the directive
   stack. */
static void
dir_push (enum operation include)
{
  if (dir_stack_height >= DIR_MAX)
    error (SRC | FTL, _("Input directives nested too deeply."));

  dir_stack[dir_stack_height].include = include;
  dir_stack[dir_stack_height].name = in_file->name;
  dir_stack[dir_stack_height].line = in_file->line;
  dir_stack_height++;

  if (include != operation)
    dir_ignore++;
}

/* Pops a directive of type INCLUDE from the directive stack. */
static void
dir_pop (enum operation include)
{
  if (dir_stack_height <= 0)
    {
      error (SRC, _("`@end' pairs with nonexistent input directive."));
      return;
    }
  dir_stack_height--;

  if (strcmp (dir_stack[dir_stack_height].name, in_file->name))
    {
      error (SRC, _("`@end' not in same file as corresponding `@if'."));
      fprintf (stderr, _("%s:%d: Here is the corresponding `@if'.\n"),
	       dir_stack[dir_stack_height].name,
	       dir_stack[dir_stack_height].line);
    }
  else if (dir_stack[dir_stack_height].include != include)
    {
      error (SRC, _("`@end' does not match corresponding `@if'."));
      fprintf (stderr, _("%s:%d: Here is the corresponding `@if'.\n"),
	       dir_stack[dir_stack_height].name,
	       dir_stack[dir_stack_height].line);
    }

  if (dir_stack[dir_stack_height].include != operation)
    dir_ignore--;
}

/* Parses @ifweave, @iftangle, and corresponding @end directives.
   Returns nonzero only if such a directive was actually processed. */
static int
dir_parse_ifx (char *line)
{
  char cmd[CMD_LEN_MAX + 1];

  if (!parse_at_cmd (line, cmd))
    return 0;

  if (!strcmp (cmd, "ifweave"))
    dir_push (OP_WEAVE);
  else if (!strcmp (cmd, "iftangle"))
    dir_push (OP_TANGLE);
  else if (!strcmp (cmd, "end"))
    {
      char *bp, *ep;

      if (!find_argument (line, &bp, &ep))
	return 0;

      if ((size_t) (ep - bp) == strlen ("ifweave")
	  && !memcmp (bp, "ifweave", strlen ("ifweave")))
	dir_pop (OP_WEAVE);
      else if ((size_t) (ep - bp) == strlen ("iftangle")
	       && !memcmp (bp, "iftangle", strlen ("iftangle")))
	dir_pop (OP_TANGLE);
      else
	return 0;
    }
  else
    return 0;

  return 1;
}

/* Checks that all opened @if directives were closed properly
   with @end's. */
static void
dir_close (void)
{
  while (dir_stack_height > 0)
    {
      dir_stack_height--;
      fprintf (stderr, _("%s:%d: `@if' opened here but never closed.\n"),
	       dir_stack[dir_stack_height].name,
	       dir_stack[dir_stack_height].line);
    }
  dir_ignore = 0;
}

/* Input and output. */

/* Writes STRING to output file. */
#define emits(STRING) \
	(fputs ((STRING), out_file), (void) 0)

/* Writes CHARACTER to output file. */
#define emitc(CHARACTER) \
	(putc ((CHARACTER), out_file), (void) 0)

/* Writes LEN characters from BUF to output file. */
#define emitb(BUF, LEN) \
	(fwrite ((BUF), (LEN), 1, out_file), (void) 0)

/* Formats FORMAT and succeeding varargs as with printf() and writes
   the result to the output file. */
static void
emitf (const char *format, ...)
{
  va_list args;

  assert (out_file != NULL && format != NULL);

  va_start (args, format);
  vfprintf (out_file, format, args);
  va_end (args);
}

/* Opens an input file named NAME and pushes it onto the in_file
   stack. */
static void
input_push (const char *filename)
{
  struct input_file *f = xmalloc (sizeof *f);
  f->outer = in_file;
  f->name = xstrdup (filename);
  f->file = fopen (filename, "r");
  if (f->file == NULL)
    error (FTL, _("Opening %s for reading: %s"), filename, strerror (errno));
  f->line = 0;
  in_file = f;
}

/* Closes the file on top of the in_file stack and pops it off. */
static void
input_pop (void)
{
  struct input_file *outer;

  /* Note that we don't free f->name because it might be referenced
     elsewhere, resulting in a small memory leak. */

  assert (in_file != NULL);
  if (fclose (in_file->file) != 0)
    error (FTL, _("Closing %s: %s"), in_file->name, strerror (errno));

  outer = in_file->outer;
  free (in_file);
  in_file = outer;
}

/* Starts an input pass by opening or rewinding `in_file'. */
static void
input_start_pass (void)
{
  input_push (in_file_name);
}

/* Ends an input pass by checking internal state. */
static void
input_end_pass (void)
{
  dir_close ();
}

/* Reads a newline-separated field of any length from file STREAM.
   *LINEPTR is a malloc'd string of size N; if *LINEPTR is NULL, it is
   allocated.  *LINEPTR is allocated/enlarged as necessary.  Returns
   -1 if at eof when entered; otherwise eof causes return of string
   without a terminating newline.  Normally '\n' is the last character
   in *LINEPTR on return (besides the null character which is always
   present).  Returns number of characters read, including the newline
   if present. */
/* Taken from GNU PSPP. */
static int
input_get_line (char **lineptr, size_t *n, FILE *stream)
{
  /* Number of characters stored in *LINEPTR so far. */
  size_t len;

  /* Last character read. */
  int c;

  if (*lineptr == NULL || *n < 2)
    {
      *lineptr = xrealloc (*lineptr, 128);
      *n = 128;
    }
  assert (*n > 0);

  len = 0;
  c = getc (stream);
  if (c == EOF)
    return -1;
  for (;;)
    {
      if (len + 1 >= *n)
	{
	  *n *= 2;
	  *lineptr = xrealloc (*lineptr, *n);
	}
      (*lineptr)[len++] = c;
      if (c == '\n')
	break;

      c = getc (stream);
      if (c == EOF)
	break;
    }
  (*lineptr)[len] = '\0';
  return len;
}

/* Parses and executes a TexiWEB @include command. */
static int
input_parse_include (char *line)
{
  static const char include[] = "@include";
  char *bp, *ep;

  if (strncmp (line, include, strlen (include))
      || !isspace ((unsigned char) line[strlen (include)]))
    return 0;

  find_argument (line, &bp, &ep);
  *ep = '\0';

  if (answer_file_name != NULL && !strcmp (bp, answer_file_name))
    {
      if (operation == OP_TANGLE)
        return 1;
      exercise_close_answer_file (); 
    }
  if (header_file_name == NULL || strcmp (bp, header_file_name)) 
    {
      input_push (bp);
      return 1; 
    }
  else return 0;
}

/* Reads a line from the input file.  If a line is successfully read,
   returns nonzero.  If end of file is encountered, returns zero. */
static int
input_read_line (char **line, size_t *line_size)
{
  while (in_file != NULL)
    {
      int line_len = input_get_line (line, line_size, in_file->file);
      in_file->line++;

      if (line_len != -1)
	{
	  if (dir_parse_ifx (*line) || dir_ignore)
	    continue;

	  if (input_parse_include (*line))
	    continue;

	  return 1;
	}

      if (ferror (in_file->file))
	error (FTL, _("Error reading %s: %s"),
	       in_file->name, strerror (errno));

      input_pop ();
    }

  return 0;
}

/* Symbol table. */

/* All the keywords in C99. */
enum
  {
    KW_AUTO, KW_BREAK, KW_CASE, KW_CHAR, KW_COMPLEX, KW_CONST,
    KW_CONTINUE, KW_DEFAULT, KW_DEFINED, KW_DO, KW_DOUBLE, KW_ELSE, KW_ENUM,
    KW_EXTERN, KW_FLOAT, KW_FOR, KW_GOTO, KW_IF, KW_IMAGINARY,
    KW_INLINE, KW_INT, KW_LONG, KW_REGISTER, KW_RESTRICT,
    KW_RETURN, KW_SHORT, KW_SIGNED, KW_SIZEOF, KW_STATIC, KW_STRUCT,
    KW_SWITCH, KW_TYPEDEF, KW_UNION, KW_UNSIGNED, KW_VOID,
    KW_VOLATILE, KW_WHILE,

    /* User-specified additional "keywords". */
    KW_OTHER,

    /* Number of keywords. */
    KW_CNT
  };

/* Symbol table entry. */
struct symbol
  {
    struct symbol *next;	/* Chains to next symbol in list. */
    char *name;			/* This symbol's name. */

    struct segment *segment;	/* Segment with this name. */
    int is_typedef;		/* Is there a typedef with this name? */
    int kw_idx;			/* One of KW_* or -1 if not a keyword. */
    struct catalogue *catalogue; /* Associated catalogue. */
  };

/* Traditional logic says to use a prime, but a decent hash function
   should have enough randomness to just use the bottom 10 bits. */
#define SYMBOL_TABLE_SIZE 1024

/* Symbol table, implemented as a hash table with collisions resolved
   by chaining. */
static struct symbol *symbol_table[SYMBOL_TABLE_SIZE];

/* Attempts to find a symbol NAME, which has length LEN, in the symbol
   table.  If found, the symbol table entry is returned.  Otherwise,
   behavior depends on ADD: if nonzero, a new entry is created and
   returned; if zero, returns a null pointer. */
static struct symbol *
symbol_find (const char *name, size_t len, int add)
{
  unsigned hash;

  /* Compute the hash function from Perl. */
  {
    const char *p;

    hash = 0;
    for (p = name; p < name + len; p++)
      hash = hash * 33 + (unsigned char) *p;
    hash %= SYMBOL_TABLE_SIZE;
  }

  /* Search for the symbol in the appropriate list. */
  {
    struct symbol **sym;

    for (sym = symbol_table + hash; *sym; sym = &(*sym)->next)
      if (strlen ((*sym)->name) == len
	  && !memcmp (name, (*sym)->name, len))
	return *sym;

    if (add == 0)
      return NULL;

    *sym = xmalloc (sizeof **sym);
    (*sym)->next = NULL;
    (*sym)->name = xstrndup (name, len);
    (*sym)->segment = NULL;
    (*sym)->is_typedef = 0;
    (*sym)->kw_idx = -1;
    (*sym)->catalogue = NULL;
    return *sym;
  }
}

/* Calls FUNC() for each symbol in the symbol table. */
static void
symbol_foreach (void (*func) (struct symbol *))
{
  int i;

  for (i = 0; i < SYMBOL_TABLE_SIZE; i++)
    {
      struct symbol *sym;

      for (sym = symbol_table[i]; sym != NULL; sym = sym->next)
	func (sym);
    }
}

/* Initializes the symbol table by inserting the standard C99
   keywords and types. */
static void
symbol_init (void)
{
  static const char *keywords[KW_CNT - 1] =
    {
      "auto", "break", "case", "char", "complex", "const",
      "continue", "default", "defined", "do", "double", "else", "enum",
      "extern", "float", "for", "goto", "if", "imaginary",
      "inline", "int", "long", "register", "restrict",
      "return", "short", "signed", "sizeof", "static", "struct",
      "switch", "typedef", "union", "unsigned", "void",
      "volatile", "while",
    };

  static const char *types[] =
    {
      /* fenv.h */
      "fenv_t", "fexcept_t",

      /* math.h */
      "float_t", "double_t",

      /* setjmp.h */
      "jmp_buf",

      /* signal.h */
      "sig_atomic_t",

      /* stdarg.h */
      "va_list",

      /* stdbool.h */
      "bool",

      /* stddef.h */
      "ptrdiff_t", "size_t", "wchar_t",

      /* stdint.h */
      "int8_t", "int16_t", "int32_t", "int64_t",
      "uint8_t", "uint16_t", "uint32_t", "uint64_t",
      "int_least8_t", "int_least16_t", "int_least32_t", "int_least64_t",
      "uint_least8_t", "uint_least16_t", "uint_least32_t", "uint_least64_t",
      "int_fast8_t", "int_fast16_t", "int_fast32_t", "int_fast64_t",
      "uint_fast8_t", "uint_fast16_t", "uint_fast32_t", "uint_fast64_t",
      "intptr_t", "uintptr_t", "intmax_t", "uintmax_t",

      /* stdio.h */
      "fpos_t", "FILE",

      /* stdlib.h */
      "div_t", "ldiv_t", "lldiv_t",

      /* time.h */
      "clock_t", "time_t",

      /* wchar.h */
      "mbstate_t", "wint_t",

      /* wctype.h */
      "wctrans_t", "wctype_t",
    };

  size_t i;

  for (i = 0; i < sizeof keywords / sizeof *keywords; i++)
    symbol_find (keywords[i], strlen (keywords[i]), 1)->kw_idx = i;

  for (i = 0; i < sizeof types / sizeof *types; i++)
    symbol_find (types[i], strlen (types[i]), 1)->is_typedef = 1;
}

/* Catalogues.

   A catalogue is mostly like an index.  The big difference is the
   presentation, which is customizable. */

/* A catalogue entry. */
struct cat_entry
  {
    int idx;			/* Index number for anchor. */
    char *label;		/* Label. */
  };

/* A catalogue. */
struct catalogue
  {
    /* Pass one. */
    int entry_cnt;		/* Number of entries. */
    int entry_cap;		/* Entry capacity. */
    struct cat_entry *entry;	/* Entries. */

    /* Pass two. */
    int idx;			/* Current index number. */
    int printed;		/* 1=Used as @printcatalogue argument. */
  };

/* Handles cataloguing commands during pass one.
   Takes CMD, the @-command on the current line, and LINE, the
   full text of the current line, and returns nonzero if the current
   line should be skipped without further processing by the caller
   (because it was parsed and executed here). */
static int
catalogue_process_one (char *cmd, char *line)
{
  char *bp, *ep;
  struct symbol *symbol;
  struct catalogue *cat;
  struct cat_entry *entry;

  if (!strcmp (cmd, "printcatalogue"))
    return 1;
  if (strcmp (cmd, "cat"))
    return 0;

  if (!find_argument (line, &bp, &ep))
    return 0;

  symbol = symbol_find (bp, strcspn (bp, " \t\r\n"), 1);
  if (symbol->catalogue != NULL)
    cat = symbol->catalogue;
  else
    {
      cat = symbol->catalogue = xmalloc (sizeof *cat);
      cat->entry_cnt = cat->entry_cap = 0;
      cat->entry = NULL;
      cat->idx = 0;
      cat->printed = 0;
    }

  if (cat->entry_cnt >= cat->entry_cap)
    {
      cat->entry_cap = cat->entry_cap * 3 / 2 + 8;
      cat->entry = xrealloc (cat->entry, sizeof *cat->entry * cat->entry_cap);
    }
  assert (cat->entry_cnt < cat->entry_cap);

  if (!find_argument (bp, &bp, &ep))
    return 0;

  entry = &cat->entry[cat->entry_cnt];
  entry->idx = cat->entry_cnt;
  entry->label = xstrndup (bp, ep - bp);
  cat->entry_cnt++;

  return 1;
}

/* Compares the `struct cat_entry's to which PA and PB point.  Returns
   a strcmp()-type result. */
static int
catalogue_compare_entries (const void *pa, const void *pb)
{
  const struct cat_entry *a = pa;
  const struct cat_entry *b = pb;
  const char *sa = a->label;
  const char *sb = b->label;

  for (;;)
    {
      char ca = tolower ((unsigned char) *sa++);
      char cb = tolower ((unsigned char) *sb++);

      if (ca != cb)
	return ca > cb ? 1 : -1;
      else if (ca == 0)
	return 0;
    }
}

/* Prints catalogue CAT named NAME to the the Texinfo output
   stream. */
static void
catalogue_print (const char *name, struct catalogue *cat)
{
  int i;

  cat->printed = 1;
  qsort (cat->entry, cat->entry_cnt, sizeof *cat->entry,
	 catalogue_compare_entries);

  emits ("@iftex\n");
  for (i = 0; i < cat->entry_cnt; i++)
    emitf ("@catentry{catalogue-entry-%s-%d}{%s}\n",
	   name, cat->entry[i].idx, cat->entry[i].label);
  emits ("@end iftex\n");

  emits ("@ifnottex\n");
  for (i = 0; i < cat->entry_cnt; i++)
    {
      const char *p;

      emitf ("@catentry{catalogue-entry-%s-%d, ", name, cat->entry[i].idx);

      for (p = cat->entry[i].label; *p != '\0'; p++)
	{
	  if (*p == ',')
	    emitc ('\\');
	  emitc (*p);
	}

      emits ("}\n");
    }
  emits ("@end ifnottex\n");
}

/* Handles cataloguing commands during pass two.
   Takes CMD, the @-command on the current line, and LINE, the
   full text of the current line, and returns nonzero if the current
   line should be skipped without further processing by the caller
   (because it was parsed and executed here). */
static int
catalogue_process_two (char *cmd, char *line)
{
  char *bp, *ep;
  struct symbol *symbol;

  if (strcmp (cmd, "printcatalogue") && strcmp (cmd, "cat"))
    return 0;

  if (!find_argument (line, &bp, &ep))
    return 0;
  ep = bp + strcspn (bp, " \t\r\n");

  symbol = symbol_find (bp, ep - bp, 0);
  if (!strcmp (cmd, "cat"))
    {
      if (symbol == NULL || symbol->catalogue == NULL)
	{
	  error (SRC, _("Internal error: no such catalogue `%.*s'."),
		 (int) (ep - bp), bp);
	  return 1;
	}
      flush_blank_lines ();
      emitf ("@anchor{catalogue-entry-%.*s-%d}\n",
	     (int) (ep - bp), bp, symbol->catalogue->idx++);
    }
  else
    {
      if (symbol != NULL && symbol->catalogue != NULL)
	catalogue_print (symbol->name, symbol->catalogue);
    }

  return 1;
}

/* Checks whether the catalogue, if any, associated with SYM has ever
   been printed. */
static void
catalogue_check_printed (struct symbol *sym)
{
  if (sym->catalogue != NULL && sym->catalogue->printed == 0)
    printf ("%s: Catalogue `%s' never printed.\n", in_file_name, sym->name);
}

/* Warns about any unprinted catalogues. */
static void
catalogue_print_unused (void)
{
  symbol_foreach (catalogue_check_printed);
}

/* Stack of states.

   The stack grows downward from state_stack_end.  This is convenient
   because ANSI C guarantees that we can point state_top one element
   beyond state_stack[].  We use this condition to indicate an empty
   stack. */

/* Maximum number of stack entries. */
#define STATE_STACK_SIZE 8

/* One element beyond the end of state_stack[]. */
#define state_stack_end (state_stack + STATE_STACK_SIZE)

/* Stack entries. */
static enum state state_stack[STATE_STACK_SIZE];

/* Points to the top of stack entry (not before or after it). */
static enum state *state_top;

/* Initializes the state stack. */
static void
state_init (void)
{
  state_top = state_stack_end;
}

/* Returns the number of states on the state stack. */
static int
state_cnt (void)
{
  assert (state_top != NULL);
  return state_stack_end - state_top;
}

/* Returns nonzero iff STATE is the state on the top of the stack. */
static int
state_is (enum state state)
{
  assert (state_top != NULL && state_top < state_stack_end);
  return *state_top == state;
}

/* Returns nonzero iff STATE is the state directly below the top of
   the stack; i.e., if STATE was the top of stack before another state
   was pushed. */
static int
state_was (enum state state)
{
  assert (state_top != NULL);
  return state_cnt () > 1 && state_top[1] == state;
}

/* Returns nonzero iff STATE is the state at the bottom of the
   stack. */
static int
state_bottom (enum state state)
{
  assert (state_top < state_stack_end);
  return state == state_stack_end[-1];
}

/* Pushes STATE onto the state stack, making it the the top of stack
   state. */
static void
state_push (enum state state)
{
  assert (state_top != NULL && state_top > state_stack);
  *--state_top = state;
}

/* Pops a state off the state stack. */
static void
state_pop (void)
{
  assert (state_top != NULL && state_top < state_stack_end);
  state_top++;
}

/* Code segments. */

/* A named segment of code that comprises one or more numbered
   pieces. */
struct segment
  {
    char *name;			/* Segment name. */
    struct segment *next;	/* Next segment in global list. */

    /* Pieces that this segment includes (weave only). */
    int piece_cnt;		/* Number of pieces. */
    struct piece **piece;	/* Pieces. */
    int piece_cur;		/* Idx of current piece. */

    /* Pieces that include this segment (weave only). */
    int ref_cnt;		/* Number of references. */
    struct piece **ref;		/* References. */
    int *indent;		/* Relative indentation level at point
				   of reference. */

    /* Tangle info. */
    int is_file;                /* Is segment an entire file? */
    int use;			/* Number of times printed. */

    /* C code. */
    struct line *c_head;	/* First line of C code for this segment. */
    struct line *c_tail;	/* Last line of C code for this segment. */
  };

/* A numbered section of code, part of a segment. */
struct piece
  {
    struct segment *segment;	/* The segment that includes this piece. */
    int number;			/* This piece's number. */

    /* Segments that this piece includes. */
    int ref_cnt;			/* Number of references. */
    struct segment **ref;	/* References. */
  };

/* Input file location. */
struct loc
  {
    const char *fn;		/* File name. */
    int ln;			/* Line number. */
  };

/* Linked list for lines of code. */
struct line
  {
    struct line *next;		/* Next line. */
    const char *text;		/* Text contents. */
    struct loc loc;		/* Location of line. */
  };

/* The currently selected segment.  This is the one that is being read
   from the input stream and written to the output stream. */
static struct segment *segment_cur;

/* List of all segments linked together on `next' field. */
static struct segment *segment_first, *segment_last;

/* Looks for a segment named NAME, and if found, returns it.  If none
   exists, one is created and returned, if CREATE is nonzero;
   otherwise, returns a null pointer. */
static struct segment *
segment_find (const char *name, int create)
{
  /* Note that there can be a symbol found for NAME even if there is
     no segment by that name.  We must allow for both
     possibilities. */

  struct symbol *symbol;
  struct segment *segment;
  size_t len;

  len = strcspn (name, ";");
  symbol = symbol_find (name, len, create);
  if (symbol == NULL)
    return NULL;

  segment = symbol->segment;
  if (segment == NULL && create)
    {
      segment = xmalloc (sizeof *segment);

      segment->name = xstrndup (name, len);
      segment->is_file = 0;
      segment->use = 0;
      segment->next = NULL;
      segment->piece_cnt = 0;
      segment->piece = NULL;
      segment->piece_cur = -1;

      segment->ref_cnt = 0;
      segment->ref = NULL;
      segment->indent = NULL;

      segment->c_head = NULL;
      segment->c_tail = NULL;

      symbol->segment = segment;

      if (segment_first == NULL)
	segment_first = segment;
      else
	segment_last->next = segment;
      segment_last = segment;
    }

  return segment;
}

/* Select SEGMENT as being currently processed.  SEGMENT may be a null
   pointer to indicate that no segment is being processed. */
static void
segment_select (struct segment *segment)
{
  segment_cur = segment;
}

/* Returns nonzero iff a segment is being processed. */
static int
segment_selected_p (void)
{
  return segment_cur != NULL;
}

/* Returns the number of pieces in the current segment. */
static int
segment_piece_cnt (void)
{
  assert (segment_cur != NULL);
  return segment_cur->piece_cnt;
}

/* Returns the piece number of the piece being processed in the
   current segment. */
static int
segment_number (void)
{
  assert (segment_cur != NULL && segment_cur->piece_cnt > 0);
  return segment_cur->piece[segment_cur->piece_cur]->number;
}

/* Returns the piece number of the first piece in the current
   segment. */
static int
segment_first_piece (void)
{
  assert (segment_cur != NULL && segment_cur->piece_cnt > 0);
  return segment_cur->piece[0]->number;
}

/* Returns nonzero iff SEGMENT ever appears indented away from the
   left margin. */
static int
segment_inside_indentation (struct segment *segment)
{
  /* FIXME: Use serial numbers to make sure some idiot (like me)
     doesn't end up with circular references. */
  int i;

  for (i = 0; i < segment->ref_cnt; i++)
    {
      if (segment->indent[i])
	return 1;
      if (segment_inside_indentation (segment->ref[i]->segment))
	return 1;
    }

  return 0;
}

/* Advances within the current segment to the next piece. */
static void
segment_next_piece (void)
{
  assert (segment_cur != NULL
	  && segment_cur->piece_cur < segment_cur->piece_cnt - 1);
  segment_cur->piece_cur++;
}

/* Emits the piece number of the first piece in SEGMENT, if SEGMENT is
   non-null and it contains at least one piece.  Otherwise emits an
   `undefined' value.  */
static void
segment_print_number (struct segment *segment)
{
  if (segment != NULL && segment->piece_cnt != 0)
    emitf ("%d", segment->piece[0]->number);
  else
    emits (_("UNDEFINED"));
}

/* Adds a copy of TEXT to the code for the current segment, if any. */
static void
segment_add_line (const char *text)
{
  struct line *line;

  if (segment_cur == NULL)
    return;

  line = xmalloc (sizeof *line);
  line->next = NULL;
  line->text = xstrdup (text);
  line->loc.fn = in_file->name;
  line->loc.ln = in_file->line;
  if (segment_cur->c_head == NULL)
    segment_cur->c_head = line;
  if (segment_cur->c_tail != NULL)
    segment_cur->c_tail->next = line;
  segment_cur->c_tail = line;
}

/* Derive a file name from S's name,
   and return the file name as a malloc'd string. */
static char *
segment_make_filename (const struct segment *s) 
{
  char *fn, *dp, *sp;

  /* Copy from s->name into the new string.
     Escape unusual characters as _XX. */
  fn = dp = xmalloc (strlen (s->name) * 3 + 64);
  for (sp = s->name; *sp != '\0'; sp++)
    if (isalnum ((unsigned char) *sp) || strchr ("-_,.", *sp) != NULL)
      *dp++ = *sp;
    else if (*sp == ' ')
      *dp++ = '_';
    else
      dp += sprintf (dp, "_%02x", (unsigned char) *sp);

  /* If the segment name is not a file name, then add a .c
     extension to indicate to the user that it's C. */
  if (!s->is_file)
    dp += sprintf (dp, ".c");

  *dp = '\0';

  return fn;
}

/* Creates a new piece with segment S.  OPERATION should be '=' or '+'. */
static void
piece_create (struct segment *s, int operation)
{
  static int piece_cnt;
  struct piece *p;

  assert (operation == '=' || operation == '+');
  if (!strcmp (s->name, "Anonymous"))
    {
      if (operation == '+')
	error (SRC, _("Anonymous segment should not have +=."));
    }
  else if (s->piece_cnt == 0 && operation == '+')
    error (SRC, _("First piece of `%s' should not have +=."), s->name);
  else if (s->piece_cnt > 0 && operation == '=')
    error (SRC, _("Second or later piece of `%s' should have +=."), s->name);

  s->piece = xrealloc (s->piece, sizeof *s->piece * (s->piece_cnt + 1));
  p = s->piece[s->piece_cnt++] = xmalloc (sizeof **s->piece);
  p->segment = s;
  if (strcmp (s->name, "Anonymous"))
    p->number = ++piece_cnt;
  p->ref_cnt = 0;
  p->ref = NULL;
}

/* Specifies that the current piece references segment REFERENCE with
   INDENTATION characters of indentation from the left margin. */
static void
piece_references (struct segment *r, int indentation)
{
  /* The current piece. */
  struct piece *piece;
  if (segment_cur == NULL)
    return;
  piece = segment_cur->piece[segment_cur->piece_cnt - 1];

  /* Add R to the references of the current piece. */
  piece->ref = xrealloc (piece->ref,
                         sizeof *piece->ref * (piece->ref_cnt + 1));
  piece->ref[piece->ref_cnt] = r;
  piece->ref_cnt++;

  /* Add the current piece to the back-references list of the
     referenced segment, if it's not there already. */
  if (r->ref_cnt == 0 || r->ref[r->ref_cnt - 1]->segment != segment_cur)
    {
      r->ref = xrealloc (r->ref, sizeof *r->ref * (r->ref_cnt + 1));
      r->indent = xrealloc (r->indent, sizeof *r->indent * (r->ref_cnt + 1));
      r->ref[r->ref_cnt] = piece;
      r->indent[r->ref_cnt] = indentation;
      r->ref_cnt++;
    }
  else if (indentation > r->indent[r->ref_cnt - 1])
    r->indent[r->ref_cnt - 1] = indentation;
}

/* Emits a trailer for the current piece in the current segment,
   consisting of `see also <the other pieces in this segment>.' and
   `This code is included in <referencing segments>.' */
static void
piece_print_trailer (void)
{
  int comment_cnt;

  if (!segment_selected_p ())
    return;

  /* This if statement causes trailers to be printed on only the first
     piece of a segment.  Remove it to print trailers on every piece
     of a segment. */
  if (segment_cur->piece_cur != 0)
    return;

  /* No trailers for anonymous segments. */
  if (!strcmp (segment_cur->name, "Anonymous"))
    return;

  comment_cnt = (segment_piece_cnt () != 1) + (segment_cur->ref_cnt > 0);
  if (comment_cnt == 0)
    return;
  emits ("@noindent\n");

  if (segment_piece_cnt () != 1)
    {
      int i, cnt;

      cnt = segment_cur->piece_cnt - 1;

      emitf ("@little{%s ", _("See also"));

      for (i = 0; i < cnt; i++)
	{
	  int idx;

	  if (cnt > 2)
	    {
	      if (i > 0)
		emits (", ");
	      if (i == cnt - 1)
		emitf ("%s", _("and"));
	    }
	  else if (cnt == 2 && i == 1)
	    emitf (" %s ", _("and"));

	  idx = i;
	  if (i >= segment_cur->piece_cur)
	    idx++;

	  emitf ("@refalso{%d}", segment_cur->piece[idx]->number);
	}
      emits (".}");
    }

  if (segment_cur->ref_cnt > 0)
    {
      int cnt = segment_cur->ref_cnt;
      int i;

      if (comment_cnt > 1)
	emits ("@*\n");
      emitf ("@little{%s ", _("This code is included in"));

      for (i = 0; i < cnt; i++)
	{
	  if (cnt > 2)
	    {
	      if (i > 0)
		emits (", ");
	      if (i == cnt - 1)
		emitf ("%s ", _("and"));
	    }
	  else if (cnt == 2 && i == 1)
	    emitf (" %s ", _("and"));

	  emitf ("@refalso{%d}", segment_cur->ref[i]->number);
	}
      emits (".}");
    }
}

/* Various functions for woven output. */

/* Emits filename FN to the output file. */
static void
print_filename (const char *fn)
{
  emits ("@t{");
  while (*fn)
    {
      if (*fn == '@' || *fn == '{' || *fn == '}')
	emitc ('@');
      emitc (*fn);
      fn++;
    }
  emitc ('}');
}

/* Emits an identifier TEXT with length LEN to the output file.  The
   identifier is properly syntax-colored depending on whether it is a
   keyword, the special identifier NULL, contains all capitals, or an
   ordinary identifier. */
static struct symbol *
print_identifier (const char *text, int len)
{
  struct symbol *symbol = symbol_find (text, len, 0);

  emits ("@w{");
  if (symbol == NULL || symbol->kw_idx == -1)
    {
      if (symbol != NULL && symbol->is_typedef)
	emitf (TYPEDEF_STYLE "{%.*s}", len, text);
#if 0
      else if (len == 4 && !memcmp (text, "NULL", 4))
	emits ("@value{NULL}");
#endif
      else
	{
	  const char *p;
	  int type;

	  if (len < 2)
	    type = 'i';
	  else
	    {
	      type = 't';
	      for (p = text; p < text + len; p++)
		if (islower ((unsigned char) *p))
		  {
		    type = 'i';
		    break;
		  }
	    }
	  
	  emitf ("@%c{%.*s}", type, len, text);
	}
    }
  else
    emitf ("@b{%.*s}", len, text);
  emitc ('}');

  return symbol;
}

/* Prints a header for a new piece in segment SEGMENT_NAME, e.g., the
   line that says "<piece name #> =".  Incidentally creates the new
   piece as well.  TYPE should be '(' if the new piece is a file or
   '<' if it is an ordinary piece.  OPERATION should be `=' if the new
   piece is in a new segment, or `+' if it is a second or subsequent
   piece in a segment. */
static void
print_piece_header (const char *segment_name, int type, int operation)
{
  int anonymous = !strcmp (segment_name, "Anonymous");

  flush_blank_lines ();
  transition (TEXT);

  if (!anonymous)
    {
      const char *cp = segment_name;
      
      /* Colons aren't allowed in Info index entries.  Skip
         them.  This isn't perfect but it does well for the
         typical libavl usage "Step 1: Frobnicate the buffer.",
         etc. */
      if (strchr (cp, ':') != NULL) 
        {
          cp = strrchr (cp, ':') + 1;
          while (isspace ((unsigned char) *cp))
            cp++;
        }
      
      /* We want idx entries to start with a lowercase letter, but
	 section names often start with an uppercase letter.  Deal
	 with it by forcing them to lowercase.  Note that this avoids
	 changing the case of program identifiers because in that case
	 the first character in the anchor name is `|', or should be,
	 not a letter.  We have to explicitly avoid downcasing the
	 first character of an acronym, though. */
      emits ("@cindex ");
      if (type == '<')
	{
	  if (isupper ((unsigned char) cp[0])
	      && !isupper ((unsigned char) cp[1]))
	    {
	      emitc (tolower ((unsigned char) cp[0]));
	      print (cp + 1, 0);
	    }
	  else
	    print (cp, 0);
	}
      else
	print_filename (cp);
      emitc ('\n');
    }

  transition (CODE);

  {
    struct segment *segment = segment_find (segment_name, 0);
    assert (segment != NULL);
    segment_select (segment);
    segment_next_piece ();
  }

  if (!anonymous) 
    {
      char *filename = segment_make_filename (segment_cur);
      emitf ("@html\n<!-- HTMLPP: file='%s' -->\n@end html\n", filename);
      free (filename);
      
      emitf ("@tabalign{}@textinleftmargin{@w{@segno{%d} }}@nottex{%d. }@value{LANG}"
             "@anchor{%d}",
	     segment_number (), segment_number (), segment_number ());
      state_push (CONTROL);
      if (type == '<')
	print (segment_name, 0);
      else
	print_filename (segment_name);
      state_pop ();
      emitf (" @smnumber{%d}@value{RANG} %s@value{IS}@cr\n",
	     segment_first_piece (), operation == '+' ? "@math{+}" : "");
    }
}

/* Emits the Texinfo macro and setting declarations required by
   Texiweb. */
static void
open_header_file (char *line)
{
  static const char *headers[] =
    {
      "@set COMMA ,\n",
      "\n",
      "@tex\n",
      "\\global\\def\\unaryminus{${}^-$}\n",
      "\\global\\def\\unaryplus{${}^+$}\n",
      "\\global\\def\\exponent#1{$\\cdot{}10^{#1}$}\n",
      "\\global\\def\\tab{&\\the\\everytab}%\n",
      "@end tex\n",
      "\n",
      "@iftex\n",
      "@set LANG @math{@langle{}@thinspace{}}\n",
      "@set RANG @math{@thinspace{}@rangle{}}\n",
      "@set LQUOTE ``\n",
      "@set RQUOTE ''\n",
      "@set NULL @math{@Lambda{}}\n",
      "@set EQ @math{@equiv{}}\n",
      "@set IS @math{@equiv{}}\n",
      "@set NE @math{@ne{}@kern-.3333em}\n",
      "@set GE @math{@ge{}@kern-.3333em}\n",
      "@set LE @math{@le{}@kern-.3333em}\n",
      "@set AST @math{@ast{}}\n",
      "@set AND @math{@wedge{}}\n",
      "@set OR @math{@vee{}}\n",
      "@set TIMES @math{@times{}}\n",
      "@set RARR @math{@rightarrow{}@kern-.3333em}\n",
      "@set INV @math{@neg{}}\n",
      "@set SP {@char`@ }\n",
      "@end iftex\n",
      "\n",
      "@ifnottex\n",
      "@set LANG <\n",
      "@set RANG >\n",
      "@set LQUOTE \"\n",
      "@set RQUOTE \"\n",
      "@set NULL NULL\n",
      "@set EQ ==\n",
      "@set IS =\n",
      "@set NE !=\n",
      "@set LE <=\n",
      "@set GE >=\n",
      "@set AST *\n",
      "@set AND &&\n",
      "@set OR ||\n",
      "@set TIMES *\n",
      "@set RARR ->\n",
      "@set INV !\n",
      "@set SP @ @c\n",
      "@end ifnottex\n",
      "\n",
      "@ifnottex\n",
      "@macro textinleftmargin{TEXT}\n",
      "@end macro\n",
      "@macro nottex{TEXT}\n",
      "\\TEXT\\\n",
      "@end macro\n",
      "@macro segno{NUMBER}\n",
      "\\NUMBER\\\n",
      "@end macro\n",
      "@ifhtml\n",
      "@macro little{TEXT}\n",
      "@html\n",
      "<small>\\TEXT\\</small>\n",
      "@end html\n",
      "@end macro\n",
      "@end ifhtml\n",
      "@ifnothtml\n",
      "@macro little{TEXT}\n",
      "\\TEXT\\\n",
      "@end macro\n",
      "@end ifnothtml\n",
      "@macro smnumber{TEXT}\n",
      "\\TEXT\\\n",
      "@end macro\n",
      "@macro tabalign\n",
      "@end macro\n",
      "@macro wtab\n",
      "@end macro\n",
      "@macro tcr{TEXT}\n",
      "@*\\TEXT\\\n",
      "@end macro\n",
      "@macro cleartabs\n",
      "@end macro\n",
      "@macro IND{AMT}\n",
      "@end macro\n",
      "@macro cr\n",
      "@end macro\n",
      "@alias begincode = format\n",
      "@alias endcode = end\n",
      "@macro blankline\n",
      "@tabalign{}@cr\n",
      "@end macro\n",
      "@macro exponent{EXP}\n",
      "e\\EXP\\\n",
      "@end macro\n",
      "@macro unaryminus{}\n",
      "-\n",
      "@end macro\n",
      "@macro unaryplus{}\n",
      "+\n",
      "@end macro\n",
      "@macro exerspace{}\n",
      "@w{ }\n",
      "@end macro\n",
      "@end ifnottex\n",
      "\n",
      "@ifhtml\n",
      "@set maybedot\n",
      "@end ifhtml\n",
      "@ifnothtml\n",
      "@set maybedot .\n",
      "@end ifnothtml\n",
      "\n",
      "@iftex\n",
      "@macro textinleftmargin{TEXT}\n",
      "@hskip -.4in@hbox to .4in{\\TEXT\\@hskip 0in plus1fil}\n",
      "@end macro\n",
      "@macro nottex{TEXT}\n",
      "@end macro\n",
      "@macro segno{NUMBER}\n",
      "@S\\NUMBER\\\n",
      "@end macro\n",
      "@macro little{TEXT}\n",
      "{@smallrm{}\\TEXT\\}\n",
      "@end macro\n",
      "@macro smnumber{TEXT}\n",
      "{@smallrm{}\\TEXT\\}\n",
      "@end macro\n",
      "@macro tcr{TEXT}\n",
      "@end macro\n",
      "@macro IND{AMT}\n",
      "@hskip\\AMT\\\n",
      "@end macro\n",
      "@macro begincode\n",
      /* Uncomment to put a thin rule above code segments. */
      /* "@vskip 1pt plus0pt@hrule@vskip -2pt plus0pt", */
      "@smallskip\n",
      "@end macro\n",
      "@macro endcode {ignore}\n",
      /* Uncomment to put a thin rule below code segments. */
      /* "@vskip 1pt plus0pt@hrule\n", */
      "@end macro\n",
      "@macro blankline\n",
      "@smallskip\n",
      "@end macro\n",
      "@alias wtab=tab\n",
      "@macro exerspace{}\n",
      "@hskip .5em plus0em minus0em\n",
      "@end macro\n",
      "@end iftex\n",
      "\n",
      "@ifhtml\n",
      "@macro refcode {TITLE, NODE}\n",
      "@value{LANG}@ref{\\NODE\\, , \\TITLE\\ \\NODE\\}@value{RANG}\n",
      "@end macro\n",
      "@macro refalso {NODE}\n",
      "@ref{\\NODE\\}\n",
      "@end macro\n",
      "@end ifhtml\n",
      "\n",
      "@ifinfo\n",
      "@ifclear PLAINTEXT\n",
      "@macro refcode {TITLE, NODE}\n",
      "@value{LANG}@ref{\\NODE\\, , \\TITLE\\}.@value{RANG}\n",
      "@end macro\n",
      "@macro refalso {NODE}\n",
      "@ref{\\NODE\\}\n",
      "@end macro\n",
      "@end ifclear\n",
      "@ifset PLAINTEXT\n",
      "@macro refcode {TITLE, NODE}\n",
      "@value{LANG}\\TITLE\\ \\NODE\\@value{RANG}\n",
      "@end macro\n",
      "@macro refalso {NODE}\n",
      "\\NODE\\\n",
      "@end macro\n",
      "@end ifset\n",
      "@end ifinfo\n",
      "\n",
      "@iftex\n",
      "@macro refcode {TITLE, NODE}\n",
      "@value{LANG}\\TITLE\\ {@smallrm{}\\NODE\\}@value{RANG}\n",
      "@end macro\n",
      "@macro refalso {NODE}\n",
      "@segno{\\NODE\\}\n"
      "@end macro\n",
      "@end iftex\n",
      "\n",
      NULL
    };

  char *bp, *ep;
  const char **p;

  if (!find_argument (line, &bp, &ep))
    return;
  *ep = '\0';

  if (header_file != NULL)
    {
      error (SRC, _("Extra @setheaderfile ignored"));
      return;
    }

  header_file_name = xstrndup (bp, ep - bp);
  header_file = fopen (header_file_name, "w");
  if (header_file == NULL)
    error (SRC | FTL, _("Opening %s: %s"), bp, strerror (errno));

  for (p = headers; *p != NULL; p++)
    fputs (*p, header_file);
}

/* Closes the header file. */
static void
close_header_file (void)
{
  if (header_file == NULL)
    error (0, _("No `@setheaderfile' in source."));
  else if (fclose (header_file) != 0)
    error (SRC | FTL, _("Closing header file: %s"), strerror (errno));
  header_file = NULL;
}

/* Sections and exercises. */

/* Currently inside exercise? */
static int in_exercise = 0;

/* Initializes SECTION to the beginning of the book. */
static void
section_init (struct section *section)
{
  int level;

  for (level = 0; level < LEVEL_CNT; level++)
    section->level[level] = 0;
}

/* Advances SECTION to the next LEVEL. */
static void
section_advance (struct section *section, enum section_level level)
{
  if (in_exercise && level != LEVEL_EXERCISE)
    {
      error (SRC | FTL, _("Unterminated exercise at section boundary."));
      in_exercise = 0;
    }

  section->level[level]++;
  for (level++; level < LEVEL_CNT; level++)
    section->level[level] = 0;
}

/* Resets counters below LEVEL.
   This is useful for unnumbered sections because it doesn't
   increment the section number but does distinguish unnumbered
   sections from their predecessors by making them part of their
   containing sections. */
static void
section_reset (struct section *section, enum section_level level)
{
  for (level++; level < LEVEL_CNT; level++)
    section->level[level] = 0;
}

/* Returns nonzero if A and B differ at level LEVEL or less. */
static int
section_differs (struct section *a, struct section *b,
		 enum section_level level)
{
  enum section_level i;

  for (i = 0; i <= level; i++)
    if (a->level[i] != b->level[i])
      return 1;
  return 0;
}

/* Writes name for SECTION into NAME. */
static void
section_name (struct section *section, char name[64])
{
  int level;

  sprintf (name, "%d", section->level[LEVEL_CHAPTER]);
  for (level = 1; level < LEVEL_EXERCISE; level++)
    {
      name = strchr (name, '\0');

      if (section->level[level] == 0)
	break;
      sprintf (name, ".%d", section->level[level]);
    }
}

/* Attempts to recognize a sectioning command in CMD and advance
   counters appropriately.  Returns nonzero if a sectioning command
   was parsed. */
static int
section_recognize (const char *cmd)
{
  struct section_cmd
    {
      enum section_level level;
      int numbered;
      char *name;
    };

  static const struct section_cmd cmds[] = 
    {
      {LEVEL_CHAPTER, 1, "chapter"},
      {LEVEL_CHAPTER, 0, "unnumbered"},
      {LEVEL_CHAPTER, 0, "appendix"},

      {LEVEL_SECTION, 1, "section"}, 
      {LEVEL_SECTION, 0, "unnumberedsec"},
      {LEVEL_SECTION, 0, "appendixsec"},

      {LEVEL_SUBSECTION, 1, "subsection"},
      {LEVEL_SUBSECTION, 0, "unnumberedsubsec"}, 
      {LEVEL_SUBSECTION, 0, "appendixsubsec"},

      {LEVEL_SUBSUBSECTION, 1, "subsubsection"}, 
      {LEVEL_SUBSUBSECTION, 0, "unnumberedsubsubsec"}, 
      {LEVEL_SUBSUBSECTION, 0, "appendixsubsubsec"},
      
      {LEVEL_EXERCISE, 1, "exercise"},
    };

  const struct section_cmd *p;

  for (p = cmds; p < cmds + sizeof cmds / sizeof *cmds; p++)
    if (!strcmp (cmd, p->name))
      {
        if (p->numbered)
          section_advance (&cur_section, p->level);
        else
          section_reset (&cur_section, p->level);
	return 1;
      }
  return 0;
}

/* Handles exercise commands.
   CMD is the @-command in question, LINE is the line that
   contains it, and PASS is 1 or 2 if we're making the first or second
   pass through the input file, respectively. */
static int
exercise_process (const char *cmd, char *line, int pass)
{
  if (!strcmp (cmd, "setanswerfile"))
    exercise_open_answer_file (line, pass);
  else if (!strncmp (cmd, "exercise", 8))
    exercise_begin (line, pass);
  else if (!strcmp (cmd, "answer"))
    exercise_answer (line, pass);
  else
    return exercise_end (cmd, line, pass);

  return 1;
}

/* Handles an @exercise command on line LINE during pass PASS. */
static void
exercise_begin (char *line, int pass)
{
  if (pass == 2)
    {
      char *bp, *ep;

      bp = ep = line + strlen ("@exercise");
      while (!isspace ((unsigned char) *ep))
	ep++;

      flush_blank_lines ();

      if (cur_section.level[LEVEL_EXERCISE] == 1)
	emitf ("@blankline @noindent @b{%s}\n\n", _("Exercises:"));
      emitf ("@blankline @noindent @b{%.*s%d.}",
	     (int) (ep - bp), bp,
	     cur_section.level[LEVEL_EXERCISE]);

      if (find_optional_argument (line, &bp, &ep))
	{
	  char sec_name[64];
	  section_name (&cur_section, sec_name);

	  if (header_file != NULL)
	    fprintf (header_file,
		     "@set %.*s Exercise %s-%d\n"
		     "@set %.*sbrief Exercise %d\n",
		     (int) (ep - bp), bp, sec_name,
		     cur_section.level[LEVEL_EXERCISE],
		     (int) (ep - bp), bp, cur_section.level[LEVEL_EXERCISE]);
	  else
	    error (SRC, _("No preceding `@setheaderfile'."));

	  emitf ("@anchor{%.*s}", (int) (ep - bp), bp);
	}

      emits ("@exerspace{}");
    }

  if (in_exercise)
    error (SRC, _("`@exercise' within exercise."));
  in_exercise = 1;
}

/* Checks for and handles an @end exercise command.
   CMD is the @-command, LINE is the line it is on, PASS is the
   current pass.  Returns nonzero only if an @end exercise command was
   parsed. */
static int
exercise_end (const char *cmd, char *line, int pass)
{
  char *bp, *ep;

  if (strcmp (cmd, "end"))
    return 0;
  find_argument (line, &bp, &ep);
  if (ep - bp != 8 || memcmp (bp, "exercise", 8))
    return 0;

  if (!in_exercise)
    {
      error (SRC, _("`@end exercise' outside exercise."));
      return 0;
    }
  if (pass == 2 && print_unanswered)
    error (SRC, _("Exercise missing answer."));
  in_exercise = 0;

  return 1;
}

/* Handles an @answer command on line PLINE during pass PASS. */
static void
exercise_answer (char *pline, int pass)
{
  char *line = xstrdup (pline);
  size_t size = strlen (pline) + 1;
  int n_answers = 0;

  if (pass == 1 && answer_file == NULL)
    error (SRC | FTL, _("@answer: No answer file defined."));

  if (pass == 2) 
    {
      char anchor[64];
      exercise_anchor (&cur_section, anchor);
      emitf ("@ifnottex\n"
             "@ifclear PLAINTEXT\n"
             "[@ref{%s, , answer}@value{maybedot}]\n"
             "@end ifclear\n"
             "@end ifnottex\n",
             anchor);
    }

  for (;;)
    {
      static const char answer[] = "@answer";
      static const char exercise[] = "@exercise";
      static const char end_exercise[] = "@end exercise";

      if (pass == 1 && !strncmp (line, answer, (sizeof answer) - 1))
	{
	  /* Catch up headings within the answer file. */
	  {
	    static struct section last_answer;

	    if (section_differs (&cur_section, &last_answer, LEVEL_CHAPTER)) 
              {
                char node_name[64];
                sprintf (node_name, "Answers for %s %d",
                         _("Chapter"), cur_section.level[0]);

                fprintf (answer_file,
                         "\n"
                         "@node %s\n"
                         "@unnumberedsec %s %d\n\n",
                         node_name,
                         _("Chapter"), cur_section.level[0]);
                exercise_menu_add_node (node_name);
              }
	    if (section_differs (&cur_section, &last_answer,
				 LEVEL_SUBSUBSECTION)
		&& cur_section.level[LEVEL_SECTION] != 0)
	      {
		char sec_name[64];
		section_name (&cur_section, sec_name);

		fprintf (answer_file,
			 "@subheading %s %s\n\n", _("Section"), sec_name);
	      }
	    last_answer = cur_section;
	  }

	  /* Print exercise number and anchor in answer file. */
	  {
	    char *bp, *ep;

	    if (!find_optional_argument (line, &bp, &ep))
	      bp = ep = "";
	    fputs ("\n@blankline ", answer_file);
            if (n_answers++ == 0) 
              {
                char anchor[64];
                exercise_anchor (&cur_section, anchor);
                fprintf (answer_file, "@anchor{%s} ", anchor);
              }
            
            fprintf (answer_file, "@noindent @b{%d%.*s.}\n",
		     cur_section.level[LEVEL_EXERCISE], (int) (ep - bp),
		     bp);
	  }
	}
      else if (!strncmp (line, exercise, (sizeof exercise) - 1))
	error (SRC | FTL, _("@exercise seen looking for @end exercise"));
      else if (!strncmp (line, end_exercise, (sizeof end_exercise) - 1))
	break;
      else if (pass == 1)
	fputs (line, answer_file);

      if (!input_read_line (&line, &size))
	error (SRC | FTL, _("End-of-file looking for @end exercise"));
    }

  free (line);
  in_exercise = 0;
}

/* Closes the current exercise answer file. */
static void
exercise_close_answer_file (void)
{
  if (answer_file == NULL)
    return;

  if (fclose (answer_file) != 0)
    error (SRC | FTL, _("Closing answer file: %s"), strerror (errno));
  answer_file = NULL;
}

/* Handles the @setanswerfile command.
   LINE is the current line, PASS the current pass. */
static void
exercise_open_answer_file (char *line, int pass)
{
  char *bp, *ep;
  if (!find_argument (line, &bp, &ep))
    return;

  if (pass == 1)
    {
      exercise_close_answer_file ();

      free (answer_file_name);
      answer_file_name = xstrndup (bp, ep - bp);
      answer_file = fopen (answer_file_name, "w");
      if (answer_file == NULL)
	error (SRC | FTL, _("Opening %s: %s"), bp, strerror (errno));
      fputs ("@answermenu\n", answer_file);
    }
}

/* Converts section number SECTION to an exercise anchor ANCHOR. */
static void
exercise_anchor (struct section *section, char name[64])
{
  char *cp;
  
  section_name (section, name);

  /* `.' is not allowed in node names. */
  for (cp = name; *cp != '\0'; cp++)
    if (*cp == '.')
      *cp = '-';

  /* Exercise number must be differentiated from section
     numbers. */
  sprintf (cp, "#%d", section->level[LEVEL_EXERCISE]);
}

/* Regrettably, `makeinfo' can only generate the proper
   inter-node pointers if we create proper menus for every node
   that has sub-nodes, and that includes the answers chapter.
   This variable accumulates a series of lines for the menu. */
static char *exercise_menu;

/* Number of characters in exercise_menu. */
static size_t exercise_menu_len;

/* Prints a Texinfo menu for the answers chapter. */
static void
exercise_emit_answer_menu (void) 
{
  if (exercise_menu_len) 
    {
      emits ("@menu\n");
      emits (exercise_menu);
      emits ("@end menu\n");

      free (exercise_menu);
      exercise_menu_len = 0;
    }
}

/* Adds a node to the Texinfo menu list. */
static void
exercise_menu_add_node (const char *node_name) 
{
  exercise_menu = xrealloc (exercise_menu,
                            exercise_menu_len + strlen (node_name) + 32);

  exercise_menu_len += sprintf (exercise_menu + exercise_menu_len,
                                "* %s::\n", node_name);
}

/* Attempts to parse LINE as beginning with an @-command.  If successful, puts
   the @-command, minus the `@', into CMD (truncating at CMD_LEN_MAX
   characters), and returns nonzero.  If unsuccessful, returns zero. */
static int
parse_at_cmd (const char *line, char cmd[CMD_LEN_MAX + 1])
{
  if (*line++ != '@')
    return 0;

  if (isalpha ((unsigned char) *line))
    {
      int i;

      for (i = 0; i < CMD_LEN_MAX; i++)
	{
	  *cmd++ = *line++;
	  if (!isalpha ((unsigned char) *line))
	    break;
	}
    }
  else if (*line != '\0' && !isspace ((unsigned char) *line))
    *cmd++ = *line++;

  *cmd = '\0';
  return 1;
}

/* Control texts. */

/* Nonzero if we are processing a control text (@< ... @>). */
static int in_control;

/* Nonzero if we've encountered whitespace in a control text. */
static int control_space;

/* Buffer used for recording control text contents. */
static char *control_buf;	/* Buffer contents. */
static size_t control_len;	/* Amount in buffer. */
static size_t control_size;	/* Number of bytes allocated for buffer. */

/* Adds TEXT having length LEN to control_buf, allocating more space
   as necessary. */
static void
add_control (const char *text, size_t len)
{
  const char *cp;

  if (control_len + len + 8 > control_size)
    {
      control_size = control_len * 2 + len + 16;
      control_buf = xrealloc (control_buf, control_size);
    }

  for (cp = text; cp < text + len; cp++)
    {
      if (isspace ((unsigned char) *cp))
	{
	  /* Delete leading spaces. */
	  if (control_len == 0)
	    continue;

	  /* Reduce internal whitespace to single spaces and delete
	     trailing spaces. */
	  control_space = 1;
	  continue;
	}

      if (control_space)
	{
	  control_buf[control_len++] = ' ';
	  control_space = 0;
	}

      control_buf[control_len++] = *cp;
    }
}

/* Attempts to parse a control text in START, which points just past
   @< or @( in the input stream.  The control text must end within
   START.  Returns the control text, heap-allocated.  If TAIL is
   non-null then *TAIL is set to point directly after the @> ending
   the control text. */
static char *
parse_control_text (char *start, char **tail)
{
  char *end = strstr (start, "@>");
  if (end != NULL)
    {
      if (tail != NULL)
	*tail = end + 2;
    }
  else
    {
      error (SRC, _("Missing control text end marker @>."));
      end = strchr (start, '\0');
      if (tail != NULL)
	*tail = end;
    }

  /* Run the control text through the same normalization as in running
     text. */
  {
    char *buf;

    control_len = 0;
    control_space = 0;
    add_control (start, end - start);
    add_control ("", 1); /* Null terminator. */
    buf = control_buf;
    control_buf = NULL;
    control_len = 0;
    control_size = 0;
    return buf;
  }
}

/* TexiWEB lexical analysis. */

/* Special tokens emitted by the tokenizer.
   When no token type from this list matches, tokens for individual
   characters are represented by their own values. */
enum
  {
    /* Recognized anywhere. */
    TOKEN_EOL = 0,		/* No more tokens available. */
    TOKEN_AT = -256,		/* @@. */
    TOKEN_BEGIN_CONTROL,	/* @<, @(. */
    TOKEN_END_CONTROL,		/* @>. */
    TOKEN_SEMICOLON,		/* @;. */
    TOKEN_PIPE,			/* @|. */
    TOKEN_COND_NEWLINE,		/* @\n. */
    TOKEN_INC_INDENT,		/* @+. */
    TOKEN_DEC_INDENT,		/* @-. */
    TOKEN_ID,			/* Word, or C identifier or keyword. */

    /* Recognized where noted. */
    TOKEN_BEGIN_EMBED_CODE,	/* | while not inside code inside text. */
    TOKEN_END_EMBED_CODE,	/* | while inside code inside text. */
    TOKEN_BEGIN_COMMENT,	/* slash-star inside code. */
    TOKEN_END_COMMENT,		/* star-slash inside a comment. */
    TOKEN_REPLACE,		/* => in control text. */

    /* Recognized only inside code. */
    TOKEN_PREPROCESSOR,		/* #. */
    TOKEN_PSTRUCT_ELEM,		/* ->. */
    TOKEN_EQ,			/* Mathematical ==. */
    TOKEN_NE,			/* Mathematical !=. */
    TOKEN_LE,			/* Mathematical <=. */
    TOKEN_GE,			/* Mathematical >=. */
    TOKEN_AND,			/* Not used. */
    TOKEN_OR,			/* Not used. */
    TOKEN_TIMES,		/* Not used. */
    TOKEN_NEG,			/* - used as unary operator. */
    TOKEN_POS,			/* + used as unary operator. */
    TOKEN_PLUSPLUS,		/* ++ */
    TOKEN_MINUSMINUS,		/* -- */
    TOKEN_QUOTED_STRING,	/* "..." */
    TOKEN_OCT_INT,		/* 0123. */
    TOKEN_HEX_INT,		/* 0xabc. */
    TOKEN_SCIENTIFIC,		/* 1.23e45. */
    TOKEN_NUMBER,		/* 123 or 1.23. */
    TOKEN_ELLIPSIS              /* ... */
  };

/* A token. */
struct token
  {
    int type;		/* One of TOKEN_* above. */
    const char *text;	/* Text of the token, not null-terminated. */
    size_t len;		/* Length of token text. */
  };

/* Obtains a token from S and stores it in TOKEN.  Returns a pointer
   to where tokenizing should begin the next time. */
static const char *
token_get (const char *s, struct token *token)
{
  /* Keeps track of current tokenizing location. */
  const char *cp = s;

  token->text = s;
  if (*cp == '@')
    {
      cp++;
      token->type = ' ';
      switch (*cp++)
	{
	case '\n':
	  token->type = TOKEN_COND_NEWLINE;
	  break;

	case '@':
	  token->type = TOKEN_AT;
	  break;

	case '(':
	case '<':
	  if (*cp == '=')
	    {
	      token->type = TOKEN_LE;
	      cp++;
	    }
	  else
	    token->type = TOKEN_BEGIN_CONTROL;
	  break;

	case '>':
	  if (*cp == '=')
	    {
	      token->type = TOKEN_GE;
	      cp++;
	    }
	  else
	    token->type = TOKEN_END_CONTROL;
	  break;

	case ';':
	  token->type = TOKEN_SEMICOLON;
	  break;

	case '|':
	  token->type = TOKEN_PIPE;
	  break;

	case '+':
	  token->type = TOKEN_INC_INDENT;
	  break;

	case '=':
	  token->type = TOKEN_EQ;
	  break;

	case '!':
	  if (*cp == '=')
	    {
	      token->type = TOKEN_NE;
	      cp++;
	    }
	  else
	    error (SRC, _("Skipped unknown token @!"));
	  break;

	case '-':
	  if (state_is (CODE))
	    {
	      token->type = TOKEN_DEC_INDENT;
	      break;
	    }
	  /* Fall through. */

	default:
	  /* We don't know this @ command.  Pass it through
             unchanged. */
	  cp--;
	  token->type = '@';
	}
    }
  else if (*cp == '|'
	   && (state_is (TEXT) || state_is (COMMENT) || state_is (CONTROL)))
    {
      cp++;
      token->type = TOKEN_BEGIN_EMBED_CODE;
    }
  else if (*cp == '=' && cp[1] == '>' && state_is (CONTROL))
    {
      cp += 2;
      token->type = TOKEN_REPLACE;
    }
  else if (isalpha ((unsigned char) *cp) || *cp == '_')
    {
      token->type = TOKEN_ID;
      while (isalnum ((unsigned char) *cp) || *cp == '_')
	cp++;
    }
  else if (state_is (CODE))
    {
      if (*cp == '\'' || *cp == '"')
	{
	  int quote = *cp++;
	  while (*cp != quote && *cp != '\0')
	    {
	      if (*cp == '\\')
		cp++;
	      cp++;
	    }
	  if (*cp == quote)
	    cp++;
	  token->type = TOKEN_QUOTED_STRING;
	}
      else if (*cp == '0' && (cp[1] == 'x' || cp[1] == 'X'))
	{
	  cp += 2;
	  while (isxdigit ((unsigned char) *cp))
	    cp++;
	  token->type = TOKEN_HEX_INT;
	}
      else if (*cp == '0' && cp[1] >= '0' && cp[1] <= '7')
	{
	  cp++;
	  while (*cp >= '0' && *cp <= '7')
	    cp++;
	  token->type = TOKEN_OCT_INT;
	}
      else if (isdigit ((unsigned char) *cp)
	       || (*cp == '.' && isdigit ((unsigned char) cp[1])))
	{
	  cp++;
	  while (isdigit ((unsigned char) *cp) || *cp == '.')
	    cp++;
	  if (*cp == 'e' || *cp == 'E')
	    {
	      cp++;
	      while (isdigit ((unsigned char) *cp) || *cp == '+' || *cp == '-')
		cp++;
	      token->type = TOKEN_SCIENTIFIC;
	    }
	  else
	    token->type = TOKEN_NUMBER;
	}
      else if (*cp == '|' && cp[1] != '|'
	       && (state_was (TEXT) || state_was (COMMENT)
		   || state_was (CONTROL)))
	{
	  cp++;
	  token->type = TOKEN_END_EMBED_CODE;
	}
      else if (*cp == '/' && cp[1] == '*')
	{
	  cp += 2;
	  token->type = TOKEN_BEGIN_COMMENT;
	}
      else if (*cp == '#')
	{
	  token->type = TOKEN_PREPROCESSOR;
	  cp++;
	}
      else if (*cp == '-' && cp[1] == '>')
	{
	  token->type = TOKEN_PSTRUCT_ELEM;
	  cp += 2;
	}
#if 0
      else if (*cp == '=' && cp[1] == '=')
	{
	  token->type = TOKEN_EQ;
	  cp += 2;
	}
      else if (*cp == '!' && cp[1] == '=')
	{
	  token->type = TOKEN_NE;
	  cp += 2;
	}
      else if (*cp == '<' && cp[1] == '=')
	{
	  token->type = TOKEN_LE;
	  cp += 2;
	}
      else if (*cp == '>' && cp[1] == '=')
	{
	  token->type = TOKEN_GE;
	  cp += 2;
	}
      else if (*cp == '&' && cp[1] == '&')
	{
	  token->type = TOKEN_AND;
	  cp += 2;
	}
      else if (*cp == '|' && cp[1] == '|')
	{
	  token->type = TOKEN_OR;
	  cp += 2;
	}
      else if (*cp == '*' && isspace ((unsigned char) cp[1]))
	{
	  token->type = TOKEN_TIMES;
	  cp++;
	}
#endif
      else if (*cp == '-' && cp[1] == '-')
	{
	  token->type = TOKEN_MINUSMINUS;
	  cp += 2;
	}
      else if (*cp == '+' && cp[1] == '+')
	{
	  token->type = TOKEN_PLUSPLUS;
	  cp += 2;
	}
      else if (*cp == '-'
	       && (cp[1] != '=' && cp[1] != '|'
		   && !isspace ((unsigned char) cp[1])))
	{
	  token->type = TOKEN_NEG;
	  cp++;
	}
      else if (*cp == '+'
	       && (cp[1] != '=' && cp[1] != '|'
		   && !isspace ((unsigned char) cp[1])))
	{
	  token->type = TOKEN_POS;
	  cp++;
	}
      else if (*cp == '.' && cp[1] == '.' && cp[2] == '.') 
        {
          token->type = TOKEN_ELLIPSIS;
          cp += 3;
        }
      else
	{
	  token->type = (unsigned char) *cp;
	  cp++;
	}
    }
  else if (*cp == '*' && cp[1] == '/' && state_is (COMMENT))
    {
      cp += 2;
      token->type = TOKEN_END_COMMENT;
    }
  else
    {
      token->type = (unsigned char) *cp;
      if (*cp)
	cp++;
    }

  token->len = cp - token->text;
  return cp;
}

/* Gets a token starting at CP and stores it into TOKEN, returning
   where parsing for the next token should begin, as with token_get().
   Also handles control text, code embedded in text, and comments. */
static const char *
token_parse (const char *cp, struct token *token)
{
  cp = token_get (cp, token);

  if (in_control && token->type != TOKEN_END_CONTROL)
    add_control (token->text, token->len);

  switch (token->type)
    {
    case TOKEN_BEGIN_CONTROL:
      if (!in_control)
	{
	  state_push (CONTROL);
	  in_control = token->text[token->len - 1];	/* Either < or (. */
	  control_len = 0;
	  control_space = 0;
	}
      else
	error (SRC, _("Can't nest control texts."));
      break;

    case TOKEN_END_CONTROL:
      if (control_len > 0)
	control_buf[control_len] = '\0';
      else
	{
	  error (SRC, _("Empty control text."));
	  token->type = ' ';
	}

      if (in_control)
	{
	  in_control = 0;
	  while (!state_is (CONTROL))
	    {
	      error (SRC, _("Missing closing within control text."));
	      state_pop ();
	    }
	  state_pop ();
	}
      else
	error (SRC, _("@> not inside control text."));
      break;

    case TOKEN_BEGIN_EMBED_CODE:
      state_push (CODE);
      break;

    case TOKEN_END_EMBED_CODE:
      state_pop ();
      break;

    case TOKEN_BEGIN_COMMENT:
      state_push (COMMENT);
      break;

    case TOKEN_END_COMMENT:
      state_pop ();
      break;

    default:
      /* Nothing to do. */
      break;
    }

  return cp;
}

/* Returns nonzero iff TOKEN represents whitespace. */
static int
token_space_p (struct token *token)
{
  return (token->type >= CHAR_MIN
	  && token->type <= CHAR_MAX
	  && isspace ((unsigned char) token->type));
}

/* Weave: Pass one. */

/* First pass.  In this pass, texiweb learns about segments and the
   pieces contained in them, and records the segments that each piece
   refers to. */
static void
weave_pass_one (void)
{
  size_t line_size = 0;
  char *line = NULL;

  section_init (&cur_section);
  state_init ();
  state_push (TEXT);

  input_start_pass ();
  while (input_read_line (&line, &line_size))
    {
      char cmd[CMD_LEN_MAX + 1];

      /* Keep track of transitions into and out of code segments. */
      if (parse_at_cmd (line, cmd))
	{
	  section_recognize (cmd);
	  if (!strcmp (cmd, "references"))
	    enforce_references_ordering ();

	  if (cmd[0] == '\0' || !strcmp (cmd, "node"))
	    {
	      segment_select (NULL);
	      continue;
	    }
          else if (!strcmp (cmd, "setheaderfile"))
            open_header_file (line);
	  else if (!strcmp (cmd, "bye"))
	    break;
	  else if (!exercise_process (cmd, line, 1)
		   && !catalogue_process_one (cmd, line))
	    {
	      int operation;
              int is_file;
	      char *control_text;

              control_text = segment_definition_line (line,
                                                      &operation, &is_file);
	      if (control_text != NULL)
		{
		  segment_select (segment_find (control_text, 1));
                  segment_cur->is_file = is_file;
		  piece_create (segment_cur, operation);
		  free (control_text);
		  continue;
		}
	    }
	}

      /* Record references that this piece makes to other pieces. */
      if (segment_cur != NULL)
	{
	  const char *cp = line;
	  int indentation = indent_amount (line, &cp);

	  for (;;)
	    {
	      struct token token;
	      cp = token_parse (cp, &token);

	      if (token.type == 0)
		break;
	      else if (token.type == TOKEN_END_CONTROL)
		piece_references (segment_find (control_buf, 1),
				  indentation);
	    }
	}
    }
  input_end_pass ();
  state_pop ();

  free (line);
}

/* Attempts to parse LINE as a segment definition line in the
   form "@<piece@> =".  Note that @< may be @( and = may be +=.
   If successful, returns a heap-allocated copy of the control
   text, sets OPERATION to '=' for = or '+' for +=, and sets
   IS_FILE to 1 if it's a file definition (@() or 0 if it's a
   segment definition (@<).  If unsuccessful, returns a null
   pointer. */
static char *
segment_definition_line (char *line, int *operation, int *is_file)
{
  char *control_text;
  char *cp, *ep;

  control_text = NULL;
  if (*line == '@' && (line[1] == '<' || line[1] == '('))
    {
      *is_file = line[1] == '(';
      if (in_control)
	{
	  error (SRC | FTL, _("Nested control texts."));
	  in_control = 0;
	}

      control_text = parse_control_text (line + 2, &cp);

      ep = strchr (cp, '\0');
      trim_whitespace (&cp, &ep);
      if (ep - cp == 1 && cp[0] == '=')
        *operation = '=';
      else if (ep - cp == 2 && cp[0] == '+' && cp[1] == '=')
        *operation = '+';
      else
	{
	  free (control_text);
	  control_text = NULL;
	}
    }

  return control_text;
}

/* Make sure that @references is before the first @exercise within a
   given section, because I tend to screw this up. */
static void
enforce_references_ordering (void)
{
  static struct section last_error;

  if (cur_section.level[LEVEL_EXERCISE] > 0
      && section_differs (&cur_section, &last_error, LEVEL_SUBSUBSECTION))
    {
      last_error = cur_section;
      error (SRC, _("References should precede exercises."));
    }
}

/* Weave: Pass two. */

/* Nonzero if the last line read was a blank line.
   Allows us squeeze multiple blank lines into single ones
   and avoid printing blank lines at all in some cases. */
static int blank;

/* The number of parentheses or brackets that we're nested within. */
static int parens;

/* Nonzero if the next line is to be pasted onto this one without a
   line break. */
static int paste;

/* Pass two.  Write out Texinfo for everything. */
static void
weave_pass_two (void)
{
  size_t line_size = 0;
  char *line = NULL;

  int print_flags = 0;

  state_init ();
  state_push (TEXT);
  section_init (&cur_section);

  input_start_pass ();
  while (input_read_line (&line, &line_size))
    {
      char cmd[CMD_LEN_MAX + 1];

      if (!parse_at_cmd (line, cmd))
	{
	  print_flags = print_line (line, print_flags);
	  continue;
	}

      section_recognize (cmd);
      if (!strcmp (cmd, "node"))
	{
	  transition (TEXT);
	  print_flags = print_line (line, print_flags);
	}
      else if (cmd[0] == '\0')
	{
	  transition (TEXT);
	  continue;
	}
      else if (!strcmp (cmd, "p"))
	{
	  transition (CODE);
	  continue;
	}
      else if (cmd[0] == '<' || cmd[0] == '(')
	{
	  char *control_text;
	  int operation;
          int is_file;

	  control_text = segment_definition_line (line, &operation, &is_file);
	  if (control_text != NULL)
	    {
	      print_piece_header (control_text, cmd[0], operation);
	      free (control_text);
	    }
	  else
	    print_flags = print_line (line, print_flags);
	}
      else if (!strcmp (cmd, "setheaderfile"))
        continue;
      else if (!strcmp (cmd, "deftypedef"))
	{
	  char *bp, *ep;
	  if (!find_argument (line, &bp, &ep))
	    continue;

	  *ep = '\0';
	  symbol_find (bp, strlen (bp), 1)->is_typedef = 1;
	}
      else if (!strcmp (cmd, "answermenu")) 
        exercise_emit_answer_menu ();
      else if (!exercise_process (cmd, line, 2)
	       && !catalogue_process_two (cmd, line))
	{
	  print_flags = print_line (line, print_flags);
	  if (!strcmp (cmd, "bye"))
	    break;
	}
    }
  input_end_pass ();
  state_pop ();
  exercise_close_answer_file ();
  close_header_file ();

  if (print_catalogues)
    catalogue_print_unused ();

  free (line);
}

/* Transition from the current state into new top-level state
   NEW_STATE, emitting whatever needs to be emitted. */
static void
transition (enum state new_state)
{
  assert (state_cnt () > 0);

  if (state_cnt () > 1)
    {
      error (SRC, _("Nested state transition."));
      while (state_cnt () > 1)
	state_pop ();
    }

  if (warn_nonzero_indent && indent_adjust != 0)
    error (SRC, _("Nonzero indent adjustment at state transition."));

  if (state_is (new_state))
    return;

  blank = 0;
  if (state_is (TEXT) && new_state == CODE)
    {
      emits ("@begincode\n");
      parens = 0;
      declaration_engine (NULL, 0);
    }
  else
    {
      assert (state_is (CODE) && new_state == TEXT);

      emits ("@endcode format\n");
      piece_print_trailer ();
      emits ("\n\n");

      segment_select (NULL);
    }

  state_pop ();
  state_push (new_state);
}

/* Counts and returns the number of leading blanks in CP.  Tabs count
   as the equivalent number of spaces.  If END is non-null, points
   *END to the first non-blank character in CP. */
static int
indent_amount (const char *cp, const char **const end)
{
  int cnt = 0;
  while (*cp == ' ' || *cp == '\t')
    {
      if (*cp == '\t')
	cnt = (cnt + 8) / 8 * 8;
      else
	cnt++;
      cp++;
    }

  if (end != NULL)
    *end = (char *) cp;

  return cnt;
}

/* Pretty-prints CP to the output file, applying an appropriate amount
   of indentation.
   FLAGS and the return value work as for print(). */
static int
print_line (const char *cp, int flags)
{
  if (empty_string (cp))
    {
      blank++;
      return 0;
    }

  if (state_bottom (CODE))
    {
      int i;
      int indent = indent_amount (cp, &cp);

      if (state_is (CODE) && state_cnt () == 1)
	declaration_engine (cp, indent);

      if (blank)
	{
	  emits ("@blankline\n");
	  blank = 0;
	}

      if (!paste)
	{
	  for (i = 0; i < indent; i++)
	    emitc (' ');

	  emits ("@tabalign{}");
	  if (parens)
	    for (i = 0; i < parens; i++)
	      emits ("@wtab{}");
	  else if (indent != 0)
	    {
	      if (indent + indent_adjust < 0)
		error (SRC, _("Negative indentation %d."),
		       indent + indent_adjust);
	      else
		emitf ("@IND{%dem}", indent + indent_adjust);
	    }
	}
      else
	{
	  emits ("@tcr{");
	  for (i = 0; i < indent; i++)
	    emits ("@w{ }");
	  emitc ('}');

	  paste = 0;
	}
    }
  else
    flush_blank_lines ();

  return print (cp, flags);      
}

/* Flushes any accumulated blank lines to the output file. */
static void
flush_blank_lines () 
{
  for (; blank > 0; blank--) 
    emitc ('\n');
}

/* Pretty-prints CP to the output file without special handling for
   any leading spaces.
   FLAGS is the previous return value from this function in this
   context, or 0 if there is no context yet established. */
static int
print (const char *cp, int flags)
{
  /* FLAGS is used to bold the identifier following `enum', `struct',
     or `union'.  It is set to 1 if we saw one of these keywords but
     not yet a `{' or an identifier. */

  for (;;)
    {
      struct token token;
      cp = token_parse (cp, &token);

      switch (token.type)
	{
	case TOKEN_BEGIN_CONTROL:
	  emits ("@refcode{");
	  if (in_control == '<')
	    emits ("@asis{");
	  else
	    emits ("@t{");
	  break;

	case TOKEN_END_CONTROL:
	  emits ("},");
	  segment_print_number (segment_find (control_buf, 0));

	  emitc ('}');
	  break;

	case TOKEN_BEGIN_EMBED_CODE:
	case TOKEN_END_EMBED_CODE:
	  flags = 0;
	  break;

	case TOKEN_REPLACE:
	  emits ("@result{}");
	  break;

	case TOKEN_INC_INDENT:
	  indent_adjust += 2;
	  break;

	case TOKEN_DEC_INDENT:
	  indent_adjust -= 2;
	  break;

	case TOKEN_AT:
	  emits ("@@");
	  break;

	case TOKEN_SEMICOLON:
	  emitc (';');
	  break;

	case TOKEN_PIPE:
	  emits ("@math{|}");
	  break;

	case TOKEN_COND_NEWLINE:
	  /* Ignored newline when weaving. */
	  paste = 1;
	  break;

	case TOKEN_BEGIN_COMMENT:
	  emits ("/@value{AST}");
	  if (state_bottom (CODE))
	    {
	      for (; isspace ((unsigned char) *cp); cp++)
		emitc (*cp);
	      emits ("@cleartabs{}@wtab{}");
	      parens++;
	    }
	  break;

	case TOKEN_END_COMMENT:
	  if (state_bottom (CODE))
	    parens--;
	  emits ("@value{AST}/");
	  break;

	case TOKEN_PREPROCESSOR:
	  {
	    const char *next;

	    emitc ('#');
	    next = token_get (cp, &token);
	    while (token_space_p (&token))
	      next = token_get (next, &token);
	    if (token.type != TOKEN_ID)
	      continue;
	    cp = next;

	    emitf ("@b{%.*s}", (int) token.len, token.text);

	    if (token.len == 6 && !memcmp (token.text, "define", 6))
	      {
		for (;;)
		  {
		    next = token_get (cp, &token);
		    if (!token_space_p (&token))
		      break;
		    emitc (token.type);
		    cp = next;
		  }

		if (token.type == TOKEN_ID)
		  {
		    emits ("@cindex ");
		    print_identifier (token.text, token.len);
		    emits (" macro@c\n");
		  }
	      }
	    else if (token.len == 7 && !memcmp (token.text, "include", 7))
	      {
		int quote = 0;

		for (; *cp && *cp != '\n' && *cp != '|'; cp++)
		  switch (*cp)
		    {
		    case '<':
		      emits ("@value{LANG}");
		      break;
		    case '>':
		      emits ("@value{RANG}");
		      break;
		    case '"':
		      if (quote++)
			emits ("@value{RQUOTE}");
		      else
			emits ("@value{LQUOTE}");
		      break;
		    case '{':
		    case '}':
		      emitf ("@math{@%c}", *cp);
		      break;
		    default:
		      emitc (*cp);
		    }
	      }
	  }
	  break;

	case TOKEN_PSTRUCT_ELEM:
	  emits ("@value{RARR}");
	  break;

	case TOKEN_EQ:
	  emits ("@value{EQ}");
	  break;

	case TOKEN_NE:
	  emits ("@value{NE}");
	  break;

	case TOKEN_GE:
	  emits ("@value{GE}");
	  break;

	case TOKEN_LE:
	  emits ("@value{LE}");
	  break;

	case TOKEN_AND:
	  emits ("@value{AND}");
	  break;

	case TOKEN_OR:
	  emits ("@value{OR}");
	  break;

	case TOKEN_TIMES:
	  emits ("@value{TIMES}");
	  break;

	case TOKEN_PLUSPLUS:
	  emits ("@math{++}");
	  break;

	case TOKEN_MINUSMINUS:
	  emits ("@math{-}@math{-}");
	  break;

	case TOKEN_NEG:
	  emits ("@unaryminus{}");
	  break;

	case TOKEN_POS:
	  emits ("@unaryplus{}");
	  break;

	case TOKEN_QUOTED_STRING:
	  {
	    const char *cp;

	    emits ("@t{");
	    for (cp = token.text; cp < token.text + token.len; cp++)
              switch (*cp) 
                {
                case ' ':
		  emits ("@value{SP}");
                  break;

                case '-':
                  /* Prevent -- or --- ligature. */
                  if (cp + 1 < token.text + token.len && cp[1] == '-')
                    emits ("@asis{-}");
                  break;

                case '@':
                case '{':
                case '}':
                  emitc ('@');
                  /* Fall through. */
                default:
                  emitc (*cp);
                }
            
	    emitc ('}');
	  }
	  break;

	case TOKEN_HEX_INT:
	  emitf ("@t{%.*s}", (int) token.len, token.text);
	  break;

	case TOKEN_OCT_INT:
	  emitf ("@i{%.*s}", (int) token.len, token.text);
	  break;

	case TOKEN_NUMBER:
	  emitb (token.text, token.len);
	  break;

        case TOKEN_ELLIPSIS:
          emits ("@dots{}");
          break;

	case TOKEN_SCIENTIFIC:
	  {
	    const char *p = memchr (token.text, 'e', token.len);
	    assert (p != NULL);
	    emitf ("%.*s@exponent{%.*s}",
		   (int) (p - token.text), token.text,
		   (int) ((token.text + token.len) - (p + 1)), p + 1);
	  }
	  break;

	case TOKEN_ID:
	  if (state_is (CODE))
	    {
	      if (flags)
		{
		  emitf (STRUCT_TAG_STYLE "{%.*s}", (int) token.len, token.text);
		  flags = 0;
		}
	      else
		{
		  struct symbol *sym = print_identifier (token.text, token.len);
		  if (sym && (sym->kw_idx == KW_ENUM
			      || sym->kw_idx == KW_STRUCT
			      || sym->kw_idx == KW_UNION))
		    flags = 1;
		}
	    }
	  else
	    emitb (token.text, token.len);
	  break;

	case 0:
	  return flags;

	default:
	  assert (token.type > 0 && token.type <= UCHAR_MAX);

	  if (state_is (CODE))
	    {
	      switch (token.type)
		{
		case '{':
		  emits ("@math{@{}");
		  flags = 0;
		  break;
		case '}':
		  emits ("@math{@}}");
		  break;
		case '(':
		case '[':
		  emitc (token.type);
		  if (state_cnt () == 1)
		    emits ("@cleartabs{}@wtab{}");
		  parens++;
		  break;
		case ')':
		case ']':
		  emitc (token.type);
		  parens--;
		  break;
		case '*':
		  emits ("@value{AST}");
		  break;
		case '<':
		case '>':
		case '+':
		case '-':
		  emitf ("@math{%c}", token.type);
		  break;
#if 0
		case '!':
		  emits ("@value{INV}");
		  break;
#else
		case '|':
		  emits ("@math{|}");
		  break;
#endif
		case '\n':
		  if (state_cnt () == 1 || state_was (COMMENT))
		    emits ("@cr\n");
		  else
		    emitc (' ');
		  break;
		default:
		  emitc (token.type);
		}
	    }
	  else if (token.type == '\n'
		   && state_is (COMMENT)
		   && state_bottom (CODE))
	    emits ("@cr\n");
	  else if (state_is (CONTROL) && token.type == ',')
	    emits ("@value{COMMA}");
	  else
	    emitc (token.type);
	}
    }
}

/* Tangle substitutions. */

/* A stack of substitutions. */
struct tangle_subst
  {
    struct tangle_subst *next;	/* Next on the stack, or NULL at bottom. */
    char *src;			/* String that will be replaced. */
    char *dst;			/* Replacement. */
  };

/* Allocates and returns a new struct tangle_subst with `src' as SRC
   with length SRC_LEN and `dst' as DST with length DST_LEN.  The
   `next' member is set up to point to TOS. */
struct tangle_subst *
ts_push (struct tangle_subst *tos,
	 const char *src, size_t src_len,
	 const char *dst, size_t dst_len)
{
  struct tangle_subst *new = xmalloc (sizeof *new);
  new->src = xstrndup (src, src_len);
  new->dst = xstrndup (dst, dst_len);
  new->next = tos;
  return new;
}

/* Frees S and its members but not recursively. */
static void
ts_free (struct tangle_subst *s)
{
  free (s->src);
  free (s->dst);
  free (s);
}

/* Frees TOS and returns the next one in the chain. */
struct tangle_subst *
ts_pop (struct tangle_subst *tos)
{
  struct tangle_subst *next = tos->next;
  ts_free (tos);
  return next;
}

/* Tangle. */

/* Outputs #line directives and whitespace as necessary to make sure
   that the output file, which currently thinks it's at the location
   in LOC, ends up at the line in LINE->loc, and that there's
   indentation of *INDENT spaces.  *INDENT and LOC are updated to
   bring them in line with what's been output. */
static void
flush_whitespace (int *indent, struct line *line, struct loc *loc)
{
  if ((loc->ln != line->loc.ln || loc->fn != line->loc.fn) && opt_line)
    {
      if (loc->fn != line->loc.fn)
	emitf ("#line %d \"%s\"\n", line->loc.ln, line->loc.fn);
      else
	emitf ("#line %d\n", line->loc.ln);

      *loc = line->loc;
    }

#if 0
  for (; *indent >= 8; *indent -= 8)
    emitc ('\t');
#endif
  for (; *indent > 0; (*indent)--)
    emitc (' ');
}

/* Compares the LEN characters starting at A and at B
   case-insensitively and returns nonzero only if they differ. */
static int
mem_casecmp (const char *a, const char *b, size_t len)
{
  for (; len; a++, b++, len--)
    if (tolower ((unsigned char) *a) != tolower ((unsigned char) *b))
      return 1;

  return 0;
}

/* Returns zero if the first LEN characters at S contain at least one
   uppercase letter, nonzero otherwise. */
static int
no_upper (const char *s, size_t len)
{
  while (len--)
    if (isupper ((unsigned char) *s))
      return 0;
  return 1;
}

/* Returns zero if the first LEN characters at S contain at least one
   lowercase letter, nonzero otherwise. */
static int
no_lower (const char *s, size_t len)
{
  while (len--)
    if (islower ((unsigned char) *s))
      return 0;
  return 1;
}

/* Emits identifier TEXT, of length LEN, to the tangled output stream,
   applying the substitutions in S. */
static void
ts_emit (const char *text, size_t len, struct tangle_subst *s)
{
  char *cur_text = (char *) text;
  size_t cur_len = len;

  for (; s != NULL; s = s->next)
    {
      const size_t src_len = strlen (s->src);
      const size_t dst_len = strlen (s->dst);
      char *next_text, *d;
      const char *p;
      size_t next_len;
      size_t n_upper;

      if (cur_len < src_len || mem_casecmp (cur_text, s->src, src_len))
	continue;

      next_len = dst_len + (cur_len - src_len);
      d = next_text = xmalloc (next_len + 1);

      if (!no_upper (s->src, src_len)
	  || !no_upper (s->dst, dst_len)
	  || no_upper (cur_text, cur_len))
	n_upper = 0;
      else if (no_lower (cur_text, cur_len))
	n_upper = dst_len;
      else
	n_upper = 1;

      for (p = s->dst; *p; p++)
	if (n_upper > 0)
	  {
	    *d++ = toupper ((unsigned char) *p);
	    n_upper--;
	  }
	else
	  *d++ = *p;
      memcpy (d, cur_text + src_len, cur_len - src_len);
      d[cur_len - src_len] = '\0';

      if (cur_text != text)
	free (cur_text);
      cur_text = next_text;
      cur_len = next_len;
    }

  emitb (cur_text, cur_len);
  if (cur_text != text)
    free (cur_text);
}

/* Reads tokens from string P until one of them is not whitespace.
   (End of string is not whitespace.)  Stores the token into TOKEN and
   returns a pointer into P to the start of the next token after
   TOKEN. */
static const char *
ts_get_token_no_ws (const char *p, struct token *token)
{
  for (;;)
    {
      p = token_get (p, token);
      if (!token_space_p (token))
	return p;
    }
}

/* Checks that the next non-whitespace token in *P is C.
   *P is adjusted to point past C.
   If the next token is not C, emits the error message MESSAGE with
   associated location LOC.
   Returns nonzero only if the token was really C. */
static int
ts_expect (const char **p, int c, const char *message, struct loc *loc)
{
  struct token token;
  *p = ts_get_token_no_ws (*p, &token);
  if (token.type == c)
    return 1;

  error (0, message, loc->fn, loc->fn);
  return 0;
}

/* Parses from TEXT a tangle substitution of the form "; SRC => DST"
   repeated zero or more times.
   Any parsed substitutions are prepended to S and the first one is
   returned.
   LOC is used for error messages, and *CNT is set to the number of
   substitutions parsed. */
static struct tangle_subst *
ts_parse (struct tangle_subst *s, const char *text,
	  struct loc *loc, int *cnt)
{
  const char *p;

  *cnt = 0;

  p = strchr (text, ';');
  if (p == NULL)
    return s;

  while (*p != '\0')
    {
      struct token src, dst;

      if (!ts_expect (&p, ';', "%s:%d: `;' or `@>' expected", loc))
	goto error;

      p = ts_get_token_no_ws (p, &src);
      if (src.type != TOKEN_ID)
	{
	  error (0, _("%s:%d: Identifier expected after `;'"),
		 loc->fn, loc->ln);
	  goto error;
	}

      if (!ts_expect (&p, '=', "%s:%d: `=>' expected", loc)
	  || !ts_expect (&p, '>', "%s:%d: `=>' expected", loc))
	goto error;

      p = ts_get_token_no_ws (p, &dst);
      if (dst.type != TOKEN_ID)
	{
	  error (0, _("%s:%d: Identifier expected after `=>'"),
		 loc->fn, loc->ln);
	  goto error;
	}

      s = ts_push (s, src.text, src.len, dst.text, dst.len);
      *cnt += 1;
    }
  return s;

 error:
  for (; *cnt > 0; *cnt -= 1)
    s = ts_pop (s);
  return s;
}

/* Prints SEGMENT to the tangle output.
   The segment should be indented INDENT spaces.
   LOC is the current output location as seen by C's preprocessor.
   SUBST is the set of tangle substitutions to apply. */
static void
tangle_print (struct segment *segment, int indent, struct loc *loc,
	      struct tangle_subst *subst)
{
  struct line *line;

  segment->use++;
  for (line = segment->c_head; line != NULL; line = line->next)
    {
      const char *cp;
      int indentation = indent_amount (line->text, &cp) + indent;
      int i = indentation;

      loc->ln++;
      for (;;)
	{
	  struct token token;
	  cp = token_get (cp, &token);

	  if (in_control && token.type != TOKEN_END_CONTROL)
	    {
	      add_control (token.text, token.len);
	      continue;
	    }

	  switch (token.type)
	    {
	    case 0:
	      goto next_line;

	    case TOKEN_COND_NEWLINE:
	    case '\n':
	      emitc ('\n');
	      break;

	    case TOKEN_BEGIN_CONTROL:
	      if (!in_control)
		{
		  state_push (CONTROL);
		  in_control = 1;
		  control_len = 0;
		  control_space = 0;
		}
	      else
		error (SRC, _("Can't nest control texts."));
	      break;

	    case TOKEN_SEMICOLON:
	    case TOKEN_INC_INDENT:
	    case TOKEN_DEC_INDENT:
	      /* Ignored. */
	      break;

	    case TOKEN_PIPE:
	      flush_whitespace (&i, line, loc);
	      emitc ('|');
	      break;

	    case TOKEN_AT:
	      flush_whitespace (&i, line, loc);
	      emitc ('@');
	      break;

	    case TOKEN_END_CONTROL:
	      if (control_len > 0)
		control_buf[control_len] = '\0';
	      else
		{
		  error (SRC, _("Empty control text."));
		  continue;
		}

	      if (in_control)
		in_control = 0;
	      else
		error (SRC, _("@> not inside control text."));
	      while (!state_is (CONTROL))
		{
		  error (SRC, _("Missing closing within control text."));
		  state_pop ();
		}
	      state_pop ();

	      {
		struct segment *segment = segment_find (control_buf, 0);
		struct tangle_subst *s;
		int cnt;

		s = ts_parse (subst, control_buf, &line->loc, &cnt);
		if (segment != NULL)
		  tangle_print (segment, indentation, loc,
				s != NULL ? s : subst);
		else
		  {
		    emitf ("/* Undefined segment: %s. */\n", control_buf);
		    error (0, _("%s:%d: segment `%s' undefined"),
			   line->loc.fn, line->loc.ln, control_buf);
		  }
		for (; cnt > 0; cnt--)
		  s = ts_pop (s);
		assert (s == subst);
	      }

	      {
		const char *p = cp;

		for (;;)
		  {
		    p = token_get (p, &token);
		    if (token.type == 0)
		      goto next_line;
		    else if (token.type != TOKEN_COND_NEWLINE
			     && token.type != TOKEN_INC_INDENT
			     && token.type != TOKEN_DEC_INDENT
			     && !token_space_p (&token))
		      break;
		  }
	      }

	      break;

	    case TOKEN_ID:
	      flush_whitespace (&i, line, loc);
	      ts_emit (token.text, token.len, subst);
	      break;

	    case ' ':
	      i++;
	      break;

	    case '\t':
	      /* FIXME. */
	      i = (i + 8) / 8 * 8;
	      break;

	    default:
	      flush_whitespace (&i, line, loc);
	      emitb (token.text, token.len);
	      break;
	    }
	}
    next_line:;
    }
}

/* Creates a file named FILENAME
   and writes the tangled version of SEGMENT to it.
   If PRINT_HEADER is nonzero, begins the file with a message
   saying that it was produced by texiweb. */
static void
tangle_segment_to_file (struct segment *segment, const char *filename,
                        int print_header) 
{
  out_file = fopen (filename, "w");
  if (out_file == NULL)
    error (FTL, _("Opening %s for writing: %s"), filename, strerror (errno));

  if (print_header) 
    fprintf (out_file, "/* Produced by texiweb from %s. */\n\n", in_file_name);
  
  state_init ();
  state_push (CODE); 
  {
    struct loc loc;
    
    loc.fn = filename;
    loc.ln = 0;
    tangle_print (segment, 0, &loc, NULL);
  }
  state_pop ();
}

/* Runs a tangle pass. */
static void
tangle (void)
{
  size_t line_size = 0;
  char *line = NULL;

  struct segment *s;

  int blank_line = 0;

  state_init ();
  state_push (TEXT);

  input_start_pass ();
  while (input_read_line (&line, &line_size))
    {
      char cmd[CMD_LEN_MAX + 1];

      /* Keep track of transitions into and out of code segments. */
      if (parse_at_cmd (line, cmd))
	{
	  if (cmd[0] == '\0' || !strcmp (cmd, "node"))
	    {
	      segment_select (NULL);
	      blank_line = 0;
	      continue;
	    }
          else if (!strcmp (cmd, "setheaderfile")
                   || !strcmp (cmd, "setanswerfile")) 
            {
              char **fn;
              char *bp, *ep;
              if (!find_argument (line, &bp, &ep))
                continue;
              if (!strcmp (cmd, "setheaderfile"))
                fn = &header_file_name;
              else
                fn = &answer_file_name;
              if (*fn != NULL)
                continue;
              *fn = xstrndup (bp, ep - bp);
            }
          else
	    {
              int operation;
              int is_file;
	      char *control_text;

              control_text = segment_definition_line (line,
                                                      &operation, &is_file);
	      if (control_text != NULL)
		{
		  struct segment *segment = segment_find (control_text, 0);
		  if (segment == NULL)
		    {
		      segment = segment_find (control_text, 1);
                      segment->is_file = is_file;
		      blank_line = 0;
		    }
		  else
		    blank_line = 0;

		  segment_select (segment);
		  free (control_text);
		  continue;
		}
	    }
	}

      /* Add this line of code to the code segment (if we're inside
         one). */
      if (blank_line)
	{
	  blank_line = 0;
	  segment_add_line ("\n");
	}
      segment_add_line (line);
    }
  input_end_pass ();
  state_pop ();
  free (line);

  for (s = segment_first; s != NULL; s = s->next)
    if (!print_all_segments) 
      {
        if (!s->is_file)
          continue;
        
        if (filenames_only)
          puts (s->name);
        else if (out_file_name == NULL || !strcmp (s->name, out_file_name))
          tangle_segment_to_file (s, s->name, 1); 
      }
    else 
      {
        char *basename, *filename;
        
        if (!strcmp (s->name, "Anonymous"))
          continue;

        basename = segment_make_filename (s);
        filename = xmalloc (strlen (out_file_name) + strlen (basename) + 64);
        sprintf (filename, "%s/%s", out_file_name, basename);

        tangle_segment_to_file (s, filename, 0);

        free (filename);
        free (basename);
      }
  
  if (print_unused)
    for (s = segment_first; s != NULL; s = s->next)
      if (s->use == 0 && strcmp (s->name, "Anonymous"))
        {
          if (s->c_head != NULL)
            printf ("%s:%d: ", s->c_head->loc.fn, s->c_head->loc.ln);

          printf ("segment `%s' not included in any output file\n", s->name);
        }
}

/* Declaration parsing engine. */

/* Parser states. */
enum state_name
  {
    STATE_START,
    STATE_PARSE,
    STATE_PARSE_ERROR
  };

/* C declarator types. */
enum type
  {
    TYPE_BASIC,
    TYPE_POINTER,
    TYPE_ARRAY,
    TYPE_FUNCTION
  };

/* Maximum height of LR parser stack. */
#define STACK_HEIGHT 256

/* Current state of declaration engine. */
struct engine_state
  {
    enum state_name state;	/* Current state. */

    char *last_id;		/* Last identifier seen, other than a tag. */
    char *save_id;		/* Saved identifier. */

    /* Lexing structs and their tags. */
    int last_was_struct;	/* Hint to lexer. */
    int struct_type;		/* KW_STRUCT, KW_UNION, or KW_ENUM. */
    char *tag;			/* struct/union/enum tag. */

    int typedefing;		/* `typedef' specified. */
    enum type type;		/* Type of this declarator. */
    enum type last_type;	/* Type of previous declarator. */

    /* LR parser. */
    int stack_cnt;		/* Stack height. */
    int stack[STACK_HEIGHT];	/* Stack contents. */
  };

/* Initializes declaration engine S. */
static void
init_engine_state (struct engine_state *s)
{
  s->state = STATE_START;
  free (s->last_id);
  free (s->save_id);
  s->last_id = s->save_id = NULL;

  s->last_was_struct = 0;
  free (s->tag);
  s->tag = NULL;

  s->typedefing = 0;
  s->type = s->last_type = TYPE_BASIC;

  s->stack_cnt = 1;
  s->stack[0] = 0;
}

/* Nonzero value enables LR parser debugging. */
static int debug_parser = 0;

/* LR parser.  ENGINE is the engine state and TOKEN is an input token.
   Returns nonzero for successful parsing, zero on a parse error. */
static int
lr_engine (struct engine_state *engine, struct token *token)
{
  /* The following parser generated by slr.c. */

  /* Actions used in action_table[][] entries. */
  enum
    {
      err,	/* Error. */
      acc,	/* Accept. */

      /* Shift actions. */
      s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15,
      s16, s17, s18, s19, s20, s21, s22, s23, s24, s25, s26, s27, s28, s29,
      s30, s31, s32, s33, s34, s35, s36, s37, s38, s39, s40, s41, s42, s43,
      s44, s45, s46, s47, s48, s49, s50, s51, s52, s53, s54, s55, s56, s57,
      s58, s59, s60, s61, s62,

      /* Reduce actions. */
      r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15,
      r16, r17, r18, r19, r20, r21, r22, r23, r24, r25, r26, r27, r28, r29,
      r30, r31, r32, r33, r34, r35, r36, r37, r38, r39, r40,

      n_states = 63,
      n_terminals = 16,
      n_nonterminals = 15,
      n_reductions = 40
    };

  /* Symbolic token names used in parse_table[][] second index. */
  enum
    {
      lex_lparen,               /* ( */
      lex_rparen,               /* ) */
      lex_pointer,              /* * */
      lex_comma,                /* , */
      lex_typedef,              /* 1 */
      lex_type_name,            /* 2 */
      lex_struct,               /* 3 */
      lex_const,                /* 4 */
      lex_semicolon,            /* ; */
      lex_lbrack,               /* [ */
      lex_rbrack,               /* ] */
      lex_identifier,           /* i */
      lex_other,                /* o */
      lex_lbrace,               /* { */
      lex_rbrace,               /* } */
      lex_stop                  /* $ */
    };

  /* Action table.  This is action[][] from Fig. 4.30, "LR parsing
     program", in Aho, Sethi, and Ullman. */
  static const unsigned char action_table[n_states][n_terminals] =
    {
      /*          (   )   *   ,   1   2   3   4   ;   [   ]   i   o   {   }   $ */
      /*  0 */ {  0,  0,  0,  0, s1, s2, s3, s4,  0,  0,  0,  0,  0,  0,  0,  0},
      /*  1 */ { r6,  0, r6,  0, r6, r6, r6, r6,  0,  0,  0, r6,  0,  0,  0,  0},
      /*  2 */ { r7,  0, r7,  0, r7, r7, r7, r7,  0,  0,  0, r7,  0,  0,  0,  0},
      /*  3 */ {  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, s8,  0,  0,  0,  0},
      /*  4 */ { r9,  0, r9,  0, r9, r9, r9, r9,  0,  0,  0, r9,  0,  0,  0,  0},
      /*  5 */ { s9,  0,s10,  0,  0,  0,  0,  0,  0,  0,  0,s15,  0,  0,  0,  0},
      /*  6 */ {  0,  0,  0,  0, s1, s2, s3, s4,  0,  0,  0,  0,  0,  0,  0,acc},
      /*  7 */ { r5,  0, r5,  0, s1, s2, s3, s4,  0,  0,  0, r5,  0,  0,  0,  0},
      /*  8 */ {r11,  0,r11,  0,r11,r11,r11,r11,  0,  0,  0,r11,  0,s20,  0,  0},
      /*  9 */ { s9,  0,s10,  0,  0,  0,  0,  0,  0,  0,  0,s15,  0,  0,  0,  0},
      /* 10 */ {r18,  0,r18,  0,  0,  0,  0,r18,  0,  0,  0,r18,  0,  0,  0,  0},
      /* 11 */ {  0,  0,  0,  0,  0,  0,  0,  0,s23,  0,  0,  0,  0,s26,  0,  0},
      /* 12 */ {s27,r16,  0,r16,  0,  0,  0,  0,r16,s28,  0,  0,  0,r16,  0,  0},
      /* 13 */ {r19,r19,  0,r19,  0,  0,  0,  0,r19,r19,  0,  0,  0,r19,  0,  0},
      /* 14 */ {  0,  0,  0,s29,  0,  0,  0,  0,r14,  0,  0,  0,  0,r14,  0,  0},
      /* 15 */ {r23,r23,  0,r23,  0,  0,  0,  0,r23,r23,  0,  0,  0,r23,  0,  0},
      /* 16 */ { s9,  0,s10,  0,  0,  0,  0,  0,  0,  0,  0,s15,  0,  0,  0,  0},
      /* 17 */ { r4,  0, r4,  0,  0,  0,  0,  0,  0,  0,  0, r4,  0,  0,  0,  0},
      /* 18 */ { r8,  0, r8,  0, r8, r8, r8, r8,  0,  0,  0, r8,  0,  0,  0,  0},
      /* 19 */ {r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,  0},
      /* 20 */ {r12,  0,r12,r12,r12,r12,r12,r12,r12,r12,  0,r12,r12,r12,r12,  0},
      /* 21 */ {  0,s32,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0},
      /* 22 */ { s9,  0,s10,  0,  0,  0,  0,s33,  0,  0,  0,s15,  0,  0,  0,  0},
      /* 23 */ {  0,  0,  0,  0,r38,r38,r38,r38,  0,  0,  0,  0,  0,  0,  0,r38},
      /* 24 */ {  0,  0,  0,  0, r2, r2, r2, r2,  0,  0,  0,  0,  0,  0,  0, r2},
      /* 25 */ {r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,  0},
      /* 26 */ {r40,  0,r40,r40,r40,r40,r40,r40,r40,r40,  0,r40,r40,r40,r40,  0},
      /* 27 */ {r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,  0},
      /* 28 */ {r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,  0},
      /* 29 */ { s9,  0,s10,  0,  0,  0,  0,  0,  0,  0,  0,s15,  0,  0,  0,  0},
      /* 30 */ {  0,  0,  0,  0,  0,  0,  0,  0,s23,  0,  0,  0,  0,s26,  0,  0},
      /* 31 */ {s40,  0,s41,s42,s43,s44,s45,s46,s47,s48,  0,s50,s51,s52,s53,  0},
      /* 32 */ {r20,r20,  0,r20,  0,  0,  0,  0,r20,r20,  0,  0,  0,r20,  0,  0},
      /* 33 */ {r17,  0,r17,  0,  0,  0,  0,r17,  0,  0,  0,r17,  0,  0,  0,  0},
      /* 34 */ {  0,r15,  0,r15,  0,  0,  0,  0,r15,  0,  0,  0,  0,r15,  0,  0},
      /* 35 */ {s40,  0,s41,s42,s43,s44,s45,s46,s47,s48,  0,s50,s51,s52,s54,  0},
      /* 36 */ {s40,s55,s41,s42,s43,s44,s45,s46,s47,s48,  0,s50,s51,s52,  0,  0},
      /* 37 */ {s40,  0,s41,s42,s43,s44,s45,s46,s47,s48,s56,s50,s51,s52,  0,  0},
      /* 38 */ {  0,  0,  0,  0,  0,  0,  0,  0,r13,  0,  0,  0,  0,r13,  0,  0},
      /* 39 */ {  0,  0,  0,  0, r3, r3, r3, r3,  0,  0,  0,  0,  0,  0,  0, r3},
      /* 40 */ {r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,  0},
      /* 41 */ {r36,r36,r36,r36,r36,r36,r36,r36,r36,r36,r36,r36,r36,r36,r36,  0},
      /* 42 */ {r35,r35,r35,r35,r35,r35,r35,r35,r35,r35,r35,r35,r35,r35,r35,  0},
      /* 43 */ {r31,r31,r31,r31,r31,r31,r31,r31,r31,r31,r31,r31,r31,r31,r31,  0},
      /* 44 */ {r32,r32,r32,r32,r32,r32,r32,r32,r32,r32,r32,r32,r32,r32,r32,  0},
      /* 45 */ {r33,r33,r33,r33,r33,r33,r33,r33,r33,r33,r33,r33,r33,r33,r33,  0},
      /* 46 */ {r34,r34,r34,r34,r34,r34,r34,r34,r34,r34,r34,r34,r34,r34,r34,  0},
      /* 47 */ {r37,r37,r37,r37,r37,r37,r37,r37,r37,r37,r37,r37,r37,r37,r37,  0},
      /* 48 */ {r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,  0},
      /* 49 */ {r25,r25,r25,r25,r25,r25,r25,r25,r25,r25,r25,r25,r25,r25,r25,  0},
      /* 50 */ {r29,r29,r29,r29,r29,r29,r29,r29,r29,r29,r29,r29,r29,r29,r29,  0},
      /* 51 */ {r30,r30,r30,r30,r30,r30,r30,r30,r30,r30,r30,r30,r30,r30,r30,  0},
      /* 52 */ {r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,r24,  0},
      /* 53 */ {r10,  0,r10,  0,r10,r10,r10,r10,  0,  0,  0,r10,  0,  0,  0,  0},
      /* 54 */ {  0,  0,  0,  0,r39,r39,r39,r39,  0,  0,  0,  0,  0,  0,  0,r39},
      /* 55 */ {r22,r22,  0,r22,  0,  0,  0,  0,r22,r22,  0,  0,  0,r22,  0,  0},
      /* 56 */ {r21,r21,  0,r21,  0,  0,  0,  0,r21,r21,  0,  0,  0,r21,  0,  0},
      /* 57 */ {s40,s60,s41,s42,s43,s44,s45,s46,s47,s48,  0,s50,s51,s52,  0,  0},
      /* 58 */ {s40,  0,s41,s42,s43,s44,s45,s46,s47,s48,s61,s50,s51,s52,  0,  0},
      /* 59 */ {s40,  0,s41,s42,s43,s44,s45,s46,s47,s48,  0,s50,s51,s52,s62,  0},
      /* 60 */ {r26,r26,r26,r26,r26,r26,r26,r26,r26,r26,r26,r26,r26,r26,r26,  0},
      /* 61 */ {r28,r28,r28,r28,r28,r28,r28,r28,r28,r28,r28,r28,r28,r28,r28,  0},
      /* 62 */ {r27,r27,r27,r27,r27,r27,r27,r27,r27,r27,r27,r27,r27,r27,r27,  0},
    };

  /* Go to table.  This is goto[][] from Fig. 4.30, "LR parsing
     program", in Aho, Sethi, and Ullman. */
  static const unsigned char goto_table[n_states][n_nonterminals] =
    {
      /*         B  D  E  I  Q  S  T  a  b  d  e  s  t  x  y */
      /*  0 */ { 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 6, 7, 0, 0},
      /*  1 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /*  2 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /*  3 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /*  4 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /*  5 */ { 0,11,12,13, 0, 0, 0, 0, 0,14, 0, 0, 0, 0, 0},
      /*  6 */ { 0, 0, 0, 0, 0, 0,16, 0, 0, 0, 0, 0, 7, 0, 0},
      /*  7 */ { 0, 0, 0, 0, 0, 0,17, 0, 0, 0, 0, 0, 7, 0, 0},
      /*  8 */ {18, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,19, 0},
      /*  9 */ { 0, 0,12,13, 0, 0, 0, 0, 0,21, 0, 0, 0, 0, 0},
      /* 10 */ { 0, 0, 0, 0,22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 11 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,24, 0, 0, 0,25},
      /* 12 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 13 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 14 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 15 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 16 */ { 0,30,12,13, 0, 0, 0, 0, 0,14, 0, 0, 0, 0, 0},
      /* 17 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 18 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 19 */ { 0, 0, 0, 0, 0, 0, 0,31, 0, 0, 0, 0, 0, 0, 0},
      /* 20 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 21 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 22 */ { 0, 0,12,13, 0, 0, 0, 0, 0,34, 0, 0, 0, 0, 0},
      /* 23 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 24 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 25 */ { 0, 0, 0, 0, 0, 0, 0,35, 0, 0, 0, 0, 0, 0, 0},
      /* 26 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 27 */ { 0, 0, 0, 0, 0, 0, 0,36, 0, 0, 0, 0, 0, 0, 0},
      /* 28 */ { 0, 0, 0, 0, 0, 0, 0,37, 0, 0, 0, 0, 0, 0, 0},
      /* 29 */ { 0,38,12,13, 0, 0, 0, 0, 0,14, 0, 0, 0, 0, 0},
      /* 30 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,39, 0, 0, 0,25},
      /* 31 */ { 0, 0, 0, 0, 0, 0, 0, 0,49, 0, 0, 0, 0, 0, 0},
      /* 32 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 33 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 34 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 35 */ { 0, 0, 0, 0, 0, 0, 0, 0,49, 0, 0, 0, 0, 0, 0},
      /* 36 */ { 0, 0, 0, 0, 0, 0, 0, 0,49, 0, 0, 0, 0, 0, 0},
      /* 37 */ { 0, 0, 0, 0, 0, 0, 0, 0,49, 0, 0, 0, 0, 0, 0},
      /* 38 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 39 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 40 */ { 0, 0, 0, 0, 0, 0, 0,57, 0, 0, 0, 0, 0, 0, 0},
      /* 41 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 42 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 43 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 44 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 45 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 46 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 47 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 48 */ { 0, 0, 0, 0, 0, 0, 0,58, 0, 0, 0, 0, 0, 0, 0},
      /* 49 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 50 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 51 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 52 */ { 0, 0, 0, 0, 0, 0, 0,59, 0, 0, 0, 0, 0, 0, 0},
      /* 53 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 54 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 55 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 56 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 57 */ { 0, 0, 0, 0, 0, 0, 0, 0,49, 0, 0, 0, 0, 0, 0},
      /* 58 */ { 0, 0, 0, 0, 0, 0, 0, 0,49, 0, 0, 0, 0, 0, 0},
      /* 59 */ { 0, 0, 0, 0, 0, 0, 0, 0,49, 0, 0, 0, 0, 0, 0},
      /* 60 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 61 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      /* 62 */ { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    };

  /* Reduction rule symbolic names (reduce_table[][2]). */
  enum
    {
      reduce_null,
      reduce_array,
      reduce_declaration,
      reduce_declarator,
      reduce_function,
      reduce_function_definition,
      reduce_identifier,
      reduce_pointer,
      reduce_struct_definition,
      reduce_typedef
    };

  /* Reduction table.  First index is reduction number, from
     parse_table[][] above.  Second index is as follows:

     reduce_table[r][0]: Number of grammar symbols on right side of
     production.

     reduce_table[r][1]: Second index into goto[][] array, corresponding
     to the left side of the production.

     reduce_table[r][2]: User-specified symbolic name for this
     production. */
  static const unsigned char reduce_table[n_reductions][3] =
    {
      {  1,  5, reduce_null                   }, /* S=s */
      {  3, 11, reduce_declaration            }, /* s=TDe */
      {  4, 11, reduce_declaration            }, /* s=sTDe */
      {  2,  6, reduce_null                   }, /* T=tT */
      {  1,  6, reduce_null                   }, /* T=t */
      {  1, 12, reduce_typedef                }, /* t=1 */
      {  1, 12, reduce_null                   }, /* t=2 */
      {  3, 12, reduce_null                   }, /* t=3iB */
      {  1, 12, reduce_null                   }, /* t=4 */
      {  3,  0, reduce_null                   }, /* B=xa} */
      {  0,  0, reduce_null                   }, /* B= */
      {  1, 13, reduce_struct_definition      }, /* x={ */
      {  3,  1, reduce_declarator             }, /* D=d,D */
      {  1,  1, reduce_declarator             }, /* D=d */
      {  3,  9, reduce_pointer                }, /* d=*Qd */
      {  1,  9, reduce_null                   }, /* d=E */
      {  2,  4, reduce_null                   }, /* Q=Q4 */
      {  0,  4, reduce_null                   }, /* Q= */
      {  1,  2, reduce_null                   }, /* E=I */
      {  3,  2, reduce_null                   }, /* E=(d) */
      {  4,  2, reduce_array                  }, /* E=E[a] */
      {  4,  2, reduce_function               }, /* E=E(a) */
      {  1,  3, reduce_identifier             }, /* I=i */
      {  0,  7, reduce_null                   }, /* a= */
      {  2,  7, reduce_null                   }, /* a=ab */
      {  3,  8, reduce_null                   }, /* b=(a) */
      {  3,  8, reduce_null                   }, /* b={a} */
      {  3,  8, reduce_null                   }, /* b=[a] */
      {  1,  8, reduce_null                   }, /* b=i */
      {  1,  8, reduce_null                   }, /* b=o */
      {  1,  8, reduce_null                   }, /* b=1 */
      {  1,  8, reduce_null                   }, /* b=2 */
      {  1,  8, reduce_null                   }, /* b=3 */
      {  1,  8, reduce_null                   }, /* b=4 */
      {  1,  8, reduce_null                   }, /* b=, */
      {  1,  8, reduce_null                   }, /* b=* */
      {  1,  8, reduce_null                   }, /* b=; */
      {  1, 10, reduce_null                   }, /* e=; */
      {  3, 10, reduce_null                   }, /* e=ya} */
      {  1, 14, reduce_function_definition    }, /* y={ */
    };

  /* LR token type. */
  int a;

  /* Translate a struct token into `a', the token value expected by
     the LR parsing tables. */
  switch (token->type)
    {
    case '{':
      a = lex_lbrace;
      break;

    case '}':
      a = lex_rbrace;
      break;

    case ',':
      a = lex_comma;
      break;

    case '*':
      a = lex_pointer;
      break;

    case '(':
      a = lex_lparen;
      break;

    case ')':
      a = lex_rparen;
      break;

    case '[':
      a = lex_lbrack;
      break;

    case ']':
      a = lex_rbrack;
      break;

    case ';':
      a = lex_semicolon;
      break;

    case TOKEN_ID:
      {
	struct symbol *symbol = symbol_find (token->text, token->len, 0);

	switch (symbol ? symbol->kw_idx : -1)
	  {
	  case KW_TYPEDEF:
	    a = lex_typedef;
	    break;

	  case KW_EXTERN: case KW_STATIC: case KW_AUTO: case KW_REGISTER:
	  case KW_VOID: case KW_CHAR: case KW_SHORT: case KW_INT:
	  case KW_LONG: case KW_FLOAT: case KW_DOUBLE:
	  case KW_SIGNED: case KW_UNSIGNED:
	    a = lex_type_name;
	    break;

	  case KW_STRUCT: case KW_UNION: case KW_ENUM:
	    a = lex_struct;
	    engine->struct_type = symbol->kw_idx;
	    break;

	  case KW_CONST: case KW_VOLATILE:
	    a = lex_const;
	    break;

	  case -1:
	    if (symbol != NULL && symbol->is_typedef
		&& !engine->last_was_struct)
	      a = lex_type_name;
	    else
	      a = lex_identifier;

	    if (engine->last_was_struct)
	      {
		free (engine->tag);
		engine->tag = xstrndup (token->text, token->len);
	      }
	    else
	      {
		free (engine->last_id);
		engine->last_id = xstrndup (token->text, token->len);
	      }
	    break;

	  default:
	    a = lex_other;
	    break;
	  }
      }
      break;

    default:
      a = lex_other;
      break;
    }
  engine->last_was_struct = (a == lex_struct);

  /* Algorithm from Fig. 4.30, p. 219, of Aho, Sethi, and Ullman,
     _Compilers: Principles, Techniques, and Tools_.  */
  assert (engine->stack_cnt > 0);
  for (;;)
    {
      int s = engine->stack[engine->stack_cnt - 1];
      int action = action_table[s][a];

      if (debug_parser)
	printf ("%d: ", s);
      if (action >= s0 && action < s0 + n_states)
	{
	  if (debug_parser)
	    printf ("s%d", action - s0);
	  if (engine->stack_cnt >= STACK_HEIGHT)
	    return 0;
	  engine->stack[engine->stack_cnt++] = action - s0;
	  return 1;
	}
      else if (action == acc)
	{
	  if (debug_parser)
	    printf ("accepted!");
	  return 1;
	}
      else if (action == err)
	{
	  if (debug_parser)
	    printf ("error!");
	  return 0;
	}
      else
	{
	  int reduction, n_pop, A;
	  int sprime;

	  reduction = action - r1;
	  assert (reduction >= 0 && reduction < n_reductions);
	  if (debug_parser)
	    printf ("r%d,", reduction);

	  n_pop = reduce_table[reduction][0];
	  A = reduce_table[reduction][1];

	  engine->stack_cnt -= n_pop;
	  assert (engine->stack_cnt > 0);

	  sprime = engine->stack[engine->stack_cnt - 1];
	  if (debug_parser)
	    printf ("g%d ", goto_table[sprime][A]);
	  engine->stack[engine->stack_cnt++] = goto_table[sprime][A];

	  switch (reduce_table[reduction][2])
	    {
	    case reduce_array:
	      if (engine->type == TYPE_BASIC)
		engine->type = TYPE_ARRAY;
	      break;

	    case reduce_declaration:
	      engine->typedefing = 0;
	      engine->type = engine->last_type = TYPE_BASIC;
	      break;

	    case reduce_declarator:
	      assert (engine->save_id != NULL);
	      if (engine->typedefing)
		{
		  symbol_find (engine->save_id,
			       strlen (engine->save_id), 1)->is_typedef = 1;
		  emitf ("@cindex " TYPEDEF_STYLE "{%s} type\n",
			 engine->save_id);
		}
	      else
		{
		  if (engine->type == TYPE_BASIC || engine->type == TYPE_POINTER)
		    emitf ("@cindex @i{%s} %s\n", engine->save_id, _("variable"));
		  else if (engine->type == TYPE_ARRAY)
		    emitf ("@cindex @i{%s} %s\n", engine->save_id, _("array"));
		}

	      engine->last_type = engine->type;
	      engine->type = TYPE_BASIC;

	      break;

	    case reduce_function:
	      if (engine->type == TYPE_BASIC)
		engine->type = TYPE_FUNCTION;
	      break;

	    case reduce_function_definition:
	      if (debug_parser)
		printf ("Reducing function!\n");
	      if (engine->last_type == TYPE_FUNCTION)
		emitf ("@cindex @i{%s} %s\n", engine->save_id, _("function"));
	      break;

	    case reduce_identifier:
	      free (engine->save_id);
	      engine->save_id = engine->last_id;
	      engine->last_id = NULL;
	      break;

	    case reduce_null:
	      /* Uninteresting reduction: nothing to do. */
	      break;

	    case reduce_pointer:
	      if (engine->type == TYPE_BASIC)
		engine->type = TYPE_POINTER;
	      break;

	    case reduce_struct_definition:
	      {
		const char *struct_name;

		if (engine->struct_type == KW_STRUCT)
		  struct_name = "structure";
		else if (engine->struct_type == KW_UNION)
		  struct_name = "union";
		else
		  {
		    assert (engine->struct_type == KW_ENUM);
		    struct_name = "enumeration";
		  }

		assert (engine->tag != NULL);
		emitf ("@cindex @i{%s} %s\n", engine->tag, struct_name);
	      }
	      break;

	    case reduce_typedef:
	      engine->typedefing = 1;
	      break;

	    default:
	      assert (0);
	    }
	}
    }
}

/* Checks for declarations on the line of code that starts at CP.
   Leading blanks have been stripped already; INDENT is the equivalent
   number of spaces that were removed.
   This function maintains internal state.  To clear this state, call
   it with a null pointer for CP. */
static void
declaration_engine (const char *cp, int indent)
{
  static struct engine_state s;
  struct token token;

  if (cp == NULL)
    {
      if (debug_parser)
	printf ("\n\n--%s:%d--\n", in_file->name, in_file->line);
      init_engine_state (&s);
      return;
    }

  if (*cp == '#')
    return;

  for (;;)
    {
      cp = token_get (cp, &token);
      if (token.type == '\0'
	  || token.type == TOKEN_COND_NEWLINE
	  || token.type == TOKEN_INC_INDENT
	  || token.type == TOKEN_DEC_INDENT)
	return;
      if (token_space_p (&token))
	{
	  if (token.type == '\n' && s.state == STATE_PARSE_ERROR)
	    init_engine_state (&s);
	  continue;
	}
      if (debug_parser)
	printf ("\n\"%.*s\": ", (int) token.len, token.text);

      switch (s.state)
	{
	case STATE_START:
	  assert (segment_cur != NULL);
	  if (indent != 0 || segment_inside_indentation (segment_cur))
	    {
	      s.state = STATE_PARSE_ERROR;
	      break;
	    }
	  s.state = STATE_PARSE;
	  /* Fall through. */

	case STATE_PARSE:
	  if (lr_engine (&s, &token) == 0)
	    s.state = STATE_PARSE_ERROR;
	  break;

	case STATE_PARSE_ERROR:
	  /* Do nothing. */
	  break;

	default:
	  assert (0);
	}
    }
}

/* Startup code. */

/* Usage message. */
static const char *help[] =
  {
N_("texiweb, a program for translating TexiWEB documents\n"),
N_("Usage: %s [OPTION]... COMMAND\n"),
N_("\nCommands:\n"),
N_("  weave INFILE OUTFILE     translate TexiWEB to Texinfo\n"),
N_("  tangle INFILE [OUTFILE]  translate TexiWEB to C\n"),
N_("\nOptions:\n"),
N_("  -d, --debug            enables code for debugging texiweb\n"),
N_("  -l, --line             (tangle) emit #line directives\n"),
N_("  -f, --filenames        (tangle) only print list of output files\n"),
N_("  -u, --unused           (tangle) also print list of unused sections\n"),
N_("  -s, --segments         (tangle) print all segments to dir OUTFILE\n"),
N_("  -c, --catalogues       (weave) also print unused catalogues\n"),
N_("  -a, --unanswered       (weave) also list exercises without answers\n"),
N_("  -n, --nonzero-indent   (weave) warn for indent adjust between blocks\n"),
N_("  -h, --help             print this help, then exit\n"),
N_("  -v, --version          show version, then exit\n"),
N_("\nReport bugs to bug-avl@gnu.org.\n"),
NULL,
  };

/* Version message. */
static const char version[] =
N_("texiweb 0.9.0\n"
   "Copyright (C) 2002, 2004 Free Software Foundation, Inc.\n"
   "texiweb comes with NO WARRANTY, to the extent permitted by law,\n"
   "not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n"
   "You may redistribute copies of texiweb under the terms of the GNU\n"
   "General Public License.  For more information about these\n"
   "matters, see the file named COPYING.\n");

static void usage (int exit_code);
static void option (int op);

/* Parses the command line. */
static void
parse_cmd_line (int argc, char **argv)
{
  int options_over;

  short_pgm_name = strrchr (argv[0], '/');
  if (short_pgm_name != NULL)
    short_pgm_name++;
  else
    short_pgm_name = argv[0];

  if (argc == 0)
    usage (EXIT_FAILURE);

  options_over = 0;
  while (argc > 1)
    {
      argc--;
      argv++;
      if (!options_over && **argv == '-')
	{
	  if (!strcmp (*argv, "--"))
	    options_over = 1;
	  else if ((*argv)[1] == '-')
	    {
	      struct long_option
		{
		  const char *name;	/* Long name. */
		  int equiv;		/* Equivalent short name. */
		};

	      static const struct long_option lops[] =
		{
		  {"debug", 'd'},
		  {"line", 'l'},
		  {"filenames", 'f'},
		  {"unused", 'u'},
                  {"segments", 's'},
                  {"catalogues", 'c'},
		  {"unanswered", 'a'},
                  {"nonzero-indent", 'n'},
		  {"help", 'h'},
		  {"version", 'v'},
		};

	      const struct long_option *op;
	      for (op = lops; ; op++)
		if (op >= lops + sizeof lops / sizeof *lops)
		  usage (EXIT_FAILURE);
		else if (!strcmp (*argv + 2, op->name))
		  {
		    option (op->equiv);
		    break;
		  }
	    }
	  else
	    {
	      for ((*argv)++; **argv; (*argv)++)
		option (**argv);
	    }
	}
      else if (operation == OP_NONE)
	{
	  const char *cmd = *argv;

	  if (!strcmp (cmd, "weave"))
	    operation = OP_WEAVE;
	  else if (!strcmp (cmd, "tangle"))
	    operation = OP_TANGLE;
	  else
	    error (FTL, _("Invalid command %s"), cmd);
	}
      else if (in_file_name == NULL)
	in_file_name = *argv;
      else if (out_file_name == NULL)
	out_file_name = *argv;
      else
	usage (EXIT_FAILURE);
    }

  if (operation == OP_NONE
      || (operation == OP_TANGLE && in_file_name == NULL)
      || (operation == OP_WEAVE && out_file_name == NULL))
    usage (EXIT_FAILURE);

  if (operation == OP_TANGLE && print_all_segments && out_file_name == NULL)
    error (FTL, _("Output directory name argument required with -s or "
                  "--segments option"));

  if (operation == OP_WEAVE)
    {
      out_file = fopen (out_file_name, "w");
      if (out_file == NULL)
	error (FTL, _("Opening %s for writing: %s"),
	       out_file_name, strerror (errno));
    }
}

/* Prints a usage message to stdout and terminates execution,
   returning value EXIT_CODE to the operating system. */
static void
usage (int exit_code)
{
  const char **p;

  for (p = help; *p != NULL; p++)
    printf (gettext (*p), short_pgm_name);

  exit (exit_code);
}

/* Handles short command line option OP. */
static void
option (int op)
{
  switch (op)
    {
    case 'a':
      print_unanswered = 1;
      break;

    case 'd':
      debug_parser = 1;
      break;

    case 'f':
      filenames_only = 1;
      break;

    case 'l':
      opt_line = 1;
      break;

    case 's':
      print_all_segments = 1;
      break;

    case 'u':
      print_unused = 1;
      break;

    case 'c':
      print_catalogues = 1;
      break;

    case 'h':
      usage (EXIT_SUCCESS);
      break;

    case 'v':
      fputs (version, stdout);
      exit (EXIT_SUCCESS);
      break;

    default:
      usage (EXIT_FAILURE);
      break;
    }
}

/* String parsing helper functions. */

/* *BP and *EP point, respectively, to the beginning and one character
   past the end of a text string.  This function advances *BP past
   leading whitespace and backs up *EP to be before trailing
   whitespace. */
static void
trim_whitespace (char **bp, char **ep)
{
  while (*bp < *ep && isspace ((unsigned char) **bp))
    (*bp)++;

  while (*ep > *bp && isspace ((unsigned char) (*ep)[-1]))
    (*ep)--;
}

/* Finds everything after the first space in LINE as an argument,
   and stores *BP and *EP to the beginning and one character past the
   end of it.  Returns nonzero if an argument was found. */
static int
find_argument (char *line, char **bp, char **ep)
{
  *bp = line = strpbrk (line, " \t\r\n");
  if (line == NULL)
    goto lossage;
  *ep = strchr (*bp, '\0');
  trim_whitespace (bp, ep);
  if (*bp != *ep)
    return 1;

 lossage:
  error (SRC, _("Command missing argument."));
  return 0;
}

/* Attempts to find an argument after the command at the beginning of
   LINE.  Returns nonzero if one was found.  See find_argument() above
   for details. */
static int
find_optional_argument (char *line, char **bp, char **ep)
{
  *bp = line = strpbrk (line, " \t\r\n");
  if (line == NULL)
    return 0;
  *ep = strchr (*bp, '\0');
  trim_whitespace (bp, ep);
  return *bp != *ep;
}

/* Returns nonzero if STRING is empty or contains only whitespace. */
static int
empty_string (const char *string)
{
  for (; *string; string++)
    if (!isspace ((unsigned char) *string))
      return 0;
  return 1;
}

#if 0 /* Dead code. */
/* Same idea as find_argument(), except that the return value is a
   copy of the argument or NULL if none found. */
static char *
copy_argument (char *line)
{
  char *bp, *ep;
  if (!find_argument (line, &bp, &ep))
    return 0;
  return xstrndup (bp, ep - bp);
}
#endif

/* Error handling and memory management. */

/* Prints error message MESSAGE, formatted as with printf().  If FATAL
   is in FLAGS, then exits unsuccessfully.  If SRC is in FLAGS, prints
   the current source file name and line number. */
static void
error (int flags, const char *message, ...)
{
  va_list args;

  if (flags & SRC)
    fprintf (stderr, "%s:%d: ", in_file->name, in_file->line);
  else
    fprintf (stderr, "%s: ", short_pgm_name);

  va_start (args, message);
  vfprintf (stderr, message, args);
  va_end (args);

  putc ('\n', stderr);

  if (flags & FTL)
    exit (EXIT_FAILURE);
}

/* Allocates a block of AMT bytes and returns a pointer to the
   block. */
static void *
xmalloc (size_t amt)
{
  void *block;

  assert (amt != 0);
  block = malloc (amt);
  if (block == NULL)
    error (FTL, _("virtual memory exhausted"));
  return block;
}

/* If SIZE is 0, then BLOCK is freed and a null pointer is
   returned.
   Otherwise, if BLOCK is a null pointer, then a new block is allocated
   and returned.
   Otherwise, BLOCK is reallocated to be SIZE bytes in size and
   the new location of the block is returned.
   Aborts if unsuccessful. */
static void *
xrealloc (void *block, size_t size)
{
  if (size == 0)
    {
      if (block != NULL)
	free (block);

      return NULL;
    }

  if (block != NULL)
    block = realloc (block, size);
  else
    block = malloc (size);

  if (block == NULL)
    error (FTL, _("virtual memory exhausted"));

  return block;
}

/* Creates on the heap and returns a null-terminated string containing
   the LEN characters starting at BUF. */
static char *
xstrndup (const char *buf, size_t len)
{
  char *s = xmalloc (len + 1);
  memcpy (s, buf, len);
  s[len] = '\0';
  return s;
}

/* Makes a copy of STRING on the heap and returns it. */
static char *
xstrdup (const char *string)
{
  char *new = xmalloc (strlen (string) + 1);
  strcpy (new, string);
  return new;
}
