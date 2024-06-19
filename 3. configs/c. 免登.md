# MySql免登
在控制台连接数据库，需要每次输入账号密码，感觉很麻烦，偶然发现可以通过login-path保存信息，实现快捷登录，这里记录下。

保存账号信息
```
mysql_config_editor set --login-path=test --user=root  --host=127.0.0.1 --port=3306 --password
```
点击回车，会要求输入密码，这里的密码会被加密保存。

查看配置的数据库快捷登陆账号列表
```
mysql_config_editor print -all
```
删除配置
```
mysql_config_editor remove --login-path=test
```
登陆数据库
```
mysql --login-path=test
```

`mysql --login-path=test << EOF`

在Shell脚本中，`<< EOF` 是一种称为"Here Document"（这里的文档）的特殊语法，用于输入多行文本或命令。它允许你传递一大段文本或一系列命令给前面的命令，直到遇到指定的结束标记（在这里是 `EOF`，但实际上可以是任何你选择的标记，只要保持前后一致即可）。

具体到你的例子 `mysql --login-path=test << EOF`，这意味着接下来的内容（直到遇到另一个 `EOF`）都将作为输入传递给 `mysql` 命令，使用名为 `test` 的登录路径连接到MySQL数据库服务器。这种方式非常适合编写包含多条SQL命令的脚本，因为你可以直接在脚本中编写SQL语句，而不需要为每一行SQL都单独运行一次 `mysql` 命令。

例如：

```bash
mysql --login-path=test << EOF
CREATE DATABASE my_new_database;
USE my_new_database;
CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(255), email VARCHAR(255));
EOF
```

在这个脚本中，从 `CREATE DATABASE` 到最后的 `EOF` 之间所有的文本都会作为SQL命令一次性发送给MySQL服务器执行。这样可以简化脚本的编写，提高效率，同时也使得代码更加整洁易读。