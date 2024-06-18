# orderby
## orderby 是怎么工作的
一个例子说明：
```
CREATE TABLE `t` (
  `id` int(11) NOT NULL,
  `city` varchar(16) NOT NULL,
  `name` varchar(16) NOT NULL,
  `age` int(11) NOT NULL,
  `addr` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `city` (`city`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```
name是人的姓名，只为city加了索引，目的是为了加快查询速度
```
select city,name,age from t where city='杭州' order by name limit 1000;
```
处理流程如下：

<img src="./orderby全字段排序.jpg" />

大致是说，先根据city找到所有满足杭州的，然后city,name,age全部放到sort_buffer里面，
再把srot_buffer中内容全部按照name排序，排好后返回前1000行即可。

- 1. 如果sort_buff不足以装下数据，那么就会使用磁盘临时文件，大大降低查询速度。
- 2. SET max_length_for_sort_data = 16;该参数表示单行数据超过16时，sort_buffer就只会保存要排序的列和主键id，这时就需要排好序后，
回行查到其它字段，比如这里的age。

解决方法：加入（city,name）联合索引 
```
alter table t add index city_user(city, name);
```
这样，where city='杭州'后查询出的数据就是天然按name排序的，就不再需要sort buffer了，直接从主键索引id中取到city,name,age到1000行即可
 
<br>

## order by 示例
```
select sh.question_id as survey_log from 
(select question_id, count(*) as show_cnt from SurveyLog
where action = "show"
group by question_id) as sh
left join
(select question_id, count(*) as answer_cnt from SurveyLog
where action = "answer"
group by question_id) as an
on sh.question_id = an.question_id
where an.answer_cnt is not null
order by (an.answer_cnt / sh.show_cnt) desc, sh.question_id asc
limit 0,1
```
可以看到，order by 中可以是计算式，并且可以单独设置某个字段升序还是降