#include <algorithm>
#include <string.h>

template<class type> class Vector {
    static const int INIT = 5 ;
    static const int STEP = 2 ;
    int sz ;
    int cap ;
    type *v ;

    public :
    Vector (int n = 0) : sz(n) , cap(n > INIT ? n : INIT) {
        v = new type[cap] ;
    }
    Vector (int n , type val) : sz(n) , cap(n > INIT ? n : INIT) {
        v = new type[cap] ;
        for(int i = 0 ; i < n ; i++) v[i] = val ;
    }
    Vector (const Vector & b) : sz(b.sz) , cap(b.cap) {
        v = new type[cap] ;
        memcpy(v , b.v , sz * sizeof(type)) ;
    }
    ~Vector () {
        delete v ;
    }
    Vector & operator = (const Vector & b) {
        Vector <type> r(b) ;
        std::swap(sz , r.sz) ;
        std::swap(cap , r.cap) ;
        std::swap(v , r.v) ;
        return * this ;
    }
    void push_back(type val){
        if(sz < cap){
            v[sz++] = val ;
        }
        else {
            cap = cap * STEP ;
            type * v2 = new type[cap] ;
            memcpy(v2 , v , sz * sizeof(type)) ;
            v2[sz++] = val ;
            delete v ;
            v = v2 ;
        }
    }
    void pop_back(){
        if(sz) sz-- ;
    }
    const type & front() const {
        return v[0] ;
    }
    const type & back() const {
        return v[sz - 1] ;
    }
    const type & operator [] (int i) const {
        return v[i] ;
    }
    type & operator [] (int i) {
        return v[i] ;
    }
    int size() {
        return sz ;
    }
    int capacity() {
        return cap ;
    }
    bool operator < (const Vector & b) const {
        for (int i = 0 ; i < min(sz , b.sz) ; i++) {
            if(! (v[i] == b.v[i])) return v[i] < b.v[i] ;
        }
        return sz < b.sz ;
    }
    bool operator == (const Vector & b) const {
        for (int i = 0 ; i < min(sz , b.sz) ; i++) {
            if(! (v[i] == b.v[i])) return false ;
        }
        return sz == b.sz ;
    }
    bool operator > (const Vector & b) const {
        return b < *this ;
    }
    bool operator <= (const Vector & b) const {
        return !(b < *this) ;
    }
    bool operator >= (const Vector & b) const {
        return !(*this < b) ;
    }
    bool operator != (const Vector & b) const {
        return !(*this == b) ;
    }

/*
    struct iterator {
        type * p ;
        iterator operator ++ () {
            return (iterator){p++} ;
        }
        iterator operator -- () {
            return (iterator){p--} ;
        }
        iterator & operator ++ (int) {
            return (iterator){++p} ;
        }
        iterator & operator -- (int) {
            return (iterator){--p} ;
        }
    } ;
//*/
    typedef type * iterator ;
    iterator begin() {
        return iterator(v) ;
    }
    iterator end() {
        return iterator(v + sz) ;
    }

} ;


#define OUT(x) {clog << "# " << #x << ": \t" << x << endl ;}
#define For(i , n) for(int i = 0 ; i < (n) ; ++i)
#include <iostream>
using namespace std ;

int main(){

    Vector<string> vect , vect2 ;
    vect.push_back("456") ;
    vect.push_back("2") ;
    vect.push_back("3") ;
    vect.push_back("4") ;
    Vector<string>::iterator it;
    for(it=vect.begin();it<vect.end();it++){
       OUT(*it); 
    }
    OUT(vect[0]) ;
    OUT(vect[1]) ;
    OUT(vect[2]) ;
    OUT(vect[3]) ;
    OUT(vect.size()) ;
    OUT(vect.capacity()) ;


    while(1) ;
    return 0 ;
}
