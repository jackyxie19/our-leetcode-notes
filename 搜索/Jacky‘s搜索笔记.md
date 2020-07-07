# Jacky‘s搜索笔记

### [1091. 二进制矩阵中的最短路径](https://leetcode-cn.com/problems/shortest-path-in-binary-matrix/)

#### 第一眼思路

一个顶点可以向相连的八个方向走一步，但不能走阻塞节点，且已走过节点也不能走。可维护一个已经过路径标志矩阵，至于是否将已经过节点与阻塞节点相同标记、共同存储有待考虑。所有的行走路径可以化成一棵树，因为不仅过重复节点，最后路径是一颗单边树。



#### 题解

从`(0,0)`点开始按照层次遍历构建路径树。设起点层级为1，终点`(len-1,len-1)`层级为最终距离。





### [695. 岛屿的最大面积](https://leetcode-cn.com/problems/max-area-of-island/)

设置`visited`数组，耗时`4ms`。

取代`visited`数组，每次访问节点后将`grid`数组中`1`置`0`，减少了对`visited`数组的判断操作，因无论如何都需要对`grid[row][col]`元素判`1`。耗时`3ms`。

用`count+=recurse()`替代`count=left+right+up+down+1`，耗时`2ms`。