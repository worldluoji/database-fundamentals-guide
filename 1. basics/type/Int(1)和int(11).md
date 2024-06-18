# int(M)
在 int(M) 中，M 的值跟 int(M) 所占多少存储空间并无任何关系。
int(3)、int(4)、int(8) 在磁盘上都是占用 4 btyes 的存储空间。
说白了，除了显示给用户的方式有点不同外，int(M) 跟 int 数据类型是相同的。

## M的意义
那么设置int(M)中的M的意义是什么呢？其实设置M得和zerofill结合起来才会生效。
```
CREATE TABLE `test` (
  `id` int(4) unsigned zerofill NOT NULL AUTO_INCREMENT,
   PRIMARY KEY (`id`)
) 
```
注意int(4)后面加了个zerofill，我们先来插入4条数据。
```
mysql> INSERT INTO `user` (`id`) VALUES (1),(10),(100),(1000);
Query OK, 4 rows affected (0.00 sec)
Records: 4  Duplicates: 0  Warnings: 0
```
然后我们来查询下

```
mysql> select * from test;
+------+
| id   |
+------+
| 0001 |
| 0010 |
| 0100 |
| 1000 |
+------+
4 rows in set (0.00 sec)
```
通过数据可以发现 int(4) + zerofill实现了不足4位补0的现象，单单int(4)是没有用的。而且对于0001这种，底层存储的还是1，只是在展示的会补0。