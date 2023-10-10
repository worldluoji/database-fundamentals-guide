# MySql Update

<img src="./pics/update语句执行流程.png" />

update流程涉及redo log和bin log两个重要的日志模块。

MySql里说的WAL(Write-Ahead Logging)，关键点就是先写日志再写磁盘，对应的就是redo log.
- redo log是innodb特有的，而bin log在Service层，MyIAsam和InnoDb都有。
- redo log大小是固定的，从头写到尾又到头，是一个圈；bin log则是追加写，不会覆盖原来的。 
- redo log相当于一个“粉板”， 在执行更新操作的时候，先写到redo log（内存）里，等到空闲的时候再写到磁盘；
- bin log用来恢复数据，可以恢复记录的任意一秒的数据。

为什么用bin log恢复数据？因为前面已经说了，redo log是innnodb用来优化性能和保证crash-safe（即数据库异常重启，之前的提交也不会丢失），而且会循环写覆盖，而bin log是追加写的。
Mysql innodb在update时，会先记录redo log， 再记录bin log,最后提交事务，是一个典型的两阶段提交。

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

innodb_flush_log_at_trx_commit取值补充：

innodb_flush_log_at_trx_commit = 0

Innodb 中的Log Thread 每隔1 秒钟会将log buffer中的数据写入到文件，同时还会通知文件系统进行文件同步的flush
操作，保证数据确实已经写入到磁盘上面的物理文件。但是，每次事务的结束（commit 或者是rollback）并不会触发Log Thread
将log buffer 中的数据写入文件。所以，当设置为0 的时候，当MySQL Crash 和OS Crash
或者主机断电之后，最极端的情况是丢失1 秒时间的数据变更。

innodb_flush_log_at_trx_commit = 1

这也是Innodb 的默认设置。我们每次事务的结束都会触发Log Thread 将log buffer
中的数据写入文件并通知文件系统同步文件。**这个设置是最安全的设置，能够保证不论是MySQL Crash 还是OS Crash
或者是主机断电都不会丢失任何已经提交的数据。**

innodb_flush_log_at_trx_commit = 2

当我们设置为2 的时候，Log Thread
会在我们每次事务结束的时候将数据写入事务日志，但是这里的写入仅仅是调用了文件系统的文件写入操作。
而我们的文件系统都是有缓存机制的，所以Log Thread的这个写入并不能保证内容真的已经写入到物理磁盘上面完成持久化的动作。
文件系统什么时候会将缓存中的这个数据同步到物理磁盘文件Log
Thread 就完全不知道了。所以，当设置为2 的时候，MySQL Crash 并不会造成数据的丢失，但是OS Crash
或者是主机断电后可能丢失的数据量就完全控制在文件系统上了。
各种文件系统对于自己缓存的刷新机制各不一样，大家可以自行参阅相关的手册。

根据上面三种参数值的说明，0的时候，如果mysql crash可能会丢失数据，可靠性不高。
我们着重测试1和2两种情况。1的时候会影响数据库写入性能，相对2而言写入速度会慢，这只能根据实际情况来决定吧。
