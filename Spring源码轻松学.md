# Spring源码轻松学

## 课程目的:

- 了解自研框架的总体架构设计
- 了解Spring的总体架构及学习路径

## Spring简史:

- 2000年Rod Johson在 J2EE Development withous EJB中提出Spring 核心思想: 如何让应用程序超出当时大众所惯于接收的易用性和稳定性与j2ee平台上的不同组件合作.
- Spring配档了详尽的文档
- Spring可快速方便地集成项目用到的技术

## Spring 设计初衷

用于构造JAVA应用程序的轻量级框架:

- 可以采用Spring来构造任何程序, 而不局限于Web程序
- 轻量级: 最少的侵入, 与应用程序低耦合, 接入成本低
- 最直观感受: 基于POJO, 构建出稳健而强大的应用

## Spring野心

为各大技术领域提供支持:

- 微服务
- 移动开发
- 社交API集成
- 安全管理
- 云计算
- ...

![image-20210217165655569](Spring%E6%BA%90%E7%A0%81%E8%BD%BB%E6%9D%BE%E5%AD%A6.assets/image-20210217165655569.png)



Spring架构

![image-20210217170845052](Spring%E6%BA%90%E7%A0%81%E8%BD%BB%E6%9D%BE%E5%AD%A6.assets/image-20210217170845052.png)

## Spring基础核心模块预览

### spring-core

- 包含了框架基本的核心工具类,其他组件都要使用到这个包里的类. 为IoC&AoP提供最基础的能力
- 定义并提供资源的访问方式

### spring-beans

Spring主要面向Bean编程(BOP)

主要功能:

- Bean的定义:
- Bean的解析:
- Bean的创建:

最重要接口: BeanFactory

### spring-context

为spring提供运行时环境, 保存对象的状态. context要检查并维护bean之间的关系

扩展了BeanFactory

ApplicationContext是该模块核心接口

### spring-aop

最小化的动态代理实现

两种实现代理模式: 只能使用运行时织入, 仅支持方法级编织, 仅支持方法执行切入点

- JDK动态代理
- Cglib

### other

spring-aspectj + spring-instrument : Full AspectJ

- 编译期Weaving
- 类加载器Weaving
- 运行期Weaving

| Spring AOP                                       | AspectJ                                                      |
| ------------------------------------------------ | ------------------------------------------------------------ |
| 纯JAVA中实现                                     | 使用Java语言的扩展实现                                       |
| 不需要单独的编译过程                             | 除非设置LTW, 否则需要AspectJ编译器(ajc)                      |
| 只能使用运行时织入                               | 运行时织入不可用. 支持编译时, 编译后和加载时织入             |
| 功能不强-仅支持方法级编织                        | 更强大-可以编织字段, 方法, 构造函数, 静态初始值设定项, 最终类/方法等 |
| 只能在由Spring容器管理的bean上实现               | 可以在所有域对象上实现                                       |
| 仅支持方法执行切入点                             | 支持所有切入点                                               |
| 代理是由目标对象创建的, 并且切面应用在这些代理商 | 在执行应用程序之前(运行前), 各方面直接在代码中进行织入       |
| 比AspectJ慢许多                                  | 更好的性能                                                   |
| 易学易用                                         | 比Spring AOP更复杂                                           |

# 自研框架

为了更好地了解Spring框架. 会有所取舍, 不一定严格与Spring线路同步. 

![image-20210218164412049](Spring%E6%BA%90%E7%A0%81%E8%BD%BB%E6%9D%BE%E5%AD%A6.assets/image-20210218164412049.png)

<center>自研框架架构图</center>

jsp运行原理:

![image-20210218171847277](Spring%E6%BA%90%E7%A0%81%E8%BD%BB%E6%9D%BE%E5%AD%A6.assets/image-20210218171847277.png)

## 前奏

### 反射

循序程序在运行时来进行自我检查并且对内部的成员进行操作

反射主要是指程序可以访问,检测和修改它本身状态或行为的一种能力. 并且根据自身行为的状态和结果, 调整或修改应用所描述行为的状态和相关的语义.

反射机制的作用:

- 在运行时判断任意一个对象所属的类
- 在运行时获取类的对象
- 在运行时访问java对象的属性,方法,构造方法等

反射可以使代码在运行时灵活装配

java.lang.reflect类库中主要的类:

- Fiel:表示类中的成员变量
- Method: 表示类中的方法
- Constructor:表示类的构造方法
- Array:该类提供了动态创建数组和访问数组元素的静态方法

反射依赖的Class: 用来表示运行时类型信息的对应类

- 每个类都有唯一一个对应的Class对象
- Class类可称为类类型,而Class对象为类类型对象

Class类特点

- Class也是类的一种, class是关键字
- Class类只有一个私有的构造函数,只有JVM可以创建Class类的实例
- JVM中只有唯一一个和类相对应的Class对象来描述其类型信息

获取Class对象的三种方式:

- Object-->getClass()
- 任何数据类型都有一个静态的class属性: 如Integer.class
- 通过Class类的静态方法forName()获取.(最常用)

运行期间,一个类只有一个与之对应的Class对象产生.



反射的主要用法:

- 如何获取类的构造方法并使用
- 如何获取类的成员变量并使用
- 如何获取类的成员方法并使用



### 注解

反射获取源:

- 通过XML来保存类相关的信息以供反射调用
- 用注解来保存类相关信息以供反射调用



注解定义: 为程序提供一种设置元数据的方法

- 元数据是添加到程序元素(方法,字段,类,包)上的额外信息
- 注解是一种分散式 的元数据设置方式(与源代码绑定),XML是集中式的设置方式(不与源代码绑定)
- 注解不能直接干扰程序代码的运行



注解功能: 注解可以说是特殊功能的注释

- 作为特定的标记, 用于告诉编译器一些信息
- 编译时动态处理, 如动态生成代码
- 运行时动态处理, 作为额外信息的载体, 如获取注解信息



注解分类:

- 标准注解: Override, Deprecated, SuppressWarnings
- 元注解: @Retention, @Target, @Inherited, @Documentated. 元注解用于定义其他注解
- 自定义注解: 



元注解:

- 用于修饰注解的注解, 通常用于定义注解. 指定注解生命周期及作用目标等信息
- @Target: 指定注解的作用目标
- @Retention: 指定注解的生命周期
- @Documented: 注解是否应当被包含在JavaDoc文档中, 默认情况下JavaDoc不包含注解
- @Inherited: 是否允许子类继承该注解



@Target: 描述所修饰注解的使用范围:

- packages, types(类, 接口, 枚举, Annotation类型)

- 类型成员(方法, 构造方法, 成员变量, 枚举值)

- 方法参数和本地变量(如循环变量, catch参数)

  > Target源码中有一个ElementType[], 枚举数组. 该数组中每个元素标志该注解作用的范围(方法,类,变量...)



@Retention:

- 源码中枚举值RetentionPolicy标志注解作用范围
  - SOURCE: 源文件中保留,class中不保留
  - CLASS: 注解保留在源代码及对应的CLASS中
  - RUNTIME: 可在运行时获取该注解信息. Spring的@Autowired标签生命周期为RUNTIME



自定义注解自动实现了java.lang.annotation.Annotation接口



注解支持的类型:

- 所有基本的数据类型
- String类型
- Class类型
- Enum类型
- Annotation类型
- 以上所有类型的数组

