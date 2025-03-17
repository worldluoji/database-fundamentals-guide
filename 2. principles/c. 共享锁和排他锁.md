# 共享锁和排他锁
## 共享锁
`SELECT ... LOCK IN SHARE MODE` 是 SQL 中的一种锁定机制，主要用于事务处理中，确保数据在读取过程中的稳定性和一致性。
- 共享锁允许多个事务同时读取同一行数据。
- 加锁后，其他事务可以继续加共享锁，但不能加排他锁。

### 使用场景：
适用于只读操作，确保数据在读取期间不会被其他事务修改。

### 示例：

假设我们有以下的表结构和数据：

```sql
CREATE TABLE accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    balance DECIMAL(10,2) NOT NULL
);
INSERT INTO accounts (balance) VALUES (100), (200);
```

现在，两个事务想要读取 `accounts` 表中的数据，并且事务 A 想要锁定数据以便稍后进行更新：

```sql
-- 事务 A 开始
START TRANSACTION;
SELECT * FROM accounts WHERE id = 1 LOCK IN SHARE MODE;

-- 事务 B 尝试读取相同的数据
START TRANSACTION;
SELECT * FROM accounts WHERE id = 1; -- 成功读取，因为是共享锁
```

此时，事务 B 可以读取数据，但是如果事务 B 尝试修改这些数据，将会被阻塞，直到事务 A 的锁被释放：

```sql
-- 事务 B 尝试更新数据
UPDATE accounts SET balance = 150 WHERE id = 1; -- 被阻塞
```

只有当事务 A 显式地提交或回滚时，锁才会被释放，事务 B 才能继续执行其更新操作：

```sql
-- 事务 A 提交
COMMIT;
```

### 注意事项：

- 使用 `SELECT ... LOCK IN SHARE MODE` 需要在事务中进行，否则锁不会生效。
- 如果在同一个事务中使用了 `FOR UPDATE` 锁（排他锁）之后再使用 `LOCK IN SHARE MODE`，那么 `LOCK IN SHARE MODE` 实际上会被忽略，因为排他锁已经禁止了所有其他事务对该行的访问。
- 在高并发环境下，过度使用共享锁可能会导致锁等待时间增加，影响数据库性能。

---

## 排他锁
- 排他锁用于写操作，确保只有一个事务可以修改数据。
- 加锁后，其他事务不能加共享锁或排他锁。

### 使用场景
适用于写操作（如 UPDATE、DELETE、INSERT），确保数据在修改期间不会被其他事务读取或修改。

使用 FOR UPDATE 可以显式加排他锁，它会对查询结果集中的所有行加排他锁。

### 示例：

考虑一个简单的转账场景，有两个账户 A 和 B，我们需要从 A 账户转一定金额到 B 账户。为了确保转账过程中数据的一致性，我们可以使用 `FOR UPDATE` 锁定账户数据：

```sql
-- 创建表和插入数据
CREATE TABLE accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    balance DECIMAL(10,2) NOT NULL
);
INSERT INTO accounts (balance) VALUES (100), (200);

-- 启动事务
START TRANSACTION;

-- 读取账户 A 的信息并锁定
SELECT * FROM accounts WHERE id = 1 FOR UPDATE;

-- 检查余额是否足够
IF (SELECT balance FROM accounts WHERE id = 1) >= 50 THEN
    -- 更新账户 A 和 B 的余额
    UPDATE accounts SET balance = balance - 50 WHERE id = 1;
    UPDATE accounts SET balance = balance + 50 WHERE id = 2;
END IF;

-- 提交事务
COMMIT;
```
在这个例子中，`SELECT * FROM accounts WHERE id = 1 FOR UPDATE;` 不仅读取了账户 A 的信息，还对其进行了锁定，防止在转账过程中其他事务对其进行修改。

### 注意事项：
- 排他锁与共享锁和排他锁都不兼容。
- 一个事务持有排他锁后，其他事务无法读取或修改该行数据。
- 索引的重要性：如果查询条件没有使用索引，FOR UPDATE 或 LOCK IN SHARE MODE 可能会导致锁表。
- 事务大小：尽量减少事务中锁定的数据量，避免长时间锁定影响并发性能。
- 隔离级别：不同隔离级别下，锁的行为可能有所不同。例如，READ COMMITTED 隔离级别下，FOR UPDATE 只会锁定符合条件的行，而 REPEATABLE READ 会锁定扫描过的所有行。

---

## 对比
通过对比，发现for update的加锁方式无非是比lock in share mode的方式
多阻塞了select...lock in share mode的查询方式，并不会阻塞快照读。

也就是说，FOR UPDATE 锁是一种排他锁（exclusive lock），它阻止其他事务对被锁定的行进行任何写操作，同时也阻止其他事务对这些行使用 FOR UPDATE 或 LOCK IN SHARE MODE 加锁。但是，普通的 SELECT 查询（不带任何锁提示）仍然可以读取这些行，因为它们不试图获取任何类型的锁。而LOCK IN SHARE MODE 可以在多个不同的事务中执行,如果事务 A 稍早于事务 B 请求锁，那么事务 A 将首先获得锁。事务 B 将被阻塞，直到事务 A 提交或回滚，释放了锁。

example:
```sql
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

example2:
```sql
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