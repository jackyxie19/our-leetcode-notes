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



