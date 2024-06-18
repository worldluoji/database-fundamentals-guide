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