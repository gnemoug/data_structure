// Abstract AVL Tree Template Example 1.
// This code is in the public domain.
// Version: 1.2  Author: Walt Karas

// This example shows how to use the AVL template to create the
// env class.  The env class stores multiple variables with string
// names and string values, similar to the environment in a UNIX
// shell.

#include <string.h>
#include <stdio.h>

#include "avl_tree.h"

// An "environment" of variables and (string) values.
class env
{
private:

    struct node
    {
        // Child pointers.
        node *gt, *lt;

        // First character of variable name string is actually balance factor.
        // Remaining characters are name as nul-terminated string.
        char *name;

        // Value of variable, nul-terminated string.
        char *value;
    };

    // Abstractor class for avl_tree template.
    struct abstr
    {
        typedef node *handle;

        typedef const char *key;

        typedef unsigned size;

        static handle get_less(handle h, bool access)
        {
            return(h->lt);
        }
        static void set_less(handle h, handle lh)
        {
            h->lt = lh;
        }
        static handle get_greater(handle h, bool access)
        {
            return(h->gt);
        }
        static void set_greater(handle h, handle gh)
        {
            h->gt = gh;
        }

        static int get_balance_factor(handle h)
        {
            return((signed char) (h->name[0]));
        }
        static void set_balance_factor(handle h, int bf)
        {
            h->name[0] = bf;
        }

        static int compare_key_node(key k, handle h)
        {
            return(strcmp(k, (h->name) + 1));
        }

        static int compare_node_node(handle h1, handle h2)
        {
            return(strcmp((h1->name) + 1, (h2->name) + 1));
        }

        static handle null(void)
        {
            return(0);
        }

        // Nodes are not stored on secondary storage, so this should
        // always return false.
        static bool read_error(void)
        {
            return(false);
        }
    };

    typedef abstract_container::avl_tree<abstr> tree_t;

    tree_t tree;

public:

    void set(const char *name, const char *value)
    {
        node *n = tree.search(name);

        if (!n)
        {
            // This variable does not currently exist.  Create a node for it.
            n = new node;
            n->name = new char [strlen(name) + 2];
            strcpy(n->name + 1, name);
            tree.insert(n);
        }
        else
            // Delete current value.
            delete [] n->value;

        if (value)
        {
            if (strlen(value) == 0)
                value = 0;
        }

        if (value)
        {
            n->value = new char [strlen(value) + 1];
            strcpy(n->value, value);
        }
        else
        {
            // Variable is being set to empty string, which deletes it.
            tree.remove(name);
            delete [] n->name;
            delete n;
        }
    }

    const char *get(const char *name)
    {
        node *n = tree.search(name);

        return(n ? n->value : "");
    }

    // Dump environment in ascending order by variable name.
    void dump(void)
    {
        tree_t::iter it;
        node *n;

        it.start_iter_least(tree);

        for (n = *it; n; it++, n = *it)
            printf("%s=%s\n", n->name + 1, n->value);

    }

    // Clear environment.
    void clear(void)
    {
        tree_t::iter it;
        node *n;

        it.start_iter_least(tree);

        // A useful property of this data structure is the ability to do a
        // "death march" through it.  Once the iterator (forward or backward)
        // has stepped past a node, the node is not accessed again (assuming
        // you don't reverse the direction of iteration).  Of course, if
        // you've corrupted the nodes, you need to make the tree as empty.

        for (n = *it; n; n = *it)
        {
            it++;
            delete [] n->name;
            delete [] n->value;
            delete n;
        }
    }
};

// Demo main program.
int main(void)
{
    env e;

    e.set("The", "The value");
    e.set("quick", "quick value");
    e.set("brown", "brown value");
    e.set("fox", "fox value");
    e.set("jumped", "jumped value");
    e.set("over", "over value");
    e.set("the", "the value");
    e.set("lazy", "lazy value");
    e.set("dog", "dog value");

    e.set("DOG", "DOG value");
    e.set("DOG", 0);

    printf("The value of \"dog\" is \"%s\"\n\n", e.get("dog"));

    printf("DUMP\n");
    e.dump();

    return(0);
}
