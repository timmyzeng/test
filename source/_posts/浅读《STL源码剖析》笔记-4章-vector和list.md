---
title: 浅读《STL源码剖析》笔记 4章-vector和list
date: 2018-02-09 10:13:57
tags:
categories:
    - "learning"
---
## 4 序列式容器
### 4.1 容器的概观与分类
![SGI STL的各个容器](http://p3ax8ersb.bkt.clouddn.com/201801311638_540.png)
所谓序列式容器，其中的元素都是可序的(ordered),但未必有序(sorted)。C++本身有array，其它是STL提供的。
<!--more-->
### 4.2 vector
#### 4.2.1 vector概述
array是静态的，vector是动态增长的，随着元素的增加，内部机制自动扩充空间以容纳元素，不需要自己分配空间。
#### 4.2.3 vector的迭代器
由于vector维护的是连续线性空间，所以不论元素类型是什么，普通指针都可以作为vector的迭代器而满足要求。vector支持随机存取，普通指针也满足。`vector<int> :: iterator ivite;vector<Shape> :: iterator svite;`其中 `ivite`的类型就是`int*`，`svite`的类型就是`Shape*` 。
#### 4.2.4 vector的数据结构
vector的数据结构如下：
```c++
template<class T, class Alloc = alloc>
class vecotr{
    //...
    protected:
    //注意STL的左闭右开特性。finish和end_of_storage指向最后一个元素的下一个位置
        iterator start;             //表示目前使用空间的头部
        iterator finish;            //表示目前使用空间的尾部
        iterator end_of_storage;    //表示目前可用空间的尾部
}
```
为了降低空间配置时的成本，实际上，vector配置的空间会比客户端需要的更大一些，这样是为了将来可能扩充的准备。当容量等于大小的时候，开辟新的空间。
运用 start，finish，end_of_storage三个迭代器，可以实现begin(),end(),size(),capacity(),empty(),operator[],front(),back()等方法。

#### 4.2.5 vector的构造与内存管理：constructor，push_back
push_back：将新元素插入vector尾端的时候，先检查是否还有备用空间，够的话，直接构造元素，并调整finish。如果没有备用空间，动态增长空间。这指并不是在原空间之后开辟新的空间，因为无法保证原空间之后还有可供配置的空间。而是以原大小的两倍例外配置一块大的空间，然后将原内容拷贝过来，然后才开始在原内容之后构造新元素，并释放原空间。**因此，对于vector的任何操作，一旦引起了空间重新配置，指向原vector的所有迭代器都是失效了。**push_back源代码节选如下：
```c++
void push_back( const T& x){
    if( finish != end_of_storage ){
        construct( finish, x );
        ++finish;
    }
    else    //无备用空间
    insert_aux(end(), x);
}

template <class T, class Alloc>
void vector<T, Alloc>::insert_aux( iterator positon, const T& x ){
    if( finish != end_of_storage ){ //为什么还要再次判断
        construct( finish, *(finish - 1));
        ++finish;
        T x_copy = x;
        //不懂
        copy_backward(position, finish - 2, finish - 1);
        *position = x_copy;
    }
    else{   //无备用空间
        const size_type old_size = size();
        const size_type len = old_size != 0 ? 2*old_size : 1;
        iterator new_start = data_allocator::allocatr(len); //实际配置空间
        iterator new_finish = new_start;
        try{
            //将原来vector内容拷贝到新的vector
            new_finish = uninitialized_copy(start, position, new_start);
            //为新元素设定初值x
            construct(new_finish, x);
            ++new_finish;
            //将安插点的原内容也拷贝过来//不懂
            new_finish = uninitialized_copy(posiition, finish, new_finish);
        }
        catch(...){
            //开辟失败
            destroy(new_start, new_finish);
            data_allocator::deallocate(new_start, len);
            throw;
        }
        //析构并释放原vector
        destory(begin(), end());
        deallocate();
        //调整迭代器，指向新的vector
        start = new_start;
        finish = new_finish;
        end_of_storage = new_start+len;
    }
}
```

#### 4.2.6 vector的元素操作：pop_back, erase, clear, insert
```c++
//清除[first, last)中的元素
iterator erase(iterator first, iterator last){
    iterator ii = copy(last, finish, first);    //copy是全局函数，第六章
    destory(i, finish);
    finish = finish - (last - first);
    return first;
}
//清除某个位置上的元素
iterator erase(iterator position){
    if(position + 1 != end())
        copy(position + 1, finish, position);
    --finish;
    destroy(finish);
    return position;
}

void clear(){ erase(begin(), end()); }

//从position开始，插入n个元素，元素初值为x
template <class T, class Alloc>
void vector<T, Alloc>::insert(iterator position, size_type n ,const T& x){
    if(n != 0){
        //备用空间大于等于新增元素个数
        if(size_type(end_of_storage - finish) >= 0){
            T x_copy = x;
            //计算插入点之后的现有元素个数
            const size_type elems_after = finish - position;
            iterator old_finish = finish;
            if(elems_after > n){    //插入点之后的现有元素个数 > 新增元素个数
                uninitialized_copy(finish - n, finish, finish);
                finish += n;    //将vector 尾端标记后移
                copy_backward(position, old_finish - n, old_finish);
                fill(position, position+n, x_copy); //从插入点开始填入新值
            }
            else{
                uninitialized_fill_n(finish, n-elems_affter, x_copy);
                finish += n - elems_after;
                uninitialized_copy(position, old_finish, finish);
                finish += elems_after;
                fill(position, old_finish, x_copy);
            }
        }
        else{   //备用空间 < 新增元素个数
            const size_type old_size = size();
            //决定新的长度为旧长度+新增元素个数
            const size_type len = old_size + max(old_size, n);
            //配置新的vector空间
            iterator new_start = data_allocaator::allocate(len);
            iterator new_finish = new_start;
            __STL_TRY{  //<-- 这个是什么
                //将旧的vector在插入点之前的元素复制到新空间
                new_finish = uninitialized_copy(start, position, new_start);
                //将新增元素(初值为x)填入新空间
                new_finish = uninitialized_fill_n(new_finish, n, x);
                //将旧的vector在插入点之后的元素复制到新空间
                nwe_finish = uninitialized_copy(position, finish, new_finish);
            }
            //异常处理
            //...

            //清除释放旧的空间
            destroy(start，finish);
            deallocate();
            //调整迭代器指向新的空间
            start = new_start;
            finish = new_finish;
            end_of_storage = new_start+len;
        }
    }
}
//插入操作完成之后，新增节点应位于position的后面。
```
图解如下：![insert](http://p3ax8ersb.bkt.clouddn.com/201802021439_772.png)
### 4.3 list
#### 4.3.1 list概述
list每次插入或删除一个元素，就配置或释放一个元素空间。对于任何位置的元素插入或元素移除，是时间常数。
#### 4.3.2 list的节点(node)
list的节点和list本身的设计是分开的。以下是STL list的节点结构：
```c++
template <class T>
struct __list_node{
    typedef void* void_pointer;
    void_pointer prev;  //型别为void*，其实可以是__list_node<T>
    void_pointer next;
    T data;
}
//这是一个双向链表节点
```
#### 4.3.3 list的迭代器
**list的迭代器有一个重要性质，insert(插入)和splice(接合)操作都不会造成原有的迭代器失效。list的delete(删除)只有被删除的那个节点的迭代器失效**
#### 4.3.4 list的数据结构
SGI list 是一个双向循环链表。list结构如下：
```c++
template <class T, class Alloc = alloc>
class list{
protected:
    typedef __list_node<T> list_node;
public:
    typedef list_node* link_type;
protected:
    link_type node;
}
```
**STL中指针node指向尾端的一个空白节点，以符合STL中前闭后开规范。**
```c++
iterator begin() { return (link_type)((*node).next); }
iterator end() { return node; }
bool empty() const { return node->next == node; }
size_type size() const {
    size_type result = 0;
    distance(begin(), end(), result);   //全局函数，第三章//计算两个迭代器之间的距离
    return result;
}
reference front() { return *begin(); }
reference back() { return *(--end()); }
```
图解如下：![list](http://p3ax8ersb.bkt.clouddn.com/201802021641_929.png)

#### 4.3.5 list的构造与内存管理：constructor， push_back, insert
list缺省使用alloc，并由此定义了一个list_node_alloctor是为了更方便的以节点大小为配置单位。`list_node_alloctor(n)`表示配置n个节点空间。同时有四个函数，如下：
```c++
//配置一个节点并传回
link_type get_node();
//释放一个节点
void put_node(link_type p);
//配置并构造一个节点，带有元素值
link_type create_node(const T& x);
//析构并释放一个节点
void destroy_node(link_type p);
```
list众多构造函数中，有一个允许我们构造一个空list出来：
```c++
public:
    list(){ empty_initialize(); }
protected:
    void empty_initialize(){
        //next、prev指针都指向自己
        node = get_node();
        node->next = node;
        node->prev = node;
    }
```
空节点对象模型：![空节点](http://p3ax8ersb.bkt.clouddn.com/201802021656_767.png)
当我们用push_back()插入新节点的时候，函数内部调用insert()`void push_back(const T& x) { inset( end(), x ); }`insert()有很多的重载函数，最简单的如下:
```c++
//在迭代器position所指位置插入一个节点，值为x
iterator insert(iterator position, const T& x){
    link_type tmp = create_node(x);
    //插入位置在position之前,这是STL规范。
    tmp->next = position.node;
    tmp->prev = position.node->prev;
    (link_type(position.node->node->prev))->next = tmp;
    position.node->prev = tmp;
    return tmp;
}
```
#### 4.3.6 list的元素操作：`push_front, push_back, erase, pop_front, pop_back, clear, remove, unique, splice, merge, reverse, sort`
push_front, push_back复用insert；pop_front, pop_back复用erase。
```c++
//移除迭代器position所指节点
iterator erase(iterator position){
    link_type next_node = link_type(position.node->next);
    link_type prev_node = link_type(position.node->prev);
    prev_node->next = next_node;
    next_node->prev = prev_node;
    destroy_node(position.node);
    return iterator(next_node);
}
//清除所有节点
template <class T, class Alloc>
void list<T, Alloc>::clear(){
    link_type cur = (link__type) node->next;    //begin();
    while( cur != node ){
        link_type tmp - cur;
        cur = (link_type)cur->next;
        destroy_node(tmp);
    }
    //恢复成空节点的初始结构
    node->next = node;
    node->prev = node;
}
//将数值为value的所有元素移除
template <class T, class Alloc>
void list<T, Alloc>::remove(const T& value){
    iterator first = begin();
    iterator last = end();
    while(first != last){
        iterator next = first;
        ++next;
        if(*first == value) erase(first);
        first = next;
    }
}
//移除相同连续的元素，只有连续相同的元素才会被移除只剩一个
//很帅啊
template <class T, class Alloc>
void list<T, Alloc>::unique(){
    iterator first = begin();
    iterator last = end();
    if(first == last) return;   //判空
    iterator next = first;
    while(++next != last){
        if(*first == *next)
            erase(next);
        else
            first = next;
        next = first;
    }
}
```
list 内部提供了一个迁移操作(transfer)：将某连续分为的元素迁移到某特定位置之前。
```c++
protected:
    //将[first, last)内的所有元素移动到position之前。
    void transfer(iterator position, iterator first, iterator last){
        if(position != last){
            //先处理各节点的next
            (*(link_type((*last.node).prev))).next = position.node;
            (*(link_type((*first.node).prev))).next = last.node;
            (*(link_type((*position.node).prev))).next = first.node;
            //tmp为position的prev节点
            link_type tmp = link_type((*position.node).prev);
            //处理各节点的prev
            (*position.node).prev = (*last.node).prev;
            (*last.node).prev = (*first.node).prev;
            (*first.node).prev = tmp;
        }
    }
```
splice各个版本：
```c++
public:
    //将list x接合与position所指位置之前，x必须不同于*this
    void splice(iterator position, list& x){
        if(!x.empty())
            transfer(position, x.begin(), x.end());
    }
    //将i 所指元素接合于position所指元素之前。position和i可指向同一个list
    void splice(iterator position, list&, iterator i){
        iterator j = i;
        ++j;
        if(position == i || position == j) return;
        trasfer(position, i, j);
    }
    //将[first, last)内的所有元素接合于position所指位置之前，
    //position和[first, last)可指向同一个list。
    //但是position不能在[first, last)范围之内
    void splice(iterator posiition, list&, iterator first, iterator last){
        if(first != last)
            transfer(position, first, last);
    }
```
merge(), reverse(), sort()源码：
```c++
//merge()将x合并到*this上，两个list必须是递增排序的
template <class T, class Alloc>
void list<T, Alloc>::merge(list<T, Alloc>& x){
    iterator first1 = begin();
    iterator last1 = end();
    iterator first2 = x.begin();
    iterator last2 = x.end();
    while(first1 != last1 && first2 != last2){
        if(*first2 < *first1){
            iterator next = first2;
            transfer(first1, first2, ++next);
            first2 = next;
        }
        else
            ++first1;
        if(first2 !=  last2) transfer(last1, first2,last2);
    }
}

//reverse()将*this的内容逆置
template <class T, class Alloc>
void list<T, Alloc>::reverse(){
    //判空或只有一个节点，用size() == 0 || size() == 1速度比较慢
    if(node->next == node || link_type(node->next)->next == node)
        return;
    iterator first = begin();
    ++first;
    while(first != end()){
        iterator old = first;
        ++first;
        transfer(begin(), old, first);
    }
}

//list不能使用STL中的sort()算法，只能使用自己的sort()
//因为STL的sort()只接受RamdonAccessIterator
//本函数使用quick sort
template <class T, class Alloc>
void list<T, Alloc>::sort(){
     //判空或只有一个节点，用size() == 0 || size() == 1速度比较慢
    if(node->next == node || link_type(node->next)->next == node)
        return;
    //创建新的list空间，作为中介数据存放区
    list<T, Alloc> carry;
    list<T, Alloc> counter[64];
    int fill = 0;
    while(!empty()){
        carry.splice(carry.begin(), *this, begin());
        int i = 0;
        while(i < fill && !counter[i].empty()){
            counter[i].merge(carry);
            carry.swap(counter[i++]);
        }
        carry.swap(counter[i]);
        if(i == fill)
            ++fill;
    }
    for(int i = 1; i < fill; ++i)
        counter[i].merge(counter[i-1]);
    swap(counter[fill-1]);
}
```