# insert ignore
```sql
-- 创建用户表（如果之前没创建）
CREATE TABLE users (
    id INT PRIMARY KEY COMMENT '用户ID',
    name VARCHAR(50) COMMENT '用户名',
    email VARCHAR(100) COMMENT '邮箱'
) ENGINE=InnoDB CHARSET=utf8mb4  COMMENT='用户信息表';

-- 插入测试数据
INSERT INTO users VALUES 
(1, '张三', 'zhangsan@example.com'),
(2, '李四', 'lisi@example.com');

-- 使用 INSERT IGNORE 插入数据，遇到重复则跳过
INSERT IGNORE INTO users (id, name, email) 
VALUES 
(1, '张三', 'zhangsan@example.com'),
(3, '王五', 'wangwu@example.com');
```
在处理批量导入数据时，遇到重复数据直接跳过，不会报错，让程序继续运行。