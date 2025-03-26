1. char和varchar的区别
- char是固定长度，char中的n最大长度是255个字符, 如果是utf8编码方式， 那么char类型占255 * 3个字节，存储时字符数没有达到定义的位数，会后面补齐空格入库; 
- varchar是变长的（0-65535字节），没有达到定义的位数，也不会补齐。 

所以char速度更快，但是会浪费空间。

---

2. 存储过程
先编译，再执行。实际就是把sql语句编译后存储在数据库中，这样用户通过指定存储过程名字并给定参数即可执行。明显，存储过程有更快的速度，同时也符合组件化编程的思想。
使用方法详见create_procedure.sql. 

注意：
- Mysql以";"为分隔符，如果没有声明分隔符，则编译器会将存储过程当作SQL语句处理，编译会报错，所以之前delimiter ;;，结束后再还原回delimiter ; 
- 如果有入参，就SET &p_in=1, CALL 存储过程名（@p_in）

---

3. 查看版本，字符集等
```sql
show variables like '%version%';
show variables like 'character_set%';
```

---

4. Mysql允许用关键字作为表名（最好不要）。

例如admin作为表明时，查询这张表要select * from `admin`;比较反人类

---

5. 连接Mysql: mysql -u 用户名 -p -h Mysql服务器所在主机。下面就会让输入密码。

---

6. 什么是STRAIGHT_JOING?

STRAIGHT_JOIN is similar to JOIN, except that the left table is always read before the right table. 
This can be used for those (few) cases for which the join optimizer puts the tables in the wrong order.

例子：
```sql
select * from t1 straight_join t2 on (t1.a=t2.a);
```
则t1是驱动表，t2是被驱动表，如果直接用inner join则编译器不一定按照这个顺序。

注意：STRAIGHT_JOIN只适用于inner join，并不适用于left join，right join。（因为left join，right join已经代表指定了表的执行顺序）

尽可能让优化器去判断，因为大部分情况下mysql优化器是比人要聪明的。

使用STRAIGHT_JOIN一定要慎重，因为啊部分情况下认为指定的执行顺序并不一定会比优化引擎要靠谱。

---

7. explain SQL语句 \G来分析一条SQL语句。 不加\G就是表格形，加了就是列表形式。

---

8. MySql中如果设置了主键值达到了上限，再insert语句是就会报主键冲突的错误，
因此建议尽量将主键类型设置为8个字节的 bigint unsigned（2^64-1）防止那么快达到上限.
如果没有设置primary key，那么mysql会自动生成一个自增的看不到的rowId, 其也是bitint unsigned，但是只用了6个字节。达到上限后就会覆盖原来的行，循环。

---

9. count(*)

MyISAM把一张表的记录总数记到了磁盘上，所以count(*) 查询时直接读取总数的记录就OK了，优点是速度快，但是MyISAM不支持事务的。 

而InnoDB则是一条一条记录取数，目的是为了保证多版本控制（MVVC）时数据的正确性。

InnoDB count(*)性能优化：
- 1）可以单独一张表存放总数，增加时+1，删除时-1；如果使用redis等内存数据库，可能会统计不准确，要求不高时可以使用。
- 2）应该尽量使用`count(*)`, Mysql Innodb做了优化，速度`count(*)`约等于count(1)>count(id)>count(字段)
- 3）根据业务场景优化，比如统计A+B+C三次查询记录的总数，可以在查询记录时把数量一起返回给前端，前端再加起来。
   
---

10.   尽量不要用业务字段作为主键，但有一种情况例外，即典型的K-V场景。

---

11.  MySQL 中 sum 函数没统计到任何记录时，会返回 null 而不是 0，可以使用 IFNULL 函数把 null 转换为 0；
- MySQL 中 count 字段不统计 null 值，COUNT(*) 才是统计所有记录数量的正确方式。
- MySQL 中 =NULL 并不是判断条件而是赋值，对 NULL 进行判断只能使用 IS NULL 或者 IS NOT NULL。

---

12.  表数据量大，增加字段很慢的解决办法
新建一张表，将原表的数据全部插入，将新表重命名。

---

13.  其它常用语句
增加一个age字段，类型是INT(4)
```sql
ALTER TABLE student ADD age INT(4); 
```

---

14.  导出全部数据库
```shell
mysqldump -uroot -p --all-databases > sqlfile.sql
```

---

15.   关于外键约束
在Mysql数据库中，有时会用到外键约束FOREIGN KEY。这些外键约束也可以使用触发器TRIGGER来实现。当然，外键约束和触发器都是不提倡使用的。
因为外键约束和触发器容易给数据库服务器增加额外的负担，造成性能下降。甚至可能造成频发的锁等待或者死锁。

---

16.  MySQL FIND_IN_SET
FIND_IN_SET内置函数，允许您在逗号分隔的字符串列表中查找指定字符串的位置。
例子：
```
mysql> SELECT FIND_IN_SET('y','x,y,z');
+--------------------------+
| FIND_IN_SET('y','x,y,z') |
+--------------------------+
|                        2 |
+--------------------------+
1 row in set
```
如没有查询到则返回0

如需验证特定版本的支持，可直接查阅 MySQL 官方文档 或执行以下命令查询：

```sql
SHOW FUNCTION STATUS LIKE 'FIND_IN_SET';
```

---

17. change password
```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'your_new_password';
```