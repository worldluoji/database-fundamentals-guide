# 共享锁和排他锁
## 共享锁
`SELECT ... LOCK IN SHARE MODE` 是 SQL 中的一种锁定机制，主要用于事务处理中，确保数据在读取过程中的稳定性和一致性。这种类型的锁被称为共享锁（Share Lock），它允许其他事务可以继续读取同一行的数据，但阻止任何事务对这些行进行更新或删除直到锁被释放。

### 如何工作？

当你执行一个 `SELECT ... LOCK IN SHARE MODE` 查询时，MySQL 会为涉及到的每一行数据加上共享锁。这意味着其他事务仍然可以读取这些行（因此称为共享锁），但是不能对这些行执行任何排他性操作，如更新或删除，直到当前事务结束或者显式地解锁。

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

总之，`SELECT ... LOCK IN SHARE MODE` 是一种在读取数据时保证数据一致性的有效手段，尤其适用于需要在多个事务间共享数据的场景。但在设计时也需要注意避免不必要的锁竞争，以保持良好的系统响应时间和吞吐量。

<br>

## 排他锁
`FOR UPDATE` 是 SQL 中用于获取排他锁的一种机制，通常在事务处理中使用，以确保数据的一致性和隔离性。当一个查询使用 `FOR UPDATE` 子句时，它不仅读取数据，还会在所读取的每一行上放置排他锁（Exclusive Locks），这会阻止其他事务对这些行进行任何修改，包括更新或删除，直到当前事务完成（提交或回滚）。

### 如何工作？

当你执行一个带有 `FOR UPDATE` 子句的 `SELECT` 查询时，MySQL 将会在读取的所有行上放置排他锁。这意味着直到当前事务结束，其他任何事务都不能对这些行进行读取或写入操作。

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

1. **锁定范围**：`FOR UPDATE` 锁定的范围取决于查询的条件。如果查询没有使用索引，那么可能锁定整个表，这会影响数据库的性能和并发能力。

2. **死锁**：在高并发环境中，多个事务同时使用 `FOR UPDATE` 锁可能导致死锁情况。死锁是指两个或更多事务在等待对方释放锁，从而无法继续执行的情况。MySQL 会检测到死锁，并自动回滚其中一个事务来解除死锁。

3. **隐式锁定**：在某些存储引擎（如 InnoDB）中，即使没有显式使用 `FOR UPDATE`，在事务中进行的更新操作也会自动锁定受影响的行，以保证数据的一致性。

4. **与其他锁定类型的关系**：在同一个事务中，`FOR UPDATE` 锁会优先于 `LOCK IN SHARE MODE` 锁，即排他锁会覆盖共享锁的效果。

总的来说，`FOR UPDATE` 是一种强大的工具，用于在事务中保护数据免受并发修改的影响。然而，它也需要谨慎使用，以避免不必要的性能下降和死锁风险。

<br>

## 对比
通过对比，发现for update的加锁方式无非是比lock in share mode的方式
多阻塞了select...lock in share mode的查询方式，并不会阻塞快照读。

也就是说，FOR UPDATE 锁是一种排他锁（exclusive lock），它阻止其他事务对被锁定的行进行任何写操作，同时也阻止其他事务对这些行使用 FOR UPDATE 或 LOCK IN SHARE MODE 加锁。但是，普通的 SELECT 查询（不带任何锁提示）仍然可以读取这些行，因为它们不试图获取任何类型的锁。而LOCK IN SHARE MODE 可以在多个不同的事务中执行,如果事务 A 稍早于事务 B 请求锁，那么事务 A 将首先获得锁。事务 B 将被阻塞，直到事务 A 提交或回滚，释放了锁。

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

example2:
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