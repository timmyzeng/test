---
title: 二维数组中的查找
date: 2018-04-08 19:26:29
tags:
categories:
    - "practice"
    - "剑指offer"
keywords:
    - "C++"
    - "vector"
    - "二维数组"
    - "剑指offer"
password:
---
## 题目：
在一个二维数组中，每一行都按照从左到右递增的顺序排序，每一列都按照从上到下递增的顺序排序。请完成一个函数，输入这样的一个二维数组和一个整数，判断数组中是否含有该整数。

### 解题思路：
第一行到最后一行是递增，第一列到最后一列是递增，那么肯定会有四个特殊的点。
![图示](http://p3ax8ersb.bkt.clouddn.com/201804081945_716.png-480.jpg)
<!--more-->
分别是最小的，最大的，行最大列最小，列最大行最小。如果要入手解题从这四个点入手。
1、最小的，如图中1。寻找的时候，如果target比1大，那么该往何处走？不清楚。所以最小点不适合，同理最大点。
2、行最大列最小，如图左下角4。如果target比4大，那么向当前列右走。如果target跟他比4小，那么向当前行上走。同理列最大行最小。

### 代码：
```c++
class Solution {
public:
    bool Find(int target, vector<vector<int> > array) {
        int size = array.size();
        if(size != 0){
            int row = size - 1;
            int col = 0;
            while(row >= 0 && col < array[0].size()){
                if(array[row][col] == target){
                    return true;
                }
                else if(array[row][col] < target){
                    ++ col;
                }
                else {
                    -- row;
                }
            }
        }
        return false;
    }
};
```

## vector构成的二维数组
### 创建二维数组赋值
可以使用vector函数resize()和函数assign()对数组大小进行修改。
1、利用构造函数直接创建。
```c++
//利用构造函数直接创建arr[2][3]
vector<vector<int> >arr(2, vector<int>(3));
for(int i = 0; i < arr.size(); ++i){
    for(int j = 0; j < arr[0].size(); ++j){
        arr[i][j] = i+j;
    }
}
```
2、利用函数resize()或函数assign()
```c++
//利用创建的arr1[3][3]改变为arr1[3][4]
vector<vector<int> >arr1(3, vector<int>(3));
for(int i = 0; i < arr1.size(); ++i){
    arr1[i].resize(4);
}

for(int i = 0; i < arr1.size(); ++i){
    for(int j = 0; j < arr[0].size(); ++j){
        arr1[i][j] = i+j;
    }
}
```
### 遍历二维数组
1、获取下标，利用operator\[\]函数
```c++
for(int i = 0; i < arr.size(); ++i){
    for(int j = 0; j < arr[i].size(); ++j){
        cout << arr[i][j] << " ";
    }
    cout << endl;
}
```
2、利用迭代器。利用迭代器的时候，有点难理解。it1是二维vector迭代器，it2是一维vector迭代器。\*it1得到的是一个一维vector。\*it2得到的是int类型。

```c++
vector<vector<int> >::iterator it1;
vector<int>::iterator it2;

for(it1 = arr1.begin(); it1 != arr1.end(); ++it1){
    for(it2 = (*it1).begin(); it2 != (*it1).end(); ++it2){
        cout << *it2 << " ";
    cout << endl;
    }
}
```
### 输出图示：
![输出](http://p3ax8ersb.bkt.clouddn.com/201804092001_758.png-480.jpg)
