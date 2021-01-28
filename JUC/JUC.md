# JUC

# 分类

1. 为了**并发安全**：**互斥同步**、**非互斥同步**、无同步方案(`ThreadLocal` `volatile`)：
2. 管理线程、提高效率：
3. 线程协作：

## 为了线程安全（底层原理角度分类）

### 互斥同步

#### 使用各种互斥同步的锁

##### synchronized

##### ReentrantLock

##### ReadWriteLock

#### 使用同步的工具类

##### Collections.synchornized

##### Vector

### 非互斥同步

#### Atomic包，原子类

### 结合互斥同步及非互斥同步

#### 并发容器

### 无同步方案、不可变

## 为了线程安全（使用者角度分类）

### 避免共享变量

### 共享变量，但加以处理

### 使用成熟工具类

## 为了方便管理线程、提高效率



## 为了线程间配合，满足业务逻辑



# 线程池

## 线程池自我介绍

### 线程池的重要性

对线程池的提问可以层层递进。

### 什么是“池”

软件中的“池”，可以理解为计划经济。如固定数量的线程池，预创建指定数量线程。可以复用线程、控制线程的总量。

如果不使用线程池、每个任务都新开一个线程处理。

系统创建与回收线程开销大，使用线程池减少创建开销。过多的线程消耗大量内存。

### 为什么要使用线程池

问题一：反复创建线程开销大	

解决：少量线程反复工作

问题二：过多的线程占用太多内存	

解决：用少量的线程

### 线程池的优点

1. 速度快，无需反复创建与收回；节省线程创建与回收时间。
2. 合理利用CPU和内存。
3. 统一管理资源。

### 线程池适用场景

1. 服务器接收到大量请求时，适用线程池非常合适，可大大减少线程的创建和销毁次数，提高服务器工作效率。
2. 开发中，如果需要创建5个以上的线程，那么就可以适用线程池来管理，

## 创建和停止线程池

### 线程池构造函数的参数

1. corePoolSize: 线程池核心线程数。默认情况下，线程池在初始化后没有任何线程，直到任务到来时再创建线程执行任务。corePoolSize指定线程池首个任务到达时生成的线程数量，类似minSize。
2. maxPoolSize: 线程池最大上限。达max后拒绝请求，交handler处理。
3. keepAliveTime: 多余corePoolSize数量的线程在超过keepAliveTime时被回收。
4. workQueue: 线程数处于corePoolSize与maxPoolSize间先将任务加入队列，队列满则创建新线程。
   1. 直接交换：SynchronousQueue，无队列缓冲，maxPoolSize需要设置大一些。
   2. 无界队列：LinkedBlockingQueue
   3. 有界队列：ArrayBlockingQueue
5. threadFactory: 新线程都由ThreadFactory创建。
6. handler:

corePoolSize与maxPoolSize相同为固定大小的线程池。

线程池希望保持较少的线程数，只有负载增大时才增加。

如果workQueue使用的是无界队列，如LinkedBlockingQueue，那么线程数不会超过......

### 线程池应手动创建还是自动创建

手动创建更好，可以更明确线程池的运行规则，避免资源耗尽风险。

直接调用JDK提供线程池可能带来风险：

1. newFixedThreadPool: corePoolSize与maxPoolSize相同，workQueue使用无界队列LinkedBlockingQueue，有内存溢出的风险。
2. newSingleThreadExecutor: corePoolSize与maxPoolSize设1，workQueue使用无界队列LinkedBlockingQueue。
3. newCachedThreadPool: corePoolSize为1，maxPoolSize为Integer.MAX_VALUE，keepAliveTime为60s，workQueue使用SynchronousQueue。
4. newScheduledThreadPool: corePoolSize传入，maxPoolSize为Integer.MAX_VALUE，workQueue使用DelayWorkQueue，threadFactory可传入。
   1. 提供schedule(Runnable, initialDelay, period, timeUnit)，可周期性执行任务。

业务调研后设计线程参数。

1.8后加入workStealingPool，与之前线程池有很大不同：

1. 子任务：子任务放入子任务独有的队列中
2. 窃取：若其他线程空闲，可帮助其他线程子任务队列中的任务执行，要求执行任务不加锁。任务执行顺序不被保证。

### 线程池的线程数量设定为多少比较合适

CPU密集型（加密、计算hash等）：最佳线程数为CPU核心数1-2倍。

IO密集型（读写数据库、文件、网络通信等）：以JVM线程监控显示繁忙情况为依据，保证线程空闲可衔接。参照Brain Goetz推荐计算方法：CPU cores * (1+avg_wait/avg_working)。

最为精准的线程数量设置根据压测结果设定。

### 线程池停止

1. shutdown(): 初始化整个关闭过程，不保证线程池关闭。将正执行的任务及等待队列中的任务执行完成后再关闭，拒绝接受新任务。
2. isShutdown(): 
3. isTerminated(): 
4. awaitTermination(): 等待一段时间看线程池是否关闭，仅用于检测。
5. shutdownNow(): 关闭线程池，中断正在运行线程，返回等待执行任务队列。

## 任务太多，怎么拒绝

### 拒绝时机

1. Executor关闭时，新任务会被拒绝。
2. Executor队列满，且线程达maxSize，新任务会被拒绝。

### 4种拒绝策略

1. AbortPolicy：抛出异常 RejectedExecutionException
2. DiscardPolicy：丢弃任务，不通知
3. DiscardOldestPolicy：丢弃队列中最老的任务
4. CallerRunsPolicy：由提交任务线程执行该任务

1-3中会有任务损失，4不会有任务损失。

4可以使提交速度降低，负反馈，给线程池缓冲时间。

## 钩子方法，给线程池加点料

在每个任务执行前后做一些操作，如日志、统计。

## 实现原理、源码分析

### 线程池组成

1. 线程池管理器：
2. 工作线程：
3. 任务队列：
4. 任务接口（Task）：

### Executor家族

Executor

ExecutorService

Executors

### 线程池实现线程复用原理

相同线程执行不同任务

## 线程池注意点

线程池状态：

1. RUNNING：
2. SHUTDOWN：
3. STOP：
4. TIDYING：
5. TERMINATED：

避免任务堆积：

避免线程数过度增加：

排查线程泄漏：已执行完毕，但线程未被回收



# ThreadLocal

## 两大使用场景

1. 每个线程需要一个独享的对象（通常是工具类，典型需要使用的有SimpleDateFormat与Random）。主要诉求是工具类线程不安全。
2. 每个线程内需要保存全局信息（例如在拦截器总获取用户信息），可以让不同方法使用，避免参数层层传递的麻烦。主要诉求是避免参数传递麻烦。

### 每个线程需要一个独享的对象

每个Thread内有自己的实例副本，不共享。

比喻：教材只有一本，一起做笔记有线程安全问题。复印后没问题。

SimpleDateFormate进化之路

### 每个线程内需要保存全局信息，避免参数传递麻烦

### 总结

1. 让某个需要用到的对象在**线程间隔离**（每个线程都有自己的独立对象）
2. 在任何方法中都可以轻松的获取到对象，`ThreadLocal::get`

根据共享对象的生成时机不同，选择initialValue与set设置值

1. initialValue：在ThreadLocal第一次get的时候把对象初始化出来，对象的初始化时机可以由我们掌控。
2. set：保存包ThreadLocal中的对象的生成时机不由我们随意控制。如拦截器中生成的用户对象。

## ThreadLocal好处

1. 线程安全
2. 不需要锁，提高执行效率
3. 更高效地利用内存、节省开销
4. 免去传参的繁琐，降低代码耦合度

## ThreadLocal原理

<img src="JUC.assets/image-20210126171234915.png" alt="image-20210126171234915" style="zoom:50%;" />

每一个Thread对象中都持有一个ThreadLocalMap成员变量

<img src="JUC.assets/image-20210126180835426.png" alt="image-20210126180835426" style="zoom:50%;" />

Entry可视为以ThreadLocal为key的键值对。

ThreadLocalMap类似HashMap，但与HaspMap在处理Hash冲突时不同。ThreadLocalMapHash冲突时使用线性探测法。

### 主要方法

1. initialValue(): 调用get()时延时加载; 若get()前调用了set()方法则不会执行initialValue(); initialValue()只会执行一次
2. set(): 
3. get():
4. remove():

## ThreadLocal注意点

### 内存泄漏

某个对象不再使用，但占用内存却未被回收。最终导致内存耗尽抛出OOM。Entry.key or Entry.value泄漏。

Entry中的key（ThreadLocal）存于弱引用中，而弱引用可被GC回收。但Entry中value为强引用，不能不GC回收。

正常情况下，线程终止时value会被回收。但若线程不终止，那么线程的value就不能回收。

JDK中Entry的set、remove、rehash等方法在发现key为null时，将value置为null，断掉强引用。

> 在使用完ThreadLocal后，主动调用remove方法清除ThreadLocal。

### 空指针异常

ThreadLocal指定的为包装类型。若ThreadLocal包装类型未赋值，get时会返回null，若此时get值赋值为原始类型则会抛出空指针异常（为null的封装类型拆箱抛出NullPointerException）。

### 共享对象

如果每个线程中ThreadLocal.set()传入值本来就是多个线程共享的对象，如static对象，那么多个线程的ThreadLocal.get()获取的还是共享对象本身，有并发访问问题。

### 如果可以不使用ThreadLocal，尽量不使用

如任务少时，局部变量即可解决问题。

### 优先使用框架的支持

如Spring中可使用RequestContextHolder、DateTimeContextHolder。



# 锁

## Lock接口

### 简介、地位、作用

锁是一种工具，用于控制对**共享资源**的访问。

Lock和synchronized是两个最常见的锁，他们都可达到线程安全目的，但在使用及功能上有较大不同。

Lock不是用来替代synchronized的，而是补充synchronized不具备的高级功能。

Lock接口最常见的实现类是ReentrantLock。

通常情况下，Lock只允许一个线程访问上锁资源。但有时，特殊的实现可允许并发访问，如ReadWriteLock中的ReadLock。

### Why Lock？

为什么synchronized不够用？

1. 效率低：锁的释放情况少、视图获取锁时不能释放定超时、不能中断一个正在试图获取锁的线程。
2. 不够灵活：加锁和释放的时机单一，每个锁仅有单一的条件
3. 无法知道是否成功获得锁

### 方法介绍

lock()：最普通的获取锁

Lock不会像synchronized一样在异常时自动释放，因此需在finally中释放锁。

tryLock()用来尝试获取锁，如果锁未被占用则获取成功，否则返回false

tryLock(long time, TimeUnit unit)：超时就放弃。

### 可见性保证

happens-before原则

Lock的加解锁和synchronized有同样的内存语义，下一个线程加锁后可以看到前一个线程解锁前发生的所有操作。

## 锁的分类

分类是从不同角度出发，这些角度并不互斥，可能并行。如ReentrantLock即时互斥锁又是可重入锁

### 是否锁住同步资源

乐观锁与悲观锁

### 多线程能否共享一把锁

共享锁与独占锁，最典型为读锁/写锁

### 多线程竞争时是否排队

公平锁与非公平锁

### 是否可中断

可中断锁与不可中断锁

### 等锁过程

自旋锁与非自旋锁

## 乐观锁与悲观锁

### （悲观锁）互斥同步锁的劣势

阻塞和唤醒带来的性能劣势：核心态用户态切换、上下文切换等

可能陷入永久阻塞：若持有锁线程被永久阻塞，其余线程得不到执行

优先级反转：获得锁的低优先级线程不释放锁

### 什么是乐观锁与悲观锁

乐观锁假设出错是小概率事件，悲观锁假设出错是一种常态

悲观锁认为不锁住资源，别人会来争抢。Java中悲观锁实现为synchronized及Lock。

乐观锁认为处理操作时不会受到干扰，其不锁住被操作对象。如果操作失败，则选择放弃、报错、重试等策略。乐观锁一般使用CAS算法。典型实现为原子类、并发容器等。

Git就是乐观锁的典型例子。当我们向远端仓库push时，git会检查远端仓库版本是否领先当前版本。若远端和本地版本不一致，表明其他人修改了远端代码，则此次更新失败。若远端与本地版本一致则提交到远端。

数据库中select for update是悲观锁，用version来控制是乐观锁。

### 开销对比

悲观锁适合并发写入多的情况，适用于临界区持锁时间比较长的情况，可避免大量无用的自旋操作。

乐观锁适合写入少，大部分是读取的场景，不加锁能让读取性能大幅提升。

## 可重入锁与非可重入锁（ReentrantLock）

再次申请锁时，无需释放当前锁即可获取锁（同一把锁）。可重入锁又称递归锁。好处是避免死锁、提高封装性。



## 公平锁与非公平锁

### 什么是公平和非公平

公平指按照线程请求的顺序来分配锁；非公平指不完全按照请求顺序，在一定情况下可以插队。

什么是合适的时机？

### 为什么有非公平锁

可提高效率，避免唤醒带来的空档期。

### 特例

### 对比公平和非公平的优缺点

## 共享锁与排它锁

## 自旋锁和阻塞锁

## 可中断锁

## 锁优化