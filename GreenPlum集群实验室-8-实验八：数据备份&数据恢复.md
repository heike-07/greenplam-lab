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

#### 数据SQL导入

##### 数据选择

使用psql的方式对pg_dump生成的sql进行导入，为了确认导入，使用不同的数据库进行导入，即为导入和导出为分别不同的数据库，上面的实验我们导出了单表和单库所有表的数据，我们用这个作为基础来进行sql导入，导入规则是将test_database数据库中的employees7导出的文件导入至test_db数据库中，表的名称变更为backup_employees，其二，我们将test_database数据库全部的导出的sql文件导出至新建一个数据库backup_test_database中进行两个实验。

```powershell
[gpadmin@Master-a output_sql]$ ll
total 1950448
-rw-rw-r-- 1 gpadmin gpadmin      12160 Nov 22 11:39 employees7.sql
-rw-rw-r-- 1 gpadmin gpadmin 1997242656 Nov 22 13:40 test_database.sql
[gpadmin@Master-a output_sql]$
```

##### 单表导入

根据导入规则：将test_database数据库中的employees7导出的文件导入至test_db数据库中，表的名称变更为backup_employees，我们构建语句并修改相应的文件内容。

```powershell
# 创建backup文件夹
[gpadmin@Master-a output_sql]$ mkdir backup
[gpadmin@Master-a output_sql]$ cd backup/

# 复制导入文件
[gpadmin@Master-a backup]$ cp ../employees7.sql backup_employees7.sql
[gpadmin@Master-a backup]$ ll
total 12
-rw-rw-r-- 1 gpadmin gpadmin 12160 Nov 26 16:11 backup_employees7.sql

# 查看表名称为employees命中关联 
[gpadmin@Master-a backup]$ grep employees7 backup_employees7.sql
-- Name: employees7; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
CREATE TABLE public.employees7 (
ALTER TABLE public.employees7 OWNER TO gpadmin;
-- Name: TABLE public.employees7 ; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON TABLE public.employees7 IS '员工信息表，包括姓名、年龄、性别、部门、入职日期、出生日期、地址和薪资等字段。';
-- Name: COLUMN employees7.name; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON COLUMN public.employees7.name IS '员工姓名，以固定格式加随机数生成';
-- Name: COLUMN employees7.age; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON COLUMN public.employees7.age IS '员工年龄，范围在 18 到 60 之间';
-- Name: COLUMN employees7.gender; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON COLUMN public.employees7.gender IS '员工性别，M 代表男性，F 代表女性';
-- Name: COLUMN employees7.department; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON COLUMN public.employees7.department IS '员工部门，如 HR、Engineering、Marketing、Sales';
-- Name: COLUMN employees7.hire_date; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON COLUMN public.employees7.hire_date IS '员工入职日期，随机生成的日期';
-- Name: COLUMN employees7.birth_date; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON COLUMN public.employees7.birth_date IS '员工出生日期，随机生成的日期';
-- Name: COLUMN employees7.address; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON COLUMN public.employees7.address IS '员工地址，随机生成的地址信息';
-- Name: COLUMN employees7.salary; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON COLUMN public.employees7.salary IS '员工薪资，范围在 3000 到 50000 之间';
-- Name: employees7_id_seq; Type: SEQUENCE; Schema: public; Owner: gpadmin
CREATE SEQUENCE public.employees7_id_seq
ALTER TABLE public.employees7_id_seq OWNER TO gpadmin;
-- Name: employees7_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gpadmin
ALTER SEQUENCE public.employees7_id_seq OWNED BY public.employees7.id;
ALTER TABLE ONLY public.employees7 ALTER COLUMN id SET DEFAULT nextval('public.employees7_id_seq'::regclass);
-- Data for Name: employees7; Type: TABLE DATA; Schema: public; Owner: gpadmin
COPY public.employees7 (id, name, age, gender, department, hire_date, birth_date, address, salary) FROM stdin;
-- Name: employees7_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gpadmin
SELECT pg_catalog.setval('public.employees7_id_seq', 100, true);
-- Name: employees7_pkey; Type: CONSTRAINT; Schema: public; Owner: gpadmin; Tablespace: 
ALTER TABLE ONLY public.employees7
    ADD CONSTRAINT employees7_pkey PRIMARY KEY (id);
[gpadmin@Master-a backup]$

# 通过sed进行修改文件
[gpadmin@Master-a backup]$ sed -i 's/employees7/backup_employees7/g' backup_employees7.sql 
[gpadmin@Master-a backup]$ grep employees7 backup_employees7.sql
-- Name: backup_employees7; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
CREATE TABLE public.backup_employees7 (
ALTER TABLE public.backup_employees7 OWNER TO gpadmin;
-- Name: TABLE public.backup_employees7 ; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON TABLE public.backup_employees7 IS '员工信息表，包括姓名、年龄、性别、部门、入职日期、出生日期、地址和薪资等字段。';
-- Name: COLUMN backup_employees7.name; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON COLUMN public.backup_employees7.name IS '员工姓名，以固定格式加随机数生成';
-- Name: COLUMN backup_employees7.age; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON COLUMN public.backup_employees7.age IS '员工年龄，范围在 18 到 60 之间';
-- Name: COLUMN backup_employees7.gender; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON COLUMN public.backup_employees7.gender IS '员工性别，M 代表男性，F 代表女性';
-- Name: COLUMN backup_employees7.department; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON COLUMN public.backup_employees7.department IS '员工部门，如 HR、Engineering、Marketing、Sales';
-- Name: COLUMN backup_employees7.hire_date; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON COLUMN public.backup_employees7.hire_date IS '员工入职日期，随机生成的日期';
-- Name: COLUMN backup_employees7.birth_date; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON COLUMN public.backup_employees7.birth_date IS '员工出生日期，随机生成的日期';
-- Name: COLUMN backup_employees7.address; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON COLUMN public.backup_employees7.address IS '员工地址，随机生成的地址信息';
-- Name: COLUMN backup_employees7.salary; Type: COMMENT; Schema: public; Owner: gpadmin
COMMENT ON COLUMN public.backup_employees7.salary IS '员工薪资，范围在 3000 到 50000 之间';
-- Name: backup_employees7_id_seq; Type: SEQUENCE; Schema: public; Owner: gpadmin
CREATE SEQUENCE public.backup_employees7_id_seq
ALTER TABLE public.backup_employees7_id_seq OWNER TO gpadmin;
-- Name: backup_employees7_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gpadmin
ALTER SEQUENCE public.backup_employees7_id_seq OWNED BY public.backup_employees7.id;
ALTER TABLE ONLY public.backup_employees7 ALTER COLUMN id SET DEFAULT nextval('public.backup_employees7_id_seq'::regclass);
-- Data for Name: backup_employees7; Type: TABLE DATA; Schema: public; Owner: gpadmin
COPY public.backup_employees7 (id, name, age, gender, department, hire_date, birth_date, address, salary) FROM stdin;
-- Name: backup_employees7_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gpadmin
SELECT pg_catalog.setval('public.backup_employees7_id_seq', 100, true);
-- Name: backup_employees7_pkey; Type: CONSTRAINT; Schema: public; Owner: gpadmin; Tablespace: 
ALTER TABLE ONLY public.backup_employees7
    ADD CONSTRAINT backup_employees7_pkey PRIMARY KEY (id);
[gpadmin@Master-a backup]$

# 导入执行 -注意db选择非源数据库

[gpadmin@Master-a backup]$ psql -h Master-a -U gpadmin -d test_db -f backup_employees7.sql 
SET
SET
SET
SET
SET
 set_config 
------------
 
(1 row)

SET
SET
SET
SET
SET
CREATE TABLE
ALTER TABLE
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
CREATE SEQUENCE
ALTER TABLE
ALTER SEQUENCE
ALTER TABLE
COPY 100
 setval 
--------
    100
(1 row)

ALTER TABLE
```

###### 查看结果

![image-20241126162507483](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241126162507483.png)

数据正常导入

##### 单库全表导入

根据导入规则：将test_database数据库全部的导出的sql文件导出至新建一个数据库backup_test_database中。

```powershell
# 复制相应文件
[gpadmin@Master-a backup]$ cp ../test_database.sql backup_test_database.sql
[gpadmin@Master-a backup]$

# 查看数据库名称关联
[gpadmin@Master-a backup]$ grep test_database backup_test_database.sql 
[gpadmin@Master-a backup]$

无命中，查看文件发现没有数据创建相关，只有建表。

# 进入数据库
[gpadmin@Master-a backup]$ psql -h Master-a -U gpadmin
psql (9.4.24)
Type "help" for help.

# 查看当前数据库信息
gp_sydb=# \l
                                 List of databases
     Name      |  Owner  | Encoding |  Collate   |   Ctype    |  Access privileges  
---------------+---------+----------+------------+------------+---------------------
 gp_sydb       | gpadmin | UTF8     | en_US.utf8 | en_US.utf8 | 
 postgres      | gpadmin | UTF8     | en_US.utf8 | en_US.utf8 | 
 template0     | gpadmin | UTF8     | en_US.utf8 | en_US.utf8 | =c/gpadmin         +
               |         |          |            |            | gpadmin=CTc/gpadmin
 template1     | gpadmin | UTF8     | en_US.utf8 | en_US.utf8 | =c/gpadmin         +
               |         |          |            |            | gpadmin=CTc/gpadmin
 test_database | gpadmin | UTF8     | en_US.utf8 | en_US.utf8 | 
 test_db       | gpadmin | UTF8     | en_US.utf8 | en_US.utf8 | 
(6 rows)

# 创建数据库
gp_sydb=# CREATE DATABASE backup_test_database
gp_sydb-#     WITH OWNER = gpadmin
gp_sydb-#     ENCODING = 'UTF8'
gp_sydb-#     LC_COLLATE = 'en_US.utf8'
gp_sydb-#     LC_CTYPE = 'en_US.utf8'
gp_sydb-#     CONNECTION LIMIT = -1;
CREATE DATABASE

# 再次查看数据库
gp_sydb=# \l
                                     List of databases
         Name         |  Owner  | Encoding |  Collate   |   Ctype    |  Access privileges  
----------------------+---------+----------+------------+------------+---------------------
 backup_test_database | gpadmin | UTF8     | en_US.utf8 | en_US.utf8 | 
 gp_sydb              | gpadmin | UTF8     | en_US.utf8 | en_US.utf8 | 
 postgres             | gpadmin | UTF8     | en_US.utf8 | en_US.utf8 | 
 template0            | gpadmin | UTF8     | en_US.utf8 | en_US.utf8 | =c/gpadmin         +
                      |         |          |            |            | gpadmin=CTc/gpadmin
 template1            | gpadmin | UTF8     | en_US.utf8 | en_US.utf8 | =c/gpadmin         +
                      |         |          |            |            | gpadmin=CTc/gpadmin
 test_database        | gpadmin | UTF8     | en_US.utf8 | en_US.utf8 | 
 test_db              | gpadmin | UTF8     | en_US.utf8 | en_US.utf8 | 
(7 rows)

gp_sydb=#
gp_sydb-# \q
[gpadmin@Master-a backup]$ 
```

查看原始数据库情况

![image-20241126163223099](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241126163223099.png)

查看新创建的数据库情况

![image-20241126164459256](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241126164459256.png)

数据导入-根据数据大小决定导入时间

```powershell
[gpadmin@Master-a backup]$ psql -h Master-a -U gpadmin -d backup_test_database -f backup_test_database.sql 
SET
SET
SET
SET
SET
 set_config 
------------
 
(1 row)

SET
SET
SET
CREATE EXTENSION
COMMENT
SET
SET
CREATE TABLE
ALTER TABLE
CREATE TABLE
ALTER TABLE
CREATE SEQUENCE
ALTER TABLE
ALTER SEQUENCE
CREATE TABLE
ALTER TABLE
CREATE SEQUENCE
ALTER TABLE
ALTER SEQUENCE
CREATE TABLE
ALTER TABLE
CREATE SEQUENCE
ALTER TABLE
ALTER SEQUENCE
CREATE TABLE
ALTER TABLE
CREATE SEQUENCE
ALTER TABLE
ALTER SEQUENCE
CREATE TABLE
ALTER TABLE
CREATE SEQUENCE
ALTER TABLE
ALTER SEQUENCE
CREATE TABLE
ALTER TABLE
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
CREATE SEQUENCE
ALTER TABLE
ALTER SEQUENCE
CREATE SEQUENCE
ALTER TABLE
ALTER SEQUENCE
CREATE TABLE
ALTER TABLE
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
CREATE SEQUENCE
ALTER TABLE
ALTER SEQUENCE
CREATE TABLE
ALTER TABLE
CREATE TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
COPY 100
COPY 100
 setval 
--------
    100
(1 row)

COPY 100
 setval 
--------
    100
(1 row)

COPY 100
 setval 
--------
    100
(1 row)

COPY 100
 setval 
--------
    400
(1 row)

COPY 100
 setval 
--------
    100
(1 row)

COPY 100
 setval 
--------
    100
(1 row)

 setval 
--------
    100
(1 row)

COPY 0
  setval  
----------
 20839259
(1 row)

COPY 50000000
COPY 5000000
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
REVOKE
REVOKE
GRANT
GRANT
[gpadmin@Master-a backup]$

导入完成，可以看到每条都输出了对应的内容，因为表不多所有全都放出来。
```

###### 查看结果

原始表

![image-20241126165037430](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241126165037430.png)

备份表

![image-20241126164956932](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241126164956932.png)

可以看到表的数量一致，再通过sql看下条数是否一致，用之前的sql改一下。

![image-20241126165347291](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241126165347291.png)

可以看到数据是一致的，但是navicat的备份表的行数统计的有问题，为了确认没问题再次查询这个单表。

![image-20241126165653420](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241126165653420.png)

数据查询没问题，结束。

#### 总结

可以看到数据SQL操作greenplum数据库可以进行sql的导出和导入，sql导出使用pg_dump导出后使用psql 进行导入可以解决生产环境中数据导入导出的简单需求，本次只做了单库单表导出和单库全表导出2个方向，其他方式根据具体情况修改参数即可。

### 数据库备份与恢复

#### 软件安装

##### 插件下载

参考V6.23 Documentatuion 中 （gpbackup, gprestore, and related utilities are provided as a separate download, VMware Tanzu™ Greenplum® Backup and Restore. Follow the instructions in the VMware Tanzu Greenplum Backup and Restore Documentation to install and use these utilities.）需要单独进行下载。

![image-20241204141511052](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241204141511052.png)

![image-20241204142021156](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241204142021156.png)

对于版本，选择最大的版本， Greenplum Backup and Restore 1.30.7，然后选择对应操作系统以及GP的版本。

![image-20241204143402176](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241204143402176.png)

填写核查信息（需要根据自己的账户来进行核查)

![image-20241204143632043](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241204143632043.png)

下载完成

![image-20241204143718148](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241204143718148.png)

##### 插件安装

查看下如何安装 https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum-backup-and-restore/1-30/greenplum-backup-and-restore/backup-restore-install.html

![image-20241204143759255](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241204143759255.png)

Copy the `gppkg` file you downloaded to the gpadmin user's home directory on the Greenplum Database coordinator host. ，根据文档提示，需要下载到coordinator也就是master的主文件夹内，并进行安装。

```powershell
# 创建gppkg插件存放位置文件夹
[gpadmin@Master-a ~]$ mkdir gppkg
[gpadmin@Master-a ~]$ cd gppkg
[gpadmin@Master-a gppkg]$ cp ../greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg .
[gpadmin@Master-a gppkg]$ ls
greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg
[gpadmin@Master-a gppkg]$ ll
total 18948
-rw-r--r-- 1 gpadmin gpadmin 19401617 Dec  4 15:10 greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg
[gpadmin@Master-a gppkg]$

# Install
[gpadmin@Master-a gppkg]$ gppkg -i greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg 
20241204:15:12:54:008265 gppkg:Master-a:gpadmin-[INFO]:-Starting gppkg with args: -i greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg
20241204:15:12:54:008265 gppkg:Master-a:gpadmin-[INFO]:-Installing package greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg
20241204:15:12:54:008265 gppkg:Master-a:gpadmin-[INFO]:-Validating rpm installation cmdStr='rpm --test -i /usr/local/greenplum-db-6.13.0/.tmp/gpbackup_tools_RHEL7-1.30.7-1.x86_64.rpm --dbpath /usr/local/greenplum-db-6.13.0/share/packages/database --prefix /usr/local/greenplum-db-6.13.0'
20241204:15:12:58:008265 gppkg:Master-a:gpadmin-[CRITICAL]:-Error occurred: non-zero rc: 1
 Command was: '/bin/scp greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg Standby-a:/usr/local/greenplum-db-6.13.0/greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg'
rc=1, stdout='', stderr='scp: /usr/local/greenplum-db-6.13.0/greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg: Permission denied
'
[gpadmin@Master-a gppkg]$

error了，这...看问题是没有权限，需要root权限执行

# 再次执行(root)
[gpadmin@Master-a greenplum-db]$ exit
exit
[root@Master-a local]# cd /home/gpadmin/
[root@Master-a gpadmin]# ls
conf            expand_segment_instance  gpconfigs    output_data  union_data.sh
data            get_script_data.sh       gppkg        output_sql
expand_mirrors  gpAdminLogs              import_data  soft
[root@Master-a gpadmin]# cd gppkg/
[root@Master-a gppkg]# ls
greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg
[root@Master-a gppkg]#

不对应该是要放到gp程序目录执行，root带入不了环境变量。

[root@Master-a gpadmin]# su gpadmin

[gpadmin@Master-a ~]$ cd ~
[gpadmin@Master-a ~]$ cd /usr/local/greenplum-db-6.13.0/
[gpadmin@Master-a greenplum-db-6.13.0]$ cp /home/gpadmin/gppkg/greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg .
[gpadmin@Master-a greenplum-db-6.13.0]$ ls
bin
COPYRIGHT
docs
etc
ext
greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg
greenplum_path.sh
include
lib
libexec
LICENSE
NOTICE
open_source_license_greenplum_database.txt
sbin
share
[gpadmin@Master-a greenplum-db-6.13.0]$

[gpadmin@Master-a greenplum-db-6.13.0]$ gppkg -i greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg 
20241204:15:22:53:009605 gppkg:Master-a:gpadmin-[INFO]:-Starting gppkg with args: -i greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg
20241204:15:22:53:009605 gppkg:Master-a:gpadmin-[INFO]:-Installing package greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg
20241204:15:22:53:009605 gppkg:Master-a:gpadmin-[INFO]:-Validating rpm installation cmdStr='rpm --test -i /usr/local/greenplum-db-6.13.0/.tmp/gpbackup_tools_RHEL7-1.30.7-1.x86_64.rpm --dbpath /usr/local/greenplum-db-6.13.0/share/packages/database --prefix /usr/local/greenplum-db-6.13.0'
20241204:15:22:55:009605 gppkg:Master-a:gpadmin-[CRITICAL]:-Error occurred: non-zero rc: 1
 Command was: '/bin/scp greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg Standby-a:/usr/local/greenplum-db-6.13.0/greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg'
rc=1, stdout='', stderr='scp: /usr/local/greenplum-db-6.13.0/greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg: Permission denied
'
[gpadmin@Master-a greenplum-db-6.13.0]$

依然报错,找到问题了，问题出在Stabdby-a,提示说是权限不足，那就查看一下权限

[root@Standby-a local]# ll
total 0
drwxr-xr-x.  2 root root   6 Apr 11  2018 bin
drwxr-xr-x.  2 root root   6 Apr 11  2018 etc
drwxr-xr-x.  2 root root   6 Apr 11  2018 games
lrwxrwxrwx   1 root root  30 Aug  7 13:37 greenplum-db -> /usr/local/greenplum-db-6.13.0
drwxr-xr-x  11 root root 238 Aug  7 13:37 greenplum-db-6.13.0
drwxr-xr-x.  2 root root   6 Apr 11  2018 include

发现standby-a节点是root权限，这个应该是没有改当时，只是起到backup的作用。

# 根据报错修改Standby-a节点权限
[root@Standby-a local]# chown -R gpadmin:gpadmin greenplum-db*
[root@Standby-a local]# ll
total 0
drwxr-xr-x.  2 root    root      6 Apr 11  2018 bin
drwxr-xr-x.  2 root    root      6 Apr 11  2018 etc
drwxr-xr-x.  2 root    root      6 Apr 11  2018 games
lrwxrwxrwx   1 gpadmin gpadmin  30 Aug  7 13:37 greenplum-db -> /usr/local/greenplum-db-6.13.0
drwxr-xr-x  11 gpadmin gpadmin 238 Aug  7 13:37 greenplum-db-6.13.0
drwxr-xr-x.  2 root    root      6 Apr 11  2018 include
drwxr-xr-x.  2 root    root      6 Apr 11  2018 lib
drwxr-xr-x.  2 root    root      6 Apr 11  2018 lib64
drwxr-xr-x.  2 root    root      6 Apr 11  2018 libexec
drwxr-xr-x.  2 root    root      6 Apr 11  2018 sbin
drwxr-xr-x.  5 root    root     49 Jun  4  2024 share
drwxr-xr-x.  2 root    root      6 Apr 11  2018 src
[root@Standby-a local]#

# 再次尝试（gpadmin）
[gpadmin@Master-a greenplum-db-6.13.0]$ gppkg -i greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg 
20241204:15:27:47:009940 gppkg:Master-a:gpadmin-[INFO]:-Starting gppkg with args: -i greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg
20241204:15:27:48:009940 gppkg:Master-a:gpadmin-[INFO]:-Installing package greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg
20241204:15:27:48:009940 gppkg:Master-a:gpadmin-[INFO]:-Validating rpm installation cmdStr='rpm --test -i /usr/local/greenplum-db-6.13.0/.tmp/gpbackup_tools_RHEL7-1.30.7-1.x86_64.rpm --dbpath /usr/local/greenplum-db-6.13.0/share/packages/database --prefix /usr/local/greenplum-db-6.13.0'
20241204:15:27:52:009940 gppkg:Master-a:gpadmin-[INFO]:-Installing greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg locally
20241204:15:27:52:009940 gppkg:Master-a:gpadmin-[INFO]:-Validating rpm installation cmdStr='rpm --test -i /usr/local/greenplum-db-6.13.0/.tmp/gpbackup_tools_RHEL7-1.30.7-1.x86_64.rpm --dbpath /usr/local/greenplum-db-6.13.0/share/packages/database --prefix /usr/local/greenplum-db-6.13.0'
20241204:15:27:52:009940 gppkg:Master-a:gpadmin-[INFO]:-Installing rpms cmdStr='rpm -i --force /usr/local/greenplum-db-6.13.0/.tmp/gpbackup_tools_RHEL7-1.30.7-1.x86_64.rpm --dbpath /usr/local/greenplum-db-6.13.0/share/packages/database --prefix=/usr/local/greenplum-db-6.13.0'
20241204:15:27:53:009940 gppkg:Master-a:gpadmin-[INFO]:-Completed local installation of greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg.
20241204:15:27:53:009940 gppkg:Master-a:gpadmin-[INFO]:-gpbackup 1.30.7 successfully installed
20241204:15:27:53:009940 gppkg:Master-a:gpadmin-[INFO]:-greenplum_backup_restore-1.30.7-gp6-rhel7-x86_64.gppkg successfully installed.
[gpadmin@Master-a greenplum-db-6.13.0]$

这个命令执行了，尝试安装gppkg插件包，执行rpm -test -i 测试通过后，通过-i --force 进行安装，安装是全部节点进行安装的，全部安装完成后提示 successfully，安装成功
看一下文件发生了哪些变化
```

![image-20241204152939660](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241204152939660.png)

![image-20241204153213991](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241204153213991.png)

```powershell
可以看到各节点的bin都有gpbackup和gprestore相关工具了

# 尝试运行gpbackup
[gpadmin@Master-a docs]$ gpbackup
Error: required flag(s) "dbname" not set
Usage:
  gpbackup [flags]

Flags:
      --backup-dir string            The absolute path of the directory to which all backup files will be written
      --compression-level int        Level of compression to use during data backup. Range of valid values depends on compression type (default 1)
      --compression-type string      Type of compression to use during data backup. Valid values are 'gzip', 'zstd' (default "gzip")
      --copy-queue-size int          number of COPY commands gpbackup should enqueue when backing up using the --single-data-file option (default 1)
      --data-only                    Only back up data, do not back up metadata
      --dbname string                The database to be backed up
      --debug                        Print verbose and debug log messages
      --exclude-schema stringArray   Back up all metadata except objects in the specified schema(s). --exclude-schema can be specified multiple times.
      --exclude-schema-file string   A file containing a list of schemas to be excluded from the backup
      --exclude-table stringArray    Back up all metadata except the specified table(s). --exclude-table can be specified multiple times.
      --exclude-table-file string    A file containing a list of fully-qualified tables to be excluded from the backup
      --from-timestamp string        A timestamp to use to base the current incremental backup off
      --help                         Help for gpbackup
      --include-schema stringArray   Back up only the specified schema(s). --include-schema can be specified multiple times.
      --include-schema-file string   A file containing a list of schema(s) to be included in the backup
      --include-table stringArray    Back up only the specified table(s). --include-table can be specified multiple times.
      --include-table-file string    A file containing a list of fully-qualified tables to be included in the backup
      --incremental                  Only back up data for AO tables that have been modified since the last backup
      --jobs int                     The number of parallel connections to use when backing up data (default 1)
      --leaf-partition-data          For partition tables, create one data file per leaf partition instead of one data file for the whole table
      --metadata-only                Only back up metadata, do not back up data
      --no-compression               Skip compression of data files
      --no-history                   Do not write a backup entry to the gpbackup_history database
      --no-inherits                  For a filtered backup, don't back up all tables that inherit included tables
      --plugin-config string         The configuration file to use for a plugin
      --quiet                        Suppress non-warning, non-error log messages
      --single-backup-dir            Back up all data to a single directory instead of split by segment
      --single-data-file             Back up all data to a single file instead of one per table
      --verbose                      Print verbose log messages
      --version                      Print version number and exit
      --with-stats                   Back up query plan statistics
      --without-globals              Skip backup of global metadata

[gpadmin@Master-a docs]$

提示缺少参数，证明可以用了

# 尝试运行gprestore
[gpadmin@Master-a docs]$ gprestore 
20241204:15:36:29 gprestore:gpadmin:Master-a:010615-[CRITICAL]:-Must provide --backup-dir if --timestamp is not provided
20241204:15:36:29 gprestore:gpadmin:Master-a:010615-[INFO]:-Beginning cleanup
20241204:15:36:29 gprestore:gpadmin:Master-a:010615-[INFO]:-Cleanup complete
[gpadmin@Master-a docs]$

可以用了。
```

#### 单个数据库-全量备份与恢复

##### 开始全量备份

完整性备份参考文档：https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum-backup-and-restore/1-30/greenplum-backup-and-restore/admin_guide-managing-backup-gpbackup.html

```powershell
要对数据库以及 Greenplum 数据库系统元数据进行完整备份，请使用以下命令：

[gpadmin@Master-a docs]$ gpbackup --dbname backup_test_database
20241205:10:36:48 gpbackup:gpadmin:Master-a:066002-[INFO]:-gpbackup version = 1.30.7
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Greenplum Database Version = 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Starting backup of database backup_test_database
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Backup Timestamp = 20241205103649
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Backup Database = backup_test_database
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Gathering table state information
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Acquiring ACCESS SHARE locks on tables
Locks acquired:  10 / 10 [==============================================================] 100.00% 0s
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Gathering additional table metadata
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Getting partition definitions
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Getting storage information
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Getting child partitions with altered schema
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Metadata will be written to /home/gpadmin/data/master/gpseg-1/backups/20241205/20241205103649/gpbackup_20241205103649_metadata.sql
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Writing global database metadata
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Global database metadata backup complete
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Writing pre-data metadata
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Pre-data metadata metadata backup complete
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Writing post-data metadata
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Post-data metadata backup complete
20241205:10:36:49 gpbackup:gpadmin:Master-a:066002-[INFO]:-Writing data to file
Tables backed up:  10 / 10 [============================================================] 100.00% 8s
20241205:10:36:58 gpbackup:gpadmin:Master-a:066002-[INFO]:-Data backup complete
20241205:10:36:59 gpbackup:gpadmin:Master-a:066002-[INFO]:-Found neither /usr/local/greenplum-db/bin/gp_email_contacts.yaml nor /home/gpadmin/gp_email_contacts.yaml
20241205:10:36:59 gpbackup:gpadmin:Master-a:066002-[INFO]:-Email containing gpbackup report /home/gpadmin/data/master/gpseg-1/backups/20241205/20241205103649/gpbackup_20241205103649_report will not be sent
20241205:10:36:59 gpbackup:gpadmin:Master-a:066002-[INFO]:-Beginning cleanup
20241205:10:36:59 gpbackup:gpadmin:Master-a:066002-[INFO]:-Cleanup complete
20241205:10:36:59 gpbackup:gpadmin:Master-a:066002-[INFO]:-Backup completed successfully
[gpadmin@Master-a docs]$
```

查看Segment-a节点发现了备份内容

![image-20241205104011514](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205104011514.png)

查看Segment-b节点发现了备份内容

![image-20241205104718804](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205104718804.png)

查看Segment-c节点发现了备份内容

![image-20241205104920358](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205104920358.png)

查看Segment-d节点发现了备份内容

![image-20241205105054086](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205105054086.png)

查看Master-a节点发现了备份内容

![image-20241205104201889](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205104201889.png)

查看Standby-a节点**没有发现**备份内容

![image-20241205104347383](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205104347383.png)

由此可以看到，backup被平均分配到了各节点的各文件夹中。

查看报告

![image-20241205114323486](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205114323486.png)

可以看到备份已经完成，且据有详细的报告。

##### 删除已经备份的数据库

![image-20241205105549418](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205105549418.png)

通过数据库工具对数据库进行删除操作

![image-20241205105628613](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205105628613.png)

报错了，提示说有其他程序正在访问，有2个会话在访问，那么我们就关闭这个。

![image-20241205105907877](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205105907877.png)

再次尝试删除

![image-20241205105936040](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205105936040.png)

依然提示这个，我们看下进程，进程中没有异常，再次尝试删除

![image-20241205110508610](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205110508610.png)

通过命令行删除

![image-20241205111216298](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205111216298.png)

提示依旧，那就看下是谁在占用。

![image-20241205111323399](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205111323399.png)

就是navicat在用，关闭后进程就没有了，但是我采用函数的方式断掉链接。

![image-20241205111522817](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205111522817.png)

进程消失，继续删除数据库。

![image-20241205111610695](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205111610695.png)

数据库删除成功

##### 恢复单个数据库

要使用`gprestore`从备份集恢复，您必须使用`--timestamp`选项指定要恢复的准确时间戳值 ( `YYYYMMDDHHMMSS`)。`--create-db`如果数据库在集群中不存在，请包含该选项。

```powershell
# 删除数据库
[gpadmin@Master-a 20241205103649]$ dropdb backup_test_database
dropdb: database removal failed: ERROR:  database "backup_test_database" does not exist
[gpadmin@Master-a 20241205103649]$

因为已经删除了，所有这个提示不存在了，是正确的，我们继续

# 恢复数据库
首先要获取时间戳，这里时间戳就是文件夹的名称 20241205103649，我们来构建我们的数据库恢复命令。

[gpadmin@Master-a ~]$ gprestore --timestamp 20241205103649 --create-db
20241205:11:21:18 gprestore:gpadmin:Master-a:068682-[INFO]:-Restore Key = 20241205103649
20241205:11:21:18 gprestore:gpadmin:Master-a:068682-[INFO]:-gpbackup version = 1.30.7
20241205:11:21:18 gprestore:gpadmin:Master-a:068682-[INFO]:-gprestore version = 1.30.7
20241205:11:21:18 gprestore:gpadmin:Master-a:068682-[INFO]:-Greenplum Database Version = 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source
20241205:11:21:18 gprestore:gpadmin:Master-a:068682-[INFO]:-Creating database
20241205:11:21:19 gprestore:gpadmin:Master-a:068682-[INFO]:-Database creation complete for: backup_test_database
20241205:11:21:19 gprestore:gpadmin:Master-a:068682-[INFO]:-Restoring pre-data metadata
Pre-data objects restored:  66 / 66 [===================================================] 100.00% 0s
20241205:11:21:20 gprestore:gpadmin:Master-a:068682-[INFO]:-Pre-data metadata restore complete
Table data loads restored:  10 / 10 [==================================================] 100.00% 16s
20241205:11:21:36 gprestore:gpadmin:Master-a:068682-[INFO]:-Data restore complete
20241205:11:21:36 gprestore:gpadmin:Master-a:068682-[INFO]:-Restoring post-data metadata
Post-data objects restored:  10 / 10 [=================================================] 100.00% 14s
20241205:11:21:51 gprestore:gpadmin:Master-a:068682-[INFO]:-Post-data metadata restore complete
20241205:11:21:51 gprestore:gpadmin:Master-a:068682-[INFO]:-Found neither /usr/local/greenplum-db/bin/gp_email_contacts.yaml nor /home/gpadmin/gp_email_contacts.yaml
20241205:11:21:51 gprestore:gpadmin:Master-a:068682-[INFO]:-Email containing gprestore report /home/gpadmin/data/master/gpseg-1/backups/20241205/20241205103649/gprestore_20241205103649_20241205112118_report will not be sent
20241205:11:21:51 gprestore:gpadmin:Master-a:068682-[INFO]:-Beginning cleanup
20241205:11:21:51 gprestore:gpadmin:Master-a:068682-[INFO]:-Cleanup complete
20241205:11:21:51 gprestore:gpadmin:Master-a:068682-[INFO]:-Restore completed successfully
[gpadmin@Master-a ~]$

恢复成功
```

##### 查看恢复结果

![image-20241205112556175](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205112556175.png)

数据正常，但是有个问题，备份数据和运行数据在一个硬盘也就是segment下，如果硬盘损坏那么备份数据也会丢失，这个情况，我们采取异地的方式进行处理，但是备份这么多写一个脚本去把数据进行汇总吗，并不用那么麻烦，gpbackup已经帮我们想到这个问题了只需要增加一个参数即可。

##### 扩展-异地备份

```powershell
# 全量备份
[gpadmin@Master-a ~]$ mkdir backups
[gpadmin@Master-a ~]$ cd backups/
[gpadmin@Master-a backups]$ gpbackup --dbname test_db --backup-dir /home/gpadmin/backups
20241205:14:28:22 gpbackup:gpadmin:Master-a:078132-[INFO]:-gpbackup version = 1.30.7
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Greenplum Database Version = 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Starting backup of database test_db
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Backup Timestamp = 20241205142822
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Backup Database = test_db
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Gathering table state information
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Acquiring ACCESS SHARE locks on tables
Locks acquired:  8 / 8 [================================================================] 100.00% 0s
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Gathering additional table metadata
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Getting partition definitions
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Getting storage information
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Getting child partitions with altered schema
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Metadata will be written to /home/gpadmin/backups/gpseg-1/backups/20241205/20241205142822/gpbackup_20241205142822_metadata.sql
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Writing global database metadata
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Global database metadata backup complete
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Writing pre-data metadata
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Pre-data metadata metadata backup complete
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Writing post-data metadata
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Post-data metadata backup complete
20241205:14:28:23 gpbackup:gpadmin:Master-a:078132-[INFO]:-Writing data to file
Tables backed up:  4 / 4 [==============================================================] 100.00% 3s
20241205:14:28:26 gpbackup:gpadmin:Master-a:078132-[INFO]:-Data backup complete
20241205:14:28:26 gpbackup:gpadmin:Master-a:078132-[INFO]:-Skipped data backup of 4 external/foreign table(s).
20241205:14:28:26 gpbackup:gpadmin:Master-a:078132-[INFO]:-See /home/gpadmin/gpAdminLogs/gpbackup_20241205.log for a complete list of skipped tables.
20241205:14:28:27 gpbackup:gpadmin:Master-a:078132-[INFO]:-Found neither /usr/local/greenplum-db/bin/gp_email_contacts.yaml nor /home/gpadmin/gp_email_contacts.yaml
20241205:14:28:27 gpbackup:gpadmin:Master-a:078132-[INFO]:-Email containing gpbackup report /home/gpadmin/backups/gpseg-1/backups/20241205/20241205142822/gpbackup_20241205142822_report will not be sent
20241205:14:28:27 gpbackup:gpadmin:Master-a:078132-[INFO]:-Beginning cleanup
20241205:14:28:27 gpbackup:gpadmin:Master-a:078132-[INFO]:-Cleanup complete
20241205:14:28:27 gpbackup:gpadmin:Master-a:078132-[INFO]:-Backup completed successfully
[gpadmin@Master-a backups]$

# 查看备份数据
```

![image-20241205143118172](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205143118172.png)

![image-20241205143135965](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205143135965.png)

其他节点忽略展示，原理都是在相同位置进行了backups文件夹的创建，那么我们就可以规划一下：

每一台Segment节点中

![image-20241205143324566](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241205143324566.png)

新增一块硬盘 挂载到 /backup，那么这样，就可以实现异地备份了，至于备份的位置就可以因人因项目因规划而异了，可以传输到S3也可以传输到OSS总之前提需要实现挂载位置的自定义。

恢复时如果对时间和性能有要求，可以在恢复时增加--jobs 4 数值根据CPU的线程进行设置即可。

#### 单个数据库-增量备份与恢复

全量备份备份时间长，在业务变动频繁的情况下就不是最有的选择了，因此我们可以进行增量备份

增量备份参考文档：https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum-backup-and-restore/1-30/greenplum-backup-and-restore/admin_guide-managing-backup-gpbackup-incremental.html

##### 全量数据备份

备份前数据（因为backup这个库就是test_database的实验镜像)

![image-20241206102246417](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206102246417.png)

##### 模拟数据录入

- A. 表新增x条数据
- B. 表删除x条数据
- C. 修改特定规则x条数据
- D. 删除一个表
- E. 新增一个表

###### 新增数据

数据执行前有0条数据

![image-20241206111108797](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206111108797.png)

通过语句随机写入50条数据

![image-20241206111305968](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206111305968.png)

再次查看

![image-20241206111438042](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206111438042.png)

![image-20241206111509333](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206111509333.png)

###### 删除数据

数据查看

![image-20241206105136719](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206105136719.png)

![image-20241206105300537](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206105300537.png)

删除数据

![image-20241206105352154](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206105352154.png)

![image-20241206105405010](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206105405010.png)

###### 修改数据

数据查看

![image-20241206105509339](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206105509339.png)

数据修改

![image-20241206105846599](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206105846599.png)

数据修改后查看

![image-20241206105917118](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206105917118.png)

###### 删除表

![image-20241206111639980](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206111639980.png)

###### 新增表

这里直接复制一个表吧

![image-20241206111724919](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206111724919.png)

数据汇总一下

因为有排它锁更新一下相关统计SQL

```sql
/* 创建临时表 */
CREATE TEMP TABLE table_counts (
    schema_name TEXT,
    table_name TEXT,
    row_count BIGINT
);

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
            AND n.nspname NOT LIKE 'pg_temp%'  -- 排除所有临时命名空间
    LOOP 
        EXECUTE format(
            'INSERT INTO table_counts (schema_name, table_name, row_count) 
             SELECT %L, %L, count(*) FROM %I.%I',
            tbl.schema_name, 
            tbl.table_name, 
            tbl.schema_name, 
            tbl.table_name
        );
    END LOOP; 
END $$;

/* 查询临时表结果 */
SELECT * FROM table_counts ORDER BY row_count DESC;
```

再看下统计结果

![image-20241206113225439](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206113225439.png)

这个数据结果作为增量同步是否成功的判定标准，即为先进行全量的恢复，再进行增量的恢复，有个尴尬的点，由于test_database并没有做全量数据备份，而 backup_test_database做了全量数据备份，那就修改一下思路，test_database作为对照组，除了自动生成的50条数据外其他其他数据一致，50条仅记录条数。

以上的内容需要在backup_test_database再做一遍，故此过程忽略。

![image-20241206114635313](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206114635313.png)

##### 增量备份

![image-20241206115620837](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206115620837.png)

基于上一个全量备份的时间戳进行增量备份，就是上面模拟数据录入的修改部分

查看备份报告

![image-20241206115747046](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206115747046.png)

查看Sengment备份数据

```powershell
[gpadmin@Master-a ~]$ for host in Master-a Standby-a Segment-a Segment-b Segment-c Segment-d; do
>   echo "===== $host ====="
>   ssh gpadmin@$host "tree /home/gpadmin/backups"
> done
===== Master-a =====
/home/gpadmin/backups
└── gpseg-1
    └── backups
        ├── 20241205
        │   └── 20241205142822
        │       ├── gpbackup_20241205142822_config.yaml
        │       ├── gpbackup_20241205142822_metadata.sql
        │       ├── gpbackup_20241205142822_report
        │       └── gpbackup_20241205142822_toc.yaml
        └── 20241206
            ├── 20241206102913
            │   ├── gpbackup_20241206102913_config.yaml
            │   ├── gpbackup_20241206102913_metadata.sql
            │   ├── gpbackup_20241206102913_report
            │   └── gpbackup_20241206102913_toc.yaml
            └── 20241206115607
                ├── gpbackup_20241206115607_config.yaml
                └── gpbackup_20241206115607_report

7 directories, 10 files
===== Standby-a =====
/home/gpadmin/backups [error opening dir]

0 directories, 0 files
===== Segment-a =====
/home/gpadmin/backups
├── gpseg0
│   └── backups
│       ├── 20241205
│       │   └── 20241205142822
│       │       ├── gpbackup_0_20241205142822_57370.gz
│       │       ├── gpbackup_0_20241205142822_65584.gz
│       │       ├── gpbackup_0_20241205142822_65593.gz
│       │       └── gpbackup_0_20241205142822_73785.gz
│       └── 20241206
│           ├── 20241206102913
│           │   ├── gpbackup_0_20241206102913_73900.gz
│           │   ├── gpbackup_0_20241206102913_73904.gz
│           │   ├── gpbackup_0_20241206102913_73908.gz
│           │   ├── gpbackup_0_20241206102913_73912.gz
│           │   ├── gpbackup_0_20241206102913_73916.gz
│           │   ├── gpbackup_0_20241206102913_73920.gz
│           │   ├── gpbackup_0_20241206102913_73924.gz
│           │   ├── gpbackup_0_20241206102913_73928.gz
│           │   ├── gpbackup_0_20241206102913_73932.gz
│           │   └── gpbackup_0_20241206102913_73938.gz
│           └── 20241206115607
├── gpseg1
│   └── backups
│       ├── 20241205
│       │   └── 20241205142822
│       │       ├── gpbackup_1_20241205142822_57370.gz
│       │       ├── gpbackup_1_20241205142822_65584.gz
│       │       ├── gpbackup_1_20241205142822_65593.gz
│       │       └── gpbackup_1_20241205142822_73785.gz
│       └── 20241206
│           ├── 20241206102913
│           │   ├── gpbackup_1_20241206102913_73900.gz
│           │   ├── gpbackup_1_20241206102913_73904.gz
│           │   ├── gpbackup_1_20241206102913_73908.gz
│           │   ├── gpbackup_1_20241206102913_73912.gz
│           │   ├── gpbackup_1_20241206102913_73916.gz
│           │   ├── gpbackup_1_20241206102913_73920.gz
│           │   ├── gpbackup_1_20241206102913_73924.gz
│           │   ├── gpbackup_1_20241206102913_73928.gz
│           │   ├── gpbackup_1_20241206102913_73932.gz
│           │   └── gpbackup_1_20241206102913_73938.gz
│           └── 20241206115607
├── gpseg16
│   └── backups
│       ├── 20241205
│       │   └── 20241205142822
│       │       ├── gpbackup_16_20241205142822_57370.gz
│       │       ├── gpbackup_16_20241205142822_65584.gz
│       │       ├── gpbackup_16_20241205142822_65593.gz
│       │       └── gpbackup_16_20241205142822_73785.gz
│       └── 20241206
│           ├── 20241206102913
│           │   ├── gpbackup_16_20241206102913_73900.gz
│           │   ├── gpbackup_16_20241206102913_73904.gz
│           │   ├── gpbackup_16_20241206102913_73908.gz
│           │   ├── gpbackup_16_20241206102913_73912.gz
│           │   ├── gpbackup_16_20241206102913_73916.gz
│           │   ├── gpbackup_16_20241206102913_73920.gz
│           │   ├── gpbackup_16_20241206102913_73924.gz
│           │   ├── gpbackup_16_20241206102913_73928.gz
│           │   ├── gpbackup_16_20241206102913_73932.gz
│           │   └── gpbackup_16_20241206102913_73938.gz
│           └── 20241206115607
├── gpseg4
│   └── backups
│       ├── 20241205
│       │   └── 20241205142822
│       │       ├── gpbackup_4_20241205142822_57370.gz
│       │       ├── gpbackup_4_20241205142822_65584.gz
│       │       ├── gpbackup_4_20241205142822_65593.gz
│       │       └── gpbackup_4_20241205142822_73785.gz
│       └── 20241206
│           ├── 20241206102913
│           │   ├── gpbackup_4_20241206102913_73900.gz
│           │   ├── gpbackup_4_20241206102913_73904.gz
│           │   ├── gpbackup_4_20241206102913_73908.gz
│           │   ├── gpbackup_4_20241206102913_73912.gz
│           │   ├── gpbackup_4_20241206102913_73916.gz
│           │   ├── gpbackup_4_20241206102913_73920.gz
│           │   ├── gpbackup_4_20241206102913_73924.gz
│           │   ├── gpbackup_4_20241206102913_73928.gz
│           │   ├── gpbackup_4_20241206102913_73932.gz
│           │   └── gpbackup_4_20241206102913_73938.gz
│           └── 20241206115607
└── gpseg5
    └── backups
        ├── 20241205
        │   └── 20241205142822
        │       ├── gpbackup_5_20241205142822_57370.gz
        │       ├── gpbackup_5_20241205142822_65584.gz
        │       ├── gpbackup_5_20241205142822_65593.gz
        │       └── gpbackup_5_20241205142822_73785.gz
        └── 20241206
            ├── 20241206102913
            │   ├── gpbackup_5_20241206102913_73900.gz
            │   ├── gpbackup_5_20241206102913_73904.gz
            │   ├── gpbackup_5_20241206102913_73908.gz
            │   ├── gpbackup_5_20241206102913_73912.gz
            │   ├── gpbackup_5_20241206102913_73916.gz
            │   ├── gpbackup_5_20241206102913_73920.gz
            │   ├── gpbackup_5_20241206102913_73924.gz
            │   ├── gpbackup_5_20241206102913_73928.gz
            │   ├── gpbackup_5_20241206102913_73932.gz
            │   └── gpbackup_5_20241206102913_73938.gz
            └── 20241206115607

35 directories, 70 files
===== Segment-b =====
/home/gpadmin/backups
├── gpseg17
│   └── backups
│       ├── 20241205
│       │   └── 20241205142822
│       │       ├── gpbackup_17_20241205142822_57370.gz
│       │       ├── gpbackup_17_20241205142822_65584.gz
│       │       ├── gpbackup_17_20241205142822_65593.gz
│       │       └── gpbackup_17_20241205142822_73785.gz
│       └── 20241206
│           ├── 20241206102913
│           │   ├── gpbackup_17_20241206102913_73900.gz
│           │   ├── gpbackup_17_20241206102913_73904.gz
│           │   ├── gpbackup_17_20241206102913_73908.gz
│           │   ├── gpbackup_17_20241206102913_73912.gz
│           │   ├── gpbackup_17_20241206102913_73916.gz
│           │   ├── gpbackup_17_20241206102913_73920.gz
│           │   ├── gpbackup_17_20241206102913_73924.gz
│           │   ├── gpbackup_17_20241206102913_73928.gz
│           │   ├── gpbackup_17_20241206102913_73932.gz
│           │   └── gpbackup_17_20241206102913_73938.gz
│           └── 20241206115607
├── gpseg2
│   └── backups
│       ├── 20241205
│       │   └── 20241205142822
│       │       ├── gpbackup_2_20241205142822_57370.gz
│       │       ├── gpbackup_2_20241205142822_65584.gz
│       │       ├── gpbackup_2_20241205142822_65593.gz
│       │       └── gpbackup_2_20241205142822_73785.gz
│       └── 20241206
│           ├── 20241206102913
│           │   ├── gpbackup_2_20241206102913_73900.gz
│           │   ├── gpbackup_2_20241206102913_73904.gz
│           │   ├── gpbackup_2_20241206102913_73908.gz
│           │   ├── gpbackup_2_20241206102913_73912.gz
│           │   ├── gpbackup_2_20241206102913_73916.gz
│           │   ├── gpbackup_2_20241206102913_73920.gz
│           │   ├── gpbackup_2_20241206102913_73924.gz
│           │   ├── gpbackup_2_20241206102913_73928.gz
│           │   ├── gpbackup_2_20241206102913_73932.gz
│           │   └── gpbackup_2_20241206102913_73938.gz
│           └── 20241206115607
├── gpseg3
│   └── backups
│       ├── 20241205
│       │   └── 20241205142822
│       │       ├── gpbackup_3_20241205142822_57370.gz
│       │       ├── gpbackup_3_20241205142822_65584.gz
│       │       ├── gpbackup_3_20241205142822_65593.gz
│       │       └── gpbackup_3_20241205142822_73785.gz
│       └── 20241206
│           ├── 20241206102913
│           │   ├── gpbackup_3_20241206102913_73900.gz
│           │   ├── gpbackup_3_20241206102913_73904.gz
│           │   ├── gpbackup_3_20241206102913_73908.gz
│           │   ├── gpbackup_3_20241206102913_73912.gz
│           │   ├── gpbackup_3_20241206102913_73916.gz
│           │   ├── gpbackup_3_20241206102913_73920.gz
│           │   ├── gpbackup_3_20241206102913_73924.gz
│           │   ├── gpbackup_3_20241206102913_73928.gz
│           │   ├── gpbackup_3_20241206102913_73932.gz
│           │   └── gpbackup_3_20241206102913_73938.gz
│           └── 20241206115607
├── gpseg6
│   └── backups
│       ├── 20241205
│       │   └── 20241205142822
│       │       ├── gpbackup_6_20241205142822_57370.gz
│       │       ├── gpbackup_6_20241205142822_65584.gz
│       │       ├── gpbackup_6_20241205142822_65593.gz
│       │       └── gpbackup_6_20241205142822_73785.gz
│       └── 20241206
│           ├── 20241206102913
│           │   ├── gpbackup_6_20241206102913_73900.gz
│           │   ├── gpbackup_6_20241206102913_73904.gz
│           │   ├── gpbackup_6_20241206102913_73908.gz
│           │   ├── gpbackup_6_20241206102913_73912.gz
│           │   ├── gpbackup_6_20241206102913_73916.gz
│           │   ├── gpbackup_6_20241206102913_73920.gz
│           │   ├── gpbackup_6_20241206102913_73924.gz
│           │   ├── gpbackup_6_20241206102913_73928.gz
│           │   ├── gpbackup_6_20241206102913_73932.gz
│           │   └── gpbackup_6_20241206102913_73938.gz
│           └── 20241206115607
└── gpseg7
    └── backups
        ├── 20241205
        │   └── 20241205142822
        │       ├── gpbackup_7_20241205142822_57370.gz
        │       ├── gpbackup_7_20241205142822_65584.gz
        │       ├── gpbackup_7_20241205142822_65593.gz
        │       └── gpbackup_7_20241205142822_73785.gz
        └── 20241206
            ├── 20241206102913
            │   ├── gpbackup_7_20241206102913_73900.gz
            │   ├── gpbackup_7_20241206102913_73904.gz
            │   ├── gpbackup_7_20241206102913_73908.gz
            │   ├── gpbackup_7_20241206102913_73912.gz
            │   ├── gpbackup_7_20241206102913_73916.gz
            │   ├── gpbackup_7_20241206102913_73920.gz
            │   ├── gpbackup_7_20241206102913_73924.gz
            │   ├── gpbackup_7_20241206102913_73928.gz
            │   ├── gpbackup_7_20241206102913_73932.gz
            │   └── gpbackup_7_20241206102913_73938.gz
            └── 20241206115607

35 directories, 70 files
===== Segment-c =====
/home/gpadmin/backups
├── gpseg10
│   └── backups
│       ├── 20241205
│       │   └── 20241205142822
│       │       ├── gpbackup_10_20241205142822_57370.gz
│       │       ├── gpbackup_10_20241205142822_65584.gz
│       │       ├── gpbackup_10_20241205142822_65593.gz
│       │       └── gpbackup_10_20241205142822_73785.gz
│       └── 20241206
│           ├── 20241206102913
│           │   ├── gpbackup_10_20241206102913_73900.gz
│           │   ├── gpbackup_10_20241206102913_73904.gz
│           │   ├── gpbackup_10_20241206102913_73908.gz
│           │   ├── gpbackup_10_20241206102913_73912.gz
│           │   ├── gpbackup_10_20241206102913_73916.gz
│           │   ├── gpbackup_10_20241206102913_73920.gz
│           │   ├── gpbackup_10_20241206102913_73924.gz
│           │   ├── gpbackup_10_20241206102913_73928.gz
│           │   ├── gpbackup_10_20241206102913_73932.gz
│           │   └── gpbackup_10_20241206102913_73938.gz
│           └── 20241206115607
├── gpseg11
│   └── backups
│       ├── 20241205
│       │   └── 20241205142822
│       │       ├── gpbackup_11_20241205142822_57370.gz
│       │       ├── gpbackup_11_20241205142822_65584.gz
│       │       ├── gpbackup_11_20241205142822_65593.gz
│       │       └── gpbackup_11_20241205142822_73785.gz
│       └── 20241206
│           ├── 20241206102913
│           │   ├── gpbackup_11_20241206102913_73900.gz
│           │   ├── gpbackup_11_20241206102913_73904.gz
│           │   ├── gpbackup_11_20241206102913_73908.gz
│           │   ├── gpbackup_11_20241206102913_73912.gz
│           │   ├── gpbackup_11_20241206102913_73916.gz
│           │   ├── gpbackup_11_20241206102913_73920.gz
│           │   ├── gpbackup_11_20241206102913_73924.gz
│           │   ├── gpbackup_11_20241206102913_73928.gz
│           │   ├── gpbackup_11_20241206102913_73932.gz
│           │   └── gpbackup_11_20241206102913_73938.gz
│           └── 20241206115607
├── gpseg18
│   └── backups
│       ├── 20241205
│       │   └── 20241205142822
│       │       ├── gpbackup_18_20241205142822_57370.gz
│       │       ├── gpbackup_18_20241205142822_65584.gz
│       │       ├── gpbackup_18_20241205142822_65593.gz
│       │       └── gpbackup_18_20241205142822_73785.gz
│       └── 20241206
│           ├── 20241206102913
│           │   ├── gpbackup_18_20241206102913_73900.gz
│           │   ├── gpbackup_18_20241206102913_73904.gz
│           │   ├── gpbackup_18_20241206102913_73908.gz
│           │   ├── gpbackup_18_20241206102913_73912.gz
│           │   ├── gpbackup_18_20241206102913_73916.gz
│           │   ├── gpbackup_18_20241206102913_73920.gz
│           │   ├── gpbackup_18_20241206102913_73924.gz
│           │   ├── gpbackup_18_20241206102913_73928.gz
│           │   ├── gpbackup_18_20241206102913_73932.gz
│           │   └── gpbackup_18_20241206102913_73938.gz
│           └── 20241206115607
├── gpseg8
│   └── backups
│       ├── 20241205
│       │   └── 20241205142822
│       │       ├── gpbackup_8_20241205142822_57370.gz
│       │       ├── gpbackup_8_20241205142822_65584.gz
│       │       ├── gpbackup_8_20241205142822_65593.gz
│       │       └── gpbackup_8_20241205142822_73785.gz
│       └── 20241206
│           ├── 20241206102913
│           │   ├── gpbackup_8_20241206102913_73900.gz
│           │   ├── gpbackup_8_20241206102913_73904.gz
│           │   ├── gpbackup_8_20241206102913_73908.gz
│           │   ├── gpbackup_8_20241206102913_73912.gz
│           │   ├── gpbackup_8_20241206102913_73916.gz
│           │   ├── gpbackup_8_20241206102913_73920.gz
│           │   ├── gpbackup_8_20241206102913_73924.gz
│           │   ├── gpbackup_8_20241206102913_73928.gz
│           │   ├── gpbackup_8_20241206102913_73932.gz
│           │   └── gpbackup_8_20241206102913_73938.gz
│           └── 20241206115607
└── gpseg9
    └── backups
        ├── 20241205
        │   └── 20241205142822
        │       ├── gpbackup_9_20241205142822_57370.gz
        │       ├── gpbackup_9_20241205142822_65584.gz
        │       ├── gpbackup_9_20241205142822_65593.gz
        │       └── gpbackup_9_20241205142822_73785.gz
        └── 20241206
            ├── 20241206102913
            │   ├── gpbackup_9_20241206102913_73900.gz
            │   ├── gpbackup_9_20241206102913_73904.gz
            │   ├── gpbackup_9_20241206102913_73908.gz
            │   ├── gpbackup_9_20241206102913_73912.gz
            │   ├── gpbackup_9_20241206102913_73916.gz
            │   ├── gpbackup_9_20241206102913_73920.gz
            │   ├── gpbackup_9_20241206102913_73924.gz
            │   ├── gpbackup_9_20241206102913_73928.gz
            │   ├── gpbackup_9_20241206102913_73932.gz
            │   └── gpbackup_9_20241206102913_73938.gz
            └── 20241206115607

35 directories, 70 files
===== Segment-d =====
/home/gpadmin/backups
├── gpseg12
│   └── backups
│       ├── 20241205
│       │   └── 20241205142822
│       │       ├── gpbackup_12_20241205142822_57370.gz
│       │       ├── gpbackup_12_20241205142822_65584.gz
│       │       ├── gpbackup_12_20241205142822_65593.gz
│       │       └── gpbackup_12_20241205142822_73785.gz
│       └── 20241206
│           ├── 20241206102913
│           │   ├── gpbackup_12_20241206102913_73900.gz
│           │   ├── gpbackup_12_20241206102913_73904.gz
│           │   ├── gpbackup_12_20241206102913_73908.gz
│           │   ├── gpbackup_12_20241206102913_73912.gz
│           │   ├── gpbackup_12_20241206102913_73916.gz
│           │   ├── gpbackup_12_20241206102913_73920.gz
│           │   ├── gpbackup_12_20241206102913_73924.gz
│           │   ├── gpbackup_12_20241206102913_73928.gz
│           │   ├── gpbackup_12_20241206102913_73932.gz
│           │   └── gpbackup_12_20241206102913_73938.gz
│           └── 20241206115607
├── gpseg13
│   └── backups
│       ├── 20241205
│       │   └── 20241205142822
│       │       ├── gpbackup_13_20241205142822_57370.gz
│       │       ├── gpbackup_13_20241205142822_65584.gz
│       │       ├── gpbackup_13_20241205142822_65593.gz
│       │       └── gpbackup_13_20241205142822_73785.gz
│       └── 20241206
│           ├── 20241206102913
│           │   ├── gpbackup_13_20241206102913_73900.gz
│           │   ├── gpbackup_13_20241206102913_73904.gz
│           │   ├── gpbackup_13_20241206102913_73908.gz
│           │   ├── gpbackup_13_20241206102913_73912.gz
│           │   ├── gpbackup_13_20241206102913_73916.gz
│           │   ├── gpbackup_13_20241206102913_73920.gz
│           │   ├── gpbackup_13_20241206102913_73924.gz
│           │   ├── gpbackup_13_20241206102913_73928.gz
│           │   ├── gpbackup_13_20241206102913_73932.gz
│           │   └── gpbackup_13_20241206102913_73938.gz
│           └── 20241206115607
├── gpseg14
│   └── backups
│       ├── 20241205
│       │   └── 20241205142822
│       │       ├── gpbackup_14_20241205142822_57370.gz
│       │       ├── gpbackup_14_20241205142822_65584.gz
│       │       ├── gpbackup_14_20241205142822_65593.gz
│       │       └── gpbackup_14_20241205142822_73785.gz
│       └── 20241206
│           ├── 20241206102913
│           │   ├── gpbackup_14_20241206102913_73900.gz
│           │   ├── gpbackup_14_20241206102913_73904.gz
│           │   ├── gpbackup_14_20241206102913_73908.gz
│           │   ├── gpbackup_14_20241206102913_73912.gz
│           │   ├── gpbackup_14_20241206102913_73916.gz
│           │   ├── gpbackup_14_20241206102913_73920.gz
│           │   ├── gpbackup_14_20241206102913_73924.gz
│           │   ├── gpbackup_14_20241206102913_73928.gz
│           │   ├── gpbackup_14_20241206102913_73932.gz
│           │   └── gpbackup_14_20241206102913_73938.gz
│           └── 20241206115607
├── gpseg15
│   └── backups
│       ├── 20241205
│       │   └── 20241205142822
│       │       ├── gpbackup_15_20241205142822_57370.gz
│       │       ├── gpbackup_15_20241205142822_65584.gz
│       │       ├── gpbackup_15_20241205142822_65593.gz
│       │       └── gpbackup_15_20241205142822_73785.gz
│       └── 20241206
│           ├── 20241206102913
│           │   ├── gpbackup_15_20241206102913_73900.gz
│           │   ├── gpbackup_15_20241206102913_73904.gz
│           │   ├── gpbackup_15_20241206102913_73908.gz
│           │   ├── gpbackup_15_20241206102913_73912.gz
│           │   ├── gpbackup_15_20241206102913_73916.gz
│           │   ├── gpbackup_15_20241206102913_73920.gz
│           │   ├── gpbackup_15_20241206102913_73924.gz
│           │   ├── gpbackup_15_20241206102913_73928.gz
│           │   ├── gpbackup_15_20241206102913_73932.gz
│           │   └── gpbackup_15_20241206102913_73938.gz
│           └── 20241206115607
└── gpseg19
    └── backups
        ├── 20241205
        │   └── 20241205142822
        │       ├── gpbackup_19_20241205142822_57370.gz
        │       ├── gpbackup_19_20241205142822_65584.gz
        │       ├── gpbackup_19_20241205142822_65593.gz
        │       └── gpbackup_19_20241205142822_73785.gz
        └── 20241206
            ├── 20241206102913
            │   ├── gpbackup_19_20241206102913_73900.gz
            │   ├── gpbackup_19_20241206102913_73904.gz
            │   ├── gpbackup_19_20241206102913_73908.gz
            │   ├── gpbackup_19_20241206102913_73912.gz
            │   ├── gpbackup_19_20241206102913_73916.gz
            │   ├── gpbackup_19_20241206102913_73920.gz
            │   ├── gpbackup_19_20241206102913_73924.gz
            │   ├── gpbackup_19_20241206102913_73928.gz
            │   ├── gpbackup_19_20241206102913_73932.gz
            │   └── gpbackup_19_20241206102913_73938.gz
            └── 20241206115607

35 directories, 70 files
[gpadmin@Master-a ~]$
```

![image-20241206131459384](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206131459384.png)

报错提示无法生效

那就重新处理下，把backup这数据库重新删除恢复一下，然后做全量备份，再通过增量做备份。

```powershell
[gpadmin@Master-a 20241206131336]$ psql
psql (9.4.24)
Type "help" for help.

gp_sydb=# SELECT pid, usename, application_name, client_addr, client_port, backend_start, state
FROM pg_stat_activity
WHERE datname = 'backup_test_database';
  pid  | usename | application_name | client_addr  | client_port |         backend_start         | state 
-------+---------+------------------+--------------+-------------+-------------------------------+-------
 35098 | gpadmin | Navicat          | 192.168.7.99 |       59474 | 2024-12-06 11:42:12.055003+08 | idle
 35140 | gpadmin | Navicat          | 192.168.7.99 |       59476 | 2024-12-06 11:43:00.365024+08 | idle
 35159 | gpadmin | Navicat          | 192.168.7.99 |       59478 | 2024-12-06 11:43:21.590585+08 | idle
 35161 | gpadmin | Navicat          | 192.168.7.99 |       59480 | 2024-12-06 11:43:22.285872+08 | idle
(4 rows)

gp_sydb=# DROP DATABASE backup_test_database;
ERROR:  database "backup_test_database" is being accessed by other users
DETAIL:  There are 4 other sessions using the database.
gp_sydb=# 
gp_sydb=# SELECT pg_terminate_backend(pid)                                                     
FROM pg_stat_activity
WHERE datname = 'backup_test_database' AND pid <> pg_backend_pid();
 pg_terminate_backend 
----------------------
 t
 t
 t
 t
(4 rows)

gp_sydb=# DROP DATABASE backup_test_database;
DROP DATABASE
gp_sydb=# SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'backup_test_database' AND pid <> pg_backend_pid();
 pg_terminate_backend 
----------------------
(0 rows)

gp_sydb=#


# 恢复今天备份的内容
[gpadmin@Master-a 20241206131336]$ gprestore --backup-dir /home/gpadmin/backups/ --timestamp 20241206102913 --create-db --jobs 4
20241206:13:36:04 gprestore:gpadmin:Master-a:042776-[INFO]:-Restore Key = 20241206102913
20241206:13:36:04 gprestore:gpadmin:Master-a:042776-[INFO]:-gpbackup version = 1.30.7
20241206:13:36:04 gprestore:gpadmin:Master-a:042776-[INFO]:-gprestore version = 1.30.7
20241206:13:36:04 gprestore:gpadmin:Master-a:042776-[INFO]:-Greenplum Database Version = 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source
20241206:13:36:04 gprestore:gpadmin:Master-a:042776-[INFO]:-Creating database
20241206:13:36:05 gprestore:gpadmin:Master-a:042776-[INFO]:-Database creation complete for: backup_test_database
20241206:13:36:05 gprestore:gpadmin:Master-a:042776-[INFO]:-Restoring pre-data metadata
Pre-data objects restored:  66 / 66 [===================================================] 100.00% 0s
20241206:13:36:05 gprestore:gpadmin:Master-a:042776-[INFO]:-Pre-data metadata restore complete
Table data loads restored:  10 / 10 [==================================================] 100.00% 13s
20241206:13:36:19 gprestore:gpadmin:Master-a:042776-[INFO]:-Data restore complete
20241206:13:36:19 gprestore:gpadmin:Master-a:042776-[INFO]:-Restoring post-data metadata
Post-data objects restored:  10 / 10 [==================================================] 100.00% 8s
20241206:13:36:28 gprestore:gpadmin:Master-a:042776-[INFO]:-Post-data metadata restore complete
20241206:13:36:28 gprestore:gpadmin:Master-a:042776-[INFO]:-Found neither /usr/local/greenplum-db/bin/gp_email_contacts.yaml nor /home/gpadmin/gp_email_contacts.yaml
20241206:13:36:28 gprestore:gpadmin:Master-a:042776-[INFO]:-Email containing gprestore report /home/gpadmin/backups/gpseg-1/backups/20241206/20241206102913/gprestore_20241206102913_20241206133604_report will not be sent
20241206:13:36:28 gprestore:gpadmin:Master-a:042776-[INFO]:-Beginning cleanup
20241206:13:36:28 gprestore:gpadmin:Master-a:042776-[INFO]:-Cleanup complete
20241206:13:36:28 gprestore:gpadmin:Master-a:042776-[INFO]:-Restore completed successfully
[gpadmin@Master-a 20241206131336]$

# 进行完整备份

[gpadmin@Master-a ~]$ gpbackup --dbname backup_test_database --backup-dir /home/gpadmin/backups-incremental2/ --leaf-partition-data
20241206:13:44:03 gpbackup:gpadmin:Master-a:060041-[INFO]:-gpbackup version = 1.30.7
20241206:13:44:03 gpbackup:gpadmin:Master-a:060041-[INFO]:-Greenplum Database Version = 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source
20241206:13:44:03 gpbackup:gpadmin:Master-a:060041-[INFO]:-Starting backup of database backup_test_database
20241206:13:44:03 gpbackup:gpadmin:Master-a:060041-[INFO]:-Backup Timestamp = 20241206134403
20241206:13:44:03 gpbackup:gpadmin:Master-a:060041-[INFO]:-Backup Database = backup_test_database
20241206:13:44:03 gpbackup:gpadmin:Master-a:060041-[INFO]:-Gathering table state information
20241206:13:44:03 gpbackup:gpadmin:Master-a:060041-[INFO]:-Acquiring ACCESS SHARE locks on tables
Locks acquired:  10 / 10 [==============================================================] 100.00% 0s
20241206:13:44:03 gpbackup:gpadmin:Master-a:060041-[INFO]:-Gathering additional table metadata
20241206:13:44:03 gpbackup:gpadmin:Master-a:060041-[INFO]:-Getting partition definitions
20241206:13:44:03 gpbackup:gpadmin:Master-a:060041-[INFO]:-Getting storage information
20241206:13:44:03 gpbackup:gpadmin:Master-a:060041-[INFO]:-Getting child partitions with altered schema
20241206:13:44:03 gpbackup:gpadmin:Master-a:060041-[INFO]:-Metadata will be written to /home/gpadmin/backups-incremental2/gpseg-1/backups/20241206/20241206134403/gpbackup_20241206134403_metadata.sql
20241206:13:44:03 gpbackup:gpadmin:Master-a:060041-[INFO]:-Writing global database metadata
20241206:13:44:03 gpbackup:gpadmin:Master-a:060041-[INFO]:-Global database metadata backup complete
20241206:13:44:03 gpbackup:gpadmin:Master-a:060041-[INFO]:-Writing pre-data metadata
20241206:13:44:04 gpbackup:gpadmin:Master-a:060041-[INFO]:-Pre-data metadata metadata backup complete
20241206:13:44:04 gpbackup:gpadmin:Master-a:060041-[INFO]:-Writing post-data metadata
20241206:13:44:04 gpbackup:gpadmin:Master-a:060041-[INFO]:-Post-data metadata backup complete
20241206:13:44:04 gpbackup:gpadmin:Master-a:060041-[INFO]:-Writing data to file
Tables backed up:  10 / 10 [============================================================] 100.00% 8s
20241206:13:44:12 gpbackup:gpadmin:Master-a:060041-[INFO]:-Data backup complete
20241206:13:44:13 gpbackup:gpadmin:Master-a:060041-[INFO]:-Found neither /usr/local/greenplum-db/bin/gp_email_contacts.yaml nor /home/gpadmin/gp_email_contacts.yaml
20241206:13:44:13 gpbackup:gpadmin:Master-a:060041-[INFO]:-Email containing gpbackup report /home/gpadmin/backups-incremental2/gpseg-1/backups/20241206/20241206134403/gpbackup_20241206134403_report will not be sent
20241206:13:44:13 gpbackup:gpadmin:Master-a:060041-[INFO]:-Beginning cleanup
20241206:13:44:13 gpbackup:gpadmin:Master-a:060041-[INFO]:-Cleanup complete
20241206:13:44:13 gpbackup:gpadmin:Master-a:060041-[INFO]:-Backup completed successfully
[gpadmin@Master-a ~]$ cat /home/gpadmin/backups-incremental2/gpseg-1/backups/20241206/20241206134403/
cat: /home/gpadmin/backups-incremental2/gpseg-1/backups/20241206/20241206134403/: Is a directory
[gpadmin@Master-a ~]$ cat /home/gpadmin/backups-incremental2/gpseg-1/backups/20241206/20241206134403/gpbackup_20241206134403_report 
Greenplum Database Backup Report

timestamp key:         20241206134403
gpdb version:          6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source
gpbackup version:      1.30.7

database name:         backup_test_database
command line:          gpbackup --dbname backup_test_database --backup-dir /home/gpadmin/backups-incremental2/ --leaf-partition-data
compression:           gzip
plugin executable:     None
backup section:        All Sections
object filtering:      None
includes statistics:   No
data file format:      Multiple Data Files Per Segment
incremental:           False

start time:            Fri Dec 06 2024 13:44:03
end time:              Fri Dec 06 2024 13:44:13
duration:              0:00:10

backup status:         Success

database size:         4702 MB
segment count:         20

count of database objects in backup:
aggregates                   0
casts                        0
collations                   0
constraints                  10
conversions                  0
default privileges           0
database gucs                0
event triggers               0
extensions                   0
foreign data wrappers        0
foreign servers              0
functions                    0
indexes                      0
operator classes             0
operator families            0
operators                    0
procedural languages         0
protocols                    0
resource groups              2
resource queues              1
roles                        1
rules                        0
schemas                      1
sequences                    8
tables                       10
tablespaces                  0
text search configurations   0
text search dictionaries     0
text search parsers          0
text search templates        0
triggers                     0
types                        0
user mappings                0
views                        0
[gpadmin@Master-a ~]$

# 查看数据

[gpadmin@Master-a ~]$ for host in Master-a Standby-a Segment-a Segment-b Segment-c Segment-d; do   echo "===== $host =====";   ssh gpadmin@$host "tree /home/gpadmin/backups-incremental2/"; done
===== Master-a =====
/home/gpadmin/backups-incremental2/
└── gpseg-1
    └── backups
        └── 20241206
            └── 20241206134403
                ├── gpbackup_20241206134403_config.yaml
                ├── gpbackup_20241206134403_metadata.sql
                ├── gpbackup_20241206134403_report
                └── gpbackup_20241206134403_toc.yaml

4 directories, 4 files
===== Standby-a =====
/home/gpadmin/backups-incremental2/ [error opening dir]

0 directories, 0 files
===== Segment-a =====
/home/gpadmin/backups-incremental2/
├── gpseg0
│   └── backups
│       └── 20241206
│           └── 20241206134403
│               ├── gpbackup_0_20241206134403_74057.gz
│               ├── gpbackup_0_20241206134403_74060.gz
│               ├── gpbackup_0_20241206134403_74065.gz
│               ├── gpbackup_0_20241206134403_74068.gz
│               ├── gpbackup_0_20241206134403_74073.gz
│               ├── gpbackup_0_20241206134403_74076.gz
│               ├── gpbackup_0_20241206134403_74081.gz
│               ├── gpbackup_0_20241206134403_74085.gz
│               ├── gpbackup_0_20241206134403_74091.gz
│               └── gpbackup_0_20241206134403_74097.gz
├── gpseg1
│   └── backups
│       └── 20241206
│           └── 20241206134403
│               ├── gpbackup_1_20241206134403_74057.gz
│               ├── gpbackup_1_20241206134403_74060.gz
│               ├── gpbackup_1_20241206134403_74065.gz
│               ├── gpbackup_1_20241206134403_74068.gz
│               ├── gpbackup_1_20241206134403_74073.gz
│               ├── gpbackup_1_20241206134403_74076.gz
│               ├── gpbackup_1_20241206134403_74081.gz
│               ├── gpbackup_1_20241206134403_74085.gz
│               ├── gpbackup_1_20241206134403_74091.gz
│               └── gpbackup_1_20241206134403_74097.gz
├── gpseg16
│   └── backups
│       └── 20241206
│           └── 20241206134403
│               ├── gpbackup_16_20241206134403_74057.gz
│               ├── gpbackup_16_20241206134403_74060.gz
│               ├── gpbackup_16_20241206134403_74065.gz
│               ├── gpbackup_16_20241206134403_74068.gz
│               ├── gpbackup_16_20241206134403_74073.gz
│               ├── gpbackup_16_20241206134403_74076.gz
│               ├── gpbackup_16_20241206134403_74081.gz
│               ├── gpbackup_16_20241206134403_74085.gz
│               ├── gpbackup_16_20241206134403_74091.gz
│               └── gpbackup_16_20241206134403_74097.gz
├── gpseg4
│   └── backups
│       └── 20241206
│           └── 20241206134403
│               ├── gpbackup_4_20241206134403_74057.gz
│               ├── gpbackup_4_20241206134403_74060.gz
│               ├── gpbackup_4_20241206134403_74065.gz
│               ├── gpbackup_4_20241206134403_74068.gz
│               ├── gpbackup_4_20241206134403_74073.gz
│               ├── gpbackup_4_20241206134403_74076.gz
│               ├── gpbackup_4_20241206134403_74081.gz
│               ├── gpbackup_4_20241206134403_74085.gz
│               ├── gpbackup_4_20241206134403_74091.gz
│               └── gpbackup_4_20241206134403_74097.gz
└── gpseg5
    └── backups
        └── 20241206
            └── 20241206134403
                ├── gpbackup_5_20241206134403_74057.gz
                ├── gpbackup_5_20241206134403_74060.gz
                ├── gpbackup_5_20241206134403_74065.gz
                ├── gpbackup_5_20241206134403_74068.gz
                ├── gpbackup_5_20241206134403_74073.gz
                ├── gpbackup_5_20241206134403_74076.gz
                ├── gpbackup_5_20241206134403_74081.gz
                ├── gpbackup_5_20241206134403_74085.gz
                ├── gpbackup_5_20241206134403_74091.gz
                └── gpbackup_5_20241206134403_74097.gz

20 directories, 50 files
===== Segment-b =====
/home/gpadmin/backups-incremental2/
├── gpseg17
│   └── backups
│       └── 20241206
│           └── 20241206134403
│               ├── gpbackup_17_20241206134403_74057.gz
│               ├── gpbackup_17_20241206134403_74060.gz
│               ├── gpbackup_17_20241206134403_74065.gz
│               ├── gpbackup_17_20241206134403_74068.gz
│               ├── gpbackup_17_20241206134403_74073.gz
│               ├── gpbackup_17_20241206134403_74076.gz
│               ├── gpbackup_17_20241206134403_74081.gz
│               ├── gpbackup_17_20241206134403_74085.gz
│               ├── gpbackup_17_20241206134403_74091.gz
│               └── gpbackup_17_20241206134403_74097.gz
├── gpseg2
│   └── backups
│       └── 20241206
│           └── 20241206134403
│               ├── gpbackup_2_20241206134403_74057.gz
│               ├── gpbackup_2_20241206134403_74060.gz
│               ├── gpbackup_2_20241206134403_74065.gz
│               ├── gpbackup_2_20241206134403_74068.gz
│               ├── gpbackup_2_20241206134403_74073.gz
│               ├── gpbackup_2_20241206134403_74076.gz
│               ├── gpbackup_2_20241206134403_74081.gz
│               ├── gpbackup_2_20241206134403_74085.gz
│               ├── gpbackup_2_20241206134403_74091.gz
│               └── gpbackup_2_20241206134403_74097.gz
├── gpseg3
│   └── backups
│       └── 20241206
│           └── 20241206134403
│               ├── gpbackup_3_20241206134403_74057.gz
│               ├── gpbackup_3_20241206134403_74060.gz
│               ├── gpbackup_3_20241206134403_74065.gz
│               ├── gpbackup_3_20241206134403_74068.gz
│               ├── gpbackup_3_20241206134403_74073.gz
│               ├── gpbackup_3_20241206134403_74076.gz
│               ├── gpbackup_3_20241206134403_74081.gz
│               ├── gpbackup_3_20241206134403_74085.gz
│               ├── gpbackup_3_20241206134403_74091.gz
│               └── gpbackup_3_20241206134403_74097.gz
├── gpseg6
│   └── backups
│       └── 20241206
│           └── 20241206134403
│               ├── gpbackup_6_20241206134403_74057.gz
│               ├── gpbackup_6_20241206134403_74060.gz
│               ├── gpbackup_6_20241206134403_74065.gz
│               ├── gpbackup_6_20241206134403_74068.gz
│               ├── gpbackup_6_20241206134403_74073.gz
│               ├── gpbackup_6_20241206134403_74076.gz
│               ├── gpbackup_6_20241206134403_74081.gz
│               ├── gpbackup_6_20241206134403_74085.gz
│               ├── gpbackup_6_20241206134403_74091.gz
│               └── gpbackup_6_20241206134403_74097.gz
└── gpseg7
    └── backups
        └── 20241206
            └── 20241206134403
                ├── gpbackup_7_20241206134403_74057.gz
                ├── gpbackup_7_20241206134403_74060.gz
                ├── gpbackup_7_20241206134403_74065.gz
                ├── gpbackup_7_20241206134403_74068.gz
                ├── gpbackup_7_20241206134403_74073.gz
                ├── gpbackup_7_20241206134403_74076.gz
                ├── gpbackup_7_20241206134403_74081.gz
                ├── gpbackup_7_20241206134403_74085.gz
                ├── gpbackup_7_20241206134403_74091.gz
                └── gpbackup_7_20241206134403_74097.gz

20 directories, 50 files
===== Segment-c =====
/home/gpadmin/backups-incremental2/
├── gpseg10
│   └── backups
│       └── 20241206
│           └── 20241206134403
│               ├── gpbackup_10_20241206134403_74057.gz
│               ├── gpbackup_10_20241206134403_74060.gz
│               ├── gpbackup_10_20241206134403_74065.gz
│               ├── gpbackup_10_20241206134403_74068.gz
│               ├── gpbackup_10_20241206134403_74073.gz
│               ├── gpbackup_10_20241206134403_74076.gz
│               ├── gpbackup_10_20241206134403_74081.gz
│               ├── gpbackup_10_20241206134403_74085.gz
│               ├── gpbackup_10_20241206134403_74091.gz
│               └── gpbackup_10_20241206134403_74097.gz
├── gpseg11
│   └── backups
│       └── 20241206
│           └── 20241206134403
│               ├── gpbackup_11_20241206134403_74057.gz
│               ├── gpbackup_11_20241206134403_74060.gz
│               ├── gpbackup_11_20241206134403_74065.gz
│               ├── gpbackup_11_20241206134403_74068.gz
│               ├── gpbackup_11_20241206134403_74073.gz
│               ├── gpbackup_11_20241206134403_74076.gz
│               ├── gpbackup_11_20241206134403_74081.gz
│               ├── gpbackup_11_20241206134403_74085.gz
│               ├── gpbackup_11_20241206134403_74091.gz
│               └── gpbackup_11_20241206134403_74097.gz
├── gpseg18
│   └── backups
│       └── 20241206
│           └── 20241206134403
│               ├── gpbackup_18_20241206134403_74057.gz
│               ├── gpbackup_18_20241206134403_74060.gz
│               ├── gpbackup_18_20241206134403_74065.gz
│               ├── gpbackup_18_20241206134403_74068.gz
│               ├── gpbackup_18_20241206134403_74073.gz
│               ├── gpbackup_18_20241206134403_74076.gz
│               ├── gpbackup_18_20241206134403_74081.gz
│               ├── gpbackup_18_20241206134403_74085.gz
│               ├── gpbackup_18_20241206134403_74091.gz
│               └── gpbackup_18_20241206134403_74097.gz
├── gpseg8
│   └── backups
│       └── 20241206
│           └── 20241206134403
│               ├── gpbackup_8_20241206134403_74057.gz
│               ├── gpbackup_8_20241206134403_74060.gz
│               ├── gpbackup_8_20241206134403_74065.gz
│               ├── gpbackup_8_20241206134403_74068.gz
│               ├── gpbackup_8_20241206134403_74073.gz
│               ├── gpbackup_8_20241206134403_74076.gz
│               ├── gpbackup_8_20241206134403_74081.gz
│               ├── gpbackup_8_20241206134403_74085.gz
│               ├── gpbackup_8_20241206134403_74091.gz
│               └── gpbackup_8_20241206134403_74097.gz
└── gpseg9
    └── backups
        └── 20241206
            └── 20241206134403
                ├── gpbackup_9_20241206134403_74057.gz
                ├── gpbackup_9_20241206134403_74060.gz
                ├── gpbackup_9_20241206134403_74065.gz
                ├── gpbackup_9_20241206134403_74068.gz
                ├── gpbackup_9_20241206134403_74073.gz
                ├── gpbackup_9_20241206134403_74076.gz
                ├── gpbackup_9_20241206134403_74081.gz
                ├── gpbackup_9_20241206134403_74085.gz
                ├── gpbackup_9_20241206134403_74091.gz
                └── gpbackup_9_20241206134403_74097.gz

20 directories, 50 files
===== Segment-d =====
/home/gpadmin/backups-incremental2/
├── gpseg12
│   └── backups
│       └── 20241206
│           └── 20241206134403
│               ├── gpbackup_12_20241206134403_74057.gz
│               ├── gpbackup_12_20241206134403_74060.gz
│               ├── gpbackup_12_20241206134403_74065.gz
│               ├── gpbackup_12_20241206134403_74068.gz
│               ├── gpbackup_12_20241206134403_74073.gz
│               ├── gpbackup_12_20241206134403_74076.gz
│               ├── gpbackup_12_20241206134403_74081.gz
│               ├── gpbackup_12_20241206134403_74085.gz
│               ├── gpbackup_12_20241206134403_74091.gz
│               └── gpbackup_12_20241206134403_74097.gz
├── gpseg13
│   └── backups
│       └── 20241206
│           └── 20241206134403
│               ├── gpbackup_13_20241206134403_74057.gz
│               ├── gpbackup_13_20241206134403_74060.gz
│               ├── gpbackup_13_20241206134403_74065.gz
│               ├── gpbackup_13_20241206134403_74068.gz
│               ├── gpbackup_13_20241206134403_74073.gz
│               ├── gpbackup_13_20241206134403_74076.gz
│               ├── gpbackup_13_20241206134403_74081.gz
│               ├── gpbackup_13_20241206134403_74085.gz
│               ├── gpbackup_13_20241206134403_74091.gz
│               └── gpbackup_13_20241206134403_74097.gz
├── gpseg14
│   └── backups
│       └── 20241206
│           └── 20241206134403
│               ├── gpbackup_14_20241206134403_74057.gz
│               ├── gpbackup_14_20241206134403_74060.gz
│               ├── gpbackup_14_20241206134403_74065.gz
│               ├── gpbackup_14_20241206134403_74068.gz
│               ├── gpbackup_14_20241206134403_74073.gz
│               ├── gpbackup_14_20241206134403_74076.gz
│               ├── gpbackup_14_20241206134403_74081.gz
│               ├── gpbackup_14_20241206134403_74085.gz
│               ├── gpbackup_14_20241206134403_74091.gz
│               └── gpbackup_14_20241206134403_74097.gz
├── gpseg15
│   └── backups
│       └── 20241206
│           └── 20241206134403
│               ├── gpbackup_15_20241206134403_74057.gz
│               ├── gpbackup_15_20241206134403_74060.gz
│               ├── gpbackup_15_20241206134403_74065.gz
│               ├── gpbackup_15_20241206134403_74068.gz
│               ├── gpbackup_15_20241206134403_74073.gz
│               ├── gpbackup_15_20241206134403_74076.gz
│               ├── gpbackup_15_20241206134403_74081.gz
│               ├── gpbackup_15_20241206134403_74085.gz
│               ├── gpbackup_15_20241206134403_74091.gz
│               └── gpbackup_15_20241206134403_74097.gz
└── gpseg19
    └── backups
        └── 20241206
            └── 20241206134403
                ├── gpbackup_19_20241206134403_74057.gz
                ├── gpbackup_19_20241206134403_74060.gz
                ├── gpbackup_19_20241206134403_74065.gz
                ├── gpbackup_19_20241206134403_74068.gz
                ├── gpbackup_19_20241206134403_74073.gz
                ├── gpbackup_19_20241206134403_74076.gz
                ├── gpbackup_19_20241206134403_74081.gz
                ├── gpbackup_19_20241206134403_74085.gz
                ├── gpbackup_19_20241206134403_74091.gz
                └── gpbackup_19_20241206134403_74097.gz

20 directories, 50 files
[gpadmin@Master-a ~]$

# 做模拟数据录入
```

![image-20241206135814452](GreenPlum集群实验室-8-实验八：数据备份&数据恢复.assets/image-20241206135814452.png)

现在进行增量备份、

```powershell
# 基于刚刚创建的完整性备份进行增量备份

[gpadmin@Master-a ~]$ gpbackup --dbname backup_test_database --backup-dir /home/gpadmin/backups-incremental2/ --leaf-partition-data --incremental --from-timestamp 20241206134403
20241206:14:02:21 gpbackup:gpadmin:Master-a:100593-[INFO]:-gpbackup version = 1.30.7
20241206:14:02:21 gpbackup:gpadmin:Master-a:100593-[INFO]:-Greenplum Database Version = 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source
20241206:14:02:21 gpbackup:gpadmin:Master-a:100593-[INFO]:-Starting backup of database backup_test_database
20241206:14:02:21 gpbackup:gpadmin:Master-a:100593-[INFO]:-Backup Timestamp = 20241206140221
20241206:14:02:21 gpbackup:gpadmin:Master-a:100593-[INFO]:-Backup Database = backup_test_database
20241206:14:02:21 gpbackup:gpadmin:Master-a:100593-[INFO]:-Gathering table state information
20241206:14:02:22 gpbackup:gpadmin:Master-a:100593-[INFO]:-Acquiring ACCESS SHARE locks on tables
Locks acquired:  10 / 10 [==============================================================] 100.00% 0s
20241206:14:02:22 gpbackup:gpadmin:Master-a:100593-[INFO]:-Gathering additional table metadata
20241206:14:02:22 gpbackup:gpadmin:Master-a:100593-[INFO]:-Getting partition definitions
20241206:14:02:22 gpbackup:gpadmin:Master-a:100593-[INFO]:-Getting storage information
20241206:14:02:22 gpbackup:gpadmin:Master-a:100593-[INFO]:-Getting child partitions with altered schema
20241206:14:02:22 gpbackup:gpadmin:Master-a:100593-[INFO]:-Metadata will be written to /home/gpadmin/backups-incremental2/gpseg-1/backups/20241206/20241206140221/gpbackup_20241206140221_metadata.sql
20241206:14:02:22 gpbackup:gpadmin:Master-a:100593-[INFO]:-Basing incremental backup off of backup with timestamp = 20241206134403
20241206:14:02:22 gpbackup:gpadmin:Master-a:100593-[INFO]:-Writing global database metadata
20241206:14:02:22 gpbackup:gpadmin:Master-a:100593-[INFO]:-Global database metadata backup complete
20241206:14:02:22 gpbackup:gpadmin:Master-a:100593-[INFO]:-Writing pre-data metadata
20241206:14:02:22 gpbackup:gpadmin:Master-a:100593-[INFO]:-Pre-data metadata metadata backup complete
20241206:14:02:22 gpbackup:gpadmin:Master-a:100593-[INFO]:-Writing post-data metadata
20241206:14:02:22 gpbackup:gpadmin:Master-a:100593-[INFO]:-Post-data metadata backup complete
20241206:14:02:22 gpbackup:gpadmin:Master-a:100593-[INFO]:-Writing data to file
Tables backed up:  10 / 10 [============================================================] 100.00% 8s
20241206:14:02:30 gpbackup:gpadmin:Master-a:100593-[INFO]:-Data backup complete
20241206:14:02:31 gpbackup:gpadmin:Master-a:100593-[INFO]:-Found neither /usr/local/greenplum-db/bin/gp_email_contacts.yaml nor /home/gpadmin/gp_email_contacts.yaml
20241206:14:02:31 gpbackup:gpadmin:Master-a:100593-[INFO]:-Email containing gpbackup report /home/gpadmin/backups-incremental2/gpseg-1/backups/20241206/20241206140221/gpbackup_20241206140221_report will not be sent
20241206:14:02:31 gpbackup:gpadmin:Master-a:100593-[INFO]:-Beginning cleanup
20241206:14:02:31 gpbackup:gpadmin:Master-a:100593-[INFO]:-Cleanup complete
20241206:14:02:31 gpbackup:gpadmin:Master-a:100593-[INFO]:-Backup completed successfully
[gpadmin@Master-a ~]$

# 查看增量备份数据

[gpadmin@Master-a ~]$ for host in Master-a Standby-a Segment-a Segment-b Segment-c Segment-d; do   echo "===== $host =====";   ssh gpadmin@$host "tree /home/gpadmin/backups-incremental2/"; done
===== Master-a =====
/home/gpadmin/backups-incremental2/
└── gpseg-1
    └── backups
        └── 20241206
            ├── 20241206134403
            │   ├── gpbackup_20241206134403_config.yaml
            │   ├── gpbackup_20241206134403_metadata.sql
            │   ├── gpbackup_20241206134403_report
            │   └── gpbackup_20241206134403_toc.yaml
            └── 20241206140221
                ├── gpbackup_20241206140221_config.yaml
                ├── gpbackup_20241206140221_metadata.sql
                ├── gpbackup_20241206140221_report
                └── gpbackup_20241206140221_toc.yaml

5 directories, 8 files
===== Standby-a =====
/home/gpadmin/backups-incremental2/ [error opening dir]

0 directories, 0 files
===== Segment-a =====
/home/gpadmin/backups-incremental2/
├── gpseg0
│   └── backups
│       └── 20241206
│           ├── 20241206134403
│           │   ├── gpbackup_0_20241206134403_74057.gz
│           │   ├── gpbackup_0_20241206134403_74060.gz
│           │   ├── gpbackup_0_20241206134403_74065.gz
│           │   ├── gpbackup_0_20241206134403_74068.gz
│           │   ├── gpbackup_0_20241206134403_74073.gz
│           │   ├── gpbackup_0_20241206134403_74076.gz
│           │   ├── gpbackup_0_20241206134403_74081.gz
│           │   ├── gpbackup_0_20241206134403_74085.gz
│           │   ├── gpbackup_0_20241206134403_74091.gz
│           │   └── gpbackup_0_20241206134403_74097.gz
│           └── 20241206140221
│               ├── gpbackup_0_20241206140221_74057.gz
│               ├── gpbackup_0_20241206140221_74060.gz
│               ├── gpbackup_0_20241206140221_74065.gz
│               ├── gpbackup_0_20241206140221_74068.gz
│               ├── gpbackup_0_20241206140221_74073.gz
│               ├── gpbackup_0_20241206140221_74081.gz
│               ├── gpbackup_0_20241206140221_74085.gz
│               ├── gpbackup_0_20241206140221_74091.gz
│               ├── gpbackup_0_20241206140221_74097.gz
│               └── gpbackup_0_20241206140221_74129.gz
├── gpseg1
│   └── backups
│       └── 20241206
│           ├── 20241206134403
│           │   ├── gpbackup_1_20241206134403_74057.gz
│           │   ├── gpbackup_1_20241206134403_74060.gz
│           │   ├── gpbackup_1_20241206134403_74065.gz
│           │   ├── gpbackup_1_20241206134403_74068.gz
│           │   ├── gpbackup_1_20241206134403_74073.gz
│           │   ├── gpbackup_1_20241206134403_74076.gz
│           │   ├── gpbackup_1_20241206134403_74081.gz
│           │   ├── gpbackup_1_20241206134403_74085.gz
│           │   ├── gpbackup_1_20241206134403_74091.gz
│           │   └── gpbackup_1_20241206134403_74097.gz
│           └── 20241206140221
│               ├── gpbackup_1_20241206140221_74057.gz
│               ├── gpbackup_1_20241206140221_74060.gz
│               ├── gpbackup_1_20241206140221_74065.gz
│               ├── gpbackup_1_20241206140221_74068.gz
│               ├── gpbackup_1_20241206140221_74073.gz
│               ├── gpbackup_1_20241206140221_74081.gz
│               ├── gpbackup_1_20241206140221_74085.gz
│               ├── gpbackup_1_20241206140221_74091.gz
│               ├── gpbackup_1_20241206140221_74097.gz
│               └── gpbackup_1_20241206140221_74129.gz
├── gpseg16
│   └── backups
│       └── 20241206
│           ├── 20241206134403
│           │   ├── gpbackup_16_20241206134403_74057.gz
│           │   ├── gpbackup_16_20241206134403_74060.gz
│           │   ├── gpbackup_16_20241206134403_74065.gz
│           │   ├── gpbackup_16_20241206134403_74068.gz
│           │   ├── gpbackup_16_20241206134403_74073.gz
│           │   ├── gpbackup_16_20241206134403_74076.gz
│           │   ├── gpbackup_16_20241206134403_74081.gz
│           │   ├── gpbackup_16_20241206134403_74085.gz
│           │   ├── gpbackup_16_20241206134403_74091.gz
│           │   └── gpbackup_16_20241206134403_74097.gz
│           └── 20241206140221
│               ├── gpbackup_16_20241206140221_74057.gz
│               ├── gpbackup_16_20241206140221_74060.gz
│               ├── gpbackup_16_20241206140221_74065.gz
│               ├── gpbackup_16_20241206140221_74068.gz
│               ├── gpbackup_16_20241206140221_74073.gz
│               ├── gpbackup_16_20241206140221_74081.gz
│               ├── gpbackup_16_20241206140221_74085.gz
│               ├── gpbackup_16_20241206140221_74091.gz
│               ├── gpbackup_16_20241206140221_74097.gz
│               └── gpbackup_16_20241206140221_74129.gz
├── gpseg4
│   └── backups
│       └── 20241206
│           ├── 20241206134403
│           │   ├── gpbackup_4_20241206134403_74057.gz
│           │   ├── gpbackup_4_20241206134403_74060.gz
│           │   ├── gpbackup_4_20241206134403_74065.gz
│           │   ├── gpbackup_4_20241206134403_74068.gz
│           │   ├── gpbackup_4_20241206134403_74073.gz
│           │   ├── gpbackup_4_20241206134403_74076.gz
│           │   ├── gpbackup_4_20241206134403_74081.gz
│           │   ├── gpbackup_4_20241206134403_74085.gz
│           │   ├── gpbackup_4_20241206134403_74091.gz
│           │   └── gpbackup_4_20241206134403_74097.gz
│           └── 20241206140221
│               ├── gpbackup_4_20241206140221_74057.gz
│               ├── gpbackup_4_20241206140221_74060.gz
│               ├── gpbackup_4_20241206140221_74065.gz
│               ├── gpbackup_4_20241206140221_74068.gz
│               ├── gpbackup_4_20241206140221_74073.gz
│               ├── gpbackup_4_20241206140221_74081.gz
│               ├── gpbackup_4_20241206140221_74085.gz
│               ├── gpbackup_4_20241206140221_74091.gz
│               ├── gpbackup_4_20241206140221_74097.gz
│               └── gpbackup_4_20241206140221_74129.gz
└── gpseg5
    └── backups
        └── 20241206
            ├── 20241206134403
            │   ├── gpbackup_5_20241206134403_74057.gz
            │   ├── gpbackup_5_20241206134403_74060.gz
            │   ├── gpbackup_5_20241206134403_74065.gz
            │   ├── gpbackup_5_20241206134403_74068.gz
            │   ├── gpbackup_5_20241206134403_74073.gz
            │   ├── gpbackup_5_20241206134403_74076.gz
            │   ├── gpbackup_5_20241206134403_74081.gz
            │   ├── gpbackup_5_20241206134403_74085.gz
            │   ├── gpbackup_5_20241206134403_74091.gz
            │   └── gpbackup_5_20241206134403_74097.gz
            └── 20241206140221
                ├── gpbackup_5_20241206140221_74057.gz
                ├── gpbackup_5_20241206140221_74060.gz
                ├── gpbackup_5_20241206140221_74065.gz
                ├── gpbackup_5_20241206140221_74068.gz
                ├── gpbackup_5_20241206140221_74073.gz
                ├── gpbackup_5_20241206140221_74081.gz
                ├── gpbackup_5_20241206140221_74085.gz
                ├── gpbackup_5_20241206140221_74091.gz
                ├── gpbackup_5_20241206140221_74097.gz
                └── gpbackup_5_20241206140221_74129.gz

25 directories, 100 files
===== Segment-b =====
/home/gpadmin/backups-incremental2/
├── gpseg17
│   └── backups
│       └── 20241206
│           ├── 20241206134403
│           │   ├── gpbackup_17_20241206134403_74057.gz
│           │   ├── gpbackup_17_20241206134403_74060.gz
│           │   ├── gpbackup_17_20241206134403_74065.gz
│           │   ├── gpbackup_17_20241206134403_74068.gz
│           │   ├── gpbackup_17_20241206134403_74073.gz
│           │   ├── gpbackup_17_20241206134403_74076.gz
│           │   ├── gpbackup_17_20241206134403_74081.gz
│           │   ├── gpbackup_17_20241206134403_74085.gz
│           │   ├── gpbackup_17_20241206134403_74091.gz
│           │   └── gpbackup_17_20241206134403_74097.gz
│           └── 20241206140221
│               ├── gpbackup_17_20241206140221_74057.gz
│               ├── gpbackup_17_20241206140221_74060.gz
│               ├── gpbackup_17_20241206140221_74065.gz
│               ├── gpbackup_17_20241206140221_74068.gz
│               ├── gpbackup_17_20241206140221_74073.gz
│               ├── gpbackup_17_20241206140221_74081.gz
│               ├── gpbackup_17_20241206140221_74085.gz
│               ├── gpbackup_17_20241206140221_74091.gz
│               ├── gpbackup_17_20241206140221_74097.gz
│               └── gpbackup_17_20241206140221_74129.gz
├── gpseg2
│   └── backups
│       └── 20241206
│           ├── 20241206134403
│           │   ├── gpbackup_2_20241206134403_74057.gz
│           │   ├── gpbackup_2_20241206134403_74060.gz
│           │   ├── gpbackup_2_20241206134403_74065.gz
│           │   ├── gpbackup_2_20241206134403_74068.gz
│           │   ├── gpbackup_2_20241206134403_74073.gz
│           │   ├── gpbackup_2_20241206134403_74076.gz
│           │   ├── gpbackup_2_20241206134403_74081.gz
│           │   ├── gpbackup_2_20241206134403_74085.gz
│           │   ├── gpbackup_2_20241206134403_74091.gz
│           │   └── gpbackup_2_20241206134403_74097.gz
│           └── 20241206140221
│               ├── gpbackup_2_20241206140221_74057.gz
│               ├── gpbackup_2_20241206140221_74060.gz
│               ├── gpbackup_2_20241206140221_74065.gz
│               ├── gpbackup_2_20241206140221_74068.gz
│               ├── gpbackup_2_20241206140221_74073.gz
│               ├── gpbackup_2_20241206140221_74081.gz
│               ├── gpbackup_2_20241206140221_74085.gz
│               ├── gpbackup_2_20241206140221_74091.gz
│               ├── gpbackup_2_20241206140221_74097.gz
│               └── gpbackup_2_20241206140221_74129.gz
├── gpseg3
│   └── backups
│       └── 20241206
│           ├── 20241206134403
│           │   ├── gpbackup_3_20241206134403_74057.gz
│           │   ├── gpbackup_3_20241206134403_74060.gz
│           │   ├── gpbackup_3_20241206134403_74065.gz
│           │   ├── gpbackup_3_20241206134403_74068.gz
│           │   ├── gpbackup_3_20241206134403_74073.gz
│           │   ├── gpbackup_3_20241206134403_74076.gz
│           │   ├── gpbackup_3_20241206134403_74081.gz
│           │   ├── gpbackup_3_20241206134403_74085.gz
│           │   ├── gpbackup_3_20241206134403_74091.gz
│           │   └── gpbackup_3_20241206134403_74097.gz
│           └── 20241206140221
│               ├── gpbackup_3_20241206140221_74057.gz
│               ├── gpbackup_3_20241206140221_74060.gz
��               ├── gpbackup_3_20241206140221_74065.gz
│               ├── gpbackup_3_20241206140221_74068.gz
│               ├── gpbackup_3_20241206140221_74073.gz
│               ├── gpbackup_3_20241206140221_74081.gz
│               ├── gpbackup_3_20241206140221_74085.gz
│               ├── gpbackup_3_20241206140221_74091.gz
│               ├── gpbackup_3_20241206140221_74097.gz
│               └── gpbackup_3_20241206140221_74129.gz
├── gpseg6
│   └── backups
│       └── 20241206
│           ├── 20241206134403
│           │   ├── gpbackup_6_20241206134403_74057.gz
│           │   ├── gpbackup_6_20241206134403_74060.gz
│           │   ├── gpbackup_6_20241206134403_74065.gz
│           │   ├── gpbackup_6_20241206134403_74068.gz
│           │   ├── gpbackup_6_20241206134403_74073.gz
│           │   ├── gpbackup_6_20241206134403_74076.gz
│           │   ├── gpbackup_6_20241206134403_74081.gz
│           │   ├── gpbackup_6_20241206134403_74085.gz
│           │   ├── gpbackup_6_20241206134403_74091.gz
│           │   └── gpbackup_6_20241206134403_74097.gz
│           └── 20241206140221
│               ├── gpbackup_6_20241206140221_74057.gz
│               ├── gpbackup_6_20241206140221_74060.gz
│               ├── gpbackup_6_20241206140221_74065.gz
│               ├── gpbackup_6_20241206140221_74068.gz
│               ├── gpbackup_6_20241206140221_74073.gz
│               ├── gpbackup_6_20241206140221_74081.gz
│               ├── gpbackup_6_20241206140221_74085.gz
│               ├── gpbackup_6_20241206140221_74091.gz
│               ├── gpbackup_6_20241206140221_74097.gz
│               └── gpbackup_6_20241206140221_74129.gz
└── gpseg7
    └── backups
        └── 20241206
            ├── 20241206134403
            │   ├── gpbackup_7_20241206134403_74057.gz
            │   ├── gpbackup_7_20241206134403_74060.gz
            │   ├── gpbackup_7_20241206134403_74065.gz
            │   ├── gpbackup_7_20241206134403_74068.gz
            │   ├── gpbackup_7_20241206134403_74073.gz
            │   ├── gpbackup_7_20241206134403_74076.gz
            │   ├── gpbackup_7_20241206134403_74081.gz
            │   ├── gpbackup_7_20241206134403_74085.gz
            │   ├── gpbackup_7_20241206134403_74091.gz
            │   └── gpbackup_7_20241206134403_74097.gz
            └── 20241206140221
                ├── gpbackup_7_20241206140221_74057.gz
                ├── gpbackup_7_20241206140221_74060.gz
                ├── gpbackup_7_20241206140221_74065.gz
                ├── gpbackup_7_20241206140221_74068.gz
                ├── gpbackup_7_20241206140221_74073.gz
                ├── gpbackup_7_20241206140221_74081.gz
                ├── gpbackup_7_20241206140221_74085.gz
                ├── gpbackup_7_20241206140221_74091.gz
                ├── gpbackup_7_20241206140221_74097.gz
                └── gpbackup_7_20241206140221_74129.gz

25 directories, 100 files
===== Segment-c =====
/home/gpadmin/backups-incremental2/
├── gpseg10
│   └── backups
│       └── 20241206
│           ├── 20241206134403
│           │   ├── gpbackup_10_20241206134403_74057.gz
│           │   ├── gpbackup_10_20241206134403_74060.gz
│           │   ├── gpbackup_10_20241206134403_74065.gz
│           │   ├── gpbackup_10_20241206134403_74068.gz
│           │   ├── gpbackup_10_20241206134403_74073.gz
│           │   ├── gpbackup_10_20241206134403_74076.gz
│           │   ├── gpbackup_10_20241206134403_74081.gz
│           │   ├── gpbackup_10_20241206134403_74085.gz
│           │   ├── gpbackup_10_20241206134403_74091.gz
│           │   └── gpbackup_10_20241206134403_74097.gz
│           └── 20241206140221
│               ├── gpbackup_10_20241206140221_74057.gz
│               ├── gpbackup_10_20241206140221_74060.gz
│               ├── gpbackup_10_20241206140221_74065.gz
│               ├── gpbackup_10_20241206140221_74068.gz
│               ├── gpbackup_10_20241206140221_74073.gz
│               ├── gpbackup_10_20241206140221_74081.gz
│               ├── gpbackup_10_20241206140221_74085.gz
│               ├── gpbackup_10_20241206140221_74091.gz
│               ├── gpbackup_10_20241206140221_74097.gz
│               └── gpbackup_10_20241206140221_74129.gz
├── gpseg11
│   └── backups
│       └── 20241206
│           ├── 20241206134403
│           │   ├── gpbackup_11_20241206134403_74057.gz
│           │   ├── gpbackup_11_20241206134403_74060.gz
│           │   ├── gpbackup_11_20241206134403_74065.gz
│           │   ├── gpbackup_11_20241206134403_74068.gz
│           │   ├── gpbackup_11_20241206134403_74073.gz
│           │   ├── gpbackup_11_20241206134403_74076.gz
│           │   ├── gpbackup_11_20241206134403_74081.gz
│           │   ├── gpbackup_11_20241206134403_74085.gz
│           │   ├── gpbackup_11_20241206134403_74091.gz
│           │   └── gpbackup_11_20241206134403_74097.gz
│           └── 20241206140221
│               ├── gpbackup_11_20241206140221_74057.gz
│               ├── gpbackup_11_20241206140221_74060.gz
│               ├── gpbackup_11_20241206140221_74065.gz
│               ├── gpbackup_11_20241206140221_74068.gz
│               ├── gpbackup_11_20241206140221_74073.gz
│               ├── gpbackup_11_20241206140221_74081.gz
│               ├── gpbackup_11_20241206140221_74085.gz
│               ├── gpbackup_11_20241206140221_74091.gz
│               ├── gpbackup_11_20241206140221_74097.gz
│               └── gpbackup_11_20241206140221_74129.gz
├── gpseg18
│   └── backups
│       └── 20241206
│           ├── 20241206134403
│           │   ├── gpbackup_18_20241206134403_74057.gz
│           │   ├── gpbackup_18_20241206134403_74060.gz
│           │   ├── gpbackup_18_20241206134403_74065.gz
│           │   ├── gpbackup_18_20241206134403_74068.gz
│           │   ├── gpbackup_18_20241206134403_74073.gz
│           │   ├── gpbackup_18_20241206134403_74076.gz
│           │   ├── gpbackup_18_20241206134403_74081.gz
│           │   ├── gpbackup_18_20241206134403_74085.gz
│           │   ├── gpbackup_18_20241206134403_74091.gz
│           │   └── gpbackup_18_20241206134403_74097.gz
│           └── 20241206140221
│               ├── gpbackup_18_20241206140221_74057.gz
│               ├── gpbackup_18_20241206140221_74060.gz
│               ├── gpbackup_18_20241206140221_74065.gz
│               ├── gpbackup_18_20241206140221_74068.gz
│               ├── gpbackup_18_20241206140221_74073.gz
│               ├── gpbackup_18_20241206140221_74081.gz
│               ├── gpbackup_18_20241206140221_74085.gz
│               ├── gpbackup_18_20241206140221_74091.gz
│               ├── gpbackup_18_20241206140221_74097.gz
│               └── gpbackup_18_20241206140221_74129.gz
├── gpseg8
│   └── backups
│       └── 20241206
│           ├── 20241206134403
│           │   ├── gpbackup_8_20241206134403_74057.gz
│           │   ├── gpbackup_8_20241206134403_74060.gz
│           │   ├── gpbackup_8_20241206134403_74065.gz
│           │   ├── gpbackup_8_20241206134403_74068.gz
│           │   ├── gpbackup_8_20241206134403_74073.gz
│           │   ├── gpbackup_8_20241206134403_74076.gz
│           │   ├── gpbackup_8_20241206134403_74081.gz
│           │   ├── gpbackup_8_20241206134403_74085.gz
│           │   ├── gpbackup_8_20241206134403_74091.gz
│           │   └── gpbackup_8_20241206134403_74097.gz
│           └── 20241206140221
│               ├── gpbackup_8_20241206140221_74057.gz
│               ├── gpbackup_8_20241206140221_74060.gz
│               ├── gpbackup_8_20241206140221_74065.gz
│               ├── gpbackup_8_20241206140221_74068.gz
│               ├── gpbackup_8_20241206140221_74073.gz
│               ├── gpbackup_8_20241206140221_74081.gz
│               ├── gpbackup_8_20241206140221_74085.gz
│               ├── gpbackup_8_20241206140221_74091.gz
│               ├── gpbackup_8_20241206140221_74097.gz
│               └── gpbackup_8_20241206140221_74129.gz
└── gpseg9
    └── backups
        └── 20241206
            ├── 20241206134403
            │   ├── gpbackup_9_20241206134403_74057.gz
            │   ├── gpbackup_9_20241206134403_74060.gz
            │   ├── gpbackup_9_20241206134403_74065.gz
            │   ├── gpbackup_9_20241206134403_74068.gz
            │   ├── gpbackup_9_20241206134403_74073.gz
            │   ├── gpbackup_9_20241206134403_74076.gz
            │   ├── gpbackup_9_20241206134403_74081.gz
            │   ├── gpbackup_9_20241206134403_74085.gz
            │   ├── gpbackup_9_20241206134403_74091.gz
            │   └── gpbackup_9_20241206134403_74097.gz
            └── 20241206140221
                ├── gpbackup_9_20241206140221_74057.gz
                ├── gpbackup_9_20241206140221_74060.gz
                ├── gpbackup_9_20241206140221_74065.gz
                ├── gpbackup_9_20241206140221_74068.gz
                ├── gpbackup_9_20241206140221_74073.gz
                ├── gpbackup_9_20241206140221_74081.gz
                ├── gpbackup_9_20241206140221_74085.gz
                ├── gpbackup_9_20241206140221_74091.gz
                ├── gpbackup_9_20241206140221_74097.gz
                └── gpbackup_9_20241206140221_74129.gz

25 directories, 100 files
===== Segment-d =====
/home/gpadmin/backups-incremental2/
├── gpseg12
│   └── backups
│       └── 20241206
│           ├── 20241206134403
│           │   ├── gpbackup_12_20241206134403_74057.gz
│           │   ├── gpbackup_12_20241206134403_74060.gz
│           │   ├── gpbackup_12_20241206134403_74065.gz
│           │   ├── gpbackup_12_20241206134403_74068.gz
│           │   ├── gpbackup_12_20241206134403_74073.gz
│           │   ├── gpbackup_12_20241206134403_74076.gz
│           │   ├── gpbackup_12_20241206134403_74081.gz
│           │   ├── gpbackup_12_20241206134403_74085.gz
│           │   ├── gpbackup_12_20241206134403_74091.gz
│           │   └── gpbackup_12_20241206134403_74097.gz
│           └── 20241206140221
│               ├── gpbackup_12_20241206140221_74057.gz
│               ├── gpbackup_12_20241206140221_74060.gz
│               ├── gpbackup_12_20241206140221_74065.gz
│               ├── gpbackup_12_20241206140221_74068.gz
│               ├── gpbackup_12_20241206140221_74073.gz
│               ├── gpbackup_12_20241206140221_74081.gz
│               ├── gpbackup_12_20241206140221_74085.gz
│               ├── gpbackup_12_20241206140221_74091.gz
│               ├── gpbackup_12_20241206140221_74097.gz
│               └── gpbackup_12_20241206140221_74129.gz
├── gpseg13
│   └── backups
│       └── 20241206
│           ├── 20241206134403
│           │   ├── gpbackup_13_20241206134403_74057.gz
│           │   ├── gpbackup_13_20241206134403_74060.gz
│           │   ├── gpbackup_13_20241206134403_74065.gz
│           │   ├── gpbackup_13_20241206134403_74068.gz
│           │   ├── gpbackup_13_20241206134403_74073.gz
│           │   ├── gpbackup_13_20241206134403_74076.gz
│           │   ├── gpbackup_13_20241206134403_74081.gz
│           │   ├── gpbackup_13_20241206134403_74085.gz
│           │   ├── gpbackup_13_20241206134403_74091.gz
│           │   └── gpbackup_13_20241206134403_74097.gz
│           └── 20241206140221
│               ├── gpbackup_13_20241206140221_74057.gz
│               ├── gpbackup_13_20241206140221_74060.gz
│               ├── gpbackup_13_20241206140221_74065.gz
│               ├── gpbackup_13_20241206140221_74068.gz
│               ├── gpbackup_13_20241206140221_74073.gz
│               ├── gpbackup_13_20241206140221_74081.gz
│               ├── gpbackup_13_20241206140221_74085.gz
│               ├── gpbackup_13_20241206140221_74091.gz
│               ├── gpbackup_13_20241206140221_74097.gz
│               └── gpbackup_13_20241206140221_74129.gz
├── gpseg14
│   └── backups
│       └── 20241206
│           ├── 20241206134403
│           │   ├── gpbackup_14_20241206134403_74057.gz
│           │   ├── gpbackup_14_20241206134403_74060.gz
│           │   ├── gpbackup_14_20241206134403_74065.gz
│           │   ├── gpbackup_14_20241206134403_74068.gz
│           │   ├── gpbackup_14_20241206134403_74073.gz
│           │   ├── gpbackup_14_20241206134403_74076.gz
│           │   ├── gpbackup_14_20241206134403_74081.gz
│           │   ├── gpbackup_14_20241206134403_74085.gz
│           │   ├── gpbackup_14_20241206134403_74091.gz
│           │   └── gpbackup_14_20241206134403_74097.gz
│           └── 20241206140221
│               ├── gpbackup_14_20241206140221_74057.gz
│               ├── gpbackup_14_20241206140221_74060.gz
│               ├── gpbackup_14_20241206140221_74065.gz
│               ├── gpbackup_14_20241206140221_74068.gz
│               ├── gpbackup_14_20241206140221_74073.gz
│               ├── gpbackup_14_20241206140221_74081.gz
│               ├── gpbackup_14_20241206140221_74085.gz
│               ├── gpbackup_14_20241206140221_74091.gz
│               ├── gpbackup_14_20241206140221_74097.gz
│               └── gpbackup_14_20241206140221_74129.gz
├── gpseg15
│   └── backups
│       └── 20241206
│           ├── 20241206134403
│           │   ├── gpbackup_15_20241206134403_74057.gz
│           │   ├── gpbackup_15_20241206134403_74060.gz
│           │   ├── gpbackup_15_20241206134403_74065.gz
│           │   ├── gpbackup_15_20241206134403_74068.gz
│           │   ├── gpbackup_15_20241206134403_74073.gz
│           │   ├── gpbackup_15_20241206134403_74076.gz
│           │   ├── gpbackup_15_20241206134403_74081.gz
│           │   ├── gpbackup_15_20241206134403_74085.gz
│           │   ├── gpbackup_15_20241206134403_74091.gz
│           │   └── gpbackup_15_20241206134403_74097.gz
│           └── 20241206140221
│               ├── gpbackup_15_20241206140221_74057.gz
│               ├── gpbackup_15_20241206140221_74060.gz
│               ├── gpbackup_15_20241206140221_74065.gz
│               ├── gpbackup_15_20241206140221_74068.gz
│               ├── gpbackup_15_20241206140221_74073.gz
│               ├── gpbackup_15_20241206140221_74081.gz
│               ├── gpbackup_15_20241206140221_74085.gz
│               ├── gpbackup_15_20241206140221_74091.gz
│               ├── gpbackup_15_20241206140221_74097.gz
│               └── gpbackup_15_20241206140221_74129.gz
└── gpseg19
    └── backups
        └── 20241206
            ├── 20241206134403
            │   ├── gpbackup_19_20241206134403_74057.gz
            │   ├── gpbackup_19_20241206134403_74060.gz
            │   ├── gpbackup_19_20241206134403_74065.gz
            │   ├── gpbackup_19_20241206134403_74068.gz
            │   ├── gpbackup_19_20241206134403_74073.gz
            │   ├── gpbackup_19_20241206134403_74076.gz
            │   ├── gpbackup_19_20241206134403_74081.gz
            │   ├── gpbackup_19_20241206134403_74085.gz
            │   ├── gpbackup_19_20241206134403_74091.gz
            │   └── gpbackup_19_20241206134403_74097.gz
            └── 20241206140221
                ├── gpbackup_19_20241206140221_74057.gz
                ├── gpbackup_19_20241206140221_74060.gz
                ├── gpbackup_19_20241206140221_74065.gz
                ├── gpbackup_19_20241206140221_74068.gz
                ├── gpbackup_19_20241206140221_74073.gz
                ├── gpbackup_19_20241206140221_74081.gz
                ├── gpbackup_19_20241206140221_74085.gz
                ├── gpbackup_19_20241206140221_74091.gz
                ├── gpbackup_19_20241206140221_74097.gz
                └── gpbackup_19_20241206140221_74129.gz

25 directories, 100 files
[gpadmin@Master-a ~]$
```













