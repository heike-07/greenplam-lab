# GreenPlum集群实验室

> Author ：Heike07

[TOC]

## 实验二：在原有集群基础上扩容2个Segment_instance_primary不含Mirror

### 原理

扩容分为横向扩容，和纵向扩容。

**横向扩容为：**增加segment节点也就是物理主机节点，随着增加了物理主机节点segment同时也会生成segment实例，如果不进行设置默认是与原始集群保持一致的。

**纵向扩容为：**所谓纵向扩容即为增加segment实例，而不是新增机器。

当原始集群的内存和磁盘充足时可以考虑先进行纵向扩容，来进行扩容结果的验证，多为查询等。

### 确认环境情况

```powershell
[gpadmin@Master-a root]$ gpstate
20240611:11:09:12:001608 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: 
20240611:11:09:12:001608 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240611:11:09:12:001608 gpstate:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240611:11:09:12:001608 gpstate:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240611:11:09:12:001608 gpstate:Master-a:gpadmin-[INFO]:-Gathering data from segments...
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-Greenplum instance status summary
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Master instance                                = Active
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Master standby                                 = No master standby configured
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Total segment instance count from metadata     = 4
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Primary Segment Status
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segments                         = 4
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment valid (at master)        = 4
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment failures (at master)     = 0
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files missing   = 0
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files found     = 4
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing    = 0
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found      = 4
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files missing        = 0
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files found          = 4
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes missing      = 0
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes found        = 4
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Mirror Segment Status
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-   Mirrors not configured on this array
20240611:11:09:13:001608 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
[gpadmin@Master-a root]$

gpstart, gplogfilter[gpadmin@Master-a root]$ gpstate -s
20240611:11:22:15:001700 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: -s
20240611:11:22:15:001700 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240611:11:22:15:001700 gpstate:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240611:11:22:15:001700 gpstate:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240611:11:22:15:001700 gpstate:Master-a:gpadmin-[INFO]:-Gathering data from segments...
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:--Master Configuration & Status
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Master host                    = Master-a
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Master postgres process ID     = 1591
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Master data directory          = /home/gpadmin/data/master/gpseg-1
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Master port                    = 5432
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Master current role            = dispatch
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Greenplum initsystem version   = 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Greenplum current version      = PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Postgres version               = 9.4.24
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Master standby                 = No master standby configured
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-Segment Instance Status Report
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-a
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-a
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg0
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6000
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1540
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-a
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-a
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg1
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6001
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1539
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-b
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-b
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg2
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6000
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1539
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-b
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-b
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg3
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6001
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1540
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240611:11:22:16:001700 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
[gpadmin@Master-a root]$

由此分析gp版本为6.13 ,且pg数据库为9.4版本，mirror未开启镜像，seg主机节点数量2，seg实例数量为4，seg分布为2台seg数据节点对应2个seg实例。
```

### 创建测试数据

```plsql
# 创建一个UTF-8的数据库
CREATE DATABASE test_database WITH OWNER = gpadmin ENCODING = 'UTF-8';

# 创建一个测试表
CREATE TABLE table_test(
  ID INT PRIMARY KEY   NOT NULL,
  NAME      TEXT  NOT NULL,
  AGE      INT   NOT NULL,
  ADDRESS    CHAR(50),
  SALARY     REAL
);

# 写入随机测试数据500w
DO $$
DECLARE
  batch_size INTEGER := 500000;
  num_batches INTEGER := 10;
BEGIN
  FOR i IN 1..num_batches LOOP
    INSERT INTO table_test (ID, NAME, AGE, ADDRESS, SALARY)
    SELECT 
      g.key,
      repeat(chr(int4(random() * 26 + 65)), 16),
      (random() * 36)::integer,
      NULL,
      (random() * 10000)::integer
    FROM (
      SELECT generate_series((i-1)*batch_size + 1, i*batch_size) AS key
    ) g;
  END LOOP;
END $$;

# 查看数据结果
test_database=# select count(1) from table_test;
  count
---------
 5000000
(1 row)

test_database=# 

# 查看数据
test_database=# select * from table_test limit 5;
 id |       name       | age | address | salary
----+------------------+-----+---------+--------
  1 | XXXXXXXXXXXXXXXX |  20 |         |   5555
 12 | KKKKKKKKKKKKKKKK |  33 |         |   6319
 15 | YYYYYYYYYYYYYYYY |   6 |         |   7837
 20 | IIIIIIIIIIIIIIII |  23 |         |   7650
 23 | PPPPPPPPPPPPPPPP |   3 |         |   9389
(5 rows)

test_database=# 

可以看到已经生成了500w数据
```

### 查看数据分布

```powershell
test_database=# SELECT gp_segment_id,count(1) FROM table_test
GROUP BY gp_segment_id
ORDER BY gp_segment_id;
 gp_segment_id |  count
---------------+---------
             0 | 1249354
             1 | 1249079
             2 | 1250529
             3 | 1251038
(4 rows)

test_database=# 

可以看到数据目前分配在 4个segment 实例上，分别有124w数据 
```

### 纵向扩容-Segment_instance_primary

```powershell
# 创建扩容实例文件
[gpadmin@Master-a ~]$ cd /home/gpadmin/
[gpadmin@Master-a ~]$ mkdir expand_segment_instance
[gpadmin@Master-a ~]$ cd expand_segment_instance/
[gpadmin@Master-a expand_segment_instance]$ cp ../conf/seg_hosts expand_segment_indtance_hosts
[gpadmin@Master-a expand_segment_instance]$ cat expand_segment_indtance_hosts 
Segment-a
Segment-b
[gpadmin@Master-a expand_segment_instance]$

# 生成扩容计划
扩容计划 - 在每个segment-node节点 新增2个segment_instance实例 路径与之前保持一致
[gpadmin@Master-a expand_segment_instance]$ gpexpand -f expand_segment_indtance_hosts 
20240611:14:00:38:002323 gpexpand:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240611:14:00:38:002323 gpexpand:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240611:14:00:38:002323 gpexpand:Master-a:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state

System Expansion is used to add segments to an existing GPDB array.
gpexpand did not detect a System Expansion that is in progress.

Before initiating a System Expansion, you need to provision and burn-in
the new hardware.  Please be sure to run gpcheckperf to make sure the
new hardware is working properly.

Please refer to the Admin Guide for more information.

Would you like to initiate a new System Expansion Yy|Nn (default=N):
> y

** No hostnames were given that do not already exist in the **
** array. Additional segments will be added existing hosts. **

    By default, new hosts are configured with the same number of primary
    segments as existing hosts.  Optionally, you can increase the number
    of segments per host.

    For example, if existing hosts have two primary segments, entering a value
    of 2 will initialize two additional segments on existing hosts, and four
    segments on new hosts.  In addition, mirror segments will be added for
    these new primary segments if mirroring is enabled.
    

How many new primary segments per host do you want to add? (default=0):
> 2
Enter new primary data directory 1:
> /home/gpadmin/data/primary
Enter new primary data directory 2:
> /home/gpadmin/data/primary

Generating configuration file...

20240611:14:02:03:002323 gpexpand:Master-a:gpadmin-[INFO]:-Generating input file...

Input configuration file was written to 'gpexpand_inputfile_20240611_140203'.

Please review the file and make sure that it is correct then re-run
with: gpexpand -i gpexpand_inputfile_20240611_140203
                
20240611:14:02:03:002323 gpexpand:Master-a:gpadmin-[INFO]:-Exiting...
[gpadmin@Master-a expand_segment_instance]$ ls
expand_segment_indtance_hosts  gpexpand_inputfile_20240611_140203
[gpadmin@Master-a expand_segment_instance]$ cat gpexpand_inputfile_20240611_140203 
Segment-a|Segment-a|6002|/home/gpadmin/data/primary/gpseg4|6|4|p
Segment-a|Segment-a|6003|/home/gpadmin/data/primary/gpseg5|7|5|p
Segment-b|Segment-b|6002|/home/gpadmin/data/primary/gpseg6|8|6|p
Segment-b|Segment-b|6003|/home/gpadmin/data/primary/gpseg7|9|7|p
[gpadmin@Master-a expand_segment_instance]$

# 扩容计划执行 - 失败
[gpadmin@Master-a expand_segment_instance]$ gpexpand -i gpexpand_inputfile_20240611_140203 
20240611:14:03:05:002353 gpexpand:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240611:14:03:05:002353 gpexpand:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240611:14:03:05:002353 gpexpand:Master-a:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state
20240611:14:03:05:002353 gpexpand:Master-a:gpadmin-[INFO]:-Heap checksum setting consistent across cluster
20240611:14:03:05:002353 gpexpand:Master-a:gpadmin-[INFO]:-Syncing Greenplum Database extensions
20240611:14:03:06:002353 gpexpand:Master-a:gpadmin-[INFO]:-The packages on Segment-a are consistent.
20240611:14:03:06:002353 gpexpand:Master-a:gpadmin-[INFO]:-The packages on Segment-b are consistent.
20240611:14:03:06:002353 gpexpand:Master-a:gpadmin-[INFO]:-Locking catalog
20240611:14:03:06:002353 gpexpand:Master-a:gpadmin-[INFO]:-Locked catalog
20240611:14:03:06:002353 gpexpand:Master-a:gpadmin-[INFO]:-Creating segment template
20240611:14:03:08:002353 gpexpand:Master-a:gpadmin-[INFO]:-Copying postgresql.conf from existing segment into template
20240611:14:03:08:002353 gpexpand:Master-a:gpadmin-[INFO]:-Copying pg_hba.conf from existing segment into template
20240611:14:03:08:002353 gpexpand:Master-a:gpadmin-[INFO]:-Creating schema tar file
20240611:14:03:09:002353 gpexpand:Master-a:gpadmin-[INFO]:-Distributing template tar file to new hosts
20240611:14:03:10:002353 gpexpand:Master-a:gpadmin-[INFO]:-Configuring new segments (primary)
20240611:14:03:10:002353 gpexpand:Master-a:gpadmin-[INFO]:-{'Segment-a': '/home/gpadmin/data/primary/gpseg4:6002:true:false:6:4::-1:,/home/gpadmin/data/primary/gpseg5:6003:true:false:7:5::-1:', 'Segment-b': '/home/gpadmin/data/primary/gpseg6:6002:true:false:8:6::-1:,/home/gpadmin/data/primary/gpseg7:6003:true:false:9:7::-1:'}
20240611:14:03:13:002353 gpexpand:Master-a:gpadmin-[ERROR]:-gpexpand failed: ExecutionError: 'Error Executing Command: ' occurred.  Details: 'ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 Segment-a ". /usr/local/greenplum-db/greenplum_path.sh; env GPSESSID=0000000000 GPERA=None $GPHOME/bin/pg_ctl -D /home/gpadmin/data/primary/gpseg4 -l /home/gpadmin/data/primary/gpseg4/pg_log/startup.log -w -t 600 -o \" -p 6002 -c gp_role=utility -M \" start 2>&1"'  cmd had rc=1 completed=True halted=False
  stdout='waiting for server to start.... stopped waiting
pg_ctl: could not start server
Examine the log output.
'
  stderr='' 

Exiting...
20240611:14:03:13:002353 gpexpand:Master-a:gpadmin-[ERROR]:-Please run 'gpexpand -r' to rollback to the original state.
20240611:14:03:13:002353 gpexpand:Master-a:gpadmin-[INFO]:-Shutting down gpexpand...
[gpadmin@Master-a expand_segment_instance]$ ls
expand_segment_indtance_hosts  gpexpand_inputfile_20240611_140203  gpexpand_schema.tar
[gpadmin@Master-a expand_segment_instance]$

# 查看失败原因以及日志
[root@Segment-a pg_log]# tail -f /home/gpadmin/data/primary/gpseg4/pg_log/startup.log 
2024-06-11 14:03:07.917118 CST,,,p3085,th1574885504,,,,0,,,seg4,,,,,"FATAL","XX000","could not create semaphores: No space left on device","Failed system call was semget(6002001, 17, 03600).","This error does *not* mean that you have run out of disk space.  It occurs when either the system limit for the maximum number of semaphore sets (SEMMNI), or the system wide maximum number of semaphores (SEMMNS), would be exceeded.  You need to raise the respective kernel parameter.  Alternatively, reduce PostgreSQL's consumption of semaphores by reducing its max_connections parameter.
The PostgreSQL documentation contains more information about configuring your system for PostgreSQL.",,,,,,"InternalIpcSemaphoreCreate","pg_sema.c",126,1    0xbf0dac postgres errstart (elog.c:557)
2    0x9fc6c8 postgres PGSemaphoreCreate (pg_sema.c:113)
3    0xa74291 postgres InitProcGlobal (proc.c:259)
4    0xa60005 postgres CreateSharedMemoryAndSemaphores (ipci.c:290)
5    0xa10d6b postgres PostmasterMain (postmaster.c:1337)
6    0x6b5f21 postgres main (main.c:205)
7    0x7f405a9c4555 libc.so.6 __libc_start_main + 0xf5
8    0x6c1c7c postgres <symbol not found> + 0x6c1c7c

# 判断故障原因
故障疑似为系统参数不足以支撑此次扩容

# 故障分析
查看系统信号
[root@Segment-a pg_log]# ipcs -ls

------ Semaphore Limits --------
max number of arrays = 128
max semaphores per array = 250
max semaphores system wide = 32000
max ops per semop call = 32
semaphore max value = 32767

# 修改系统信号
@ ALL
[gpadmin@Master-a expand_segment_instance]$ ipcs -ls

------ Semaphore Limits --------
max number of arrays = 128
max semaphores per array = 250
max semaphores system wide = 32000
max ops per semop call = 32
semaphore max value = 32767

[root@Segment-a pg_log]# cat  /etc/sysctl.conf  | grep kernel.sem
kernel.sem = 250 64000 100 256
[root@Segment-a pg_log]#
[root@Master-a ~]# sysctl -p
[root@Segment-a pg_log]# ipcs -ls

------ Semaphore Limits --------
max number of arrays = 256
max semaphores per array = 250
max semaphores system wide = 64000
max ops per semop call = 100
semaphore max value = 32767

# 回滚扩容计划
[gpadmin@Master-a expand_segment_instance]$ ll
total 171608
-rw-rw-r-- 1 gpadmin gpadmin        20 Jun 11 13:56 expand_segment_indtance_hosts
-rw-rw-r-- 1 gpadmin gpadmin       260 Jun 11 14:02 gpexpand_inputfile_20240611_140203
-rw-rw-r-- 1 gpadmin gpadmin 175718400 Jun 11 14:03 gpexpand_schema.tar
[gpadmin@Master-a expand_segment_instance]$ gpexpand -r
20240611:14:15:14:002624 gpexpand:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240611:14:15:14:002624 gpexpand:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240611:14:15:14:002624 gpexpand:Master-a:gpadmin-[INFO]:-Rolling back building of new segments
20240611:14:15:14:002624 gpexpand:Master-a:gpadmin-[INFO]:-Rolling back segment template build
20240611:14:15:14:002624 gpexpand:Master-a:gpadmin-[INFO]:-Rollback complete.
[gpadmin@Master-a expand_segment_instance]$ ll
total 8
-rw-rw-r-- 1 gpadmin gpadmin  20 Jun 11 13:56 expand_segment_indtance_hosts
-rw-rw-r-- 1 gpadmin gpadmin 260 Jun 11 14:02 gpexpand_inputfile_20240611_140203
[gpadmin@Master-a expand_segment_instance]$

# 执行扩容计划
[gpadmin@Master-a expand_segment_instance]$ gpexpand -i gpexpand_inputfile_20240611_140203 
20240611:14:15:47:002681 gpexpand:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240611:14:15:47:002681 gpexpand:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240611:14:15:47:002681 gpexpand:Master-a:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state
20240611:14:15:47:002681 gpexpand:Master-a:gpadmin-[INFO]:-Heap checksum setting consistent across cluster
20240611:14:15:47:002681 gpexpand:Master-a:gpadmin-[INFO]:-Syncing Greenplum Database extensions
20240611:14:15:48:002681 gpexpand:Master-a:gpadmin-[INFO]:-The packages on Segment-a are consistent.
20240611:14:15:48:002681 gpexpand:Master-a:gpadmin-[INFO]:-The packages on Segment-b are consistent.
20240611:14:15:48:002681 gpexpand:Master-a:gpadmin-[INFO]:-Locking catalog
20240611:14:15:48:002681 gpexpand:Master-a:gpadmin-[INFO]:-Locked catalog
20240611:14:15:48:002681 gpexpand:Master-a:gpadmin-[INFO]:-Creating segment template
20240611:14:15:49:002681 gpexpand:Master-a:gpadmin-[INFO]:-Copying postgresql.conf from existing segment into template
20240611:14:15:49:002681 gpexpand:Master-a:gpadmin-[INFO]:-Copying pg_hba.conf from existing segment into template
20240611:14:15:49:002681 gpexpand:Master-a:gpadmin-[INFO]:-Creating schema tar file
20240611:14:15:50:002681 gpexpand:Master-a:gpadmin-[INFO]:-Distributing template tar file to new hosts
20240611:14:15:51:002681 gpexpand:Master-a:gpadmin-[INFO]:-Configuring new segments (primary)
20240611:14:15:51:002681 gpexpand:Master-a:gpadmin-[INFO]:-{'Segment-a': '/home/gpadmin/data/primary/gpseg4:6002:true:false:6:4::-1:,/home/gpadmin/data/primary/gpseg5:6003:true:false:7:5::-1:', 'Segment-b': '/home/gpadmin/data/primary/gpseg6:6002:true:false:8:6::-1:,/home/gpadmin/data/primary/gpseg7:6003:true:false:9:7::-1:'}
20240611:14:15:53:002681 gpexpand:Master-a:gpadmin-[INFO]:-Cleaning up temporary template files
20240611:14:15:54:002681 gpexpand:Master-a:gpadmin-[INFO]:-Cleaning up databases in new segments.
20240611:14:15:54:002681 gpexpand:Master-a:gpadmin-[INFO]:-Unlocking catalog
20240611:14:15:54:002681 gpexpand:Master-a:gpadmin-[INFO]:-Unlocked catalog
20240611:14:15:54:002681 gpexpand:Master-a:gpadmin-[INFO]:-Creating expansion schema
20240611:14:15:54:002681 gpexpand:Master-a:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database template1
20240611:14:15:55:002681 gpexpand:Master-a:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database postgres
20240611:14:15:55:002681 gpexpand:Master-a:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database gp_sydb
20240611:14:15:55:002681 gpexpand:Master-a:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database test_db
20240611:14:15:55:002681 gpexpand:Master-a:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database test_database
20240611:14:15:55:002681 gpexpand:Master-a:gpadmin-[INFO]:-************************************************
20240611:14:15:55:002681 gpexpand:Master-a:gpadmin-[INFO]:-Initialization of the system expansion complete.
20240611:14:15:55:002681 gpexpand:Master-a:gpadmin-[INFO]:-To begin table expansion onto the new segments
20240611:14:15:55:002681 gpexpand:Master-a:gpadmin-[INFO]:-rerun gpexpand
20240611:14:15:55:002681 gpexpand:Master-a:gpadmin-[INFO]:-************************************************
20240611:14:15:55:002681 gpexpand:Master-a:gpadmin-[INFO]:-Exiting...

# 查看集群状态
[gpadmin@Master-a expand_segment_instance]$ gpstate
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: 
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-Gathering data from segments...
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-Greenplum instance status summary
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Master instance                                = Active
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Master standby                                 = No master standby configured
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Total segment instance count from metadata     = 8
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Primary Segment Status
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segments                         = 8
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment valid (at master)        = 8
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment failures (at master)     = 0
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files missing   = 0
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files found     = 8
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing    = 0
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found      = 8
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files missing        = 0
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files found          = 8
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes missing      = 0
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes found        = 8
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Mirror Segment Status
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Mirrors not configured on this array
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-   Cluster Expansion                              = In Progress
20240611:14:16:08:002847 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
[gpadmin@Master-a expand_segment_instance]$

可以看到扩容成功 为segment_instance 为 8 个，各增加2个。
```

### 数据重分布

```powershell
# 查看调整前数据分布
test_database=# SELECT gp_segment_id,count(1) FROM table_test
GROUP BY gp_segment_id
ORDER BY gp_segment_id;
 gp_segment_id |  count
---------------+---------
             0 | 1249354
             1 | 1249079
             2 | 1250529
             3 | 1251038
(4 rows)

test_database=# 

# 进行数据重分布 -超时时间1小时
[gpadmin@Master-a expand_segment_instance]$ gpexpand -d 1:00:00
20240611:14:20:00:003108 gpexpand:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240611:14:20:00:003108 gpexpand:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240611:14:20:00:003108 gpexpand:Master-a:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state
20240611:14:20:00:003108 gpexpand:Master-a:gpadmin-[INFO]:-Expanding test_database.public.table_test
20240611:14:20:03:003108 gpexpand:Master-a:gpadmin-[INFO]:-Finished expanding test_database.public.table_test
20240611:14:20:05:003108 gpexpand:Master-a:gpadmin-[INFO]:-EXPANSION COMPLETED SUCCESSFULLY
20240611:14:20:05:003108 gpexpand:Master-a:gpadmin-[INFO]:-Exiting...
[gpadmin@Master-a expand_segment_instance]$

# 查看调整后数据分布
test_database=# SELECT gp_segment_id,count(1) FROM table_test
GROUP BY gp_segment_id
ORDER BY gp_segment_id;
 gp_segment_id | count
---------------+--------
             0 | 623840
             1 | 625310
             2 | 625583
             3 | 625607
             4 | 625369
             5 | 624097
             6 | 624808
             7 | 625386
(8 rows)

test_database=# 
调整后，数据平均分布之0-7节点中，各有62w左右。

```

以上完成了实验二，结果满足预期

**END**
