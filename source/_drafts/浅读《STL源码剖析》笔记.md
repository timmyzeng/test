---
title: 浅读《STL源码剖析》笔记
tags:
categories:
    - "learning"
---
#### 1 STL概论与版本简介
##### 1.2 STL六大组件
1. 容器(containers):`vector,list,deque,set,map`,用来存放数据
2. 算法(algorithms):`sort,search,copy,erase`
3. 迭代器(iterators):扮演容器与算法之间的胶合剂，所谓的“泛型指针”。从实现角度来看，<!--more-->迭代器器将`operator*,operator++,operator--,operator->`等指针进行了重载的class template。原生指针（native pointer）也是一种迭代器。
4. 仿函数(functors):行为类似函数，实现来看，重载了operator()的class或class template。
5. 配接器(adapters):一种用来修饰容器(containers)或仿函数(functors)或迭代器(iterators)接口的东西。如stack和queue他们的底层实现是deque。
6. 配置器(allocators):负责空间配置与管理，从实现的角度看来，配置器是一个实现了动态空间配置、空间管理、空间释放的class template。

##### 1.5~1.8 STL版本之二
1. P.J.Plauger (Microsoft Visual C++)
2. SGI STL (Linux GCC)
    C++标准规范下的C头文件: `cstdio,cstdlib,cstring`
    C++标准程序库中不属于STL范畴: `stream,string`
    STL标准头文件: `vector,deque,list,map,algorithm,functional`
    C++Standard定案前，HP所规范的STL头文件: `vector.h,deque.h,list.h,algo.h,function.h`
    SGI STL内部文件(STL真正实现于此): `stl_vector.h,stl_deque.h,stl_list.h,stl_map.h,stl_algo.h,stl_function.h`

##### 1.9 可能令你困惑的C++语法
###### 1.9.2 临时对象的产生与运用
临时对象就是匿名对象，创造临时对象的方法是，在类型后面直接加上()，同时可以赋初值。如：Shape(3,5),int(8)。他的意义相当于调用相应的constructor且不指定对象名称。**STL中最常将此技巧用在仿函数(functor)中。**临时对象的生命周期只有这一行指令。
###### 1.9.3 静态常量整数成员在class内部直接初始化
class内含有`const static integral data member`，我们可以直接给予初值。
    ```c++
    //1.9.3测试代码如下
    template <typename T>
    class testclass{
    public:
        static const int datai = 5;
        static const long datal = 3L;
        static const char datac = 'c';
    };

    int main(){
        cout << testclass<int>::datai << endl;
        cout << testclass<int>::datal << endl;
        cout << testclass<int>::datac << endl;
        return 0;
    }
    ```
运行结果：
![运行结果](http://p3ax8ersb.bkt.clouddn.com/201801291947_629.png)
###### 1.9.5 前闭后开区间表示法[)
**STL中范围是用前闭后开。[first, last)元素从first开始，结束于last-1.迭代器中的last指的是最后一个元素的下一个。**
###### 1.9.6 function call操作符(operator())
function call操作符(oprator())。C语言中用函数指针作为参数传递。有个缺点就是，没有可适配性，也就是确定了这个函数指针之后，无法再加上新的修饰条件从而改变他的状态。STL中用仿函数(functor)实现这个功能。**如果你针对某个class进行operator()重载，它就成为一个仿函数。**
    ```c++
    //1.9.6测试代码如下
    template <class T>
    struct Add{
        //重载了operator()
        T operator()(const T&x, const T&y) const{
            return x+y;
        }
    };
    int main(){
        Add<int> addxy;
        system( "clear" );
        //调用重载函数
        cout << addxy(3,5) << endl;
        //调用匿名对象
        cout << Add<int>()(5,5) << endl;
        return 0;
    }
    ```
运行结果：
![仿函数](http://p3ax8ersb.bkt.clouddn.com/201801292024_990.png)

#### 2 空间配置器(allocator)
空间配置器在容器背后工作，整个STL的操作对象(所有的数值)，对存放在容器中，而容器一定要配置空间以置放资料。不一定是内存，也可以是磁盘或其他的辅助存储介质。
##### 2.2 具备此配置力的SGI空间配置器
###### 2.2.1 SGI标准的空间配置器,std::allocator
SGI的空间配置器和标准规范不同，他的名称是alloc而不是allocator，且不接受任何参数。标准写法如下：`vector<int,std::allocator<int>>`;SGI STL写法如下：`vector<int, std::aloc>`绝大多数情况下，我们都是使用缺省的空间配置器。
###### 2.2.2 SGI特殊的空间配置器，std::alloc
- SGI同时也配备了标准空间配置器`std::allocator`，但是这只是对C++的`operator new和operator delete`做了一层封装，效率低下，**SGI并不使用，只是为了向前兼容语法。**
- **SGI自身使用的空间配置器是`std::alloc`**一般来说，我们习惯的C++内存操作和释放操作是这样的：
    ```c++
    class Foo{};
    Foo* pf = new Foo;
    delete pf;
    ```
    这其中的new包含两个操作，一个是调用::operator new配置内存；另一个是调用Foo::Foo()构造对象内容。delete也是两个，一个是调用Foo::~Foo()析构对象，另一个是调用::operator detele 释放内存。**为了分工，STL allocator将这个两个阶段分开来，内存配置操作有alloc:allocate()负责，内存释放操作有alloc::deallocate()负责，对象构造操作有:construct()负责，对象析构操作由::destroy()负责。**
- STL的配置器(allocator)定于于`<memory>`，其中包含两个文件,一个是负责内存空间的配置与释放<stl_alloc.h>,这里定义了一二级配置器，配置器名为alloc；另一个是负责对象内容的构造与析构<stl_construct.h>，定义了全局函数construct()和destroy()。

###### 2.2.3 构造和析构基本工具:construct()和destroy()
- construct()的实现如下：
    ```c++
    #include <new.h>    //使用placement new 需要这个头文件
    template <class T1, class T2>
    inline void construct(T1* p, const T2& value){
        new (p) T1(value);  //使用了placement new;调用T1:T1(value);
    }
    ```
    代码解释：`construct()`接收一个指针p和一个初始值value，用来将初值设定到指针所指向的空间，**通过`placement new`实现**。
- destroy()有两个版本，实现如下:
    ```c++
    //第一个版本，接受一个指针
    template <class T>
    inline void destroy(T* pointer){
        pointer->~T();
    }
    //第二个版本，接受两个迭代器。此函数设法找出元素的数值型别，进而利用__type_traits<>求取最适当的措施。
    template <class ForwardIterator>
    inline void destroy(ForwardIterator first, ForwardIterator last){
        __destroy(first, last, value_type(first));
    }
    //判断元素的数值型别(value type)是否有 trivial destructor
    template <class ForwardIterator, class T>
    inline void __destroy(ForwardIterator first, ForwardIterator last, T*){
        typedef typename __type_traits<T>::has_trivial_destructor trivial_destructor;
        __destroy_aux(first, last, trivial_destructor());
    }
    //如果元素的数值型别(value type)有non-truvial destructor，循环释放
    template <class ForwardIterator>
    inline void __destroy_aux(ForwardIterator first, ForwardIterator last, __false_type){
        for( ; first < last; ++first)
            //调用第一个版本的destroy()
            destroy(&* first);
    }
    //如果元素的数值型别(value type)有trivial destructor,函数什么也不做
    template <class ForwardIterator, ForwardIterator, __true_type>{
        inline void __destroy_aux(ForwardIterator, ForwardIterator, __true_type){}
    }
    //destroy()中第二版本针对迭代器为char* 和 wchar_t*的特化版本,函数什么都不做
    inline void desroy(char*, char*){}
    inline void destroy(wchar_t*,wchar_t*){}
    ```
    代码解释：`destroy()`有两个版本，**第一个版本接收一个指针，准备将该指针所指之物析构，这个直接调用该对象的析构函数即可**。第二个版本接收first和last两个迭代器，准备将`[firat, last)`范围内的所有对象析构。我们不知道范围有多大，万一很大，而每个对象的析构函数都无关痛痒(所谓`trivial destructor`),那么一次次调用这些无关痛痒的析构函数，对效率是一个伤害，因此，**这里首先利用`value_type()`获得迭代器所指对象的型别，再利用`__type_traits<T>`判断该型别的析构函数是否无关痛痒。若是`(__true_type)`，则什么都不做结束；若不是`(__false_type)`,这才循环巡防整个范围，并在循环中每经历一个对象就调用第一个版本的`destroy()`。**
- construct()和destroy()图解：对于C++本身并不支持“指针所指之物”的型别判断，也不支持对“对象析构函数是否为trivial”的判断，具体实现value_type()和__type_traits<>在3.7节。![construct()和destroy()图解](http://p3ax8ersb.bkt.clouddn.com/201802011438_654.png)

###### 2.2.4 空间的配置与释放，std::alloc
- 对象构造前的空间配置和对象析构后的空间释放，由`<stl_alloc.h>`负责。
    - 向 system heap 要求空间
    - 考虑多线程(multi-threads)状态(这里不考虑多线程的情况)
    - 考虑内存不足时的应变措施
    - 考虑过多“小型区域”可能造成的内存碎片(fragment)问题
- **C++内存配置的基本操作是:`:operator new()`，内存释放的基本操作是`::operator delete()`。这两个全局函数相当于C的malloc()和free()函数，所以SGI正是用malloc()和free()完成内存的配置和释放。**
- 为了解决小型区块可能造成的内存破碎问题，SGI设计了双层级的配置器，**第一级配置器`(__malloc_alloc_template)`用malloc()和free()，第二级配置器`(__default_alloc_template)`看情况而定：当配置区块超过128bytes，调用第一级配置器；小于128bytes，采用复杂的内存池`memory bool`整理方式。**其中具体是开放了第一级配置器还是两级配置器都开放了由__USE_MEALLOC是否定义决定，定义了__USE_MEALLOC就将alloc定义为第一级配置器，没有定义就将alloc定义为第二级配置器。SGI STL采用第二级配置器。
- 无论是第一级配置器还是第二级配置器，SGI都为其包装了一个接口`simple_alloc`，使其能够符合STL的接口规格。
    ```c++
    template <class T,class Alloc>
    class simple_alloc{
    public:
        static T* allocate(size_t n){
            return 0 == n?0 : (T*) Alloc::allocate(n* sizeof (T));
        }
        static T* allocate(void){
            return (T*) Alloc::allocatte(sizeof (T));
        }
        static void dallocate(T* p, size_t n){
            if(0 != n)
                Alloc::deallocate(p, n*sizeof (T));
        }
        static void deallocat(T* p){
            Alloc::deallocate(p, sizeof (T));
        }
    };
    ```
    内部四个成员函数都是单纯的转调用，这个接口使配置器的单位从bytes转为个别元素的大小(sizeof(T))。
- 图解如下：
    - 第一级配置器和第二级配置器：![第一级配置器和第二级配置器](http://p3ax8ersb.bkt.clouddn.com/201802011620_34.png)
    - 包装接口和运用：![包装接口和运用](http://p3ax8ersb.bkt.clouddn.com/201802011647_747.png)

接下来几节，暂时先压住……
###### 2.2.5 第一级配置器 __malloc_alloc_template 剖析
###### 2.2.6 第二级配置器__default_alloc_template 剖析
###### 2.2.7 空间配置函数allocate()
###### 2.2.8 空间释放函数 deallocate()
###### 2.2.9 重新填充 free lists
###### 2.2.10 内存池(memory pool)
##### 2.3 内存基本处理工具
STL定义了五个全局函数，作用于未初始化化空间上：用于构造的`construct()`和析构的`destroy()`,另外三个是：`uninitialized_copy(),uninitialized_fill(),uninitialozed_fill_n()`(定于于`<memory>`),分别对应于高层次函数`copy(),fill(),fill_n()`,这些都是STL的算法。
###### 2.3.1 uninitialized_copy
###### 2.3.2 uninitialized_fill
###### 2.3.3 uninitialized_fill_n

#### 3 迭代器(iterator)概念与traits编程技法
迭代器(iterator)是一种抽象的设计概念，iterator模式定义如下；提供一种方法，使之能够按照次序访问某个聚合物（容器）所含有的各个元素，而同时又无需暴露该聚合物的内部表述方式

##### 3.1 迭代器设计思维
**STL的中心是将数据容器和算法分开，然后用一个胶合剂将他们联系在一起，这个就是iterators的作用之一**

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
![迭代器](http://p3ax8ersb.bkt.clouddn.com/201802011511_588.png)

##### 3.2 迭代器(ierator)是一种smart pointer
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
##### 3.3 迭代器相应型别(associated types)
当算法中有必要声明一个变量，需要获取“迭代器所指对象的型别”为型别，我们可以通过function template 的参数推导(argument deducation)机制实现。例如：![function template的例子](http://p3ax8ersb.bkt.clouddn.com/201802011841_231.png)
以func()为对外接口，实际操作全部置于func_imp中，由于func_imp()是一个function template，一旦被调用，编译器会自动进行template参数推导。推导出型别T，顺利解决了问题。
##### 3.4 Traits 编程技法——STL源代码门钥
- **value type：迭代器所指对象的型别。**上述的参数型别推导技巧在value type需要用于函数的传回值就束手无策了，因为函数的"template参数推导机制"推导的只是参数，无法推导函数的返回值型别。我们需要别的方法，例如声明内嵌型别。如下：
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
- 这样有一个缺陷，并不是所有的迭代器都是class type，原生指针就不是。真正可以解决这个问题的是 **偏特化(template partial specialization)**。也就是将泛化版本中的某些template参数赋予明确大的指定内容。见如下例子：
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
- 下面这个例子，**专门用来萃取迭代器的特性，value type正是迭代器的特性之一**
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
- 图解iterator_traits：![iterator_traits](http://p3ax8ersb.bkt.clouddn.com/201802012217_572.png)
- 常用的迭代器相应型别有以上五种，“特性萃取机”traits会原汁原味的榨取出来：
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

本章先到这里，往下就是对STL原原本本的探究了。
###### 3.4.1 value type 如上
###### 3.4.2 difference type
###### 3.4.3 reference type
###### 3.4.4 pointer type
###### 3.4.5 iterator_catrgory


#### 4 序列式容器
##### 4.1 容器的概观与分类
![SGI STL的各个容器](http://p3ax8ersb.bkt.clouddn.com/201801311638_540.png)
所谓序列式容器，其中的元素都是可序的(ordered),但未必有序(sorted)。C++本身有array，其它是STL提供的。
##### 4.2 vector
###### 4.2.1 vector概述
array是静态的，vector是动态增长的，随着元素的增加，内部机制自动扩充空间以容纳元素，不需要自己分配空间。
###### 4.2.3 vector的迭代器
由于vector维护的是连续线性空间，所以不论元素类型是什么，普通指针都可以作为vector的迭代器而满足要求。vector支持随机存取，普通指针也满足。`vector<int> :: iterator ivite;vector<Shape> :: iterator svite;`其中 `ivite`的类型就是`int*`，`svite`的类型就是`Shape*` 。
###### 4.2.4 vector的数据结构
- vector的数据结构如下：
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
- 为了降低空间配置时的成本，实际上，vector配置的空间会比客户端需要的更大一些，这样是为了将来可能扩充的准备。当容量等于大小的时候，开辟新的空间。
- 运用 start，finish，end_of_storage三个迭代器，可以实现begin(),end(),size(),capacity(),empty(),operator[],front(),back()等方法。

###### 4.2.5 vector的构造与内存管理：constructor，push_back
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

###### 4.2.6 vector的元素操作：pop_back, erase, clear, insert
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
##### 4.3 list
###### 4.3.1 list概述
list每次插入或删除一个元素，就配置或释放一个元素空间。对于任何位置的元素插入或元素移除，是时间常数。
###### 4.3.2 list的节点(node)
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
###### 4.3.3 list的迭代器
**list的迭代器有一个重要性质，insert(插入)和splice(接合)操作都不会造成原有的迭代器失效。list的delete(删除)只有被删除的那个节点的迭代器失效**
###### 4.3.4 list的数据结构
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

###### 4.3.5 list的构造与内存管理：constructor， push_back, insert
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
###### 4.3.6 list的元素操作：`push_front, push_back, erase, pop_front, pop_back, clear, remove, unique, splice, merge, reverse, sort`
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
##### 4.4 deque
###### 4.4.1 deque概述
deque是双向开口的连续性空间。可以在头尾两端分贝做元素的插入和删除操作。vector从技术层面也可以实现，但是头部操作效果奇差。
![deque](http://p3ax8ersb.bkt.clouddn.com/201802021818_269.png)
deque和vector的最大区别在于二：一是deque对头部的常数时间操作。二是deque没有capacity的概念，因为deque是动态的以分段连续空间组合而成，随时可以增加一段新的空间并链接起来。
###### 4.4.2 deque的中控器
deque是由一段一段的定量连续空间构成。deque的最大任务就是，在这些分段的定量连续空间上，维护其整体连续的假象，并提供随机存储的接口。避开了vector那样的重新分配、复制、释放的轮回，而是以复杂的迭代器架构为代价。

deque采用一块所谓的map(非STL中的map容器)作为主控。这个map是一块连续空间，其中每个元素(称为节点node)都是指针，指向另一段较大的连续线性空间(缓冲区)。缓冲区才是deque的存储空间主题。SGI STL允许我们指定缓冲区的大小，默认值0代表使用512bytes缓冲区。结构如下：
```c++
template <class T, class Alloc=alloc, size_t BufSiz = 0>
class deque {
public:
    typedef T value_type;
    typedef value_type* pointer;
    //...
protected:
    //元素的指针的指针
    typedef pointer* map_pointer;
    map_pointer map;    //指向map，map是一个连续空间，
                        //每一个元素是一个指针(称为节点)，指向一块缓冲区
    size_type map_size; //指定map可以容纳多少指针
}
```
**map是一个二级指针，指向型别是T**。见图解：
![map](http://p3ax8ersb.bkt.clouddn.com/201802031030_124.png)
###### 4.4.3 deque的迭代器
维持deque是一块连续空间的假象，用迭代器的operator++和operator--实现。迭代器起码要实现两个功能：一、可以指出分段连续空间(缓冲区)在哪里。二、能够判断是否处于缓冲区的边缘，如果是，向前移动或向后移动可以跳到上一个缓冲区或下一个缓冲区。需要正确跳段，需要掌控map。结构如下：
```c++
template <class T, class Ref, class Ptr, size_t BufSiz>
struct __deque_iterator{
    typedef __deque_iterator<T, Ref, Ptr, BufSiz> iterator;
    typedef __deque_iterator<T, const T&, const T*, BufSiz> const_iterator;
    static size_t buffer_size() { return __deque_buf_size(BufSiz, sizeof(T)); }

    //没有继承std::iterator,所以需要自己写五个必要的迭代器相应型别(第三章)
    typedef random_access_iterator_tag iterator_category;   //1
    typedef T value_type;   //2
    typedef Ptr pointer;    //3
    typedef Ref reference;  //4
    typedef ptrdiff_t difference_type;  //5

    typedef size_t size_type;
    typedef T** map_pointer;
    typedef __deque_iterator self;

    //保持与容器的联系
    T* cur;     //当前缓冲区中当前元素
    T* first;   //当前缓冲区的头
    T* last;    //当前缓冲区的尾
    map_pointer node;   //指向中控器map
    //...
}
//上段决定缓冲区大小的函数buffer_size()，调用__deque_buf_size(),这是一个全局函数，如下：
//当n不为0，传回n，表示buffer_size用户自定义了
//当n为0，buffer_size使用默认值
inline size_t __deque_buf_size(size_t n, size_t sz){
    return n != 0 ? n : (sz < 512 ? size_t(512 / sz) : size_t(1));
}
```
下图是deque的中控器，缓冲区，迭代器的相互关系：
![deque的中控器，缓冲区，迭代器的相互关系](http://p3ax8ersb.bkt.clouddn.com/201802031110_957.png)