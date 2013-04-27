// Abstract AVL Tree Template Test Suite.
// This code is in the public domain.
// Version: 1.2  Author: Walt Karas

#include "stdio.h"
#include "stdlib.h"
#include "string.h"

#include "avl_tree.h"

// Check to make sure double inclusion OK.
#include "avl_tree.h"

void bail(const char *note)
{
    printf("%s\n", note);
    exit(1);
}

// Mask of highest bit in an unsigned int.
const unsigned HIGH_BIT = (~(((unsigned) (~ 0)) >> 1));

// Node array and "shadow" node array.
struct
{
    signed char bf;

    int val;

    unsigned gt, lt;

}
arr[401], arr2[400];

// Class to pass to template as abstractor parameter.
class abstr
{
public:

    // Handles are indexes into the "arr" array.  If a handle has been
    // "accessed", it has its high bit set.  (The handle has to have been
    // accessed in order to alter the node's values, or compare its key.)
    typedef unsigned handle;

    typedef unsigned size;

    typedef int key;

    static handle get_less(handle h, bool access)
    {
        if (!(h & HIGH_BIT))
            bail("get_less");
        handle child = arr[h & ~HIGH_BIT].lt;
        if (access)
            child |= HIGH_BIT;
        return(child);
    }

    static void set_less(handle h, handle lh)
    {
        if (!(h & HIGH_BIT))
        {
            printf("%x %x\n", h, lh);
            bail("set_less");
        }
        if (lh != ~0)
            lh &= ~HIGH_BIT;
        arr[h & ~HIGH_BIT].lt = lh;
    }

    static handle get_greater(handle h, bool access)
    {
        if (!(h & HIGH_BIT))
            bail("get_greater");
        handle child = arr[h & ~HIGH_BIT].gt;
        if (access)
            child |= HIGH_BIT;
        return(child);
    }

    static void set_greater(handle h, handle gh)
    {
        if (!(h & HIGH_BIT))
            bail("set_greater");
        if (gh != ~0)
            gh &= ~HIGH_BIT;
        arr[h & ~HIGH_BIT].gt = gh;
    }

    static int get_balance_factor(handle h)
    {
        if (!(h & HIGH_BIT))
            bail("get_balance_factor");
        return(arr[h & ~HIGH_BIT].bf);
    }

    static void set_balance_factor(handle h, int bf)
    {
        if (!(h & HIGH_BIT))
            bail("set_balance_factor");
        arr[h & ~HIGH_BIT].bf = bf;
    }

    static int compare_key_node(key k, handle h)
    {
        if (!(h & HIGH_BIT))
            bail("compare_key_node");
        return(k - arr[h & ~HIGH_BIT].val);
    }

    static int compare_node_node(handle h1, handle h2)
    {
        if (!(h1 & HIGH_BIT))
            bail("compare_node_node - h1");
        if (!(h2 & HIGH_BIT))
            bail("compare_node_node - h2");
        return(arr[h1 & ~HIGH_BIT].val - arr[h2 & ~HIGH_BIT].val);
    }

    static handle null(void)
    {
        return(~0);
    }

    static bool read_error(void)
    {
        return(false);
    }

};

// AVL tree with public root for testing purposes.
class t_avl_tree : public abstract_container::avl_tree<abstr>
{
public:
    handle &pub_root;

    t_avl_tree(void) : pub_root(root) { }
};

t_avl_tree tree;

typedef t_avl_tree::iter iter;

// Verifies that a tree is a valid AVL Balanced Binary Search Tree.
// Returns depth.  Don't use on an empty tree.
int verify_tree(unsigned subroot = tree.pub_root & ~HIGH_BIT)
{
    int l_depth, g_depth;
    unsigned h;

    if (arr[subroot].lt == ~0)
        l_depth = 0;
    else
    {
        h = arr[subroot].lt & ~HIGH_BIT;
        if (arr[subroot].val <= arr[h].val)
        {
            printf("not less: %u %d %d %d\n",
                   subroot, arr[subroot].val, h, arr[h].val);
            bail("verify_tree");
        }
        l_depth = verify_tree(h);
    }

    if (arr[subroot].gt == ~0)
        g_depth = 0;
    else
    {
        h = arr[subroot].gt & ~HIGH_BIT;
        if (arr[subroot].val >= arr[h].val)
        {
            printf("not greater: %u %d %d %d\n",
                   subroot, arr[subroot].val, h, arr[h].val);
            bail("verify_tree");
        }
        g_depth = verify_tree(h);
    }

    if (arr[subroot].bf != (g_depth - l_depth))
    {
        printf("bad bf: n=%u bf=%d gd=%d ld=%d\n",
               subroot, arr[subroot].bf, g_depth, l_depth);
        bail("verify_tree");
    }

    return((g_depth > l_depth ? g_depth : l_depth) + 1);
}

void check_empty(void)
{
    if (tree.pub_root != ~0)
        bail("not empty");
}

void insert(unsigned h)
{
    unsigned rh = tree.insert(h | HIGH_BIT);
    if (rh == ~0)
        bail("insert null");
    rh &= ~HIGH_BIT;
    if (arr[h].val != arr[rh].val)
    {
        printf("bad - %u %u\n", h, rh);
        bail("insert");
    }
}

void remove(int k, bool should_be_null = false)
{
    unsigned rh = tree.remove(k);
    if (rh == ~0)
    {
        if (!should_be_null)
        {
            printf("null key=%d\n", k);
            bail("remove");
        }
    }
    else
    {
        if (should_be_null)
        {
            printf("not null key=%d rh=%u\n", k, rh);
            bail("remove");
        }
        rh &= ~HIGH_BIT;
        if (arr[rh].val != k)
        {
            printf("wrong key=%d rh=%u [rh].val=%d\n", k, rh, arr[rh].val);
            bail("remove");
        }
        // Mark balance factor of node to indicate it's not in the tree.
        arr[rh].bf = 123;
    }
}

unsigned max_elems;

// Prior to starting a test, mark all the nodes to be used in the test
// with a bad balance factor.  This makes it easy to tell which nodes
// are in the tree and which aren't.
void mark_bf(void)
{
    unsigned i = max_elems;

    while (i)
    {
        i--;
        arr[i].bf = 123;
    }
}

void search_test(int key, abstract_container::search_type st, unsigned rh)
{
    if (tree.search(key, st) != (rh | HIGH_BIT))
    {
        printf("%d %x %u\n", key, (unsigned) st, rh);
        bail("search_test");
    }
    iter it;
    it.start_iter(tree, key, st);
    if (*it != (rh | HIGH_BIT))
    {
        printf("%d %x %x %x\n", key, (unsigned) st, rh, *it);
        bail("search_test - iter");
    }
    if ((st == abstract_container::EQUAL) && (rh != ~0))
    {
        unsigned h = *it;
        iter it2 = it;
        it++;
        it2--;
        if (*it != tree.search(key, abstract_container::GREATER))
        {
            printf("%d %x %x %x\n", key, (unsigned) st, h, *it);
            bail("search_test - iter ++");
        }
        if (*it2 != tree.search(key, abstract_container::LESS))
        {
            printf("%d %x %x %x\n", key, (unsigned) st, h, *it2);
            bail("search_test - iter --");
        }
    }
    return;
}

void search_test(unsigned h)
{

    if (arr[h].bf == 123)
        search_test(2 * h, abstract_container::EQUAL, ~0);
    else
    {
        search_test(2 * h, abstract_container::EQUAL, h);
        search_test(2 * h, abstract_container::LESS_EQUAL, h);
        search_test(2 * h, abstract_container::GREATER_EQUAL, h);

        search_test(2 * h + 1, abstract_container::EQUAL, ~0);
        search_test(2 * h + 1, abstract_container::LESS, h);
        search_test(2 * h + 1, abstract_container::LESS_EQUAL, h);

        search_test(2 * h - 1, abstract_container::EQUAL, ~0);
        search_test(2 * h - 1, abstract_container::GREATER, h);
        search_test(2 * h - 1, abstract_container::GREATER_EQUAL, h);
    }
}

void search_all(void)
{
    unsigned h = max_elems, min = ~0, max = ~0;

    while (h)
    {
        h--;

        search_test(h);

        if (arr[h].bf != 123)
        {
            if (max == ~0)
                max = h;
            min = h;
        }
    }

    h = tree.search_least();
    if (h != (min | HIGH_BIT))
    {
        printf("%x %x\n", h, min);
        bail("search_all least");
    }

    h = tree.search_greatest();
    if (h != (max | HIGH_BIT))
    {
        printf("%x %x\n", h, max);
        bail("search_all greatest");
    }

    iter it;

    // Test forward iteration through entire tree.
    it.start_iter_least(tree);
    if (*it != (min | HIGH_BIT))
    {
        printf("%x %x\n", h, min);
        bail("search_all least - iter");
    }
    while (*it != (max | HIGH_BIT))
    {
        h = *it;
        it++;
        if (*it != tree.search(2 * h, abstract_container::GREATER))
        {
            printf("%x %x\n", h, *it);
            bail("search_all increment - iter");
        }
    }
    it++;
    if (*it != ~0)
        bail("search_all increment - end");

    // Test backward iteration through entire tree.
    it.start_iter_greatest(tree);
    if (*it != (max | HIGH_BIT))
    {
        printf("%x %x\n", h, max);
        bail("search_all greatest - iter");
    }
    while (*it != (min | HIGH_BIT))
    {
        h = *it;
        it--;
        if (*it != tree.search(2 * h, abstract_container::LESS))
        {
            printf("%x %x\n", h, *it);
            bail("search_all increment - iter");
        }
    }
    it--;
    if (*it != ~0)
        bail("search_all increment - end");
}

void dump(unsigned subroot, unsigned depth)
{
    if (arr[subroot].lt != ~0)
        dump(arr[subroot].lt, depth + 1);
    printf("%u(%u, %d) ", subroot, depth, arr[subroot].bf);
    if (arr[subroot].gt != ~0)
        dump(arr[subroot].gt, depth + 1);
}

void dump(void)
{
    dump(tree.pub_root & ~HIGH_BIT, 0);
    putchar('\n');
}

// Create a tree with the nodes whose handles go from 0 to max_elems - 1.
// Insert step and remove step parameters must be relatively prime to
// max_elems.
void big_test(unsigned in_step, unsigned rm_step)
{
    unsigned in = 0, rm = 0;

    printf("inserting\n");
    do
    {
        insert(in);
        verify_tree();
        in += in_step;
        in %= max_elems;
    }
    while (in != 0);

    search_all();

    printf("removing\n");
    for ( ; ; )
    {
        remove(rm * 2);
        rm += rm_step;
        rm %= max_elems;
        if (rm == 0)
            break;
        verify_tree();
    }

    check_empty();
}

// Iterate through all the possible topologies of AVL trees with a
// certain depth.  The trees are created in the "shadow" node array,
// then copied into the main node array.
class possible_trees
{
private:

    // 1-base depth.
    unsigned depth_;

    // Subtree description structure.  size is number of nodes in subtree.
    struct sub
    {
        unsigned root, size;
    };

    sub t;

    // Create "first" subtree of a given depth with the node whose handle
    // is "start" as the node with the minimum key in the tree. balance
    // factors of nodes with children are all -1 in the first subtree.
    sub first(unsigned start, unsigned depth)
    {
        sub s;

        if (depth == 0)
        {
            s.size = 0;
            s.root = ~0;
        }
        else if (depth == 1)
        {
            arr2[start].bf = 0;
            arr2[start].lt = ~0;
            arr2[start].gt = ~0;
            s.size = 1;
            s.root = start;
        }
        else
        {
            s = first(start, depth - 1);
            start += s.size;
            arr2[start].bf = -1;
            arr2[start].lt = s.root;
            sub s2 = first(start + 1, depth - 2);
            arr2[start].gt = s2.root;
            s.root = start;
            s.size += s2.size + 1;
        }
        return(s);
    }

    // If there is no "next" subtree, returns a subtree description with
    // a size of zero.
    sub next(unsigned start, unsigned subroot, unsigned depth)
    {
        sub s;

        if (depth < 2)
            // For a subtree of depth 1 (1 node), the first topology is the
            // only topology, so no next.
            s.size = 0;
        else
        {
            // Get next greater subtree.
            s = next(subroot + 1, arr2[subroot].gt,
                     depth - (arr2[subroot].bf == -1 ? 2 : 1));
            if (s.size != 0)
            {
                arr2[subroot].gt = s.root;
                s.size += subroot - start + 1;
                s.root = subroot;
            }
            else
            {
                // No next greater subtree.  Get next less subtree, and
                // start over with first greater subtree.
                int bf = arr2[subroot].bf;
                s = next(start, arr2[subroot].lt, depth - (bf == 1 ? 2 : 1));
                if (s.size == 0)
                {
                    // No next less subtree.
                    if (bf == 1)
                        // No next balance factor.
                        return(s);
                    // Go to next balance factor, then start iteration
                    // all over with first less and first greater subtrees.
                    bf++;
                    s = first(start, depth - (bf == 1 ? 2 : 1));
                }
                start += s.size;
                arr2[start].lt = s.root;
                s.root = start;
                sub s2 = first(s.root + 1, depth - (bf == -1 ? 2 : 1));
                arr2[s.root].gt = s2.root;
                arr2[s.root].bf = bf;
                s.size += s2.size + 1;
            }
        }

        return(s);
    }

    void dump(unsigned subroot, unsigned depth)
    {
        if (arr2[subroot].lt != ~0)
            dump(arr2[subroot].lt, depth + 1);
        printf("%u(%u, %d) ", subroot, depth, arr2[subroot].bf);
        if (arr2[subroot].gt != ~0)
            dump(arr2[subroot].gt, depth + 1);
    }

public:

    // Copy from shadow node array to main node array and set tree root.
    void place(void)
    {
        memcpy(arr, arr2, t.size * sizeof(arr[0]));
        tree.pub_root = t.root | HIGH_BIT;
    }

    void first(unsigned d)
    {
        depth_ = d;
        t = first(0, depth_);
    }

    bool next(void)
    {
        if (t.size == 0)
            bail("possible_trees::next");
        t = next(0, t.root, depth_);
        return(t.size > 0);
    }

    void dump(void)
    {
        dump(t.root, 0);
        putchar('\n');
    }

    possible_trees(void)
    {
        t.size = 0;
    }

};

possible_trees pt;

// Tests for each tree in the iteration.
void one_tree(void)
{
    pt.place();
    unsigned h = tree.search_least();
    while (h != ~0)
    {
        arr[400].val = 2 * h - 1;
        insert(400);
        verify_tree();
        pt.place();

        arr[400].val = 2 * h + 1;
        insert(400);
        verify_tree();
        pt.place();

        remove(2 * h);
        verify_tree();
        pt.place();

        h = tree.search(2 * h, abstract_container::GREATER);
    }
}

void all_trees(unsigned depth)
{
    pt.first(depth);
    do
        one_tree();
    while (pt.next());
}

// Array of handles in order by node key.
unsigned h_arr[400];

// Test the build member function template by building tress with from 1
// to 400 nodes.
void build_test(void)
{
    unsigned i;

    tree.build(h_arr, 0);
    check_empty();

    for (i = 0; i < 400; i++)
    {
        h_arr[i] = i | HIGH_BIT;
        tree.build(h_arr, i + 1);
        verify_tree();
    }
}

int main()
{
    unsigned i;

    for (i = 0; i < 400; i++)
        arr2[i].val = i * 2;

    memcpy(arr, arr2, sizeof(arr));

    max_elems = 3;
    mark_bf();

    printf("0 nodes\n");

    check_empty();

    search_all();

    printf("1 node\n");

    insert(1);
    insert(1);
    verify_tree();
    search_all();
    remove(2);
    remove(2, true);
    check_empty();

    printf("2 nodes less slant\n");

    insert(2);
    insert(2);
    insert(1);
    insert(1);
    verify_tree();
    search_all();
    remove(2);
    remove(2, true);
    insert(1);
    verify_tree();
    remove(4);
    remove(4, true);
    verify_tree();
    remove(2);
    check_empty();

    printf("2 nodes greater slant\n");

    insert(1);
    insert(1);
    insert(2);
    insert(2);
    verify_tree();
    search_all();
    remove(4);
    remove(4, true);
    insert(2);
    verify_tree();
    remove(2);
    remove(2, true);
    verify_tree();
    remove(4);
    check_empty();

    max_elems = 400;

    printf("%u nodes\n", max_elems);

    mark_bf();

    big_test(3, 7);
    big_test(13, 7);

    printf("all trees depth 3\n");

    all_trees(3);

    printf("all trees depth 4\n");

    all_trees(4);

    printf("all trees depth 5\n");

    all_trees(5);

    printf("build test\n");

    build_test();

    printf("SUCCESS!\n");

    return(0);
}
