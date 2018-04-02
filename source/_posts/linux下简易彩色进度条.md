---
title: linux下简易彩色进度条
date: 2018-03-19 19:03:14
tags:
categories:
    - "Linux"
    - "practice"
keywords:
    - "Linux"
    - "进度条"
    - "颜色设置"
password:
---
### 前言
在Linux下安装文件的时候，都会有个进度条来提示我们安装的进度是多少。这里我们模拟输出这个进度条。主要用到输出函数的操作、缓冲区的刷新、usleep函数、linux终端颜色的显示等知识。
效果如下：
![进度条](http://p3ax8ersb.bkt.clouddn.com/201803191947_365.gif-1920.jpg)
![彩色进度条](http://p3ax8ersb.bkt.clouddn.com/201803191947_20.gif-1920.jpg)
<!--more-->
### 铺垫知识点
**缓冲区**
缓冲区分位三种：无缓冲，行缓冲，全缓冲。
**无缓冲**：没有缓冲，也就是信息在输入输出的时候，立马输入或输出。典型的代表就是标准错误流stderr。
**行缓冲**：当输入输出的时候，遇到换行才执行I/O操作。典型的代表是键盘的操作。
**全缓冲**：当输入输出写满缓冲区才执行I/O操作。典型的代表是磁盘的读写。
由于输出函数是行缓冲类型的。所以我们需要使用缓冲区刷新函数fflush来输出。否则我们看到的进度条将是一段一段输出的。
![错误进度条](http://p3ax8ersb.bkt.clouddn.com/201803191959_49.gif-1920.jpg)
补充：printf函数是一个行缓冲函数，先写到缓冲区，满足条件就将缓冲区刷到对应文件中。满足下列条件之一，缓冲区都会刷新：
（1）缓冲区填满
（2）写入的字符中有`'\n''\r'`
（3）调用fflush刷新缓冲区
（4）调用scanf从缓冲区获取数据时，也会刷新新缓冲区。

**换行符**
有两个符号需要区分：`'\n''\r'`。他们有不同的含义。**`'\n'`表示的是换行，将光标指向下一行的开头位置。'\`r'`指的是回车，将光标回到当前行的开头位置。**在这里我们要使用`'\r'`，否则我们的进度条将输出一个`'#'`就换一行。

**usleep函数**
刷新了缓冲区之后，如果并没有加上睡眠函数，结果将一次性输出来。进度条应该是随着加载不停出现才对。
这里统一总结一下Linux睡眠函数：
头文件：`#include <unistd.h>`
以 **秒**为单位：unsigned int sleep( unsigned int seconds );
以 **微秒**为单位：int usleep ( useconds_t usec );
以 **四分之一毫秒**为单位：extern void delay( unsigned int msec );

以睡眠一秒为例:
sleep(1); usleep(1000 000); delay(250);

**输出颜色的设置**
printf函数可以通过输出特定的转义序列来实现输出字符的颜色和状态。
转义序列以控制字符'ESC'开头。该字符的ASCII码十进制表示为27，十六进制表示为0x1B，八进制表示为033。多数转义序列超过两个字符，故通常以'ESC'和左括号'['开头。该起始序列称为控制序列引导符(CSI，Control Sequence Intro)，通常由'\033['或'\e['代替。
**一般格式如下：(显示方式指的是样式，前景色是30+颜色值，背景色是40+颜色值，字符m表示结束)**
> \033[显示方式；前景色；背景色m + 输出字符串
> 或者
> \e[显示方式；前景色；背景色m + 输出字符串

常见参数如下：
显示方式：0(默认)、1(粗体/高亮)、22(非粗体)、4(单条下划线)、24(无下划线)、5(闪烁)、25(无闪烁)、7(反显、翻转前景色和背景色)、27(无反显)
颜色：0(黑)、1(红)、2(绿)、 3(黄)、4(蓝)、5(洋红)、6(青)、7(白)
见例子：
```c
printf("\033[31mHello!\n\033[0m");
printf("\033[4;32mHello!\n\033[0m");
printf("\033[1;34;43mHello!\n\033[0m");
```
![color](http://p3ax8ersb.bkt.clouddn.com/201803192037_682.png-480.jpg)
其中：**\033[0m用于恢复默认的终端输出属性，否则会影响后续的输出。**
[**颜色设置详细解析传送门**](http://www.cnblogs.com/clover-toeic/p/4031618.html)

### 代码如下
```c
#include <unistd.h>
#include <string.h>
#include <stdio.h>

int main(){
    int i = 0;
    int j = 0;
    char bar[102];
    //color数组用来改变颜色的值，让进度条在七种颜色中变幻
    int color[] = {1, 2, 3, 4, 5, 6, 7};
    //设置状态，显示此时正在加载
    const char *status = "|/-\\";
    memset(bar, 0, siezof(bar));
    while(i <= 100){
        //无颜色版本
        //printf("[%-100s][%d%%][%c]\r", bar, i, status[i%4]);
        printf("\033[3%dm[%-100s]\033[0m\033[33m[%d%%]\033[0m[%c]\r", color[j], bar, i, lable[i%4]);
        fflush(stdout);
        bar[i ++] = '#';
        //每加载15%，就变换一次颜色
        if(i%15 == 0){
            ++ j;
        }
        //休眠0.03秒输出字符
        usleep(30000);
    }
    printf("\n");
    return 0;
}
```
![代码分析](http://p3ax8ersb.bkt.clouddn.com/201803192104_382.png-1920.jpg)
[参考一](http://blog.csdn.net/sssssuuuuu666/article/details/78599860)
[参考二](http://blog.csdn.net/ArchyLi/article/details/78680231)