# exam1
以下是一套精心设计的**MySQL中高难度试题**，覆盖概念、原理、SQL编写及优化等核心领域，结合真实场景与高频面试考点，助你全面提升MySQL能力。所有题目均附带解析，便于查漏补缺。

---

### **一、选择题**（共10题，每题3分）  
1. **关于InnoDB的MVCC机制，以下描述错误的是？**  
   A. 通过事务ID和回滚指针实现多版本  
   B. 读已提交（RC）隔离级别下，每次读取都会生成新的ReadView  
   C. 可重复读（RR）隔离级别下，ReadView在事务开始时创建且不更新  
   D. MVCC完全避免了锁的使用  
   **答案：D**  
   **解析**：MVCC通过多版本减少锁竞争，但写操作仍需加锁（如行锁、间隙锁）。

2. **以下哪种场景会导致索引失效？**  
   A. `WHERE name LIKE 'John%'`  
   B. `WHERE YEAR(create_time) = 2025`  
   C. `WHERE age = 30 AND status = 1`（联合索引为`(age, status)`）  
   D. `WHERE id IN (1, 2, 3)`（id为主键）  
   **答案：B**  
   **解析**：对索引列使用函数（如`YEAR()`）会使优化器无法使用索引。

3. **关于死锁的产生条件，错误的是？**  
   A. 事务A持有锁1并请求锁2，事务B持有锁2并请求锁1  
   B. InnoDB会自动检测死锁并回滚代价较小的事务  
   C. 增大锁等待超时时间（innodb_lock_wait_timeout）可避免死锁  
   D. 死锁仅发生在并发写操作中  
   **答案：C**  
   **解析**：增大超时时间无法避免死锁，仅延迟响应。死锁可能发生在读操作（如共享锁升级）。

---

### **二、简答题**（共4题，每题10分）  
1. **简述InnoDB的B+树索引结构与MyISAM的差异，并说明为何InnoDB推荐使用自增主键。**  
   **答案**：  
   - InnoDB：主键索引为聚簇索引，数据与索引存储在一起；二级索引叶子节点存储主键值。  
   - MyISAM：非聚簇索引，数据与索引分离，索引叶子节点存储数据行地址。  
   - 自增主键优势：插入数据时顺序写入，减少页分裂和碎片，提升写入效率。

2. **解释SQL优化中的“索引下推”（Index Condition Pushdown, ICP）及其适用场景。**  
   **答案**：  
   - **原理**：在存储引擎层直接利用索引过滤数据，减少回表次数。  
   - **场景**：联合索引`(a, b)`，查询条件`WHERE a > 100 AND b LIKE 'abc%'`。  
   - **效果**：引擎层直接过滤`a`和`b`，仅对符合条件的记录回表。

---

### **三、SQL编写题**（共3题，每题15分）  
1. **编写SQL：查询每个部门工资前三高的员工（允许并列）。**  
   ```sql
   WITH Ranked AS (
     SELECT 
       name, department_id, salary,
       DENSE_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rk
     FROM employee
   )
   SELECT name, department_id, salary
   FROM Ranked
   WHERE rk <= 3;
   ```
   **考点**：窗口函数`DENSE_RANK()`处理并列排名。

2. **优化慢查询：大分页场景（`SELECT * FROM orders ORDER BY id LIMIT 1000000, 10`）。**  
   **优化方案**：  
   ```sql
   SELECT o.* 
   FROM orders o
   JOIN (SELECT id FROM orders ORDER BY id LIMIT 1000000, 10) AS tmp
   ON o.id = tmp.id;
   ```
   **解析**：子查询先通过索引定位ID，减少回表数据量。

---

### **四、场景分析题**（共2题，每题20分）  
**场景**：某表结构如下，频繁出现慢查询：  
```sql
CREATE TABLE logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  action VARCHAR(20),
  create_time DATETIME,
  INDEX idx_user (user_id)
);
```
**问题**：查询`SELECT * FROM logs WHERE user_id = 5 AND create_time > '2025-01-01';`执行缓慢。  

**优化方案**：  
1. **添加联合索引**：`ALTER TABLE logs ADD INDEX idx_user_time(user_id, create_time);`  
2. **避免全表扫描**：联合索引覆盖`user_id`和`create_time`，利用索引下推。  
3. **监控效果**：使用`EXPLAIN`确认索引使用情况，避免`Using filesort`或`Using temporary`。

---

### **五、原理深度题**  
**描述InnoDB事务的ACID特性是如何实现的？**  
- **原子性（A）**：通过Undo Log回滚未提交事务。  
- **隔离性（I）**：MVCC + 锁机制（行锁、间隙锁）控制并发可见性。  
- **持久性（D）**：Redo Log保证提交事务的修改持久化（WAL机制）。  
- **一致性（C）**：由A、I、D共同保障。

---

### **答案解析与学习建议**  
1. **索引优化**：关注最左前缀、避免函数操作、合理使用覆盖索引。  
2. **事务与锁**：理解MVCC、隔离级别对锁的影响，掌握死锁排查方法（`SHOW ENGINE INNODB STATUS`）。  
3. **SQL编写**：优先用`JOIN`替代子查询，窗口函数处理复杂分组。  

> 如需扩展练习，可参考：
> - [MySQL经典50题](https://mp.weixin.qq.com/s/17db2238cb04a61a55e9a775d02026ac)   
> - [SQL优化十大案例](https://blog.csdn.net/Java_zhujia/article/details/128094533)