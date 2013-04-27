/* texitree - draws PostScript and plain text tree diagrams
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

#include <assert.h>
#include <ctype.h>
#include <limits.h>
#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* FIXME?  In text-based trees we should perhaps make sure that
   all of the nodes at a given level have the same height.  See,
   e.g., avlins2.tree for an example of where this might be
   nice. */

/* TODO: In text mode break too-long lines.  Useful for
   vine2tree2.txt. */

/* TODO: Should be able to support k-way trees, perhaps with a special #k
   directive.  Then we can talk about 2-3-4 trees in the RB chapter. */

/* FIXME: Needs to be more or less rewritten to fix the cruft. */

/* FIXME: Arrows between trees not properly aligned with $t.  Example:
   rootins.tree. */

/* FIXME: Handle loopback threads; i.e., a=a(>a). */

/* FIXME: Need to re-encode output font in order to get access to
   minus sign instead of hyphen.  Could use ISOLatin1Encoding I
   suppose. */

/* FIXME: Do real fitting of a circle to a set of boxes:
	_____
     __|_____|__
    |___________|
        |___|

   Possible strategy: find the center of the set of lines, then find
   the 3 box corner points that are farthest away from the center, and
   fit a circle to these three points. */

/* FIXME: Ellipses (...) should be made prettier in PostScript
   output. */

/* A PostScript-formatted binary tree node contains the following,
   from top down:

   - If TOPT_LEADER is set, a leader one radius in height.

   - The node itself.  If TOPT_NO_CIRCLE is unset, this is two radii
     in height.  If TOPT_NO_CIRCLE is set, then it is the actual
     height of the text plus one radius above.

   - A gutter between the node and its children.  This contains any
     lines between the node and its children.  It is missing if the
     node has no children.

   - The node's children, if any, having the height of the taller of
     its children.  The node's children are formatted recursively like
     the node itself.

   From left to right:

   - A gutter to accommodate long left-side labels, in top-level
     trees, of width margin[0].

   - If the node has an outside left thread (denoted >> in source
     form) then a left thread gutter of width PS_THREAD_WIDTH.

   - If the node has a left child, its left child, with width
     link[0]->w.

   - The node itself If TOPT_NO_CIRCLE is unset, this is two radii in
     width.  If TOPT_NO_CIRCLE is set, it is the text's actual width
     plus twice PS_MARGIN (one on its left, one on its right).

   - If the node has a right child, its right child, with width
     link[1]->w.

   - If the node has an outside right thread (denoted >> in source
     form) then a right thread gutter of width PS_THREAD_WIDTH.

   - A gutter to accommodate long right-side labels, in top-level
     trees, of width margin[1].

   A production node contains the following, from left to right:

   - The left side of the production, of width link[0]->w.

   - The production operator, of width 4 * PS_CHAR_WIDTH.

   - The right side of the production, of width link[1]->w. */

/* Recent GNU C versions support declaring certain function
   attributes.  Allow less cool compilers to ignore these
   attributes. */
#ifdef __GNUC__
#define ATTRIBUTE(X) __attribute__ (X)
#else
#define ATTRIBUTE(X)
#endif

/* Font metrics. */
struct font
  {
    struct character *chars;
    unsigned char *map;
    struct kern_pair *kern;
  };

/* Metrics for one character. */
struct character
  {
    int wx;			/* Width. */
    int llx, lly, urx, ury;	/* Bounding box. */
  };

/* Kerning information for a character pair. */
struct kern_pair
  {
    unsigned char c0, c1;	/* Characters. */
    int amt;			/* Kern adjust. */
  };

#include "helvetica.inc"
#define font helv_font

/* Output mode. */
enum output_mode
  {
    MODE_TEXT,			/* Textual output. */
    MODE_POSTSCRIPT		/* PostScript output. */
  };

/* Token types. */
enum token_type
  {
    TOKEN_EOF,			/* End of file. */
    TOKEN_LPAREN,		/* `(', `{', `<'. */
    TOKEN_RPAREN,		/* `)', `}', `>'. */
    TOKEN_LEFT,			/* `/'. */
    TOKEN_MIDDLE,		/* `|'. */
    TOKEN_RIGHT,		/* `\'. */
    TOKEN_COMMA,		/* `,'. */
    TOKEN_PRODUCES,		/* `=>'. */
    TOKEN_TWOWAY,		/* `<>'. */
    TOKEN_ADJACENT,		/* `||'. */
    TOKEN_NO_CIRCLE,		/* `^'. */
    TOKEN_LEADER,		/* `*'. */
    TOKEN_SHADE,		/* `%'. */
    TOKEN_THREAD,		/* `>'. */
    TOKEN_NAME,			/* `='. */
    TOKEN_NO_LINE,		/* `!'. */
    TOKEN_QUOTE,		/* `"'. */
    TOKEN_INCORRECT,		/* `**'. */
    TOKEN_JUSTIFICATION,	/* `$'. */
    TOKEN_SHAPE,		/* `@'. */
    TOKEN_LABEL			/* Anything else. */
  };

/* Current token. */
struct token
  {
    int ln;			/* Tracks input line number. */
    enum token_type type;	/* Token type. */
    int c;			/* Character corresponding to token. */
    int eof;			/* 1=Reached end of file. */
  };

/* Tree types. */
enum tree_type
  {
    TREE_BINARY,		/* Ordinary binary tree. */
    TREE_PRODUCTION,		/* Two binary trees separated by =>. */
    TREE_SHIFT			/* Binary tree shifted left or right. */
  };

/* Binary tree options. */
enum tree_options
  {
    TOPT_LEADER = 001,		/* Line leads in from top. */
    TOPT_NO_CIRCLE = 002,	/* Omit circle around node. */
    TOPT_THREAD = 004,		/* This is a thread, not a real node. */
    TOPT_NO_LINE = 010		/* Don't draw line from parent node. */
  };

/* Label positions. */
enum label_position
  {
    LP_MIDDLE,			/* Inside the node circle. */
    LP_LEFT,			/* (PostScript only) Left of node circle. */
    LP_RIGHT,			/* (PostScript only) Right of node circle. */
    LP_COUNT
  };

/* A binary tree or production. */
struct tree
  {
    enum tree_type type;	/* Tree type. */
    int w, h;			/* Width, height in characters or units. */
    double x, y;		/* (PostScript only) Absolute x,y of circle. */

    /* TREE_BINARY or TREE_SHIFT. */
    int ofs;			/* Relative x coordinate of label's center. */

    /* TREE_BINARY. */
    enum tree_options options;	/* Options. */
    char *label[LP_COUNT];	/* Labels for the root of this tree. */
    struct tree *link[2];	/* Links to subtrees. */
    struct tree *thread[2];	/* Thread links. */
    int shade;			/* Percentage shading, 0=black, 100=white. */
    char *name;			/* Node name. */
    int margin[2];		/* Left and right margins for label space. */
    int justify;		/* Justification: 't', 'm', 'b'. */
    int shape;			/* 'c' for circle or 's' for square. */

    /* TREE_PRODUCTION. */
    enum token_type prod_type;	/* TOKEN_PRODUCES, TOKEN_ADJACENT,
				   TOKEN_TWOWAY. */
  };

/* Address used to designate a thread pointing outside the tree. */
static struct tree outside_thread;

/* A text art canvas. */
struct canvas
  {
    int w;			/* Width in characters. */
    int ll;			/* Line length (may be greater than width). */
    int h;			/* Height in characters. */
    unsigned char *buf;		/* Content. */
  };

/* A window onto a PostScript page. */
struct space
  {
    int sh;
    int x0, w;
    int y0, h;
  };

/* PostScript page dimensions, in 1000/point units. */
#define PS_CHAR_HEIGHT 11000	/* Font size. */
#define PS_CHAR_WIDTH 6000	/* Average character width. */
#define PS_MARGIN 3000		/* Extra margin space within circle. */
#define PS_TOP_MARGIN 3000	/* Extra space above output. */
#define PS_BOT_MARGIN 0		/* Extra space below output. */
#define PS_THREAD_WIDTH 5000	/* Width of outside thread. */
#define PS_THREAD_HEIGHT 6500	/* Height of outside thread. */

/* Ways to justify text. */
enum justification
  {
    JT_LEFT = 001,		/* Left justification. */
    JT_RIGHT = 002,		/* Right justification. */
    JT_CENTER = 003,		/* Center justification. */
    JT_HORZ = 003,		/* Horizontal justification field. */

    JT_TOP = 010,		/* Top justification. */
    JT_MIDDLE = 030,		/* Middle justification. */
    JT_VERT = 030		/* Vertical justification field. */
  };

static void lex_init (struct token *);
static void lex_get (struct token *);
static int lex_match (struct token *token, enum token_type type);
static void lex_get_string (struct token *token, char **s);

static struct tree *tree_parse (struct token *, enum output_mode);
static void tree_free (struct tree *tree);
static void tree_print (struct tree *);

static void ps_resolve_threads (struct tree *this, struct tree *top);
static void ps_measure_tree (struct tree *, int *radius);
static void ps_draw_tree (struct tree *tree, struct space *space, int radius);
static void ps_draw_threads (const struct tree *tree, double radius);
static int ps_determine_diam (const struct tree *tree);
static void ps_measure_text (const char *text, int *w, int *h);
static void ps_layout_tree (struct tree *tree, int radius);
static void ps_draw_tree_justified (struct tree *tree,
				    struct space *space, int x, int radius);

static void space_create (struct space *space, int w, int h);
static void space_subdivide (struct space *dst, const struct space *src,
			     int x0, int y0, int x1, int y1);
static void space_line (struct space *space, int x0, int y0, int x1, int y1,
			int radius, int s0, int s1);
static void space_circle (struct space *space, int x, int y, int radius,
			  int shade);
static void space_square (struct space *space, int x0, int y0, int x1, int y1,
			  int shade);
static void space_text (struct space *space, int x, int y,
			const char *text, enum justification,
			int adjust_height, int shade);
static void space_special (struct space *space, int x, int y, int w, int h,
			   const char *text);
static double space_xc (const struct space *space, double x);
static double space_yc (const struct space *space, double y);
static void space_distance_along (double x0, double y0,
				  double x1, double y1,
				  double radius, int dir,
				  double *x, double *y, int shape);

static void text_measure_tree (struct tree *);
static void text_draw_tree (const struct tree *, struct canvas *);
static void text_measure_text (const char *text, int *w, int *h);
static struct tree *text_shift_tree (struct tree *old, int direction);
static int text_trivial (const struct tree *tree);
static int text_caret (const struct tree *tree);
static void text_draw_line (struct canvas *, int x0, int x1, int y);
static void text_draw_text (struct canvas *canvas, int x, int y, int w,
			    const char *text);
static void text_draw_tree_justified (const struct tree *tree,
				      struct canvas *canvas, int x);

static void canvas_create (struct canvas *, int w, int h);
static void canvas_free (struct canvas *);
static int canvas_get (const struct canvas *canvas, int x, int y);
static void canvas_set (struct canvas *, int x, int y, int c);
static void canvas_subdivide (struct canvas *dst, const struct canvas *src,
			      int x0, int y0, int x1, int y1);
static void canvas_print (const struct canvas *);

static void error (struct token *, const char *, ...)
     ATTRIBUTE ((format (printf, 2, 3)));
static void *xmalloc (size_t);
static void *xrealloc (void *ptr, size_t size);
static int max (int a, int b);

int
main (int argc, char *argv[])
{
  struct token token;
  enum output_mode mode = MODE_POSTSCRIPT;

  struct tree **input = NULL;
  int *radius = NULL;
  int m, n;

  int width, height;
  int page_width, page_height;
  

  int i, y;

  struct space page;

  if (argc >= 2 && !strncmp (argv[1], "--", 2))
    argv[1] += 2;
  if (argc < 2 || !strcmp (argv[1], "help"))
    {
      fprintf
	(stderr,
	 "texitree, a program for drawing binary trees\n"
	 "Usage: %s COMMAND [OPTION...]\n"
	 "\nCommands:\n"
	 "  text < tree.in > tree.txt   output plain text\n"
	 "  ps < tree.in > tree.eps     output PostScript\n"
	 "  help                        print this help, then exit\n"
	 "  version                     show version, then exit\n"
	 "\nOptions:\n"
	 "  -w WIDTH  page width for centering, WIDTH in characters (text)\n"
	 "            or 1/1000 point (PostScript), default 72 or 612000\n"
	 "\nReport bugs to bug-avl@gnu.org.\n", argv[0]);

      return argc == 2 ? EXIT_SUCCESS : EXIT_FAILURE;
    }
  else if (!strcmp (argv[1], "version"))
    {
      fprintf
	(stderr,
	 "texitree 0.9.0\n"
	 "Copyright (C) 2002, 2004 Free Software Foundation, Inc.\n"
	 "texiweb comes with NO WARRANTY, to the extent permitted by law,\n"
	 "not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n"
	 "You may redistribute copies of texiweb under the terms of the GNU\n"
	 "General Public License.  For more information about these\n"
	 "matters, see the file named COPYING.\n");

      return EXIT_SUCCESS;
    }
  else if (!strcmp (argv[1], "ps"))
    {
      mode = MODE_POSTSCRIPT;
      page_width = 612000;
      page_height = 792000;
      if (argc == 4 && !strcmp (argv[2], "-w"))
	page_width = atoi (argv[3]);
    }
  else if (!strcmp (argv[1], "text"))
    {
      mode = MODE_TEXT;
      page_width = 72;
      page_height = 66;
      if (argc == 4 && !strcmp (argv[2], "-w"))
	page_width = atoi (argv[3]);
    }
  else
    {
      fprintf (stderr, "bad command; use --help for usage\n");
      return EXIT_FAILURE;
    }

  lex_init (&token);
  lex_get (&token);

  n = m = 0;
  while (token.type != TOKEN_EOF)
    {
      if (n >= m)
	{
	  m = 2 * n + 8;
	  input = xrealloc (input, sizeof *input * m);
	  radius = xrealloc (radius, sizeof *radius * m);
	}

      input[n++] = tree_parse (&token, mode);
    }

  height = 0;
  if (mode == MODE_POSTSCRIPT)
    {
      /* Spacing between rows. */
      height += (n - 1) * PS_CHAR_HEIGHT;

      /* Top and bottom margins. */
      height += PS_TOP_MARGIN + PS_BOT_MARGIN;
    }

  for (i = 0; i < n; i++)
    {
      if (mode == MODE_POSTSCRIPT)
	{
	  ps_resolve_threads (input[i], input[i]);
	  ps_measure_tree (input[i], &radius[i]);
	}
      else
	text_measure_tree (input[i]);

      height += input[i]->h;
    }

  width = 0;
  for (i = 0; i < n; i++)
    width = max (width, input[i]->w);
  if (width > page_width)
    page_width = width;

  if (mode == MODE_POSTSCRIPT) 
    {
      if (height + 2 * 72000 > page_height)
        page_height = height + 2 * 72000;
    }

  y = mode == MODE_POSTSCRIPT ? 72000 : 0;
  if (mode == MODE_POSTSCRIPT)
    {
      int x0 = page_width / 2 - width / 2 - 1000;
      int x1 = page_width / 2 + width / 2 + 1000;
      int y0 = y - 1000;
      int y1 = y + height + 1000;
      
      space_create (&page, page_width, page_height);

      printf ("%%!PS-Adobe-3.0 EPSF-3.0\n"
	      "%%%%BoundingBox: %.0f %.0f %.0f %.0f\n",
              space_xc (&page, x0), space_yc (&page, y1),
	      space_xc (&page, x1), space_yc (&page, y0));
      fputs ("/ED { exch def } def\n"
             "/MT { moveto } def\n"
             "/LT { lineto } def\n"
             "/L { newpath MT LT stroke } bind def\n"
             "/F { exch findfont exch scalefont setfont } bind def\n"
             "/C { dup 3 index add 2 index MT 0 360 arc stroke } "
             "bind def\n"
             "/SG { 100 div setgray } bind def\n"
             "/D { SG dup 3 index add 2 index MT 0 360 arc fill 0 SG } "
             "bind def\n"
             "/TC { SG dup stringwidth pop 2 div 4 -1 roll exch sub\n"
             "     3 -1 roll MT show 0 SG } bind def\n"
             "/TR { SG dup stringwidth pop 4 -1 roll exch sub\n", stdout);
      fputs ("     3 -1 roll MT show 0 SG } bind def\n"
             "/TL { SG 0 4 -1 roll exch sub\n"
             "     3 -1 roll MT show 0 SG } bind def\n"
             "/S { gsave /Symbol 12 F 0 TC grestore } bind def\n"
             "/T { [2 1] 0 setdash MT curveto stroke } bind def\n"
             "/A { [] 0 setdash /y ED /x ED x 1.4 sub y 4 sub\n"
             "     MT x y LT x 1.4 add y 4 sub LT fill } def\n"
             "/Q { /y1 ED /x1 ED /y0 ED /x0 ED\n"
             "     x0 y0 MT x1 y0 LT x1 y1 LT x0 y1 LT\n"
             "     x0 y0 LT closepath } def\n"
             "/SD { Q stroke } def\n"
             "/SS { SG Q fill 0 SG } def\n"
             "/Helvetica 12 F\n", stdout);

      y += PS_TOP_MARGIN;
    }

  for (i = 0; i < n; i++)
    {
      int x0 = page_width / 2 - input[i]->w / 2;

      if (mode == MODE_POSTSCRIPT)
	{
	  struct space space;

	  space_subdivide (&space, &page,
			   x0, y, x0 + input[i]->w, y + input[i]->h);
	  ps_draw_tree (input[i], &space, radius[i]);
	  ps_draw_threads (input[i], radius[i] / 1000.);

	  if (i < n - 1)
	    y += input[i]->h + PS_CHAR_HEIGHT;
	}
      else
	{
	  struct canvas canvas, subcanvas;

	  canvas_create (&canvas, x0 + input[i]->w, input[i]->h);
	  canvas_subdivide (&subcanvas, &canvas,
			    x0, 0, x0 + input[i]->w, input[i]->h);
	  text_draw_tree (input[i], &subcanvas);
	  canvas_print (&canvas);
	  canvas_free (&canvas);

	  if (i < n - 1)
	    putchar ('\n');
	}

      tree_free (input[i]);
    }

  if (mode == MODE_POSTSCRIPT)
    fputs ("showpage\n"
	   "%%EOF\n", stdout);

  if (mode == MODE_TEXT)
    fputs (" \n", stdout);

  free (input);
  free (radius);

  return EXIT_SUCCESS;
}

/* Initialize lexeme *TOKEN. */
static void
lex_init (struct token *token)
{
  token->ln = 1;
  token->eof = 0;
}

/* Stuffs C back into the input buffer if appropriate. */
static void
lex_putback (int c)
{
  if (c != EOF)
    ungetc (c, stdin);
}

/* Obtains a lexeme from standard input and stores it into *TOKEN. */
static void
lex_get (struct token *token)
{
  int c;

  /* Whitespace is not significant.
     Comments are introduced by #. */
  for (;;)
    {
      do {
	c = getchar ();
	if (c == '\n')
	  token->ln++;
      } while (isspace ((unsigned char) c));

      if (c != '#')
	break;

      do {
	c = getchar ();
      }	while (c != '\n' && c != EOF);
      if (c == '\n')
	token->ln++;
    }

  /* Parse a token. */
  token->c = c;
  switch (c)
    {
    case EOF:
      token->type = TOKEN_EOF;
      if (token->eof == 1)
	error (token, "unexpected end of file");
      token->eof = 1;
      break;

    case '(':
      token->type = TOKEN_LPAREN;
      break;

    case ')':
      token->type = TOKEN_RPAREN;
      break;

    case '/':
      token->type = TOKEN_LEFT;
      break;

    case '\\':
      token->type = TOKEN_RIGHT;
      break;

    case ',':
      token->type = TOKEN_COMMA;
      break;

    case '<':
      c = getchar ();
      if (c == '>')
	token->type = TOKEN_TWOWAY;
      break;

    case '=':
      /* = followed by > is =>.
	 Otherwise, = is a character by itself. */
      c = getchar ();
      if (c == '>')
	token->type = TOKEN_PRODUCES;
      else
	{
	  lex_putback (c);
	  token->type = TOKEN_NAME;
	}
      break;

    case '^':
      token->type = TOKEN_NO_CIRCLE;
      break;

    case '*':
      /* ** is TOKEN_INCORRECT; * by itself is TOKEN_LEADER. */
      c = getchar ();
      if (c == '*')
	token->type = TOKEN_INCORRECT;
      else
	{
	  lex_putback (c);
	  token->type = TOKEN_LEADER;
	}
      break;

    case '%':
      token->type = TOKEN_SHADE;
      break;

    case '|':
      c = getchar ();
      if (c == '|')
	token->type = TOKEN_ADJACENT;
      else
	{
	  lex_putback (c);
	  token->type = TOKEN_MIDDLE;
	}
      break;

    case '>':
      token->type = TOKEN_THREAD;
      break;

    case '!':
      token->type = TOKEN_NO_LINE;
      break;

    case '"':
      token->type = TOKEN_QUOTE;
      break;

    case '$':
      token->type = TOKEN_JUSTIFICATION;
      break;

    case '@':
      token->type = TOKEN_SHAPE;
      break;

    default:
      if (isprint (c))
	token->type = TOKEN_LABEL;
      else
	error (token, "bad character in input");
      break;
    }
}

/* If *TOKEN is of type TYPE, reads the next token into *TOKEN and
   returns nonzero.  Otherwise, returns zero and takes no action. */
static int
lex_match (struct token *token, enum token_type type)
{
  if (token->type == type)
    {
      lex_get (token);
      return 1;
    }
  else
    return 0;
}

/* Add character C to string pointed to by S,
   allocating space for it as well. */
static void
add_char (char **s, int c)
{
  size_t len = 0;
  if (*s != NULL)
    len = strlen (*s);

  *s = xrealloc (*s, len + 2);
  (*s)[len] = c;
  (*s)[len + 1] = '\0';
}

/* Parses a single-character or quoted string name into S. */
static void
lex_get_string (struct token *token, char **s)
{
  if (*s != NULL)
    error (token, "duplicate node or thread name");

  if (token->type == TOKEN_QUOTE)
    {
      lex_get (token);
      do
	{
	  if (token->type != TOKEN_LABEL)
	    error (token, "non-label character inside quoted string");
	  add_char (s, token->c);

	  lex_get (token);
	}
      while (token->type != TOKEN_QUOTE);
    }
  else if (token->type == TOKEN_LABEL)
    add_char (s, token->c);
  else
    error (token, "node or thread name expected");
}

static struct tree *parse_production (struct token *token,
				      struct tree *tree1,
				      enum token_type,
				      enum output_mode);
static void parse_tree_label (struct token *token, struct tree *tree,
			      enum output_mode mode);

/* Parses and returns a tree structure starting at lexeme *TOKEN.
   Tree structures are specified as follows:

     - (Optional) `*' indicates that a vertical line should be drawn
       down to the node to indicate that the tree is part of a larger
       tree.  '^' indicates that the circle normally drawn around the
       node for PostScript output should be omitted.

     - (Required) A label.  Note that, in labels, the character &
       represents newline.  For PostScript output, `/' precedes
       left-side labels, `\' precedes right-side labels, and `|'
       precedes middle labels; unprefixed label text is put in the
       middle.  For text output, `/', `\', and `|' are ignored.

       Additionally, `%' followed by `r', `g', or `b' can be included
       for shading as a red, gray, or black node, respectively.  In
       text output, the `r', `g', or `b' is copied literally to the
       output.

     - (Optional) A pair of parentheses containing a pair of tree
       structures delimited by a comma (the node's left and right
       subtrees), a single tree structure (the node's left subtree),
       or a comma followed by a single tree structure (the node's
       right subtree).  Subtree(s) not specified are considered to be
       empty.

     - (Optional) A =>, ||, or <> token followed by another tree
     structure, specifying a transformation or production rule. */
static struct tree *
tree_parse (struct token *token, enum output_mode mode)
{
  struct tree *tree = xmalloc (sizeof *tree);
  tree->type = TREE_BINARY;
  tree->options = 0;
  tree->thread[0] = tree->thread[1] = NULL;
  tree->margin[0] = tree->margin[1] = 0;
  tree->name = NULL;

  parse_tree_label (token, tree, mode);

  tree->link[0] = tree->link[1] = NULL;
  if (lex_match (token, TOKEN_LPAREN))
    {
      if (token->type != TOKEN_COMMA)
	tree->link[0] = tree_parse (token, mode);
      if (lex_match (token, TOKEN_COMMA))
	tree->link[1] = tree_parse (token, mode);
      if (!lex_match (token, TOKEN_RPAREN))
	error (token, "expecting right paren");
    }

  if (strlen (tree->label[LP_MIDDLE]) == 0
      && tree->label[LP_LEFT] == NULL
      && tree->label[LP_RIGHT] == NULL
      && tree->link[0] == NULL
      && tree->link[1] == NULL)
    error (token, "node has no label and no children");

  if (lex_match (token, TOKEN_TWOWAY))
    return parse_production (token, tree, TOKEN_TWOWAY, mode);
  else if (lex_match (token, TOKEN_PRODUCES))
    return parse_production (token, tree, TOKEN_PRODUCES, mode);
  else if (lex_match (token, TOKEN_ADJACENT))
    return parse_production (token, tree, TOKEN_ADJACENT, mode);
  else
    return tree;
}

/* Parses and returns a tree label string.  */
static void
parse_tree_label (struct token *token, struct tree *tree,
		  enum output_mode mode)
{
  enum label_position pos;
  size_t count;

  {
    int i;

    for (i = 0; i < LP_COUNT; i++)
      tree->label[i] = NULL;
  }
  tree->shade = 100;
  tree->justify = 'm';
  tree->shape = 'c';

  pos = LP_MIDDLE;
  for (count = 0;; lex_get (token), count++)
    switch (token->type)
      {
      case TOKEN_INCORRECT:
	add_char (&tree->label[LP_MIDDLE], '*');
	add_char (&tree->label[LP_MIDDLE], '*');
	tree->options |= TOPT_NO_CIRCLE;
	break;
	
      case TOKEN_LEFT:
	if (mode == MODE_POSTSCRIPT)
	  pos = LP_LEFT;
	break;

      case TOKEN_RIGHT:
	if (mode == MODE_POSTSCRIPT)
	  pos = LP_RIGHT;
	break;

      case TOKEN_MIDDLE:
	pos = LP_MIDDLE;
	break;

      case TOKEN_LABEL:
        if (token->c == '\'')
          {
            /* We used to print ' as a traditional mathematical
               prime symbol, but that was too easy to overlook.
               So now we substitute an asterisk, which is much
               more obvious. */
            add_char (&tree->label[pos], '*');
          }
        else if (token->c == ';')
          {
            if (mode == MODE_TEXT)
              add_char (&tree->label[pos], ',');
          }
        else
          add_char (&tree->label[pos], token->c);
	break;

        break;

      case TOKEN_SHADE: 
        {
          char *arg = NULL;
          lex_get (token);
          lex_get_string (token, &arg);
          if (mode == MODE_POSTSCRIPT)
            {
              if (!strcmp (arg, "b"))
		tree->shade = 0;
              else if (!strcmp (arg, "g"))
		tree->shade = 100;
              else if (!strcmp (arg, "r"))
		tree->shade = 75;
              else
                for (; *arg != '\0'; arg++)
                  add_char (&tree->label[pos], *arg); 
            }
          else 
            {
              add_char (&tree->label[pos], '&');
              add_char (&tree->label[pos], '<');
              for (; *arg != '\0'; arg++)
                add_char (&tree->label[pos], *arg); 
              add_char (&tree->label[pos], '>');
            }
        }
        break;

      case TOKEN_JUSTIFICATION:
	lex_get (token);
	if (token->c == 't' || token->c == 'm' || token->c == 'b')
	  tree->justify = token->c;
	else
	  error (token, "expecting `t', `m', or `b'");
	break;

      case TOKEN_SHAPE:
	lex_get (token);
	if (token->c == 'c' || token->c == 's')
	  tree->shape = token->c;
	else
	  error (token, "expecting `c', `s'");
	if (tree->shape == 's' && mode == MODE_TEXT)
	  add_char (&tree->label[LP_MIDDLE], '[');
	break;

      case TOKEN_NO_CIRCLE:
	tree->options |= TOPT_NO_CIRCLE;
	break;

      case TOKEN_NO_LINE:
	tree->options |= TOPT_NO_LINE;
	break;

      case TOKEN_LEADER:
	tree->options |= TOPT_LEADER;
	break;

      case TOKEN_NAME:
	lex_get (token);
	lex_get_string (token, &tree->name);
	break;

      case TOKEN_THREAD:
	lex_get (token);
	if (token->type != TOKEN_THREAD)
	  lex_get_string (token, &tree->name);
	if (mode == MODE_POSTSCRIPT)
	  tree->options |= TOPT_THREAD;
	add_char (&tree->label[LP_MIDDLE], '[');
	if (token->c != '>')
	  {
	    const char *p;
	    for (p = tree->name; *p != '\0'; p++)
	      add_char (&tree->label[LP_MIDDLE], *p);
	  }
	add_char (&tree->label[LP_MIDDLE], ']');
	break;

      default:
	if (count == 0)
	  error (token, "expecting label");
	if (tree->shape == 's' && mode == MODE_TEXT)
	  add_char (&tree->label[LP_MIDDLE], ']');
	if (tree->label[LP_MIDDLE] == NULL)
	  add_char (&tree->label[LP_MIDDLE], '\0');
	return;
      }
}

/* Parses the latter part of and returns a `production' consisting of
   TREE1 followed by PROD_TYPE followed by another tree. */
static struct tree *
parse_production (struct token *token,
		  struct tree *tree1, enum token_type prod_type,
		  enum output_mode mode)
{
  struct tree *tree2 = tree_parse (token, mode);
  struct tree *production = xmalloc (sizeof *production);
  production->type = TREE_PRODUCTION;
  production->prod_type = prod_type;
  production->link[0] = tree1;
  production->link[1] = tree2;
  production->name = NULL;
  return production;
}

/* Frees TREE and any subtrees. */
static void
tree_free (struct tree *tree)
{
  if (tree->link[0] != NULL)
    tree_free (tree->link[0]);
  if (tree->link[1] != NULL)
    tree_free (tree->link[1]);

  free (tree->name);
  if (tree->type == TREE_BINARY)
    {
      int i;

      for (i = 0; i < LP_COUNT; i++)
	free (tree->label[i]);
    }

  free (tree);
}

/* Prints the structure of *TREE to stderr in a format acceptable to
   tree_parse().  For debugging purposes.  */
static void
tree_print (struct tree *tree)
{
  switch (tree->type)
    {
    case TREE_BINARY:
      fprintf (stderr, "%s", tree->label[LP_MIDDLE]);
      if (tree->link[0] != NULL || tree->link[1] != NULL)
	{
	  putc ('(', stderr);
	  if (tree->link[0] != NULL)
	    tree_print (tree->link[0]);
	  if (tree->link[1] != NULL)
	    {
	      putc (',', stderr);
	      tree_print (tree->link[1]);
	      putc (')', stderr);
	    }
	}
      break;

    case TREE_PRODUCTION:
      tree_print (tree->link[0]);
      if (tree->prod_type == TOKEN_TWOWAY)
	fprintf (stderr, " <> ");
      else if (tree->prod_type == TOKEN_PRODUCES)
	fprintf (stderr, " => ");
      else
	fprintf (stderr, " || ");
      tree_print (tree->link[1]);
      break;

    default:
      assert (0);
    }
}

static struct tree *
find_node_by_name (struct tree *tree, const char *name)
{
  if (tree == NULL)
    return NULL;

  if (!(tree->options & TOPT_THREAD)
      && tree->name != NULL && !strcmp (tree->name, name))
    return tree;

  {
    struct tree *tmp = find_node_by_name (tree->link[0], name);

    if (tmp != NULL)
      return tmp;
  }

  return find_node_by_name (tree->link[1], name);
}

static void
ps_resolve_threads (struct tree *this, struct tree *top)
{
  int i;

  if (this == NULL)
    return;

  for (i = 0; i < 2; i++)
    if (this->type == TREE_BINARY
	&& this->link[i] != NULL
	&& (this->link[i]->options & TOPT_THREAD))
      {
	if (this->link[i]->name != NULL)
	  {
	    this->thread[i] = find_node_by_name (top, this->link[i]->name);
	    if (this->thread[i] == NULL)
	      error (NULL, "thread to nonexistent node %s",
		     this->link[i]->name);
	  }
	else
	  this->thread[i] = &outside_thread;

	tree_free (this->link[i]);
	this->link[i] = NULL;
      }
    else
      ps_resolve_threads (this->link[i],
			  this->type == TREE_BINARY ? top : this->link[i]);
}

/* Calculates and returns the amount of margin needed on SIDE of TREE
   by considering the width of the left-side (or right-side) labels of
   nodes in TREE. */
static int
calc_margin (struct tree *tree, int side)
{
  int label_pos = side == 0 ? LP_LEFT : LP_RIGHT;
  int margin = 0;
  
  for (; tree != NULL; tree = tree->link[side])
    if (tree->label[label_pos] != NULL)
      {
	int w, h;
	int threshold;
      
	threshold = 0;
	if (tree->thread[side] == &outside_thread)
	  threshold += PS_THREAD_WIDTH;
	if (tree->link[side] != NULL)
	  threshold += tree->link[side]->w;

	ps_measure_text (tree->label[label_pos], &w, &h);
	w += 2 * PS_MARGIN;

	if (w > threshold && w - threshold > margin)
	  margin = w - threshold;
      }

  return margin;
}

static void
pad_top_level_tree (struct tree *tree)
{
  tree->w += tree->margin[0] = calc_margin (tree, 0);
  tree->w += tree->margin[1] = calc_margin (tree, 1);
}

/* Calculates the size of *TREE and all its subtrees.  Sets *RADIUS
   to the radius of circle to be used for drawing nodes. */
static void
ps_measure_tree (struct tree *tree, int *radius)
{
  *radius = (ps_determine_diam (tree) + PS_MARGIN + 1) / 2;
  ps_layout_tree (tree, *radius);
  if (tree->type == TREE_BINARY)
    pad_top_level_tree (tree);
}

/* Draw TREE inside SPACE using nodes of radius RADIUS. */
static void
ps_draw_tree (struct tree *tree, struct space *space, int radius)
{
  switch (tree->type)
    {
    case TREE_BINARY:
      {
	int x = 0;

	if (tree->thread[0] == &outside_thread)
	  x += PS_THREAD_WIDTH;
	x += tree->margin[0];

	if (tree->options & TOPT_LEADER)
	  space_subdivide (space, space, 0, radius, space->w, space->h);

	/* Draw left subtree and line connecting it to this node, if
	   any. */
	if (tree->link[0] != NULL)
	  {
	    struct space subspace;

	    space_subdivide (&subspace, space, x, radius * 3,
			     x + tree->link[0]->w,
			     radius * 3 + tree->link[0]->h);
	    ps_draw_tree (tree->link[0], &subspace, radius);

	    x += tree->link[0]->w;

	    if (!(tree->link[0]->options & TOPT_NO_LINE))
	      space_line (space,
			  x + radius, radius,
			  tree->margin[0] + tree->link[0]->ofs + radius, radius * 4,
			  radius,
			  tree->shape, tree->link[0]->shape);
	  }

	/* Draw this node. */
	tree->x = space_xc (space, x + radius);
	tree->y = space_yc (space, radius);
	if (!(tree->options & TOPT_NO_CIRCLE))
	  {
	    if (tree->shape == 'c')
	      space_circle (space, x + radius, radius, radius, tree->shade);
	    else
	      space_square (space, x, 0, x + 2 * radius, 2 * radius, tree->shade);
	    space_text (space, x + radius, radius,
			tree->label[LP_MIDDLE], JT_CENTER | JT_MIDDLE, 1,
			tree->shade <= 50 ? 100 : 0);
	    if (tree->label[LP_LEFT] != NULL)
	      space_text (space, x - PS_MARGIN, radius,
			  tree->label[LP_LEFT], JT_RIGHT | JT_MIDDLE, 1, 0);
	    x += 2 * radius;
	    if (tree->label[LP_RIGHT] != NULL)
	      space_text (space, x + PS_MARGIN, radius,
			  tree->label[LP_RIGHT], JT_LEFT | JT_MIDDLE, 1, 0);
	  }
	else
	  {
	    int w, h;
	    
	    ps_measure_text (tree->label[LP_MIDDLE], &w, &h);
	    space_text (space, x + PS_MARGIN + w / 2, radius,
			tree->label[LP_MIDDLE], JT_CENTER | JT_TOP, 0, 0);

	    x += w + PS_MARGIN * 2;
	  }
	
	/* Draw leader. */
	if (tree->options & TOPT_LEADER)
	  space_line (space, x - radius, -radius, x - radius, 0, 0,
		      'c', tree->shape);

	/* Draw right subtree and line connecting it to this node, if
	   any. */
	if (tree->link[1] != NULL)
	  {
	    struct space subspace;

	    if (!(tree->link[1]->options & TOPT_NO_LINE))	    
	      space_line (space,
			  x + tree->link[1]->ofs + radius, radius * 4,
			  x - radius, radius, radius,
			  tree->link[1]->shape, tree->shape);

	    space_subdivide (&subspace, space, x, radius * 3,
			     x + tree->link[1]->w,
			     radius * 3 + tree->link[1]->h);
	    ps_draw_tree (tree->link[1], &subspace, radius);
	  }
      }
      break;

    case TREE_PRODUCTION:
      {
	int extra_space;
	
	/* Draw left side. */
	ps_draw_tree_justified (tree->link[0], space, 0, radius);

	/* \336 is =>, \333 is <=> in the default Symbol font encoding. */
	if (tree->prod_type == TOKEN_PRODUCES)
	  space_special (space, tree->link[0]->w,
			 0, PS_CHAR_WIDTH * 4, tree->h, "\\336");
	else if (tree->prod_type == TOKEN_TWOWAY)
	  space_special (space, tree->link[0]->w,
			 0, PS_CHAR_WIDTH * 4, tree->h, "\\333");

	if (tree->prod_type == TOKEN_ADJACENT)
	  extra_space = 2 * PS_CHAR_WIDTH;
	else
	  extra_space = 4 * PS_CHAR_WIDTH;

	/* Draw right side. */
	ps_draw_tree_justified (tree->link[1], space,
			        tree->link[0]->w + extra_space, radius);
      }
      break;

    default:
      assert (0);
    }
}

static void
ps_draw_threads (const struct tree *tree, double radius)
{
  int i;

  if (tree == NULL)
    return;

  for (i = 0; i < 2; i++)
    {
      if (tree->type == TREE_BINARY && tree->thread[i] != NULL)
	{
	  double x[4], y[4];

	  x[0] = tree->x - 2 + 4 * i;
	  y[0] = tree->y - radius;
	  x[1] = x[0];
	  y[1] = y[0] - 10.;
	  if (tree->thread[i] != &outside_thread)
	    {
	      x[3] = tree->thread[i]->x + 2 - 4 * i;
	      y[3] = tree->thread[i]->y - radius - 3;
	    }
	  else
	    {
	      if (i == 0)
		x[3] = x[0] - radius - PS_THREAD_WIDTH / 1000. + 3;
	      else
		x[3] = x[0] + radius + PS_THREAD_WIDTH / 1000. - 3;

	      y[3] = y[0] + radius;
	    }
	  x[2] = x[3];
	  y[2] = y[1];

	  printf ("%.1f %.1f %.1f %.1f %.1f %.1f %.1f %.1f T\n",
		  x[1], y[1], x[2], y[2], x[3], y[3], x[0], y[0]);
	  printf ("%.1f %.1f A\n", x[3], y[3] + 3);
	}

      ps_draw_threads (tree->link[i], radius);
    }
}

/* Determines and returns required diameter of node circle for
   *TREE and its subtrees if any. */
static int
ps_determine_diam (const struct tree *tree)
{
  int w, h;
  int diam;

  if (tree->type == TREE_BINARY && !(tree->options & TOPT_NO_CIRCLE))
    {
      ps_measure_text (tree->label[LP_MIDDLE], &w, &h);
      diam = max (w, h);
    }
  else
    diam = 0;

  if (tree->link[0] != NULL)
    diam = max (diam, ps_determine_diam (tree->link[0]));
  if (tree->link[1] != NULL)
    diam = max (diam, ps_determine_diam (tree->link[1]));

  return diam;
}

/* Measures the width and height of the text string represented by
   TEXT. */
static void
ps_measure_text (const char *text, int *w, int *h)
{
  int ll = 0;

  *w = 0;
  *h = PS_CHAR_HEIGHT;

  for (;; text++)
    switch (*text)
      {
      case '\0':
	*w = (*w / 10) * (PS_CHAR_HEIGHT / 10) / 10;
	return;

      case '&':
	*h += PS_CHAR_HEIGHT;
	ll = 0;
	break;

      default:
	{
	  int ch = *text == '_' ? ' ' : (unsigned char) *text;
	  int first = ll == 0;
	  int last = ch != '\'' && (text[1] == '&' || text[1] == '\0');
	  struct character *c = &font.chars[font.map[ch]];
	  if (first && last)
	    ll += c->urx - c->llx;
	  else if (first)
	    ll += c->wx - c->llx;
	  else if (last)
	    ll += c->urx;
	  else
	    ll += c->wx;
	}
	*w = max (ll, *w);
	break;
      }
}

/* Figures out the size of *TREE and its subtrees given that node
   circles are of radius RADIUS. */
static void
ps_layout_tree (struct tree *tree, int radius)
{
  switch (tree->type)
    {
    case TREE_BINARY:
      {
	int subtree_height = 0;

	if (!(tree->options & TOPT_NO_CIRCLE))
	  tree->w = tree->h = 2 * radius;
	else
	  {
	    ps_measure_text (tree->label[LP_MIDDLE], &tree->w, &tree->h);
	    tree->w += 2 * PS_MARGIN;
	    tree->h += 2 * PS_MARGIN;
	  }

	tree->ofs = 0;
	if (tree->link[0] != NULL)
	  {
	    ps_layout_tree (tree->link[0], radius);
	    tree->w += tree->ofs = tree->link[0]->w;
	    subtree_height = radius + tree->link[0]->h;
	  }
	if (tree->thread[0] == &outside_thread)
	  {
	    tree->w += PS_THREAD_WIDTH;
	    tree->ofs += PS_THREAD_WIDTH;
	  }

	if (tree->link[1] != NULL)
	  {
	    ps_layout_tree (tree->link[1], radius);
	    tree->w += tree->link[1]->w;
	    subtree_height = max (subtree_height, radius + tree->link[1]->h);
	  }
	tree->h += subtree_height;

	if (tree->thread[1] == &outside_thread)
	  tree->w += PS_THREAD_WIDTH;
	if (subtree_height == 0
	    && (tree->thread[0] != NULL || tree->thread[1] != NULL))
	  tree->h += PS_THREAD_HEIGHT;

	if (tree->options & TOPT_LEADER)
	  tree->h += radius;
      }
      break;

    case TREE_PRODUCTION:
      {
	int extra_space;
	
	ps_layout_tree (tree->link[0], radius);
	ps_layout_tree (tree->link[1], radius);

	pad_top_level_tree (tree->link[0]);
	if (tree->link[1]->type == TREE_BINARY)
	  pad_top_level_tree (tree->link[1]);

	if (tree->prod_type == TOKEN_ADJACENT)
	  extra_space = 2 * PS_CHAR_WIDTH;
	else
	  extra_space = 4 * PS_CHAR_WIDTH;
	
	tree->w = tree->link[0]->w + extra_space + tree->link[1]->w;
	tree->h = max (tree->link[0]->h, tree->link[1]->h);
      }
      break;

    default:
      assert (0);
    }
}

/* Draws TREE with nodes of radius RADIUS, vertically justified in
   SPACE at an offset of X from the left margin. */
static void
ps_draw_tree_justified (struct tree *tree, struct space *space,
		        int x, int radius)
{
  struct space subspace;
  int ofs;

  if (tree->type == TREE_BINARY)
    {
      if (tree->justify == 'm')
	ofs = (space->h - tree->h) / 2;
      else if (tree->justify == 'b')
	ofs = (space->h - tree->h);
      else
	ofs = 0;
    }
  else
    ofs = 0;

  space_subdivide (&subspace, space, x, ofs, x + tree->w, ofs + tree->h);
  ps_draw_tree (tree, &subspace, radius);
}

/* Creates in SPACE a space W points wide and H points tall. */
static void
space_create (struct space *space, int w, int h)
{
  space->x0 = space->y0 = 0;
  space->w = w;
  space->h = space->sh = h;
}

/* Sets up DST as a subspace of SRC, occupying area (X0,Y0)-(X1,Y1) in
   SRC. */
static void
space_subdivide (struct space *dst, const struct space *src,
		 int x0, int y0, int x1, int y1)
{
  assert (x0 >= 0 && x0 < src->w && x1 >= x0 && x1 <= src->w);
  assert (y0 >= 0 && y0 < src->h && y1 >= y0 && y1 <= src->h);

  dst->sh = src->sh;
  dst->x0 = src->x0 + x0;
  dst->w = x1 - x0;
  dst->y0 = src->y0 + y0;
  dst->h = y1 - y0;
}

/* Draws a line in SPACE from (X0,Y0) to (X1,Y1), clipping off each end of the
   line at the edge of the shape on that end.  At (X0,Y0) there is shape S0, at
   (X1,Y1) there is shape S1.  Shapes may be circles ('c') or squares ('s').
   RADIUS is the radius of a circle or the edge length of a square. */
static void
space_line (struct space *space, int x0, int y0, int x1, int y1, int radius,
	    int s0, int s1)
{
  double ax0, ay0;
  double ax1, ay1;

  space_distance_along (x0, y0, x1, y1, radius, -1, &ax0, &ay0, s0);
  space_distance_along (x1, y1, x0, y0, radius, +1, &ax1, &ay1, s1);

  printf ("%.1f %.1f %.1f %.1f L\n",
	  space_xc (space, ax0), space_yc (space, ay0),
	  space_xc (space, ax1), space_yc (space, ay1));
}

/* Draws a circle in SPACE centered at (X,Y) with radius RADIUS. */
static void
space_circle (struct space *space, int x, int y, int radius, int shade)
{
  double x0 = space_xc (space, x);
  double y0 = space_yc (space, y);

  if (shade != 100)
    printf ("%.1f %.1f %.1f %d D\n", x0, y0, radius / 1000., shade);

  printf ("%.1f %.1f %.1f C\n", x0, y0, radius / 1000.);
}

static void 
space_square (struct space *space, int px0, int py0, int px1, int py1,
	      int shade)
{
  double x0 = space_xc (space, px0);
  double y0 = space_yc (space, py0);
  double x1 = space_xc (space, px1);
  double y1 = space_yc (space, py1);

  if (shade != 100)
    printf ("%.1f %.1f %.1f %.1f %d SS\n", x0, y0, x1, y1, shade);

  printf ("%.1f %.1f %.1f %.1f SD\n", x0, y0, x1, y1);
}

/* Draws TEXT in FONT within SPACE.  It is horizontally justified
   according to J: if JT_LEFT, X specifies the left edge of the text;
   if JT_RIGHT, X specifies the right edge; if JT_CENTER, X specifies
   the text's horizontal center.  It is vertically centered at Y if J
   specifies JT_MIDDLE; if JT_TOP, then Y specifies the top edge of
   the text. */
static void
space_text (struct space *space, int x, int y, const char *text,
	    enum justification j, int adjust_height, int shade)
{
  enum justification h = j & JT_HORZ;
  enum justification v = j & JT_VERT;
  int tw, th;

  ps_measure_text (text, &tw, &th);

  {
    struct character *c = &font.chars[font.map[(unsigned char) *text]];

    if (v == JT_MIDDLE)
      {
	/* For single-character labels, take ascenders and descenders
	   into account when centering vertically. */
	if (adjust_height && strlen (text) == 1)
	  y += ((c->ury - c->lly) / 2 + c->lly) * PS_CHAR_HEIGHT / 1000;
	else
	  y += PS_CHAR_HEIGHT * 3 / 4 - th / 2;
      }
    else
      y += PS_CHAR_HEIGHT * 3 / 8;

    x -= c->llx;
  }

  if (!strcmp (text, "**"))
    {
      space_special (space, x, y,
		     tw + PS_CHAR_WIDTH, th - PS_CHAR_HEIGHT / 2, "**");
      return;
    }

  while (*text != '\0')
    {
      printf ("%.1f %.1f (",
	      space_xc (space, x), space_yc (space, y));

      for (; *text && *text != '&'; text++)
	if (*text == '_')
	  putchar (' ');
	else
	  putchar (*text);

      printf (") %d T%c\n",
	      shade, h == JT_CENTER ? 'C' : h == JT_LEFT ? 'L' : 'R');

      if (*text == '&')
	{
	  text++;
	  y += PS_CHAR_HEIGHT;
	}
    }
}

/* Draws TEXT in Symbol font within SPACE, centered both horizontally
   and vertically in area (X,Y)-(X+W,Y+H). */
static void
space_special (struct space *space, int x, int y, int w, int h, const char *c)
{
  x += w / 2;
  y += (h - PS_CHAR_HEIGHT) / 2 + (PS_CHAR_HEIGHT * 3 / 4);
  printf ("%.0f %.0f (%s) S\n", space_xc (space, x), space_yc (space, y), c);
}

/* Returns the result of mapping logical x-coordinate X within SPACE
   into physical PostScript coordinates. */
static double
space_xc (const struct space *space, double x)
{
  return (x + space->x0) / 1000.;
}

/* Returns the result of mapping logical y-coordinate Y within SPACE
   into physical PostScript coordinates. */
static double
space_yc (const struct space *space, double y)
{
  return (space->sh - (y + space->y0)) / 1000.;
}

/* Clips an end determined by DIR off the line (X0,Y0)-(X1,Y1) and sets the
   clipped end into (*X,*Y).  The clipping is done on a circle of radius RADIUS
   if SHAPE is 'c' or on a square of side length RADIUS if SHAPE is 's'. */
static void
space_distance_along (double x0, double y0, double x1, double y1,
		      double radius, int dir, double *x, double *y, int shape)
{
  if (shape == 'c')
    {
      if (x1 != x0)
	{
	  double m = (y1 - y0) / (x1 - x0);
	  double dx = radius / sqrt (m * m + 1);
	  double dy = m * dx;
	  *x = x0 + dx * dir;
	  *y = y0 + dy * dir;
	}
      else
	{
	  /* FIXME. */
	  *x = x0;
	  *y = y0;
	}
    }
  else
    {
      *x = x0;
      *y = y0 - radius;
    }
}

/* Calculates the size of *TREE and all its subtrees. */
static void
text_measure_tree (struct tree *tree)
{
  switch (tree->type)
    {
    case TREE_BINARY:
      if (tree->link[0] != NULL)
	text_measure_tree (tree->link[0]);
      if (tree->link[1] != NULL)
	text_measure_tree (tree->link[1]);

      if (text_caret (tree))
	{
	  tree->w = 3;
	  tree->h = 3;
	  tree->ofs = 1;
	}
      else
	{
	  int subtree_height = 0;

	  text_measure_text (tree->label[LP_MIDDLE], &tree->w, &tree->h);

	  if (tree->link[0] != NULL)
	    {
	      assert (tree->link[0]->ofs >= 0
		      && tree->link[0]->ofs < tree->link[0]->w);
	      if (tree->link[0]->ofs == tree->link[0]->w - 1)
		tree->link[0] = text_shift_tree (tree->link[0], -1);
	      tree->w += tree->ofs = tree->link[0]->w;
	      subtree_height = max (subtree_height, 1 + tree->link[0]->h);
	    }
	  else
	    tree->ofs = 0;

	  if (tree->link[1] != NULL)
	    {
	      assert (tree->link[1]->ofs >= 0
		      && tree->link[1]->ofs < tree->link[1]->w);
	      if (tree->link[1]->ofs == 0)
		tree->link[1] = text_shift_tree (tree->link[1], +1);
	      tree->w += tree->link[1]->w;
	      subtree_height = max (subtree_height, 1 + tree->link[1]->h);
	    }

	  tree->h += subtree_height;
	}

      if (tree->options & TOPT_LEADER)
	tree->h++;
      break;

    case TREE_PRODUCTION:
      {
	text_measure_tree (tree->link[0]);
	text_measure_tree (tree->link[1]);
	tree->w = tree->link[0]->w + 4 + tree->link[1]->w;
	tree->h = max (tree->link[0]->h, tree->link[1]->h);
      }
      break;

    default:
      assert (0);
    }
}

/* Returns the first printable character in text string S. */
static char
text_first_char (const char *s) 
{
  while (*s == '&' || *s == '_')
    s++;
  return *s;
}

/* Draws TREE into CANVAS. */
static void
text_draw_tree (const struct tree *tree, struct canvas *canvas)
{
  switch (tree->type)
    {
    case TREE_BINARY:
      {
	struct canvas c;
	int x, tx, ty;

	if (tree->options & TOPT_LEADER)
	  canvas_subdivide (&c, canvas, 0, 1, canvas->w, canvas->h);
	else
	  c = *canvas;

	x = 0;
	if (text_caret (tree))
	  {
	    canvas_set (&c, 1, 0, text_first_char (tree->label[LP_MIDDLE]));
	    canvas_set (&c, 1, 1, '^');
	    canvas_set (&c, 0, 2,
                        text_first_char (tree->link[0]->label[LP_MIDDLE]));
	    canvas_set (&c, 2, 2,
                        text_first_char (tree->link[1]->label[LP_MIDDLE]));

	    if (tree->options & TOPT_LEADER)
	      canvas_set (canvas, 1, 0, '|');

	    return;
	  }

	text_measure_text (tree->label[LP_MIDDLE], &tx, &ty);
	if (tree->link[0] != NULL)
	  {
	    struct canvas subcanvas;

	    canvas_subdivide (&subcanvas, &c, x, ty + 1,
			      x + tree->link[0]->w, ty + 1 + tree->link[0]->h);
	    text_draw_tree (tree->link[0], &subcanvas);

	    x += tree->link[0]->w;
	    if (!(tree->link[0]->options & TOPT_NO_LINE))
	      text_draw_line (&c, tree->link[0]->ofs + 1, x, ty);
	  }

	if (tree->options & TOPT_LEADER)
	  canvas_set (canvas, x + tx / 2, 0, '|');

	text_draw_text (&c, x, 0, tx, tree->label[LP_MIDDLE]);
	x += tx;

	if (tree->link[1] != NULL)
	  {
	    struct canvas subcanvas;

	    canvas_subdivide (&subcanvas, &c, x, ty + 1,
			      x + tree->link[1]->w, ty + 1 + tree->link[1]->h);
	    text_draw_tree (tree->link[1], &subcanvas);

	    if (!(tree->link[1]->options & TOPT_NO_LINE))
	      text_draw_line (&c, x + tree->link[1]->ofs - 1, x - 1, ty);
	  }
      }
      break;

    case TREE_PRODUCTION:
      {
	text_draw_tree_justified (tree->link[0], canvas, 0);

	if (tree->prod_type == TOKEN_PRODUCES)
	  {
	    canvas_set (canvas, tree->link[0]->w + 1, tree->h / 2, '=');
	    canvas_set (canvas, tree->link[0]->w + 2, tree->h / 2, '>');
	  }

	text_draw_tree_justified (tree->link[1], canvas, tree->link[0]->w + 4);
      }
      break;

    case TREE_SHIFT:
      {
	struct canvas subcanvas;
	int shift;

	shift = tree->ofs - tree->link[0]->ofs;
	canvas_subdivide (&subcanvas, canvas,
			  shift, 0, shift + tree->link[0]->w, tree->h);

	text_draw_tree (tree->link[0], &subcanvas);
      }
      break;

    default:
      assert (0);
    }
}

/* Sets *W to the width and *H to the height of TEXT. */
static void
text_measure_text (const char *text, int *w, int *h)
{
  int ll = 0;

  *w = 0;
  *h = 1;

  while (*text == '&' || *text == '_')
    text++;

  for (;;)
    switch (*text++)
      {
      case '\0':
	return;

      case '&':
	(*h)++;
	ll = 0;
	break;

      case '_':
        break;

      default:
        *w = max (++ll, *w);
	break;
      }
}

/* Returns a new tree the same as tree OLD but shifted to the left or
   the right by MOVE characters and filled with blanks on the opposite
   side.  If MOVE is negative OLD is shifted left, otherwise right. */
static struct tree *
text_shift_tree (struct tree *old, int move)
{
  struct tree *new = xmalloc (sizeof *new);
  new->type = TREE_SHIFT;
  new->w = old->w + abs (move);
  new->h = old->h;
  new->ofs = old->ofs + (move > 0 ? move : 0);
  new->options = old->options;
  new->name = NULL;
  assert (new->ofs >= 0 && new->ofs < new->w);
  new->link[0] = old;
  new->link[1] = NULL;

  return new;
}

/* Returns nonzero iff TREE is a node with no children and a
   single-character label. */
static int
text_trivial (const struct tree *tree)
{
  return (tree->w == 1
	  && tree->link[0] == NULL
	  && tree->link[1] == NULL);
}

/* Returns nonzero if TREE can be properly rendered with a caret (^),
   like so:

    a
    ^
   b c

   This is true iff TREE's two children are both leaves and all three
   nodes have single-character labels. */
static int
text_caret (const struct tree *tree)
{
  return (tree->type == TREE_BINARY
	  && strlen (tree->label[LP_MIDDLE]) == 1
	  && tree->link[0] != NULL && text_trivial (tree->link[0])
	  && tree->link[1] != NULL && text_trivial (tree->link[1]));
}

/* Draws a line on CANVAS at vertical location Y horizontally from X0
   to X1, exclusive. */
static void
text_draw_line (struct canvas *canvas, int x0, int x1, int y)
{
  if (x1 == x0 + 1)
    canvas_set (canvas, x0, y, '/');
  else if (x1 == x0 - 1)
    canvas_set (canvas, x0, y, '\\');
  else if (x1 > x0)
    {
      int x;

      for (x = x0; x < x1; x++)
	{
	  static const char lines[] = "_.-'";
	  size_t frac = ((double) x - x0) / (x1 - x0 - 1) * 3;
	  assert (frac < sizeof lines);
	  canvas_set (canvas, x, y, lines[frac]);
	}
    }
  else
    {
      int x;

      for (x = x0; x > x1; x--)
	{
	  static const char lines[] = "_.-`";
	  size_t frac = ((double) x0 - x) / (x0 - x1 - 1) * 3;
	  assert (frac < sizeof lines);
	  canvas_set (canvas, x, y, lines[frac]);
	}
    }
}

/* Returns the number of printing characters in line of text TEXT. */
static size_t
text_line_len (const char *text)
{
  size_t len = 0;
  
  for (; *text != '\0' && *text != '&'; text++)
    if (*text != '_')
      len++;
  return len;
}

/* Draws TEXT inside CANVAS starting vertically at Y0, centered
   horizontally between X0 and X0+W. */
static void
text_draw_text (struct canvas *canvas, int x0, int y0, int w, const char *text)
{
  int y = y0;

  while (*text == '&' || *text == '_')
    text++;

  while (*text != '\0')
    {
      int line_len = text_line_len (text);
      int x = x0 + w / 2 - line_len / 2;
      for (; *text != '\0' && *text != '&'; text++)
	if (*text != '_')
	  canvas_set (canvas, x++, y, *text);

      if (*text == '&' || *text == '_')
	{
	  y++;
	  while (*text == '&' || *text == '_')
	    text++;
	}
    }
}

/* Draws TREE vertically justified in CANVAS at horizontal offset X. */
static void
text_draw_tree_justified (const struct tree *tree,
                          struct canvas *canvas, int x)
{
  struct canvas subcanvas;
  int ofs;

  if (tree->type == TREE_BINARY)
    {
      if (tree->justify == 'm')
	ofs = (canvas->h - tree->h) / 2;
      else if (tree->justify == 'b')
	ofs = canvas->h - tree->h;
      else
	ofs = 0;
    }
  else
    ofs = 0;

  canvas_subdivide (&subcanvas, canvas, x, ofs, x + tree->w, ofs + tree->h);
  text_draw_tree (tree, &subcanvas);
}

/* Sets up *CANVAS as a new canvas W characters wide and H characters
   tall. */
static void
canvas_create (struct canvas *canvas, int w, int h)
{
  canvas->w = canvas->ll = w;
  canvas->h = h;
  canvas->buf = xmalloc (w * h);
  memset (canvas->buf, ' ', w * h);
}

/* Creates DST as a subcanvas of SRC occupying the space
   (X0,Y0)-(X1,Y1). */
static void
canvas_subdivide (struct canvas *dst, const struct canvas *src,
		  int x0, int y0, int x1, int y1)
{
  assert (dst != NULL && src != NULL);
  assert (x0 >= 0 && x0 < src->w && x1 >= 0 && x1 <= src->w && x0 <= x1);
  assert (y0 >= 0 && y0 < src->h && y1 >= 0 && y1 <= src->h && y0 <= y1);

  dst->w = x1 - x0;
  dst->ll = src->ll;
  dst->h = y1 - y0;
  dst->buf = src->buf + x0 + y0 * src->ll;
}

/* Release storage associated with *CANVAS. */
static void
canvas_free (struct canvas *canvas)
{
  free (canvas->buf);
}

/* Sets location (X,Y) in CANVAS to character C. */
static void
canvas_set (struct canvas *canvas, int x, int y, int c)
{
  assert (canvas != NULL);
  assert (x >= 0 && x < canvas->w);
  assert (y >= 0 && y < canvas->h);
  assert (c >= 0 && c <= UCHAR_MAX);
  assert (canvas->buf[x + y * canvas->ll] == ' ');

  canvas->buf[x + y * canvas->ll] = c;
}

/* Returns the character at location (X,Y) in CANVAS. */
static int
canvas_get (const struct canvas *canvas, int x, int y)
{
  assert (canvas != NULL);
  assert (x >= 0 && x < canvas->w);
  assert (y >= 0 && y < canvas->h);

  return canvas->buf[x + y * canvas->ll];
}

/* Prints the contents of CANVAS to stdout. */
static void
canvas_print (const struct canvas *canvas)
{
  int y;

  for (y = 0; y < canvas->h; y++)
    {
      int x, w;

      w = canvas->w;
      while (w > 0 && canvas_get (canvas, w - 1, y) == ' ')
	w--;

      for (x = 0; x < w; x++)
	putchar (canvas_get (canvas, x, y));
      putchar ('\n');
    }
}

/* Prints error message FORMAT regarding TOKEN to stderr.  FORMAT may
   use printf()-style formatting sequences. */
static void
error (struct token *token, const char *format, ...)
{
  va_list args;

  if (token == NULL)
    fputs ("error: ", stderr);
  else if (token->c == EOF)
    fputs ("error at end-of-file: ", stderr);
  else
    fprintf (stderr, "line %d: error at `%c': ", token->ln, token->c);

  va_start (args, format);
  vfprintf (stderr, format, args);
  va_end (args);

  putc ('\n', stderr);

  exit (EXIT_FAILURE);
}

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

/* Returns the value of the larger of its arguments. */
static int
max (int a, int b)
{
  return a > b ? a : b;
}
