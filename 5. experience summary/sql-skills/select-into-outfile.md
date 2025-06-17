# SELECT INTO OUTFILE
`SELECT INTO OUTFILE` 是MySQL中用于将查询结果导出到文件的一个语句。这个功能允许你将数据库查询的结果保存到服务器上的文件中，这对于备份数据、迁移数据或与其他系统共享数据非常有用。基本语法如下：

```sql
SELECT column1, column2, ...
INTO OUTFILE 'file_path'
[CHARACTER SET charset_name]
[FIELDS [TERMINATED BY 'string']
[ENCLOSED BY 'char']
[ESCAPED BY 'char']]
[LINES [TERMINATED BY 'string']
[STARTING BY 'string']];
```

- `column1, column2, ...` 指定你想要导出的列名。
- `'file_path'` 是你希望保存输出文件的路径。注意，该文件会在MySQL服务器上生成，因此你需要有相应的文件系统权限，并且路径应该是MySQL服务器可访问的。
- `[CHARACTER SET charset_name]` 可选，指定字符集。
- `[FIELDS TERMINATED BY 'string']`、`[ENCLOSED BY 'char']`、`[ESCAPED BY 'char']` 分别定义了字段之间的分隔符、字段值的包围符和转义字符，用于控制输出文件的格式。
- `[LINES TERMINATED BY 'string']`、`[STARTING BY 'string']` 控制行的结束符和每行数据前的起始字符。

例如，如果你有一个名为 `employees` 的表，并想将其所有数据导出为CSV格式，可以使用以下命令：

```sql
SELECT * 
INTO OUTFILE '/tmp/employees.csv'
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM employees;
```

请确保MySQL有对指定目录的写权限，并且要注意安全问题，避免将敏感数据暴露在不安全的位置。此外，使用 `INTO OUTFILE` 时，文件路径必须是绝对路径，并且不能指向MySQL的数据目录以外的地方，这是出于安全考虑的限制。