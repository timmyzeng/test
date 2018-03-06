---
title: 浅读《STL源码剖析》笔记 3章
date: 2018-02-08 17:07:30
tags:
categories:
    - "learning"
keywords:
    - "STL源码剖析"
    - "iterator"
---

## 3 迭代器(iterator)概念与traits编程技法
迭代器(iterator)是一种抽象的设计概念，iterator模式定义如下；提供一种方法，使之能够按照次序访问某个聚合物（容器）所含有的各个元素，而同时又无需暴露该聚合物的内部表述方式

### 3.1 迭代器设计思维
**STL的中心是将数据容器和算法分开，然后用一个胶合剂将他们联系在一起，这个就是iterators的作用之一**
<!--more-->

```c++
//3.1举例说明迭代器的使用
//find()的定义。
template <class InputIterator, chass T>
InputIterator find( InputIterator first, InputIterator last, const T& value ){
    while ( first != last && *first != value )
        ++first;
        return first;
}

#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

int main(){
    const int arraySiza = 7;
    int ia[arraySiza] = { 0, 1, 2, 3, 4, 5, 6 };
    vector<int> ivect(ia, ia+arraySiza);
    //调用vector的iterator用于find()
    vector<int>::iterator it1 = find(ivect.begin(), ivect.end(), 4);
    if( it1 == ivect.end() )
        cout << "4 not found." << endl;
    else
        cout << "4 found:" << *it1 << endl;

    it1 = find(ivect.begin(), ivect.end(), 8);
    if( it1 == ivect.end() )
        cout << "8 not found." << endl;
    else
        cout << "8 found" << *it1 << endl;

    return 0;
}
```
运行结果：
![迭代器](http://p3ax8ersb.bkt.clouddn.com/201802011511_588.png-960.jpg)

### 3.2 迭代器(ierator)是一种smart pointer
**迭代器是一个行为类似指针的对象，所以迭代器最重要的编程工作就是对operator* 和 operator-> 进行重载工作。**
以下，简单模拟一个list的结构，然后设计对应的iterator。
```c++
//listnode
template <typename T>
class ListItem{
public:
    T value() const{ return _value; }
    ListItem* next() const{ return _next; }
    //...
private:
    T _value;
    ListItem* _next; //单向链表(single linked list)
};

//list
template <typename T>
class List{
public:
    void insert_front(T value); //省略实现
    void insert_end(T value);   //省略实现
    voide display(std::ostream &os = std::cout) const;//省略实现
    //...
private:
    ListItem<T>* _end;
    ListItem<T>* _front;
    long _size;
};
```
当我们解引用这个迭代器的时候，传回的应该是ListItem对象；当我们++迭代器的时候，它应该指向下一个ListItem对象。设计如下：
```c++
//iterator
template <class Item>//Item可以是单向链表节点或双向链表节点，此处这个迭代器特地为链表服务，因为他的operator++只适用于链表。
struct ListIter{
    Item* ptr;  //保持与容器之间的一个联系
    ListIter( Item* p = 0 )
        :ptr(p)
        {}
    //不必实现copy ctor，因为编译器提供的缺省行为已经足够
    //不必实现operator=，因为编译器提供的缺省行为已经足够
    Item& operator*() const { return *ptr; }
    Item* operator->() const { return ptr; }
    //operator++分为两种，一种是前置++(pre-increament operator),另一种是后置++(post-increment operator)
    //pre-increament operator
    ListIter& operator++(){
        ptr = ptr->next();
        return *this;
    }
    //post-incteament operator
    LostIter operator++(int){
        ListIter tmp = *this;
        ++*this;
        return tmp;
    }
    bool operator==(const LostIter& i)const{ return ptr == i.ptr; }
    bool operator!=(const LostIter& i)const{ return ptr != i.ptr; }
}
```
接下来，将List和find()由ListIter粘合起来：
```c++
int main(){
    List<int> mylist;
    for( int i=0; i<5; ++i ){
        mylist.insert_front(i);
        mylist.insert_end(i+2);
    }
    mylist.displau();   //10( 4 3 2 1 0 2 3 4 5 6)
    ListIter<ListItem<int> > begin(mylist.front());
    ListIter<ListItem<int> > end;
    ListIter<ListItem<int> > iter;

    iter = find(begin, end, 3);
    if( iter == end )
        cout << "not found" << endl;
    else
        cout << "found." << iter->value() << endl;
    //执行结果：found.3

    return 0;
}
```
由于find() 函数以`*iter != value`来检查元素值是否吻合，本例子中value的型别是 int，iter 的型别是 `ListIterm<int>`,两者之间没有可以使用的operator!=函数，所以需要重载这个函数，全局的，参数是int和`ListIterm<int>`。如下：
```c++
template <typename T>
bool operator!=(const ListItem<T>& item, T n){ return item.value() != n; }
```
### 3.3 迭代器相应型别(associated types)
当算法中有必要声明一个变量，需要获取“迭代器所指对象的型别”为型别，我们可以通过function template 的参数推导(argument deducation)机制实现。例如：![function template的例子](http://p3ax8ersb.bkt.clouddn.com/201802011841_231.png-960.jpg)
以func()为对外接口，实际操作全部置于func_imp中，由于func_imp()是一个function template，一旦被调用，编译器会自动进行template参数推导。推导出型别T，顺利解决了问题。
### 3.4 Traits 编程技法——STL源代码门钥
**value type：迭代器所指对象的型别。**上述的参数型别推导技巧在value type需要用于函数的传回值就束手无策了，因为函数的"template参数推导机制"推导的只是参数，无法推导函数的返回值型别。我们需要别的方法，例如声明内嵌型别。如下：
```c++
template <class T>
struct MyIter{
    typedef T value_type;   //内嵌型别声明(nested type)
    MyIter(T* p = 0)
        :ptr(p)
        {}
    T& operator*() const { return *ptr; }
    //...
    T* ptr; //成员变量
};
template <class I>
typename I::value_type func( I ite ){ return *ite; }    //typename I::value_type  这是func的返回值型别；
//...
MyIter<int> ite(new int(8));
cout << func(ite);  //输出:8
```
`typename I::value_type`必须加上typename，因为T是一个template参数，在它被编译器实例化之前，编译器是不知道他是什么的。**加上了关键字typename的用意在于告诉编译器这个是一个型别，如此才能够顺利编译通过。**

这样有一个缺陷，并不是所有的迭代器都是class type，原生指针就不是。真正可以解决这个问题的是 **偏特化(template partial specialization)**。也就是将泛化版本中的某些template参数赋予明确大的指定内容。见如下例子：
```c++
//class template
template <typename T>
class C{    //这个泛化版本接受T为任何型别
    //...
};
//prartial specialization
template <typename T>
class C<T*>{    //这个特化版本只适用于"T 为原生指针"的情况
    //...
};
```
下面这个例子，**专门用来萃取迭代器的特性，value type正是迭代器的特性之一**
```c++
template <class I>
struct iterator_traits{ //traits意思为“特性”
    typedef typename I::value_type value_type;
};
```
这样，前面那个func函数可以修改成这样。
```c++
template <class I>
//typename iterator_traits<I>::value_type 是函数的返回型别
typename iterator_traits<I>::value_type func(I ite){ return *ite; }
```
跟之前的相比，只是多了一个中间层，但是就是多了这个中间层，traits可以拥有特化版本。如下：
```c++
template <class T>
struct iterator_traits<T*>{ //偏特化版本--迭代器是一个原生指针
    typedef T value_type;
}
```
此时，就算是原生指针，我们也可以通过traits萃取到它的value type。我们想要的到的原生指针是一个非const值，但当像这样的`iterator_traits<const int*>::value_type`得到的是const int。所以我们另外设计一个特化版本，让`const T*`转变为T*：
```c++
template <class T>
struct iterator_traits<const T*>{   //偏特化版本，当迭代器是一个const指针的时候，
    typedef T value_type;           //萃取出来的是T，而不是const T
};
```
到这里为止，**不论是面对class-type迭代器，原生指针，const修饰的原生指针。我们都可以通过traits萃取出正确的value type。但是，需要这traits正常运作，每一个迭代器必须自行以内嵌型别定义(nested typedef)的方式定义出相应型别(associated types)。这是一个约定，STL中必须满足。**

图解iterator_traits：![iterator_traits](http://p3ax8ersb.bkt.clouddn.com/201802012217_572.png-960.jpg)
常用的迭代器相应型别有以上五种，“特性萃取机”traits会原汁原味的榨取出来：
```c++
template <class I>
struct iterator_traits{
    typedef typename I::iterator_category iterator_category;
    typedef typename I::value_type value_type;
    typedef typename I::difference_type difference_type;
    typedef typename I::pointer pointer;
    typedef typename I::reference reference;
};
```
**其中，iterator_traits必须对传入的型别为pointer和pointer-to-const设计特化版本。**
以上：

#### 3.4.1 value type 如上
#### 3.4.2 difference type
#### 3.4.3 reference type
#### 3.4.4 pointer type
#### 3.4.5 iterator_catrgory