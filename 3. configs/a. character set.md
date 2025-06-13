# MySQL字符集和校对规则设置

---

### ⚙️ 设置层级与语法
#### 1. 服务器级别  
修改配置文件（`my.cnf` 或 `my.ini`）并重启服务生效：  
```ini
[mysqld]
character-set-server = utf8mb4   # 字符集
collation-server = utf8mb4_unicode_ci  # 校对规则
```
- **作用范围**：新建数据库/表默认继承此配置
- **验证命令**：  
  ```sql
  SHOW VARIABLES LIKE 'character_set_server';
  SHOW VARIABLES LIKE 'collation_server';
  ```

#### 2. 数据库级别  
创建或修改数据库时指定：  
```sql
CREATE DATABASE mydb 
  CHARACTER SET utf8mb4 
  COLLATE utf8mb4_unicode_ci;

ALTER DATABASE mydb 
  CHARACTER SET utf8mb4 
  COLLATE utf8mb4_bin;
```

#### 3. 表级别（最常用）  
```sql
CREATE TABLE orders (
  id INT,
  note VARCHAR(100)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

ALTER TABLE orders 
  CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

#### 4. 列级别（特殊需求）  
```sql
CREATE TABLE users (
  id INT,
  name VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin
);
```

---

### 📊 常用字符集与校对规则
| **类型**       | **推荐值**          | **说明**                                     |
|----------------|---------------------|--------------------------------------------|
| **字符集**     | `utf8mb4`           | 支持完整 Unicode（含 Emoji）               |
| **校对规则**   | `utf8mb4_unicode_ci` | 不区分大小写和口音（如 `e`=`é`）           |
|                | `utf8mb4_bin`       | 二进制比较，区分大小写（如 `A`≠`a`）       |
|                | `utf8mb4_0900_ai_ci`| MySQL 8.0 优化版，更准确的 Unicode 排序  |

> 校对规则后缀含义：  
> - `_ci`：不区分大小写  
> - `_cs`：区分大小写  
> - `_bin`：二进制比较  
> - `_ai`：不区分口音

---

### ⚠️ 关键注意事项
1. **乱码预防**  
   - 确保客户端、连接层、服务端字符集一致
   - 导出/导入数据时检查文件编码

2. **已有数据转换**  
   - 使用 `ALTER TABLE ... CONVERT TO ...` 转换可能失败，需先导出再导入

3. **性能影响**  
   - `_unicode_ci` 比 `_general_ci` 更精确但略慢
   - `_bin` 最快但严格区分字符

4. **版本差异**  
   - MySQL 5.7 默认字符集为 `latin1`
   - MySQL 8.0 默认字符集为 `utf8mb4`

---

### 🔍 操作验证命令
```sql
-- 查看数据库设置
SELECT @@character_set_database, @@collation_database;

-- 查看表设置
SHOW CREATE TABLE orders;

-- 查看列设置
SELECT COLUMN_NAME, CHARACTER_SET_NAME, COLLATION_NAME 
FROM information_schema.COLUMNS 
WHERE TABLE_NAME = 'users';
```

---

### 💎 最佳实践
1. **统一使用 `utf8mb4`**：避免字符存储缺失
2. **校对规则选择**：  
   - 多语言场景 → `utf8mb4_unicode_ci`  
   - 大小写敏感场景 → `utf8mb4_bin`
3. **修改顺序**：服务器级 → 数据库级 → 表/列级
4. **连接层配置**：应用连接时显式指定字符集


--- 

MySQL 中的 `utf8` 和 `utf8mb4` 是两种看似相似但本质不同的字符集，**核心区别在于对 Unicode 字符的完整支持程度**：

---

## uft8 和 utf8mb4

### 🆚 **核心区别对比**
| **特性**                | `utf8` (又称 `utf8mb3`)          | `utf8mb4`                          |  
|-------------------------|---------------------------------|-----------------------------------|
| **最大字节长度/字符**   | 3 字节                          | 4 字节                            |  
| **支持的 Unicode 范围** | 基本多语言平面（BMP）            | 全部 Unicode 字符（含辅助平面）    |  
| **能否存储 Emoji 😊**   | ❌ 不支持                        | ✅ 完整支持（如 😊、❤️、🚀）        |  
| **能否存储生僻汉字**    | ❌ 部分汉字（如 𠀀）存储失败      | ✅ 支持所有 CJK 扩展汉字           |  
| **索引键最大长度限制**  | 191 字符（767 字节 ÷ 4 字节）    | 191 字符（767 字节 ÷ 4 字节）或 <br>升级文件格式后可支持 3072 字节 |

> 📌 **关键结论**：  
> **`utf8mb4` 是 MySQL 对完整 UTF-8 编码的实现，而 `utf8` 仅支持 UTF-8 的子集**。

---

### 🔧 **为什么会出现 `utf8` 的缺陷？**
- MySQL 早期设计（5.5.3 之前）将 `utf8` 定义为 **最长 3 字节** 的字符集（现称 `utf8mb3`）。  
- 这导致它 **无法表示 Unicode 中需要 4 字节编码的字符**（如 Emoji、特殊符号、部分汉字），这些字符属于 **辅助平面（Supplementary Planes）**。

---

### ✅ **升级到 `utf8mb4` 的优势**
1. **完整字符支持**  
   存储所有语言字符、Emoji、数学符号（如 ∀、∃）、货币符号（如 💰）等。

2. **兼容现代应用**  
   避免用户输入 Emoji 时变成 `???` 或乱码（如 `ðŸ˜Š`），提升移动端/社交应用兼容性。

3. **未来扩展性**  
   支持 Unicode 标准的新增字符（如 14.0 新增的 838 个字符）。

---

### ⚠️ **升级注意事项**
#### **1. 版本要求**
- **最低 MySQL 版本**：5.5.3（2010 年发布）  
- **建议版本**：≥ MySQL 5.7（优化空间占用和性能）

#### **2. 索引长度限制**
- **InnoDB 表**：  
  - 使用 `ROW_FORMAT=COMPACT` 或 `REDUNDANT` 时，索引键最大 **767 字节**：  
    ```sql
    VARCHAR(255) CHARACTER SET utf8mb4  -- 255字符×4字节=1020字节 → ❌超出限制！
    VARCHAR(191) CHARACTER SET utf8mb4  -- 191字符×4字节=764字节 → ✅可用
    ```
  - **解决方案**：  
    - 改用 `ROW_FORMAT=DYNAMIC` 或 `COMPRESSED`（支持 **3072 字节** 索引键）。  
    - 降低索引字段长度（如 `VARCHAR(191)`）。  
    - 前缀索引（`INDEX (column(191))`）。

#### **3. 存储空间**
- 存储 ASCII 字符（1 字节）时，`utf8mb4` 与 `utf8` 占用相同空间。  
- 存储中文（通常 3 字节）和 Emoji（4 字节）时，`utf8mb4` 多占用 33% 空间（但数据完整更重要）。

---

### 📥 **如何迁移到 `utf8mb4`**
1. **修改配置文件** (`my.cnf`/`my.ini`):  
   ```ini
   [mysqld]
   character-set-server = utf8mb4
   collation-server = utf8mb4_unicode_ci
   ```

2. **转换已有数据库**：  
   ```sql
   ALTER DATABASE mydb CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
   ALTER TABLE mytable CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

3. **连接层配置**：  
   确保应用连接串指定字符集（如 JDBC 添加 `useUnicode=true&characterEncoding=UTF-8`）。

---

### 💎 **总结**
- **❌ 停止使用 `utf8`**：它是 MySQL 的历史遗留缺陷实现。  
- **✅ 一律使用 `utf8mb4`**：现代应用强制要求，彻底解决 Emoji 和生僻字符问题。  
- **提前规划索引设计**：避免因长度限制导致结构更改困难。  

> 自 **MySQL 8.0 起**，`utf8mb4` 已成为默认字符集（校对规则为 `utf8mb4_0900_ai_ci`），标志着官方正式淘汰不完整的 `utf8`。