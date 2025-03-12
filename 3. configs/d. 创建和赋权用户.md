# 创建和赋权用户

### 创建新用户

1. **登录到 MariaDB**:
   使用具有足够权限（如 root 用户）的账户登录到 MariaDB：
   ```bash
   mysql -u root -p
   ```

2. **创建新用户**:
   在 MariaDB shell 中，使用 `CREATE USER` 语句来创建一个新用户。你可以指定用户名和主机名（通常为 `'localhost'` 或 `%` 表示所有主机），以及密码。
   
   ```sql
   CREATE USER 'newuser'@'localhost' IDENTIFIED BY 'password';
   ```
   如果你想允许该用户从任何主机连接，可以将 `'localhost'` 替换为 `'%'`：
   ```sql
   CREATE USER 'newuser'@'%' IDENTIFIED BY 'password';
   ```

### 赋予用户权限

3. **授予权限**:
   使用 `GRANT` 语句来赋予用户特定的权限。例如，如果你想给用户 `newuser` 对数据库 `mydatabase` 的所有权限，你可以这样做：
   
   ```sql
   GRANT ALL PRIVILEGES ON mydatabase.* TO 'newuser'@'localhost';
   ```

   如果你想让用户只能进行读取操作（SELECT），则可以这样授予：
   
   ```sql
   GRANT SELECT ON mydatabase.* TO 'newuser'@'localhost';
   ```

   对于更细粒度的控制，你可以分别授予不同的权限，如 `INSERT`, `UPDATE`, `DELETE` 等。

   如果你希望用户 newuser 不仅可以从 localhost 访问数据库，还可以从其他主机访问，你需要将 'newuser'@'localhost' 替换为 'newuser'@'%'。% 是通配符，表示允许从任何主机连接。
   
   ```sql
   GRANT ALL PRIVILEGES ON mydatabase.* TO 'newuser'@'%';
   ```

4. **刷新权限**:
   修改权限后，你需要运行以下命令以确保更改立即生效：
   
   ```sql
   FLUSH PRIVILEGES;
   ```

### 撤销用户权限

5. **撤销权限**:
   如果你之后想要撤销用户的某些权限，可以使用 `REVOKE` 语句。例如，撤销对 `mydatabase` 数据库的所有权限：
   
   ```sql
   REVOKE ALL PRIVILEGES ON mydatabase.* FROM 'newuser'@'localhost';
   ```

6. **删除用户**:
   如果不再需要某个用户，可以使用 `DROP USER` 语句来删除它：
   
   ```sql
   DROP USER 'newuser'@'localhost';
   ```

### 查看用户权限

7. **查看用户权限**:
   若要查看特定用户的权限，可以使用如下命令：
   
   ```sql
   SHOW GRANTS FOR 'newuser'@'localhost';
   ```

### 注意事项

- **安全提示**: 不要轻易给予 `ALL PRIVILEGES`，只赋予用户完成工作所需的最小权限。
- **密码安全**: 确保使用强密码，并根据需要定期更改密码。
- **主机名**: 使用恰当的主机名来限制用户可以从哪些主机连接到数据库，这有助于提高安全性。
