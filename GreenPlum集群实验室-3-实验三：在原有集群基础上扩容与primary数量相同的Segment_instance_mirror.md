# GreenPlum集群实验室-3

> Author ：Heike07

[TOC]

## 实验三：在原有集群基础上扩容与primary数量相同的Segment_instance_mirror

### 参考链接

> 墨天轮：https://www.modb.pro/db/1726419354244440064
>
> CSDN：https://blog.csdn.net/weixin_42633805/article/details/120641386

### 原理

greenplum目前只允许添加mirror，而不允许删除mirror，所以在添加镜像前，最好对gp做一下备份

### 确认环境情况

```powershell
# 查看集群环境
gp_sydb=# select dbid,content,role,port,hostname,address from gp_segment_configuration order by dbid;
 dbid | content | role | port | hostname  |  address
------+---------+------+------+-----------+-----------
    1 |      -1 | p    | 5432 | Master-a  | Master-a
    2 |       0 | p    | 6000 | Segment-a | Segment-a
    3 |       1 | p    | 6001 | Segment-a | Segment-a
    4 |       2 | p    | 6000 | Segment-b | Segment-b
    5 |       3 | p    | 6001 | Segment-b | Segment-b
    6 |       4 | p    | 6002 | Segment-a | Segment-a
    7 |       5 | p    | 6003 | Segment-a | Segment-a
    8 |       6 | p    | 6002 | Segment-b | Segment-b
    9 |       7 | p    | 6003 | Segment-b | Segment-b
(9 rows)

gp_sydb=# 

# 关闭集群 进行VM镜像备份
gpstop

# 开启集群 查看状态
gpstart
[gpadmin@Master-a gpseg-1]$ gpstate
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: 
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-Gathering data from segments...
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-Greenplum instance status summary
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Master instance                                = Active
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Master standby                                 = No master standby configured
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Total segment instance count from metadata     = 8
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Primary Segment Status
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segments                         = 8
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment valid (at master)        = 8
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment failures (at master)     = 0
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files missing   = 0
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files found     = 8
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing    = 0
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found      = 8
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files missing        = 0
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files found          = 8
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes missing      = 0
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes found        = 8
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Mirror Segment Status
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Mirrors not configured on this array
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-   Cluster Expansion                              = In Progress
20240612:14:51:08:047501 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
[gpadmin@Master-a gpseg-1]$
```

### 创建镜像配置文件

```powershell
因为实验为扩容当前节点增加mirror镜像实例，所以不进行文件夹创建
# 查看文件夹结构
[gpadmin@Master-a gpseg-1]$ cd /home/gpadmin/conf/
[gpadmin@Master-a conf]$ ls
hostlist  seg_hosts
[gpadmin@Master-a conf]$ gpssh -f seg_hosts 
=> pwd
[Segment-b] /home/gpadmin
[Segment-a] /home/gpadmin
=> cd data
[Segment-b]
[Segment-a]
=> ls
[Segment-b] master      mirror  primary
[Segment-a] master      mirror  primary
=> exit

[gpadmin@Master-a conf]$
根据之前的规划 是创建了mirror文件夹，现在进行mirror构建

# 生成Mirror镜像配置文件
[gpadmin@Master-a ~]$ mkdir expand_mirrors
[gpadmin@Master-a ~]$ cd expand_mirrors/ 
[gpadmin@Master-a expand_mirrors]$ cp ../expand_segment_instance/expand_segment_indtance_hosts expand_mirror_hostss
[gpadmin@Master-a expand_mirrors]$ cat expand_mirror_hostss 
Segment-a
Segment-b
[gpadmin@Master-a expand_mirrors]$
```

### 构建与Primary的Mirror1:1数量实例

```powershell
# 创建镜像配置文件
[gpadmin@Master-a expand_mirrors]$ gpaddmirrors -o mirror_config_file
20240612:15:09:18:087939 gpaddmirrors:Master-a:gpadmin-[INFO]:-Starting gpaddmirrors with args: -o mirror_config_file
20240612:15:09:18:087939 gpaddmirrors:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240612:15:09:18:087939 gpaddmirrors:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240612:15:09:18:087939 gpaddmirrors:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240612:15:09:19:087939 gpaddmirrors:Master-a:gpadmin-[INFO]:-Heap checksum setting consistent across cluster
Enter mirror segment data directory location 1 of 4 >
/home/gpadmin/data/mirror
Enter mirror segment data directory location 2 of 4 >
/home/gpadmin/data/mirror
Enter mirror segment data directory location 3 of 4 >
/home/gpadmin/data/mirror
Enter mirror segment data directory location 4 of 4 >
/home/gpadmin/data/mirror
20240612:15:10:05:087939 gpaddmirrors:Master-a:gpadmin-[INFO]:-Configuration file output to mirror_config_file successfully.
[gpadmin@Master-a expand_mirrors]$ cat 
expand_mirror_hostss  mirror_config_file    
[gpadmin@Master-a expand_mirrors]$ cat 
expand_mirror_hostss  mirror_config_file    
[gpadmin@Master-a expand_mirrors]$ cat mirror_config_file 
0|Segment-b|7000|/home/gpadmin/data/mirror/gpseg0
1|Segment-b|7001|/home/gpadmin/data/mirror/gpseg1
4|Segment-b|7002|/home/gpadmin/data/mirror/gpseg4
5|Segment-b|7003|/home/gpadmin/data/mirror/gpseg5
2|Segment-a|7000|/home/gpadmin/data/mirror/gpseg2
3|Segment-a|7001|/home/gpadmin/data/mirror/gpseg3
6|Segment-a|7002|/home/gpadmin/data/mirror/gpseg6
7|Segment-a|7003|/home/gpadmin/data/mirror/gpseg7
[gpadmin@Master-a expand_mirrors]$

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
非常重要的内容
要确认一下信号是否设置正确!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# 信号测试结果
[root@Master-a ~]# ipcs -ls

------ Semaphore Limits --------
max number of arrays = 8192
max semaphores per array = 250
max semaphores system wide = 2048000
max ops per semop call = 200
semaphore max value = 32767

[root@Master-a ~]#
必须与此数据一致，否则会需要处理集群源数据,如果故障参考故障排查

# 查看进度
[gpadmin@Master-a expand_mirrors]$ gpstate -e
20240612:16:52:27:047267 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: -e
20240612:16:52:27:047267 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240612:16:52:27:047267 gpstate:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240612:16:52:27:047267 gpstate:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240612:16:52:27:047267 gpstate:Master-a:gpadmin-[INFO]:-Gathering data from segments...
20240612:16:52:28:047267 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:16:52:28:047267 gpstate:Master-a:gpadmin-[INFO]:-Segment Mirroring Status Report
20240612:16:52:28:047267 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:16:52:28:047267 gpstate:Master-a:gpadmin-[INFO]:-All segments are running normally
[gpadmin@Master-a expand_mirrors]$

# 查看mirror在集群状态
[gpadmin@Master-a expand_mirrors]$ gpstate -m
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: -m
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:--------------------------------------------------------------
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:--Current GPDB mirror list and status
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:--Type = Group
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:--------------------------------------------------------------
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:-   Mirror      Datadir                            Port   Status    Data Status    
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg0   7000   Passive   Synchronized
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg1   7001   Passive   Synchronized
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg2   7000   Passive   Synchronized
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg3   7001   Passive   Synchronized
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg4   7002   Passive   Synchronized
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg5   7003   Passive   Synchronized
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg6   7002   Passive   Synchronized
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg7   7003   Passive   Synchronized
20240612:16:53:05:048774 gpstate:Master-a:gpadmin-[INFO]:--------------------------------------------------------------
[gpadmin@Master-a expand_mirrors]$

# 查看状态 - 正常
test_database=# select * from gp_segment_configuration;
 dbid | content | role | preferred_role | mode | status | port | hostname  |  address  |              datadir
------+---------+------+----------------+------+--------+------+-----------+-----------+-----------------------------------
    1 |      -1 | p    | p              | n    | u      | 5432 | Master-a  | Master-a  | /home/gpadmin/data/master/gpseg-1
    8 |       6 | p    | p              | s    | u      | 6002 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg6
   16 |       6 | m    | m              | s    | u      | 7002 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg6
    4 |       2 | p    | p              | s    | u      | 6000 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg2
   14 |       2 | m    | m              | s    | u      | 7000 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg2
    5 |       3 | p    | p              | s    | u      | 6001 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg3
   15 |       3 | m    | m              | s    | u      | 7001 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg3
    9 |       7 | p    | p              | s    | u      | 6003 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg7
   17 |       7 | m    | m              | s    | u      | 7003 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg7
    6 |       4 | p    | p              | s    | u      | 6002 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg4
   12 |       4 | m    | m              | s    | u      | 7002 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg4
    7 |       5 | p    | p              | s    | u      | 6003 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg5
   13 |       5 | m    | m              | s    | u      | 7003 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg5
    2 |       0 | p    | p              | s    | u      | 6000 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg0
   10 |       0 | m    | m              | s    | u      | 7000 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg0
    3 |       1 | p    | p              | s    | u      | 6001 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg1
   11 |       1 | m    | m              | s    | u      | 7001 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg1
(17 rows)

test_database=# 
```

以上完成了实验三，虽然坎坷，结果满足预期

END

### 故障排查

#### 构建镜像失败提示无法执行GPCTL

```powershell
报错提示:
[WARNING]:-Failed to start segment.  The fault prober will shortly mark it as down. Segment: Segment-a:/home/gpadmin/data/mirror/gpseg2:content=2:dbid=14:role=m:preferred_role=m:mode=n:status=d: REASON: PG_CTL failed.

# 执行镜像实例构建
[gpadmin@Master-a expand_mirrors]$ gpaddmirrors -i mirror_config_file
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Starting gpaddmirrors with args: -i mirror_config_file
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Heap checksum setting consistent across cluster
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Greenplum Add Mirrors Parameters
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Greenplum master data directory          = /home/gpadmin/data/master/gpseg-1
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Greenplum master port                    = 5432
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Parallel batch limit                     = 16
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror 1 of 8
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance host        = Segment-a
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance address     = Segment-a
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance directory   = /home/gpadmin/data/primary/gpseg0
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance port        = 6000
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance host         = Segment-b
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance address      = Segment-b
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance directory    = /home/gpadmin/data/mirror/gpseg0
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance port         = 7000
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror 2 of 8
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance host        = Segment-a
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance address     = Segment-a
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance directory   = /home/gpadmin/data/primary/gpseg1
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance port        = 6001
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance host         = Segment-b
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance address      = Segment-b
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance directory    = /home/gpadmin/data/mirror/gpseg1
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance port         = 7001
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror 3 of 8
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance host        = Segment-a
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance address     = Segment-a
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance directory   = /home/gpadmin/data/primary/gpseg4
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance port        = 6002
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance host         = Segment-b
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance address      = Segment-b
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance directory    = /home/gpadmin/data/mirror/gpseg4
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance port         = 7002
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror 4 of 8
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance host        = Segment-a
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance address     = Segment-a
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance directory   = /home/gpadmin/data/primary/gpseg5
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance port        = 6003
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance host         = Segment-b
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance address      = Segment-b
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance directory    = /home/gpadmin/data/mirror/gpseg5
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance port         = 7003
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror 5 of 8
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance host        = Segment-b
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance address     = Segment-b
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance directory   = /home/gpadmin/data/primary/gpseg2
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance port        = 6000
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance host         = Segment-a
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance address      = Segment-a
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance directory    = /home/gpadmin/data/mirror/gpseg2
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance port         = 7000
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror 6 of 8
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance host        = Segment-b
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance address     = Segment-b
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance directory   = /home/gpadmin/data/primary/gpseg3
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance port        = 6001
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance host         = Segment-a
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance address      = Segment-a
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance directory    = /home/gpadmin/data/mirror/gpseg3
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance port         = 7001
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror 7 of 8
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance host        = Segment-b
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance address     = Segment-b
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance directory   = /home/gpadmin/data/primary/gpseg6
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance port        = 6002
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance host         = Segment-a
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance address      = Segment-a
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance directory    = /home/gpadmin/data/mirror/gpseg6
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance port         = 7002
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror 8 of 8
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance host        = Segment-b
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance address     = Segment-b
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance directory   = /home/gpadmin/data/primary/gpseg7
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance port        = 6003
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance host         = Segment-a
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance address      = Segment-a
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance directory    = /home/gpadmin/data/mirror/gpseg7
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance port         = 7003
20240612:15:11:29:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------

Continue with add mirrors procedure Yy|Nn (default=N):
> y
20240612:15:11:47:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Starting to modify pg_hba.conf on primary segments to allow replication connections
20240612:15:11:51:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Successfully modified pg_hba.conf on primary segments to allow replication connections
20240612:15:11:51:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-8 segment(s) to add
20240612:15:11:51:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Validating remote directories
20240612:15:11:51:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Configuring new segments
Segment-a (dbid 14): pg_basebackup: base backup completed
Segment-a (dbid 15): pg_basebackup: base backup completed
Segment-a (dbid 16): pg_basebackup: base backup completed
Segment-a (dbid 17): pg_basebackup: base backup completed
Segment-b (dbid 10): pg_basebackup: base backup completed
Segment-b (dbid 11): pg_basebackup: base backup completed
Segment-b (dbid 12): pg_basebackup: base backup completed
Segment-b (dbid 13): pg_basebackup: base backup completed
20240612:15:11:58:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Updating configuration with new mirrors
20240612:15:11:58:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Updating mirrors
20240612:15:11:58:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Starting mirrors
20240612:15:11:58:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-era is 2dd251f5aa8fec81_240612145053
20240612:15:11:58:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Commencing parallel segment instance startup, please wait...
...
20240612:15:12:01:092839 gpaddmirrors:Master-a:gpadmin-[INFO]:-Process results...
20240612:15:12:01:092839 gpaddmirrors:Master-a:gpadmin-[WARNING]:-Failed to start segment.  The fault prober will shortly mark it as down. Segment: Segment-b:/home/gpadmin/data/mirror/gpseg0:content=0:dbid=10:role=m:preferred_role=m:mode=n:status=d: REASON: PG_CTL failed.
20240612:15:12:01:092839 gpaddmirrors:Master-a:gpadmin-[WARNING]:-Failed to start segment.  The fault prober will shortly mark it as down. Segment: Segment-b:/home/gpadmin/data/mirror/gpseg4:content=4:dbid=12:role=m:preferred_role=m:mode=n:status=d: REASON: PG_CTL failed.
20240612:15:12:01:092839 gpaddmirrors:Master-a:gpadmin-[WARNING]:-Failed to start segment.  The fault prober will shortly mark it as down. Segment: Segment-b:/home/gpadmin/data/mirror/gpseg5:content=5:dbid=13:role=m:preferred_role=m:mode=n:status=d: REASON: PG_CTL failed.
20240612:15:12:01:092839 gpaddmirrors:Master-a:gpadmin-[WARNING]:-Failed to start segment.  The fault prober will shortly mark it as down. Segment: Segment-a:/home/gpadmin/data/mirror/gpseg3:content=3:dbid=15:role=m:preferred_role=m:mode=n:status=d: REASON: PG_CTL failed.
20240612:15:12:01:092839 gpaddmirrors:Master-a:gpadmin-[WARNING]:-Failed to start segment.  The fault prober will shortly mark it as down. Segment: Segment-a:/home/gpadmin/data/mirror/gpseg7:content=7:dbid=17:role=m:preferred_role=m:mode=n:status=d: REASON: PG_CTL failed.
20240612:15:12:01:092839 gpaddmirrors:Master-a:gpadmin-[WARNING]:-Failed to start segment.  The fault prober will shortly mark it as down. Segment: Segment-a:/home/gpadmin/data/mirror/gpseg2:content=2:dbid=14:role=m:preferred_role=m:mode=n:status=d: REASON: PG_CTL failed.
[gpadmin@Master-a expand_mirrors]$ ls
expand_mirror_hostss  mirror_config_file
[gpadmin@Master-a expand_mirrors]$

可以看到提示无法实现 PG_CTL
进入到 Segment 节点中查看 gpsegx 的 PG_LOG start.LOG 查看具体的报错

2024-06-12 16:34:05.817353 CST,,,p77223,th935487616,,,,0,,,seg2,,,,,"FATAL","XX000","could not create semaphores: No space left on device","Failed system call was semget(7000001, 17, 03600).","This error does *not* mean that you have run out of disk space.  It occurs when either the system limit for the maximum number of semaphore sets (SEMMNI), or the system wide maximum number of semaphores (SEMMNS), would be exceeded.  You need to raise the respective kernel parameter.  Alternatively, reduce PostgreSQL's consumption of semaphores by reducing its max_connections parameter.
The PostgreSQL documentation contains more information about configuring your system for PostgreSQL.",,,,,,"InternalIpcSemaphoreCreate","pg_sema.c",126,1    0xbf0dac postgres errstart (elog.c:557)
2    0x9fc6c8 postgres PGSemaphoreCreate (pg_sema.c:113)
3    0xa74291 postgres InitProcGlobal (proc.c:259)
4    0xa60005 postgres CreateSharedMemoryAndSemaphores (ipci.c:290)
5    0xa10d6b postgres PostmasterMain (postmaster.c:1337)
6    0x6b5f21 postgres main (main.c:205)
7    0x7fa3347fd555 libc.so.6 __libc_start_main + 0xf5
8    0x6c1c7c postgres <symbol not found> + 0x6c1c7c

# 调整信号
[gpadmin@Segment-b pg_log]$ cat /etc/sysctl.conf |grep sem
kernel.sem = 250 2048000 200 8192
[gpadmin@Segment-b pg_log]$

报错解决
```

#### 构建镜像提示镜像已经存在无法进行构建

```powershell
报错提示:
[ERROR]:-gpaddmirrors error: GPDB physical mirroring cannot be added.  The cluster is already configured with Mirrors.

# 查看镜像状态
[gpadmin@Master-a expand_mirrors]$ gpstate -e
20240612:15:15:13:101135 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: -e
20240612:15:15:13:101135 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240612:15:15:13:101135 gpstate:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240612:15:15:13:101135 gpstate:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240612:15:15:13:101135 gpstate:Master-a:gpadmin-[INFO]:-Gathering data from segments...
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[WARNING]:-pg_stat_replication shows no standby connections
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[WARNING]:-pg_stat_replication shows no standby connections
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[WARNING]:-pg_stat_replication shows no standby connections
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[WARNING]:-pg_stat_replication shows no standby connections
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[WARNING]:-pg_stat_replication shows no standby connections
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[WARNING]:-pg_stat_replication shows no standby connections
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-Segment Mirroring Status Report
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-Unsynchronized Segment Pairs
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-   Current Primary   Port   Mirror      Port
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-   Segment-a         6000   Segment-b   7000
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-   Segment-b         6000   Segment-a   7000
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-   Segment-b         6001   Segment-a   7001
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-   Segment-a         6002   Segment-b   7002
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-   Segment-a         6003   Segment-b   7003
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-   Segment-b         6003   Segment-a   7003
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-Downed Segments (may include segments where status could not be retrieved)
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-   Segment     Port   Config status   Status
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-   Segment-b   7000   Down            Down in configuration
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-   Segment-a   7000   Down            Down in configuration
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-   Segment-a   7001   Down            Down in configuration
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-   Segment-b   7002   Down            Down in configuration
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-   Segment-b   7003   Down            Down in configuration
20240612:15:15:14:101135 gpstate:Master-a:gpadmin-[INFO]:-   Segment-a   7003   Down            Down in configuration
[gpadmin@Master-a expand_mirrors]$


# 再次添加
[gpadmin@Master-a expand_mirrors]$ gpaddmirrors -i mirror_config_file
20240612:15:25:01:122900 gpaddmirrors:Master-a:gpadmin-[INFO]:-Starting gpaddmirrors with args: -i mirror_config_file
20240612:15:25:01:122900 gpaddmirrors:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240612:15:25:01:122900 gpaddmirrors:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240612:15:25:01:122900 gpaddmirrors:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240612:15:25:01:122900 gpaddmirrors:Master-a:gpadmin-[INFO]:-Heap checksum setting consistent across cluster
20240612:15:25:01:122900 gpaddmirrors:Master-a:gpadmin-[ERROR]:-gpaddmirrors error: GPDB physical mirroring cannot be added.  The cluster is already configured with Mirrors.
[gpadmin@Master-a expand_mirrors]$
提示已经有，那就重启一下集群

# 查看M状态
[gpadmin@Master-a expand_mirrors]$ gpstate -m
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: -m
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[INFO]:--------------------------------------------------------------
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[INFO]:--Current GPDB mirror list and status
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[INFO]:--Type = Group
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[INFO]:--------------------------------------------------------------
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[INFO]:-   Mirror      Datadir                            Port   Status    Data Status    
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[WARNING]:-Segment-b   /home/gpadmin/data/mirror/gpseg0   7000   Failed                   <<<<<<<<
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg1   7001   Passive   Synchronized
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[WARNING]:-Segment-a   /home/gpadmin/data/mirror/gpseg2   7000   Failed                   <<<<<<<<
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[WARNING]:-Segment-a   /home/gpadmin/data/mirror/gpseg3   7001   Failed                   <<<<<<<<
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[WARNING]:-Segment-b   /home/gpadmin/data/mirror/gpseg4   7002   Failed                   <<<<<<<<
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[WARNING]:-Segment-b   /home/gpadmin/data/mirror/gpseg5   7003   Failed                   <<<<<<<<
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg6   7002   Passive   Synchronized
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[WARNING]:-Segment-a   /home/gpadmin/data/mirror/gpseg7   7003   Failed                   <<<<<<<<
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[INFO]:--------------------------------------------------------------
20240612:15:26:52:127197 gpstate:Master-a:gpadmin-[WARNING]:-6 segment(s) configured as mirror(s) have failed
[gpadmin@Master-a expand_mirrors]$

# 关闭集群
[gpadmin@Master-a expand_mirrors]$ gpstop
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-Starting gpstop with args: 
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-Gathering information and validating the environment...
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-Obtaining Greenplum Master catalog information
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:---------------------------------------------
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-Master instance parameters
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:---------------------------------------------
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Master Greenplum instance process active PID   = 47045
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Database                                       = template1
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Master port                                    = 5432
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Master directory                               = /home/gpadmin/data/master/gpseg-1
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Shutdown mode                                  = smart
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Timeout                                        = 120
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Shutdown Master standby host                   = Off
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:---------------------------------------------
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-Segment instances that will be shutdown:
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:---------------------------------------------
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Host        Datadir                             Port   Status
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg0   6000   u
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg0    7000   d
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg1   6001   u
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg1    7001   u
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg2   6000   u
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg2    7000   d
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg3   6001   u
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg3    7001   d
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg4   6002   u
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg4    7002   d
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg5   6003   u
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg5    7003   d
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg6   6002   u
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg6    7002   u
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg7   6003   u
20240612:15:28:58:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg7    7003   d

Continue with Greenplum instance shutdown Yy|Nn (default=N):
> y
20240612:15:29:00:001059 gpstop:Master-a:gpadmin-[INFO]:-Commencing Master instance shutdown with mode='smart'
20240612:15:29:00:001059 gpstop:Master-a:gpadmin-[INFO]:-Master segment instance directory=/home/gpadmin/data/master/gpseg-1
20240612:15:29:00:001059 gpstop:Master-a:gpadmin-[INFO]:-Stopping master segment and waiting for user connections to finish ...
server shutting down
20240612:15:29:01:001059 gpstop:Master-a:gpadmin-[INFO]:-Attempting forceful termination of any leftover master process
20240612:15:29:01:001059 gpstop:Master-a:gpadmin-[INFO]:-Terminating processes for segment /home/gpadmin/data/master/gpseg-1
20240612:15:29:01:001059 gpstop:Master-a:gpadmin-[INFO]:-No standby master host configured
20240612:15:29:01:001059 gpstop:Master-a:gpadmin-[INFO]:-Targeting dbid [2, 10, 3, 11, 4, 14, 5, 15, 6, 12, 7, 13, 8, 16, 9, 17] for shutdown
20240612:15:29:01:001059 gpstop:Master-a:gpadmin-[INFO]:-Commencing parallel primary segment instance shutdown, please wait...
20240612:15:29:01:001059 gpstop:Master-a:gpadmin-[INFO]:-0.00% of jobs completed
20240612:15:29:01:001059 gpstop:Master-a:gpadmin-[INFO]:-100.00% of jobs completed
20240612:15:29:01:001059 gpstop:Master-a:gpadmin-[INFO]:-Commencing parallel mirror segment instance shutdown, please wait...
20240612:15:29:01:001059 gpstop:Master-a:gpadmin-[INFO]:-0.00% of jobs completed
20240612:15:29:02:001059 gpstop:Master-a:gpadmin-[INFO]:-100.00% of jobs completed
20240612:15:29:02:001059 gpstop:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:15:29:02:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segments stopped successfully                              = 16
20240612:15:29:02:001059 gpstop:Master-a:gpadmin-[INFO]:-   Segments with errors during stop                           = 0
20240612:15:29:02:001059 gpstop:Master-a:gpadmin-[INFO]:-   
20240612:15:29:02:001059 gpstop:Master-a:gpadmin-[WARNING]:-Segments that are currently marked down in configuration   = 6    <<<<<<<<
20240612:15:29:02:001059 gpstop:Master-a:gpadmin-[INFO]:-            (stop was still attempted on these segments)
20240612:15:29:02:001059 gpstop:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:15:29:02:001059 gpstop:Master-a:gpadmin-[INFO]:-Successfully shutdown 16 of 16 segment instances 
20240612:15:29:02:001059 gpstop:Master-a:gpadmin-[INFO]:-Database successfully shutdown with no errors reported
20240612:15:29:02:001059 gpstop:Master-a:gpadmin-[INFO]:-Cleaning up leftover gpmmon process
20240612:15:29:02:001059 gpstop:Master-a:gpadmin-[INFO]:-No leftover gpmmon process found
20240612:15:29:02:001059 gpstop:Master-a:gpadmin-[INFO]:-Cleaning up leftover gpsmon processes
20240612:15:29:02:001059 gpstop:Master-a:gpadmin-[INFO]:-No leftover gpsmon processes on some hosts. not attempting forceful termination on these hosts
20240612:15:29:02:001059 gpstop:Master-a:gpadmin-[INFO]:-Cleaning up leftover shared memory
[gpadmin@Master-a expand_mirrors]$ gpstate
20240612:15:29:11:001760 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: 
20240612:15:29:11:001760 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240612:15:29:11:001760 gpstate:Master-a:gpadmin-[CRITICAL]:-gpstate failed. (Reason='could not connect to server: Connection refused
        Is the server running on host "localhost" (::1) and accepting
        TCP/IP connections on port 5432?
could not connect to server: Connection refused
        Is the server running on host "localhost" (127.0.0.1) and accepting
        TCP/IP connections on port 5432?
') exiting...
[gpadmin@Master-a expand_mirrors]$

# 启动集群
[gpadmin@Master-a expand_mirrors]$ gpstart
20240612:15:29:51:003113 gpstart:Master-a:gpadmin-[INFO]:-Starting gpstart with args: 
20240612:15:29:51:003113 gpstart:Master-a:gpadmin-[INFO]:-Gathering information and validating the environment...
20240612:15:29:51:003113 gpstart:Master-a:gpadmin-[INFO]:-Greenplum Binary Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240612:15:29:51:003113 gpstart:Master-a:gpadmin-[INFO]:-Greenplum Catalog Version: '301908232'
20240612:15:29:51:003113 gpstart:Master-a:gpadmin-[INFO]:-Starting Master instance in admin mode
20240612:15:29:51:003113 gpstart:Master-a:gpadmin-[INFO]:-Obtaining Greenplum Master catalog information
20240612:15:29:51:003113 gpstart:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240612:15:29:51:003113 gpstart:Master-a:gpadmin-[INFO]:-Setting new master era
20240612:15:29:51:003113 gpstart:Master-a:gpadmin-[INFO]:-Master Started...
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-Shutting down master
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[WARNING]:-Skipping startup of segment marked down in configuration: on Segment-b directory /home/gpadmin/data/mirror/gpseg0 <<<<<
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[WARNING]:-Skipping startup of segment marked down in configuration: on Segment-a directory /home/gpadmin/data/mirror/gpseg2 <<<<<
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[WARNING]:-Skipping startup of segment marked down in configuration: on Segment-a directory /home/gpadmin/data/mirror/gpseg3 <<<<<
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[WARNING]:-Skipping startup of segment marked down in configuration: on Segment-b directory /home/gpadmin/data/mirror/gpseg4 <<<<<
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[WARNING]:-Skipping startup of segment marked down in configuration: on Segment-b directory /home/gpadmin/data/mirror/gpseg5 <<<<<
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[WARNING]:-Skipping startup of segment marked down in configuration: on Segment-a directory /home/gpadmin/data/mirror/gpseg7 <<<<<
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:---------------------------
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-Master instance parameters
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:---------------------------
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-Database                 = template1
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-Master Port              = 5432
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-Master directory         = /home/gpadmin/data/master/gpseg-1
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-Timeout                  = 600 seconds
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-Master standby           = Off 
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:---------------------------------------
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-Segment instances that will be started
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:---------------------------------------
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-   Host        Datadir                             Port   Role
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg0   6000   Primary
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg1   6001   Primary
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg1    7001   Mirror
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg2   6000   Primary
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg3   6001   Primary
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg4   6002   Primary
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg5   6003   Primary
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg6   6002   Primary
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg6    7002   Mirror
20240612:15:29:52:003113 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg7   6003   Primary

Continue with Greenplum instance startup Yy|Nn (default=N):
> y
20240612:15:30:09:003113 gpstart:Master-a:gpadmin-[INFO]:-Commencing parallel primary and mirror segment instance startup, please wait...
20240612:15:30:09:003113 gpstart:Master-a:gpadmin-[INFO]:-Process results...
20240612:15:30:09:003113 gpstart:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:15:30:09:003113 gpstart:Master-a:gpadmin-[INFO]:-   Successful segment starts                                            = 10
20240612:15:30:09:003113 gpstart:Master-a:gpadmin-[INFO]:-   Failed segment starts                                                = 0
20240612:15:30:09:003113 gpstart:Master-a:gpadmin-[WARNING]:-Skipped segment starts (segments are marked down in configuration)   = 6    <<<<<<<<
20240612:15:30:09:003113 gpstart:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:15:30:09:003113 gpstart:Master-a:gpadmin-[INFO]:-Successfully started 10 of 10 segment instances, skipped 6 other segments 
20240612:15:30:09:003113 gpstart:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:15:30:09:003113 gpstart:Master-a:gpadmin-[WARNING]:-****************************************************************************
20240612:15:30:09:003113 gpstart:Master-a:gpadmin-[WARNING]:-There are 6 segment(s) marked down in the database
20240612:15:30:09:003113 gpstart:Master-a:gpadmin-[WARNING]:-To recover from this current state, review usage of the gprecoverseg
20240612:15:30:09:003113 gpstart:Master-a:gpadmin-[WARNING]:-management utility which will recover failed segment instance databases.
20240612:15:30:09:003113 gpstart:Master-a:gpadmin-[WARNING]:-****************************************************************************
20240612:15:30:09:003113 gpstart:Master-a:gpadmin-[INFO]:-Starting Master instance Master-a directory /home/gpadmin/data/master/gpseg-1 
20240612:15:30:10:003113 gpstart:Master-a:gpadmin-[INFO]:-Command pg_ctl reports Master Master-a instance active
20240612:15:30:10:003113 gpstart:Master-a:gpadmin-[INFO]:-Connecting to dbname='template1' connect_timeout=15
20240612:15:30:10:003113 gpstart:Master-a:gpadmin-[INFO]:-No standby master configured.  skipping...
20240612:15:30:10:003113 gpstart:Master-a:gpadmin-[WARNING]:-Number of segments not attempted to start: 6
20240612:15:30:10:003113 gpstart:Master-a:gpadmin-[INFO]:-Check status of database with gpstate utility
[gpadmin@Master-a expand_mirrors]$ gpstate
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: 
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-Gathering data from segments...
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-Greenplum instance status summary
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Master instance                                           = Active
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Master standby                                            = No master standby configured
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total segment instance count from metadata                = 16
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Primary Segment Status
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segments                                    = 8
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment valid (at master)                   = 8
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment failures (at master)                = 0
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 8
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 8
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 8
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes found                   = 8
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Mirror Segment Status
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total mirror segments                                     = 8
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total mirror segment valid (at master)                    = 2
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[WARNING]:-Total mirror segment failures (at master)                 = 6                              <<<<<<<<
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[WARNING]:-Total number of postmaster.pid files missing              = 6                              <<<<<<<<
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 2
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[WARNING]:-Total number of postmaster.pid PIDs missing               = 6                              <<<<<<<<
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 2
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[WARNING]:-Total number of /tmp lock files missing                   = 6                              <<<<<<<<
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 2
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[WARNING]:-Total number postmaster processes missing                 = 6                              <<<<<<<<
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes found                   = 2
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total number mirror segments acting as primary segments   = 0
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Total number mirror segments acting as mirror segments    = 8
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-   Cluster Expansion                                         = In Progress
20240612:15:30:30:004640 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
[gpadmin@Master-a expand_mirrors]$ 
[gpadmin@Master-a expand_mirrors]$

依然不对 mirror数据不正确

# 删除mirror
gp_sydb=# set allow_system_table_mods='on';
SET

gp_sydb=# select * from gp_segment_configuration;
 dbid | content | role | preferred_role | mode | status | port | hostname  |  address  |              datadir
------+---------+------+----------------+------+--------+------+-----------+-----------+-----------------------------------
    1 |      -1 | p    | p              | n    | u      | 5432 | Master-a  | Master-a  | /home/gpadmin/data/master/gpseg-1
    2 |       0 | p    | p              | n    | u      | 6000 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg0
    4 |       2 | p    | p              | n    | u      | 6000 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg2
    5 |       3 | p    | p              | n    | u      | 6001 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg3
    6 |       4 | p    | p              | n    | u      | 6002 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg4
    7 |       5 | p    | p              | n    | u      | 6003 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg5
    9 |       7 | p    | p              | n    | u      | 6003 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg7
   10 |       0 | m    | m              | n    | d      | 7000 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg0
   12 |       4 | m    | m              | n    | d      | 7002 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg4
   13 |       5 | m    | m              | n    | d      | 7003 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg5
   14 |       2 | m    | m              | n    | d      | 7000 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg2
   15 |       3 | m    | m              | n    | d      | 7001 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg3
   17 |       7 | m    | m              | n    | d      | 7003 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg7
    3 |       1 | p    | p              | s    | u      | 6001 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg1
   11 |       1 | m    | m              | s    | u      | 7001 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg1
    8 |       6 | p    | p              | s    | u      | 6002 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg6
   16 |       6 | m    | m              | s    | u      | 7002 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg6
(17 rows)

gp_sydb=# 

gp_sydb=# delete from gp_segment_configuration  where dbid between 10 and 17;
DELETE 8

gp_sydb=# select * from gp_segment_configuration;
 dbid | content | role | preferred_role | mode | status | port | hostname  |  address  |              datadir
------+---------+------+----------------+------+--------+------+-----------+-----------+-----------------------------------
    1 |      -1 | p    | p              | n    | u      | 5432 | Master-a  | Master-a  | /home/gpadmin/data/master/gpseg-1
    2 |       0 | p    | p              | n    | u      | 6000 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg0
    4 |       2 | p    | p              | n    | u      | 6000 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg2
    5 |       3 | p    | p              | n    | u      | 6001 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg3
    6 |       4 | p    | p              | n    | u      | 6002 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg4
    7 |       5 | p    | p              | n    | u      | 6003 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg5
    9 |       7 | p    | p              | n    | u      | 6003 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg7
    3 |       1 | p    | p              | s    | u      | 6001 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg1
    8 |       6 | p    | p              | s    | u      | 6002 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg6
(9 rows)

gp_sydb=# 

# 删除物理节点
[gpadmin@Segment-a pg_log]$ cd ~/data/
[gpadmin@Segment-a data]$ ls
master  mirror  primary
[gpadmin@Segment-a data]$ cd mirror/l
[gpadmin@Segment-a mirror]$ s
gpseg2  gpseg3  gpseg6  gpseg7
[gpadmin@Segment-a mirror]$ cd gpseg2
[gpadmin@Segment-a gpseg2]$ ls
backup_label  global              pg_clog            pg_dynshmem  pg_ident.conf  pg_logical    pg_notify    pg_serial     pg_stat      pg_subtrans  pg_twophase            PG_VERSION  postgresql.auto.conf  recovery.conf
base          internal.auto.conf  pg_distributedlog  pg_hba.conf  pg_log         pg_multixact  pg_replslot  pg_snapshots  pg_stat_tmp  pg_tblspc    pg_utilitymodedtmredo  pg_xlog     postgresql.conf
[gpadmin@Segment-a gpseg2]$ cd ..cd ..
[gpadmin@Segment-a mirror]$ ls
gpseg2  gpseg3  gpseg6  gpseg7
[gpadmin@Segment-a mirror]$ rm -rf gpseg*
[gpadmin@Segment-a mirror]$ pwd
/home/gpadmin/data/mirror
[gpadmin@Segment-a mirror]$

[root@Segment-b ~]# su gpadmin
[gpadmin@Segment-b root]$ cd ~/data/
[gpadmin@Segment-b data]$ ls
master  mirror  primary
[gpadmin@Segment-b data]$ cd mirror/
[gpadmin@Segment-b mirror]$ ls
gpseg0  gpseg1  gpseg4  gpseg5
[gpadmin@Segment-b mirror]$ rm -rf gpseg*
[gpadmin@Segment-b mirror]$ pwd
/home/gpadmin/data/mirror
[gpadmin@Segment-b mirror]$

以上报错解决
```

#### 构建镜像提示镜像Mirror无数据或数据异常

```powershell
报错提示:
[CRITICAL]:-gpstate failed. (Reason='Invalid GpArray: Master: Master-a:/home/gpadmin/data/master/gpseg-1:content=-1:dbid=1:role=p:preferred_role=p:mode=n:status=u
Standby: Not Configured
Segment Pairs: (Primary: Segment-a:/home/gpadmin/data/primary/gpseg0:content=0:dbid=2:role=p:preferred_role=p:mode=n:status=u, Mirror: None)

# 重建Mirror
[gpadmin@Master-a expand_mirrors]$ gpstate -m
20240612:16:08:23:088584 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: -m
20240612:16:08:23:088584 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240612:16:08:23:088584 gpstate:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240612:16:08:23:088584 gpstate:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240612:16:08:23:088584 gpstate:Master-a:gpadmin-[CRITICAL]:-gpstate failed. (Reason='Invalid GpArray: Master: Master-a:/home/gpadmin/data/master/gpseg-1:content=-1:dbid=1:role=p:preferred_role=p:mode=n:status=u
Standby: Not Configured
Segment Pairs: (Primary: Segment-a:/home/gpadmin/data/primary/gpseg0:content=0:dbid=2:role=p:preferred_role=p:mode=n:status=u, Mirror: None)
(Primary: Segment-a:/home/gpadmin/data/primary/gpseg1:content=1:dbid=3:role=p:preferred_role=p:mode=s:status=u, Mirror: None)
(Primary: Segment-b:/home/gpadmin/data/primary/gpseg2:content=2:dbid=4:role=p:preferred_role=p:mode=n:status=u, Mirror: None)
(Primary: Segment-b:/home/gpadmin/data/primary/gpseg3:content=3:dbid=5:role=p:preferred_role=p:mode=n:status=u, Mirror: None)
(Primary: Segment-a:/home/gpadmin/data/primary/gpseg4:content=4:dbid=6:role=p:preferred_role=p:mode=n:status=u, Mirror: None)
(Primary: Segment-a:/home/gpadmin/data/primary/gpseg5:content=5:dbid=7:role=p:preferred_role=p:mode=n:status=u, Mirror: None)
(Primary: Segment-b:/home/gpadmin/data/primary/gpseg6:content=6:dbid=8:role=p:preferred_role=p:mode=s:status=u, Mirror: None)
(Primary: Segment-b:/home/gpadmin/data/primary/gpseg7:content=7:dbid=9:role=p:preferred_role=p:mode=n:status=u, Mirror: None)') exiting...
[gpadmin@Master-a expand_mirrors]$

# 原数据处理
 dbid | content | role | preferred_role | mode | status | port | hostname  |  address  |              datadir
------+---------+------+----------------+------+--------+------+-----------+-----------+-----------------------------------
    1 |      -1 | p    | p              | n    | u      | 5432 | Master-a  | Master-a  | /home/gpadmin/data/master/gpseg-1
    2 |       0 | p    | p              | n    | u      | 6000 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg0
    3 |       1 | p    | p              | s    | u      | 6001 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg1
    4 |       2 | p    | p              | n    | u      | 6000 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg2
    5 |       3 | p    | p              | n    | u      | 6001 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg3
    6 |       4 | p    | p              | n    | u      | 6002 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg4
    7 |       5 | p    | p              | n    | u      | 6003 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg5
    8 |       6 | p    | p              | s    | u      | 6002 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg6
    9 |       7 | p    | p              | n    | u      | 6003 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg7
(9 rows)

gp_sydb=# UPDATE gp_segment_configuration SET mode='n', status='u' WHERE role='p';
UPDATE 9

gp_sydb=# SELECT * FROM gp_segment_configuration ORDER BY content, role;
 dbid | content | role | preferred_role | mode | status | port | hostname  |  address  |              datadir
------+---------+------+----------------+------+--------+------+-----------+-----------+-----------------------------------
    1 |      -1 | p    | p              | n    | u      | 5432 | Master-a  | Master-a  | /home/gpadmin/data/master/gpseg-1
    2 |       0 | p    | p              | n    | u      | 6000 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg0
    3 |       1 | p    | p              | n    | u      | 6001 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg1
    4 |       2 | p    | p              | n    | u      | 6000 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg2
    5 |       3 | p    | p              | n    | u      | 6001 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg3
    6 |       4 | p    | p              | n    | u      | 6002 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg4
    7 |       5 | p    | p              | n    | u      | 6003 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg5
    8 |       6 | p    | p              | n    | u      | 6002 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg6
    9 |       7 | p    | p              | n    | u      | 6003 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg7
(9 rows)

gp_sydb=# 

[gpadmin@Master-a root]$ gpstart
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Starting gpstart with args: 
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Gathering information and validating the environment...
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Greenplum Binary Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Greenplum Catalog Version: '301908232'
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Starting Master instance in admin mode
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Obtaining Greenplum Master catalog information
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Setting new master era
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Master Started...
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Shutting down master
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:---------------------------
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Master instance parameters
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:---------------------------
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Database                 = template1
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Master Port              = 5432
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Master directory         = /home/gpadmin/data/master/gpseg-1
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Timeout                  = 600 seconds
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Master standby           = Off 
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:---------------------------------------
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-Segment instances that will be started
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:---------------------------------------
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-   Host        Datadir                             Port
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg0   6000
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg1   6001
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg2   6000
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg3   6001
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg4   6002
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg5   6003
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg6   6002
20240612:16:32:48:003342 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg7   6003

Continue with Greenplum instance startup Yy|Nn (default=N):
> y
20240612:16:32:50:003342 gpstart:Master-a:gpadmin-[INFO]:-Commencing parallel segment instance startup, please wait...
20240612:16:32:50:003342 gpstart:Master-a:gpadmin-[INFO]:-Process results...
20240612:16:32:50:003342 gpstart:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:16:32:50:003342 gpstart:Master-a:gpadmin-[INFO]:-   Successful segment starts                                            = 8
20240612:16:32:50:003342 gpstart:Master-a:gpadmin-[INFO]:-   Failed segment starts                                                = 0
20240612:16:32:50:003342 gpstart:Master-a:gpadmin-[INFO]:-   Skipped segment starts (segments are marked down in configuration)   = 0
20240612:16:32:50:003342 gpstart:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:16:32:50:003342 gpstart:Master-a:gpadmin-[INFO]:-Successfully started 8 of 8 segment instances 
20240612:16:32:50:003342 gpstart:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:16:32:50:003342 gpstart:Master-a:gpadmin-[INFO]:-Starting Master instance Master-a directory /home/gpadmin/data/master/gpseg-1 
20240612:16:32:50:003342 gpstart:Master-a:gpadmin-[INFO]:-Command pg_ctl reports Master Master-a instance active
20240612:16:32:50:003342 gpstart:Master-a:gpadmin-[INFO]:-Connecting to dbname='template1' connect_timeout=15
20240612:16:32:51:003342 gpstart:Master-a:gpadmin-[INFO]:-No standby master configured.  skipping...
20240612:16:32:51:003342 gpstart:Master-a:gpadmin-[INFO]:-Database successfully started
[gpadmin@Master-a root]$ gpstate
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: 
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-Gathering data from segments...
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-Greenplum instance status summary
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Master instance                                = Active
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Master standby                                 = No master standby configured
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Total segment instance count from metadata     = 8
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Primary Segment Status
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segments                         = 8
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment valid (at master)        = 8
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment failures (at master)     = 0
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files missing   = 0
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files found     = 8
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing    = 0
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found      = 8
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files missing        = 0
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files found          = 8
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes missing      = 0
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes found        = 8
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Mirror Segment Status
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Mirrors not configured on this array
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-   Cluster Expansion                              = In Progress
20240612:16:32:55:003749 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
[gpadmin@Master-a root]$


# 重置
test_database=# 
test_database=# set allow_system_table_mods='on';
SET

test_database=# select * from gp_segment_configuration;
 dbid | content | role | preferred_role | mode | status | port | hostname  |  address  |              datadir
------+---------+------+----------------+------+--------+------+-----------+-----------+-----------------------------------
    1 |      -1 | p    | p              | n    | u      | 5432 | Master-a  | Master-a  | /home/gpadmin/data/master/gpseg-1
    2 |       0 | p    | p              | n    | u      | 6000 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg0
    4 |       2 | p    | p              | n    | u      | 6000 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg2
    5 |       3 | p    | p              | n    | u      | 6001 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg3
    7 |       5 | p    | p              | n    | u      | 6003 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg5
    9 |       7 | p    | p              | n    | u      | 6003 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg7
    3 |       1 | p    | p              | n    | u      | 6001 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg1
   10 |       0 | m    | m              | n    | d      | 7000 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg0
   11 |       1 | m    | m              | n    | d      | 7001 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg1
   13 |       5 | m    | m              | n    | d      | 7003 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg5
   14 |       2 | m    | m              | n    | d      | 7000 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg2
   15 |       3 | m    | m              | n    | d      | 7001 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg3
   17 |       7 | m    | m              | n    | d      | 7003 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg7
    8 |       6 | p    | p              | s    | u      | 6002 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg6
   16 |       6 | m    | m              | s    | u      | 7002 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg6
    6 |       4 | p    | p              | s    | u      | 6002 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg4
   12 |       4 | m    | m              | s    | u      | 7002 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg4
(17 rows)

test_database=# delete from gp_segment_configuration  where dbid between 10 and 17;
DELETE 8

test_database=# select * from gp_segment_configuration;
 dbid | content | role | preferred_role | mode | status | port | hostname  |  address  |              datadir
------+---------+------+----------------+------+--------+------+-----------+-----------+-----------------------------------
    1 |      -1 | p    | p              | n    | u      | 5432 | Master-a  | Master-a  | /home/gpadmin/data/master/gpseg-1
    2 |       0 | p    | p              | n    | u      | 6000 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg0
    4 |       2 | p    | p              | n    | u      | 6000 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg2
    5 |       3 | p    | p              | n    | u      | 6001 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg3
    7 |       5 | p    | p              | n    | u      | 6003 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg5
    9 |       7 | p    | p              | n    | u      | 6003 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg7
    3 |       1 | p    | p              | n    | u      | 6001 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg1
    8 |       6 | p    | p              | s    | u      | 6002 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg6
    6 |       4 | p    | p              | s    | u      | 6002 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg4
(9 rows)

test_database=# UPDATE gp_segment_configuration SET mode='n', status='u' WHERE role='p';
UPDATE 9

test_database=# SELECT * FROM gp_segment_configuration ORDER BY content, role;
 dbid | content | role | preferred_role | mode | status | port | hostname  |  address  |              datadir
------+---------+------+----------------+------+--------+------+-----------+-----------+-----------------------------------
    1 |      -1 | p    | p              | n    | u      | 5432 | Master-a  | Master-a  | /home/gpadmin/data/master/gpseg-1
    2 |       0 | p    | p              | n    | u      | 6000 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg0
    3 |       1 | p    | p              | n    | u      | 6001 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg1
    4 |       2 | p    | p              | n    | u      | 6000 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg2
    5 |       3 | p    | p              | n    | u      | 6001 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg3
    6 |       4 | p    | p              | n    | u      | 6002 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg4
    7 |       5 | p    | p              | n    | u      | 6003 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg5
    8 |       6 | p    | p              | n    | u      | 6002 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg6
    9 |       7 | p    | p              | n    | u      | 6003 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg7
(9 rows)

test_database=# 

# 删除物理文件

# 重新构建mirror镜像
[gpadmin@Master-a expand_mirrors]$ gpaddmirrors -i mirror_config_file
20240612:16:50:18:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Starting gpaddmirrors with args: -i mirror_config_file
20240612:16:50:18:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240612:16:50:18:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240612:16:50:18:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Heap checksum setting consistent across cluster
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Greenplum Add Mirrors Parameters
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Greenplum master data directory          = /home/gpadmin/data/master/gpseg-1
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Greenplum master port                    = 5432
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Parallel batch limit                     = 16
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror 1 of 8
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance host        = Segment-a
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance address     = Segment-a
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance directory   = /home/gpadmin/data/primary/gpseg0
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance port        = 6000
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance host         = Segment-b
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance address      = Segment-b
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance directory    = /home/gpadmin/data/mirror/gpseg0
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance port         = 7000
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror 2 of 8
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance host        = Segment-a
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance address     = Segment-a
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance directory   = /home/gpadmin/data/primary/gpseg1
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance port        = 6001
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance host         = Segment-b
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance address      = Segment-b
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance directory    = /home/gpadmin/data/mirror/gpseg1
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance port         = 7001
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror 3 of 8
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance host        = Segment-a
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance address     = Segment-a
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance directory   = /home/gpadmin/data/primary/gpseg4
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance port        = 6002
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance host         = Segment-b
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance address      = Segment-b
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance directory    = /home/gpadmin/data/mirror/gpseg4
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance port         = 7002
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror 4 of 8
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance host        = Segment-a
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance address     = Segment-a
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance directory   = /home/gpadmin/data/primary/gpseg5
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance port        = 6003
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance host         = Segment-b
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance address      = Segment-b
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance directory    = /home/gpadmin/data/mirror/gpseg5
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance port         = 7003
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror 5 of 8
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance host        = Segment-b
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance address     = Segment-b
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance directory   = /home/gpadmin/data/primary/gpseg2
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance port        = 6000
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance host         = Segment-a
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance address      = Segment-a
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance directory    = /home/gpadmin/data/mirror/gpseg2
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance port         = 7000
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror 6 of 8
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance host        = Segment-b
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance address     = Segment-b
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance directory   = /home/gpadmin/data/primary/gpseg3
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance port        = 6001
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance host         = Segment-a
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance address      = Segment-a
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance directory    = /home/gpadmin/data/mirror/gpseg3
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance port         = 7001
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror 7 of 8
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance host        = Segment-b
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance address     = Segment-b
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance directory   = /home/gpadmin/data/primary/gpseg6
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance port        = 6002
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance host         = Segment-a
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance address      = Segment-a
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance directory    = /home/gpadmin/data/mirror/gpseg6
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance port         = 7002
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror 8 of 8
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance host        = Segment-b
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance address     = Segment-b
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance directory   = /home/gpadmin/data/primary/gpseg7
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Primary instance port        = 6003
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance host         = Segment-a
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance address      = Segment-a
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance directory    = /home/gpadmin/data/mirror/gpseg7
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-   Mirror instance port         = 7003
20240612:16:50:19:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:----------------------------------------------------------

Continue with add mirrors procedure Yy|Nn (default=N):
> y
20240612:16:50:23:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Starting to modify pg_hba.conf on primary segments to allow replication connections
20240612:16:50:26:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Successfully modified pg_hba.conf on primary segments to allow replication connections
20240612:16:50:26:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-8 segment(s) to add
20240612:16:50:26:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Validating remote directories
20240612:16:50:26:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Configuring new segments
Segment-a (dbid 14): pg_basebackup: base backup completed
Segment-a (dbid 15): pg_basebackup: base backup completed
Segment-a (dbid 16): pg_basebackup: base backup completed
Segment-a (dbid 17): pg_basebackup: base backup completed
Segment-b (dbid 10): pg_basebackup: base backup completed
Segment-b (dbid 11): pg_basebackup: base backup completed
Segment-b (dbid 12): pg_basebackup: base backup completed
Segment-b (dbid 13): pg_basebackup: base backup completed
20240612:16:50:32:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Updating configuration with new mirrors
20240612:16:50:32:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Updating mirrors
20240612:16:50:32:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Starting mirrors
20240612:16:50:32:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-era is 2dd251f5aa8fec81_240612164941
20240612:16:50:32:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Commencing parallel segment instance startup, please wait...
20240612:16:50:34:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Process results...
20240612:16:50:34:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-******************************************************************
20240612:16:50:34:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Mirror segments have been added; data synchronization is in progress.
20240612:16:50:34:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Data synchronization will continue in the background.
20240612:16:50:34:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-Use  gpstate -s  to check the resynchronization progress.
20240612:16:50:34:042403 gpaddmirrors:Master-a:gpadmin-[INFO]:-******************************************************************
[gpadmin@Master-a expand_mirrors]$

报错解决 
```

