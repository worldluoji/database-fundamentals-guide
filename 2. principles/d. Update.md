# MySql Update

## update 语句执行流程
```
update users set c = c + 1 where id = 2;
```

<img src="./pics/update语句执行流程.png" />

update流程涉及 redo log和 bin log两个重要的日志模块。

---

### WAL 机制（Write-Ahead Logging）​
- ​核心思想：先写日志（内存操作），再异步刷盘（磁盘操作），以此优化性能。
- 核心日志：redo log 是实现 WAL 的关键，所有数据变更会先记录到 redo log 中，再异步持久化到磁盘文件（如 .ibd 文件）。
```
事务提交后 -> 数据页留在 Buffer Pool（脏页） -> 后台线程异步刷盘 -> 更新磁盘数据文件
```

---

### redo log 与 bin log 的对比

| **特性**          | **redo log (InnoDB 特有)**           | **bin log (Server 层)**             |
|--------------------|--------------------------------------|-------------------------------------|
| **作用**           | 保证事务的持久性（Crash-Safe）       | 数据归档、主从复制、时间点恢复      |
| **存储方式**       | 循环写入（固定大小文件组）           | 追加写入（文件持续增长）            |
| **写入时机**       | 事务执行中实时写入内存（`redo log buffer`） | 事务提交时写入磁盘（`binlog cache`） |
| **数据粒度**       | 物理日志（记录数据页修改）           | 逻辑日志（记录 SQL 或行变更）       |
| **事务支持**       | 与事务绑定，支持崩溃恢复             | 依赖存储引擎的事务状态              |

- redo log是 innodb 特有的，而bin log在Service层，MyIAsam和InnoDb都有。
- redo log大小是固定的，从头写到尾又到头，是一个圈；bin log则是追加写，不会覆盖原来的。 
- redo log相当于一个“粉板”， 在执行更新操作的时候，先写到 redo log（内存）里，等到空闲的时候再写到磁盘（redo log也是要写入磁盘的）；
- bin log用来恢复数据，可以恢复记录的任意一秒的数据。

---

### 两阶段提交（2PC）的必要性
Mysql innodb 在 update时，会先记录 redo log，再记录 bin log, 最后提交事务，是一个典型的两阶段提交。
- **核心目的**：保证 `redo log` 和 `bin log` 的日志一致性，避免以下问题：
  - **场景 1**：若先写 bin log 后写 redo log：
    - bin log 已记录提交，但 redo log 未记录。
    - 崩溃恢复时，事务会被回滚，导致主从数据不一致。
  - **场景 2**：若先写 redo log 后写 bin log：
    - redo log 已提交，但 bin log 未记录。
    - 主库数据已更新，但从库无法同步，导致数据丢失。

- **恢复逻辑**：
  - 崩溃后，检查 redo log 的 prepare 记录和 bin log 的完整性：
    - 若 bin log 完整：提交事务（即使 redo log 未 commit）。
    - 若 bin log 不完整：回滚事务。

为什么用 bin log 恢复数据？因为前面已经说了，redo log是 innnodb用来优化性能和保证 crash-safe，而且会循环写覆盖，而bin log是追加写的。

Crash-Safe 的核心含义是：即使数据库在运行过程中突然崩溃（如断电、宕机），重启后也能确保：
- ​已提交的事务数据不丢失；
- ​未提交的事务数据自动回滚。

​Crash-Safe 的本质：用日志的持久化能力，弥补内存数据丢失的风险。

#### 类比理解
​例子：记账本（redo log） vs 保险柜（磁盘数据）​
​
- 日常操作：你收到一笔钱，先在记账本上记录（redo log 刷盘）。
随后再将钱存入保险柜（数据页刷盘）。
- 突发情况：如果还没来得及存钱到保险柜，突然停电（崩溃），此时：
保险柜里的钱是旧的（磁盘数据未更新）。但记账本已明确记录这笔收入（redo log 已持久化）。
​- 恢复过程：来电后，你根据记账本的记录，将钱存入保险柜（重放 redo log）。
​最终结果：保险柜中的钱与记账本一致。

---

## innodb_flush_log_at_trx_commit
innodb_flush_log_at_trx_commit设置为1，表示redo log持久化到磁盘，这样即使MySql异常重启后数据也不会丢失；
```
mysql> show variables like 'innodb_flush_log_at_trx_commit'
    -> ;
+--------------------------------+-------+
| Variable_name                  | Value |
+--------------------------------+-------+
| innodb_flush_log_at_trx_commit | 1     |
+--------------------------------+-------+
1 row in set (0.00 sec)
```
可以看到，在MySql 5.7中，默认就是1.

sync_binlog 这个参数设置成 1 表示每次事务的bin log都写到磁盘，则异常重启后bin log不会丢失。
```
mysql> show variables like 'sync_binlog';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| sync_binlog   | 1     |
+---------------+-------+
1 row in set (0.00 sec)
```

<strong>bin log是逻辑日志，redo log是物理日志</strong>。
逻辑日志可以给别的数据库，别的引擎使用，已经大家都讲得通这个“逻辑”；
物理日志就只有“我”自己能用，别人没有共享我的“物理格式”
```
innodb_flush_log_at_trx_commit取值补充：

innodb_flush_log_at_trx_commit = 0
```
Innodb中的 Log Thread每隔1 秒钟会将 log buffer中的数据写入到文件，同时还会通知文件系统进行文件同步的 flush操作，保证数据确实已经写入到磁盘上面的物理文件。但是，每次事务的结束（commit 或者是rollback）并不会触发 Log Thread将log buffer 中的数据写入文件。

所以，当设置为0 的时候，当MySQL Crash 和 OS Crash或者主机断电之后，最极端的情况是丢失1 秒时间的数据变更。
```
innodb_flush_log_at_trx_commit = 1
```

这也是Innodb 的默认设置。我们每次事务的结束都会触发Log Thread 将log buffer
中的数据写入文件并通知文件系统同步文件。**这个设置是最安全的设置，能够保证不论是MySQL Crash 还是OS Crash
或者是主机断电都不会丢失任何已经提交的数据。**
```
innodb_flush_log_at_trx_commit = 2
```
当我们设置为2 的时候，Log Thread
会在我们每次事务结束的时候将数据写入事务日志，但是这里的写入仅仅是调用了文件系统的文件写入操作。
而我们的文件系统都是有缓存机制的，所以Log Thread的这个写入并不能保证内容真的已经写入到物理磁盘上面完成持久化的动作。

文件系统什么时候会将缓存中的这个数据同步到物理磁盘文件 Log Thread 就完全不知道了。
所以，当设置为2 的时候，MySQL Crash 并不会造成数据的丢失，但是OS Crash
或者是主机断电后可能丢失的数据量就完全控制在文件系统上了。各种文件系统对于自己缓存的刷新机制各不一样，大家可以自行参阅相关的手册。

根据上面三种参数值的说明，0的时候，如果 mysql crash可能会丢失数据，可靠性不高。
我们着重测试1和2两种情况。1的时候会影响数据库写入性能，相对2而言写入速度会慢，这只能根据实际情况来决定。

---

## UPDATE 操作的锁行为

在InnoDB存储引擎下，`UPDATE`操作的锁行为更加复杂和精细，因为它支持行级锁和多版本并发控制（MVCC）。以下是详细说明：

---

### 1. **InnoDB 的锁机制**
InnoDB默认使用行级锁，但锁的类型和行为会受到以下因素影响：
- **事务隔离级别**
- **SQL语句的条件（是否有索引）**
- **是否存在冲突操作（如并发更新同一行）**

InnoDB的锁主要分为两类：
- **共享锁（S锁）**：允许其他事务读取，但不允许写入。
- **排他锁（X锁）**：禁止其他事务读取或写入。

在执行`UPDATE`时，InnoDB会对符合条件的行加**排他锁（X锁）**，其他事务无法修改或加锁这些行，直到当前事务提交或回滚。

---

### 2. **事务隔离级别对锁的影响**
InnoDB支持四种事务隔离级别，不同级别下`UPDATE`的锁行为有所不同：

#### **1. 读未提交（Read Uncommitted）**
- `UPDATE`会对涉及的行加排他锁（X锁）。
- 其他事务可以读取未提交的数据（脏读），但不能修改这些行。

#### **2. 读已提交（Read Committed）**
- `UPDATE`会对涉及的行加排他锁（X锁）。
- 其他事务只能读取已提交的数据，不能修改这些行。
- 在`UPDATE`执行期间，如果其他事务修改了符合条件的行，InnoDB会重新扫描并锁定新的符合条件的行。

#### **3. 可重复读（Repeatable Read，InnoDB默认级别）**
- `UPDATE`会对涉及的行加排他锁（X锁）。
- 其他事务不能修改这些行，但可以读取（通过MVCC机制读取快照）。
- 在`UPDATE`执行期间，InnoDB会锁定所有符合条件的行，即使其他事务提交了新的数据，也不会影响当前事务的锁定范围。

#### **4. 串行化（Serializable）**
- `UPDATE`会对涉及的行加排他锁（X锁），并且可能升级为表级锁。
- 其他事务不能读取或修改这些行，直到当前事务完成。

---

### 3. **索引对锁的影响**
InnoDB的锁行为还取决于`UPDATE`语句的条件是否使用了索引：
- **如果使用了索引**：
  - InnoDB只会锁定符合条件的行（行级锁）。
  - 例如：`UPDATE users SET status = 'inactive' WHERE id = 10;`，如果`id`是主键或唯一索引，只会锁定`id = 10`的行。
- **如果没有使用索引**：
  - InnoDB会扫描全表，并锁定所有扫描过的行（可能升级为表级锁）。
  - 例如：`UPDATE users SET status = 'inactive' WHERE last_login < '2022-01-01';`，如果`last_login`没有索引，InnoDB会锁定整个表。

---

### 4. **锁的升级**
在某些情况下，InnoDB可能会将行级锁升级为表级锁：
- **全表扫描**：如果`UPDATE`语句没有使用索引，InnoDB可能会锁定整个表。
- **锁冲突**：当多个事务竞争同一资源时，InnoDB可能会升级锁以减少冲突。

---

### 5. **死锁问题**
InnoDB的行级锁可能导致死锁。例如：
- 事务A锁定了行1，试图锁定行2。
- 事务B锁定了行2，试图锁定行1。
- 此时，事务A和事务B互相等待，导致死锁。

InnoDB会自动检测死锁，并回滚其中一个事务以解除死锁。

---

### 6. **如何优化锁行为**
为了避免锁表或锁行带来的性能问题，可以采取以下措施：
1. **确保使用索引**：
   - 为`UPDATE`语句的条件列创建索引，避免全表扫描。
2. **控制事务大小**：
   - 尽量减少事务中`UPDATE`操作的数据量，缩短锁定时间。
3. **合理选择隔离级别**：
   - 根据业务需求选择适当的隔离级别，避免不必要的锁。
4. **分批更新**：
   - 对于大批量更新，可以分多次执行，减少单次锁定的行数。
5. **监控锁状态**：
   - 使用`SHOW ENGINE INNODB STATUS`或性能监控工具查看锁的争用情况。

---

### 7. **示例分析**
假设有一个`users`表，结构如下：
```sql
CREATE TABLE users (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    status VARCHAR(20),
    last_login DATE
);
```

#### 场景1：使用主键更新
```sql
UPDATE users SET status = 'inactive' WHERE id = 10;
```
- InnoDB会锁定`id = 10`的行（行级锁），其他行不受影响。

#### 场景2：使用非索引列更新
```sql
UPDATE users SET status = 'inactive' WHERE last_login < '2022-01-01';
```
- 如果`last_login`没有索引，InnoDB会扫描全表并锁定所有扫描过的行，可能导致锁表。

#### 场景3：并发更新同一行
- 事务A执行：
  ```sql
  UPDATE users SET status = 'inactive' WHERE id = 10;
  ```
- 事务B执行：
  ```sql
  UPDATE users SET status = 'active' WHERE id = 10;
  ```
- 事务B会被阻塞，直到事务A提交或回滚。

---

### 总结
在InnoDB下，`UPDATE`操作的锁行为主要取决于事务隔离级别、索引使用情况以及并发操作。通过合理设计索引、控制事务大小和选择适当的隔离级别，可以有效降低锁表或锁行的风险。