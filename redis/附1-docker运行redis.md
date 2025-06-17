# docker运行redis

## 1. 拉取docker镜像：
```
docker pull redis
```
可以通过
```
docker search redis
```
查看别的版本, 默认就是latest。如无法魔法上网，可以通过https://1ms.run/查询。

## 2. 运行docker
```
docker run -d --name myredis -p 6379:6379 --privileged=true redis
```

## 3.查看运行情况
```
luoji@DESKTOP-MHNTMB3:~/myredis$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
fc391c888d4c        redis:3.2           "docker-entrypoint.s¡­"   6 seconds ago       Up 4 seconds        0.0.0.0:6379->6379/tcp   myredis
```
如果有错误发生，先docker ps -a 查看退出原因，docker logs -f myredis查看日志。

## 4.连接客户端
```
docker exec -it myredis redis-cli
```

补充：docker run 时可以设置密码 --requirepass "123123"重新设置redis密码

如果重新docker run，则需要先docker stop  ,  docker rm
```
docker: Error response from daemon: Conflict. 
The container name "/myredis" is already in use by container "fc391c888d4c0323ad3f9b4ef89bce279ce852808a5a2d8ceedeccff76439946". You have to remove (or rename) that container to be able to reuse that name.
```
protected-mode 是在没有显示定义 bind 地址（即监听全网断），又没有设置密码 requirepass
时，protected-mode 只允许本地回环 127.0.0.1 访问。

也就是说当开启了 protected-mode 时，如果你既没有显示的定义了 bind 监听的地址，同时又没有设置 auth 密码。那你只能通过 127.0.0.1 来访问 redis 服务。

一个常见问题：
```
ERR This instance has cluster support disabled
```
redis.conf中将 cluster-enabled yes放开

---

## reference
https://1ms.run/r/library/redis