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



注解获取属性的底层实现

- JVM会为注解生成代理对象. JAVA中万物皆对象
- 修改vm options, 在idea运行时显示中间对象.  `-Djdk.proxy.ProxyGenerator.saveGeneratedFiles=true`
- 在vm options中添加`-XX:+TraceClassLoading`打印类加载信息



注解的工作原理

- 通过键值对的形式为注解属性赋值
- 编译器检查注解的使用范围, 将注解信息写入元素属性表
- 运行时JVM将RUNTIME的所有注解属性取出并存入map里(单个RUNTIME注解)
- 创建AnnotationInvocationHandler实例并传入前面的map
- JVM使用JDK动态代理为注解生成代理类, 并初始化处理器
- 调用invoke方法, 通过传入方法名返回注解对应的属性值



### 上述学习对自言框架意义

- 使用注解标记需要工厂管理的实例, 并依据注解属性做精细控制



### 控制反转IoC-Inversion of Control

- 依托一个类似工厂的IoC容器
- 将对象的创建, 依赖关系的管理以及生命周期交由IoC容器管理
- 降低系统在实现上的复杂性和耦合度, 易于扩展, 满足开闭原则
- 是Spring Core最核心的部分. IoC并不能算一门技术, 算一种思想
- 需要了解依赖注入(Dependency Injection): 把底层类作为参数传递给上层类, 实现上层对下层的"控制", 而非下层控制上层

![image-20210222202609436](Spring%E6%BA%90%E7%A0%81%E8%BD%BB%E6%9D%BE%E5%AD%A6.assets/image-20210222202609436.png)



依赖注入的方式:

- Setter
- Interface
- Constructor
- Annotation

![image-20210222203104656](Spring%E6%BA%90%E7%A0%81%E8%BD%BB%E6%9D%BE%E5%AD%A6.assets/image-20210222203104656.png)



IoC容器的优势:

- 避免在各处使用new来创建类, 并且可以做到统一维护
- 创建实例时候不需要了解其中的细节
- 反射+工厂模式的合体, 满足开闭原则

![image-20210222203642922](Spring%E6%BA%90%E7%A0%81%E8%BD%BB%E6%9D%BE%E5%AD%A6.assets/image-20210222203642922.png)

![image-20210222203806569](Spring%E6%BA%90%E7%A0%81%E8%BD%BB%E6%9D%BE%E5%AD%A6.assets/image-20210222203806569.png)

# 自研框架IoC容器实现

<img src="Spring%E6%BA%90%E7%A0%81%E8%BD%BB%E6%9D%BE%E5%AD%A6.assets/image-20210222213731697.png" alt="image-20210222213731697" style="zoom:67%;" />

## 框架最基本功能

- **解析配置**: XML, Annotation
- **定位与注册对象**: 定位通过注解实现
- **注入对象**: 在用户使用时将正确对象注入
- 提供通用的工具类(非必须)



## IoC容器的实现

需要实现的点:

- 创建注解: @Controller, @Service, @Repository, @Component. Component是通用的实现, 其他三个是Component具有特殊含义的拓展.
- 提取标记对象: 对象泛指被标记目标
  - 范围确定: 由框架使用者决定范围, 提取范围类的所有类
  - 遍历所有类, 获取被注解标记的类并加载进容器内
  - extractPackageClass功能:
    - 获取到类加载器: 获取项目发布的实际路径
      - 传入绝对路径不友好, 不同机器间的路径可能不同
      - 如果是war包或者jar包, 根本找不到路径
      - 通用做法通过类加载器来截取
    - 通过类加载器获取到加载的资源
    - 依据不同的资源类型, 采用不同的方式获取资源的集合
- 实现容器: 简单实现将类与类实例键值对存入
- 依赖注入:



类加载器ClassLoader:

- 根据一个指定类名称, 找到或生成其对应的字节码
- 加载Java应用所需的资源



统一资源定位符URL: 某个资源的唯一地址

- 通过获取java.net.URL实例获取协议名, 资源名路径等信息
- <img src="Spring%E6%BA%90%E7%A0%81%E8%BD%BB%E6%9D%BE%E5%AD%A6.assets/image-20210222220821076.png" alt="image-20210222220821076" style="zoom:80%;" />
- URL不仅能表示外网资源, 也可以表示本地资源, 此处我们主要关注文件类型.



容器组成部分：

- 保存Class对象及其实例的载体：私有的ConcurrentHashMap<Class<?>,Object>
- 容器的加载：
  - 配置的管理与获取
  - 获取指定范围内的Class对象：存放定义Annotation的Class对象集合
  - 依据配置提取Class对象，连同实例一并存入容器
- 容器的操作方式
  - 涉及到容器的增删改查
    - 增加、删除操作
    - 根据Class获取对应实例
    - 获取所有的Class和实例
    - 通过注解来获取被注解的Class
    - 通过超类获取对应子类的Class
    - 获取容器载体保存Class的数量



实现依赖注入：

目前容器里面管理的Bean实例仍可能不完备

- 实例里面某些必须的成员变量还未被创建出来

实现思路：

- 定义相关的注解标签
- 实现创建被注解标记的成员变量实例，并将其注入到成员变量里



## 单例模式 

确保类只有一个实例，并对外提供统一访问方式

- 饿汉式：在类加载时就创建出单例对象
- 懒汉式：在被客户端首次调用的时候才创建唯一实例。
  - 主流方式是添加双重检查锁机制来确保线程安全。
  - volatile与final不能共用，volatile保证内存可见性
  - 对象创建有三步：1分配对象内存对象空间；2初始化对象；3引用指向分配内存空间。在变量没有被volatile修饰时，2与3两步不存在依赖关系，顺序可被程序执行器优化，导致instance还未被初始化就把地址发布给其他线程。
- private私有构造器可通过反射机制被客户端访问，可导致非单例情况。
- 装备了枚举的饿汉式能抵御反射与序列化的进攻，满足容器需求。

ObjectInputStream.readObject()



Spring框架有多种作用域：

- singleton：整个Spring生命周期内只有一个
- prototype：使用原型模式，每次通过getBean获取实例时创建一个新的实例
- request：每次http请求都产生一个新实例
- session：每次http请求按session产生一个实例
- globalsession：每次全局http请求产生一个实例



# SpringIoC容器源码解析

注意点：

- 不要太在意版本问题，核心思想IOC、AOP不会改变
- 覆盖所有细节是不可能的
- 抓住骨架进行学习



主干骨架：

- 解析配置
- 定位与注册对象
- 注入对象



## Bean

全局掌握核心接口和类

解决了关键的问题：将对象之间关系转而用配置来管理

- 依赖注入：依赖关系在Spring的IoC容器中管理
- 通过把对象包装在Bean中以达到管理对象和进行额外操作的目的



Bean是Spring的一等公民

- Bean的本质就是Java对象，Spring并没有通过特定接口或父类来限制它，只是这个对象的生命周期由容器来管理
- 不需要为了创建Bean而在原来Java类上添加任何额外的限制。体现了Spring的低侵入甚至无侵入
- 对java对象的控制体现在配置上（配置文件/注解）



根据配置，生成用来描述Bean的BeanDefinition，常见属性：

- 作用范围scope(@scope)：singleton、prototype、request、session、globalsession
- 懒加载lazy-init(@Lazy)：就定Bean实例是否延时加载
- 首选primary(@Primary)：设置为true的bean会是优先的实现类
- factory-bean和factory-method(@Configuration和@Bean)：factory-bean表示工厂类的名称、factory-method表示工厂方法的名称



容器初始化主要脉络：

<img src="Spring%E6%BA%90%E7%A0%81%E8%BD%BB%E6%9D%BE%E5%AD%A6.assets/image-20210311194813914.png" alt="image-20210311194813914" style="zoom:60%;" />

1. 将XML、注解等配置信息读取到内存中
2. 在内存中配置以Resource对象存储
3. 将Resource对象解析成BeanDefinition实例
4. 最后将实例注册到容器中

对应自研框架中`解析配置`、`定位与注册对象`

![image-20210311195056943](Spring%E6%BA%90%E7%A0%81%E8%BD%BB%E6%9D%BE%E5%AD%A6.assets/image-20210311195056943.png)

Spring中Bean的继承关系不是通过extend、implements实现的。而是通过设置`parent`属性完成的。

一般情况下，Spring中的Bean标签会被解析成RootBeanDefinition。Spring2.5后使用GenericBeanDefinition将RootBeanDefinition和ChildBeanDefinition取代，因历史原因还有使用RootBeanDefinition。

FactoryBean和BeanFactory：BeanFactory是SpringBean工厂的根接口，提供一些基础特性。FactoryBean本质也是Bean，但其做用是用于生成Bean。

