# character set
在日常处理客户的问题中，会遇到非常多的客户反馈字符乱码的问题，遇到这类型的问题，我们要怎么去处理呢？又该怎么去引导用户去解决呢？

下面针对mysql字符集以及校对规则做一个详细的介绍说明，针对MYSQL字符集，将从两个方面介绍：
- 第一部分：MYSQL字符集和校对规则是什么以及如何正确的使用字符集；
- 第二部分：MySQL字符编码转换原理以及字符集转化流程案例测试。

## 一、字符集(Character set)
字符集是指多个字符(英文字符，汉字字符，或者其他国家语言字符)的集合，字符集种类较多，每个字符集包含的字符个数不同。

特点：
- ①字符编码方式是用一个或多个字节表示字符集中的一个字符
- ②每种字符集都有自己特有的编码方式，因此同一个字符，在不同字符集的编码方式下，会产生不同的二进制

常见字符集：
- ASCII字符集：基于罗马字母表的一套字符集，它采用1个字节的低7位表示字符，高位始终为0。
- LATIN1字符集：相对于ASCII字符集做了扩展，仍然使用一个字节表示字符，但启用了高位，扩展了字符集的表示范围。
- GBK字符集：支持中文，字符有一字节编码和两字节编码方式。
- UTF8字符集：Unicode字符集的一种，是计算机科学领域里的一项业界标准，支持了所有国家的文字字符，utf8采用1-4个字节表示字符。

<br>

## 1、MySQL与字符集
MySQL服务器可以支持多种字符集，不同的库，不同的表和不同的字段都可以使用不同的字符集。

MySQL中的字符集都<strong>对应着一个默认的校对规则（COLLATION）</strong>，当然一个字符集也可能对应多个校对规则，但是两个不同的字符集不能对应同一个规则。
校对规则不指定就是使用默认的，比如utf8字符集对应的默认校对规则就是utf8_general_ci。

<strong>校对规则后缀如_cs，_ci，_bin，分别表示是大小写相关/大小写无关/以字符串编码的二进制值来比较大小</strong>。
例如：在校对规则“utf8_general_ci”下，字符“a”和“A”是等价的，就是不区分大小写。
如果比较的两个字符集不同，则MySQL在比较前会先将其转换到同一个字符集再比较，如果两个字符集不兼容，则会报错Illegal mix of collations.

MySQL系统变量值：
```
show variables like '%char%';
+--------------------------+----------------------------------+
| Variable_name            | Value                            |
+--------------------------+----------------------------------+
| character_set_client     | utf8                             |
| character_set_connection | utf8                             |
| character_set_database   | utf8mb4                          |
| character_set_filesystem | binary                           |
| character_set_results    | utf8                             |
| character_set_server     | utf8mb4                          |
| character_set_system     | utf8                             |
| character_sets_dir       | /usr/local/mysql/share/charsets/ |
+--------------------------+----------------------------------+
```
相关参数说明：

- character_set_client 服务器使用character_set_client变量作为客户端发送的SQL语句中使用的字符集。
- character_set_connection 连接层字符集，服务器使用系统变量character_set_connection和collation_connection。它把客户端传来的语句，从character_set_client字符集转换成character_set_connection字符集（除非字符串中有类似_latin1或者_utf8的字符集声明）。collation_connection对于字符串的比较是非常重要的。对于字符类型的字段值的比较，collation_connection是不起作用的。因为字段有自己的collation，有更高的优先级。
- character_set_system 系统元数据(字段名等)字符集。
- character_set_serve 用于存储标识符的服务器所使用的字符集。
- character_set_results 系统变量表明了服务器返回查询结果时使用的字符集。返回的数据，有比如字段的值和元数据（例如字段名）。
- character_set_database 默认数据库使用的字符集，该服务器在默认数据库更改时设置此变量。
- character_set_filesystem 文件系统字符集。这个变量是用来解释字符串引用的文件名，如在LOAD DATA INFILE和选择…为导出的文件报表和load_file()功能。这样的文件名转换为character_set_filesystem character_set_client之前打开文件的尝试时。默认值是二进制的，这意味着不发生转换。在多字节的文件名是允许的系统，不同的价值可能更合适。例如，如果系统是文件名使用UTF-8，集character_set_filesystem来为utf8。
   
<br>

## 二、校对规则collation校对
查看数据库支持的所有字符集(charset)：
```
mysql> show character set;
```
查看数据库支持的所有校对规则
```
mysql> show collation;
```
查看当前字符集和校对规则设置
```
mysql> show variables like ‘collation_%’;
```
以collation_开头的都是用来做列校对规则的。

```
show variables like '%collation%';
+----------------------+--------------------+
| Variable_name        | Value              |
+----------------------+--------------------+
| collation_connection | utf8_general_ci    |
| collation_database   | utf8mb4_general_ci |
| collation_server     | utf8mb4_general_ci |
+----------------------+--------------------+
```
校对规则(collation)：

是在字符集内用于字符比较和排序的一套规则，比如有的规则区分大小写，有的则无视。

校对规则特征：
- ①两个不同的字符集不能有相同的校对规则；
- ②每个字符集有一个默认校对规则；
- ③存在校对规则命名约定：以其相关的字符集名开始，中间包括一个语言名，并且以_ci（大小写不敏感）、_cs（大小写敏感）或_bin（二元）结束。

注意：<strong>系统使用utf8字符集，若使用utf8_bin校对规则执行SQL查询时区分大小写，
使用utf8_general_ci不区分大小写(默认的utf8字符集对应的校对规则是utf8_general_ci)</strong>。

<br>

## 三、四个层次的字符集设置
下面以MySQL中字符集和校对规则的继承规则进行四个层次的字符集设置（服务器、数据库、表、列）。

1、安装MySQL时使用了一个默认的服务器字符集，这个字符集是Latin1。

2、编译MySQL时可以手动指定一个默认服务器字符集和校对规则，参数为：
```
cmake . -DDEFAULT_CHARSET=latin1 -DDEFAULT_COLLATION=latin1_german1_ci
```
3、安装完成后可以在配置文件my.cnf中指定一个默认的服务器字符集，如果没有指定这个值则继承编译时指定的，参数为：
```
character_set_server = utf8
```
4、启动Mysqld时可以在命令行参数中指定一个默认的字符集和校对规则，如果没有指定这个值则继承配置文件中的配置，参数为：
```
mysqld --character-set-server=latin1 --collation-server=latin1_swedish_ci
```
5、启动数据库后可以设置服务器字符集和校对规则，如果不设置就继承Mysqld进程启动时使用的字符集和校对规则，操作变量为：
```
SET character_set_server=utf8;SET collation_server=utf8;
```
6、可以选择设置数据库字符集和校对规则，如果不设置就继承服务器字符集和校对规则，操作变量为：
```
SET character_set_database =utf8;SET collation_database=utf8;
```
7、创建一个新的数据库时可以指定字符集和校对规则，否则继承服务器字符集和校对规则，语句为：
```
CREATE DATABASE db_name CHARACTER SET utf8 COLLATE utf8_general_ci;
```
8、创建一张新的表时可以指定字符集和校对规则，否则继承数据库字符集校对规则，语句为：
```
CREATE TABLE t1(id int) CHARACTER SET 'utf8' COLLATE 'utf8_general_ci';
```
9、创建一个字段时可以指定字符集和校对规则，否则继承表字符集和校对规则，语句为：
```
CREATE TABLE t2(col1 CHAR(10) CHARACTER SET utf8 COLLATE utf8_unicode_ci) CHARACTER SET latin1 COLLATE latin1_bin;
```
另外还可以通过db.opt文件来修改当前库字符集，因为每一个库创建之后都会生成一个db.opt文件，而这个文件中保存着数据库的默认字符集和校对规则。
```
default-character-set=utf8default-collation=utf8_general_c
```
10、修改表字符集和排序规则（会重新组织数据）
```
ALTER TABLE tn1 CONVERT TO CHARACTER SET 'utf8' COLLATE 'utf8_general_ci';
```
PS：如果想修改数据库、表、列的字符集，可以使用ALTER语句来修改；

<br>

## 四、如何正确使用字符集
1.库、表、列字符集的由来
- ①建库时，若未明确指定字符集，则采用character_set_server指定的字符集。
- ②建表时，若未明确指定字符集，则采用当前库所采用的字符集。
- ③新增时，修改表字段时，若未明确指定字符集，则采用当前表所采用的字符集。

<br>

2.更新、查询涉及到得字符集变量
- 更新流程字符集转换过程：character_set_client–>character_set_connection–>表字符集。
- 查询流程字符集转换过程：表字符集–>character_set_result

<br>

3.character_set_database

当前默认数据库的字符集，比如执行use xxx后，当前数据库变为xxx，若xxx的字符集为utf8，那么此变量值就变为utf8(供系统设置，无需人工设置)。

<br>

4.MySQL客户端与字符集

### （1）对于输入来说：

客户端使用的字符集必须通过character_set_client、character_set_connection体现出来：
- ①在客户端对数据进行编码（Linux：utf8、windows：gbk）
- ②MySQL接到SQL语句后(比如insert)，发现有字符，询问客户端通过什么方式对字符编码：客户端通过character_set_client参数告知MySQL客户端的编码方式(所以此参数需要正确反映客户端对应的编码)
- ③当MySQL发现客户端的client所传输的字符集与自己的connection不一样时，会将client的字符集转换为connection的字符集
- ④MySQL将转换后的编码存储到MySQL表的列上，在存储的时候再判断编码是否与内部存储字符集（按照优先级判断字符集类型）上的编码一致，如果不一致需要再次转换

### （2）对于查询来说：

客户端使用的字符集必须通过character_set_results来体现，服务器询问客户端字符集，通过character_set_results将结果转换为与客户端相同的字符集传递给客户端。
(character_set_results默认等于character_set_client)

建议：
<strong>
```
1. 在初始化数据库实例的时候最好选择好字符集，
2. 开发程序的字符集，数据库的字符集，客户端的字符集都保持一致。
```
这样就可以会避免在转码的过程中出现乱码的问题。
</strong>