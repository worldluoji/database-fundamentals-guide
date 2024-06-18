## docker启动mysql

## 1. 拉取镜像
```
docker pull mysql:5.7
```

## 2. 启动MySql
```
docker run -d -p 3309:3306 -e MYSQL_DATABASE="test" -e MYSQL_USER="luoji" -e MYSQL_PASSWORD="199114" -e MYSQL_ROOT_PASSWORD="199114"  --name=mysqlNew2  mysql:5.7 
```

## 3. 连接MySql
```
[root@kube-master /]# docker ps | grep mysql
0d451592be95   mysql:5.7    
docker exec -ti 0d451592be95 bash
mysql -uroot -p
```

或者其它机器已经安装号了MySql
直接通过
```
mysql -uroot -h服务器地址 -P3309 -p
```
连接


如果是mariadb, 使用
```
docker search mariadb 
```
搜索mariadb镜像, 将上面镜像替换为mariadb的镜像即可。