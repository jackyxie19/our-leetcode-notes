# MySQL问题

### 事务

#### 事务分类

#### MYSQL事务特性：ACID

#### 隔离级别

四个隔离级别，MySQL是如何实现RR(可重复读)和RC(提交读)的

#### 事务实现：redo、undo、purge

二阶段提交

MySQL  redo/undo日志作用

回滚是怎么实现的

MySQL  二进制日志文件binlog原理

MVCC多版本并发控制，如何实现可重复读，MVCC如何实现快照读

### 索引

#### B+树索引：聚集和非聚集、辅助索引、覆盖索引

索引为什么用B+树而不是B树

#### B+树索引的操作：插入、删除、分裂、管理

索引建立的过程

使用索引的注意事项，什么情况下使用索引（索引创建原则）

#### 自适应哈希索引

#### 联合索引

联合索引(a,b,c)  where a=100 and b>2 and c<3能使用哪些索引

#### 全文检索

全文索引，索引什么时候会失效 





### 锁

#### 锁问题：脏读、不可重复读、幻读、丢失更新	

#### 锁算法：行锁、间隙锁、Next-Key Locking

#### 一致性锁定读与非锁定读、MVCC

#### 乐观锁与悲观锁

#### Innodb引擎死锁如何解决

#### 三级封锁协议

### InnoDB其他

#### 分区表

#### InnoDB存储结构



### MySQL其他

#### 各存储引擎的区别：InnoDB、MyISAM、Memory、Archive

MYSQL主从复制

MYSQL写多读少怎么处理

MYSQL范式

如何保障MYSQL与redis、elasticsearch数据一致性

数据库读写分离