---
title: 堆(heap)的实现
date: 2018-04-02 17:08:01
tags:
categories:
    - "knowledge"
    - "数据结构"
keywords:
    - "C++"
    - "heap"
password:
---
## 定义
### 最大堆和最小堆
堆是一种完全二叉树数据结构。一般他的实现可以使用链表或者数组。**因为是完全二叉树，所以使用数组作为存储结构更加方便。**如果有一个数组a\[\]={2,3,1,5,6,4};可以创建两种堆，最大堆和最小堆。**所谓最大堆指的是父亲节点的值比孩子节点的值要大，最小堆指的是父亲节点的值要比孩子节点的值要小。**如下图：
![heap](http://p3ax8ersb.bkt.clouddn.com/201804021725_368.png-960.jpg)
<!--more-->
**生成最大堆或最小堆实际上就是对数组中的数据，按照最大堆或最小堆的规则进行交换，这里的二叉树只不过是抽象出来的形式，其本质还是他的存储结构——数组。**
### 完全二叉树用vector表示
为什么完全二叉树用数组表示呢？这个是因为完全二叉树的特性决定的。由于是完全二叉树，所以在全部节点不是有两个孩子节点就是叶子节点。**假设父亲节点的下标是n，那么用数组的方式，可以通过下标直接找到其孩子节点。(左孩子节点的下标是2\*n+1,右孩子节点的下标是2\*n+2。)**比如上述例子中，父亲节点是a\[1\],那么左孩子节点是a\[3\]，右孩子节点是a\[4\]。同时如果知道孩子节点也可以知道父亲节点的下标，**不管是左孩子还是右孩子节点，如果其下标是n，那么他父亲节点的下标是(n-1)/2取整。**
正是因为完全二叉树可以直接通过数组下标的方式很方便的确定父子节点，所以通过数组存储是很有效的。但是因为堆是动态增长的结构，所以采取vector为存储结构。

## 构造堆并调整
```c++
Heap()
{}
Heap(T* a, size_t n){
    //reserve
    _array.reserve(n);
    for(size_t i = 0; i < n; ++i){
        _array.push_back(a[i]);
    }
    for(int i = (_array.size()-2)/2; i >= 0; --i){
        AdjustDwon(i);
    }
}
```
这里提供了两个构造函数，一个是空构造函数，用来创建一个空的堆对象；一个是传参的构造函数，用来创建符合要求的堆对象。
### 空构造函数
创建空的堆对象的构造函数，尽管函数体没有任何的执行语句，但是当该构造函数被调用的时候，类的私有成员`vector<T> _array;`会调用他的默认构造函数来构造一个\_array对象。按道理来说这个构造函数有些画蛇添足，是因为一般来说，默认的构造函数就可以实现这个功能。**可是由于有了自己定义的构造函数，编译器不会再创建默认的构造函数，所以还是需要自己显示的创建空构造函数，它的功能和默认的构造函数是一样的。**
### 传参的构造函数
带参的构造函数是我们主要用到的构造函数，这里有几个点需要说明一下
#### reserve()函数的使用
reserve函数作为vector容器的内置函数，它的作用是开辟指定大小的空间。因为我们已经知道了需要开辟的空间大小，所以为了节省需要多次开辟空间的导致的消耗，就利用函数reserve一次性开辟好空间，这样会节省开销。
#### Adjustdown函数
##### 仿函数
再说明Adjustdown函数之前，先解释一下仿函数。仿函数顾名思义就是类似函数。其本质是对运算符`()`的重载，通过对`()`的重载，就产生了类似于函数调用的感觉，比如上述代码实现中一样，调用的时候给人的感觉就是仿函数：
![仿函数](http://p3ax8ersb.bkt.clouddn.com/201804021913_148.png-960.jpg)
上面这例子中定义了一个Less对象less，调用仿函数的时候就像调用了一个名为less的函数。下文代码实现了两个仿函数，分别用于创建最大堆和最小堆。在Adjustdown函数中会用到。
```c++
//仿函数
//Less
template <class T>
struct Less{
    bool operator()(const T& left, const T& right){
        return left < right;
    }
};
//Greater
template <class T>
struct Greater{
    bool operator()(const T& left, const T& right){
        return left > right;
    }
};
```
##### Adjustdown函数(一次向下调整函数)，本文用最大堆来讲解
一次向下调整函数的出现，是为了保证插入的数据在数组中是维持了最大堆或最小堆的性质。向下调整的思路很简单，查看当前父亲节点的孩子节点，如果父亲节点比两个孩子节点都要大，那么不需要交换位置；如果父亲节点比孩子节点中较大的要小，那么交换两者。这时，再查看父亲节点是否比当前的两个孩子都要大。一次循环即可。流程见下图：
![Adjustdown](http://p3ax8ersb.bkt.clouddn.com/201804021933_787.png-1920.jpg)

通过上图的调节，就完成了一次调整，起码保证了一条路径上的节点是维持了最大堆的特性。调整是利用循环实现的，循环结束的条件就是孩子节点的下标没有超过vector的大小或者父亲节点比孩子节点都要大。
##### 小技巧
因为parent替换的lchild和rchild中较大的一个，那么我们怎么确定较大的那一个呢。**我们可以这样，不定义左右孩子节点，只定义一个孩子节点，这个孩子节点是左孩子节点。然后用这个child节点和下标比它大一个值的节点比较大小(因为下标比它大一个值的节点一定是右孩子)，让大的作为child的值，这样就保证了child一定是孩子节点中较大的那一个。注意的是，在比较大小之前先判断右孩子是不是存在。**同时，循环结束的判断可以直接用child判断是否超过vector的大小。
这里判断大小的时候，就利用到了仿函数。因为堆有最大堆和最小堆，如果是最大堆就利用上面的逻辑，如果是最小堆就反之。那么如何知道是最大堆还是最小堆，我们可以通过向heap类传入一个仿函数，然后在调用的时候定义是Less还是Greater仿函数即可实现比较的时候用的是大于比较还是小于比较。
```c++
//Adjustdown函数
void AdjustDwon(size_t root){
    Compare com;
    size_t parent = root;
    size_t child = parent*2 + 1;
    while(child < _array.size()){
        if(child+1 < _array.size()
          && com(_array[child+1], _array[child])){
            ++ child;
        }
        if(com(_array[child], _array[parent])){
            swap(_array[child], _array[parent]);
            parent = child;
            child = parent*2 + 1;
        }
        else{
            break;
        }
    }
}
```
##### 补充
但是一次向下调整函数毕竟只能改变一条路径，那么我们如何利用起来的呢。在构造函数中，我们找到堆的最后一个父亲节点，然后从这个元素依次向上调用向上调整函数就可以保证调整之后整个数组的元素符合最大堆或者最小堆的性质。带参的构造函数中是如下调用的：
```c++
for(int i = (_array.size()-2)/2; i >= 0; --i){
    AdjustDwon(i);
}
```
寻找最后一个元素很简单，就是让vector的最后一个元素的下标减一除二取整就可以获取到最后一个父亲节点的下标。**需要注意的是，vector的内置函数size()返回的元素个数，而数组的下标是从零开始的，所以需要多减去一个一才符合。**
## 插入函数
插入函数调用vector的push_back()函数进行尾插，然后从后向前调整，调用一次向上调整函数。
### Push函数
```c++
//Push
void Push(const T& x){
    _array.push_back(x);
    AdjustUp(_array.size() - 1);
}
```
### AdjustUp函数(向上调整函数)
有了向下调整函数的基础，这个向上调整函数是同理。这里只要调用一次就好，是因为插入一个元素只会影响一条路径上的元素大小是否符合规则。
![adjustup](http://p3ax8ersb.bkt.clouddn.com/201804022003_82.png-1920.jpg)
```c++
void AdjustUp(size_t child){
    Compare com;
    int parent = (child - 1)/2;
    while(child > 0){
        if(com(_array[child], _array[parent])){
            swap(_array[child], _array[parent]);
            child = parent;
            parent = (child - 1)/2;
        }
        else{
            break;
        }
    }
}
```
## 出堆函数
Pop函数将堆顶的数据出堆，并保证堆的特征。如果我们是直接将堆顶的数据出堆，然后再进行调整的话，需要跟构造函数那样进行多次向下调整。那么整个堆的结构将会出现完全的改变。同时比较节点的大小的时候会十分混乱。**为了解决这个矛盾，我们可以采用更巧妙的方式，通过将堆顶的数据和堆末的数据进行交换，交换之后通过vector的pop_back函数弹出，再用一次向下调整函数就可以了。**
![pop](http://p3ax8ersb.bkt.clouddn.com/201804022013_693.png-1920.jpg)
```c++
void Pop(){
    swap(_array[0], _array[_array.size() - 1]);
    _array.pop_back();
    AdjustDwon(0);
}
```
## 判空，大小，堆顶元素
这几个函数都是调用vector的内置函数封装而成。
```c++
//Empty
bool Empty(){
    return _array.empty();
}
//Size
size_t Size(){
    return _array.size();
}
//Top
const T& Top(){
    return _array[0];
}
```
## 完整代码
```c++
#pragma once

//Less
template <class T>
struct Less{
    bool operator()(const T& left, const T& right){
        return left < right;
    }
};
//Greater
template <class T>
struct Greater{
    bool operator()(const T& left, const T& right){
        return left > right;
    }
};

template <class T, class Compare>
class Heap{
public:
    //constructor
    Heap()
    {}
    Heap(T* a, size_t n){
        //reserve
        _array.reserve(n);
        for(size_t i = 0; i < n; ++i){
            _array.push_back(a[i]);
        }
        for(int i = (_array.size()-2)/2; i >= 0; --i){
            AdjustDwon(i);
        }
    }
    //Push
    void Push(const T& x){
        _array.push_back(x);
        AdjustUp(_array.size() - 1);
    }
    //Pop
    void Pop(){
        swap(_array[0], _array[_array.size() - 1]);
        _array.pop_back();
        AdjustDwon(0);
    }
    //Empty
    bool Empty(){
        return _array.empty();
    }
    //Size
    size_t Size(){
        return _array.size();
    }
    //Top
    const T& Top(){
        return _array[0];
    }
    //Print for Test
    void Print(){
        if(!_array.empty()){
            for(size_t i = 0; i < _array.size(); ++i){
                cout << _array[i] << " ";
            }
        }
    }

protected:
    vector<T> _array;

    void AdjustDwon(size_t root){
        Compare com;
        size_t parent = root;
        size_t child = parent*2 + 1;
        while(child < _array.size()){
            if(child+1 < _array.size()
              && com(_array[child+1], _array[child])){
                ++ child;
            }
            if(com(_array[child], _array[parent])){
                swap(_array[child], _array[parent]);
                parent = child;
                child = parent*2 + 1;
            }
            else{
                break;
            }
        }
    }

    void AdjustUp(size_t child){
        Compare com;
        int parent = (child - 1)/2;
        while(child > 0){
            if(com(_array[child], _array[parent])){
                swap(_array[child], _array[parent]);
                child = parent;
                parent = (child - 1)/2;
            }
            else{
                break;
            }
        }
    }
};
```