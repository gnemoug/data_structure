// Abstract AVL Tree Template Example 2.
// This code is in the public domain.
// Version: 1.2  Author: Walt Karas

// This example shows how to use the AVL template to create the
// ip_addr_cnt class.  Imagine we are writing software for an
// embedded CPU (with limited memory) that processes IP packets.
// We want to keep count of the number of times that we see each
// distinct destination address.  We can assume that we will see at
// most 100 distinct destination addresses.

#include "avl_tree.h"

// Count the number of times each IP address is seen.
class ip_addr_cnt
{
private:

    struct node_t
    {
        // IP address.
        unsigned long ip_addr;

        // Number of times IP address seen.
        unsigned short cnt;

        // Child pointers.  The high bit of gt is robbed and used as the
        // balance factor sign.  The high bit of lt is robbed and used as
        // the magnitude of the balance factor.
        unsigned char gt, lt;
    };

    unsigned char num_nodes_used;

    // Abstractor class for avl_tree template.
    struct abstr
    {
        // handle is index into node array.  Valid handles are 0 - 99.
        typedef unsigned char handle;

        // Key is IP address.
        typedef unsigned long key;

        typedef unsigned char size;

        // Up to 100 distinct addresses.
        node_t node[100];

        handle get_less(handle h, bool access)
        {
            return(node[h].lt & 127);
        }
        void set_less(handle h, handle lh)
        {
            node[h].lt &= 128;
            node[h].lt |= lh;
        }
        handle get_greater(handle h, bool access)
        {
            return(node[h].gt & 127);
        }
        void set_greater(handle h, handle gh)
        {
            node[h].gt &= 128;
            node[h].gt |= gh;
        }

        int get_balance_factor(handle h)
        {
            if (node[h].gt & 128)
                return(-1);
            return(node[h].lt >> 7);
        }
        void set_balance_factor(handle h, int bf)
        {
            if (bf == 0)
            {
                node[h].lt &= 127;
                node[h].gt &= 127;
            }
            else
            {
                node[h].lt |= 128;
                if (bf < 0)
                    node[h].gt |= 128;
            }
        }

        int compare_key_key(key k1, key k2)
        {
            if (k1 == k2)
                return(0);
            if (k1 > k2)
                return(1);
            return(-1);
        }

        int compare_key_node(key k, handle h)
        {
            return(compare_key_key(k, node[h].ip_addr));
        }

        int compare_node_node(handle h1, handle h2)
        {
            return(compare_key_key(node[h1].ip_addr, node[h2].ip_addr));
        }

        handle null(void)
        {
            return(127);
        }

        // Nodes are not stored on secondary storage, so this should
        // always return false.
        static bool read_error(void)
        {
            return(false);
        }
    };

    // An AVL tree with 100 nodes has a max. depth of 9.
    class tree_t : public abstract_container::avl_tree<abstr, 9>
    {
    public:
        node_t * get_node(unsigned char n)
        {
            return(abs.node + n);
        }
    };

    tree_t tree;

public:

    // The given IP address appeared as the destination address in a
    // packet.
    void see(unsigned long ip_addr)
    {
        unsigned char n;
        node_t *p;

        if (num_nodes_used == 100)
        {
            n = tree.search(ip_addr);
            if (n == 127)
                // More than 100 distinct addresses seen, so ignore.
                return;
            p = tree.get_node(n);
        }
        else
        {
            p = tree.get_node(num_nodes_used);
            p->ip_addr = ip_addr;
            p->cnt = 0;
            n = tree.insert(num_nodes_used);
            if (n != num_nodes_used)
                // This IP address was seen before, already has a node.
                p = tree.get_node(n);
            else
                num_nodes_used++;
        }

        // Increment seen count, handling saturation properly.
        if ((~(p->cnt)) != 0)
            p->cnt++;
    }

    // Dump contents of tree into array of addresses and corresponding
    // array of counts.
    unsigned char dump(unsigned long *ip_addr_list, unsigned short *cnt_list)
    {
        tree_t::iter it;
        unsigned char n;
        node_t *p;
        unsigned char num_addr = 0;

        it.start_iter_least(tree);

        for (n = *it; n != 127; it++, n = *it)
        {
            p = tree.get_node(n);
            *(ip_addr_list++) = p->ip_addr;
            *(cnt_list++) = p->cnt;
            num_addr++;
        }

        return(num_addr);
    }

};

ip_addr_cnt cnt;

// Demo main program.

#include <stdio.h>

int main(void)
{
    cnt.see(40);
    cnt.see(35);
    cnt.see(30);
    cnt.see(25);
    cnt.see(20);
    cnt.see(15);
    cnt.see(10);
    cnt.see(5);

    cnt.see(35);
    cnt.see(30);
    cnt.see(25);
    cnt.see(20);
    cnt.see(15);
    cnt.see(10);
    cnt.see(5);

    cnt.see(30);
    cnt.see(25);
    cnt.see(20);
    cnt.see(15);
    cnt.see(10);
    cnt.see(5);

    cnt.see(25);
    cnt.see(20);
    cnt.see(15);
    cnt.see(10);
    cnt.see(5);

    cnt.see(20);
    cnt.see(15);
    cnt.see(10);
    cnt.see(5);

    cnt.see(15);
    cnt.see(10);
    cnt.see(5);

    cnt.see(10);
    cnt.see(5);

    cnt.see(5);

    unsigned long ip_addr[100];
    unsigned short count[100];
    unsigned char i, num_addr = cnt.dump(ip_addr, count);

    for (i = 0; i < num_addr; i++)
        printf("%12lu %12u\n", ip_addr[i], count[i]);

    return(0);
}
