# GreenPlum集群实验室-5

> Author ：Heike07

[TOC]

## 实验五：模拟故障进行缩容，并进行数据重分布

### 第一次实验

#### 第一次实验计划
gp缩容 本质上是模拟故障，在缩容之前要备份所有的数据，然后分析能否进行缩容，要保证缩容的机器或者磁盘 没有对应的 segmentx 和 mirrorx 对应关系的情况下 可以选择删除元数据 即手动置为不可用且进行删除数据，如果不差对应关系 那就是数据丢失分片 也就是毁灭性的了。所以还是强依赖于segment 和 mirror 的文件同步机制。

#### 第一次尝试故障触发

```powershell
# 查看集群状态 以及
segment 和 mirror分布情况
[gpadmin@Master-a root]$ gpstate -s
20240730:09:31:20:002551 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: -s
20240730:09:31:20:002551 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240730:09:31:20:002551 gpstate:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240730:09:31:20:002551 gpstate:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240730:09:31:20:002551 gpstate:Master-a:gpadmin-[INFO]:-Gathering data from segments...
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:--Master Configuration & Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Master host                    = Master-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Master postgres process ID     = 1717
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Master data directory          = /home/gpadmin/data/master/gpseg-1
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Master port                    = 5432
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Master current role            = dispatch
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Greenplum initsystem version   = 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Greenplum current version      = PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Postgres version               = 9.4.24
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Master standby                 = No master standby configured
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-Segment Instance Status Report
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6000
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1567
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7000
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/534772B0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/534772B0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/534772B0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1531
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg1
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6001
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1562
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg1
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7001
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/53937790
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/53937790
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/53937790
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1536
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg2
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6000
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1543
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg2
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7000
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/5349B6B8
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/5349B6B8
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/5349B6B8
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1549
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg3
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6001
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1546
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg3
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7001
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/53484EE0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/53484EE0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/53484EE0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1553
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg4
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6002
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1571
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg4
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7002
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/3393BAD0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/3393BAD0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/3393BAD0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1528
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg5
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6003
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1565
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg5
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7003
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/3803E008
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/3803E008
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/3803E008
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1525
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg6
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6002
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1562
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg6
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7002
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/33484130
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/33484130
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/33484130
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1533
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg7
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6003
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1559
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg7
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7003
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/3347C5E0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/3347C5E0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/3347C5E0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1534
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg8
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6000
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1571
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg8
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7000
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/278E50B0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/278E50B0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/278E50B0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1534
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg9
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6001
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1570
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg9
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7001
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/278E2280
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/278E2280
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/278E2280
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1537
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg10
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6002
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1541
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg10
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7002
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/278F4400
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/278F4400
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/278F4400
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1567
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg11
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6003
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1540
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg11
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7003
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/278FBE68
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/278FBE68
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/278FBE68
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1566
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg12
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6000
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1545
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg12
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7000
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/279287B8
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/279287B8
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/279287B8
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1569
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg13
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6001
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1552
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg13
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7001
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/278F22A0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/278F22A0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/278F22A0
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1563
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg14
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6002
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1563
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg14
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7002
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/2791BE58
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/2791BE58
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/2791BE58
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1554
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg15
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6003
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1562
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg15
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7003
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/278BD818
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/278BD818
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/278BD818
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1545
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg16
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6004
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1539
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg16
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7004
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/2F37BED8
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/2F37BED8
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/2F37BED8
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1550
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-b
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg17
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6004
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1563
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg17
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7004
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/2F3B2708
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/2F3B2708
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/2F3B2708
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1561
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-c
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg18
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6004
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1538
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg18
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7004
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/2F884780
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/2F884780
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/2F884780
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1568
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-d
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg19
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6004
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Synchronized
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1535
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Database status                   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-a
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/mirror/gpseg19
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 7004
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Mirror
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Streaming
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Sent Location                 = 0/2F833420
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Flush Location                = 0/2F833420
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      WAL Replay Location               = 0/2F833420
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      PID                               = 1572
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Configuration reports status as   = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-      Segment status                    = Up
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-   Cluster Expansion                    = In Progress
20240730:09:31:21:002551 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
[gpadmin@Master-a root]$

本次需要关停的是 Segment-c 和 Segment-d 节点主机所有 Primary 和 Mirror

查看此节点拥有数据链路

[gpadmin@Segment-c data]$ tree -L 2
.
├── mirror
│   ├── gpseg12
│   ├── gpseg13
│   ├── gpseg14
│   ├── gpseg15
│   └── gpseg17
└── primary
    ├── gpseg10
    ├── gpseg11
    ├── gpseg18
    ├── gpseg8
    └── gpseg9

12 directories, 0 files

[gpadmin@Segment-d data]$ tree -L 2
.
├── mirror
│   ├── gpseg10
│   ├── gpseg11
│   ├── gpseg18
│   ├── gpseg8
│   └── gpseg9
└── primary
    ├── gpseg12
    ├── gpseg13
    ├── gpseg14
    ├── gpseg15
    └── gpseg19

12 directories, 0 files
[gpadmin@Segment-d data]$

可以看到 2个节点进行了互补，如果缩容2个节点 必然会出现丢失数据的情况，比如segment-d的gpseg12 的数据 镜像在segment-c的 mirror gpseg12 ，如果全部删除会丢失数据，那么就只能通过删除Segment-d 进行缩容，而segment-c 保留。

如果这样的话，segment-d的数据为 12 13 14 15 19 而备份位置在 12 13 14 15 而 19 在其他节点位置 所以数据不会丢失，那么问题来了，如果segment-d 成功缩容 那么这些数据位置是否会重新分配呢？

验证此情况，需要进行实验分析，那么就取 14 这个 数据块进行处理，14 数据快在 segment-d上 ，而 镜像数据在 mirror 上。

做全部镜像 准备做实验！  快照4

test_database=# select * from gp_segment_configuration order by dbid;
 dbid | content | role | preferred_role | mode | status | port | hostname  |  address  |              datadir
------+---------+------+----------------+------+--------+------+-----------+-----------+------------------------------------
    1 |      -1 | p    | p              | n    | u      | 5432 | Master-a  | Master-a  | /home/gpadmin/data/master/gpseg-1
    2 |       0 | p    | p              | s    | u      | 6000 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg0
    3 |       1 | p    | p              | s    | u      | 6001 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg1
    4 |       2 | p    | p              | s    | u      | 6000 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg2
    5 |       3 | p    | p              | s    | u      | 6001 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg3
    6 |       4 | p    | p              | s    | u      | 6002 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg4
    7 |       5 | p    | p              | s    | u      | 6003 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg5
    8 |       6 | p    | p              | s    | u      | 6002 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg6
    9 |       7 | p    | p              | s    | u      | 6003 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg7
   10 |       0 | m    | m              | s    | u      | 7000 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg0
   11 |       1 | m    | m              | s    | u      | 7001 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg1
   12 |       4 | m    | m              | s    | u      | 7002 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg4
   13 |       5 | m    | m              | s    | u      | 7003 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg5
   14 |       2 | m    | m              | s    | u      | 7000 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg2
   15 |       3 | m    | m              | s    | u      | 7001 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg3
   16 |       6 | m    | m              | s    | u      | 7002 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg6
   17 |       7 | m    | m              | s    | u      | 7003 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg7
   18 |       8 | p    | p              | s    | u      | 6000 | Segment-c | Segment-c | /home/gpadmin/data/primary/gpseg8
   19 |       9 | p    | p              | s    | u      | 6001 | Segment-c | Segment-c | /home/gpadmin/data/primary/gpseg9
   20 |      10 | p    | p              | s    | u      | 6002 | Segment-c | Segment-c | /home/gpadmin/data/primary/gpseg10
   21 |      11 | p    | p              | s    | u      | 6003 | Segment-c | Segment-c | /home/gpadmin/data/primary/gpseg11
   22 |      12 | p    | p              | s    | u      | 6000 | Segment-d | Segment-d | /home/gpadmin/data/primary/gpseg12
   23 |      13 | p    | p              | s    | u      | 6001 | Segment-d | Segment-d | /home/gpadmin/data/primary/gpseg13
   24 |      14 | p    | p              | s    | u      | 6002 | Segment-d | Segment-d | /home/gpadmin/data/primary/gpseg14
   25 |      15 | p    | p              | s    | u      | 6003 | Segment-d | Segment-d | /home/gpadmin/data/primary/gpseg15
   26 |      12 | m    | m              | s    | u      | 7000 | Segment-c | Segment-c | /home/gpadmin/data/mirror/gpseg12
   27 |      13 | m    | m              | s    | u      | 7001 | Segment-c | Segment-c | /home/gpadmin/data/mirror/gpseg13
   28 |      14 | m    | m              | s    | u      | 7002 | Segment-c | Segment-c | /home/gpadmin/data/mirror/gpseg14
   29 |      15 | m    | m              | s    | u      | 7003 | Segment-c | Segment-c | /home/gpadmin/data/mirror/gpseg15
   30 |       8 | m    | m              | s    | u      | 7000 | Segment-d | Segment-d | /home/gpadmin/data/mirror/gpseg8
   31 |       9 | m    | m              | s    | u      | 7001 | Segment-d | Segment-d | /home/gpadmin/data/mirror/gpseg9
   32 |      10 | m    | m              | s    | u      | 7002 | Segment-d | Segment-d | /home/gpadmin/data/mirror/gpseg10
   33 |      11 | m    | m              | s    | u      | 7003 | Segment-d | Segment-d | /home/gpadmin/data/mirror/gpseg11
   34 |      16 | p    | p              | s    | u      | 6004 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg16
   35 |      17 | p    | p              | s    | u      | 6004 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg17
   36 |      18 | p    | p              | s    | u      | 6004 | Segment-c | Segment-c | /home/gpadmin/data/primary/gpseg18
   37 |      19 | p    | p              | s    | u      | 6004 | Segment-d | Segment-d | /home/gpadmin/data/primary/gpseg19
   38 |      19 | m    | m              | s    | u      | 7004 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg19
   39 |      16 | m    | m              | s    | u      | 7004 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg16
   40 |      17 | m    | m              | s    | u      | 7004 | Segment-c | Segment-c | /home/gpadmin/data/mirror/gpseg17
   41 |      18 | m    | m              | s    | u      | 7004 | Segment-d | Segment-d | /home/gpadmin/data/mirror/gpseg18
(41 rows)

test_database=# 

test_database=# SELECT gp_segment_id,count(1) FROM table_test
GROUP BY gp_segment_id
ORDER BY gp_segment_id;
 gp_segment_id | count
---------------+--------
             0 | 249623
             1 | 249357
             2 | 250323
             3 | 249888
             4 | 249593
             5 | 249057
             6 | 249956
             7 | 249808
             8 | 249998
             9 | 249947
            10 | 250265
            11 | 250400
            12 | 251187
            13 | 250230
            14 | 250965
            15 | 249301
            16 | 249621
            17 | 250664
            18 | 250624
            19 | 249193
(20 rows)

有2种方案可以选择，第一个是 备份全部的数据，删除对应的segment主机全部节点后重新导入数据，但是这是实验八的内容，先跳过，第二种方案是一个一个segment节点进行删除，做尝试。

我们采用规划的方案2进行处理。


37 |      19 | p    | p              | s    | u      | 6004 | Segment-d | Segment-d | /home/gpadmin/data/primary/gpseg19、

test_database=# delete from  gp_segment_configuration where dbid=37;
ERROR:  permission denied: "gp_segment_configuration" is a system catalog
test_database=# set allow_system_table_mods='true';
SET

test_database=# delete from  gp_segment_configuration where dbid=37;
DELETE 1

test_database=# select * from gp_segment_configuration order by dbid;
 dbid | content | role | preferred_role | mode | status | port | hostname  |  address  |              datadir
------+---------+------+----------------+------+--------+------+-----------+-----------+------------------------------------
    1 |      -1 | p    | p              | n    | u      | 5432 | Master-a  | Master-a  | /home/gpadmin/data/master/gpseg-1
    2 |       0 | p    | p              | s    | u      | 6000 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg0
    3 |       1 | p    | p              | s    | u      | 6001 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg1
    4 |       2 | p    | p              | s    | u      | 6000 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg2
    5 |       3 | p    | p              | s    | u      | 6001 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg3
    6 |       4 | p    | p              | s    | u      | 6002 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg4
    7 |       5 | p    | p              | s    | u      | 6003 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg5
    8 |       6 | p    | p              | s    | u      | 6002 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg6
    9 |       7 | p    | p              | s    | u      | 6003 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg7
   10 |       0 | m    | m              | s    | u      | 7000 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg0
   11 |       1 | m    | m              | s    | u      | 7001 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg1
   12 |       4 | m    | m              | s    | u      | 7002 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg4
   13 |       5 | m    | m              | s    | u      | 7003 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg5
   14 |       2 | m    | m              | s    | u      | 7000 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg2
   15 |       3 | m    | m              | s    | u      | 7001 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg3
   16 |       6 | m    | m              | s    | u      | 7002 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg6
   17 |       7 | m    | m              | s    | u      | 7003 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg7
   18 |       8 | p    | p              | s    | u      | 6000 | Segment-c | Segment-c | /home/gpadmin/data/primary/gpseg8
   19 |       9 | p    | p              | s    | u      | 6001 | Segment-c | Segment-c | /home/gpadmin/data/primary/gpseg9
   20 |      10 | p    | p              | s    | u      | 6002 | Segment-c | Segment-c | /home/gpadmin/data/primary/gpseg10
   21 |      11 | p    | p              | s    | u      | 6003 | Segment-c | Segment-c | /home/gpadmin/data/primary/gpseg11
   22 |      12 | p    | p              | s    | u      | 6000 | Segment-d | Segment-d | /home/gpadmin/data/primary/gpseg12
   23 |      13 | p    | p              | s    | u      | 6001 | Segment-d | Segment-d | /home/gpadmin/data/primary/gpseg13
   24 |      14 | p    | p              | s    | u      | 6002 | Segment-d | Segment-d | /home/gpadmin/data/primary/gpseg14
   25 |      15 | p    | p              | s    | u      | 6003 | Segment-d | Segment-d | /home/gpadmin/data/primary/gpseg15
   26 |      12 | m    | m              | s    | u      | 7000 | Segment-c | Segment-c | /home/gpadmin/data/mirror/gpseg12
   27 |      13 | m    | m              | s    | u      | 7001 | Segment-c | Segment-c | /home/gpadmin/data/mirror/gpseg13
   28 |      14 | m    | m              | s    | u      | 7002 | Segment-c | Segment-c | /home/gpadmin/data/mirror/gpseg14
   29 |      15 | m    | m              | s    | u      | 7003 | Segment-c | Segment-c | /home/gpadmin/data/mirror/gpseg15
   30 |       8 | m    | m              | s    | u      | 7000 | Segment-d | Segment-d | /home/gpadmin/data/mirror/gpseg8
   31 |       9 | m    | m              | s    | u      | 7001 | Segment-d | Segment-d | /home/gpadmin/data/mirror/gpseg9
   32 |      10 | m    | m              | s    | u      | 7002 | Segment-d | Segment-d | /home/gpadmin/data/mirror/gpseg10
   33 |      11 | m    | m              | s    | u      | 7003 | Segment-d | Segment-d | /home/gpadmin/data/mirror/gpseg11
   34 |      16 | p    | p              | s    | u      | 6004 | Segment-a | Segment-a | /home/gpadmin/data/primary/gpseg16
   35 |      17 | p    | p              | s    | u      | 6004 | Segment-b | Segment-b | /home/gpadmin/data/primary/gpseg17
   36 |      18 | p    | p              | s    | u      | 6004 | Segment-c | Segment-c | /home/gpadmin/data/primary/gpseg18
   38 |      19 | m    | m              | s    | u      | 7004 | Segment-a | Segment-a | /home/gpadmin/data/mirror/gpseg19
   39 |      16 | m    | m              | s    | u      | 7004 | Segment-b | Segment-b | /home/gpadmin/data/mirror/gpseg16
   40 |      17 | m    | m              | s    | u      | 7004 | Segment-c | Segment-c | /home/gpadmin/data/mirror/gpseg17
   41 |      18 | m    | m              | s    | u      | 7004 | Segment-d | Segment-d | /home/gpadmin/data/mirror/gpseg18
(40 rows)

test_database=# 

[gpadmin@Master-a root]$ gpstate
20240730:11:17:21:004136 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: 
20240730:11:17:21:004136 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240730:11:17:21:004136 gpstate:Master-a:gpadmin-[CRITICAL]:-gpstate failed. (Reason='FATAL:  the database system is in recovery mode
DETAIL:  last replayed record at 0/0
') exiting...
[gpadmin@Master-a root]$ gpstate -s
20240730:11:17:42:006174 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: -s
20240730:11:17:42:006174 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240730:11:17:42:006174 gpstate:Master-a:gpadmin-[CRITICAL]:-gpstate failed. (Reason='FATAL:  the database system is in recovery mode
DETAIL:  last replayed record at 0/0
') exiting...
[gpadmin@Master-a root]$

test_database=# SELECT gp_segment_id,count(1) FROM table_test
GROUP BY gp_segment_id
ORDER BY gp_segment_id;
server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
test_database=# 
```

#### 第一次故障触发失败回滚镜像分析

```powershell

需要回滚镜像了 ！！！！

回滚镜像 验证集群状态和数据状态

[gpadmin@Master-a root]$ gpstate
20240730:11:47:12:003646 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: 
20240730:11:47:12:003646 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240730:11:47:12:003646 gpstate:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240730:11:47:12:003646 gpstate:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240730:11:47:12:003646 gpstate:Master-a:gpadmin-[INFO]:-Gathering data from segments...
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-Greenplum instance status summary
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Master instance                                           = Active
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Master standby                                            = No master standby configured
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total segment instance count from metadata                = 40
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Primary Segment Status
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segments                                    = 20
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment valid (at master)                   = 20
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment failures (at master)                = 0
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 20
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 20
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 20
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes found                   = 20
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Mirror Segment Status
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total mirror segments                                     = 20
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total mirror segment valid (at master)                    = 20
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total mirror segment failures (at master)                 = 0
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 20
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 20
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 20
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes found                   = 20
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number mirror segments acting as primary segments   = 0
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Total number mirror segments acting as mirror segments    = 20
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-   Cluster Expansion                                         = In Progress
20240730:11:47:13:003646 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
[gpadmin@Master-a root]$


test_database=# SELECT gp_segment_id,count(1) FROM table_test
GROUP BY gp_segment_id
ORDER BY gp_segment_id;
 gp_segment_id | count
---------------+--------
             0 | 249623
             1 | 249357
             2 | 250323
             3 | 249888
             4 | 249593
             5 | 249057
             6 | 249956
             7 | 249808
             8 | 249998
             9 | 249947
            10 | 250265
            11 | 250400
            12 | 251187
            13 | 250230
            14 | 250965
            15 | 249301
            16 | 249621
            17 | 250664
            18 | 250624
            19 | 249193
(20 rows)

没问题 ……

本次故障造成的不可挽回的损失是因为 通过验证元数据删除 而导致集群处于崩溃状态 死循环，故需要验证思想，通过删除数据的方式（模拟磁盘或文件夹数据损坏），再次进行实验。
```

### 第二次实验

#### 第二次实验计划

计划通过删除segment实例的方式进行模拟磁盘或文件夹故障或被污染，故障触发后检查自愈能力集群状态数据状态和人工干预并记录过程后修复。

#### 第二次尝试故障触发

## 实验六：新增Standby，HA高可用热备节点

Loding ...

## 实验七：大数据量导入

Loding ...

## 实验八：数据备份&数据恢复...

Loding ...

## 实验九：数据库账户密码&权限认证相关

Loding ...

## 实验十：数据库版本更新

Loding ...