---
title: 浅读《More Effective C++》笔记
date: 2018-01-30 14:27:03
tags:
categories:
    - "learning"
---
## 第一章 基础议题
### 条款1：区分指针和引用
**不存在空引用，引用必须要指向某个对象。当确定某个对象不允许有空值，就需要定义为引用，而不是指针。**
```c++
//这种做法语法上没有错误，出现了引用为空的情况。但是不同的编译器会有不同的报错。不允许出现这样的代码。
char* pc = 0;
char &rc = *pc;
```
因为不存在空引用这种情况，所以使引用会比指针更高效。
<!--more-->
```c++
//引用不用判空
void print_double(const double& rd){
    cout << rd;
}
//指针要判空
void print_double1(const double *pd){
    if(pd){ cout << *pd; }
}
    ```
指针可以被重新赋值用以指向另外一个不同的对象，而引用则总是指向初始化时它指向的对象。
```c++
string s1("nancy");
string s2("clancy");
string& rs = s1;
string *ps = &s1;
//rs依然是s1的引用，此时rs = s1 = s2 = "clancy"
rs = s2;
//ps指向了s2,不再指向s1
ps = &s2;
```
**实现某些操作符的时候，最常见的是[]操作符，绝大多数应该返回引用。**
```c++
vector<int> v(10);
//一般情况下的返回值，此时是引用
v[5] = 10;
//如果返回的是指针就需要这样解引用，看起来v就像是一个指针vector一样。
*v[5] = 10;
```

### 条款2：优先考虑C++风格的类型转换
四个类型转换操作符：static_cast,const_cast,dynamic_cast,reinterpret_cast

- **static_cast：作用类似于C中的隐式类型转换，只能转换相近类型的变量。比如struct到int的转换就不能实现。而且在C++中，static_cast并不能将const属性转换为非const属性。**
- **const_cast：专门用来去除const属性和volatile属性。const_cast被用来用作其他的类型转换会被拒绝。**
- **dynamic_cast：它是用来针对一个继承体系做向下或者横向的安全转换的。也就是说，用dynamic_cast把指向基类的指针或引用转换成指向派生类或者基类的兄弟类的指针或引用，同时可以知道是否成功。出现空指针(转换指针的时候)或者出现异常(转换引用的时候)意味着失败。他不能用于哪些没有虚函数的类型，也不能去除const属性。**
- **reinterpret_const：这个操作符，转换结果往往是编译器定义的。因此它几乎是不可以移植的。最常见的用法是在函数指针之间进行类型转换。但是一般我们不使用这种转换，因为c++没有规定这种做法，有可能出现未知的错误，除非万不得已，不然不使用。**

使用格式举例：
`static_cast<double> (first); const_cast<special*>(first); dynamic_cast<special *>(&first); reinterpret_cast<funcptr> (&dosomething)`

### 条款3：绝不要把多态应用于数组
继承的一大特性，它允许你通过指向基类的指针和引用来操纵派生类对象。这种指针和引用的行为具有多态性。**同时C++也允许你通过基类指针和引用来操纵派生类数组，但是这个应该不被允许**。见下面这个例子：
```c++
//一个BST类，有一个BalancedBST的类，它继承与BST
class BST{
    //...
};
class BalancedBST{
    //...
};
//一个用于打印BST数组中BST元素的函数
void printBSTArray(ostream&s, const BST array[], int numElements){
    for( int i = 0; i < numElements; ++i ){
        s << array[i];
    }
}
```
第一种情况，传递的数组是BST数组，程序没有问题；第二种情况，传递的数组是BalancedBST数组(继承于BST),编译器并不会报错，但是会出现问题，关键在于对array[i]的使用。`array[i]=*(array+i)`，我们知道array是指向数组的首地址的指针，其中array+i偏移的地址是根据元素的大小而定的。因为上例子中，array的类型是BST，所以array[i]的偏移是array+i*sizeof(SBT)。但我们传递了BST的子类BalancedBST给array，这样array的访问就会出现问题。

同时，如果打算通过一个基类指针删除一个包含派生类对象的数组，一样会出现问题。
```c++
void deleteArray(ostream& logStream, BST array[]){
    logStream << static_cast<void*>(array) << endl;
    delete[] array;
}
BalancedBST *balTreeArray = new BalancedBST[50];
//...
deleteArray(cout, balTreeArray);
```
明面上这里并没有调用指针，但是当删除数组的时候，数组元素的析构函数必须被调用。

### 条款4 避免不必要的默认构造函数
更新时间：2018.02.19
默认构造函数指的是在C++语言中，不需要传参数就可以调用的构造函数，用于对象的初始化。但有的时候，我们要求这个对象，必须包含一些特定的值。比如下面例子：
```c++
class EquipmentPiece{
public:
    EquipmentPiece( int IDNumber ){}
    //...
};
```
此时EquipmentPiece类没有默认的构造函数，有三种情况，对它的应用会出现问题。第一种情况，如下：
```c++
EquipmentPiece bestPieces[10];  //没法调用构造函数
EquipmentPiece *bestPieces = new EquipmentPiece[10];    //没法调用构造函数
```
这里有三种方法可以避开这个限制。第一种，对于不在堆上分配内存的数组，在定义数组的时候，提供必要参数。**第二种，不使用对象数组，使用一个指针数组**，如下：
```c++
typedef EquipmentPiece* PEP;
PEP bestPieces[10];
PEP *bestPieces = new PEP[10];
//这样，数值的每一个指针都可以被重新赋值以指向不同的EquipmentPiece对象。
for( int i = 0; i < 10; ++i ){
    bestPieces[i] = new EquipmentPiece( ID Number );
}
```
但是这两种方法有两个缺点，**第一个是，你必须记住删除数组指针所指向的所有对象，不然会出现内存泄漏。第二，这样的方法所需要的内存需求总量会增加，需要额外的空间去存储指针。**

第三种方法，为数组分配原始内存，可以避免额外的内存消耗，利用placement new技术，如下：
```c++
void * rawMemory = operator new[](10*sizeof(EquipmentPiece));
EquipmentPiece* bestPieces = static_cast<EquipmentPiece*>(rawMemory);
for( int i = 0; i < 10; ++i ){
    new(bestPieces+i) EquipmentPiece( ID Number );
}
```
这个方法的缺点是，删除的时候，先要手工调用析构函数，然后再手工调用delete[]函数，这样才能够释放原始内存。
```c++
for( int i = 9; i >= 0; --i ){
    bestPieces[i].~EquipmentPiece();
}
operator delete[](rawMemory);
```
没有默认构造函数所造成的第二个问题是，他们没有办法作为许多基于模板的容器类的类型参数使用。因为通常用于实例化模板的那些类型需要提供默认构造函数。这个要求大多数时候来自模板内部需要创建关于模板参数类型的数组。例子如下：
```c++
template<class T>
class Array{
public:
    Array( int size );
private:
    T* data;
};
template <class T>
Array<T>::Array(int size){
    date = new T[size];
}
```
在大多数情况下，可以通过谨慎的设计排除对默认构造函数的需要。标准的vector模板就不要求。
没有默认构造函数的第三个问题是。在有虚基类的时候，到底要不要提供默认构造函数。没有默认构造函数的虚基类使用起来十分痛苦。这是因为虚基类的构造函数所要求的参数必须由被创建对象所属的最远的派生类提供。这样就导致了，没有默认构造函数的虚基类会要求所有由它继承下来的派生类都必须知道、理解虚基类构造函数的参数的含义并提供这些参数。
## 第二章 运算符
### 条款5：小心用户自定义的转换函数
C++允许编译器在两种数据类型之间进行隐式转换，char到int、short到double。甚至会出现数据丢失的也可以，int到char、double到short的转换。
接下来介绍两种类型函数可以让编译器实施这种隐式转换：单个参数的构造函数和隐式的类型转换运算符。
**单个参数的构造函数**指的是，只传递给它一个参数就可以调用的构造函数。这种构造函数可以只定义一个参数，也可以定义多个参数。定义多个参数的时候，除了第一个参数，后面的参数应该是有默认值的。例子如下：
```c++
class Name{
public:
    Name(const string& s);
};
class Ratinal{
public:
    Rational(int numerator = 0, int denominator = 1);
};
```
隐式的类型转换运算符只不过是名字看上去比较奇怪的成员函数：在operator关键字后面指定类型。