# with-rollup

```sql
-- 创建员工表
CREATE TABLE employees (
    id INT PRIMARY KEY COMMENT '员工ID',
    name VARCHAR(50) COMMENT '员工姓名',
    department VARCHAR(50) COMMENT '所属部门',
    salary DECIMAL(10,2) COMMENT '薪资'
) ENGINE=InnoDB CHARSET=utf8mb4  COMMENT='员工信息表';

-- 插入测试数据
INSERT INTO employees VALUES 
(1, '张三', '技术部', 15000.00),
(2, '李四', '技术部', 18000.00),
(3, '王五', '技术部', 17000.00),
(4, '赵六', '市场部', 12000.00),
(5, '钱七', '市场部', 13000.00),
(6, '孙八', '人事部', 10000.00),
(7, '周九', '人事部', 11000.00);

-- 统计各部门员工数量和薪资总和，并计算总计
SELECT 
    department,
    COUNT(*) as employee_count,
    SUM(salary) as total_salary
FROM employees
GROUP BY department WITH ROLLUP;
```
结果：
```
+------------+----------------+--------------+
| department | employee_count | total_salary |
+------------+----------------+--------------+
| 人事部     |              2 |     21000.00 |
| 市场部     |              2 |     25000.00 |
| 技术部     |              3 |     50000.00 |
| NULL      |              7 |     96000.00 |
+------------+----------------+--------------+
```
加了 WITH ROLLUP 后，结果中多了一行 NULL，表示总计。