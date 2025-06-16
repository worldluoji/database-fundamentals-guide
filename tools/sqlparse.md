# sqlparse

### 🔍 **一、sqlparse 是什么？**  
**核心定位**：非验证性 SQL 解析库（不检查语法正确性，仅解析结构）  
**核心能力**：  
- **词法/语法分析**：将 SQL 拆解为 Token（关键字、标识符、操作符等）并生成抽象语法树（AST）  
- **SQL 格式化**：重新缩进、统一关键字大小写（如全大写）  
- **多语句拆分**：分割由分号分隔的多条 SQL 语句  
- **结构修改**：支持增删改 Token，重构 SQL 语句  

**典型用户**：  
- 开发 IDE 插件（自动补全、语法高亮）  
- 数据库管理工具（SQL 美化、审查）  
- 安全扫描工具（检测 SQL 注入特征）  

---

### ⚙️ **二、安装与基础用法**  
#### 1. **安装**  
```bash
pip install sqlparse  # 支持 Python 3.8+ 
```

#### 2. **核心函数示例**  
- **解析 SQL 结构**：  
  ```python
  import sqlparse
  sql = "SELECT id, name FROM users WHERE age > 18;"
  parsed = sqlparse.parse(sql)[0]  # 解析第一条语句
  for token in parsed.tokens: 
      print(f"类型: {type(token).__name__}, 值: {token.value}")
  ```
  输出示例：  
  ```
  DML: 'SELECT'  
  IdentifierList: 'id, name'  
  Keyword: 'FROM'  
  Identifier: 'users'  
  Where: 'WHERE age > 18'  
  ```

- **格式化 SQL**：  
  ```python
  formatted = sqlparse.format(
      "select * from orders where amount>1000;",
      reindent=True, 
      keyword_case='upper'
  )
  print(formatted)
  ```
  输出：  
  ```sql
  SELECT *
  FROM orders
  WHERE amount > 1000;
  ```

- **拆分多语句**：  
  ```python
  statements = sqlparse.split(
      "DELETE FROM log; INSERT INTO log VALUES (1);"
  )
  # 结果: ['DELETE FROM log', 'INSERT INTO log VALUES (1)']
  ```

---

### 🛠️ **三、高级应用场景**  
#### 1. **提取关键元素**  
- **表名提取**（适用于 SELECT/INSERT）：  
  ```python
  for token in parsed.tokens:
      if isinstance(token, sqlparse.sql.Identifier):
          print(f"表名: {token.get_real_name()}")  # 输出 'users'
  ```

- **字段提取**（SELECT 语句）：  
  ```python
  if parsed.get_type() == 'SELECT':
      for token in parsed.tokens:
          if isinstance(token, sqlparse.sql.IdentifierList):
              for col in token.get_identifiers():
                  print(f"字段: {col.value}")  # 输出 'id', 'name'
  ```

#### 2. **动态修改 SQL**  
```python
# 将表名 users 替换为 customers
for token in parsed.tokens:
    if isinstance(token, sqlparse.sql.Identifier) and token.value == "users":
        token.value = "customers"
print(str(parsed))  # 输出: SELECT id, name FROM customers ...
```

#### 3. **子查询检测**  
```python
has_subquery = any(
    isinstance(token, sqlparse.sql.Parenthesis) 
    for token in parsed.tokens
)
```

---

### ⚠️ **四、注意事项**  
1. **非验证性局限**：  
   - 不验证 SQL 语法是否正确（如 `SELEC * FROM table` 不会报错）  
   - 需结合数据库驱动或执行计划验证实际可行性  

2. **方言兼容性**：  
   - 对 PostgreSQL/MySQL 支持较好，但 NoSQL 或特有语法（如 SQLite 窗口函数）可能解析失败  

3. **性能考量**：  
   - 解析超长 SQL（>10MB）时可能内存溢出，建议分块处理  

---

### 💡 **五、典型应用工具集成**  
| **场景**          | **技术方案**                                  |  
|-------------------|---------------------------------------------|  
| IDE 实时校验       | VS Code 插件 + `sqlparse` 解析 Token      |  
| SQL 审查系统       | 解析后检查敏感操作（如无 WHERE 的 DELETE） |  
| 查询日志分析       | 解析百万级 SQL 日志，提取高频查询模式         |  
| ORM 调试          | 美化 SQLAlchemy 生成的原生 SQL           |  

---

### 📚 **总结**  
`sqlparse` 是 Python 生态中**轻量但强大的 SQL 结构解析工具**，适用于开发辅助、自动化审查和查询分析场景。通过 AST 操作可灵活提取或修改 SQL 元素，但需注意其**不验证执行可行性**的局限，生产环境中建议结合数据库驱动进行二次验证。