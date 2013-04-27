#include <stdio.h>
#include <stdlib.h>

typedef int elemType;

struct List{
    elemType *list;
    int size;
    int maxSize;
};

//空间扩展 1 倍，并由 p 指针所指向
void againMalloc(struct List *L)
{
    elemType *p = realloc(L->list, 2 * L->maxSize * sizeof(elemType));
    if (!p)
    {
        printf("存储空间分配失败。");
        exit(1);
    }
    L->list = p;
    L->maxSize = 2 * L->maxSize;
}

//初始化线性表 L
void initList(struct List *L, int ms)
{
    if (ms <= 0)
    {
        printf("MaxSize 非法。");
        exit(1);
    }
    L->maxSize = ms;
    L->size = 0;
    L->list = malloc(ms * sizeof(elemType));
    if (!L->list)
    {
        printf("空间分配失败。");
        exit(1);
    }
    return;
}

//清楚线性表 L 中的所有元素，释放存储空间，成为一个空表
void clearList(struct List *L)
{
    if (L->list != NULL)
    {
        free(L->list);
        L->list = 0;
        L->size = L->maxSize = 0;
    }
    return;
}

//返回线性表 L 当前的长度
int sizeList(struct List *L)
{
    return L->size;
}

//判断线性表 L 是否为空
int emptyList(struct List *L)
{
    if (L->size == 0)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

//返回线性表 L 中第 pos 个元素的值
elemType getElem(struct List *L, int pos)
{
    if (pos < 1 || pos > L->size)
    {
        printf("元素序号越界。");
        exit(1);
    }
    return L->list[pos-1];
}

//遍历并输出每个元素
void traverseList(struct List *L)
{
    int i;

    for (i = 0; i < L->size; i++)
    {
        printf("%d ", L->list[i]);
    }

    return;
}

//查找 x 元素，返回其位置
int findList(struct List *L, elemType x)
{
    int i;

    for (i = 0; i < L->size; i++)
    {
        if (L->list[i] == x)
        {
            return i;
        }
    }

    return -1;
}

//将第 pos 个元素修改为 x，成功则返回 1
int updataPosList(struct List *L, int pos, elemType x)
{
    if (pos < 1 || pos > L->size)
    {
        return 0;
    }
    L->list[pos-1] = x;
    return 1;
}

//在线性表表头插入元素 x
void insertFirstList(struct List *L, elemType x)
{
    int i;

    if (L->size == L->maxSize)
    {
        againMalloc(L);
    }

    for (i = L->size - 1; i >= 0; i--)
    {
        L->list[i+1] = L->list[i];
    }
    L->list[0] = x;
    L->size++;
    return;
}

//在线性表表尾插入元素 x
void insertLastList(struct List *L, elemType x)
{
    if (L->size == L->maxSize)
    {
        againMalloc(L);
    }
    L->list[L->size] = x;
    L->size++;
    return;
}

//在线性表 pos 处插入元素 x
int insertPosList(struct List *L, int pos, elemType x)
{
    int i;

    if (pos < 1 || pos > L->size + 1)
    {
        return 0;
    }
    if (L->size == L->maxSize)
    {
        againMalloc(L);
    }
    for (i = L->size - 1; i >= pos - 1; i--)
    {
        L->list[i+1] = L->list[i];
    }
    L->list[pos-1] = x;
    L->size++;
    return 1;
}

//向有序列表中插入元素 x，依然有序
void insertOrderList(struct List *L, elemType x)
{
    int i, j;

    if (L->size == L->maxSize)
    {
        againMalloc(L);
    }

    for (i = 0; i < L->size; i++)
    {
        if (x < L->list[i])
        {
            break;
        }
    }
    for (j = L->size - 1; j >= i; j--)
    {
        L->list[j+1] = L->list[j];
    }
    L->list[i] = x;
    L->size++;
    return;
}

//删除线性表表头元素，并返回改元素
elemType deleteFirstList(struct List *L)
{
    elemType temp;
    int i;

    if (L->size == 0)
    {
        printf("线性表为空，不能进行删除操作。");
        exit(1);
    }
    temp = L->list[0];
    for (i = 1; i < L->size; i++)
    {
        L->list[i-1] = L->list[i];
    }
    L->size--;
    return temp;
}

//删除线性表表尾元素，并返回改元素
elemType deleteLastList(struct List *L)
{
    if (L->size == 0)
    {
        printf("线性表为空，不能进行删除操作。");
        exit(1);
    }
    L->size--;
    return L->list[L->size];
}

//删除线性表第 pos 个元素，并返回改元素
elemType deletePosList(struct List *L, int pos)
{
    elemType temp;
    int i;

    if (pos < 1 || pos > L->size)
    {
        printf("pos 值越界。");
        exit(1);
    }
    temp = L->list[pos-1];
    for (i = pos; i < L->size; i++)
    {
        L->list[i-1] = L->list[i];
    }
    L->size--;
    return temp;
}

//删除线性表为 x 的第一个元素
int deleteValueList(struct List *L, elemType x)
{
    int i, j;

    for (i = 0; i < L->size; i++)
    {
        if (L->list[i] == x)
        {
            break;
        }
    }

    if (i == L->size)
    {
        return 0;
    }

    for (j = i + 1; j < L->size; j++)
    {
        L->list[j-1] = L->list[j];
    }
    L->size--;
    return 1;
}
