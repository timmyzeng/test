---
title: BST二叉搜索树
date: 2018-03-29 20:04:18
tags:
categories:
    - "knowledge"
    - "C/C++"
keywords:
    - "C++"
    - "Binary Search Tree"
    - "查找"
    - "删除"
    - "插入"
password:
---
## 性质
二叉搜索树是一个优化的二叉树，也称作二叉排序树、二叉查找树、BST等。一般在每个节点定义一个关键值Key。插入的时候按照一定的规则使之有序插入，方便搜索。它可以是一颗空树，或者这棵树有着以下的性质：
1、如果左子树不为空，那么左子树上的所有节点的值都小于根节点的值
2、如果右子树不为空，那么右子树上的所有节点的值都大于根节点的值
3、同时，左右子树也是二叉搜索树
4、这棵二叉树没有相同关键值的节点，也就是每一个节点的值多不相同
如果插入序列是：6,3,8,7,1,2,4,0,5,9,4
图示如下：
![BSTree](http://p3ax8ersb.bkt.clouddn.com/201803292024_340.png-960.jpg)
<!--more-->
## 节点
二叉树用二叉链的形式实现。每个节点有一个关键值\_key，指向左子树的指针\_left，指向右子树的指针\_right。
```c++
template <class K>
struct BStreeNode{
    K _key;
    BStreeNode<K>* _left;
    BStreeNode<K>* _right;

    BStreeNode(const K& key)
        :_key(key)
        ,_left(NULL)
        ,_right(NULL)
    {}
};
```

## 插入
### 思路
分为三个步骤，**查找插入位置，利用key创建节点，跟二叉树连接起来**
1、插入函数接收一个关键值key，用这个key跟当前指针指向的节点(cur)的关键值(cur->_key)比较。
2、如果key大，cur向右子树走；如果key小，cur向左子树走；如果相等，那么就不需要插入。这里利用一个循环就可以实现。一直到cur指向空节点，那么这个地方就是需要插入的位置。
4、但是为了将新增节点和二叉树连接起来，还需要一个指针指向上一个节点(parent)，此时要分清楚链入parent节点的左子树上还是右子树上。
### 图示
插入key为4的节点
![1](http://p3ax8ersb.bkt.clouddn.com/201803292052_880.png-960.jpg)
![2](http://p3ax8ersb.bkt.clouddn.com/201803292101_332.png-960.jpg)
![3](http://p3ax8ersb.bkt.clouddn.com/201803292102_172.png-960.jpg)
### 代码实现
代码分为递归写法和非递归写法
```c++
//非递归
bool Insert(const K& key){
    //特殊处理插入空树的情况
    if(_root == NULL){
        _root = new Node(key);
        return true;
    }
    Node* cur = _root;
    Node* parent = NULL;
    //查找插入位置
    while(cur){
        if(cur->_key < key){
            parent = cur;
            cur = cur->_right;
        }
        else if(cur->_key > key){
            parent = cur;
            cur = cur->_left;
        }
        //已经有相同关键值的节点，不插入
        else{
            return false;
        }
    }
    cur = new Node(key);
    //插入到parent的右子树上
    if(parent->_key < key){
        parent->_right = cur;
    }
    else{
        parent->_left = cur;
    }
    return true;
}

//递归写法
bool InsertR(const K& key){
    return _InsertR(_root, key);
}
//root使用的是引用，解决了连接的问题
bool _InsertR(Node*& root, const K& key){
    if(root == NULL){
        root = new Node(key);
    }
    else if(root->_key < key){
        _InsertR(root->_right, key);
    }
    else if(root->_key > key){
        _InsertR(root->_left, key);
    }
    else
        return false;
    return true;
}
```
**这里解释两个地方：1、递归为什么要调用一个内置函数，不直接递归。2、递归写法为什么不需要链接的过程。**
1、由于递归函数需要多次调用本身，考虑如果不调用内置函数，为了实现递归左右子树，需要传入参数如下：
```c++
bool InsertR(Node* root, const K& key){}
```
但是很尴尬的是，我们没有办法将根节点\_root的左子树或者右子树进行调用。因为\_root是私有的，我们在类的外面是没有办法直接调用的。
2、递归写法不是不需要链接的过程，而是连接的过程在使用了引用root这个语法之后，隐式的完成了。一个例子：我们现在有一个关键值为6的节点，我们要插入关键值为3的节点。根据代码，代码会走到`_InsertR(root->_left, key);`这里。
![InsertR](http://p3ax8ersb.bkt.clouddn.com/201803292125_442.png-960.jpg)
此时的root有两层含义：**第一层，root是当前节点的位置，指向了NULL；第二层，root是上一层函数root->\_left指向的位置。之所以会有这样的联系，是因为root参数是引用的原因，当前的root是上一层函数的root->\_left的别名。**这样我们就不需要考虑连接的问题了，只要将新增节点直接交给当前函数的root就已经和二叉树连接在一起了。

## 查找
查找的思路十分简单，可以认为是插入的弱化版本。找到返回当前节点的指针，未找到返回空指针。
### 代码实现
查找函数也有非递归和递归两个版本。
```c++
//Find
Node* Find(const K& key){
    if(_root){
        Node* cur = _root;
        while(cur){
            if(cur->_key < key){
                cur = cur->_right;
            }
            else if(cur->_key > key){
                cur = cur->_left;
            }
            else{
                return cur;
            }
        }
    }
    return NULL;
}
//FindR
Node* FindR(const K& key){
    return _FindR(_root, key);
}
Node* _FindR(Node* root, const K& key){
    if(root == NULL)
        return NULL;
    else if(root->_key < key){
        _FindR(root->_right, key);
    }
    else if(root->_key > key){
        _FindR(root->_left, key);
    }
    else{
        return root;
    }
}
```
## 删除
### 删除思路
删除较为复杂，分析如下：
1、当前树是否为空
2、寻找需要删除节点的位置
3、如果删除的节点是叶子节点或者有一个子树为空的情况，可以归为第一类
4、如果删除的节点两个子树都存在，归为第二类
使用示例：
![delete](http://p3ax8ersb.bkt.clouddn.com/201804012101_948.png-960.jpg)
### 第一类，叶子节点或者有一个子树为空
为什么将叶子节点归为这一类，是因为可以将叶子节点看做是左子树为空或者右子树为空的情况。
#### 左子树为空
![left](http://p3ax8ersb.bkt.clouddn.com/201804012105_224.png-960.jpg)
左子树为空分为两种情况，第一种上图中红色cur一样，是parent的左子树，需要用parent的左去链接cur的右子树；第二种是上图中橙色cur，是parent的右子树，需要用parent的右去链接cur的右子树。
#### 右子树为空
![right](http://p3ax8ersb.bkt.clouddn.com/201804012108_886.png-960.jpg)
同理，右子树为空也分为两种情况，上图中红色cur和橙色cur。
#### 注意
需要特殊处理parent是NULL的情况。当左右子树为空的时候，还有一种特殊的情况需要处理，如果符合要求的节点是根节点，我们需要特殊处理。如下图：
![left&&right](http://p3ax8ersb.bkt.clouddn.com/201804012112_557.png-960.jpg)
### 第二类，两个子树都存在
这个类型的节点，需要使用到处理堆的一个操作。如果有一个大堆，需要获取第二大的节点的时候。需要将最大的节点出堆，然后获取堆顶数据。但是出堆之后，如果需要堆还是符合大堆的性质。就需要特殊处理。处理方法是替换：将堆顶的最大元素和最小元素交换，然后再删除最后一个节点，最后使用向下调整就可以了。**这里也是这样处理，当我们找到了需要删除的节点，我们就去找右子树中最小的节点，然后替换，替换之后再删除。**如图所示：
![root](http://p3ax8ersb.bkt.clouddn.com/201804012134_928.png-960.jpg)
如果需要删除节点cur，这个时候找到右子树中最小的节点pos，将节点pos的值赋给节点cur，让parent->\_left==NULL。再删除cur节点，就实现了删除了。
![small](http://p3ax8ersb.bkt.clouddn.com/201804012130_805.png-960.jpg)
但是为什么是节点pos呢？这是因为删除了两个子树都在的节点。还需要保持BST的特性：左右子树还是BST。**这时，右子树的最左节点肯定是右子树中最小的，或者说是排序下，跟当前删除节点相邻的节点。用它来改变删除节点最合适了，而且不需要对树的结构有大的修改。**
**注意**：这里有一个特殊的点，比如删除下图中的根节点。**特殊的地方是，没有办法找到子树中的最左节点，因为根本没有**，所以就需要在使用上述交换的方法的时候，特殊处理一次，判断parent的指向的时候，到底是直接让parent->\_left==NULL还是parent->\_right==pos->\_right。通过删除节点pos的右是否存在判定。
![特殊](http://p3ax8ersb.bkt.clouddn.com/201804012132_344.png-960.jpg)
### 代码实现
递归和非递归两种情况
```c++
//Remove
bool Remove(const K& key){
    if(_root){
        Node* cur = _root;
        Node* parent = NULL;
        while(cur){
            //寻找节点
            if(cur->_key < key){
                parent = cur;
                cur = cur->_right;
            }
            else if(cur->_key > key){
                parent = cur;
                cur = cur->_left;
            }
            //找到节点开始删除
            else{
                Node* del = cur;
                //删除节点的左子树为空
                if(cur->_left == NULL){
                    //特殊处理parent为NULL的情况
                    if(parent == NULL){
                        _root = cur->_right;
                    }
                    else{
                        //分cur是parent的左还是右子树
                        if(parent->_left == cur){
                            parent->_left = cur->_right;
                        }
                        else{
                            parent->_right = cur->_right;
                        }
                    }
                }
                //删除节点的右子树为空
                else if(cur->_right == NULL){
                    if(parent == NULL){
                        _root = cur->_left;
                    }
                    else{
                        if(parent->_left == cur){
                            parent->_left = cur->_left;
                        }
                        else{
                            parent->_right = cur->_left;
                        }
                    }
                }
                //删除节点的两个子树都在
                else{
                    parent = cur;
                    Node* pos = cur->_right;
                    //寻找右子树最左节点
                    while(pos->_left){
                        parent = pos;
                        pos = pos->_left;
                    }
                    //赋值给cur
                    cur->_key = pos->_key;
                    del = pos;
                    //特殊处理pos是不是找到的右子树中的最左节点
                    if(pos->_right){
                        parent->_right = pos->_right;
                    }
                    else{
                        parent->_left = NULL;
                    }
                }
                //三种情况统一删除
                delete del;
                return true;
            }
        }
    }
    //没找到，返回错误
    return false;
}

//RemoveR
bool RemoveR(const K& key){
    return _RemoveR(_root, key);
}
bool _RemoveR(Node*& root, const K& key){
    if(root){
        Node* cur = root;
        if(cur->_key < key){
            _RemoveR(root->_right, key);
        }
        else if(cur->_key > key){
            _RemoveR(root->_left, key);
        }
        else{
            Node* del = root;
            if(root->_left == NULL){
                root = root->_right;
            }
            else if(root->_right == NULL){
                root = root->_left;
            }
            else{
                Node* pos = root->_right;
                while(pos->_left){
                    pos = pos->_left;
                }
                root->_key = pos->_key;
                return _RemoveR(root->_right, pos->_key);
            }
            delete del;
            return true;
        }
    }
    return false;
}
```
说明一下递归调用的思想，对于树来说，递归的调用就相当于子问题的调用，每次都将左右节点当做是下次的根节点，然后通过相同的处理方式，一直到遇到返回条件。在递归删除中，也利用了引用的关键作用。
```c++
if(root->_left == NULL){
    root = root->_right;
}
else if(root->_right == NULL){
    root = root->_left;
}
```
这一段中，因为引用的原因，当前的root除了是指向当前节点的指针，还是上一级root指针的\_left或者\_right。这样也就不需要考虑连接的问题。在递归中处理删除节点的左右子树都在的情况，还是寻找到右子树中key最小的节点，然后赋值给需要删除的节点，在通过调用函数来删除这个节点，这样就可以直接利用删除左节点为空或者右节点为空的情况来处理。

## 中序遍历
二叉搜索树又叫做排序树，这个是因为他是排好序的。同时如果使用中序遍历的话，就可以得到这个排好序的序列。

### 代码实现
利用中序的遍历，也有递归和非递归两种形式。非递归的形式，是借用了栈来模拟回退的功能。
```c++
//InOrder
void InOrder(){
    Node* root = _root;
    if(_root){
        Node* cur = root;
        stack< Node* > s;
        while(cur || !s.empty()){
            while(cur){
                s.push(cur);
                cur = cur->_left;
            }
            cur = s.top();
            cout << cur->_key << " ";
            s.pop();
            cur = cur->_right;
        }
        cout << endl;
    }
}

//InOrderR
void InOrderR(){
    _InOrderR(_root);
    cout << endl;
}
void _InOrderR(Node* root){
    if(root){
        _InOrderR(root->_left);
        cout << root->_key << " ";
        _InOrderR(root->_right);
    }
    return;
}
```
