# id为字符串自动生成
如果你想要实现主键ID作为字符串并且自动生成，你可以使用以下几种方法之一：

1. **UUID() 函数：**
   使用内置的 `UUID()` 函数可以生成一个通用唯一识别名（Universally Unique Identifier）。UUID是一个128位长的数字，通常被显示为36个字符（不包括可能的分隔符）。

   ```sql
   CREATE TABLE my_table (
       id CHAR(36) NOT NULL DEFAULT (UUID()),
       -- other columns...
       PRIMARY KEY (id)
   );
   ```

2. **UUID_SHORT() 函数：**
   如果你希望得到更短的唯一ID，可以考虑使用`UUID_SHORT()`函数。它返回一个基于当前时间戳和服务器ID的整数，但请注意这仍然是一个较大的数字，可能会超过常规INT的范围，因此你可能需要使用BIGINT或将其转换成字符串。

   ```sql
   CREATE TABLE my_table (
       id BIGINT NOT NULL DEFAULT (UUID_SHORT()),
       -- other columns...
       PRIMARY KEY (id)
   );
   ```

3. **触发器和存储过程：**
   你可以创建一个触发器，在插入新记录时自动设置主键值。例如，如果你有一个特定的算法来生成字符串ID，你可以将这个逻辑放在触发器或存储过程中。

   ```sql
   DELIMITER //
   CREATE TRIGGER before_my_table_insert
   BEFORE INSERT ON my_table
   FOR EACH ROW
   BEGIN
       SET NEW.id = your_custom_function_to_generate_id();
   END;//
   DELIMITER ;
   ```

4. **序列（Sequences）：**
   虽然MariaDB/MySql没有直接支持序列对象像一些其他数据库系统那样，但是可以通过表模拟序列行为，并结合触发器来生成自定义格式的字符串ID。

5. **应用层生成：**
   另一种方式是在应用程序代码中生成唯一的字符串ID，然后将其与INSERT语句一起发送到数据库。这种方法可以让你完全控制ID的格式，比如使用类似Twitter Snowflake的分布式ID生成算法。
