#include <iostream>
#include <stdlib.h>
#include <time.h>
#include <stdio.h>
#include <fstream>
#include <iomanip>

using namespace std;

#define MAXlevel 20

struct node
{
    int key;         //关键码
    int newlevel;    //级数
    struct node *forward[MAXlevel];
};

int randX(int &level);                                //按指数分布的随机级数产生函数
struct node *inilialization(int &level,int &total);                        //初始化
void insert (struct node *head,int key,int &level,int newlevel);           //插入
void output(struct node *head,int level);                                  //输出函数
bool delnode (node *head,int &level);                                      //删除函数
struct node *search(struct node *head,int key,int level);    //查找函数
void save(struct node *head,FILE *fp);                                     //保存链表函数
struct node *load(FILE *fp,int &plevel);                                  //恢复链表函数
int Max (struct node *);

int main()
{
    int i=0,level,newlevel,total,key,&plevel=level,&ptotal=total;
    struct node *h=NULL,*p;
    FILE *fp;

    srand((unsigned int)time(0));
    h=inilialization(plevel,ptotal);

    cout<<"输入您的选择："<<endl;
    cout<<"0、退出 1、插入 2、检索 3、删除 4、遍历 5、存储 6、恢复 7、清空文件"<<endl;

    while(i==0)
    {
        switch(getchar())
        {
            case '0':
                i=1;
                break;
            case '1' :
                cout<<"输入要插入的数"<<endl;
                cin>>key;
                newlevel=randX(plevel);
                insert(h,key,plevel,newlevel);
                output(h,level);
                break;
            case '2':
                cout<<"输入要检索的数"<<endl;
                cin>>key;
                p=search(h,key,level);
                if(!p)  
                {   
                    cout<<"==>?"<<endl;
                    cout<<"该数不在其中"<<endl;
                }
                else    
                {   
                    cout<<"检索成功"<<endl;
                }
                break;
            case '3':
                if(delnode(h,level))
                {   
                    cout<<"删除成功"<<endl;
                    output(h,level);    
                }
                break;
            case '4':
                output(h,level);
                break;
            case '5':
                if((fp=fopen("node.db","wb"))==NULL)/* 只写打开或建立一个二进制文件，只允许写数据  */
                {
                    cout<<"打不开文件，按任意键退出!!"<<endl;
                    getchar();
                    exit(-1);
                }
                save(h,fp);
                fclose(fp);
                break;
            case '6':
                if((fp=fopen("node.db","rb"))==NULL)/* 只读打开一个二进制文件，只允许读数据  */
                {
                    cout<<"打不开文件，按任意键退出!"<<endl;
                    getchar();
                    exit(-1);
                }
                h=load(fp,plevel);
                fclose(fp);
                break;
            case '7':
                if((fp=fopen("node.db","ab+"))==NULL)
                {
                    cout<<"打不开文件，按任意键退出!"<<endl;
                    getchar();
                    exit(-1);
                }
                fclose(fp);
                /* You can delete a file with unlink or remove. */
                if(unlink("node.db")==-1)
                    cout<<"文件不存在"<<endl;
                else 
                    cout<<"成功清空文件"<<endl;
                break;
            default:
                cout<<"输入您的选择："<<endl;
                cout<<"0、退出 1、插入 2、检索 3、删除 4、遍历 5、存储 6、恢复 7、清空文件"<<endl;
        }
    }
    
    return 0;
}

int randX(int &level)             //按指数分布的随机级数产生函数
{
    int i,j,t;
    t=rand();
    for(i=0,j=2;i<MAXlevel;i++,j+=j) 
        if(t>RAND_MAX/j) 
            break;
    if(i>level) 
        level=i;

    return i;
}

struct node *inilialization(int &level,int &total)      //初始化
{
    int i;
    struct node *head;

    head = new(struct node);
    for(i=0;i<MAXlevel;i++) 
        head->forward[i]=0;
    head->key=0;
    head->newlevel=0;
    level=0;
    total=0;
    return head;
}

void insert (struct node *head,int key,int &level,int newlevel)          //插入
{
    struct node *p,*updata[MAXlevel];
    int i;
    p=head;
    p->newlevel=level;

    if(newlevel>level) 
        level=newlevel;           //如果要插入点的级数比最大级数大，将其赋给最大级数
    else 
        level=level;

    cout<<"节点级数:"<<newlevel<<endl;
    for(i=level;i>=0;i--)
    {
        while((p->forward[i]!=0)&&(p->forward[i]->key<key)) 
            p=p->forward[i];
        updata[i]=p;                     //updata[i]记录了搜索过程中在各级走过的最大节点位置
    }
    p=new(struct node);
    p->key=key;                                         //设置新节点
    p->newlevel=newlevel;
    for(i=0;i<MAXlevel;i++) 
        p->forward[i]=0;
    for(i=0;i<=newlevel;i++)                             //插入是从最高的newlevel层链直至0层链
    {
        p->forward[i]=updata[i]->forward[i];             //插入到分配的级数链
        updata[i]->forward[i]=p;
    }
}

struct node *search(struct node *head,int key,int level)       //查找
{
    int i;
    struct node *p;
    p=head;
    cout<<"搜索路径："<<endl;
    cout<<"head";

    for(i=level;i>=0;i--)
    {  
        while((p->forward[i]!=0)&&(p->forward[i]->key<=key))      
        {
            p=p->forward[i];
            cout<<"==>"<<p->key;
        }
        if(p->key==key)  
        {
            cout<<endl;
            return p;
        }
        else p=p;
    }
    p=p->forward[0];                    //回到0级链，当前p或者为空或者指向比搜索关键字小的前一个节点
    if(!p) 
        return 0;
    else if(p->key==key) 
        return (p);
    else 
        return (NULL);
}

bool delnode (node *head,int &level) //删除成功返回true,否则返回false
{
    int key;
    node *r;
    cout<<"请输入你所要删除的数据: ";
    cin>>key;
    r=search(head,key,level); //先检索要删除的数值是否存在
    if (r)
    {   
        cout<<r->key<<endl;
        cout<<"找到要删除的数据"<<endl;
        int i=level;
        node *p,*q;
        while (i>=0)
        {
            p=q=head;
            while (q!=r && q)
            {
                p=q;
                q=q->forward[i];
            }
            if (q)
            {
                p->forward[i]=q->forward[i];
            }
            i--;
        }
        level=Max(head);
        head->newlevel=level;
        return(true);
    }
    else 
    {
        cout<<"==>?"<<endl;
        cout<<"没找到要删除的节点!"<<endl;
    }
    return(false);
}

int Max(struct node *head)            //求最大级数
{
    int i=MAXlevel,level;
    struct node *p;
    p=new(node);
    p=head;
    level=0;
    
    while(i>=1)
    {
        if(p->forward[i]==0&&p->forward[i-1]!=0) 
        {
            level=i-1;
            return level;
        }
        else i--;
    }
    return level;
}

void output(struct node *head,int level)         //输出函数
{
    int i=0 ,total=0;
    struct node *head1,*p;
    if(!head->forward[0])  
        cout<<"空表"<<endl;
    else
    {
        if (head)
        {  
            cout<<"遍历如下："<<endl;
            cout<<"head";
            head1=head->forward[0];
            while (head1)
            {
                cout<<"     "<<head1->key;
                head1=head1->forward[0];
                total++;
            }
            cout<<endl;
            for(i=0;i<=level;i++)
            { 
                p=head->forward[i];
                cout<<"head";
                while(p)
                {
                    if(p->newlevel==i)  
                        cout<<"---->"<<p->key;
                    p=p->forward[i];
                }
                cout<<"---->NULL"<<endl;
            }
            cout<<"现在共有"<<total<<"个节点"<<endl;
            cout<<"最大级数为"<<Max(head)<<"级"<<endl;
        }
        else cout<<"表为空!"<<endl;
    }
}

struct node *load(FILE *fp,int &plevel)        //从文件中恢复链表
{   
    int ptotal=0;
    plevel=0;
    struct node *p,*head,*head1;
    
    head=new(struct node);
    p=(struct node *)malloc(sizeof(node)); //申请一个节点空间
    if(!p)
        exit(-1);
    head=inilialization(plevel,ptotal);
    fread(p,sizeof(struct node),1,fp); //预读一次文件
    plevel=p->newlevel;
    while(!feof(fp))       //不是结尾，则插入链表
    {
        insert(head,p->key,plevel,p->newlevel);
        p=(struct node *)malloc(sizeof(node));
        if(!p)
            exit(-1);
        fread(p,sizeof(struct node),1,fp); //继续读文件
    }
    head1=head->forward[0];
    output(head1,plevel);
    
    return head1;
}

void save(struct node *head,FILE *fp)          //保存链表至文件
{
    struct node *p;
    p=head;
    if(!p->forward[0])  
        cout<<"空表，请先输入数据再保存！"<<endl;
    else
    {
        while(p)
        {
            fwrite(p,sizeof(struct node),1,fp);//每次写入一个长度是stu字节数的纪录
            p=p->forward[0];
        }
        cout<<"保存成功"<<endl;
    }
}
