
# partition table
分区是一种表的设计模式，通俗地讲表分区是将一大表，根据条件分割成若干个小表。

但是对于应用程序来讲，分区的表和没有分区的表是一样的。
换句话来讲，分区对于应用是透明的，只是数据库对于数据的重新整理。

<br>

## 1. 分区的目的及分区类型
MySQL在创建表的时候可以通过使用PARTITION BY子句定义每个分区存放的数据。
在执行查询的时候，优化器根据分区定义过滤那些没有我们需要的数据的分区，这样查询就可以无需扫描所有分区，只需要查找包含需要数据的分区即可。

分区的另一个目的是将数据按照一个较粗的粒度分别存放在不同的表中。
这样做可以将相关的数据存放在一起，另外，当我们想要一次批量删除整个分区的数据也会变得很方便。

下面简单介绍下四种常见的分区类型：
- RANGE分区：最为常用，基于属于一个给定连续区间的列值，把多行分配给分区。最常见的是基于时间字段。
- LIST分区：LIST分区和RANGE分区类似，区别在于LIST是枚举值列表的集合，RANGE是连续的区间值的集合。
- HASH分区：基于用户定义的表达式的返回值来进行选择的分区，该表达式使用将要插入到表中的这些行的列值进行计算。这个函数可以包含MySQL中有效的、产生非负整数值的任何表达式。
- KEY分区：类似于按HASH分区，区别在于KEY分区只支持计算一列或多列，且MySQL服务器提供其自身的哈希函数。必须有一列或多列包含整数值。
上述四种分区类型中，RANGE分区即范围分区是最常用的。RANGE分区的特点是多个分区的范围要连续，但是不能重叠，默认情况下使用VALUES LESS THAN属性，即每个分区不包括指定的那个值。

<br>

## 2. 分区操作示例
本节内容以RANGE分区为例，介绍下分区表相关的操作。

### 创建分区表
```
mysql> CREATE TABLE `tr` (
      `id` INT, 
      `name` VARCHAR(50),
      `purchased` DATE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8

    PARTITION BY RANGE( YEAR(purchased) ) (
    PARTITION p0 VALUES LESS THAN (1990),
    PARTITION p1 VALUES LESS THAN (1995),
    PARTITION p2 VALUES LESS THAN (2000),
    PARTITION p3 VALUES LESS THAN (2005),
    PARTITION p4 VALUES LESS THAN (2010),
    PARTITION p5 VALUES LESS THAN (2015)
);
```

<br>

### 插入数据
```
mysql> INSERT INTO `tr` VALUES
    (1, 'desk organiser', '2003-10-15'),
    (2, 'alarm clock', '1997-11-05'),
    (3, 'chair', '2009-03-10'),
    (4, 'bookcase', '1989-01-10'),
    (5, 'exercise bike', '2014-05-09'),
    (6, 'sofa', '1987-06-05'),
    (7, 'espresso maker', '2011-11-22'),
    (8, 'aquarium', '1992-08-04'),
    (9, 'study desk', '2006-09-16'),
    (10, 'lava lamp', '1998-12-25');
```
创建后可以看到，每个分区都会对应1个ibd文件。
上面创建语句还是很好理解的，在此分区表中，通过YEAR函数取出DATE日期中的年份并转化为整型，年份小于1990的存储在分区p0中，小于1995的存储在分区p1中，以此类推。
请注意，每个分区的定义顺序是从最低到最高。为了防止插入的数据因找不到相应分区而报错，我们应该及时创建新的分区。

<br>

### 查看某个分区的数据
```
mysql> SELECT * FROM tr PARTITION (p2);

+------+-------------+------------+

| id   | name        | purchased  |

+------+-------------+------------+

|    2 | alarm clock | 1997-11-05 |

|   10 | lava lamp   | 1998-12-25 |

+------+-------------+------------+

2 rows in set (0.00 sec)
```

<br>

### 增加分区
```
mysql> alter table tr add partition(
    PARTITION p6 VALUES LESS THAN (2020)
);

Query OK, 0 rows affected (0.06 sec)
```

<br>


### 拆分分区
```
mysql> alter table tr reorganize partition p5 into(
    partition s0 values less than(2012),
    partition s1 values less than(2015)
);

Query OK, 0 rows affected (0.26 sec)
```

<br>

### 合并分区
```
mysql> alter table tr reorganize partition s0,s1 into ( 
    partition p5 values less than (2015) 
);

Query OK, 0 rows affected (0.12 sec)
```

<br>


### 清空某分区的数据
```
mysql> alter table tr truncate partition p0;

Query OK, 0 rows affected (0.11 sec)
```

<br>

### 删除分区
```
mysql> alter table tr drop partition p1;

Query OK, 0 rows affected (0.06 sec)

```

<br>

### 交换分区

先创建与分区表同样结构的交换表
```
mysql> CREATE TABLE `tr_archive` (
      `id` INT, 
      `name` VARCHAR(50), 
      `purchased` DATE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

Query OK, 0 rows affected (0.28 sec)
```

执行exchange交换分区 
```
mysql> alter table tr exchange PARTITION p2 with table tr_archive;

Query OK, 0 rows affected (0.13 sec)    
```

<br>

## 3.分区注意事项及适用场景
其实分区表的使用有很多限制和需要注意的事项，参考官方文档，简要总结几点如下：
- 分区字段必须是整数类型或解析为整数的表达式。
- 分区字段建议设置为NOT NULL，若某行数据分区字段为null，在RANGE分区中，该行数据会划分到最小的分区里。
- MySQL分区中如果存在主键或唯一键，则分区列必须包含在其中。
- Innodb分区表不支持外键。
- 更改sql_mode模式可能影响分区表的表现。
- 分区表不影响自增列。
  
从上面的介绍中可以看出，分区表适用于一些日志记录表。
这类表的特点是数据量大、并且有冷热数据区分，可以按照时间维度来进行数据归档。
这类表是比较适合使用分区表的，因为分区表可以对单独的分区进行维护，对于数据归档更方便。

<br>

## 4.分区表为什么不常用
在我们项目开发中，分区表其实是很少用的，下面简单说明下几点原因：
- 分区字段的选择有限制。
- 若查询不走分区键，则可能会扫描所有分区，效率不会提升。
- 若数据分布不均，分区大小差别较大，可能性能提升也有限。
- 普通表改造成分区表比较繁琐。
- 需要持续对分区进行维护，比如到了6月份前就要新增6月份的分区。
- 增加学习成本，存在未知风险。

<br>

## 总结：
如果想使用分区表的话，建议提早做好规划，在初始化的时候即创建分区表并制定维护计划，使用得当还是比较方便的，特别是有历史数据归档需求的表，使用分区表会使归档更方便。
当然，关于分区表的内容还有很多，有兴趣的同学可以找找官方文档，官方文档中有大量示例。