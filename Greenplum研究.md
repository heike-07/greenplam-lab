# Greenplum 研究

## 主机规划

| 主机名    | IP                           | 所属用途    |
| --------- | ---------------------------- | ----------- |
| gpserver1 | 192.168.7.159/192.168.30.179 | master节点  |
| gpserver2 | 192.168.7.160/192.168.30.180 | segment节点 |

## 操作系统初始化配置

$全部节点执行$

```shell
# 关闭SELINUX
略

# 查看外网连接
[root@gpserver1 ~]# ping www.baidu.com
PING www.a.shifen.com (110.242.68.4) 56(84) bytes of data.
64 bytes from 110.242.68.4 (110.242.68.4): icmp_seq=1 ttl=128 time=37.5 ms
64 bytes from 110.242.68.4 (110.242.68.4): icmp_seq=2 ttl=128 time=30.2 ms
...

# 安装epel源
[root@gpserver1 ~]# yum install -y epel-release
Loaded plugins: fastestmirror
Determining fastest mirrors
 * base: mirrors.bfsu.edu.cn
 * extras: mirrors.bfsu.edu.cn
...

# 安装基础依赖库
[root@gpserver1 ~]# yum install vim net-tools psmisc nc rsync lrzsz ntp libzstd openssl-static tree iotop git
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
epel/x86_64/metalink                                                             ...

# 修改hosts文件
[root@gpserver1 ~]# vim /etc/hosts
[root@gpserver1 ~]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.7.159 gpserver1
192.168.7.160 gpserver2
[root@gpserver1 ~]#

---gpserver2+
[root@gpserver2 ~]# echo '''
> 192.168.7.159 gpserver1
> 192.168.7.160 gpserver2
> ''' >> /etc/hosts
[root@gpserver2 ~]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.7.159 gpserver1
192.168.7.160 gpserver2

[root@gpserver2 ~]#
---

# 安装基础依赖环境
yum install apr apr-util bash bzip2 curl krb5 libcurl libevent libxml2 libyaml zlib openldap openssh-client openssl openssl-libs perl readline rsync R sed tar zip krb5-
devel
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
...
```

## 系统配置参数计算

$全部节点执行$

```shell
# 计算共享内存 公式: kernel.shmall= _PHYS_PAGESS / 2 :_PHYS_PAGESS 可用内存页总量
# 实际计算 
# KERNEL.SHMALL
[root@gpserver1 ~]# echo $(expr $(getconf _PHYS_PAGES) / 2)
232880
[root@gpserver1 ~]# free
              total        used        free      shared  buff/cache   available
Mem:        1863040      254744      565428        9776     1042868     1417188
Swap:       2097148           0     2097148
[root@gpserver1 ~]#

# KERNEL.SHMMAX
[root@gpserver1 ~]# echo $(expr $(getconf _PHYS_PAGES) / 2 \* $(getconf PAGE_SIZE))
953876480
[root@gpserver1 ~]# 

vm.overcommit_memory 系统使用该参数来确定可用为进程分配多少内存 gp 应该为2
vm.overcommit_ratio 为进程分配的百分比，其余留给操作系统 gp 建议 95

# 调整sysctl.conf
[root@gpserver1 ~]# vim /etc/sysctl.conf 
[root@gpserver1 ~]# sysctl -p
kernel.shmall = 232880
kernel.shmmax = 953876480
kernel.shmmni = 4096
vm.overcommit_memory = 2
vm.overcommit_ratio = 95
net.ipv4.ip_local_port_range = 10000 65535
kernel.sysrq = 1
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.msgmni = 2048
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.conf.all.arp_filter = 1
net.core.netdev_max_backlog = 10000
net.core.rmem_max = 2097152
net.core.wmem_max = 2097152
vm.swappiness = 10
vm.zone_reclaim_mode = 0
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
vm.dirty_background_ratio = 3
vm.dirty_ratio = 10
[root@gpserver1 ~]#
```

参数解释  -由Gpt4.0(128K)提供

```objective-c
好的，这些参数大致可以分为处理内存、网络和内核消息的参数。下面是它们的详细解释：
kernel.shmall：在系统范围内设定共享内存的最大总量（以页为单位）。当创建共享内存段时，系统将它和这个值进行比较。
kernel.shmmax：系统中单个共享内存段的最大大小（以字节为单位）。这个参数也会影响到共享内存的创建。
kernel.shmmni：系统范围内共享内存段的最大数量。
vm.overcommit_memory 和 vm.overcommit_ratio：这些设置决定了系统对内存超量分配的策略。
net.ipv4.ip_local_port_range：这个值设定了TCP和UDP协议能使用的本地端口范围。
kernel.sysrq：延长系统请求的功能，如重新启动、关机、内存转储等。
kernel.core_uses_pid：当启用后，程序跳出核心文件时会在文件名中包含进程ID。
kernel.msgmnb，kernel.msgmax，kernel.msgmni：这些参数调整IPC消息队列的大小和数量。
net.ipv4.tcp_syncookies：当启用时，防止了TCP SYN洪水攻击，但在某些情况下可能会影响正常的TCP链接。
net.ipv4.conf.default.accept_source_route 和 net.ipv4.conf.all.arp_filter：IP选项和ARP协议的处理。
net.ipv4.tcp_max_syn_backlog：为尚未获得对方确认的连接请求设置最大排队数量。
net.core.netdev_max_backlog：接收数据包的最大速率。
net.core.rmem_max 和 net.core.wmem_max：设定网络连接的最大内存缓冲区大小。
vm.swappiness：影响内核交换内存页面的相对权重。
vm.zone_reclaim_mode：设置本地节点内存回收策略。
vm.dirty_expire_centisecs，vm.dirty_writeback_centisecs，vm.dirty_background_ratio，vm.dirty_ratio：调整系统何时对“脏”内存页面进行写回。
以上是对每个参数的简短解释，每个参数的设定都会对系统性能产生影响，需要根据具体的系统环境和应用需求进行设置。
```

```shell
# 修改系统配额
[root@gpserver1 ~]# vim /etc/security/limits.conf 
[root@gpserver1 ~]# cat /etc/security/limits.conf | grep *
[root@gpserver1 ~]# cat /etc/security/limits.conf | grep ^*
*    soft    nofile    65536
*    hard    nofile    65536
*    soft    nproc     131072
*    hard    nproc     131072
[root@gpserver1 ~]#

# 修改系统配额2
[root@gpserver1 ~]# vim /etc/security/limits.d/20-nproc.conf 
[root@gpserver1 ~]# cat /etc/security/limits.d/20-nproc.conf 
# Default limit for number of user's processes to prevent
# accidental fork bombs.
# See rhbz #432903 for reasoning.

*          soft    nproc     4096
root       soft    nproc     unlimited

*    soft    nofile    65536
*    hard    nofile    65536
*    soft    nproc     131072
*    hard    nproc     131072
[root@gpserver1 ~]#

# 修改SSHD服务相关配置
[root@gpserver1 ~]# vim /etc/ssh/sshd_config 
[root@gpserver1 ~]# cat /etc/ssh/sshd_config |grep *Max
[root@gpserver1 ~]# cat /etc/ssh/sshd_config |grep ^Max
MaxSessions 200
MaxStartups 100:30:1000
[root@gpserver1 ~]# 
[root@gpserver1 ~]# systemctl restart sshd
[root@gpserver1 ~]# 

# 字符集编码确认
[root@gpserver1 ~]# echo $LANG
en_US.UTF-8
[root@gpserver1 ~]#
-- 如果不是 执行localectl set-locale LANG=es_US.UTF-8

# 时间同步
[root@gpserver1 ~]# ntpdate cn.pool.ntp.org
11 May 09:34:31 ntpdate[98072]: adjust time server 95.111.202.5 offset 0.003456 sec
[root@gpserver1 ~]# date
Sat May 11 09:34:34 CST 2024
[root@gpserver1 ~]#
```

## 安装GreenPlum前设置

$全部节点执行，部分特定节点执行$

```shell
# 创建gpadmin用户以及用户组
[root@gpserver2 ~]# groupadd gpadmin
[root@gpserver2 ~]# useradd gpadmin -r -m -g gpadmin
[root@gpserver2 ~]# id gpadmin
uid=997(gpadmin) gid=1000(gpadmin) groups=1000(gpadmin)
[root@gpserver2 ~]#

# 设置密码123456 --生产不可以使用弱密码
[root@gpserver2 ~]# passwd gpadmin
Changing password for user gpadmin.
New password:       
BAD PASSWORD: The password is shorter than 8 characters
Retype new password:       
passwd: all authentication tokens updated successfully.
[root@gpserver2 ~]#

# gpadmin设置无需输入密码确认ROOT权限
[root@gpserver2 ~]# cat /etc/sudoers | grep gpadmin
gpadmin ALL=(ALL)       NOPASSWD:ALL
[root@gpserver2 ~]#

# 切换到gpadmin用户
[root@gpserver1 ~]# su - gpadmin
[gpadmin@gpserver1 ~]$

# 制作免密登陆
[gpadmin@gpserver1 ~]$ ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/home/gpadmin/.ssh/id_rsa): 
Created directory '/home/gpadmin/.ssh'.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/gpadmin/.ssh/id_rsa.
Your public key has been saved in /home/gpadmin/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:KOOufHKJmqhVBeV++vyVTbSA239cKjOd+aDA2eheiHQ gpadmin@gpserver1
The key's randomart image is:
+---[RSA 2048]----+
|    ...          |
|     o     .     |
|      o   . . .  |
|     o .   o o . |
|    + o S E . o .|
|   o o + + = * =.|
|  ..... . * O O o|
|.+o.+  o . + = + |
|*.o=.   oo+ .   .|
+----[SHA256]-----+
[gpadmin@gpserver1 ~]$

[gpadmin@gpserver1 ~]$ ssh-copy-id gpserver1
/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/gpadmin/.ssh/id_rsa.pub"
The authenticity of host 'gpserver1 (192.168.7.159)' can't be established.
ECDSA key fingerprint is SHA256:bYMqijStdlu132Ken/cAWqQUuTHgOPkdvTkG0ewM/bw.
ECDSA key fingerprint is MD5:4c:50:c2:db:9e:aa:c7:f8:e2:79:0d:50:73:7f:1f:a8.
Are you sure you want to continue connecting (yes/no)? yes
/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
gpadmin@gpserver1's password:       

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'gpserver1'"
and check to make sure that only the key(s) you wanted were added.

[gpadmin@gpserver1 ~]$ ssh 'gpserver1'
Last login: Sat May 11 09:48:32 2024
[gpadmin@gpserver1 ~]$ exit
logout
Connection to gpserver1 closed.
[gpadmin@gpserver1 ~]$ ssh-copy-id gpserver2
/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/gpadmin/.ssh/id_rsa.pub"
The authenticity of host 'gpserver2 (192.168.7.160)' can't be established.
ECDSA key fingerprint is SHA256:hFaYoCSA2ZvOcVkljAzPCfuRHTTa+aBbOEdoQ5FzgXY.
ECDSA key fingerprint is MD5:ca:84:4f:f3:d1:d9:f6:56:4f:f6:18:e6:82:65:87:44.
Are you sure you want to continue connecting (yes/no)? yes
/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
gpadmin@gpserver2's password:       

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'gpserver2'"
and check to make sure that only the key(s) you wanted were added.

[gpadmin@gpserver1 ~]$ ssh 'gpserver2'
Last login: Sat May 11 09:48:39 2024
[gpadmin@gpserver2 ~]$ exit
logout
Connection to gpserver2 closed.
[gpadmin@gpserver1 ~]$

# 配置GreepPlum SSH权限互通 **仅在gpserver1 master节点配置
[gpadmin@gpserver1 ~]$ mkdir -p /home/gpadmin/conf
[gpadmin@gpserver1 ~]$ touch /home/gpadmin/conf/hostlist
[gpadmin@gpserver1 ~]$ touch /home/gpadmin/conf/seg_hosts
[gpadmin@gpserver1 ~]$ cat conf/hostlist 
gpserver1
gpserver2
[gpadmin@gpserver1 ~]$ cat conf/seg_hosts 
gpserver2
[gpadmin@gpserver1 ~]$ 
```

## GP数据库安装

$全部节点执行$

```powershell
# RPM 安装数据库
[gpadmin@gpserver1 ~]$ mkdir soft
[gpadmin@gpserver1 ~]$ cd soft/
[gpadmin@gpserver1 soft]$ ls
greenplum-db-6.13.0-rhel7-x86_64.rpm
[gpadmin@gpserver1 soft]$ yum install ./greenplum-db-6.13.0-rhel7-x86_64.rpm 
Loaded plugins: fastestmirror
You need to be root to perform this command.
[gpadmin@gpserver1 soft]$ sudo yum install ./greenplum-db-6.13.0-rhel7-x86_64.rpm 
Loaded plugins: fastestmirror
Examining ./greenplum-db-6.13.0-rhel7-x86_64.rpm: greenplum-db-6-6.13.0-1.el7.x86_64
Marking ./greenplum-db-6.13.0-rhel7-x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package greenplum-db-6.x86_64 0:6.13.0-1.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

======================================================================================================================================================================
 Package                              Arch                         Version                              Repository                                               Size
======================================================================================================================================================================
Installing:
 greenplum-db-6                       x86_64                       6.13.0-1.el7                         /greenplum-db-6.13.0-rhel7-x86_64                       311 M

Transaction Summary
======================================================================================================================================================================
Install  1 Package

Total size: 311 M
Installed size: 311 M
Is this ok [y/d/N]: y
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : greenplum-db-6-6.13.0-1.el7.x86_64                                                                                                                 1/1 
  Verifying  : greenplum-db-6-6.13.0-1.el7.x86_64                                                                                                                 1/1 

Installed:
  greenplum-db-6.x86_64 0:6.13.0-1.el7                                                                                                                                

Complete!
[gpadmin@gpserver1 soft]$

# 查看安装结果
[gpadmin@gpserver1 soft]$ cd /usr/local/
[gpadmin@gpserver1 local]$ ls
bin  etc  games  greenplum-db  greenplum-db-6.13.0  include  lib  lib64  libexec  sbin  share  src
[gpadmin@gpserver1 local]$ ll
total 0
drwxr-xr-x.  2 root root   6 Apr 11  2018 bin
drwxr-xr-x.  2 root root   6 Apr 11  2018 etc
drwxr-xr-x.  2 root root   6 Apr 11  2018 games
lrwxrwxrwx   1 root root  30 May 11 11:15 greenplum-db -> /usr/local/greenplum-db-6.13.0
drwxr-xr-x  11 root root 238 May 11 11:15 greenplum-db-6.13.0
drwxr-xr-x.  2 root root   6 Apr 11  2018 include
drwxr-xr-x.  2 root root   6 Apr 11  2018 lib
drwxr-xr-x.  2 root root   6 Apr 11  2018 lib64
drwxr-xr-x.  2 root root   6 Apr 11  2018 libexec
drwxr-xr-x.  2 root root   6 Apr 11  2018 sbin
drwxr-xr-x.  5 root root  49 May 10 18:26 share
drwxr-xr-x.  2 root root   6 Apr 11  2018 src
[gpadmin@gpserver1 local]$

# 授权用户
[gpadmin@gpserver1 local]$ sudo chown -R gpadmin:gpadmin /usr/local/greenplum-db*
[gpadmin@gpserver1 local]$ ll
total 0
drwxr-xr-x.  2 root    root      6 Apr 11  2018 bin
drwxr-xr-x.  2 root    root      6 Apr 11  2018 etc
drwxr-xr-x.  2 root    root      6 Apr 11  2018 games
lrwxrwxrwx   1 gpadmin gpadmin  30 May 11 11:15 greenplum-db -> /usr/local/greenplum-db-6.13.0
drwxr-xr-x  11 gpadmin gpadmin 238 May 11 11:15 greenplum-db-6.13.0
drwxr-xr-x.  2 root    root      6 Apr 11  2018 include
drwxr-xr-x.  2 root    root      6 Apr 11  2018 lib
drwxr-xr-x.  2 root    root      6 Apr 11  2018 lib64
drwxr-xr-x.  2 root    root      6 Apr 11  2018 libexec
drwxr-xr-x.  2 root    root      6 Apr 11  2018 sbin
drwxr-xr-x.  5 root    root     49 May 10 18:26 share
drwxr-xr-x.  2 root    root      6 Apr 11  2018 src
[gpadmin@gpserver1 local]$ 

# 传输到gpserver2
[gpadmin@gpserver1 local]$ ssh gpserver2 "mkdir /home/gpadmin/soft"
[gpadmin@gpserver1 local]$ scp /home/gpadmin/soft/greenplum-db-6.13.0-rhel7-x86_64.rpm gpserver2:/home/gpadmin/soft/
greenplum-db-6.13.0-rhel7-x86_64.rpm                                                                                                100%   66MB  54.2MB/s   00:01    
[gpadmin@gpserver1 local]$ 

# gpserver2 同样方式安装数据库
略
```

## GP数据库设置

```powershell
# source 环境变量
[gpadmin@gpserver1 local]$ source /usr/local/greenplum-db-6.13.0/greenplum_path.sh 
[gpadmin@gpserver1 local]$ 

# 测试联通性
[gpadmin@gpserver1 local]$ gpssh-exkeys -f /home/gpadmin/conf/hostlist 
[STEP 1 of 5] create local ID and authorize on local host
  ... /home/gpadmin/.ssh/id_rsa file exists ... key generation skipped

[STEP 2 of 5] keyscan all hosts and update known_hosts file

[STEP 3 of 5] retrieving credentials from remote hosts
  ... send to gpserver2

[STEP 4 of 5] determine common authentication file content

[STEP 5 of 5] copy authentication files to all remote hosts
  ... finished key exchange with gpserver2

[INFO] completed successfully
[gpadmin@gpserver1 local]$

# 创建数据目录
[gpadmin@gpserver1 local]$ mkdir -p /home/gpadmin/data/master
[gpadmin@gpserver1 local]$ cd ~
[gpadmin@gpserver1 ~]$ ls
conf  data  soft
[gpadmin@gpserver1 ~]$ ll -a
total 20
drwx------  6 gpadmin gpadmin 147 May 11 11:32 .
drwxr-xr-x. 3 root    root     21 May 11 09:47 ..
-rw-------  1 gpadmin gpadmin   5 May 11 09:51 .bash_history
-rw-r--r--  1 gpadmin gpadmin  18 Nov 25  2021 .bash_logout
-rw-r--r--  1 gpadmin gpadmin 193 Nov 25  2021 .bash_profile
-rw-r--r--  1 gpadmin gpadmin 231 Nov 25  2021 .bashrc
drwxrwxr-x  2 gpadmin gpadmin  39 May 11 10:07 conf
drwxrwxr-x  3 gpadmin gpadmin  20 May 11 11:32 data
drwxrwxr-x  2 gpadmin gpadmin  50 May 11 11:12 soft
drwx------  2 gpadmin gpadmin 113 May 11 11:31 .ssh
-rw-------  1 gpadmin gpadmin 791 May 11 10:07 .viminfo
[gpadmin@gpserver1 ~]$ 


# 环境变量配置
[gpadmin@gpserver1 ~]$ vim .bashrc 
[gpadmin@gpserver1 ~]$ cat .bashrc 
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions

source /usr/local/greenplum-db/greenplum_path.sh
export PGPORT=5432
export PGUSER=gpadmin
export MASTER_DATA_DIRECTORY=/home/gpadmin/data/master/gpseg-1
export PGDATABASE=gp_sydb
export LD_PRELOAD=/lib64/libz.so.1 ps
[gpadmin@gpserver1 ~]$

# 增加环境变量
[gpadmin@gpserver1 ~]$ cat /usr/local/greenplum-db/greenplum_path.sh | grep GPHOME=/
GPHOME=/usr/local/greenplum-db
[gpadmin@gpserver1 ~]$

# 创建数据文件夹
[gpadmin@gpserver1 ~]$ gpssh -f /home/gpadmin/conf/hostlist 
=> mkdir data
[gpserver1] mkdir: cannot create directory ‘data’: File exists
[gpserver2] mkdir: cannot create directory ‘data’: File exists
=> cd data
[gpserver1]
[gpserver2]
=> mkdir master
[gpserver1] mkdir: cannot create directory ‘master’: File exists
[gpserver2] mkdir: cannot create directory ‘master’: File exists
=> mkdir primary
[gpserver1]
[gpserver2]
=> mkdir mirror
[gpserver1]
[gpserver2]
=> exit

[gpadmin@gpserver1 ~]$

# 检查联通性
[gpadmin@gpserver1 ~]$ gpcheckperf -f /home/gpadmin/conf/hostlist -r N -d /tmp
/usr/local/greenplum-db-6.13.0/bin/gpcheckperf -f /home/gpadmin/conf/hostlist -r N -d /tmp

-------------------
--  NETPERF TEST
-------------------
NOTICE: -t is deprecated, and has no effect
NOTICE: -f is deprecated, and has no effect
Could not connect to server after 5 retries
[Warning] netperf failed on gpserver1 -> gpserver2
NOTICE: -t is deprecated, and has no effect
NOTICE: -f is deprecated, and has no effect
Could not connect to server after 5 retries
[Warning] netperf failed on gpserver2 -> gpserver1

====================
==  RESULT 2024-05-11T11:54:19.504109
====================
[gpadmin@gpserver1 ~]$ 
&& 报错，需要把防火墙关闭

# 关闭防火墙
[gpadmin@gpserver1 ~]$ sudo systemctl stop firewalld
[gpadmin@gpserver1 ~]$ sudo systemctl disable firewalld
Removed symlink /etc/systemd/system/multi-user.target.wants/firewalld.service.
Removed symlink /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service.

# 再次测试
[gpadmin@gpserver1 ~]$ gpcheckperf -f /home/gpadmin/conf/hostlist -r N -d /tmp
/usr/local/greenplum-db-6.13.0/bin/gpcheckperf -f /home/gpadmin/conf/hostlist -r N -d /tmp

-------------------
--  NETPERF TEST
-------------------
[Warning] retrying with port 23012
NOTICE: -t is deprecated, and has no effect
NOTICE: -f is deprecated, and has no effect
NOTICE: -t is deprecated, and has no effect
NOTICE: -f is deprecated, and has no effect

====================
==  RESULT 2024-05-11T11:59:36.828222
====================
Netperf bisection bandwidth test
gpserver1 -> gpserver2 = 72.310000
gpserver2 -> gpserver1 = 72.970000

Summary:
sum = 145.28 MB/sec
min = 72.31 MB/sec
max = 72.97 MB/sec
avg = 72.64 MB/sec
median = 72.97 MB/sec

[gpadmin@gpserver1 ~]$ 

```

## 初始化集群

```powershell
# 启动前修改配置文件
[gpadmin@gpserver1 ~]$ mkdir /home/gpadmin/gpconfigs
[gpadmin@gpserver1 ~]$ cp /usr/local/greenplum-db/docs/cli_help/gpconfigs/gpinitsystem_config /home/gpadmin/gpconfigs/
[gpadmin@gpserver1 ~]$ 

[gpadmin@gpserver1 ~]$ cat gpconfigs/gpinitsystem_config |grep -v '#'
ARRAY_NAME="Greenplum Data Platform"
SEG_PREFIX=gpseg
PORT_BASE=6000
declare -a DATA_DIRECTORY=(/home/gpadmin/data/primary /home/gpadmin/data/primary)
MASTER_HOSTNAME=gpserver1
MASTER_DIRECTORY=/home/gadmin/data/master
MASTER_PORT=5432
TRUSTED_SHELL=ssh
CHECK_POINT_SEGMENTS=8
ENCODING=UNICODE
declare -a MIRROR_DATA_DIRECTORY=(/home/gpadmin/data/primary /home/gpamin/data/primary)
DATABASE_NAME=gp_sydb
[gpadmin@gpserver1 ~]$ 

# 创建初始化配置文件
[gpadmin@gpserver1 gpconfigs]$ touch hostfile_gpinitsystem
[gpadmin@gpserver1 gpconfigs]$ cat << EOF >> hostfile_gpinitsystem 
> gpserver2
> EOF
[gpadmin@gpserver1 gpconfigs]$ cat hostfile_gpinitsystem 
gpserver2
[gpadmin@gpserver1 gpconfigs]$

# 初始化集群
[gpadmin@gpserver1 gpconfigs]$ gpinitsystem -c /home/gpadmin/gpconfigs/gpinitsystem_config -h /home/gpadmin/gpconfigs/hostfile_gpinitsystem 
20240511:13:54:04:049220 gpinitsystem:gpserver1:gpadmin-[INFO]:-Checking configuration parameters, please wait...
20240511:13:54:04:049220 gpinitsystem:gpserver1:gpadmin-[INFO]:-Reading Greenplum configuration file /home/gpadmin/gpconfigs/gpinitsystem_config
20240511:13:54:04:049220 gpinitsystem:gpserver1:gpadmin-[INFO]:-Locale has not been set in /home/gpadmin/gpconfigs/gpinitsystem_config, will set to default value
20240511:13:54:04:049220 gpinitsystem:gpserver1:gpadmin-[INFO]:-Locale set to en_US.utf8
/bin/touch: cannot touch ‘/home/gadmin/data/master/tmp_file_test’: No such file or directory
20240511:13:54:04:049220 gpinitsystem:gpserver1:gpadmin-[FATAL]:-Cannot write to /home/gadmin/data/master on master host  Script Exiting!
[gpadmin@gpserver1 gpconfigs]$ 

>>? 报错？ 修改错误路径

[gpadmin@gpserver1 gpconfigs]$ gpinitsystem -c /home/gpadmin/gpconfigs/gpinitsystem_config -h /home/gpadmin/gpconfigs/hostfile_gpinitsystem 
20240511:13:56:50:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Checking configuration parameters, please wait...
20240511:13:56:50:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Reading Greenplum configuration file /home/gpadmin/gpconfigs/gpinitsystem_config
20240511:13:56:50:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Locale has not been set in /home/gpadmin/gpconfigs/gpinitsystem_config, will set to default value
20240511:13:56:50:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Locale set to en_US.utf8
20240511:13:56:50:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-MASTER_MAX_CONNECT not set, will set to default value 250
20240511:13:56:50:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Detected a single host GPDB array build, reducing value of BATCH_DEFAULT from 60 to 4
20240511:13:56:50:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Checking configuration parameters, Completed
20240511:13:56:50:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Commencing multi-home checks, please wait...
.
20240511:13:56:50:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Configuring build for standard array
20240511:13:56:50:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Commencing multi-home checks, Completed
20240511:13:56:50:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Building primary segment instance array, please wait...
..
20240511:13:56:51:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Checking Master host
20240511:13:56:51:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Checking new segment hosts, please wait...
..
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Checking new segment hosts, Completed
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Greenplum Database Creation Parameters
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:---------------------------------------
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Master Configuration
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:---------------------------------------
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Master instance name       = Greenplum Data Platform
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Master hostname            = gpserver1
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Master port                = 5432
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Master instance dir        = /home/gpadmin/data/master/gpseg-1
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Master LOCALE              = en_US.utf8
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Greenplum segment prefix   = gpseg
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Master Database            = gp_sydb
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Master connections         = 250
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Master buffers             = 128000kB
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Segment connections        = 750
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Segment buffers            = 128000kB
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Checkpoint segments        = 8
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Encoding                   = UNICODE
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Postgres param file        = Off
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Initdb to be used          = /usr/local/greenplum-db-6.13.0/bin/initdb
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-GP_LIBRARY_PATH is         = /usr/local/greenplum-db-6.13.0/lib
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-HEAP_CHECKSUM is           = on
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-HBA_HOSTNAMES is           = 0
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Ulimit check               = Passed
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Array host connect type    = Single hostname per node
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Master IP address [1]      = ::1
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Master IP address [2]      = 192.168.30.179
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Master IP address [3]      = 192.168.7.159
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Master IP address [4]      = fe80::1ae:82de:e4d4:b157
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Master IP address [5]      = fe80::20c:29ff:fe71:61e0
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Standby Master             = Not Configured
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Number of primary segments = 2
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Total Database segments    = 2
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Trusted shell              = ssh
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Number segment hosts       = 1
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Mirroring config           = OFF
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:----------------------------------------
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Greenplum Primary Segment Configuration
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:----------------------------------------
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-gpserver2       6000    gpserver2       /home/gpadmin/data/primary/gpseg0       2
20240511:13:56:54:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-gpserver2       6001    gpserver2       /home/gpadmin/data/primary/gpseg1       3

Continue with Greenplum creation Yy|Nn (default=N):

输入Y


> y
20240511:13:57:21:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Building the Master instance database, please wait...
20240511:13:57:44:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Starting the Master in admin mode
20240511:13:57:45:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Commencing parallel build of primary segment instances
20240511:13:57:46:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Spawning parallel processes    batch [1], please wait...
..
20240511:13:57:46:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Waiting for parallel processes batch [1], please wait...
.................
20240511:13:58:03:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:------------------------------------------------
20240511:13:58:03:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Parallel process exit status
20240511:13:58:03:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:------------------------------------------------
20240511:13:58:03:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Total processes marked as completed           = 2
20240511:13:58:03:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Total processes marked as killed              = 0
20240511:13:58:03:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Total processes marked as failed              = 0
20240511:13:58:03:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:------------------------------------------------
20240511:13:58:03:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Deleting distributed backout files
20240511:13:58:03:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Removing back out file
20240511:13:58:03:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-No errors generated from parallel processes
20240511:13:58:03:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Restarting the Greenplum instance in production mode
20240511:13:58:03:051549 gpstop:gpserver1:gpadmin-[INFO]:-Starting gpstop with args: -a -l /home/gpadmin/gpAdminLogs -m -d /home/gpadmin/data/master/gpseg-1
20240511:13:58:03:051549 gpstop:gpserver1:gpadmin-[INFO]:-Gathering information and validating the environment...
20240511:13:58:03:051549 gpstop:gpserver1:gpadmin-[INFO]:-Obtaining Greenplum Master catalog information
20240511:13:58:03:051549 gpstop:gpserver1:gpadmin-[INFO]:-Obtaining Segment details from master...
20240511:13:58:03:051549 gpstop:gpserver1:gpadmin-[INFO]:-Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240511:13:58:03:051549 gpstop:gpserver1:gpadmin-[INFO]:-Commencing Master instance shutdown with mode='smart'
20240511:13:58:03:051549 gpstop:gpserver1:gpadmin-[INFO]:-Master segment instance directory=/home/gpadmin/data/master/gpseg-1
20240511:13:58:03:051549 gpstop:gpserver1:gpadmin-[INFO]:-Stopping master segment and waiting for user connections to finish ...
server shutting down
20240511:13:58:05:051549 gpstop:gpserver1:gpadmin-[INFO]:-Attempting forceful termination of any leftover master process
20240511:13:58:05:051549 gpstop:gpserver1:gpadmin-[INFO]:-Terminating processes for segment /home/gpadmin/data/master/gpseg-1
20240511:13:58:05:051573 gpstart:gpserver1:gpadmin-[INFO]:-Starting gpstart with args: -a -l /home/gpadmin/gpAdminLogs -d /home/gpadmin/data/master/gpseg-1
20240511:13:58:05:051573 gpstart:gpserver1:gpadmin-[INFO]:-Gathering information and validating the environment...
20240511:13:58:05:051573 gpstart:gpserver1:gpadmin-[INFO]:-Greenplum Binary Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240511:13:58:05:051573 gpstart:gpserver1:gpadmin-[INFO]:-Greenplum Catalog Version: '301908232'
20240511:13:58:05:051573 gpstart:gpserver1:gpadmin-[INFO]:-Starting Master instance in admin mode
20240511:13:58:05:051573 gpstart:gpserver1:gpadmin-[INFO]:-Obtaining Greenplum Master catalog information
20240511:13:58:05:051573 gpstart:gpserver1:gpadmin-[INFO]:-Obtaining Segment details from master...
20240511:13:58:05:051573 gpstart:gpserver1:gpadmin-[INFO]:-Setting new master era
20240511:13:58:05:051573 gpstart:gpserver1:gpadmin-[INFO]:-Master Started...
20240511:13:58:05:051573 gpstart:gpserver1:gpadmin-[INFO]:-Shutting down master
20240511:13:58:06:051573 gpstart:gpserver1:gpadmin-[INFO]:-Commencing parallel segment instance startup, please wait...
.
20240511:13:58:08:051573 gpstart:gpserver1:gpadmin-[INFO]:-Process results...
20240511:13:58:08:051573 gpstart:gpserver1:gpadmin-[INFO]:-----------------------------------------------------
20240511:13:58:08:051573 gpstart:gpserver1:gpadmin-[INFO]:-   Successful segment starts                                            = 2
20240511:13:58:08:051573 gpstart:gpserver1:gpadmin-[INFO]:-   Failed segment starts                                                = 0
20240511:13:58:08:051573 gpstart:gpserver1:gpadmin-[INFO]:-   Skipped segment starts (segments are marked down in configuration)   = 0
20240511:13:58:08:051573 gpstart:gpserver1:gpadmin-[INFO]:-----------------------------------------------------
20240511:13:58:08:051573 gpstart:gpserver1:gpadmin-[INFO]:-Successfully started 2 of 2 segment instances 
20240511:13:58:08:051573 gpstart:gpserver1:gpadmin-[INFO]:-----------------------------------------------------
20240511:13:58:08:051573 gpstart:gpserver1:gpadmin-[INFO]:-Starting Master instance gpserver1 directory /home/gpadmin/data/master/gpseg-1 
20240511:13:58:08:051573 gpstart:gpserver1:gpadmin-[INFO]:-Command pg_ctl reports Master gpserver1 instance active
20240511:13:58:08:051573 gpstart:gpserver1:gpadmin-[INFO]:-Connecting to dbname='template1' connect_timeout=15
20240511:13:58:08:051573 gpstart:gpserver1:gpadmin-[INFO]:-No standby master configured.  skipping...
20240511:13:58:08:051573 gpstart:gpserver1:gpadmin-[INFO]:-Database successfully started
20240511:13:58:08:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Completed restart of Greenplum instance in production mode
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Scanning utility log file for any warning messages
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[WARN]:-*******************************************************
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[WARN]:-Scan of log file indicates that some warnings or errors
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[WARN]:-were generated during the array creation
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Please review contents of log file
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-/home/gpadmin/gpAdminLogs/gpinitsystem_20240511.log
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-To determine level of criticality
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-These messages could be from a previous run of the utility
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-that was called today!
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[WARN]:-*******************************************************
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Greenplum Database instance successfully created
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-------------------------------------------------------
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-To complete the environment configuration, please 
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-update gpadmin .bashrc file with the following
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-1. Ensure that the greenplum_path.sh file is sourced
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-2. Add "export MASTER_DATA_DIRECTORY=/home/gpadmin/data/master/gpseg-1"
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-   to access the Greenplum scripts for this instance:
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-   or, use -d /home/gpadmin/data/master/gpseg-1 option for the Greenplum scripts
20240511:13:58:09:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-   Example gpstate -d /home/gpadmin/data/master/gpseg-1
20240511:13:58:10:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Script log file = /home/gpadmin/gpAdminLogs/gpinitsystem_20240511.log
20240511:13:58:10:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-To remove instance, run gpdeletesystem utility
20240511:13:58:10:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-To initialize a Standby Master Segment for this Greenplum instance
20240511:13:58:10:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Review options for gpinitstandby
20240511:13:58:10:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-------------------------------------------------------
20240511:13:58:10:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-The Master /home/gpadmin/data/master/gpseg-1/pg_hba.conf post gpinitsystem
20240511:13:58:10:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-has been configured to allow all hosts within this new
20240511:13:58:10:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-array to intercommunicate. Any hosts external to this
20240511:13:58:10:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-new array must be explicitly added to this file
20240511:13:58:10:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-Refer to the Greenplum Admin support guide which is
20240511:13:58:10:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-located in the /usr/local/greenplum-db-6.13.0/docs directory
20240511:13:58:10:049585 gpinitsystem:gpserver1:gpadmin-[INFO]:-------------------------------------------------------

# 验证集群
[gpadmin@gpserver1 gpconfigs]$ psql 
psql: FATAL:  database "gpadmin" does not exist
[gpadmin@gpserver1 gpconfigs]$

# source 环境变量
[gpadmin@gpserver1 ~]$ source .bashrc 
[gpadmin@gpserver1 ~]$ psql
psql (9.4.24)
Type "help" for help.

gp_sydb=# 

OK了，集群安装成功
```

## 一些常见操作

```powershell
# 查看集群状态
[gpadmin@gpserver1 ~]$ gpstate
20240511:14:08:32:052630 gpstate:gpserver1:gpadmin-[INFO]:-Starting gpstate with args: 
20240511:14:08:32:052630 gpstate:gpserver1:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240511:14:08:32:052630 gpstate:gpserver1:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240511:14:08:32:052630 gpstate:gpserver1:gpadmin-[INFO]:-Obtaining Segment details from master...
20240511:14:08:32:052630 gpstate:gpserver1:gpadmin-[INFO]:-Gathering data from segments...
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-Greenplum instance status summary
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-----------------------------------------------------
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Master instance                                = Active
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Master standby                                 = No master standby configured
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Total segment instance count from metadata     = 2
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-----------------------------------------------------
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Primary Segment Status
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-----------------------------------------------------
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Total primary segments                         = 2
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Total primary segment valid (at master)        = 2
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Total primary segment failures (at master)     = 0
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Total number of postmaster.pid files missing   = 0
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Total number of postmaster.pid files found     = 2
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing    = 0
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found      = 2
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Total number of /tmp lock files missing        = 0
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Total number of /tmp lock files found          = 2
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Total number postmaster processes missing      = 0
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Total number postmaster processes found        = 2
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-----------------------------------------------------
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Mirror Segment Status
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-----------------------------------------------------
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-   Mirrors not configured on this array
20240511:14:08:33:052630 gpstate:gpserver1:gpadmin-[INFO]:-----------------------------------------------------
[gpadmin@gpserver1 ~]$ 

# 停止集群
[gpadmin@gpserver1 ~]$ gpstop
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-Starting gpstop with args: 
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-Gathering information and validating the environment...
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-Obtaining Greenplum Master catalog information
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-Obtaining Segment details from master...
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:---------------------------------------------
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-Master instance parameters
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:---------------------------------------------
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-   Master Greenplum instance process active PID   = 51621
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-   Database                                       = template1
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-   Master port                                    = 5432
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-   Master directory                               = /home/gpadmin/data/master/gpseg-1
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-   Shutdown mode                                  = smart
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-   Timeout                                        = 120
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-   Shutdown Master standby host                   = Off
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:---------------------------------------------
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-Segment instances that will be shutdown:
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:---------------------------------------------
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-   Host        Datadir                             Port   Status
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-   gpserver2   /home/gpadmin/data/primary/gpseg0   6000   u
20240511:14:09:28:052747 gpstop:gpserver1:gpadmin-[INFO]:-   gpserver2   /home/gpadmin/data/primary/gpseg1   6001   u

Continue with Greenplum instance shutdown Yy|Nn (default=N):
> y
20240511:14:09:29:052747 gpstop:gpserver1:gpadmin-[INFO]:-Commencing Master instance shutdown with mode='smart'
20240511:14:09:29:052747 gpstop:gpserver1:gpadmin-[INFO]:-Master segment instance directory=/home/gpadmin/data/master/gpseg-1
20240511:14:09:29:052747 gpstop:gpserver1:gpadmin-[INFO]:-Stopping master segment and waiting for user connections to finish ...
server shutting down
20240511:14:09:30:052747 gpstop:gpserver1:gpadmin-[INFO]:-Attempting forceful termination of any leftover master process
20240511:14:09:30:052747 gpstop:gpserver1:gpadmin-[INFO]:-Terminating processes for segment /home/gpadmin/data/master/gpseg-1
20240511:14:09:30:052747 gpstop:gpserver1:gpadmin-[INFO]:-No standby master host configured
20240511:14:09:30:052747 gpstop:gpserver1:gpadmin-[INFO]:-Targeting dbid [2, 3] for shutdown
20240511:14:09:30:052747 gpstop:gpserver1:gpadmin-[INFO]:-Commencing parallel segment instance shutdown, please wait...
20240511:14:09:30:052747 gpstop:gpserver1:gpadmin-[INFO]:-0.00% of jobs completed
20240511:14:09:31:052747 gpstop:gpserver1:gpadmin-[INFO]:-100.00% of jobs completed
20240511:14:09:31:052747 gpstop:gpserver1:gpadmin-[INFO]:-----------------------------------------------------
20240511:14:09:31:052747 gpstop:gpserver1:gpadmin-[INFO]:-   Segments stopped successfully      = 2
20240511:14:09:31:052747 gpstop:gpserver1:gpadmin-[INFO]:-   Segments with errors during stop   = 0
20240511:14:09:31:052747 gpstop:gpserver1:gpadmin-[INFO]:-----------------------------------------------------
20240511:14:09:31:052747 gpstop:gpserver1:gpadmin-[INFO]:-Successfully shutdown 2 of 2 segment instances 
20240511:14:09:31:052747 gpstop:gpserver1:gpadmin-[INFO]:-Database successfully shutdown with no errors reported
20240511:14:09:31:052747 gpstop:gpserver1:gpadmin-[INFO]:-Cleaning up leftover gpmmon process
20240511:14:09:31:052747 gpstop:gpserver1:gpadmin-[INFO]:-No leftover gpmmon process found
20240511:14:09:31:052747 gpstop:gpserver1:gpadmin-[INFO]:-Cleaning up leftover gpsmon processes
20240511:14:09:31:052747 gpstop:gpserver1:gpadmin-[INFO]:-No leftover gpsmon processes on some hosts. not attempting forceful termination on these hosts
20240511:14:09:31:052747 gpstop:gpserver1:gpadmin-[INFO]:-Cleaning up leftover shared memory
[gpadmin@gpserver1 ~]$ 

# 启动集群
[gpadmin@gpserver1 ~]$ gpstart
20240511:14:09:50:052883 gpstart:gpserver1:gpadmin-[INFO]:-Starting gpstart with args: 
20240511:14:09:50:052883 gpstart:gpserver1:gpadmin-[INFO]:-Gathering information and validating the environment...
20240511:14:09:50:052883 gpstart:gpserver1:gpadmin-[INFO]:-Greenplum Binary Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240511:14:09:50:052883 gpstart:gpserver1:gpadmin-[INFO]:-Greenplum Catalog Version: '301908232'
20240511:14:09:50:052883 gpstart:gpserver1:gpadmin-[INFO]:-Starting Master instance in admin mode
20240511:14:09:50:052883 gpstart:gpserver1:gpadmin-[INFO]:-Obtaining Greenplum Master catalog information
20240511:14:09:50:052883 gpstart:gpserver1:gpadmin-[INFO]:-Obtaining Segment details from master...
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:-Setting new master era
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:-Master Started...
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:-Shutting down master
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:---------------------------
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:-Master instance parameters
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:---------------------------
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:-Database                 = template1
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:-Master Port              = 5432
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:-Master directory         = /home/gpadmin/data/master/gpseg-1
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:-Timeout                  = 600 seconds
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:-Master standby           = Off 
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:---------------------------------------
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:-Segment instances that will be started
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:---------------------------------------
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:-   Host        Datadir                             Port
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:-   gpserver2   /home/gpadmin/data/primary/gpseg0   6000
20240511:14:09:51:052883 gpstart:gpserver1:gpadmin-[INFO]:-   gpserver2   /home/gpadmin/data/primary/gpseg1   6001

Continue with Greenplum instance startup Yy|Nn (default=N):
> y
20240511:14:09:53:052883 gpstart:gpserver1:gpadmin-[INFO]:-Commencing parallel segment instance startup, please wait...
20240511:14:09:54:052883 gpstart:gpserver1:gpadmin-[INFO]:-Process results...
20240511:14:09:54:052883 gpstart:gpserver1:gpadmin-[INFO]:-----------------------------------------------------
20240511:14:09:54:052883 gpstart:gpserver1:gpadmin-[INFO]:-   Successful segment starts                                            = 2
20240511:14:09:54:052883 gpstart:gpserver1:gpadmin-[INFO]:-   Failed segment starts                                                = 0
20240511:14:09:54:052883 gpstart:gpserver1:gpadmin-[INFO]:-   Skipped segment starts (segments are marked down in configuration)   = 0
20240511:14:09:54:052883 gpstart:gpserver1:gpadmin-[INFO]:-----------------------------------------------------
20240511:14:09:54:052883 gpstart:gpserver1:gpadmin-[INFO]:-Successfully started 2 of 2 segment instances 
20240511:14:09:54:052883 gpstart:gpserver1:gpadmin-[INFO]:-----------------------------------------------------
20240511:14:09:54:052883 gpstart:gpserver1:gpadmin-[INFO]:-Starting Master instance gpserver1 directory /home/gpadmin/data/master/gpseg-1 
20240511:14:09:54:052883 gpstart:gpserver1:gpadmin-[INFO]:-Command pg_ctl reports Master gpserver1 instance active
20240511:14:09:54:052883 gpstart:gpserver1:gpadmin-[INFO]:-Connecting to dbname='template1' connect_timeout=15
20240511:14:09:54:052883 gpstart:gpserver1:gpadmin-[INFO]:-No standby master configured.  skipping...
20240511:14:09:54:052883 gpstart:gpserver1:gpadmin-[INFO]:-Database successfully started
[gpadmin@gpserver1 ~]$ 

# 设置远程连接重载配置文件
[gpadmin@gpserver1 ~]$ echo "host all gpadmin 0.0.0.0/0 trust" >> /home/gpadmin/data/master/gpseg-1/pg_hba.conf 
[gpadmin@gpserver1 ~]$ gpstop -u
20240511:14:18:20:053354 gpstop:gpserver1:gpadmin-[INFO]:-Starting gpstop with args: -u
20240511:14:18:20:053354 gpstop:gpserver1:gpadmin-[INFO]:-Gathering information and validating the environment...
20240511:14:18:20:053354 gpstop:gpserver1:gpadmin-[INFO]:-Obtaining Greenplum Master catalog information
20240511:14:18:20:053354 gpstop:gpserver1:gpadmin-[INFO]:-Obtaining Segment details from master...
20240511:14:18:21:053354 gpstop:gpserver1:gpadmin-[INFO]:-Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240511:14:18:21:053354 gpstop:gpserver1:gpadmin-[INFO]:-Signalling all postmaster processes to reload
[gpadmin@gpserver1 ~]$ 
```

