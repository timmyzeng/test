---
title: 浅读《STL源码剖析》笔记 1、2章
date: 2018-02-03 11:15:06
tags:
categories:
    - "learning"
---
## 1 STL概论与版本简介
### 1.2 STL六大组件
1. 容器(containers):`vector,list,deque,set,map`,用来存放数据
2. 算法(algorithms):`sort,search,copy,erase`
3. 迭代器(iterators):扮演容器与算法之间的胶合剂，所谓的“泛型指针”。从实现角度来看，<!--more-->迭代器器将`operator*,operator++,operator--,operator->`等指针进行了重载的class template。原生指针（native pointer）也是一种迭代器。
4. 仿函数(functors):行为类似函数，实现来看，重载了operator()的class或class template。
5. 配接器(adapters):一种用来修饰容器(containers)或仿函数(functors)或迭代器(iterators)接口的东西。如stack和queue他们的底层实现是deque。
6. 配置器(allocators):负责空间配置与管理，从实现的角度看来，配置器是一个实现了动态空间配置、空间管理、空间释放的class template。

### 1.5~1.8 STL版本之二
1. P.J.Plauger (Microsoft Visual C++)
2. SGI STL (Linux GCC)
    C++标准规范下的C头文件: `cstdio,cstdlib,cstring`
    C++标准程序库中不属于STL范畴: `stream,string`
    STL标准头文件: `vector,deque,list,map,algorithm,functional`
    C++Standard定案前，HP所规范的STL头文件: `vector.h,deque.h,list.h,algo.h,function.h`
    SGI STL内部文件(STL真正实现于此): `stl_vector.h,stl_deque.h,stl_list.h,stl_map.h,stl_algo.h,stl_function.h`

### 1.9 可能令你困惑的C++语法
#### 1.9.2 临时对象的产生与运用
临时对象就是匿名对象，创造临时对象的方法是，在类型后面直接加上()，同时可以赋初值。如：Shape(3,5),int(8)。他的意义相当于调用相应的constructor且不指定对象名称。**STL中最常将此技巧用在仿函数(functor)中。**临时对象的生命周期只有这一行指令。
#### 1.9.3 静态常量整数成员在class内部直接初始化
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
![运行结果](http://p3ax8ersb.bkt.clouddn.com/201801291947_629.png-960.jpg)
#### 1.9.5 前闭后开区间表示法[)
**STL中范围是用前闭后开。[first, last)元素从first开始，结束于last-1.迭代器中的last指的是最后一个元素的下一个。**
#### 1.9.6 function call操作符(operator())
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
![仿函数](http://p3ax8ersb.bkt.clouddn.com/201801292024_990.png-960.jpg)

## 2 空间配置器(allocator)
空间配置器在容器背后工作，整个STL的操作对象(所有的数值)，对存放在容器中，而容器一定要配置空间以置放资料。不一定是内存，也可以是磁盘或其他的辅助存储介质。
### 2.2 具备此配置力的SGI空间配置器
#### 2.2.1 SGI标准的空间配置器,std::allocator
SGI的空间配置器和标准规范不同，他的名称是alloc而不是allocator，且不接受任何参数。标准写法如下：`vector<int,std::allocator<int>>`;SGI STL写法如下：`vector<int, std::aloc>`绝大多数情况下，我们都是使用缺省的空间配置器。
#### 2.2.2 SGI特殊的空间配置器，std::alloc
SGI同时也配备了标准空间配置器`std::allocator`，但是这只是对C++的`operator new和operator delete`做了一层封装，效率低下，**SGI并不使用，只是为了向前兼容语法。**

**SGI自身使用的空间配置器是`std::alloc`**一般来说，我们习惯的C++内存操作和释放操作是这样的：
```c++
class Foo{};
Foo* pf = new Foo;
delete pf;
```
这其中的new包含两个操作，一个是调用::operator new配置内存；另一个是调用Foo::Foo()构造对象内容。delete也是两个，一个是调用Foo::~Foo()析构对象，另一个是调用::operator detele 释放内存。**为了分工，STL allocator将这个两个阶段分开来，内存配置操作有alloc:allocate()负责，内存释放操作有alloc::deallocate()负责，对象构造操作有:construct()负责，对象析构操作由::destroy()负责。**
STL的配置器(allocator)定于于`<memory>`，其中包含两个文件,一个是负责内存空间的配置与释放<stl_alloc.h>,这里定义了一二级配置器，配置器名为alloc；另一个是负责对象内容的构造与析构<stl_construct.h>，定义了全局函数construct()和destroy()。

#### 2.2.3 构造和析构基本工具:construct()和destroy()
construct()的实现如下：
```c++
#include <new.h>    //使用placement new 需要这个头文件
template <class T1, class T2>
inline void construct(T1* p, const T2& value){
    new (p) T1(value);  //使用了placement new;调用T1:T1(value);
}
```
代码解释：`construct()`接收一个指针p和一个初始值value，用来将初值设定到指针所指向的空间，**通过`placement new`实现**。
destroy()有两个版本，实现如下:
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

construct()和destroy()图解：对于C++本身并不支持“指针所指之物”的型别判断，也不支持对“对象析构函数是否为trivial”的判断，具体实现value_type()和__type_traits<>在3.7节。
![construct()和destroy()图解](http://p3ax8ersb.bkt.clouddn.com/201802011438_654.png-960.jpg)

#### 2.2.4 空间的配置与释放，std::alloc
对象构造前的空间配置和对象析构后的空间释放，由`<stl_alloc.h>`负责。
1. 向 system heap 要求空间
2. 考虑多线程(multi-threads)状态(这里不考虑多线程的情况)
3. 考虑内存不足时的应变措施
4. 考虑过多“小型区域”可能造成的内存碎片(fragment)问题

**C++内存配置的基本操作是:`:operator new()`，内存释放的基本操作是`::operator delete()`。这两个全局函数相当于C的malloc()和free()函数，所以SGI正是用malloc()和free()完成内存的配置和释放。**

为了解决小型区块可能造成的内存破碎问题，SGI设计了双层级的配置器，**第一级配置器`(__malloc_alloc_template)`用malloc()和free()，第二级配置器`(__default_alloc_template)`看情况而定：当配置区块超过128bytes，调用第一级配置器；小于128bytes，采用复杂的内存池`memory bool`整理方式。**其中具体是开放了第一级配置器还是两级配置器都开放了由__USE_MEALLOC是否定义决定，定义了__USE_MEALLOC就将alloc定义为第一级配置器，没有定义就将alloc定义为第二级配置器。SGI STL采用第二级配置器。

无论是第一级配置器还是第二级配置器，SGI都为其包装了一个接口`simple_alloc`，使其能够符合STL的接口规格。
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

图解如下：
    第一级配置器和第二级配置器：![第一级配置器和第二级配置器](http://p3ax8ersb.bkt.clouddn.com/201802011620_34.png-960.jpg)
    包装接口和运用：![包装接口和运用](http://p3ax8ersb.bkt.clouddn.com/201802011647_747.png-960.jpg)

更新时间：2018.02.17
#### 2.2.5 第一级配置器 __malloc_alloc_template 剖析
```c++
template <int inst> //inst 没有用到
class __malloc_alloc_template{
private:
    //处理内存不够的情况
    //oom: out of memory
    static void *oom_malloc(size_t);
    static void *oom_realloc(void*, size_t);
    static void (* __malloc_alloc_oom_handler)();

public:
    //直接调用malloc，free，realloc，只是多了一层封装，使之可以处理内存不够的情况
    static void* allocate(size_t n){
        void *result = malloc(n);
        if(0 == result)
            result = oom_malloc(n);
    }
    static void deallocate(void* p, size_t){
        free(p);
    }
    static void* reallocate(void* p, size_t, size_t new_sz){
        void* result = realloc(p, new_sz);
        if(0 = result)
            result = oom_realloc(p, new_sz);
            return result;
    }

    //仿真c++的set_new_handdler()
    static void(* set_malloc_handler(void(*f)()))(){
        //被调用的函数__malloc_alloc_oom_handler
        void(* old)() = __malloc_alloc_oom_handler;
        __malloc_alloc_oom_handler = f;
        return (old);
    }
    //__malloc_alloc_oom_handler函数初始值是0，该值由客端自己设定
    template <int inst>
    void (* __malloc_alloc_template<inst> :: __malloc_alloc_oom_handler)() = 0;

    //oom_malloc
    template <int inst>
    void* __malloc_alloc_template<inst> :: oom_malloc(size_t n){
        void (* my_malloc_handler)();
        void* result;
        for(; ;){   //不停的尝试，释放，配置，释放，配置……
            my_malloc_handler = __malloc_alloc_oom_handler;
            //如果没有设置__malloc_alloc_oom_handler的值，直接抛出异常
            if(0 == my_malloc_handler){
                __THROW_BAD_ALLOC;
            }
            (*my_malloc_handler)(); //调用处理例程，企图释放内存
            result = malloc(n);     //再次配置
            if(result)
                return (result);
        }
    }
    //oom_realloc
    template <int inst>
    void* __malloc_alloc_template<inst> :: oom_realloc(void* p, size_t n){
        void (* my_malloc_handler)();
        void* result;
        for(; ;){   //不停的尝试，释放，配置，释放，配置……
            my_malloc_handler = __malloc_alloc_oom_handler;
            //如果没有设置__malloc_alloc_oom_handler的值，直接抛出异常
            if(0 == my_malloc_handler){
                __THROW_BAD_ALLOC;
            }
            (*my_malloc_handler)(); //调用处理例程，企图释放内存
            result = malloc(n);     //再次配置
            if(result)
                return (result);
        }
    }
}
```
第一级配置器以malloc()、free()、realloc()等C函数执行实际的内存的配置、释放、重配置操作，同时实现出类似C++ new-handler的机制。所谓new-handler就是在系统内存配置需求无法被满足的情况下，调用一个指定的函数。
#### 2.2.6 第二级配置器__default_alloc_template 剖析
第二级配置器__default_alloc_template多了些机制，避免太多小额区块造成内存的碎片。

当区块超过128bytes，则用内存池管理，此做法又称为次层配置(sub-allocation)：每次配置一大块内存，并维护对应自由链表(free-lists)。下次如果再有相同大小的内存需求，就直接从free-lists中取出。如果客端释放返还小额区块，就有配置器会受到free-lists中。二级配置器会自动将内存调整为8的倍数，并维护16个free-lists，各自管理8的倍数的小额区块。
```c++
//free-list的节点
union obj{
    union obj *free_list_link;
    char client_data[1];
}
```
其中，obj是一个obj指针，指向下一个相同大小的区块。同时obj是一个指针，指向实际中区块。结合2.2.7的图理解。
如图：
![free-lists](http://p3ax8ersb.bkt.clouddn.com/201802171615_46.png-480.jpg)
#### 2.2.7 空间配置函数allocate()
allocate()是二级配置器__default_alloc_template的一个标准接口函数。这个函数首先判断区块大小，大于128bytes调用的第一级配置器，小于128bytes的查询对应free-list有可以用的区块，就直接拿来用，如果没有，就将区块大小调至8倍数边界，然后调用refill()，为free list重新填充空间。
```c++
//n > 0
static void* allocate(size_t n){
    //二级指针，但是volatile的用法不详
    obj* volatile *my_free_list;
    obj* result;

    if(n>(size_t) __MAX_BYTES){
        return (malloc_alloc::allocate(n));
    }
    //寻找16个free list中适合的一个
    my_free_list = free_list + FREELIST_INDEX(n);
    result  = *my_free_list;
    if(result == 0){
        //准备填充free list
        void* r = refill(ROUND_UP(n));
        return r;
    }
    //调整free list
    *my_free_list = result -> free_list_link;
    return (result);
}
```
图解如下：
![freel list 拔出](http://p3ax8ersb.bkt.clouddn.com/201802171658_88.png-480.jpg)
#### 2.2.8 空间释放函数 deallocate()
deallocate()是配置器__default_alloc_template的一个标准接口函数。大于128bytes调用第一级配置器，小于128bytes找到对应的free list将区块回收。
```c++
// p不可以是 0
static void deallocate(void *p, size_t n){
    obj* q = (obj* )p;
    //二级指针，但是volatile的用法不详
    obj* volatile *my_free_list;

    if(n>(size_t) __MAX_BYTES){
        malloc_alloc::deallocate(p, n);
        return;
    }
    //寻找对应的free list
    my_free_list = free_list + FREELIST_INDEX(n);
    //调整free list，回收区域
    q->free_list_link = *my_free_list();
    *my_free_list = q;
}
```
图解如下：
![deallocate](http://p3ax8ersb.bkt.clouddn.com/201802171745_127.png-480.jpg)
#### 2.2.9 重新填充 free lists
allocate()中，当它发现free list中没有可用区块的时候，调用refill()，为free list重新填充空间。新的空间将取自内存池(chunk_alloc()完成)。缺省获得20个新节点。
```c++
//返回一个大小为n的对象，并且有时候会为适当的free list增加节点
//假设n已经适当上调至8的倍数
template <bool threads, int inst>
void* __default_alloc_template<threads, inst> :: refill(size_t n){
    int nobjs = 20; //缺省值
    //调用chunk_alloc()，尝试获得nobjs个区块作为free list的新节点
    char* chunk = chunk_alloc(n, nobjs);
    obj* volatile* my_free_list;
    obj* result;
    obj* current_obj, *next_obj;
    int i;
    //如果只获得一个区块，这个区块就分配给调用者使用，free list无新节点
    if(1 == nobjs)
        return (chunk);
    //否则调整free list纳入新的节点
    my_free_list = free_list + FREELIST_INDEX(n)；
    //以下在chunk空间创建free list
    result = (obj *)chumk;
    //以下导引free list 指向新配置的空间(取自内存池)
    *my_free_list = next_obj = (obj*)(chunk + n);
    //以下将free list 的各个节点串联起来
    for(i = 1; ; i++){  //从n == 1开始，因为0号要返回给客端
        current_obj = next_obj;
        next_obj = (obj*)((char *)next_obj + n);
        if(nobjs - 1 == i){
            current_obj -> free_list_link = 0;
            break;
        }
        else{
            current_obj->free_list_link = next_obj;
        }
    }
    return (result);
}
```
内存池暂时先按下……
#### 2.2.10 内存池(memory pool)

### 2.3 内存基本处理工具
STL定义了五个全局函数，作用于未初始化化空间上：用于构造的`construct()`和析构的`destroy()`,另外三个是：`uninitialized_copy(),uninitialized_fill(),uninitialozed_fill_n()`(定于于`<memory>`),分别对应于高层次函数`copy(),fill(),fill_n()`,这些都是STL的算法。
#### 2.3.1 uninitialized_copy
#### 2.3.2 uninitialized_fill
#### 2.3.3 uninitialized_fill_n
