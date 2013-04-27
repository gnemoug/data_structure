@c -*-texinfo-*-
@c 
@c GNU libavl - library for manipulation of binary trees.
@c Copyright (C) 1998, 1999, 2000, 2001, 2002, 2004 Free Software
@c Foundation, Inc.
@c Permission is granted to copy, distribute and/or modify this document
@c under the terms of the GNU Free Documentation License, Version 1.2
@c or any later version published by the Free Software Foundation;
@c with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
@c A copy of the license is included in the section entitled "GNU
@c Free Documentation License".

@node Supplementary Code
@appendix Supplementary Code

This appendix contains code too long for the exposition or too far
from the main topic of the book.

@menu
* Option Parser::
* Command-Line Parser::
@end menu

@node Option Parser
@appendixsection Option Parser

The BST test program contains an option parser for handling command-line
options.  @xref{User Interaction}, for an introduction to its public
interface.  This section describes the option parser's implementation.

The option parsing state is kept in |struct option_state|:

@<Option parser@> =
/* Option parsing state. */
struct option_state @
  {@-
    const struct option *options; /* List of options. */
    char **arg_next;            /* Remaining arguments. */
    char *short_next;           /* When non-null, unparsed short options. */
  };@+

@

The initialization function just creates and returns one of these
structures:

@<Option parser@> +=
/* Creates and returns a command-line options parser.  
   |args| is a null-terminated array of command-line arguments, not
   including program name. */
static struct option_state *@
option_init (const struct option *options, char **args) @
{
  struct option_state *state;

  assert (options != NULL && args != NULL);

  state = xmalloc (sizeof *state);
  state->options = options;
  state->arg_next = args;
  state->short_next = NULL;

  return state;
}

@

The option retrieval function uses a couple of helper functions.  The
code is lengthy, but not complicated:

@<Option parser@> +=
/* Parses a short option whose single-character name is pointed to by
   |state->short_next|.  Advances past the option so that the next one
   will be parsed in the next call to |option_get()|.  Sets |*argp| to
   the option's argument, if any.  Returns the option's short name. */
static int @
handle_short_option (struct option_state *state, char **argp) @
{
  const struct option *o;

  assert (state != NULL @
	  && state->short_next != NULL && *state->short_next != '\0'
	  && state->options != NULL);

  /* Find option in |o|. */
  for (o = state->options; ; o++)
    if (o->long_name == NULL)
      fail ("unknown option `-%c'; use --help for help", *state->short_next);
    else if (o->short_name == *state->short_next)
      break;
  state->short_next++;

  /* Handle argument. */
  if (o->has_arg) @
    {@-
      if (*state->arg_next == NULL || **state->arg_next == '-')
	fail ("`-%c' requires an argument; use --help for help");

      *argp = *state->arg_next++;
    }@+

  return o->short_name;
}

/* Parses a long option whose command-line argument is pointed to by
   |*state->arg_next|.  Advances past the option so that the next one
   will be parsed in the next call to |option_get()|.  Sets |*argp| to
   the option's argument, if any.  Returns the option's identifier. */
static int @
handle_long_option (struct option_state *state, char **argp) @
{
  const struct option *o;	/* Iterator on options. */
  char name[16];		/* Option name. */
  const char *arg;		/* Option argument. */

  assert (state != NULL @
	  && state->arg_next != NULL && *state->arg_next != NULL
	  && state->options != NULL @
	  && argp != NULL);

  /* Copy the option name into |name|
     and put a pointer to its argument, or |NULL| if none, into |arg|. */
  {
    const char *p = *state->arg_next + 2;
    const char *q = p + strcspn (p, "=");
    size_t name_len = q - p;

    if (name_len > (sizeof name) - 1)
      name_len = (sizeof name) - 1;
    memcpy (name, p, name_len);
    name[name_len] = '\0';

    arg = (*q == '=') ? q + 1 : NULL;
  }

  /* Find option in |o|. */
  for (o = state->options; ; o++)
    if (o->long_name == NULL)
      fail ("unknown option --%s; use --help for help", name);
    else if (!strcmp (name, o->long_name))
      break;

  /* Make sure option has an argument if it should. */
  if ((arg != NULL) != (o->has_arg != 0)) @
    {@-
      if (arg != NULL)
	fail ("--%s can't take an argument; use --help for help", name);
      else @
	fail ("--%s requires an argument; use --help for help", name);
    }@+

  /* Advance and return. */
  state->arg_next++;
  *argp = (char *) arg;
  return o->short_name;
}

/* Retrieves the next option in the state vector |state|.
   Returns the option's identifier, or -1 if out of options.
   Stores the option's argument, or |NULL| if none, into |*argp|. */
static int @
option_get (struct option_state *state, char **argp) @
{
  assert (state != NULL && argp != NULL);

  /* No argument by default. */
  *argp = NULL;

  /* Deal with left-over short options. */
  if (state->short_next != NULL) @
    {@-
      if (*state->short_next != '\0')
	return handle_short_option (state, argp);
      else @
	state->short_next = NULL;
    }@+

  /* Out of options? */
  if (*state->arg_next == NULL) @
    {@-
      free (state);
      return -1;
    }@+

  /* Non-option arguments not supported. */
  if ((*state->arg_next)[0] != '-')
    fail ("non-option arguments encountered; use --help for help");
  if ((*state->arg_next)[1] == '\0')
    fail ("unknown option `-'; use --help for help");

  /* Handle the option. */
  if ((*state->arg_next)[1] == '-')
    return handle_long_option (state, argp);
  else @
    {@-
      state->short_next = *state->arg_next + 1;
      state->arg_next++;
      return handle_short_option (state, argp);
    }@+
}

@

@node Command-Line Parser
@appendixsection Command-Line Parser

The option parser in the previous section handles the general form of
command-line options.  The code in this section applies that option
parser to the specific options used by the BST test program.  It has
helper functions for argument parsing and advice to users.  Here is all
of it together:

@<Command line parser@> =
/* Command line parser. */

/* If |a| is a prefix for |b| or vice versa, returns the length of the @
   match.
   Otherwise, returns 0. */
size_t @
match_len (const char *a, const char *b) @
{
  size_t cnt;

  for (cnt = 0; *a == *b && *a != '\0'; a++, b++)
    cnt++;

  return (*a != *b && *a != '\0' && *b != '\0') ? 0 : cnt;
}

/* |s| should point to a decimal representation of an integer.
   Returns the value of |s|, if successful, or 0 on failure. */
static int @
stoi (const char *s) @
{
  long x = strtol (s, NULL, 10);
  return x >= INT_MIN && x <= INT_MAX ? x : 0;
}

/* Print helpful syntax message and exit. */
static void @
usage (void) @
{
  static const char *help[] = @
    {@-@-
      "bst-test, unit test for GNU libavl.\n\n",
      "Usage: %s [OPTION]...\n\n",
      "In the option descriptions below, CAPITAL denote arguments.\n",
      "If a long option shows an argument as mandatory, then it is\n",
      "mandatory for the equivalent short option also.  See the GNU\n",
      "libavl manual for more information.\n\n",
      "-t, --test=TEST     Sets test to perform.  TEST is one of:\n",
      "                      correctness insert/delete/... (default)\n",
      "                      overflow    stack overflow test\n",
      "                      benchmark   benchmark test\n",
      "                      null        no test\n",
      "-s, --size=TREE-SIZE  Sets tree size in nodes (default 16).\n",
      "-r, --repeat=COUNT  Repeats operation COUNT times (default 16).\n",
      "-i, --insert=ORDER  Sets the insertion order.  ORDER is one of:\n",
      "                      random      random permutation (default)\n",
      "                      ascending   ascending order 0...n-1\n",
      "                      descending  descending order n-1...0\n",
      "                      balanced    balanced tree order\n",
      "                      zigzag      zig-zag tree\n",
      "                      asc-shifted n/2...n-1, 0...n/2-1\n",
      "                      custom      custom, read from stdin\n",
      "-d, --delete=ORDER  Sets the deletion order.  ORDER is one of:\n",
      "                      random   random permutation (default)\n",
      "                      reverse  reverse order of insertion\n",
      "                      same     same as insertion order\n",
      "                      custom   custom, read from stdin\n",
      "-a, --alloc=POLICY  Sets allocation policy.  POLICY is one of:\n",
      "                      track     track memory leaks (default)\n",
      "                      no-track  turn off leak detection\n",
      "                      fail-CNT  fail after CNT allocations\n",
      "                      fail%%PCT  fail random PCT%% of allocations\n",
      "                      sub-B,A   divide B-byte blocks in A-byte units\n",
      "                    (Ignored for `benchmark' test.)\n",
      "-A, --incr=INC      Fail policies: arg increment per repetition.\n",
      "-S, --seed=SEED     Sets initial number seed to SEED.\n",
      "                    (default based on system time)\n",
      "-n, --nonstop       Don't stop after a single error.\n",
      "-q, --quiet         Turns down verbosity level.\n",
      "-v, --verbose       Turns up verbosity level.\n",
      "-h, --help          Displays this help screen.\n",
      "-V, --version       Reports version and copyright information.\n",
      NULL,
    };@+@+

  const char **p;
  for (p = help; *p != NULL; p++)
    printf (*p, pgm_name);

  exit (EXIT_SUCCESS);
}

/* Parses command-line arguments from null-terminated array |args|.
   Sets up |options| appropriately to correspond. */
static void @
parse_command_line (char **args, struct test_options *options) @
{
  static const struct option option_tab[] = @
    {@-
      {"test", 't', 1}, @
      {"insert", 'i', 1}, @
      {"delete", 'd', 1},
      {"alloc", 'a', 1}, @
      {"incr", 'A', 1}, @
      {"size", 's', 1},
      {"repeat", 'r', 1}, @
      {"operation", 'o', 1}, @
      {"seed", 'S', 1},
      {"nonstop", 'n', 0}, @
      {"quiet", 'q', 0}, @
      {"verbose", 'v', 0},
      {"help", 'h', 0}, @
      {"version", 'V', 0}, @
      {NULL, 0, 0},
    };@+

  struct option_state *state;

  /* Default options. */
  options->test = TST_CORRECTNESS; @
  options->insert_order = INS_RANDOM;
  options->delete_order = DEL_RANDOM; @
  options->alloc_policy = MT_TRACK;
  options->alloc_arg[0] = 0; @
  options->alloc_arg[1] = 0;
  options->alloc_incr = 0; @
  options->node_cnt = 15; 
  options->iter_cnt = 15; @
  options->seed_given = 0;
  options->verbosity = 0; @
  options->nonstop = 0;

  if (*args == NULL)
    return;

  state = option_init (option_tab, args + 1);
  for (;;) @
    {@-
      char *arg;
      int id = option_get (state, &arg);
      if (id == -1)
	break;

      switch (id) @
	{
	case 't':
	  if (match_len (arg, "correctness") >= 3)
	    options->test = TST_CORRECTNESS;
	  else if (match_len (arg, "overflow") >= 3)
	    options->test = TST_OVERFLOW;
	  else if (match_len (arg, "null") >= 3)
            options->test = TST_NULL;
          else
	    fail ("unknown test \"%s\"", arg);
	  break;

	case 'i': @
	  {
	    static const char *orders[INS_CNT] = @
	      {@-
		"random", "ascending", "descending",
		"balanced", "zigzag", "asc-shifted", "custom",
	      };@+

	    const char **iter;

	    assert (sizeof orders / sizeof *orders == INS_CNT);
	    for (iter = orders; ; iter++)
	      if (iter >= orders + INS_CNT)
		fail ("unknown order \"%s\"", arg);
	      else if (match_len (*iter, arg) >= 3) @
		{@-
		  options->insert_order = iter - orders;
		  break;
		}@+
	  }
	  break;

	case 'd': @
	  {
	    static const char *orders[DEL_CNT] = @
	      {@-
		"random", "reverse", "same", "custom",
	      };@+

	    const char **iter;

	    assert (sizeof orders / sizeof *orders == DEL_CNT);
	    for (iter = orders; ; iter++)
	      if (iter >= orders + DEL_CNT)
		fail ("unknown order \"%s\"", arg);
	      else if (match_len (*iter, arg) >= 3) @
		{@-
		  options->delete_order = iter - orders;
		  break;
		}@+
	  }
	  break;

	case 'a':
	  if (match_len (arg, "track") >= 3)
	    options->alloc_policy = MT_TRACK;
	  else if (match_len (arg, "no-track") >= 3)
	    options->alloc_policy = MT_NO_TRACK;
	  else if (!strncmp (arg, "fail", 3)) @
	    {@-
	      const char *p = arg + strcspn (arg, "-%");
	      if (*p == '-') @
		options->alloc_policy = MT_FAIL_COUNT;
	      else if (*p == '%') @
		options->alloc_policy = MT_FAIL_PERCENT;
	      else @
		fail ("invalid allocation policy \"%s\"", arg);

	      options->alloc_arg[0] = stoi (p + 1);
	    }@+
	  else if (!strncmp (arg, "suballoc", 3)) @
	    {@-
	      const char *p = strchr (arg, '-');
	      const char *q = strchr (arg, ',');
	      if (p == NULL || q == NULL)
		fail ("invalid allocation policy \"%s\"", arg);

	      options->alloc_policy = MT_SUBALLOC;
	      options->alloc_arg[0] = stoi (p + 1);
	      options->alloc_arg[1] = stoi (q + 1);
	      if (options->alloc_arg[MT_BLOCK_SIZE] < 32)
		fail ("block size too small");
	      else if (options->alloc_arg[MT_ALIGN] 
                       > options->alloc_arg[MT_BLOCK_SIZE])
		fail ("alignment cannot be greater than block size");
              else if (options->alloc_arg[MT_ALIGN] < 1)
                fail ("alignment must be at least 1");
	    }@+
	  break;

	case 'A': @
	  options->alloc_incr = stoi (arg); @
	  break;

	case 's':
	  options->node_cnt = stoi (arg);
	  if (options->node_cnt < 1)
	    fail ("bad tree size \"%s\"", arg);
	  break;
	  
	case 'r':
	  options->iter_cnt = stoi (arg);
	  if (options->iter_cnt < 1)
	    fail ("bad repeat count \"%s\"", arg);
	  break;
	  
	case 'S':
	  options->seed_given = 1;
	  options->seed = strtoul (arg, NULL, 0);
	  break;

	case 'n': @
	  options->nonstop = 1; @
	  break;
	  
	case 'q': @
	  options->verbosity--; @
	  break;
	  
	case 'v': @
	  options->verbosity++; @
	  break;
	  
	case 'h': @
	  usage (); @
	  break;

	case 'V':
	  fputs ("GNU libavl 2.0.3\n"
                 "Copyright (C) 1998, 1999, 2000, 2001, 2002, 2004 "
                 "Free Software Foundation, Inc.\n"
		 "This program comes with NO WARRANTY, not even for\n"
		 "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n"
		 "You may redistribute copies under the terms of the\n"
		 "GNU General Public License.  For more information on\n"
		 "these matters, see the file named COPYING.\n",
		 stdout);
	  exit (EXIT_SUCCESS);

	default: @
	  assert (0);
	}
    }@+
}

@
