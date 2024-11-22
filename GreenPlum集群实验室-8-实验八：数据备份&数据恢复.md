# GreenPlum集群实验室-6

> Author ：Heike07

[TOC]

## 实验八：数据备份&数据恢复

### 数据SQL操作

#### Pg_dump导出数据SQL

##### 导出单个数据库中的单个表

###### 数据选择

![image-20241122113459960](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241122113459960.png)

![image-20241122113513175](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241122113513175.png)

我们选择这个员工信息表作为导出的数据

###### 执行语句导出

```powershell
# 数据导出
[gpadmin@Master-a ~]$ mkdir output_sql
[gpadmin@Master-a ~]$ cd output_sql/
[gpadmin@Master-a output_sql]$ ls
[gpadmin@Master-a output_sql]$

# 单表导出
[gpadmin@Master-a output_sql]$ pg_dump -h Master-a -p 5432 -U gpadmin -d test_database -t public.employees7 -f employees7.sql
```

###### 分析导出SQL

导出文件可在同级图片文件目录查看

![image-20241122114451255](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241122114451255.png)

数据库设置部分 对导出的环境的设置进行导出

![image-20241122114532220](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241122114532220.png)

建表和权限部分，可以看到创建了一个表，并设置分布键为id用于分布式存储唯一键值，并设置账户权限为gpadmin用户

![image-20241122114627408](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241122114627408.png)

表字段的注释，这是在创建表的时候带入的，可以看到也是很完整的输出出来

![image-20241122114844918](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241122114844918.png)

创建了一个序列，并将序列设置好了相应的用户权限，关联序列和表的列，设置列的默认值nextval('public.employees7_id_seq'::regclass)，为每次插入新行都会从employees7_id_seq序列中取下一个值作为id的默认值

![image-20241122115140698](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241122115140698.png)

对上述字段通过COPY整合形成数据，更加直观而不像mysql的都是insert插入语句，直观清晰，好评！

![image-20241122115500370](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241122115500370.png)

###### 小结

copy最后一行的插入结束标识，更新序列当前值为100，增加主键约束，并设置主键不能为空，限制此操作只应用于当前表不影响继承表。

通过分析导出的sql文件可以看到，整体上导出的sql还是比较清楚明了的。

##### 导出单个数据库中的全部表

###### 数据选择

```sql
/* 创建临时表 */
CREATE TEMP TABLE temp_table_counts (
    schema_name TEXT,
    table_name TEXT,
    row_count BIGINT
);

/* 动态插入数据 */
DO $$
DECLARE
    tbl RECORD;
BEGIN
    FOR tbl IN 
        SELECT 
            n.nspname AS schema_name, 
            c.relname AS table_name 
        FROM 
            pg_class c 
        JOIN 
            pg_namespace n ON n.oid = c.relnamespace
        WHERE 
            c.relkind = 'r' 
            AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'gp_toolkit')
    LOOP
        EXECUTE format(
            'INSERT INTO temp_table_counts (schema_name, table_name, row_count) 
             SELECT %L, %L, count(*) FROM %I.%I',
            tbl.schema_name, 
            tbl.table_name, 
            tbl.schema_name, 
            tbl.table_name
        );
    END LOOP;
END $$;

/* 查询临时表结果 */
SELECT * FROM temp_table_counts ORDER BY row_count DESC;
```

![image-20241122133228762](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241122133228762.png)

通过构建数据语句可以看到准备导出sql的数据全部表数据量为5亿、500w、100条若干等。

###### 执行语句导出

![image-20241122134023471](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241122134023471.png)

```powershell
[gpadmin@Master-a output_sql]$ pg_dump -h Master-a -p 5432 -U gpadmin -d test_database -F p -f test_database.sql
[gpadmin@Master-a output_sql]$ ll -h
total 1.9G
-rw-rw-r-- 1 gpadmin gpadmin  12K Nov 22 11:39 employees7.sql
-rw-rw-r-- 1 gpadmin gpadmin 1.9G Nov 22 13:40 test_database.sql
[gpadmin@Master-a output_sql]$
```

###### 分析导出SQL

这个文件过大就不拿出来了，就在linux中分析

```powershell
# 确认数据不为空
[gpadmin@Master-a output_sql]$ wc -l test_database.sql 
55001499 test_database.sql
[gpadmin@Master-a output_sql]$

[gpadmin@Master-a output_sql]$ head test_database.sql 
--
-- Greenplum Database database dump
--

SET gp_default_storage_options = '';
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
[gpadmin@Master-a output_sql]$

# 分析文件
# 先分析数据库中表是否存在
```

![image-20241122134518014](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241122134518014.png)

前面都和其他的都一样，我们看下数据部分 直接搜索COPY

![image-20241122134855772](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241122134855772.png)

根据之前查看的结果那行数应该大于5亿，查看一下

![image-20241122135003185](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241122135003185.png)

有意思的点，只有5千万，而数据有5亿

![image-20241122135108326](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241122135108326.png)

按照COPY来说，应该大于才对啊？

```sqlite
-- 最大数据条数
50000000
-- SQL文件行数
55001499
-- 数据row(sum)条数
55000700

由此可得
-799
多出来的就是构建语句和空格等
那就对了！
```

#### Psql导出数据SQL

#### 数据SQL导入

### 数据库备份

#### 使用gpcrondump备份

#### 使用gpdbrestore恢复







