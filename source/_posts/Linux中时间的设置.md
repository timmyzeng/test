---
title: Linux中时间的设置
date: 2018-03-08 11:36:45
tags:
categories:
    - "Linux"
    - "method"
keywords:
    - "Linux"
    - "date"
password:
---
test: CentOS Linux release 7.4.1708 (Core)
#### 查看时区
> **data -R**

![查看时区](http://p3ax8ersb.bkt.clouddn.com/201803081634_167.png-960.jpg)
+0800 表示在东八区
其中：
CST：中国标准时间（China Standard Time），这个解释可能是针对RedHat Linux。
UTC：协调世界时，又称世界标准时间，简称UTC，从英文国际时间/法文协调时间”Universal Time/Temps Cordonné”而来。中国大陆、香港、澳门、台湾、蒙古国、新加坡、马来西亚、菲律宾、澳洲西部的时间与UTC的时差均为+8，也就是UTC+8。UTC较于GMT更准确。
GMT：格林尼治标准时间（旧译格林威治平均时间或格林威治标准时间；英语：Greenwich Mean Time，GMT）是指位于英国伦敦郊区的皇家格林尼治天文台的标准时间，因为本初子午线被定义在通过那里的经线。
#### 修改时区
> **tzselect**

<!--more-->
![tzselect1](http://p3ax8ersb.bkt.clouddn.com/201803081645_514.png-960.jpg)
**这个命令并不是用来修改时区的**，这个命令可以通过你自己的选择然后清楚的知道每个时区的样式。然后你通过修改.progile、.bash_profile或者/etc/profile文件，设置正确的TZ环境变量并导出，可以成功改变时区。
![tzselect2](http://p3ax8ersb.bkt.clouddn.com/201803081647_798.png-960.jpg)

**tip：这些修改应该出现用户家目录下**
下面例子，我将时区由东八区改变为波兰的时区，东一区：
先通过tzselect查询波兰的时区书写格式：
![tzselect3](http://p3ax8ersb.bkt.clouddn.com/201803081702_845.png-960.jpg)
然后通过修改文件.bash_profile并应用得以修改。
![tzselect4](http://p3ax8ersb.bkt.clouddn.com/201803081701_60.png-960.jpg)
> **通过替换系统时区文件，或者创建链接文件**

1、在目录/usr/share/zoneinfo中有所有的时区文件，通过复制替换到/etc/locatime即可
![替换](http://p3ax8ersb.bkt.clouddn.com/201803081715_394.png-960.jpg)
但是有的时候会出现没有效果的情况，比如上例子。这是因为修改了在profile或.bash_profile中设置了TZ。这个时候就需要重新修改TZ。

2、创建链接文件
这里如果出现修改失败，同上。
![ln](http://p3ax8ersb.bkt.clouddn.com/201803081722_543.png-960.jpg)

#### 查看和修改时间和日期
> **date**
> date用于查看和设置 **系统时间**

![date](http://p3ax8ersb.bkt.clouddn.com/201803081733_375.png-960.jpg)
如果不输入命令"hwclock -w"将时间写入硬件时间，电脑重启之后将会返回原样。
> **hwclock**
> hwclock用来查看设置 **硬件时间**。

> **hwclock --hctosys**
> hc代表硬件时间，sys代表系统时间，即用硬件时钟同步系统时钟

> **hwclock --systohc**
> 即用系统时钟同步硬件时钟,等于 **hwclock -w**

执行完这两个命令系统没有任何反馈。
![hwclock](http://p3ax8ersb.bkt.clouddn.com/201803081739_539.png-960.jpg)

解释一下硬件时钟和系统时钟的区别：
硬件时钟指的是主板上由电池供电的那个时间，可以在BIOS中设置。**Linux可以通过hwclock设置。当Linux启动的时候，硬件时钟会赋值给系统时钟。然后系统时钟会独立于硬件时钟工作。**
系统时钟指的是当前Linux Kernel中的时钟。Linux中的所有命令包括函数都是采用系统时钟设置的。
这就是为什么当我们用date修改了时间，没有同步到硬件时钟的时候，这个修改是无效的。

#### 时间自动同步
> **yum install -y ntpdate**
首先安装ntpdate软件，用来同步Linux时间服务。

> **ntpdate time.nist.gov**

![ntpdate](http://p3ax8ersb.bkt.clouddn.com/201803081941_193.png-960.jpg)
上面表示同步成功，调整时间为服务器129.6.15.29的时间，时间相差0.136318 sec

> **hwclock -w**
调整硬件时间

> **crontab -e**
设定crontab计划任务自动校时，并添加下列内容
**0 1 * * * ntpdate time.nist.gov**
这样设定一个小时自动进行网络校时。

通过cat /etc/crontab 查看crontab的设置解释，如下：
![crontab](http://p3ax8ersb.bkt.clouddn.com/201803082006_609.png-1920.jpg)
[参考文章1](https://www.cnblogs.com/kerrycode/p/4217995.html)
[参考文章2](https://www.cnblogs.com/wanghuaijun/p/6547046.html)