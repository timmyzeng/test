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
#### 单个参数的构造函数和隐式类型转换符
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
**隐式的类型转换运算符**只不过是名字看上去比较奇怪的成员函数：在operator关键字后面指定类型。**同时，不能指定这个函数的返回值类型，因为返回值的类型就是这个函数的名字。**比如说，为了允许有理数对象可以被隐式地转换为double类型，可以如下定义：
```c++
class Rational{
public:
    //...
    operator double() const;
};
```
这个隐式的转换函数在类似于下列情况下会被自动调用：
```c++
Rational r(1, 2);
double d = 0.5*r;
```
#### 为什么不希望给任何类型提供隐式类型转换函数
例子：如果还是上面的有理数Rational对象
```c++
Rational r(1, 2);
cout << r;  //此时应该输出1/2
```
但是因为没有重载cout，按道理来说应该没有办法编译通过。可是因为编译器的优化，他会试图通过找到合适的隐式类型转换以便程序成功运行。上述代码就会发现可以通过调用`Rational::operator double`函数将r隐式转换为double。这样上述代码打印的是一个浮点型，而不是一个有理数。
#### 解决办法
对于隐式的类型转换符，使用名字不同于语法关键字但功能相同的函数来代替转换运算符。例如为了把Rational对象转换为double，使用名为asDouble这样的函数代替operator double函数：
```c++
class Rational{
public:
    //...
    double asDouble() const;
};
//调用
Rational r(1, 2);
cout << r;  //operator<< 没有被重载，调用失败

cout << r.asDouble();   //调用成功，输出浮点型数据
```
对于单个参数的构造函数，第一种十分简单的方法：我们可以通过使用 **关键字explicit就可以解决隐式类型转换的问题**。比如下列例子：
```c++
template <class T>
class Array{
public:
    //...
    explicit Array(int size);
    //...
    Array<int> a(10);
    Array<int> b(10);
};
if(a == b[i])
    //...
    //报错，如果Array的构造函数没有被声明为explicit的话，是可以判断成功的。
    //a是Array<int>类型，b[i]是int类型，operator==函数发现两个参数分别是Array<int>和int类型。
    //虽然没有适配的函数，但是b[i]可以通过单参数的构造函数从int类型转换为Array<int>类型。
if(a == (Array<int>)b[i])
    //...
    //可以，通过C风格的隐式类型转换
if(a == static_cast< Array<int> >(b[i]))
    //...
    //可以，这个是C++风格的隐式类型转换
    //注意，static_cast<Array<int> >(b[i])此处的 > >一定要空格开来，不然会被解释为输入运算符>>
if(a == Array<int>(b[i]))
    //...
    //可以，用b[i]创建一个Array<int>对象，类型符合
```

第二种方法：可以通过重组类的模板实现。因为决定隐式类型转换的序列是否合法，还需要通过一定的规则，其中有一个规则是这些隐式的转换不能包含多于一个用户自定义类型转换。
所以我们将上面数组类的大小通过一个代理类来获取，这样构造函数的大小是调用了一个自定义函数。代码如下：
```c++
template <class T>
class Array{
public:
    class ArraySize{
    public:
        ArraySize(int numElements)
            :theSize(numElements)
            {}
        int size() const { return theSize;}
    private:
        int theSize;
    };
    Array(ArraySize size);
};
```
上述代码在Array类中嵌套了一个ArraySize代理类。
当我们使用下列代码的时候：
```c++
Array<int> a(10);
```
编译器要求调用一个接受int类型参数的构造函数，但是Array类没有，不过编译器意识到，可以将int类型转换为一个临时的ArraySize对象，ArraySize对象正是`Array<int>`需要的。这样也就创建成功了。
那么是不是可以避免隐式类型转换呢
```c++
bool operator==(const Array<int>& lrs, const Array<int>& hrs);
Array<int> a(10);
Array<int> b(10);
//...
for(int i = 0; i < 10; ++i){
    if(a == b[i])
        //...
        //报错
}
```
为了调用operator==函数，需要一个`Array<int>`对象在`==`的右边，但是不存在一个参数为int的单个参数构造函数。而且编译器无法通过吧int转换为一个临时的ArraySize对象，再根据这个临时对象创建必须的`Array<int>`对象。

### 条款6：区分自增运算符和自减运算符的前缀形式和后缀形式
#### 前缀形式和后缀形式的区别
```c++
class UPInt{
public:
    UPInt& operator++();
    const UPInt operator++(int);
    UPInt& operator--();
    const UPInt operator--(int);
};
```
当函数被调用的时候，编译器悄无声息的传递一个0作为int参数的值给该函数。**其中前缀形式返回一个引用，后缀形式返回一个const对象。**

```c++
UPInt& UPInt::operator++(){
    *this += 1;
    return *this;
}

const UPInt UPInt::operator++(int){
    count UPInt oldvalue = *this;
    //*this += 1;
    //复用前缀自增
    ++(*this);
    return oldvalue;
}
```
#### 后缀形式返回const
后缀自增形式的返回值是一个const对象，为什么是一个const对象呢？如果不是const对象，那么下面这个代码就是正确的：

```c++
UPInt i;
i++++;
```
但是很明显这样是不正确的。根据内置类型的性质，当我们自增两次int类型的数据的时候，这个是不允许发生的。
有一个点需要说明的是，如果不是很必要使用后缀自增的形式，那么尽量使用前缀自增。**因为后缀自增首先需要显示创建一个临时变量，然后返回的时候，还需要创建一个临时对象作为返回。最后结束函数的时候需要析构两者。如果十分在意效率问题，尽量使用前缀自增。**
最后，为了降低维护成本，后缀自增或自减最好复用前缀自增或自减。这样只需要维护前缀自增或自减即可。

### 条款7：不要重载“ && ”、“ || ”和“ , ”
#### 短路求值法
C++使用了**短路求值法**对布尔表达式求值。这个表示，一旦确定了布尔表达式为真或为假，即使还有部分表达式还没有测试，布尔表达式也会停止运算。

```c++
char* p;
//...
if(p != 0 && strlen(p) > 10)
    //...
```
这里我们永远不需要担心strlen中的p是否为0值，因为p=0的时候，strlen(p)根本就不会进行运算。

#### 不要重载“ && ” 和 “ || ”
实际上，C++允许我们对`&& ||`进行重载，但是为了保证短路求值法的正确性，我们要确定不要重载`&& ||`这两个运算符。如果重载了`&&`，效果如下：

```c++
if(exp1 && exp2)
if(exp1.operator&&(exp2))
if(operator(ex1, ex2))
```
这样就变成了函数的调用，首先，函数的调用需要求出两个参数的运算结果，这样就不能实现短路求值的功能；其次，函数的调用没有规定先运算哪个参数，有可能是第一个，也有可能是第二个。

#### 不要重载逗号运算符
逆置一个字符串的例子：
```c++
void reverse(char s[]){
    for(int i = 0, j = strlen(s) - 1; i < j; ++i, --j){
        int c = s[i];
        s[i] = s[j];
        s[j] = c;
    }
}
```
**包含逗号的表达式，首先计算逗号左边的表达式，然后计算右边的表达式；整个表达式返回最右边的表达式的值。**鉴于你完全没有办法模拟这个行为，所以不要重载逗号运算符。
#### 不能重载以下的运算符

 - `.`
 - `.*`
 - `::`
 - `?:`
 - `new delete sizeof typeid`
 - `static_cast dynamic_cast const_cast reinterpret_cast`

### 条款8：理解new和delete在不同情形下的含义
#### 区分 new 操作符(new operator)和 operator new 函数
```c++
string *ps = new string("Memory Management");
```
上面的代码中使用的new 指的是 new 操作符。new分配足够多的内存用以容纳一个string对象，再调用构造函数用来初始化刚分配的内存中的对象。new的这两个操作是无法被修改的。
所能修改的是如何为对象分配内存。new操作符分配内存所调用函数的名字是operator new，其声明通常如下：
```c++
void *operator new(size_t size);
```
一般来说，我们并不会直接调用operator new函数。但是如果我们需要调用它可以这样：
```c++
void *rawMemory = operator new(sizeof(string));
```
函数operator new返回一个指针，指向一块足够容纳一个string对象的内存。
如果想要创建一个堆对象，只能使用new函数，这个是因为构造函数只有编译器可以调用，个人无法直接调用。
#### placement new函数
有的时候真的需要直接调用构造函数，有一种情况可以用到。就是在一块已经分配了大小的却没有初始化的内存，可以调用函数placement new，他是operator new函数的特化版本。
使用见下列例子：
```c++
class Widget{
public:
    Widget(int widgetSize);
    //...
};
Widget* constructWidgetInBuffer(void *buffer, int widgetSize){
    return new(buffer) Widget(widgetSize);
}
```
这个函数返回一个指向Widget对象的指针，而Widget对象在传递给函数的buffer种分配。**当程序使用共享内存或者memory-mapped I/O的时候，这种函数可能会被用到。**

 - 如果想在对上建立一个对象，使用new函数，它既分配内存又为对象调用构造函数。
 - 如果仅仅是想要分配内存，就调用operator new函数。它不会调用构造函数。
 - 如果想要定制在堆对象被创建时的内存分配过程，重载operator new函数，然后使用new函数，它会调用你的operator new函数。
 - 想要在一块已经有指针指向的内存中创建一个对象，使用placement new函数。

#### 对象删除和内存释放
通常我们使用delete来释放内存。实际上delete操作符调用operator delete函数，其声明如下：
```c++
void operator delete(void* memoryToBeDeallocated);
```
因此调用delete函数的时候，生成类似于下列的语句：
```c++
string* ps;
delete ps;
//->
ps->~string();
operator delete(ps);
```
如果 **用placement new函数在内存中创建对象，此时不能用delete操作符**。因为delete操作符调用operator delete函数，而operator delete函数释放由operator new函数分配的内存。但是谁知道placement new函数指向的内存是谁创建的呢。所以我们 **应该显示的调用对象的析构函数来销毁函数创建的对象。**

#### 数组(Array)
```c++
string *ps = new string[10];
```
这里使用的是operator new[]函数
```c++
delete [] ps;
```
相应的使用delete[]函数来释放内存。
[**对delete[]的具体解析**](https://blog.csdn.net/Mac_timmy/article/details/78736460)

## 第三章异常
## 第四章效率
### 条款16：记住80-20原则
20%的代码占用了80%的资源，所以需要提高效率就需要找到这一小部分的核心代码。
### 条款17：考虑使用延迟计算
延迟计算指的是，我们写一个类的时候，需要运算的部分会被延迟进行，直到程序要求给出结果的时候才进行计算。这里分为四个运算场景
#### 引用计数(Reference Counting)
```c++
class String{
    //...
};
String s1 = "Hello";
String s2 = s1;
```
如果我们使用即时计算，那么s2初始化的时候，会直接拷贝构造一份字符串"Hello"。这个需要使用到new操作符在堆上分配空间。这样会有比较大的开销。**如果我们使用延时计算，只需要让s1和s2共享s1的"Hello"字符串，这个只是简单的记录工作。以便知道谁共享了这个空间。**
```c++
cout << s1;
cout << s1 + s2;
```
对于以上代码来说，延时计算和即时计算并没有任何的不同，因为这里只是读取，并没有写入。但是延时计算的方式减，了调用操作符new和拷贝构造函数的开销。
共享数据唯一行不通的就是需要改变其中一个数据的值的时候，而不是全部都需要改变。这个时候，只能够将s2拷贝一份，然后再进行修改，防止对s1进行了修改。

#### 区分读操作和写操作
如果继续探讨引用计数这个例子，还有一个地方可以通过延时计算来提高效率
```c++
String s = "Hello";
//...
cout << s[2];
s[3] = 'x';
```
第一次调用operator[]是为了读取s中的字符，第二次调用operator[]是为了向s中写入数据。我们可以通过一个方法，在operator[]函数中区分读操作和写操作，因为只有写操作才需要一份拷贝，读操作是不需要这些拷贝的开销的。
残忍的是，我们没有办法知道什么时候是写操作还是读操作。**不过通过延迟计算和条款30讲的代理类，我们可以将对操作的判断推迟到我们可以决定哪一个是正确的操作的是。**

#### 延迟读取(Lazy Fetching)
假设这里有个程序使用了包含许多数据成员的对象。这些对象必须在每次程序运行的时候保留下来，所以他们被存入了数据库。同时每个对象都有一个唯一的对象标识符用来从数据库中取出这个对象：
```c++
class LargeObject{
public:
    LargeObject(ObjectID id);
    const string& field1() const;
    int field2() const;
    double field3() const;
    //...
};
```
这个时候，从硬盘中恢复一个LargeObject所需要的开销是十分大的。但是如果我们只需要field2的数据，这个是获取其他字段付出的开销都是浪费。
```c++
voide restoreAndProcessObject(ObjectID id)
{
    LargeObject object(id);
    if(object.field2() == 0){
        cout << "Object" << id << ": null field2.\n";
    }
}
```
对于这种情况，我们可以通过创建LargeObject对象的时候，不从硬盘中读取数据，而是仅仅创建这个对象的外壳，在需要使用某项数据的时候，才冲数据库中获取。
```c++
class LargeObject{
public:
    LargeObject(ObjectID id);
    const string& field1() const;
    int field2() const;
    double field3() const;
    //...
private:
    ObjectID oid;
    //外壳
    mutable string *field1Value;
    mutable int *field2Value;
    mutable double *field3Value;
    //...
};

LargeObject::LargeObject(ObjectID id)
    :oid(id)
    ,field1Value(0)
    ,field2Value(0)
    ,field3Value(0)
    //...
    {}
const string& LargeObject::field1() const{
    if(field1Value == 0){
        //从数据库中获取field1的数据，让field1Value指针指向field1
    }
    return *field1Value;
}
```
mutable关键字，用来让被const修饰的函数里面也可以修改他的成员。[**mutable关键字详解**](https://blog.csdn.net/starlee/article/details/1430387)
上述代码的方式是：先将对象中每一个字段都用一个指向数据的指针来表示，初始化的时候全部置为空。每个LargeObject成员函数在访问字段指针指向的数据之前必须检查字段指针的状态。如果为空，在对数据进行任何操作之前必须先从数据库中读取相应的数据。

#### 延迟表达式求值(Lazy Expression Evaluation)
```c++
template <class T>
class Matrix{
    //...
};
Matrix<int> m1(1000, 1000);
Matrix<int> m2(1000, 1000);
//...
Matrix<int> m3 = m1 + m2;
```
如果这里直接计算m3将会进行一万次加法运算，这个消耗是十分巨大的。如果我们使用延迟计算法，在m3的n内部建立一个数据结构指明m3的值是m1和m2的相加的结果，再加上一个枚举类型表明所进行的操作是加法运算。这里只要用到两个指针就可以了。
如果在后面的程序，下列代码被执行了。
```c++
Matrix<int> m4(1000, 1000);
//...
m3 = m4*m1;
```
这里我们只要进行替换，让m3记住是m4和m1的乘积。就省略了计算m1和m2相加这一步开销。
不单单如此，更常见的场景是，我们只要计算其中的一部分值。比如：
```c++
cout << m3[4];
```
这个时候，必须要进行计算了。但是只需要计算矩阵m3第四行的值，其他的值也不需要计算。
但是如果需要整个输出m3或者m3所依赖的矩阵被修改，就需要进行计算了
```c++
cout << m3;

m3 = m1 + m2;   //m3需要被计算出来，不然m1被修改了。
m1 = m4;
```
### 条款18：分期摊还预期的计算开销
### 条款19：了解临时对象的来源
#### 临时对象
```c++
template <class T>
void swap(T& object1, T& object2){
    T temp = object1;
    object1 = object2;
    object2 = temp;
}
```
我们通常把temp变量叫做临时变量。但是就c++本身来说，这个叫做局部对象。临时对象是不可见的。所谓 **临时对象指的是：这个对象被创建，而不是在堆上被创建的，并且还没有名字。**
#### 临时对象的产生
##### 为了函数调用能过通过产生的临时对象
**当传递给某个函数的对象的类型与这个函数所绑定的参数类型不一致的时候**会发生这种情况。下面代码用来计算字符串中某个字母出现的次数：
```c++
size_t countChar(const string& str, char ch);
char buffer[MAX_STRING_LEN];
char c;

cin >> c >> setw(MAX_STRING_LEN) >> buffer;
cout << "There are " << countChar(buffer, c) << " occurrences of the character " << c << "in" << buffer << endl;
```
这个代码有一个问题，countChar函数的第一个参数是const string&类型，但是调用的时候，传入的是char类型。这个时候，需要类型匹配才可以让函数正常运行。所以编译器会调用string类的构造函数，并用buffer创建一个临时string对象。但函数调用结束的时候，临时对象被销毁。
这里就会付出了没有必要的开销。**只有以传值方式传递对象或者把对象传递给声明为常量引用的参数，才会出现这样的类型转换。**
```c++
void uppercasify(string& str);
char subtleBookPlug[] = "C++";
uppercasify(subtleBookPlug);    //wrong
```
上面这个例子，并不会通过产生临时对象的转换来让函数成功执行。
解释一下两者的区别：当传入的参数和函数所期待的参数类型不一致的时候，就会产生了临时对象。如果加上了const，表示函数不会对形参进行任何的修改，那么产生临时对象来使函数成功执行并不会产生任何的问题。
如果没有const，表示我的形参有可能会被改变。但这个时候产生了临时对象，如果函数对形参做出了任何的修改，也不会修改到传入的形参，而是对临时变量进行了修改。这样就会产生一定的错误，编译器为了避免这种错误的产生，就限制了没有const的情况下，不会调用该函数成功运行。
##### 函数返回对象的时候产生临时对象
有一个叫做Number的类型，他的operator+声明如下：
```c++
const Number operator+(const Number& lhs, cosnt Number& rhs);
```
这个函数的返回只是一个临时对象，因为它没有名字：它只是函数的返回值。但是临时对象的构造函数和析构函数都是一个开销。这里，可以通过operator=来避免这种开销。但是大部分时候，我们没法通过转用其他函数的方式来避免这个开销。条款20会提到利用编译器的优化来减少返回值的开销。

### 条款20：协助编译器实现返回值优化
```c++
class Rational{
public:
    Rational(int numertor = 0, int denominator = 1);
    //...
}；
const Rational operator*(const Rational& lhs, const Rational& rhs);
```
由于operator*函数一定要返回一个对象，是两个有理数的乘积。这是不可避免的。
#### 通过返回指针和引用的方式减小临时对象产生的开销，不正确的做法不过程序员有些尝试，通过指针来返回
```c++
const Rational* operator*(const Rational& lhs, const Rational& rhs);

Rational a = 10;
Rational b(1, 2);
Rational c = *(a*b);
```
这样代码看起来就有点奇怪，而且，这个返回的指针需要删除函数返回给他的指针，否则就会造成资源泄露。
也有的人通过返回引用来实现：
```c++
const Rational& operator*(const Rational& lhs, const Rational& rhs);

Rational a = 10;
Rational b(1, 2);
Rational c = a*b;
```
这个在语法上是没有任何问题的。但是无论如何都是失败的。因为返回引用的对象是局部对象，当函数结束的时候，这个局部对象已经被销毁了，返回一个指向被销毁的对象的引用是大问题。
#### 返回带有参数的构造函数消除开销
有些函数就是需要返回对象的，我们没有办法消除对象本身。但是可以通过返回带有参数的构造函数代替直接返回对象让编译器消除临时对象的开销。
```c++
const Rational operator*(const Rational& lhs, const Rational& rhs){
    return Rational(lhs.numerator() * rhs.numerator(),
                    lhs.denominator() * rhs.denominator());
}
```
上面的表达式，**返回的时候调用了一个Rational类的构造函数，这个函数返回值是这个临时对象的一个拷贝。**这样似乎没有任何好处啊，此时仍然需要为函数内部创建的临时对象的构造和析构付出开销，还要为函数所返回的对象的构造和析构付出开销。但是这个时候，有一个叫做编译器优化的东西。
```c++
Rational a = 10;
Rational b(1, 2);
Rational c = a*b;
```
**此时c++允许编译器消除operator*函数内部的临时变量以及operator\*所返回的临时变量。**这样调用operator*所产生的临时对象带来的所有开销就是零。这个时候还有一个开销，就是用来创建c对象的构造函数的开销。不过**我们可以通过声明operator\*函数为内联函数取出调用构造函数带来的开销。**

### 条款21：通过函数重载避免隐式类型转换
先看代码：
```c++
class UPInt{
public:
    UPInt();
    UPInt(int value);
    //...
};
const UPInt operator+(const UPInt& lhs, const UPInt& rhs);
UPInt upi1, upi2;
//...
UPInt upi3 = upi1 + upi2;
```
上面的代码没有问题，但是执行下面的语句，会产生临时对象，增加开销。因为这些临时对象用来将整形10转换为UPInt类型。
```c++
upi3 = upi1 + 10;
upi3 = 10 + upi2;
```
可是我们可用通过重载的方式消除这些开销。
```c++
const UPInt operator+(const UPInt& lhs, const UPInt& rhs);
const UPInt operator+(const UPInt& lhs, int rhs);
const UPInt operator+(int lhs, const UPInt& rhs);
```
这样就可以直接调用函数，而不是生成临时对象进行隐式类型转换。
但是如下的重载是错误的：
```c++
const UPInt operator+(int lhs, int rhs);
```
这个是因为，**c++规定，每一个被重载的运算符，必须要有一个自定义类型的参数。**否则上面那样的修改，可能会将两个int相加的方式改变，这样会造成混乱。

### 条款22：考虑使用operator=来取代单独的operator运算符
如果我们有一个自定义类型，需要实现+运算，比如：x=x+y;那么x+=y;也要同样适用。实现operator+最好复用operator+=来实现。比如下列这样：
```c++
class Rational{
public:
    Rational& operator+=(const Rational& rhs);
    //...
};
const Rational operator+(const Rational& lhs,
                        const Rational& rhs){
    return Rational(lhs) += rhs;
}
```
这样的实现有一个好处就是复用了operator+=函数，提高了代码的可维护性。
而在效率方面，有两个方面的效率值得注意：
首先，单独形式的运算符总是要返回一个新的对象，需要付出构建和析构一个临时对象的开销。而赋值形式的运算符没有这个消耗。
其次，operator+的实现可以有下列两种方式：
```c++
template <class T>
const T operator+(const T& lhs, const T& rhs){
    return T(lhs) += rhs;
}

template <class T>
const T operator+(const T& lhs, const T& rhs){
    T result(lhs);
    return result += rhs;
}
```
两者的实现是等价的，但是不同的地方是：第二种的实现会产生临时对象，没有编译器优化。第一种实现方式是：表达式T(lhs)它用的是T的拷贝构造函数。它创建了一个和lhs等值的临时对象。然后这个临时对象和rhs一起被用于调用operator+=函数，这里有编译器的优化。

### 条款23：考虑使用其他等价的程序库
### 条款24：理解虚函数、多重继承、虚基类以及RTTI带来的开销
#### 关于虚基类
当虚基类被调用的时候，实际执行的代码取决于被调用对象的动态类型，而指向这个对象的指针或引用的类型是无关紧要的。大多数编译器的实现都是采用虚函数表(virtual table)和指向虚函数表的指针(virtual table pointer)，缩写分别为vtbls和vptrs。
一个vtbl通常就是一个函数指针的数组。函数中每个申明了或者继承了虚函数的类都有它自己的虚函数表