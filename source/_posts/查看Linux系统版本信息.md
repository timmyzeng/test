---
title: 查看Linux系统版本信息
date: 2018-03-08 11:44:55
tags:
categories:
    - "Linux"
    - "method"
keywords:
    - "Linux"
    - "version"
password:
---
#### 查看内核版本
> **cat /proc/version**

![cat /proc/version](http://p3ax8ersb.bkt.clouddn.com/201803081150_955.png-960.jpg)
> **uname -a**

<!--more-->
![uname -a](http://p3ax8ersb.bkt.clouddn.com/201803081151_552.png-960.jpg)
#### 查看系统版本
> **cat /etc/redhat-release**

![查看版本](http://p3ax8ersb.bkt.clouddn.com/201803081158_576.png-960.jpg)
> **lsb_release -a**

这个命令需要安装，安装命令：
> yum install lsb -y

![lsb_release](http://p3ax8ersb.bkt.clouddn.com/201803081233_128.png-960.jpg)
> **cat /etc/issue**

都说可以，这个我的查出来很奇怪
![有错误](http://p3ax8ersb.bkt.clouddn.com/201803081223_694.png-960.jpg)
> **rpm -q centos-release**

![rpm](http://p3ax8ersb.bkt.clouddn.com/201803081235_126.png-960.jpg)

#### 查看cpu相关信息，包括型号、主频、内核等信息
> **cat /proc/cpuinfo**

![cpuinfo](http://p3ax8ersb.bkt.clouddn.com/201803081226_578.png-960.jpg)

[参考地址1](https://www.linuxidc.com/Linux/2016-05/131749.htm)
[参考地址2](http://blog.csdn.net/Aoril/article/details/53518917)