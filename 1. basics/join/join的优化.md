# join的优化

1. NLJ和BNL

表的创建和数据参考create_procedure.sql

```sql
explain select * from t1 straight_join t2 on t1.a=t2.a;
```
执行结果：
```
MySQL [test]> explain select * from t1 straight_join t2 on t1.a=t2.a \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t1
   partitions: NULL
         type: ALL
possible_keys: a
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 100
     filtered: 100.00
        Extra: Using where
*************************** 2. row ***************************
           id: 1
  select_type: SIMPLE
        table: t2
   partitions: NULL
         type: ref
possible_keys: a
          key: a
      key_len: 5
          ref: test.t1.a
         rows: 1
     filtered: 100.00
        Extra: NULL
2 rows in set, 1 warning (0.003 sec)
```
可以看到ref一栏t2表似乎用了a上添加的索引。实际是把t1表中的a遍历，然后去t2表中根据索引查a,找到匹配的，所以速度就很快了。这个过程在Mysql中叫做Index Nested-Loop Join(NLJ).

结论1：在被驱动表（上面的t2）可以使用上索引的情况下：
- 1）. 使用Join语句要用小表做驱动表 
- 2）. 使用Join语句比直接使用多个单表查询语句性能好。

JOIN类型的约束​：
- LEFT JOIN：​左表必为驱动表​（返回所有左表记录）。
- RIGHT JOIN：右表必为驱动表。
- INNER JOIN：优化器自由选择驱动表

示例：
```sql
explain select * from t2 inner join t1 on t2.a=t1.a \G;
```
结果：
```
MySQL [test]> explain select * from t2 inner join t1 on t2.a=t1.a \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t1
   partitions: NULL
         type: ALL
possible_keys: a
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 100
     filtered: 100.00
        Extra: Using where
*************************** 2. row ***************************
           id: 1
  select_type: SIMPLE
        table: t2
   partitions: NULL
         type: ref
possible_keys: a
          key: a
      key_len: 5
          ref: test.t1.a
         rows: 1
     filtered: 100.00
        Extra: NULL
2 rows in set, 1 warning (0.002 sec)
```
上面虽然把t2表写在了前面，但是因为t1表数据只有t2表的1/10，因此优化器将t1表作为驱动表。

---

```sql
explain select * from t1 straight_join t2 on (t1.a=t2.b) \G;
```
结果如下：
```
MySQL [test]> explain select * from t1 straight_join t2 on (t1.a=t2.b) \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t1
   partitions: NULL
         type: ALL
possible_keys: a
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 100
     filtered: 100.00
        Extra: NULL
*************************** 2. row ***************************
           id: 1
  select_type: SIMPLE
        table: t2
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 1000
     filtered: 10.00
        Extra: Using where; Using join buffer (Block Nested Loop)
```
这一次由于b上没有索引，可以看到使用了join buffer,过程是先把t1的数据a放到join buffer中，再遍历t2的数据b进行比较，选出满足的。这个过程对应了Block Nested-Loop Join(BNL)算法，虽然都是全盘扫描，但是使用了内存join buffer, 所以速度也不慢。 

但是这时候不建议使用了，因为两张表都进行了全盘扫描，会占用大量的系统资源。

结论2：
- 1）可以使用join语句，但是如果explain出来出现了Block Nested就不建议使用了 
- 2）使用join语句要使用小表作为驱动表，所谓的小表，就是说通过过滤条件后，总数据量少的表。
```sql
select * from t1 straight_join t2 on (t1.b=t2.b) where t2.id<=50;
select * from t2 straight_join t1 on (t1.b=t2.b) where t2.id<=50;这时候t2是小表
```

---

## BNL的优化策略
- 1）加索引转化为NLJ
- 2）不适合加索引的情况，分析业务场景，通过临时表或者后端业务代码提升性能

例：还是使用create_procedure1.sql
```
select * from t1 join t2 on (t1.b=t2.b) where t2.b>=1 and t2.b<=2000; 由于t2有100万条记录，b如果没有索引，使用BNL要去查1000*1000000次，速度很慢，要查询一分钟左右；
```
如果加上索引，数据量那么大，索引又会很耗资源。有没有两全其美的方法呢：
```
create temporary table temp_t(id int primary key, a int, b int, index(b))engine=innodb;
insert into temp_t select * from t2 where b>=1 and b<=2000;
select * from t1 join temp_t on (t1.b=temp_t.b);
```
虽然查了两次表，还创建了临时表，但是t2 100万这次由于通过where过滤了，实际速率很快。
实际中，临时表也可以是我们Java,Go的后端代码，比如先查询t2后放到set保存，再去查t1，最后在业务代码里整合。

---

## MRR优化查询思路
简单说：MRR 通过把「随机磁盘读」，转化为「顺序磁盘读」，从而提高了索引查询的性能。

大多数数据都是按照主键递增的顺序插入的，可以认为查询时也按照主键递增的顺序查询，对磁盘的读接近顺序度，速度会更快。
MRR首先通过索引去查询到主键id, 然后将id排序后，通过主键id去回查数据。

---

## BKA（Batch key access）优化
在使用NLJ算法时，也使用join buffer, 一次性将t1的多个值传给t2

例：使用create_procedure1.sql

启用BKA:
```
set optimizer_switch='mrr=on,mrr_cost_based=off,batched_key_access=on';
select * from t1 straight_join t2 on (t1.a=t2.a);
```
另外，BKA是依赖于MRR算法的。