# 共享锁和排他锁
SELECT ... LOCK IN SHARE MODE走的是IS锁(意向共享锁)，即在符合条件的rows上都加了共享锁，
这样的话，其他session可以读取这些记录，也可以继续添加IS锁，
但是无法修改这些记录直到你这个加锁的session执行完成(否则直接锁等待超时)。 

SELECT ... FOR UPDATE 走的是IX锁(意向排它锁)，即在符合条件的rows上都加了排它锁，
其他session也就无法在这些记录上添加任何的S锁或X锁。
但是innodb有非锁定读(快照读并不需要加锁)，for update之后并不会阻塞其他session的快照读取操作，
除了select ...lock in share mode和select ... for update这种显示加锁的查询操作。 

通过对比，发现for update的加锁方式无非是比lock in share mode的方式
多阻塞了select...lock in share mode的查询方式，并不会阻塞快照读。
但是，for update 会加上一个写锁。

example:
```
CREATE TABLE `t` (
  `id` int(11) NOT NULL,
  `c` int(11) DEFAULT NULL,
  `d` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `c` (`c`)
) ENGINE=InnoDB;

insert into t values(0,0,0),(5,5,5),
(10,10,10),(15,15,15),(20,20,20),(25,25,25);
 
begin;
select * from t where d=5 for update;
commit;
```
这个语句会命中 d=5 的这一行，对应的主键 id=5，
因此在 select 语句执行完成后，id=5 这一行会加一个写锁，而且由于两阶段锁协议，
这个写锁会在执行 commit 语句的时候释放。

<br>

## select for update例子
```
CREATE TABLE `t` (
  `id` int(11) NOT NULL,
  `c` int(11) DEFAULT NULL,
  `d` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `c` (`c`)
  ) ENGINE=InnoDB;
insert into t values(0,0,0),(5,5,5),
(10,10,10),(15,15,15),(20,20,20),(25,25,25);

   begin;
   select * from t where d=5 for update;
   commit;
```
- select for update仅适用于InnoDB，且必须在事务区块(start sta/COMMIT)中才能生效。
- select for update会加一个写锁， 写锁在commit提交事务后释放。