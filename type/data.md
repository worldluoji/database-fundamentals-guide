# date
日期、时间类型比较比较的是时间戳，即long型;

当涉及日期类型、时间类型和字符串类型比较时，会先将字符串转换成日期、时间类型，然后进行比较；

例如: date_col < "2020-09-01" ,date_col是date类型，在比较时，会自动先将"2020-09-01"转换成date类型，然后再比较。
如果你要查询2013年1月份加入的产品：
```
select * from product where Date(add_time) between '2013-01-01' and '2013-01-31'
```
--你还可以这样写：
```
select * from product where Year(add_time) = 2013 and Month(add_time) = 1
```

<br>

## 【常用日期和时间处理函数】
```
AddDate（）：增加一个日期（天、周等）
AddTime（）：增加一个是时间（时、分等）
Now（）：返回当前日期和时间
CurDate（）：返回当前日期
CurTime（）：返回当前时间
Date（）：返回日期时间的日期部分
DateDiff（）：计算两个日期之差
-语法: datediff(string enddate, string startdate)。返回结束日期减去开始日期的天数
Date_Add（）：高度灵活的日期运算函数
Date_Sub(): 返回两个日期之间的间隔
-语法: date_sub (string startdate, int days)。 返回开始日期startdate减少days天后的日期。
Date_Format（）：返回一个格式化的日期或时间串
DayOfWeek（）：对于一个日期，返回对应的星期几，显示的一周是从周日开始周六结束，其中周日为1，周六为7
WeekDay(): 对于一个日期,返回对应的星期几，显示的一周是从周一开始周日结束，其中周一为0，周日为6
Time（）：返回一个日期时间的时间部分
Year（）：返回一个日期的年份部分
Month（）：返回一个日期的月份部分
Day（）：返回一个日期的天数部分
Hour（）：返回一个时间的小时部分
Minute（）：返回一个时间的分钟部分
Second（）：返回一个时间的秒数部分
```

<br>


## 【日期函数转换】
1.	UNIX时间戳转日期函数: （时间戳->日期）
- from_unixtime
- 语法: from_unixtime(bigint unixtime[, string format])。
- 转化UNIX时间戳（从1970-01-01 00:00:00 UTC到指定时间的秒数）到当前时区的时间格式

2. 获取当前UNIX时间戳函数：（当前时间戳）
- unix_timestamp
- 语法: unix_timestamp()。
- 获得当前时区的UNIX时间戳

3. 日期转UNIX时间戳函数:（日期->时间戳）
- unix_timestamp
- 语法: unix_timestamp(string date)。
- 转换格式为"yyyy-MM-dd HH:mm:ss"的日期到UNIX时间戳。如果转化失败，则返回0。

4. 指定格式日期转UNIX时间戳函数:（指定日期格式化->时间戳）
- unix_timestamp
- 语法: unix_timestamp(string date, string pattern)。
- 转换pattern格式的日期到UNIX时间戳。如果转化失败，则返回0。

<br>

## 【日期格式化】
DATE_FORMAT() 函数用于以不同的格式显示日期/时间数据

【日期、时间戳、字符串互转】涉及函数：
- date_format(date,format)
- unix_timestamp()
- str_to_date(str,format)
- from_unixtime(unix_timestamp,format)
  
### 1) 时间->字符串
date_format(now(0,"%Y-%m-%d")

### 2) 时间->时间戳
unix_timestamp(now())

### 3) 字符串-> 时间
str_to_date("2016-01-02","%Y-%m-%d %T")

### 4) 字符串-> 时间戳
unix_timestamp("2020-08-01")

### 5) 时间戳-> 时间
from_unixtime(1592755199)

### 6) 时间戳-> 字符串
from_unixtime(1592755199,"%Y-%m-%d")

<br>

## 【时间差函数】-timestampdiff、timediff、datediff
1.timestampdiff
- 语法：timestampdiff(interval, startDateTime,endDateTime)
- 结果：返回（endDateTime-startDateTime）的时间差，结果单位由interval参数给出。
- interval 参数：
```
•	frac_second 毫秒（低版本不支持，用second，再除于1000）
•	second 秒
•	minute 分钟
•	hour 小时
•	day 天
•	week 周
•	month 月
•	quarter 季度
•	year 年
```

<br>

2. timediff
- 语法：timediff( Date1, Date2)
- 结果：返回DAY天数，Date1-Date2 的天数值，结果单位为day

<br

3. datediff
- 语法：timediff(time1,time2)
- 结果：返回两个时间相减得到的差值，time1-time2,结果单位为Time类型

<br>

## 【案例-常用日期和时间处理函数】
```
select ADDDATE(NOW(),INTERVAL 1 DAY)
select ADDTIME(NOW(),"10:10:10")
select Now()
select CURDATE()
select CurTime()
select CURRENT_DATE()
select CURRENT_TIME()
select CURRENT_TIMESTAMP()
select DATE(now())
select DATEDIFF("2020-08-01","2020-08-20")
select DATE_ADD(NOW(),INTERVAL 1 DAY)
select DATE_FORMAT(NOW(),"%Y-%m-%d"),DATE_FORMAT(NOW(),"%y-%M-%D %T")
select DAYOFWEEK("2020-09-21"),WEEKDAY("2020-09-21")
select TIME(now())
select YEAR(now())
select month(now())
select DAY(now())
select Hour(now())
select Minute(now())
select second(now())
```


