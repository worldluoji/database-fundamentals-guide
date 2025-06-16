## docker启动mysql

## 1. 拉取镜像
```bash
docker pull mysql:5.7
```

---

## 2. 启动MySql
```bash
docker run -d -p 3309:3306 -e MYSQL_DATABASE="test" -e MYSQL_USER="luoji" -e MYSQL_PASSWORD="<your_password>" -e MYSQL_ROOT_PASSWORD="<your_root_password>"  --name=mysqlNew2  mysql:5.7 
```
只有第一次需要用这种方式启动。
后续如果重启了docker，直接 
```bash
docker ps -a | grep mysql
```
找到容器ID，然后 
```bash
docker start 容器ID
```

---

## 3. 连接MySql
方法1:进入容器连接：
```bash
[root@kube-master /]# docker ps | grep mysql
0d451592be95   mysql:5.7    
docker exec -ti 0d451592be95 bash
mysql -uroot -p
```

---

方法2:直接在宿主机通过链接
```
mysql -uroot -h服务器地址 -P3309 -p
```
这里一定要注意，宿主机连接，也必须加-h参数。