# MySql Index
## 1. 为什么使用索引
使用索引其实就是为了加速查询，就像书的目录一样，能够快速定位到我们想要的内容。

---

## 2. 什么是聚簇索引、非聚簇索引和回表？
```sql
create table T(
id int not null primary key auto_increment, 
k int not null, 
name varchar(16),
index (k)
) engine=InnoDB charset=utf8mb4;
```
id是主键，默认有主键索引，主键索引是“聚簇”的，就是说select * from T where id=5, 直接遍历主键id的索引树，就能把id,k,name都查询出来，就像id把k,name都聚集在一起了一样

k是普通索引，普通索引是非聚簇的，就是说select * from T where k=5那么会遍历k的索引树，找到k=5对应的id集合，再通过id索引树搜索一次找到name等其它信息，这个过程称为回表（或回行）

---

## 3. 什么是页分裂，为什么说要尽量使用自增主键？

继续上面的例子，假设ID没有设置auto_increment且ID不连续,ids=(300,500,800)在一个数据页。

这时候插入一个ID为600的数据，如果该数据页未满，需要把800的数据往后移，再插入600的数据；如果该数据已满，根据B+树算法，就会发生页分裂，800会被移动到新申请的数据页上。

显然，页分裂会严重影响性能和空间利用率。其逆过程就是页合并。

设置了auto_increment之后，每次id都是自增1，就不会出现上述需要挪动位置的情况，不会触发叶子节点的分裂，因为每次插入一条数据都是追加操作。

另外，如果主键长度越小，普通索引的叶子节点就越小，普通索引占用的空间也越小。
当然也有适合其它业务字段做主键的情形，那就是典型的KV场景，即只有主键上有索引（且该索引是唯一索引）的情况。

---

## 4. 为什么要重建普通索引？
```sql
alter table T drop index k;
alter table T add index(k);
```
因为重建普通索引可以节省空间。前面说过索引可能因为删除和页分裂等原因导致数据空洞。重建索引时会将数据按顺序插入，这样页的利用率高，数据更加紧凑。

反之如果是主键索引，重建就不合理，因为下面两个语句都会导致数据表的重建。替代语句是alter table T engine=InnoDB.
```sql
alter table T drop primary key;
alter table T add primary key(id);
```

---

## 5. 什么是索引覆盖？
```sql
select ID from T where k=5
```
由于ID已经在索引树上了，这句查询就不需要回表。这就是索引覆盖。

索引覆盖例子:
```sql
CREATE TABLE `tuser` (
  `id` int(11) NOT NULL,
  `id_card` varchar(32) DEFAULT NULL,
  `name` varchar(32) DEFAULT NULL,
  `age` int(11) DEFAULT NULL,
  `ismale` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `id_card_name` (`id_card`，`name`),
  KEY `name_age` (`name`,`age`)
) ENGINE=InnoDB
select name from tuser where id_card='xxxxxxxxxx'
```
根据身份证号查询姓名时，联合索引就让我们使用上了索引覆盖，通过id_card的索引树就能直接拿到name,不需要回表了

---

## 6. 什么是索引的最左前缀原则？

实际是利用了B+树的最左前缀原则。上面的name_age联合索引，在select * from tuser where name='xxx'也能使用到索引。 
但是select * from tuser where age=28就使用不到了。这就是左前缀原则。

所以通过建立name_age联合索引，就不用再为name单独建立索引了，可以少维护一个索引。
```
select name from tuser where name like '张%' and age=10
```
这样也能利用到索引，找到名字“张”起头，age=10的记录

---

## 7.什么是索引下推？
```sql
select * from tuser where name like '张 %' and age=10 and ismale=1;
```
还是只有name_age联合索引，在Mysql5.6及以后，引入了索引下推。
这句查询语句会先匹配name以张开头的且age=10的记录，再回表找id，并且找到ismale=1的记录；
5.6之前没有索引下推，在找到name以张开头的就会回表去查询，这样明显age != 10的也被回表查出来了。

---

## 8.下面的联合索引有必要吗？
```sql
CREATE TABLE `geek` (
  `a` int(11) NOT NULL,
  `b` int(11) NOT NULL,
  `c` int(11) NOT NULL,
  `d` int(11) NOT NULL,
  PRIMARY KEY (`a`,`b`),
  KEY `c` (`c`),
  KEY `ca` (`c`,`a`),
  KEY `cb` (`c`,`b`)
) ENGINE=InnoDB;
```
业务中有查询语句
```sql
select * from geek where c=N order by a limit 1;
select * from geek where c=N order by b limit 1;
```
答：cb联合索引有必要，但是ca联合索引没有必要。
对于
```sql
select ... from geek where c=N order by a
```
走ca,cb索引都能定位到满足c=N主键
而且主键的聚簇索引本身就是按order by a,b排序，无需重新排序。所以ca可以去掉
```sql
select ... from geek where c=N order by b 
```
这条sql如果只有c单个字段的索引，定位记录可以走索引，但是order by b的顺序与主键顺序不一致，需要额外排序

cb索引可以把排序优化掉

--- 

## 9. 分页优化
LIMIT 2 5 : 在原始结果集中，跳过 2 个记录行，并从 第 3 个记录行开始，最多返回 5 个记录行。
LIMIT 5 最多返回 5 个记录行，等效于 LIMIT 0 5
```sql
select * from ORDER_DMEO order by order_no limit 10000, 20; 速度慢
select * from ORDER_DMEO where order_no > (select order_no from ORDER_DMEO order by order_no limit 10000, 1) limit 20; 速度快
```
默认在order_no上加入了索引
第一个语句要扫描所有记录行，按照order_no排序，还要回表取出其它所有信息，再取出其中20行；
第二个语句先用子查询查出起始的那条记录，由于子查询里只查了order_no ，不需要回表，速度很快；外部查询就只需要查询20条记录了。
可以查看order_demo.sql，里面插入了12000行记录
通过explain分析：
```sql
explain select * from ORDER_DMEO order by order_no limit 10000, 20 \G;
           id: 1
  select_type: SIMPLE
        table: ORDER_DMEO
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 12222
     filtered: 100.00
        Extra: Using filesort
```
可以看到第一条语句使用到了filesort，即因为扫描行数太多（1222行），无法直接通过sort_buffer排序，所以用到了磁盘，用到了磁盘效率就大大降低了。

第二条语句，子查询用到了索引，而且只扫描了10001行
```sql
 explain select order_no from ORDER_DMEO order by order_no limit 10000, 1 \G
*************************** 1. row ***************************
           order_no : 1
  select_type: SIMPLE
        table: ORDER_DMEO
   partitions: NULL
         type: index
possible_keys: NULL
          key: order_no_index
      key_len: 147
          ref: NULL
         rows: 10001
     filtered: 100.00
        Extra: Using index
```
 最后外部查询只需要扫描20行即可。
 
---

## 10. 普通索引和唯一索引区别
1). 唯一索引要求字段不能重复，普通索引则没有这个限制。

2). 查询区别：
```sql
select id from T where k=5. 
```
- 普通索引，查找到下一个不满足k=5的才完成查询；
- 唯一索引：因为是唯一的，查到到k=5的后就退出

可以看到对于查询来说，普通索引查询会多一次判断，但性能影响不大。

3). 更新。对于更新来说，当更新一个数据页时，普通索引会使用change buffer。
即当这个数据页在内存中时就直接修改，否则先写到change buffer中（写的是操作），这样就暂时不用先操作磁盘了。这样下次读取数据时，再执行change buffer中的这个操作，这样就保证了数据的一致性。

如果加了唯一索引，每次更新数据时就会校验唯一性，就会将数据从磁盘读取到内存，所以change buffer就使用不上了。

可见change buffer可以提升“写多读少”时候的性能。如果读多写少，由于加了change buffer, 性能反而可能下降。

实践建议​：
- ​优先选普通索引​：若业务允许重复值（如日志表状态码），利用 Change Buffer 提升写入性能。
- ​必须用唯一索引​：需保证数据唯一性时（如用户ID），即使牺牲部分写入性能也要使用。
- ​混合使用​：同一表可同时存在唯一索引（主键/业务键）和普通索引（辅助查询字段）。