#include <fstream>
#include <sys/time.h>
#include <time.h>
#include <assert.h>
#include <iostream>
#include <cstring>
#include <cstdlib>
#include <sstream>
#include <vector>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "AvlTreeNode.h"

using namespace std;

//define the AvlTreeNode
class StockNode : public AvlTreeNode
{
    public :
        int date;
        string line;
        float deal;

    public :
        StockNode(int pdate,string pline,float pdeal): date(pdate), line(pline), deal(pdeal) 
        {
            
        }
        string GetLine()
        { 
            return line; 
        }
        int GetDate()
        {
            return date;
        }
        float GetDeal()
        {
           return deal;  
        }
        //to compare to StockNode,the avltree to judge the tree for this.
        int CompareTo(const Comparable* pComparable) const
        { 
            return date - (static_cast<const StockNode*>(pComparable))->date;
        }
};

vector<float> deals;
vector<string> lines;
vector<int> dates;
vector<string> stocks;
vector<string> uniquestocks;
vector<AvlTreeNode*> stocktrees;

vector<float>::iterator deal_it;
//vector<float>::reverse_iterator rdeal_it = deals.rbegin();
vector<string>::iterator line_it;

//convert the char* to string
string cstr_to_string(const char *p_str);
//print the deal and line info.
void printf_deal_line();
//print the stocks,dates,deals andd lines info.
void printf_stock_date_deal_line();
//read deals and lines from file.
void create_init_data();
//create the index avl tree.
void create_index_tree();
//the implemention of the insert sort
void insertSort();
//read deals,stocks,dates and lines from file.
void avl_create_init_data();
//destory the data of deals and the lines.
void destory_data();
//destory the data of deals,stocks,dates and the lines.
void avl_destory_data();
//save the sorted data to file.
void save_sorteddata(string filename);
//the tmep of the quick sort.
int partion(int s, int e);
//the implemention of the quick sort.
void quickSort(int s, int e);
//traverse the stocktrees for print
void traversestocks();
//delete the index avl tree.
void freeindextree();
//search the index avl tree by the StockNode object and the stock.
void searchStock(StockNode *pnode,string pstock);

/*
 * args:
 *      p_str:the pointer points to char*
 * return:the string object that have the same content with p_str
 * doc:convert the char* to string
 *
 */
string cstr_to_string(const char *p_str)
{
    return p_str; 
}

/*
 * args:
 * return:
 * doc:print the deal and line info.
 *
 */
void printf_deal_line()
{
    assert (deals.size() == lines.size());

    for(int i = 0;i < deals.size();i++)
    {
       printf("deal:\n%f\n",deals.at(i));
       printf("line:\n%s\n",lines.at(i).c_str());
    }
}

/*
 * args:
 * return:
 * doc:print the stocks,dates,deals andd lines info.
 *
 */
void printf_stock_date_deal_line()
{
    assert (deals.size() == lines.size());
    assert (stocks.size() == dates.size());
    assert (lines.size() == stocks.size());

    for(int i = 0;i < deals.size();i++)
    {
       printf("stocks:\n%s\n",stocks.at(i).c_str());
       printf("dates:\n%d\n",dates.at(i));
       printf("deal:\n%f\n",deals.at(i));
       printf("line:\n%s\n",lines.at(i).c_str());
    }
}

/*
 * args:
 * return:
 * doc:read deals and lines from file.
 *
 */
void create_init_data()
{
    char *lim = NULL; 
    char line[256] = {0};
    ifstream infile; 

    infile.open("demo.txt");
    if(infile.is_open())//the file is open?
    {
        while(!infile.eof())//read to the end of the file
        {
            infile.getline(line,256);
            //ignore the blank line
            if(line[0] == 0)
            {
                continue;
            }
            lines.push_back(cstr_to_string(line));//read the whole line into the lines
            strtok(line,"_");
            for(int i = 0;i < 6;i++)
            {
                lim = strtok(NULL,"_");
            }
            deals.push_back(atof(lim));//get the deal about the stock
            memset(line,0,256);
        }
        infile.close();
      /*
       *doc: for test all data all into deals, that is meaning we had read all of the data 
      for(rdeal_it = deals.rbegin();rdeal_it != deals.rend(); rdeal_it++)
      {
         printf("deal:\n%f\n",*rdeal_it);  
      }
      */
      /*
       *doc:cout the size of the data
      cout << "deal's size is:" << deals.size() << "------" << "line's size is:" << lines.size() << endl;
       */
    }else
    {
        cout << "Error opening file" << endl;  
    }
}

/*
 * args:
 * return:
 * doc:read deals,stocks,dates and lines from file.
 *
 */
void avl_create_init_data()
{
    char *lim = NULL; 
    char line[256] = {0};
    ifstream infile; 

    infile.open("demo.txt");
    if(infile.is_open())
    {
        while(!infile.eof())
        {
            infile.getline(line,256);
            if(line[0] == 0)
            {
                continue;
            }
            lines.push_back(cstr_to_string(line));
            lim = strtok(line,"_");
            stocks.push_back(cstr_to_string(lim));
            lim = strtok(NULL,"_");
            dates.push_back(atoi(lim));
            for(int i = 0;i < 5;i++)
            {
                lim = strtok(NULL,"_");
            }
            deals.push_back(atof(lim));
            memset(line,0,256);
        }
        infile.close();
    }else
    {
        cout << "Error opening file" << endl;  
    }
}

/*
 * args:
 * return:
 * doc:create the index avl tree.
 *
 */
void create_index_tree()
{
    assert (deals.size() == lines.size());
    assert (stocks.size() == dates.size());
    assert (lines.size() == stocks.size());
     
    for(int i = 0;i < deals.size();i++)
    {
        int j = 0;
        for(j = 0;j < uniquestocks.size();j++)
        {
            if(stocks.at(i) == uniquestocks.at(j))
            {
                break;
            }
        }
        if(j == uniquestocks.size())
        {
            AvlTreeNode* Root = new StockNode(dates.at(i),lines.at(i),deals.at(i));
            stocktrees.push_back(Root);
            uniquestocks.push_back(stocks.at(i));     
        }else
        {
            AvlTreeNode* Root = stocktrees.at(j)->Insert(new StockNode(dates.at(i),lines.at(i),deals.at(i)));
            stocktrees.at(j) = Root;
        }
    }
}

/*
 * args:
 * return:
 * dco:destory the data of deals and the lines.
 *
 */
void destory_data()
{
    deals.clear();
    lines.clear();
}

/*
 * args:
 * return:
 * dco:destory the data of deals,stocks,dates and the lines.
 *
 */
void avl_destory_data()
{
    deals.clear();
    lines.clear();
    stocks.clear();
    dates.clear();
}

/*
 * args:
 * return:
 * doc:the implemention of the insert sort
 *
 */
void insertSort()
{
    assert (deals.size() == lines.size());

    for(int i = 1; i < deals.size(); i++)
    {
        float temp = deals.at(i);
        string tempdata = lines.at(i);
        int j;

        //make sure you must use deals[i] instead of deals.at(i),
        //because deals.at(-i) will raise out_of_range error
        for(j = i - 1; temp > deals[j] && j >= 0; j--)
        {
            //cout << deals.at(j+1) << "------" << deals.at(j) << endl;
            deals.at(j + 1) = deals.at(j);
            lines.at(j + 1) = lines.at(j);
        }
        deals.at(j + 1) = temp;
        lines.at(j + 1) = tempdata;
    }
}

/*
 * args:
 * return:
 * doc:the tmep of the quick sort.
 *
 */
int partion(int s, int e)
{
    int start = s;
    int end = e;

    float temp = deals.at(s);
    string datatemp = lines.at(s);

    while(start < end)
    {
        while(start < end && deals.at(end) < temp) 
        {
            end--;
        }

        if(start < end)
        {
            deals.at(start) = deals.at(end);
            lines.at(start) = lines.at(end);
            start++;
        }

        while(start < end && deals.at(start) > temp) 
        {
            start++;    
        }

        if(start < end)
        {
            deals.at(end) = deals.at(start);
            lines.at(end) = lines.at(start);
            end--;
        }
    }

    deals.at(start) = temp;
    lines.at(start) = datatemp;

    return start;
}

/*
 * args:
 * return:
 * doc:the implemention of the quick sort.
 *
 */
void quickSort(int s, int e)
{
    if( s < e )
    {
        int temp = partion(s,e);
        quickSort(s,temp - 1);
        quickSort(temp + 1, e);
    }
}

/*
 * args:
 *      filename:the file name to save data.
 * return:
 * doc:save the sorted data to file.
 *
 */
void save_sorteddata(string filename)
{
    ofstream resultfile;

    resultfile.open(filename.c_str(),ofstream::out);
    if(resultfile.is_open())//判断文件是否打开
    {
        for(int i = 0;i < lines.size();i++)
        {
            resultfile.write((lines.at(i) + '\n').c_str(),lines.at(i).length() + 1);
        }
        resultfile.close();
    }else
    {
        cout << "Error opening file:" << filename << endl;  
    }
}

/*
 * args:
 * return:
 * doc:traverse the stocktrees for print
 *
 */
void traversestocks()
{
    assert (uniquestocks.size() == stocktrees.size());
    AvlTreeNode::TraversePath  sTraversePath;
    StockNode* pNode;

    for(int i = 0;i < uniquestocks.size();i++)
    {
        printf("Traverse %s:\n",uniquestocks.at(i).c_str());
        stocktrees.at(i)->InitTraverse(&sTraversePath);

        pNode = static_cast<StockNode*>(stocktrees.at(i)->Traverse(&sTraversePath));

        do
        {
            printf("%s\n", pNode->GetLine().c_str());
            pNode = static_cast<StockNode*>(stocktrees.at(i)->Traverse(&sTraversePath));
        }while(pNode);
    }
}

/*
 * args:
 * return:
 * doc:delete the index avl tree.
 *
 */
void freeindextree()
{
    assert (uniquestocks.size() == stocktrees.size());
    AvlTreeNode::TraversePath  sTraversePath;
    StockNode* pNode;

    for(int i = 0;i < uniquestocks.size();i++)
    {
        //printf("Delete %s stock\n",uniquestocks.at(i).c_str());
        stocktrees.at(i)->InitTraverse(&sTraversePath);

        pNode = static_cast<StockNode*>(stocktrees.at(i)->Traverse(&sTraversePath));
        delete pNode;

        do
        {
            pNode = static_cast<StockNode*>(stocktrees.at(i)->Traverse(&sTraversePath));
            delete pNode;
        }while(pNode);
    }
}

/*
 * args:
 *      pnode:the StockNode pointer points to the node you want to search,
 *      pstock: the stock name you search.
 * return:
 * doc:search the index avl tree by the StockNode object and the stock.
 *
 */
void searchStock(StockNode *pnode,string pstock)
{
    AvlTreeNode::ProbePath sProbePath;
    AvlTreeNode::probe_result eResult;
    
    int i;
    for(i = 0;i < uniquestocks.size();i++)
    {
        if(pstock == uniquestocks.at(i)){
            eResult = stocktrees.at(i)->Probe(pnode, &sProbePath);

            switch(eResult)
            {
                case AvlTreeNode::FOUND: 
                    printf(" -> found.\n"); 
                    printf("the deal is:%f\n",static_cast<StockNode*>(sProbePath.Access())->GetDeal());
                    printf("the line is:%s\n",static_cast<StockNode*>(sProbePath.Access())->GetLine().c_str());
                    break;
                case AvlTreeNode::NOT_FOUND: 
                    printf(" -> not found.\n"); 
                    break;
            }
            break;
        }  
    }
    if(i == uniquestocks.size())
    {
        printf(" -> not found.\n"); 
    }
}

int main(int argc, const char *argv[])
{
    int pdate;
    char pstock[256] = {0};
    struct timeval tv_start;
    struct timeval tv_end;
    //time_t stime,etime;

    /*****************************the insert sort****************************/
    create_init_data();
    //time(&stime);
    gettimeofday(&tv_start,NULL);
    insertSort();
    gettimeofday(&tv_end,NULL);
    //time(&etime);
    //cout << "the time of insertSort is:" << etime - stime << endl;
    if((unsigned int)tv_start.tv_usec < (unsigned int)tv_end.tv_usec)
    {
       printf("the time of insertSort is:%u seconds and %u microseconds.\n",(unsigned int)tv_end.tv_sec - (unsigned int)tv_start.tv_sec,(unsigned int)tv_end.tv_usec - (unsigned int)tv_start.tv_usec);  
    }else
    {
       printf("the time of insertSort is:%u seconds and %u microseconds.\n",(unsigned int)tv_end.tv_sec - (unsigned int)tv_start.tv_sec - 1,(unsigned int)tv_end.tv_usec - (unsigned int)tv_start.tv_usec + 1000000);
    }
    save_sorteddata("insertSort.txt");
    destory_data();

    /*****************************the quick sort****************************/
    create_init_data();
    //time(&stime);
    gettimeofday(&tv_start,NULL);
    quickSort(0,deals.size() - 1);
    gettimeofday(&tv_end,NULL);
    if((unsigned int)tv_start.tv_usec < (unsigned int)tv_end.tv_usec)
    {
       printf("the time of quickSort is:%u seconds and %u microseconds.\n",(unsigned int)tv_end.tv_sec - (unsigned int)tv_start.tv_sec,(unsigned int)tv_end.tv_usec - (unsigned int)tv_start.tv_usec);  
    }else
    {
       printf("the time of quickSort is:%u seconds and %u microseconds.\n",(unsigned int)tv_end.tv_sec - (unsigned int)tv_start.tv_sec - 1,(unsigned int)tv_end.tv_usec - (unsigned int)tv_start.tv_usec + 1000000);
    }
    //time(&etime);
    //cout << "the time of quickSort is:" << etime - stime << endl;
    save_sorteddata("quickSort.txt");
    destory_data();
   //printf_deal_line();

    /*****************************the avl tree****************************/
    avl_create_init_data();
    //printf_stock_date_deal_line();
    create_index_tree();
    avl_destory_data();
    printf("please insert the stock(the format like:000001),then enter the 'Enter' key\n");
    scanf("%s",pstock);
    printf("please insert the date(the format like:20080717),then enter the 'Enter' key\n");
    scanf("%d",&pdate);

    StockNode* pNode = new StockNode(pdate,"",0.0);
    gettimeofday(&tv_start,NULL);
    searchStock(pNode,cstr_to_string(pstock));
    gettimeofday(&tv_end,NULL);
    if((unsigned int)tv_start.tv_usec < (unsigned int)tv_end.tv_usec)
    {
       printf("the time of search is:%u seconds and %u microseconds.\n",(unsigned int)tv_end.tv_sec - (unsigned int)tv_start.tv_sec,(unsigned int)tv_end.tv_usec - (unsigned int)tv_start.tv_usec);  
    }else
    {
       printf("the time of search is:%u seconds and %u microseconds.\n",(unsigned int)tv_end.tv_sec - (unsigned int)tv_start.tv_sec - 1,(unsigned int)tv_end.tv_usec - (unsigned int)tv_start.tv_usec + 1000000);
    }
    delete pNode;
    //traversestocks();
    freeindextree();
}
