---
title: static const integral data member在类中的初始化
date: 2018-01-30 14:25:04
tags:
categories:
    - "knowledge"
    - "C/C++"
---
**当我们在类中定义了一个静态成员变量的时候，我们需要在类之外初始化它，因为他是属于所有的类的。**该类的其它对象对这个静态变量也是可以进行修改的。
```c++
//非常量静态成员变量初始化对比
#include <iostream>
using namespace std;

class person{
    public:
        static int num;
        //static int num = 11;
};
int person::num = 10;

int main(){
    person bob;
    system("clear");
    cout << bob.num << endl;
    return 0;
}
```
<!--more-->
在类内初始化非常量静态成员变量失败
![在类内初始化非常量静态成员变量](http://p3ax8ersb.bkt.clouddn.com/201801301358_611.png)
在类外初始化静态成员变量成功
![在类外初始化静态成员变量](http://p3ax8ersb.bkt.clouddn.com/201801301359_872.png)
```c++
//定义另外一个对象timmy
person timmy;
cout << "timmy:" << timmy.num<< endl;
```
同一个类的不同对象共用一个静态成员变量
![同一个类的不同对象共用一个静态成员变量](http://p3ax8ersb.bkt.clouddn.com/201801301406_632.png)

**但是，常量的静态成员变量可以在类里面定义。**
```c++
#include <iostream>
using namespace std;

class person{
    public:
        static const int num = 11;
        const static int age = 23;
};

int main(){
    system("clear");
    person tom;
    cout << "tom:" << tom.num << endl;
    cout << "tom:" << tom.age << endl;
    return 0;
}
```
static const和const static一样的。
![static const](http://p3ax8ersb.bkt.clouddn.com/201801301417_598.png)

**可是只有integral data member才可以，像 int，long，char才行。double，float等都不行**
```c++
#include <iostream>
using namespace std;

class person{
    public:
        static const double num = 2.2;
};
int main(){
    system("clear");
    person tom;
    cout << "tom:" << tom.num << endl;
    return 0;
}
```
用 static const double 初始化失败
![double失败](http://p3ax8ersb.bkt.clouddn.com/201801301421_850.png)
