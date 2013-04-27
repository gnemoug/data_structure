#ifndef __BINARY_TREE_H__
#define __BINARY_TREE_H__
#include<string>
#include<vector>
#include<set>
#include<map>
#include<algorithm>
#include<cmath>
using namespace std;
template<class Elem>
class BinaryTree
{
protected:
	typedef struct Node
	{
	public:
		Node(){ left = right = parent =-1;}
		Elem element;
		unsigned int left;
		unsigned int right;
		unsigned int parent;
	}Node;
	std::vector<Node> data;
	virtual unsigned int Depth(unsigned int index)const
	{
		if(index < data.size()){
			unsigned int l,r,ld = 0,rd = 0;
			l = data[index].left;
			r = data[index].right;
			if(l < data.size()){
				ld = Depth(l);
			}
			if(r < data.size()){
				rd = Depth(r);
			}
			return ld > rd ? (ld+1) : (rd+1);
		}
		return 0;
	}
public:
	typedef enum ChildEnum
	{
		Left=0,Right=1,None=-1,
	}ChildEnum;
protected:
	virtual void MarkChildren(unsigned int index,vector<unsigned int>& marks)
	{
		if(index < data.size()){
			marks.push_back(index);
			if(data[index].left < data.size()){
				MarkChildren(data[index].left,marks);
			}
			if(data[index].right < data.size()){
				MarkChildren(data[index].right,marks);
			}
		}
	}
public :
	//typedef typename Elem Elem;
	BinaryTree<Elem>(){}
	BinaryTree<Elem>(const BinaryTree<Elem>& T)
	{
		data.insert(T.data.begin(),T.data.end());
	}
	BinaryTree<Elem>(const Elem& value,unsigned int totalNo)
	{
		if(totalNo >0 ){
			unsigned int depth = (unsigned int)(log((double)(totalNo+1))/log(2.0));
			Root(value);
			if(depth > 1){
				vector<unsigned int> leafs;
				unsigned int u= depth,i;
				while(u > 0){
					if(data.size() == totalNo){
						break;
					}
					leafs.clear();
					MarkLeaf(leafs);
					for(i = 0; i < leafs.size(); ++i){
						if(data.size() < totalNo){
							InsertChild(leafs[i],Left,value);
						}else{
							break;
						}
						if(data.size() < totalNo){
							InsertChild(leafs[i],Right,value);
						}else{
							break;
						}
					}
					u--;
				}
			}
		}
		//(totalNo+1)
	}
	BinaryTree<Elem>(const Elem& value,unsigned int depth,unsigned int leafNo)
	{
		vector<unsigned int> leafs;
		unsigned int i,j,other;
		Root(value);
		for(i = 1 ; i < depth-1; i++){
			MarkLeaf(leafs);
			for(j = 0; j < leafs.size(); ++j){
				InsertChild(leafs[j],Left,value);
				InsertChild(leafs[j],Right,value);
			}
			leafs.clear();
		}
		MarkLeaf(leafs);
		other = leafNo - leafs.size();
		for(j = 0  ; j < other; j++ ){
			InsertChild(leafs[j],Left,value);
			InsertChild(leafs[j],Right,value);
		}
		for(j = other  ; j < leafs.size(); j++ ){
			InsertChild(leafs[j],Left,value);
		}
	}
	virtual bool IsEmpty(void)const{return data.empty();}
	virtual unsigned int Depth(void) const
	{
		if(data.size()>0){
			unsigned int l,r,ld = 0,rd = 0;
			l = data[0].left;
			r = data[0].right;
			if(l < data.size()){
				ld = Depth(l);
			}
			if(r < data.size()){
				rd = Depth(r);
			}
			return ld > rd ? (ld+1) : (rd+1);
		}else{
			return 0;
		}
	}
	virtual void Assign(unsigned int index,const Elem& value)
	{
		if(index < data.size()){
			data[index].element = value;
		}else if(index == data.size()){
			Node node = Node();
			node.element = value;
			data.push_back(node);
		}
	}
	virtual void Root(const Elem& value)
	{
		Clear();
		Node node = Node();
		node.element = value;
		data.push_back(node);
	}
	virtual Elem* Root(void)
	{
		if(data.size() >0)
			return &(data[0].element);
		return NULL;
	}
	virtual Elem* Value(unsigned int index)
	{
		if(index < data.size())
			return &(data[index].element);
		return NULL;
	}
	virtual Elem* Parent(unsigned int index)
	{
		if(index >= data.size())
			return NULL;
		unsigned int p = data[index].parent;
		if(p < data.size())
			return &(data[p].element);
		return NULL;
	}
	virtual Elem* LeftChild(unsigned int index)
	{
		if(index >= data.size())
			return NULL;
		unsigned int l = data[index].left;
		if(l < data.size())
			return &(data[l].element);
		return NULL;
	}
	virtual Elem* RightChild(unsigned int index)
	{
		if(index >= data.size())
			return NULL;
		unsigned int r = data[index].right;
		if(r < data.size())
			return &(data[r].element);
		return NULL;
	}
	virtual Elem* LeftSibling(unsigned int index)
	{
		if(index >= data.size())
			return NULL;
		unsigned int p = data[index].parent;
		if(p >= data.size())
			return NULL;
		unsigned int l = data[p].left;
		if(l < data.size())
			return &(data[l].element);
		return NULL;
	}
	virtual Elem* RightSibling(unsigned int index)
	{
		if(index >= data.size())
			return NULL;
		unsigned int p = data[index].parent;
		if(p >= data.size())
			return NULL;
		unsigned int r = data[p].right;
		if(r < data.size())
			return &(data[r].element);
		return NULL;
	}
	virtual void Clear(void)
	{
		data.clear();
	}
	virtual bool InsertChild(unsigned int index,int flag,const BinaryTree<Elem>& t)
	{
		unsigned int offset = data.size();
		unsigned int append = t.data.size();
		unsigned int i;
		if(index < data.size()){
			if(t.data.size() >0){
				if(flag == Left){
					if(data[index].left >= data.size()){
						for(i=0; i < append; i++){
							data.push_back(t.data[i]);
							data[offset+i].parent = index;
							if(t.data[i].left < append){
								data[offset+i].left += offset;
							}
							if(t.data[i].right < append){
								data[offset+i].right += offset;
							}
						}
					}
				}else if(flag == Right){
					if(data[index].right >= data.size()){
						for(i=0; i < append; i++){
							data.push_back(t.data[i]);
							data[offset+i].parent = index;
							if(t.data[i].left < append){
								data[offset+i].left += offset;
							}
							if(t.data[i].right < append){
								data[offset+i].right += offset;
							}
						}
					}
				}
			}
		}	
		return false;
	}
	virtual unsigned int InsertChild(unsigned int index,int flag,const Elem& value)
	{
		if(index < data.size()){
			if(flag == Left && data[index].left >= data.size() ){
				Node node;
				node.element = value;
				node.left = -1;
				node.right = -1;
				node.parent = index;
				data[index].left = data.size();
				data.push_back(node);
				return data.size()-1;
			}else if(flag == Right && data[index].right >= data.size()){
				Node node;
				node.element = value;
				node.left = -1;
				node.right = -1;
				node.parent = index;
				data[index].right = data.size();
				data.push_back(node);
				return data.size()-1;
			}
		}
		return -1;
	}
	virtual bool DeleteChild(unsigned int index,int flag)
	{
		unsigned int i,j,k;
		if(index < data.size()){
			vector<unsigned int> marks;
			if(flag == Left && data[index].left < data.size()){
				MarkChildren(data[index].left,marks);
				data[index].left = -1;
			}else if(flag == Right && data[index].right < data.size()){
				MarkChildren(data[index].right,marks);
				data[index].right = -1;
			}
			if(marks.size()>0){//have elem to delete;
				unsigned int newSize = data.size() - marks.size();
				std::sort(marks.begin(),marks.end());
				vector<unsigned int> swaps;
				for(i = 0 ;i < marks.size(); ++i){
					if(marks[i] >= newSize ){
						dels.insert(marks[i]);
					}
				}
				for(j = newSize; j < data.size(); ++j){
					if(dels.find(j) == dels.end()){
						swaps.push_back(j);
					}
				}
				map<unsigned int,unsigned int> swapMap;
				for(k = 0; k < swaps.size(); ++k){
					swapMap[swaps[k]] = marks[k];
				}
				for(k = 0; k < swaps.size(); ++k){
					data[marks[k]] = data[swaps[k]];
				}
				for(i = 0; i < newSize; ++i){
					unsigned int l = data[i].left,r =data[i].right;
					if(l < data.size() && swapMap.find(l) != swapMap.end()){
						data[i].left = swapMap[l];
					}
					if(r < data.size() && swapMap.find(r) != swapMap.end()){
						data[i].right = swapMap[r];
					}
				}
				for(i = 0 ; i < marks.size(); ++i){
					data.pop_back();
				}
				return true;
			}
		}
		return false;
	}
	virtual void MarkLeaf(vector<unsigned int>& marks)
	{
		for(unsigned int i=0; i < data.size();i++){
			if(data[i].left > data.size() && data[i].right > data.size() ){
				marks.push_back(i);
			}
		}
	}
};


#endif
