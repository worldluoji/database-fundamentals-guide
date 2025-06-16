
# json
-- 创建用户偏好表，使用 JSON 类型存储灵活配置
```sql
CREATE TABLE user_preferences (
    id INT PRIMARY KEY COMMENT '主键ID',
    user_id INT COMMENT '用户ID',
    preferences JSON COMMENT '用户偏好设置（JSON格式）'
)ENGINE=InnoDB  CHARSET=utf8mb4  COMMENT='用户偏好表';
```

-- 插入测试数据
```sql
INSERT INTO user_preferences VALUES 
(1, 1, '{"theme": "dark", "notifications": true, "fontSize": 14}'),
(2, 2, '{"theme": "light", "notifications": false, "fontSize": 16}'),
(3, 3, '{"theme": "dark", "notifications": true, "fontSize": 12}');
```

-- 查询 JSON 数据
```sql
SELECT preferences->'$.theme' as theme FROM user_preferences WHERE user_id = 1;
```

---

MySQL 5.7.44已经支持JSON数据类型。
```
MySQL [test]> select version();
+-----------+
| version() |
+-----------+
| 5.7.44    |
+-----------+
```