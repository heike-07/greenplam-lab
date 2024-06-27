# GreenPlum集群实验室-4

> Author ：Heike07

[TOC]

## 实验四：新增2个Segment物理Node节点并建立与其他Segment_instance相同的primary与mirror实例

### 创建虚拟机VM

通过Laboratory PXE宿主机，生出2个虚拟机，命名为Segment-c、Segment-d

### 主机规划

| 主机名    | IP地址        | 节点描述     |
| --------- | ------------- | ------------ |
| Mastar-a  | 192.168.7.136 | MASTER节点   |
| Standby-a | 192.168.7.137 | STANDBY节点  |
| Segment-a | 192.168.7.138 | SEGMENT节点1 |
| Segment-b | 192.168.7.139 | SEGMENT节点2 |
| Segment-c | 192.168.7.141 | SEGMENT节点3 |
| Segment-d | 192.168.7.140 | SEGMENT节点4 |

### 初始化SengmentCandD

#### SELINUX

selinux 修改为 disabled

#### 修改主机名

使用nmtui调整主机名后重新登陆

#### 调整网络模拟内网环境

网络调整为自动获取DHCP并模拟断网情况

```powershell
Last login: Fri Jun 14 18:12:55 2024
[root@localhost ~]# nmtui
[root@localhost ~]# exit
logout
SSH connection has been disconnected. 
Wait for 3 second to Reconnecting...
Last login: Fri Jun 14 18:17:20 2024 from 192.168.7.99
[root@Segment-c ~]# 
[root@Segment-c ~]# nmcli connection show
NAME                UUID                                  TYPE      DEVICE 
Wired connection 1  218bc651-24b6-3133-849b-36cc6b2fc5b1  ethernet  ens36  
System ens33        6f53f999-8d62-4716-93fc-b2a34371a79e  ethernet  --     
[root@Segment-c ~]# ping www.baidu.com
^C
[root@Segment-c ~]# nmcli connection up 6f53f999-8d62-4716-93fc-b2a34371a79e
Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/2)
[root@Segment-c ~]# nmcli connection show
NAME                UUID                                  TYPE      DEVICE 
System ens33        6f53f999-8d62-4716-93fc-b2a34371a79e  ethernet  ens33  
Wired connection 1  218bc651-24b6-3133-849b-36cc6b2fc5b1  ethernet  ens36  
[root@Segment-c ~]# ping www.baidu.com
PING www.a.shifen.com (39.156.66.18) 56(84) bytes of data.
64 bytes from 39.156.66.18 (39.156.66.18): icmp_seq=1 ttl=128 time=24.8 ms
64 bytes from 39.156.66.18 (39.156.66.18): icmp_seq=2 ttl=128 time=25.1 ms
^C
--- www.a.shifen.com ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 24.895/24.999/25.103/0.104 ms
[root@Segment-c ~]# nmcli connection down 6f53f999-8d62-4716-93fc-b2a34371a79e
Connection 'System ens33' successfully deactivated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/2)
[root@Segment-c ~]# ping www.baidu.com
^C
[root@Segment-c ~]# nmcli connection show
NAME                UUID                                  TYPE      DEVICE 
Wired connection 1  218bc651-24b6-3133-849b-36cc6b2fc5b1  ethernet  ens36  
System ens33        6f53f999-8d62-4716-93fc-b2a34371a79e  ethernet  --     
[root@Segment-c ~]#


[root@localhost ~]# nmtui
[root@localhost ~]# exit
logout
SSH connection has been disconnected. 
Wait for 3 second to Reconnecting...
Last login: Fri Jun 14 18:17:02 2024 from 192.168.7.99
[root@Segment-d ~]# nmcli connection show
NAME                UUID                                  TYPE      DEVICE 
Wired connection 1  9e51d6c6-873d-3f9d-a219-250702c1dda7  ethernet  ens36  
System ens33        1947a30a-4b91-4a41-90d7-dbb0c87a479f  ethernet  --     
[root@Segment-d ~]# ping www.baidu.com
^C
[root@Segment-d ~]# nmcli connection up 1947a30a-4b91-4a41-90d7-dbb0c87a479f
Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/2)
[root@Segment-d ~]# ping www.baidu.com
PING www.a.shifen.com (39.156.66.14) 56(84) bytes of data.
64 bytes from 39.156.66.14 (39.156.66.14): icmp_seq=1 ttl=128 time=23.1 ms
^C
--- www.a.shifen.com ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 23.119/23.119/23.119/0.000 ms
[root@Segment-d ~]# nmcli connection show
NAME                UUID                                  TYPE      DEVICE 
System ens33        1947a30a-4b91-4a41-90d7-dbb0c87a479f  ethernet  ens33  
Wired connection 1  9e51d6c6-873d-3f9d-a219-250702c1dda7  ethernet  ens36  
[root@Segment-d ~]# nmcli connection down 1947a30a-4b91-4a41-90d7-dbb0c87a479f
Connection 'System ens33' successfully deactivated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/2)
[root@Segment-d ~]# ping www.baidu.com
^C
[root@Segment-d ~]# nmcli connection show
NAME                UUID                                  TYPE      DEVICE 
Wired connection 1  9e51d6c6-873d-3f9d-a219-250702c1dda7  ethernet  ens36  
System ens33        1947a30a-4b91-4a41-90d7-dbb0c87a479f  ethernet  --     
[root@Segment-d ~]#
```

#### 修改hosts文件

```powershell
# 在Standby-a 节点上新增hosts文件
[root@Standby-a ~]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.7.136  Master-a
192.168.7.137  Standby-a
192.168.7.138  Segment-a
192.168.7.139  Segment-b
[root@Standby-a ~]# cat << EOF >> /etc/hosts
> 192.168.7.141  Segment-c
> 192.168.7.140  Segment-d
> EOF
[root@Standby-a ~]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.7.136  Master-a
192.168.7.137  Standby-a
192.168.7.138  Segment-a
192.168.7.139  Segment-b
192.168.7.141  Segment-c
192.168.7.140  Segment-d
[root@Standby-a ~]#

# 复制到其他节点
[root@Standby-a ~]# scp /etc/hosts Master-a:/etc/hosts
root@master-a's password:       
hosts                                                                                                                          100%  307   493.8KB/s   00:00    
[root@Standby-a ~]# scp /etc/hosts Segment-a:/etc/hosts
root@segment-a's password:       
hosts                                                                                                                          100%  307   305.4KB/s   00:00    
[root@Standby-a ~]# scp /etc/hosts Segment-b:/etc/hosts
root@segment-b's password:       
hosts                                                                                                                          100%  307   320.8KB/s   00:00    
[root@Standby-a ~]# scp /etc/hosts Segment-c:/etc/hosts
The authenticity of host 'segment-c (192.168.7.141)' can't be established.
ECDSA key fingerprint is SHA256:GLOzhVa4h3m9pvgy7RlImPqrJsKQqu6MK0fVM4Mt/OE.
ECDSA key fingerprint is MD5:e7:7e:03:19:6e:1b:61:a9:41:11:a1:e2:d7:4e:e8:72.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'segment-c,192.168.7.141' (ECDSA) to the list of known hosts.
root@segment-c's password:       
hosts                                                                                                                          100%  307   869.7KB/s   00:00    
[root@Standby-a ~]# scp /etc/hosts Segment-d:/etc/hosts
The authenticity of host 'segment-d (192.168.7.140)' can't be established.
ECDSA key fingerprint is SHA256:I1f3uAfaIdL9/v9+FfzOQhluYIWG1sHOf+BP4euLdPg.
ECDSA key fingerprint is MD5:10:a4:29:ab:1e:97:35:67:ff:ad:3f:8a:d9:e2:be:a2.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'segment-d,192.168.7.140' (ECDSA) to the list of known hosts.
root@segment-d's password:       
hosts                                                                                                                          100%  307   661.6KB/s   00:00    
[root@Standby-a ~]#
```

#### 关联本地YUM源

```powershell
# 新增segment节点注释原有yum源
[root@Standby-a ~]# ssh Segment-c "cd /etc/yum.repos.d ; rename repo repotmp * ; ls"
root@segment-c's password:       
CentOS-Base.repotmp
CentOS-CR.repotmp
CentOS-Debuginfo.repotmp
CentOS-fasttrack.repotmp
CentOS-Media.repotmp
CentOS-Sources.repotmp
CentOS-Vault.repotmp
CentOS-x86_64-kernel.repotmp
[root@Standby-a ~]# ssh Segment-d "cd /etc/yum.repos.d ; rename repo repotmp * ; ls"
root@segment-d's password:       
CentOS-Base.repotmp
CentOS-CR.repotmp
CentOS-Debuginfo.repotmp
CentOS-fasttrack.repotmp
CentOS-Media.repotmp
CentOS-Sources.repotmp
CentOS-Vault.repotmp
CentOS-x86_64-kernel.repotmp
[root@Standby-a ~]#

# 复制本地yum源文件并执行构建
[root@Standby-a ~]# scp /etc/yum.repos.d/localhttp.repo Segment-c:/etc/yum.repos.d/localhttp.repo
root@segment-c's password:      
Permission denied, please try again.
root@segment-c's password:       
localhttp.repo                                                                                                                 100%   90   135.8KB/s   00:00    
[root@Standby-a ~]# scp /etc/yum.repos.d/localhttp.repo Segment-d:/etc/yum.repos.d/localhttp.repo
root@segment-d's password:       
localhttp.repo                                                                                                                 100%   90   137.8KB/s   00:00    
[root@Standby-a ~]# ssh Segment-c "yum clean all ; yum makecache"
root@segment-c's password:       
Loaded plugins: fastestmirror
Cleaning repos: localhttp
Loaded plugins: fastestmirror
Determining fastest mirrors
Metadata Cache Created
[root@Standby-a ~]# ssh Segment-d "yum clean all ; yum makecache"
root@segment-d's password:       
Loaded plugins: fastestmirror
Cleaning repos: localhttp
Loaded plugins: fastestmirror
Determining fastest mirrors
Metadata Cache Created
[root@Standby-a ~]#
```

#### 关闭防火墙（实验环境）

```powershell
# 关闭两个新增节点的防火墙
[root@Standby-a ~]# ssh Segment-c "systemctl stop firewalld ; systemctl disabled firewalld ; systemctl status firewalld"
root@segment-c's password:       
Unknown operation 'disabled'.
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: inactive (dead) since Fri 2024-06-14 18:49:49 CST; 6ms ago
     Docs: man:firewalld(1)
  Process: 724 ExecStart=/usr/sbin/firewalld --nofork --nopid $FIREWALLD_ARGS (code=exited, status=0/SUCCESS)
 Main PID: 724 (code=exited, status=0/SUCCESS)

Jun 14 18:12:29 localhost.localdomain systemd[1]: Starting firewalld - dynamic firewall daemon...
Jun 14 18:12:29 localhost.localdomain systemd[1]: Started firewalld - dynamic firewall daemon.
Jun 14 18:49:48 Segment-c systemd[1]: Stopping firewalld - dynamic firewall daemon...
Jun 14 18:49:49 Segment-c systemd[1]: Stopped firewalld - dynamic firewall daemon.
[root@Standby-a ~]# ssh Segment-d "systemctl stop firewalld ; systemctl disabled firewalld ; systemctl status firewalld"
root@segment-d's password:       
Unknown operation 'disabled'.
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: inactive (dead) since Fri 2024-06-14 10:50:07 CST; 5ms ago
     Docs: man:firewalld(1)
  Process: 714 ExecStart=/usr/sbin/firewalld --nofork --nopid $FIREWALLD_ARGS (code=exited, status=0/SUCCESS)
 Main PID: 714 (code=exited, status=0/SUCCESS)

Jun 14 18:12:16 localhost.localdomain systemd[1]: Starting firewalld - dynamic firewall daemon...
Jun 14 18:12:17 localhost.localdomain systemd[1]: Started firewalld - dynamic firewall daemon.
Jun 14 10:50:06 Segment-d systemd[1]: Stopping firewalld - dynamic firewall daemon...
Jun 14 10:50:07 Segment-d systemd[1]: Stopped firewalld - dynamic firewall daemon.
[root@Standby-a ~]#
```

#### 取消SSHD-DNS缓存加速连接

```powershell
# 设置standby节点取消sshd-DNS缓存
[root@Standby-a ~]# sed -i "s/#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config 
[root@Standby-a ~]# cat /etc/ssh/sshd_config | grep DNS
UseDNS no
[root@Standby-a ~]# systemctl restart sshd

# 复刻其他2个SegmentCandD节点
[root@Standby-a ~]# ssh Segment-c "sed -i "s/#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config ; cat /etc/ssh/sshd_config | grep DNS ; systemctl restart sshd" 
root@segment-c's password:       
sed: -e expression #1, char 9: unterminated `s' command
#UseDNS yes
[root@Standby-a ~]# ssh Segment-c "sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config ; cat /etc/ssh/sshd_config | grep DNS ; systemctl restart sshd" 
root@segment-c's password:       
Permission denied, please try again.
root@segment-c's password:       
UseDNS no
[root@Standby-a ~]# ssh Segment-d "sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config ; cat /etc/ssh/sshd_config | grep DNS ; systemctl restart sshd" 
root@segment-d's password:       
UseDNS no
[root@Standby-a ~]#

# 测试连接速度
重新连接测试速度
```

### 数据库安装前准备工作

参考实验一思路 简略处理

#### 底层依赖安装

```powershell
# yum 依赖进行安装
[root@Segment-c ~]# yum install vim net-tools psmisc nc rsync lrzsz ntp libzstd openssl-static tree iotop git

[root@Segment-c ~]# yum install apr apr-util bash bzip2 curl krb5 libcurl libevent libxml2 libyaml zlib openldap openssh-client openssl openssl-libs perl readline rsync R sed tar zip krb5-devel

[root@Segment-d ~]# yum install vim net-tools psmisc nc rsync lrzsz ntp libzstd openssl-static tree iotop git

[root@Segment-d ~]# yum install apr apr-util bash bzip2 curl krb5 libcurl libevent libxml2 libyaml zlib openldap openssh-client openssl openssl-libs perl readline rsync R sed tar zip krb5-devel
```

#### 同步系统参数配置文件

```powershell
# 从master 同步至segment c and d
[root@Master-a ~]# scp /etc/sysctl.conf Segment-c:/etc/sysctl.conf
The authenticity of host 'segment-c (192.168.7.141)' can't be established.
ECDSA key fingerprint is SHA256:GLOzhVa4h3m9pvgy7RlImPqrJsKQqu6MK0fVM4Mt/OE.
ECDSA key fingerprint is MD5:e7:7e:03:19:6e:1b:61:a9:41:11:a1:e2:d7:4e:e8:72.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'segment-c,192.168.7.141' (ECDSA) to the list of known hosts.
root@segment-c's password:       
sysctl.conf                                                                                                                    100% 1151     2.4MB/s   00:00    
[root@Master-a ~]# scp /etc/security/limits.conf Segment-c:/etc/security/limits.conf
root@segment-c's password:     
limits.conf                                                                                                                    100% 2555     5.9MB/s   00:00    
[root@Master-a ~]# scp /etc/security/limits.d/20-nproc.conf Segment-c:/etc/security/limits.d/20-nproc.conf
root@segment-c's password:       
20-nproc.conf                                                                                                                  100%  324   756.4KB/s   00:00    
[root@Master-a ~]# scp /etc/sysctl.conf Segment-d:/etc/sysctl.conf
The authenticity of host 'segment-d (192.168.7.140)' can't be established.
ECDSA key fingerprint is SHA256:I1f3uAfaIdL9/v9+FfzOQhluYIWG1sHOf+BP4euLdPg.
ECDSA key fingerprint is MD5:10:a4:29:ab:1e:97:35:67:ff:ad:3f:8a:d9:e2:be:a2.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'segment-d,192.168.7.140' (ECDSA) to the list of known hosts.
root@segment-d's password:       
sysctl.conf                                                                                                                    100% 1151     2.0MB/s   00:00    
[root@Master-a ~]# scp /etc/security/limits.conf Segment-d:/etc/security/limits.conf
root@segment-d's password:       
limits.conf                                                                                                                    100% 2555     5.0MB/s   00:00    
[root@Master-a ~]# scp /etc/security/limits.d/20-nproc.conf Segment-d:/etc/security/limits.d/20-nproc.conf
root@segment-d's password:       
20-nproc.conf                                                                                                                  100%  324   698.8KB/s   00:00    
[root@Master-a ~]#
```

#### 同步时间

```powershell
# 同步时间后模拟断网
[root@Segment-c ~]# nmcli connection show
NAME                UUID                                  TYPE      DEVICE 
Wired connection 1  218bc651-24b6-3133-849b-36cc6b2fc5b1  ethernet  ens36  
System ens33        6f53f999-8d62-4716-93fc-b2a34371a79e  ethernet  --     
[root@Segment-c ~]# nmcli connection up 6f53f999-8d62-4716-93fc-b2a34371a79e
Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/3)
[root@Segment-c ~]# ping www.baidu.com
PING www.a.shifen.com (39.156.66.18) 56(84) bytes of data.
64 bytes from 39.156.66.18 (39.156.66.18): icmp_seq=1 ttl=128 time=24.8 ms
64 bytes from 39.156.66.18 (39.156.66.18): icmp_seq=2 ttl=128 time=24.6 ms
^C
--- www.a.shifen.com ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 24.661/24.767/24.874/0.190 ms
[root@Segment-c ~]# ntpdate cn.pool.ntp.org
14 Jun 11:40:41 ntpdate[2138]: adjust time server 139.199.215.251 offset 0.019672 sec
[root@Segment-c ~]# date
Fri Jun 14 11:40:45 CST 2024
[root@Segment-c ~]# date
Fri Jun 14 11:40:59 CST 2024
[root@Segment-c ~]# nmcli connection down 6f53f999-8d62-4716-93fc-b2a34371a79e
Connection 'System ens33' successfully deactivated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/3)
[root@Segment-c ~]#


[root@Segment-d ~]# nmcli connection show
NAME                UUID                                  TYPE      DEVICE 
Wired connection 1  9e51d6c6-873d-3f9d-a219-250702c1dda7  ethernet  ens36  
System ens33        1947a30a-4b91-4a41-90d7-dbb0c87a479f  ethernet  --     
[root@Segment-d ~]# nmcli connection up
Error: neither a valid connection nor device given.
[root@Segment-d ~]# nmcli connection up 1947a30a-4b91-4a41-90d7-dbb0c87a479f
Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/3)
[root@Segment-d ~]# ntpdate cn.pool.ntp.org
14 Jun 11:47:20 ntpdate[2121]: adjust time server 202.112.29.82 offset 0.099432 sec
[root@Segment-d ~]# nmcli connection down 1947a30a-4b91-4a41-90d7-dbb0c87a479f
Connection 'System ens33' successfully deactivated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/3)
[root@Segment-d ~]#
```

### 数据库安装前设置

#### 设置gpadmin用户密码以及免密登陆

```powershell
# 设置Segment-a gpadmin账户以及免密
Last login: Thu Jun 20 09:35:47 2024 from 192.168.7.99
[root@Segment-c ~]# 
[root@Segment-c ~]# groupadd gpadmin
[root@Segment-c ~]# useradd gpadmin -r -m -g gpadmin
[root@Segment-c ~]# id gpadmin
uid=997(gpadmin) gid=1000(gpadmin) groups=1000(gpadmin)
[root@Segment-c ~]# passwd gpadmin
Changing password for user gpadmin.
New password:        
BAD PASSWORD: The password is shorter than 8 characters
Retype new password:        
passwd: all authentication tokens updated successfully.
[root@Segment-c ~]# su - gpadmin
[gpadmin@Segment-c ~]$ ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/home/gpadmin/.ssh/id_rsa): 
Created directory '/home/gpadmin/.ssh'.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/gpadmin/.ssh/id_rsa.
Your public key has been saved in /home/gpadmin/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:5NNThbhbPCGxDIS2x/98BwNUGaTBu+xoratKrv6hmo8 gpadmin@Segment-c
The key's randomart image is:
+---[RSA 2048]----+
|       oo .+.+=o |
|      o  oo.=+.  |
|     . o. o=oo   |
|      .oo...*    |
|       .S.o+ +   |
|         .o.o o  |
|      o    *   o |
|   o + .  o = . .|
|  E+=o+..ooo . . |
+----[SHA256]-----+
[gpadmin@Segment-c ~]$ ssh-copy-id Master-a
/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/gpadmin/.ssh/id_rsa.pub"
The authenticity of host 'master-a (192.168.7.136)' can't be established.
ECDSA key fingerprint is SHA256:ICELL8DOaZ7rN9rWXoqyfr5pz+bw523/FwwHjsi66QM.
ECDSA key fingerprint is MD5:06:6a:e0:62:f0:df:8a:be:2a:3e:95:51:05:f5:bd:da.
Are you sure you want to continue connecting (yes/no)? yes
/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
gpadmin@master-a's password:        

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'Master-a'"
and check to make sure that only the key(s) you wanted were added.

[gpadmin@Segment-c ~]$ ssh-copy-id Segment-a
/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/gpadmin/.ssh/id_rsa.pub"
The authenticity of host 'segment-a (192.168.7.138)' can't be established.
ECDSA key fingerprint is SHA256:sTgeZrp9dUXMX/wO2qbJKvFurTOqBSbqOWYsoMK2Z1s.
ECDSA key fingerprint is MD5:06:b9:1a:65:b3:12:d8:be:f2:e6:f1:5c:e0:9e:2b:6c.
Are you sure you want to continue connecting (yes/no)? yes
/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
gpadmin@segment-a's password:        

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'Segment-a'"
and check to make sure that only the key(s) you wanted were added.

[gpadmin@Segment-c ~]$ ssh-copy-id Segment-b
/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/gpadmin/.ssh/id_rsa.pub"
The authenticity of host 'segment-b (192.168.7.139)' can't be established.
ECDSA key fingerprint is SHA256:UNVqysnB3DIdtF5W35IlvIHRN6ZpVB61fu5HjWP/HbM.
ECDSA key fingerprint is MD5:ba:14:8a:f9:36:bc:24:4b:7b:81:51:1a:73:8d:52:d8.
Are you sure you want to continue connecting (yes/no)? yes
/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
gpadmin@segment-b's password:        

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'Segment-b'"
and check to make sure that only the key(s) you wanted were added.

[gpadmin@Segment-c ~]$ ssh-copy-id Segment-c
/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/gpadmin/.ssh/id_rsa.pub"
The authenticity of host 'segment-c (192.168.7.141)' can't be established.
ECDSA key fingerprint is SHA256:GLOzhVa4h3m9pvgy7RlImPqrJsKQqu6MK0fVM4Mt/OE.
ECDSA key fingerprint is MD5:e7:7e:03:19:6e:1b:61:a9:41:11:a1:e2:d7:4e:e8:72.
Are you sure you want to continue connecting (yes/no)? yes
/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
gpadmin@segment-c's password:        

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'Segment-c'"
and check to make sure that only the key(s) you wanted were added.

[gpadmin@Segment-c ~]$ ssh-copy-id Segment-d
/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/gpadmin/.ssh/id_rsa.pub"
The authenticity of host 'segment-d (192.168.7.140)' can't be established.
ECDSA key fingerprint is SHA256:I1f3uAfaIdL9/v9+FfzOQhluYIWG1sHOf+BP4euLdPg.
ECDSA key fingerprint is MD5:10:a4:29:ab:1e:97:35:67:ff:ad:3f:8a:d9:e2:be:a2.
Are you sure you want to continue connecting (yes/no)? yes
/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
gpadmin@segment-d's password:        
Permission denied, please try again.
gpadmin@segment-d's password:        
Permission denied, please try again.
gpadmin@segment-d's password: 
Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password).
[gpadmin@Segment-c ~]$ ssh-copy-id Segment-d
/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/gpadmin/.ssh/id_rsa.pub"
/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
gpadmin@segment-d's password:        

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'Segment-d'"
and check to make sure that only the key(s) you wanted were added.

[gpadmin@Segment-c ~]$

# Segment-d 同理设置即可
略
```

### 数据库安装

```powershell
[gpadmin@Master-a conf]$ cd /home/gpadmin/soft/
[gpadmin@Master-a soft]$ ls
greenplum-db-6.13.0-rhel7-x86_64.rpm
[gpadmin@Master-a soft]$ ssh Segment-c "cd /home/gpadmin ; mkdir soft ; cd soft ; pwd"
/home/gpadmin/soft
[gpadmin@Master-a soft]$ ssh Segment-d "cd /home/gpadmin ; mkdir soft ; cd soft ; pwd"
/home/gpadmin/soft
[gpadmin@Master-a soft]$ scp greenplum-db-6.13.0-rhel7-x86_64.rpm Segment-c:/home/gpadmin/soft
greenplum-db-6.13.0-rhel7-x86_64.rpm                                                                                                                                   100%   66MB 112.2MB/s   00:00    
[gpadmin@Master-a soft]$ scp greenplum-db-6.13.0-rhel7-x86_64.rpm Segment-d:/home/gpadmin/soft
greenplum-db-6.13.0-rhel7-x86_64.rpm                                                                                                                                   100%   66MB 131.6MB/s   00:00    
[gpadmin@Master-a soft]$ ssh Segment-c "cd /home/gpadmin/soft ; ls -l "
total 67712
-rw-r--r-- 1 gpadmin gpadmin 69333396 Jun 20 13:27 greenplum-db-6.13.0-rhel7-x86_64.rpm
[gpadmin@Master-a soft]$ ssh Segment-d "cd /home/gpadmin/soft ; ls -l "
total 67712
-rw-r--r-- 1 gpadmin gpadmin 69333396 Jun 20 13:27 greenplum-db-6.13.0-rhel7-x86_64.rpm
[gpadmin@Master-a soft]$

[root@Segment-c local]# cd /home/gpadmin/soft/
[root@Segment-c soft]# yum install ./greenplum-db-6.13.0-rhel7-x86_64.rpm 
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
[root@Segment-c soft]#

[root@Segment-c soft]# cd /usr/local/
[root@Segment-c local]# ll
total 0
drwxr-xr-x.  2 root root   6 Apr 11  2018 bin
drwxr-xr-x.  2 root root   6 Apr 11  2018 etc
drwxr-xr-x.  2 root root   6 Apr 11  2018 games
lrwxrwxrwx   1 root root  30 Jun 20 13:29 greenplum-db -> /usr/local/greenplum-db-6.13.0
drwxr-xr-x  11 root root 238 Jun 20 13:29 greenplum-db-6.13.0
drwxr-xr-x.  2 root root   6 Apr 11  2018 include
drwxr-xr-x.  2 root root   6 Apr 11  2018 lib
drwxr-xr-x.  2 root root   6 Apr 11  2018 lib64
drwxr-xr-x.  2 root root   6 Apr 11  2018 libexec
drwxr-xr-x.  2 root root   6 Apr 11  2018 sbin
drwxr-xr-x.  5 root root  49 Jun 13 23:25 share
drwxr-xr-x.  2 root root   6 Apr 11  2018 src
[root@Segment-c local]# chown -R gpadmin.gpadmin greenplum-db*
[root@Segment-c local]#
```



### 原节点做CD的免密登陆

##### 解决Master无法找到密钥文件

```powershell
# 问题
[gpadmin@Master-a conf]$ gpssh-exkeys -f expand_seg_hosts 
[ERROR]: Failed to ssh to Segment-c. No ECDSA host key is known for segment-c and you have requested strict checking.
Host key verification failed.

[ERROR]: Expected passwordless ssh to host Segment-c

[gpadmin@Master-a conf]$ ssh-copy-id Segment-c

/usr/bin/ssh-copy-id: ERROR: failed to open ID file '/home/gpadmin/.ssh/iddummy': No such file or directory
        (to install the contents of '/home/gpadmin/.ssh/iddummy.pub' anyway, look at the -f option)
[gpadmin@Master-a conf]$ ssh-copy-id Segment-d

/usr/bin/ssh-copy-id: ERROR: failed to open ID file '/home/gpadmin/.ssh/iddummy': No such file or directory
        (to install the contents of '/home/gpadmin/.ssh/iddummy.pub' anyway, look at the -f option)

# 解决方法
[gpadmin@Master-a .ssh]$ ll
total 16
-rw------- 1 gpadmin gpadmin 1994 Jun 20 10:30 authorized_keys
-rw-r--r-- 1 gpadmin gpadmin    0 Jun  6 15:17 config
-rw-r--r-- 1 gpadmin gpadmin    0 Jun  6 15:17 iddummy.pub
-rw------- 1 gpadmin gpadmin 1679 Jun  6 14:50 id_rsa
-rw-r--r-- 1 gpadmin gpadmin  398 Jun  6 14:50 id_rsa.pub
-rw-r--r-- 1 gpadmin gpadmin 2096 Jun 20 10:54 known_hosts
[gpadmin@Master-a .ssh]$ rm config iddummy.pub 
[gpadmin@Master-a .ssh]$ ssh-copy-id Segment-c
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/gpadmin/.ssh/id_rsa.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
gpadmin@segment-c's password: 
Permission denied, please try again.
gpadmin@segment-c's password:        

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'Segment-c'"
and check to make sure that only the key(s) you wanted were added.

[gpadmin@Master-a .ssh]$ ssh-copy-id Segment-d
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/gpadmin/.ssh/id_rsa.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
gpadmin@segment-d's password:        

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'Segment-d'"
and check to make sure that only the key(s) you wanted were added.

[gpadmin@Master-a .ssh]$

问题产生的原因是顺序问题，因为没有做ssh-copy 所以产生了错误的密钥文件，删除对应错误密钥文件O字节即可。
```

##### 其他节点做免密登陆

```powershell
# Segment-a Segment-b
[gpadmin@Segment-b .ssh]$ ssh-copy-id Segment-c
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/gpadmin/.ssh/id_rsa.pub"
The authenticity of host 'segment-c (192.168.7.141)' can't be established.
ECDSA key fingerprint is SHA256:GLOzhVa4h3m9pvgy7RlImPqrJsKQqu6MK0fVM4Mt/OE.
ECDSA key fingerprint is MD5:e7:7e:03:19:6e:1b:61:a9:41:11:a1:e2:d7:4e:e8:72.
Are you sure you want to continue connecting (yes/no)? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed

/usr/bin/ssh-copy-id: WARNING: All keys were skipped because they already exist on the remote system.
                (if you think this is a mistake, you may want to use -f option)

[gpadmin@Segment-b .ssh]$ ssh-copy-id Segment-d
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/gpadmin/.ssh/id_rsa.pub"
The authenticity of host 'segment-d (192.168.7.140)' can't be established.
ECDSA key fingerprint is SHA256:I1f3uAfaIdL9/v9+FfzOQhluYIWG1sHOf+BP4euLdPg.
ECDSA key fingerprint is MD5:10:a4:29:ab:1e:97:35:67:ff:ad:3f:8a:d9:e2:be:a2.
Are you sure you want to continue connecting (yes/no)? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed

/usr/bin/ssh-copy-id: WARNING: All keys were skipped because they already exist on the remote system.
                (if you think this is a mistake, you may want to use -f option)

[gpadmin@Segment-b .ssh]$ ssh Segment-c
Last login: Thu Jun 20 11:36:47 2024 from 192.168.7.138
[gpadmin@Segment-c ~]$ exit
logout
Connection to segment-c closed.
[gpadmin@Segment-b .ssh]$ ssh Segment-d
Last login: Thu Jun 20 11:36:51 2024 from 192.168.7.138
[gpadmin@Segment-d ~]$ exit
logout
Connection to segment-d closed.
[gpadmin@Segment-b .ssh]$
```

### 实验前准备

```powershell
# 设置虚拟机镜像 用于回滚
略

# 创建expand_seg_hosts
[gpadmin@Master-a conf]$ touch expand_seg_hosts
[gpadmin@Master-a conf]$ cat << EOF >> expand_seg_hosts 
> Segment-c
> Segment-d
> EOF
[gpadmin@Master-a conf]$ cat expand_seg_hosts 
Segment-c
Segment-d

# 执行联通性测试
[gpadmin@Master-a conf]$ gpssh-exkeys -f expand_seg_hosts
[STEP 1 of 5] create local ID and authorize on local host
  ... /home/gpadmin/.ssh/id_rsa file exists ... key generation skipped

[STEP 2 of 5] keyscan all hosts and update known_hosts file

[STEP 3 of 5] retrieving credentials from remote hosts
  ... send to Segment-c
  ... send to Segment-d

[STEP 4 of 5] determine common authentication file content

[STEP 5 of 5] copy authentication files to all remote hosts
  ... finished key exchange with Segment-c
  ... finished key exchange with Segment-d

[INFO] completed successfully
[gpadmin@Master-a conf]$

# 之前的也需要进行一次联通测试
[gpadmin@Master-a conf]$ gpssh-exkeys -f seg_hosts 
[STEP 1 of 5] create local ID and authorize on local host
  ... /home/gpadmin/.ssh/id_rsa file exists ... key generation skipped

[STEP 2 of 5] keyscan all hosts and update known_hosts file

[STEP 3 of 5] retrieving credentials from remote hosts
  ... send to Segment-a
  ... send to Segment-b

[STEP 4 of 5] determine common authentication file content

[STEP 5 of 5] copy authentication files to all remote hosts
  ... finished key exchange with Segment-a
  ... finished key exchange with Segment-b

[INFO] completed successfully
[gpadmin@Master-a conf]$

# 创建数据目录
[gpadmin@Master-a conf]$ gpssh -f expand_seg_hosts 
=> pwd
[Segment-d] /home/gpadmin
[Segment-c] /home/gpadmin
=> mkdir -p data/{primary,mirror}
[Segment-d]
[Segment-c]
=> tree
[Segment-d] .
[Segment-d] └── data
[Segment-d]     ├── mirror
[Segment-d]     └── primary
[Segment-d] 
[Segment-d] 3 directories, 0 files
[Segment-c] .
[Segment-c] └── data
[Segment-c]     ├── mirror
[Segment-c]     └── primary
[Segment-c] 
[Segment-c] 3 directories, 0 files
=> exit

[gpadmin@Master-a conf]$

# 关闭防火墙
[root@Segment-c ~]# systemctl disable firewalld --now
Removed symlink /etc/systemd/system/multi-user.target.wants/firewalld.service.
Removed symlink /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service.
[root@Segment-c ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)

Jun 18 09:05:29 Segment-c systemd[1]: Starting firewalld - dynamic firewall daemon...
Jun 18 09:05:30 Segment-c systemd[1]: Started firewalld - dynamic firewall daemon.
Jun 20 11:51:33 Segment-c systemd[1]: Stopping firewalld - dynamic firewall daemon...
Jun 20 11:51:33 Segment-c systemd[1]: Stopped firewalld - dynamic firewall daemon.
[root@Segment-c ~]#

[root@Segment-d ~]# systemctl disable firewalld --now
Removed symlink /etc/systemd/system/multi-user.target.wants/firewalld.service.
Removed symlink /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service.
[root@Segment-d ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)

Jun 18 09:05:17 Segment-d systemd[1]: Starting firewalld - dynamic firewall daemon...
Jun 18 09:05:17 Segment-d systemd[1]: Started firewalld - dynamic firewall daemon.
Jun 20 11:52:39 Segment-d systemd[1]: Stopping firewalld - dynamic firewall daemon...
Jun 20 11:52:40 Segment-d systemd[1]: Stopped firewalld - dynamic firewall daemon.
[root@Segment-d ~]#

# 测试服务器性能IO以及网络性能IO

[gpadmin@Master-a conf]$ gpcheckperf -f expand_seg_hosts -r N -d /tmp
/usr/local/greenplum-db/bin/gpcheckperf -f expand_seg_hosts -r N -d /tmp

-------------------
--  NETPERF TEST
-------------------
NOTICE: -t is deprecated, and has no effect
NOTICE: -f is deprecated, and has no effect
NOTICE: -t is deprecated, and has no effect
NOTICE: -f is deprecated, and has no effect

====================
==  RESULT 2024-06-20T11:54:45.045745
====================
Netperf bisection bandwidth test
Segment-c -> Segment-d = 687.200000
Segment-d -> Segment-c = 692.910000

Summary:
sum = 1380.11 MB/sec
min = 687.20 MB/sec
max = 692.91 MB/sec
avg = 690.06 MB/sec
median = 692.91 MB/sec

[gpadmin@Master-a conf]$

```

### 实验开始

```powershell
[gpadmin@Master-a conf]$ gpexpand -f  expand_seg_hosts 
20240620:13:31:37:006624 gpexpand:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:13:31:37:006624 gpexpand:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240620:13:31:37:006624 gpexpand:Master-a:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state
20240620:13:31:37:006624 gpexpand:Master-a:gpadmin-[INFO]:-Expansion has already completed.
20240620:13:31:37:006624 gpexpand:Master-a:gpadmin-[INFO]:-If you want to expand again, run gpexpand -c to remove
20240620:13:31:37:006624 gpexpand:Master-a:gpadmin-[INFO]:-the gpexpand schema and begin a new expansion
20240620:13:31:37:006624 gpexpand:Master-a:gpadmin-[INFO]:-Exiting...
[gpadmin@Master-a conf]$ cd ..
[gpadmin@Master-a ~]$ ls
conf  data  expand_mirrors  expand_segment_instance  gpAdminLogs  gpconfigs  soft
[gpadmin@Master-a ~]$ cd expand_segment_instance/
[gpadmin@Master-a expand_segment_instance]$ ls
expand_segment_indtance_hosts  gpexpand_inputfile_20240611_140203
[gpadmin@Master-a expand_segment_instance]$ cp -ra ../conf/expand_seg_hosts expand_Segment_nodes
[gpadmin@Master-a expand_segment_instance]$ cat expand_Segment_nodes 
Segment-c
Segment-d
[gpadmin@Master-a expand_segment_instance]$

[gpadmin@Master-a expand_segment_instance]$ gpexpand -f  expand_Segment_nodes 
20240620:13:33:48:006736 gpexpand:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:13:33:48:006736 gpexpand:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240620:13:33:48:006736 gpexpand:Master-a:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state
20240620:13:33:48:006736 gpexpand:Master-a:gpadmin-[INFO]:-Expansion has already completed.
20240620:13:33:48:006736 gpexpand:Master-a:gpadmin-[INFO]:-If you want to expand again, run gpexpand -c to remove
20240620:13:33:48:006736 gpexpand:Master-a:gpadmin-[INFO]:-the gpexpand schema and begin a new expansion
20240620:13:33:48:006736 gpexpand:Master-a:gpadmin-[INFO]:-Exiting...
[gpadmin@Master-a expand_segment_instance]$ gpexpand -c
20240620:13:33:54:006763 gpexpand:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:13:33:54:006763 gpexpand:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240620:13:33:54:006763 gpexpand:Master-a:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state


Do you want to dump the gpexpand.status_detail table to file? Yy|Nn (default=Y):
> y
20240620:13:34:45:006763 gpexpand:Master-a:gpadmin-[INFO]:-Dumping gpexpand.status_detail to /home/gpadmin/data/master/gpseg-1/gpexpand.status_detail
20240620:13:34:45:006763 gpexpand:Master-a:gpadmin-[INFO]:-Removing gpexpand schema
20240620:13:34:45:006763 gpexpand:Master-a:gpadmin-[INFO]:-Cleanup Finished.  exiting...
[gpadmin@Master-a expand_segment_instance]$


# 构建扩容任务
[gpadmin@Master-a expand_segment_instance]$ gpexpand -f  expand_Segment_nodes 
20240620:13:49:45:006977 gpexpand:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:13:49:45:006977 gpexpand:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240620:13:49:45:006977 gpexpand:Master-a:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state

System Expansion is used to add segments to an existing GPDB array.
gpexpand did not detect a System Expansion that is in progress.

Before initiating a System Expansion, you need to provision and burn-in
the new hardware.  Please be sure to run gpcheckperf to make sure the
new hardware is working properly.

Please refer to the Admin Guide for more information.

Would you like to initiate a new System Expansion Yy|Nn (default=N):
> y

You must now specify a mirroring strategy for the new hosts.  Spread mirroring places
a given hosts mirrored segments each on a separate host.  You must be 
adding more hosts than the number of segments per host to use this. 
Grouped mirroring places all of a given hosts segments on a single 
mirrored host.  You must be adding at least 2 hosts in order to use this.



What type of mirroring strategy would you like?
 spread|grouped (default=grouped):
> 

    By default, new hosts are configured with the same number of primary
    segments as existing hosts.  Optionally, you can increase the number
    of segments per host.

    For example, if existing hosts have two primary segments, entering a value
    of 2 will initialize two additional segments on existing hosts, and four
    segments on new hosts.  In addition, mirror segments will be added for
    these new primary segments if mirroring is enabled.
    

How many new primary segments per host do you want to add? (default=0):
> 

Generating configuration file...

20240620:13:50:48:006977 gpexpand:Master-a:gpadmin-[INFO]:-Generating input file...

Input configuration file was written to 'gpexpand_inputfile_20240620_135048'.

Please review the file and make sure that it is correct then re-run
with: gpexpand -i gpexpand_inputfile_20240620_135048
                
20240620:13:50:48:006977 gpexpand:Master-a:gpadmin-[INFO]:-Exiting...
[gpadmin@Master-a expand_segment_instance]$ cat gpexpand_inputfile_20240620_135048
Segment-c|Segment-c|6000|/home/gpadmin/data/primary/gpseg8|18|8|p
Segment-d|Segment-d|7000|/home/gpadmin/data/mirror/gpseg8|30|8|m
Segment-c|Segment-c|6001|/home/gpadmin/data/primary/gpseg9|19|9|p
Segment-d|Segment-d|7001|/home/gpadmin/data/mirror/gpseg9|31|9|m
Segment-c|Segment-c|6002|/home/gpadmin/data/primary/gpseg10|20|10|p
Segment-d|Segment-d|7002|/home/gpadmin/data/mirror/gpseg10|32|10|m
Segment-c|Segment-c|6003|/home/gpadmin/data/primary/gpseg11|21|11|p
Segment-d|Segment-d|7003|/home/gpadmin/data/mirror/gpseg11|33|11|m
Segment-d|Segment-d|6000|/home/gpadmin/data/primary/gpseg12|22|12|p
Segment-c|Segment-c|7000|/home/gpadmin/data/mirror/gpseg12|26|12|m
Segment-d|Segment-d|6001|/home/gpadmin/data/primary/gpseg13|23|13|p
Segment-c|Segment-c|7001|/home/gpadmin/data/mirror/gpseg13|27|13|m
Segment-d|Segment-d|6002|/home/gpadmin/data/primary/gpseg14|24|14|p
Segment-c|Segment-c|7002|/home/gpadmin/data/mirror/gpseg14|28|14|m
Segment-d|Segment-d|6003|/home/gpadmin/data/primary/gpseg15|25|15|p
Segment-c|Segment-c|7003|/home/gpadmin/data/mirror/gpseg15|29|15|m

[gpadmin@Master-a expand_segment_instance]$ cat gpexpand_inputfile_20240620_135048 | grep p$
Segment-c|Segment-c|6000|/home/gpadmin/data/primary/gpseg8|18|8|p
Segment-c|Segment-c|6001|/home/gpadmin/data/primary/gpseg9|19|9|p
Segment-c|Segment-c|6002|/home/gpadmin/data/primary/gpseg10|20|10|p
Segment-c|Segment-c|6003|/home/gpadmin/data/primary/gpseg11|21|11|p
Segment-d|Segment-d|6000|/home/gpadmin/data/primary/gpseg12|22|12|p
Segment-d|Segment-d|6001|/home/gpadmin/data/primary/gpseg13|23|13|p
Segment-d|Segment-d|6002|/home/gpadmin/data/primary/gpseg14|24|14|p
Segment-d|Segment-d|6003|/home/gpadmin/data/primary/gpseg15|25|15|p
[gpadmin@Master-a expand_segment_instance]$ cat gpexpand_inputfile_20240620_135048 | grep m$
Segment-d|Segment-d|7000|/home/gpadmin/data/mirror/gpseg8|30|8|m
Segment-d|Segment-d|7001|/home/gpadmin/data/mirror/gpseg9|31|9|m
Segment-d|Segment-d|7002|/home/gpadmin/data/mirror/gpseg10|32|10|m
Segment-d|Segment-d|7003|/home/gpadmin/data/mirror/gpseg11|33|11|m
Segment-c|Segment-c|7000|/home/gpadmin/data/mirror/gpseg12|26|12|m
Segment-c|Segment-c|7001|/home/gpadmin/data/mirror/gpseg13|27|13|m
Segment-c|Segment-c|7002|/home/gpadmin/data/mirror/gpseg14|28|14|m
Segment-c|Segment-c|7003|/home/gpadmin/data/mirror/gpseg15|29|15|m
[gpadmin@Master-a expand_segment_instance]$


[gpadmin@Master-a expand_segment_instance]$ gpexpand -i gpexpand_inputfile_20240620_135048
20240620:13:54:51:007169 gpexpand:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:13:54:51:007169 gpexpand:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240620:13:54:51:007169 gpexpand:Master-a:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state
20240620:13:54:51:007169 gpexpand:Master-a:gpadmin-[INFO]:-Heap checksum setting consistent across cluster
20240620:13:54:51:007169 gpexpand:Master-a:gpadmin-[INFO]:-Syncing Greenplum Database extensions
20240620:13:54:52:007169 gpexpand:Master-a:gpadmin-[ERROR]:-ExecutionError: 'non-zero rc: 1' occurred.  Details: 'ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 Segment-d ". /usr/local/greenplum-db/greenplum_path.sh;  python -c \"import os, pickle; print pickle.dumps(os.makedirs('/usr/local/greenplum-db-6.13.0/share/packages/archive'))\" "'  cmd had rc=1 completed=True halted=False
  stdout=''
  stderr='Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/usr/local/greenplum-db-6.13.0/ext/python/lib/python2.7/os.py", line 150, in makedirs
    makedirs(head, mode)
  File "/usr/local/greenplum-db-6.13.0/ext/python/lib/python2.7/os.py", line 157, in makedirs
    mkdir(name, mode)
OSError: [Errno 13] Permission denied: '/usr/local/greenplum-db-6.13.0/share/packages'
'
Traceback (most recent call last):
  File "/usr/local/greenplum-db/lib/python/gppylib/commands/base.py", line 278, in run
    self.cmd.run()
  File "/usr/local/greenplum-db/lib/python/gppylib/operations/__init__.py", line 53, in run
    self.ret = self.execute()
  File "/usr/local/greenplum-db/lib/python/gppylib/operations/package.py", line 1021, in execute
    MakeRemoteDir(GPPKG_ARCHIVE_PATH, self.host).run()
  File "/usr/local/greenplum-db/lib/python/gppylib/operations/__init__.py", line 53, in run
    self.ret = self.execute()
  File "/usr/local/greenplum-db/lib/python/gppylib/operations/unix.py", line 43, in execute
    cmd.run(validateAfter=True)
  File "/usr/local/greenplum-db/lib/python/gppylib/commands/base.py", line 561, in run
    self.validate()
  File "/usr/local/greenplum-db/lib/python/gppylib/commands/base.py", line 609, in validate
    raise ExecutionError("non-zero rc: %d" % self.results.rc, self)
ExecutionError: ExecutionError: 'non-zero rc: 1' occurred.  Details: 'ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 Segment-d ". /usr/local/greenplum-db/greenplum_path.sh;  python -c \"import os, pickle; print pickle.dumps(os.makedirs('/usr/local/greenplum-db-6.13.0/share/packages/archive'))\" "'  cmd had rc=1 completed=True halted=False
  stdout=''
  stderr='Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/usr/local/greenplum-db-6.13.0/ext/python/lib/python2.7/os.py", line 150, in makedirs
    makedirs(head, mode)
  File "/usr/local/greenplum-db-6.13.0/ext/python/lib/python2.7/os.py", line 157, in makedirs
    mkdir(name, mode)
OSError: [Errno 13] Permission denied: '/usr/local/greenplum-db-6.13.0/share/packages'
'
20240620:13:54:52:007169 gpexpand:Master-a:gpadmin-[ERROR]:-ExecutionError: 'non-zero rc: 1' occurred.  Details: 'ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 Segment-c ". /usr/local/greenplum-db/greenplum_path.sh;  python -c \"import os, pickle; print pickle.dumps(os.makedirs('/usr/local/greenplum-db-6.13.0/share/packages/archive'))\" "'  cmd had rc=1 completed=True halted=False
  stdout=''
  stderr='Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/usr/local/greenplum-db-6.13.0/ext/python/lib/python2.7/os.py", line 150, in makedirs
    makedirs(head, mode)
  File "/usr/local/greenplum-db-6.13.0/ext/python/lib/python2.7/os.py", line 157, in makedirs
    mkdir(name, mode)
OSError: [Errno 13] Permission denied: '/usr/local/greenplum-db-6.13.0/share/packages'
'
Traceback (most recent call last):
  File "/usr/local/greenplum-db/lib/python/gppylib/commands/base.py", line 278, in run
    self.cmd.run()
  File "/usr/local/greenplum-db/lib/python/gppylib/operations/__init__.py", line 53, in run
    self.ret = self.execute()
  File "/usr/local/greenplum-db/lib/python/gppylib/operations/package.py", line 1021, in execute
    MakeRemoteDir(GPPKG_ARCHIVE_PATH, self.host).run()
  File "/usr/local/greenplum-db/lib/python/gppylib/operations/__init__.py", line 53, in run
    self.ret = self.execute()
  File "/usr/local/greenplum-db/lib/python/gppylib/operations/unix.py", line 43, in execute
    cmd.run(validateAfter=True)
  File "/usr/local/greenplum-db/lib/python/gppylib/commands/base.py", line 561, in run
    self.validate()
  File "/usr/local/greenplum-db/lib/python/gppylib/commands/base.py", line 609, in validate
    raise ExecutionError("non-zero rc: %d" % self.results.rc, self)
ExecutionError: ExecutionError: 'non-zero rc: 1' occurred.  Details: 'ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 Segment-c ". /usr/local/greenplum-db/greenplum_path.sh;  python -c \"import os, pickle; print pickle.dumps(os.makedirs('/usr/local/greenplum-db-6.13.0/share/packages/archive'))\" "'  cmd had rc=1 completed=True halted=False
  stdout=''
  stderr='Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/usr/local/greenplum-db-6.13.0/ext/python/lib/python2.7/os.py", line 150, in makedirs
    makedirs(head, mode)
  File "/usr/local/greenplum-db-6.13.0/ext/python/lib/python2.7/os.py", line 157, in makedirs
    mkdir(name, mode)
OSError: [Errno 13] Permission denied: '/usr/local/greenplum-db-6.13.0/share/packages'
'
20240620:13:54:52:007169 gpexpand:Master-a:gpadmin-[ERROR]:-Syncing of Greenplum Database extensions has failed.
Traceback (most recent call last):
  File "/usr/local/greenplum-db/bin/gpexpand", line 1886, in sync_packages
    operation.get_ret()
  File "/usr/local/greenplum-db/lib/python/gppylib/operations/__init__.py", line 65, in get_ret
    raise self.ret
ExecutionError: ExecutionError: 'non-zero rc: 1' occurred.  Details: 'ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 Segment-d ". /usr/local/greenplum-db/greenplum_path.sh;  python -c \"import os, pickle; print pickle.dumps(os.makedirs('/usr/local/greenplum-db-6.13.0/share/packages/archive'))\" "'  cmd had rc=1 completed=True halted=False
  stdout=''
  stderr='Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/usr/local/greenplum-db-6.13.0/ext/python/lib/python2.7/os.py", line 150, in makedirs
    makedirs(head, mode)
  File "/usr/local/greenplum-db-6.13.0/ext/python/lib/python2.7/os.py", line 157, in makedirs
    mkdir(name, mode)
OSError: [Errno 13] Permission denied: '/usr/local/greenplum-db-6.13.0/share/packages'
'
20240620:13:54:52:007169 gpexpand:Master-a:gpadmin-[WARNING]:-Please run gppkg --clean after successful expansion.
20240620:13:54:52:007169 gpexpand:Master-a:gpadmin-[INFO]:-Locking catalog
20240620:13:54:52:007169 gpexpand:Master-a:gpadmin-[INFO]:-Locked catalog
20240620:13:54:52:007169 gpexpand:Master-a:gpadmin-[INFO]:-Creating segment template
20240620:13:54:54:007169 gpexpand:Master-a:gpadmin-[INFO]:-Copying postgresql.conf from existing segment into template
20240620:13:54:54:007169 gpexpand:Master-a:gpadmin-[INFO]:-Copying pg_hba.conf from existing segment into template
20240620:13:54:55:007169 gpexpand:Master-a:gpadmin-[INFO]:-Creating schema tar file
20240620:13:54:55:007169 gpexpand:Master-a:gpadmin-[INFO]:-Distributing template tar file to new hosts
20240620:13:54:57:007169 gpexpand:Master-a:gpadmin-[INFO]:-Configuring new segments (primary)
20240620:13:54:57:007169 gpexpand:Master-a:gpadmin-[INFO]:-{'Segment-d': '/home/gpadmin/data/primary/gpseg12:6000:true:false:22:12::-1:,/home/gpadmin/data/primary/gpseg13:6001:true:false:23:13::-1:,/home/gpadmin/data/primary/gpseg14:6002:true:false:24:14::-1:,/home/gpadmin/data/primary/gpseg15:6003:true:false:25:15::-1:', 'Segment-c': '/home/gpadmin/data/primary/gpseg8:6000:true:false:18:8::-1:,/home/gpadmin/data/primary/gpseg9:6001:true:false:19:9::-1:,/home/gpadmin/data/primary/gpseg10:6002:true:false:20:10::-1:,/home/gpadmin/data/primary/gpseg11:6003:true:false:21:11::-1:'}
20240620:13:55:07:007169 gpexpand:Master-a:gpadmin-[INFO]:-Cleaning up temporary template files
20240620:13:55:07:007169 gpexpand:Master-a:gpadmin-[INFO]:-Cleaning up databases in new segments.
20240620:13:55:09:007169 gpexpand:Master-a:gpadmin-[INFO]:-Unlocking catalog
20240620:13:55:09:007169 gpexpand:Master-a:gpadmin-[INFO]:-Unlocked catalog
20240620:13:55:09:007169 gpexpand:Master-a:gpadmin-[INFO]:-Creating expansion schema
20240620:13:55:09:007169 gpexpand:Master-a:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database template1
20240620:13:55:09:007169 gpexpand:Master-a:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database postgres
20240620:13:55:09:007169 gpexpand:Master-a:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database gp_sydb
20240620:13:55:09:007169 gpexpand:Master-a:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database test_db
20240620:13:55:09:007169 gpexpand:Master-a:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database test_database
20240620:13:55:09:007169 gpexpand:Master-a:gpadmin-[INFO]:-Starting new mirror segment synchronization
20240620:13:55:29:007169 gpexpand:Master-a:gpadmin-[INFO]:-************************************************
20240620:13:55:29:007169 gpexpand:Master-a:gpadmin-[INFO]:-Initialization of the system expansion complete.
20240620:13:55:29:007169 gpexpand:Master-a:gpadmin-[INFO]:-To begin table expansion onto the new segments
20240620:13:55:29:007169 gpexpand:Master-a:gpadmin-[INFO]:-rerun gpexpand
20240620:13:55:29:007169 gpexpand:Master-a:gpadmin-[INFO]:-************************************************
20240620:13:55:29:007169 gpexpand:Master-a:gpadmin-[INFO]:-Exiting...
[gpadmin@Master-a expand_segment_instance]$

失败了 查看下集群状态
查看集群状态

[gpadmin@Master-a root]$ gpstate
20240620:13:56:46:007649 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: 
20240620:13:56:46:007649 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:13:56:46:007649 gpstate:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240620:13:56:46:007649 gpstate:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240620:13:56:46:007649 gpstate:Master-a:gpadmin-[INFO]:-Gathering data from segments...
20240620:13:56:47:007649 gpstate:Master-a:gpadmin-[INFO]:-Greenplum instance status summary
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Master instance                                           = Active
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Master standby                                            = No master standby configured
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total segment instance count from metadata                = 32
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Primary Segment Status
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segments                                    = 16
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment valid (at master)                   = 16
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment failures (at master)                = 0
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 16
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 16
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 16
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes found                   = 16
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Mirror Segment Status
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total mirror segments                                     = 16
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total mirror segment valid (at master)                    = 16
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total mirror segment failures (at master)                 = 0
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 16
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 16
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 16
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes found                   = 16
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number mirror segments acting as primary segments   = 0
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Total number mirror segments acting as mirror segments    = 16
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-   Cluster Expansion                                         = In Progress
20240620:13:56:48:007649 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
[gpadmin@Master-a root]$

重启下集群验证下

[gpadmin@Master-a root]$ gpstop
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-Starting gpstop with args: 
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-Gathering information and validating the environment...
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-Obtaining Greenplum Master catalog information
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:---------------------------------------------
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-Master instance parameters
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:---------------------------------------------
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Master Greenplum instance process active PID   = 3667
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Database                                       = template1
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Master port                                    = 5432
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Master directory                               = /home/gpadmin/data/master/gpseg-1
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Shutdown mode                                  = smart
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Timeout                                        = 120
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Shutdown Master standby host                   = Off
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:---------------------------------------------
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-Segment instances that will be shutdown:
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:---------------------------------------------
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Host        Datadir                              Port   Status
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg0    6000   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg0     7000   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg1    6001   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg1     7001   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg2    6000   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg2     7000   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg3    6001   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg3     7001   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg4    6002   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg4     7002   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg5    6003   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg5     7003   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg6    6002   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg6     7002   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg7    6003   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg7     7003   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-c   /home/gpadmin/data/primary/gpseg8    6000   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-d   /home/gpadmin/data/mirror/gpseg8     7000   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-c   /home/gpadmin/data/primary/gpseg9    6001   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-d   /home/gpadmin/data/mirror/gpseg9     7001   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-c   /home/gpadmin/data/primary/gpseg10   6002   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-d   /home/gpadmin/data/mirror/gpseg10    7002   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-c   /home/gpadmin/data/primary/gpseg11   6003   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-d   /home/gpadmin/data/mirror/gpseg11    7003   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-d   /home/gpadmin/data/primary/gpseg12   6000   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-c   /home/gpadmin/data/mirror/gpseg12    7000   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-d   /home/gpadmin/data/primary/gpseg13   6001   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-c   /home/gpadmin/data/mirror/gpseg13    7001   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-d   /home/gpadmin/data/primary/gpseg14   6002   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-c   /home/gpadmin/data/mirror/gpseg14    7002   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-d   /home/gpadmin/data/primary/gpseg15   6003   u
20240620:13:58:02:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segment-c   /home/gpadmin/data/mirror/gpseg15    7003   u

Continue with Greenplum instance shutdown Yy|Nn (default=N):
> y
20240620:13:58:05:007725 gpstop:Master-a:gpadmin-[INFO]:-Commencing Master instance shutdown with mode='smart'
20240620:13:58:05:007725 gpstop:Master-a:gpadmin-[INFO]:-Master segment instance directory=/home/gpadmin/data/master/gpseg-1
20240620:13:58:05:007725 gpstop:Master-a:gpadmin-[INFO]:-Stopping master segment and waiting for user connections to finish ...
could not change directory to "/root": Permission denied
server shutting down
could not change directory to "/root": Permission denied
could not change directory to "/root": Permission denied
20240620:13:58:06:007725 gpstop:Master-a:gpadmin-[INFO]:-Attempting forceful termination of any leftover master process
20240620:13:58:06:007725 gpstop:Master-a:gpadmin-[INFO]:-Terminating processes for segment /home/gpadmin/data/master/gpseg-1
20240620:13:58:06:007725 gpstop:Master-a:gpadmin-[INFO]:-No standby master host configured
20240620:13:58:06:007725 gpstop:Master-a:gpadmin-[INFO]:-Targeting dbid [2, 10, 3, 11, 4, 14, 5, 15, 6, 12, 7, 13, 8, 16, 9, 17, 18, 30, 19, 31, 20, 32, 21, 33, 22, 26, 23, 27, 24, 28, 25, 29] for shutdown
20240620:13:58:06:007725 gpstop:Master-a:gpadmin-[INFO]:-Commencing parallel primary segment instance shutdown, please wait...
20240620:13:58:06:007725 gpstop:Master-a:gpadmin-[INFO]:-0.00% of jobs completed
20240620:13:58:07:007725 gpstop:Master-a:gpadmin-[INFO]:-100.00% of jobs completed
20240620:13:58:07:007725 gpstop:Master-a:gpadmin-[INFO]:-Commencing parallel mirror segment instance shutdown, please wait...
20240620:13:58:07:007725 gpstop:Master-a:gpadmin-[INFO]:-0.00% of jobs completed
20240620:13:58:08:007725 gpstop:Master-a:gpadmin-[INFO]:-100.00% of jobs completed
20240620:13:58:08:007725 gpstop:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:58:08:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segments stopped successfully      = 32
20240620:13:58:08:007725 gpstop:Master-a:gpadmin-[INFO]:-   Segments with errors during stop   = 0
20240620:13:58:08:007725 gpstop:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:58:08:007725 gpstop:Master-a:gpadmin-[INFO]:-Successfully shutdown 32 of 32 segment instances 
20240620:13:58:08:007725 gpstop:Master-a:gpadmin-[INFO]:-Database successfully shutdown with no errors reported
20240620:13:58:08:007725 gpstop:Master-a:gpadmin-[INFO]:-Cleaning up leftover gpmmon process
20240620:13:58:08:007725 gpstop:Master-a:gpadmin-[INFO]:-No leftover gpmmon process found
20240620:13:58:08:007725 gpstop:Master-a:gpadmin-[INFO]:-Cleaning up leftover gpsmon processes
20240620:13:58:08:007725 gpstop:Master-a:gpadmin-[INFO]:-No leftover gpsmon processes on some hosts. not attempting forceful termination on these hosts
20240620:13:58:08:007725 gpstop:Master-a:gpadmin-[INFO]:-Cleaning up leftover shared memory
[gpadmin@Master-a root]$ cd ~
[gpadmin@Master-a ~]$ gp

[gpadmin@Master-a ~]$ gpstart
20240620:13:58:43:007908 gpstart:Master-a:gpadmin-[INFO]:-Starting gpstart with args: 
20240620:13:58:43:007908 gpstart:Master-a:gpadmin-[INFO]:-Gathering information and validating the environment...
20240620:13:58:43:007908 gpstart:Master-a:gpadmin-[INFO]:-Greenplum Binary Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:13:58:43:007908 gpstart:Master-a:gpadmin-[INFO]:-Greenplum Catalog Version: '301908232'
20240620:13:58:43:007908 gpstart:Master-a:gpadmin-[INFO]:-Starting Master instance in admin mode
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-Obtaining Greenplum Master catalog information
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-Setting new master era
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-Master Started...
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-Shutting down master
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:---------------------------
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-Master instance parameters
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:---------------------------
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-Database                 = template1
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-Master Port              = 5432
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-Master directory         = /home/gpadmin/data/master/gpseg-1
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-Timeout                  = 600 seconds
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-Master standby           = Off 
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:---------------------------------------
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-Segment instances that will be started
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:---------------------------------------
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Host        Datadir                              Port   Role
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg0    6000   Primary
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg0     7000   Mirror
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg1    6001   Primary
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg1     7001   Mirror
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg2    6000   Primary
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg2     7000   Mirror
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg3    6001   Primary
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg3     7001   Mirror
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg4    6002   Primary
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg4     7002   Mirror
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/primary/gpseg5    6003   Primary
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/mirror/gpseg5     7003   Mirror
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg6    6002   Primary
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg6     7002   Mirror
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-b   /home/gpadmin/data/primary/gpseg7    6003   Primary
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-a   /home/gpadmin/data/mirror/gpseg7     7003   Mirror
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-c   /home/gpadmin/data/primary/gpseg8    6000   Primary
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-d   /home/gpadmin/data/mirror/gpseg8     7000   Mirror
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-c   /home/gpadmin/data/primary/gpseg9    6001   Primary
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-d   /home/gpadmin/data/mirror/gpseg9     7001   Mirror
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-c   /home/gpadmin/data/primary/gpseg10   6002   Primary
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-d   /home/gpadmin/data/mirror/gpseg10    7002   Mirror
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-c   /home/gpadmin/data/primary/gpseg11   6003   Primary
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-d   /home/gpadmin/data/mirror/gpseg11    7003   Mirror
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-d   /home/gpadmin/data/primary/gpseg12   6000   Primary
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-c   /home/gpadmin/data/mirror/gpseg12    7000   Mirror
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-d   /home/gpadmin/data/primary/gpseg13   6001   Primary
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-c   /home/gpadmin/data/mirror/gpseg13    7001   Mirror
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-d   /home/gpadmin/data/primary/gpseg14   6002   Primary
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-c   /home/gpadmin/data/mirror/gpseg14    7002   Mirror
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-d   /home/gpadmin/data/primary/gpseg15   6003   Primary
20240620:13:58:44:007908 gpstart:Master-a:gpadmin-[INFO]:-   Segment-c   /home/gpadmin/data/mirror/gpseg15    7003   Mirror

Continue with Greenplum instance startup Yy|Nn (default=N):
> y
20240620:13:58:48:007908 gpstart:Master-a:gpadmin-[INFO]:-Commencing parallel primary and mirror segment instance startup, please wait...
.....
20240620:13:58:53:007908 gpstart:Master-a:gpadmin-[INFO]:-Process results...
20240620:13:58:53:007908 gpstart:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:58:53:007908 gpstart:Master-a:gpadmin-[INFO]:-   Successful segment starts                                            = 32
20240620:13:58:53:007908 gpstart:Master-a:gpadmin-[INFO]:-   Failed segment starts                                                = 0
20240620:13:58:53:007908 gpstart:Master-a:gpadmin-[INFO]:-   Skipped segment starts (segments are marked down in configuration)   = 0
20240620:13:58:53:007908 gpstart:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:58:53:007908 gpstart:Master-a:gpadmin-[INFO]:-Successfully started 32 of 32 segment instances 
20240620:13:58:53:007908 gpstart:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:58:53:007908 gpstart:Master-a:gpadmin-[INFO]:-Starting Master instance Master-a directory /home/gpadmin/data/master/gpseg-1 
20240620:13:58:54:007908 gpstart:Master-a:gpadmin-[INFO]:-Command pg_ctl reports Master Master-a instance active
20240620:13:58:54:007908 gpstart:Master-a:gpadmin-[INFO]:-Connecting to dbname='template1' connect_timeout=15
20240620:13:58:54:007908 gpstart:Master-a:gpadmin-[INFO]:-No standby master configured.  skipping...
20240620:13:58:54:007908 gpstart:Master-a:gpadmin-[INFO]:-Database successfully started
[gpadmin@Master-a ~]$

[gpadmin@Master-a ~]$ gpstate
20240620:13:59:20:008038 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: 
20240620:13:59:20:008038 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:13:59:20:008038 gpstate:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240620:13:59:20:008038 gpstate:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240620:13:59:20:008038 gpstate:Master-a:gpadmin-[INFO]:-Gathering data from segments...
20240620:13:59:20:008038 gpstate:Master-a:gpadmin-[INFO]:-Greenplum instance status summary
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Master instance                                           = Active
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Master standby                                            = No master standby configured
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total segment instance count from metadata                = 32
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Primary Segment Status
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segments                                    = 16
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment valid (at master)                   = 16
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment failures (at master)                = 0
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 16
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 16
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 16
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes found                   = 16
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Mirror Segment Status
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total mirror segments                                     = 16
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total mirror segment valid (at master)                    = 16
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total mirror segment failures (at master)                 = 0
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 16
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 16
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 16
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes found                   = 16
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number mirror segments acting as primary segments   = 0
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Total number mirror segments acting as mirror segments    = 16
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-   Cluster Expansion                                         = In Progress
20240620:13:59:21:008038 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
[gpadmin@Master-a ~]$


结果是OK的但是故障是因为权限不正确，
[root@Segment-c soft]# cd /usr/local/
[root@Segment-c local]# ll
total 0
drwxr-xr-x.  2 root root   6 Apr 11  2018 bin
drwxr-xr-x.  2 root root   6 Apr 11  2018 etc
drwxr-xr-x.  2 root root   6 Apr 11  2018 games
lrwxrwxrwx   1 root root  30 Jun 20 13:29 greenplum-db -> /usr/local/greenplum-db-6.13.0
drwxr-xr-x  11 root root 238 Jun 20 13:29 greenplum-db-6.13.0
drwxr-xr-x.  2 root root   6 Apr 11  2018 include
drwxr-xr-x.  2 root root   6 Apr 11  2018 lib
drwxr-xr-x.  2 root root   6 Apr 11  2018 lib64
drwxr-xr-x.  2 root root   6 Apr 11  2018 libexec
drwxr-xr-x.  2 root root   6 Apr 11  2018 sbin
drwxr-xr-x.  5 root root  49 Jun 13 23:25 share
drwxr-xr-x.  2 root root   6 Apr 11  2018 src
[root@Segment-c local]# chown -R gpadmin.gpadmin greenplum-db*
[root@Segment-c local]#
处理下即可
```

### 一些错误的记录

```powershell
> 这里是错误的操作 不要效方，需要先进行数据重新分布 再删除扩容计划
[gpadmin@Master-a expand_segment_instance]$ gpexpand -c
20240620:14:06:29:008127 gpexpand:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:14:06:29:008127 gpexpand:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240620:14:06:29:008127 gpexpand:Master-a:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state
20240620:14:06:29:008127 gpexpand:Master-a:gpadmin-[WARNING]:-Expansion has not yet completed.  Removing the expansion
20240620:14:06:29:008127 gpexpand:Master-a:gpadmin-[WARNING]:-schema now will leave the following tables unexpanded:
20240620:14:06:29:008127 gpexpand:Master-a:gpadmin-[WARNING]:-  public.table_test

20240620:14:06:29:008127 gpexpand:Master-a:gpadmin-[WARNING]:-These tables will have to be expanded manually by setting
20240620:14:06:29:008127 gpexpand:Master-a:gpadmin-[WARNING]:-the distribution policy using the ALTER TABLE command.


Are you sure you want to drop the expansion schema? Yy|Nn (default=N):
> y


Do you want to dump the gpexpand.status_detail table to file? Yy|Nn (default=Y):
> y
20240620:14:06:38:008127 gpexpand:Master-a:gpadmin-[INFO]:-Dumping gpexpand.status_detail to /home/gpadmin/data/master/gpseg-1/gpexpand.status_detail
20240620:14:06:38:008127 gpexpand:Master-a:gpadmin-[INFO]:-Removing gpexpand schema
20240620:14:06:38:008127 gpexpand:Master-a:gpadmin-[INFO]:-Cleanup Finished.  exiting...
[gpadmin@Master-a expand_segment_instance]$


完蛋了！集群白做了，一定要记得扩容完要重新分布数据要不没有意义！！ 或者根据需求不分布也可以，但是实验规划分布，所以要镜像回滚了！！

# 回滚镜像到 数据 - 不能回滚

数据重分布
因为扩容后没有执行数据重新分布，所以数据依然为之前的segment，模拟场景也有可能发生，有个思路，就是再创建一个segment，或者2个segment，重新做一次数据分布，看看有没有效果。
再次扩容一次
[gpadmin@Master-a expand_segment_instance]$ gpexpand -f expand_Segment_nodes 
20240620:15:28:41:008675 gpexpand:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:15:28:41:008675 gpexpand:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240620:15:28:41:008675 gpexpand:Master-a:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state

System Expansion is used to add segments to an existing GPDB array.
gpexpand did not detect a System Expansion that is in progress.

Before initiating a System Expansion, you need to provision and burn-in
the new hardware.  Please be sure to run gpcheckperf to make sure the
new hardware is working properly.

Please refer to the Admin Guide for more information.

Would you like to initiate a new System Expansion Yy|Nn (default=N):
> y

You must now specify a mirroring strategy for the new hosts.  Spread mirroring places
a given hosts mirrored segments each on a separate host.  You must be 
adding more hosts than the number of segments per host to use this. 
Grouped mirroring places all of a given hosts segments on a single 
mirrored host.  You must be adding at least 2 hosts in order to use this.



What type of mirroring strategy would you like?
 spread|grouped (default=grouped):
> 

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
> 1
Enter new primary data directory 1:
> /home/gpadmin/data/primary
Enter new mirror data directory 1:
> /home/gpadmin/data/mirror

Generating configuration file...

20240620:15:29:24:008675 gpexpand:Master-a:gpadmin-[INFO]:-Generating input file...

Input configuration file was written to 'gpexpand_inputfile_20240620_152924'.

Please review the file and make sure that it is correct then re-run
with: gpexpand -i gpexpand_inputfile_20240620_152924
                
20240620:15:29:24:008675 gpexpand:Master-a:gpadmin-[INFO]:-Exiting...
[gpadmin@Master-a expand_segment_instance]$ cat gpexpand_inputfile_20240620_152924 
Segment-a|Segment-a|6004|/home/gpadmin/data/primary/gpseg16|34|16|p
Segment-b|Segment-b|7004|/home/gpadmin/data/mirror/gpseg16|39|16|m
Segment-b|Segment-b|6004|/home/gpadmin/data/primary/gpseg17|35|17|p
Segment-c|Segment-c|7004|/home/gpadmin/data/mirror/gpseg17|40|17|m
Segment-c|Segment-c|6004|/home/gpadmin/data/primary/gpseg18|36|18|p
Segment-d|Segment-d|7004|/home/gpadmin/data/mirror/gpseg18|41|18|m
Segment-d|Segment-d|6004|/home/gpadmin/data/primary/gpseg19|37|19|p
Segment-a|Segment-a|7004|/home/gpadmin/data/mirror/gpseg19|38|19|m
[gpadmin@Master-a expand_segment_instance]$ cat gpexpand_inputfile_20240620_152924 | grep p$
Segment-a|Segment-a|6004|/home/gpadmin/data/primary/gpseg16|34|16|p
Segment-b|Segment-b|6004|/home/gpadmin/data/primary/gpseg17|35|17|p
Segment-c|Segment-c|6004|/home/gpadmin/data/primary/gpseg18|36|18|p
Segment-d|Segment-d|6004|/home/gpadmin/data/primary/gpseg19|37|19|p
[gpadmin@Master-a expand_segment_instance]$ cat gpexpand_inputfile_20240620_152924 | grep m$
Segment-b|Segment-b|7004|/home/gpadmin/data/mirror/gpseg16|39|16|m
Segment-c|Segment-c|7004|/home/gpadmin/data/mirror/gpseg17|40|17|m
Segment-d|Segment-d|7004|/home/gpadmin/data/mirror/gpseg18|41|18|m
Segment-a|Segment-a|7004|/home/gpadmin/data/mirror/gpseg19|38|19|m
[gpadmin@Master-a expand_segment_instance]$

[gpadmin@Master-a expand_segment_instance]$ gpexpand -i gpexpand_inputfile_20240620_152924
20240620:15:35:26:008710 gpexpand:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:15:35:26:008710 gpexpand:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240620:15:35:26:008710 gpexpand:Master-a:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state
20240620:15:35:27:008710 gpexpand:Master-a:gpadmin-[INFO]:-Heap checksum setting consistent across cluster
20240620:15:35:27:008710 gpexpand:Master-a:gpadmin-[INFO]:-Syncing Greenplum Database extensions
20240620:15:35:27:008710 gpexpand:Master-a:gpadmin-[INFO]:-The packages on Segment-d are consistent.
20240620:15:35:27:008710 gpexpand:Master-a:gpadmin-[INFO]:-The packages on Segment-a are consistent.
20240620:15:35:28:008710 gpexpand:Master-a:gpadmin-[INFO]:-The packages on Segment-c are consistent.
20240620:15:35:28:008710 gpexpand:Master-a:gpadmin-[INFO]:-The packages on Segment-b are consistent.
20240620:15:35:28:008710 gpexpand:Master-a:gpadmin-[INFO]:-Locking catalog
20240620:15:35:28:008710 gpexpand:Master-a:gpadmin-[INFO]:-Locked catalog
20240620:15:35:28:008710 gpexpand:Master-a:gpadmin-[INFO]:-Creating segment template
20240620:15:35:29:008710 gpexpand:Master-a:gpadmin-[INFO]:-Copying postgresql.conf from existing segment into template
20240620:15:35:29:008710 gpexpand:Master-a:gpadmin-[INFO]:-Copying pg_hba.conf from existing segment into template
20240620:15:35:29:008710 gpexpand:Master-a:gpadmin-[INFO]:-Creating schema tar file
20240620:15:35:30:008710 gpexpand:Master-a:gpadmin-[INFO]:-Distributing template tar file to new hosts
20240620:15:35:33:008710 gpexpand:Master-a:gpadmin-[INFO]:-Configuring new segments (primary)
20240620:15:35:33:008710 gpexpand:Master-a:gpadmin-[INFO]:-{'Segment-d': '/home/gpadmin/data/primary/gpseg19:6004:true:false:37:19::-1:', 'Segment-a': '/home/gpadmin/data/primary/gpseg16:6004:true:false:34:16::-1:', 'Segment-c': '/home/gpadmin/data/primary/gpseg18:6004:true:false:36:18::-1:', 'Segment-b': '/home/gpadmin/data/primary/gpseg17:6004:true:false:35:17::-1:'}
20240620:15:35:37:008710 gpexpand:Master-a:gpadmin-[INFO]:-Cleaning up temporary template files
20240620:15:35:37:008710 gpexpand:Master-a:gpadmin-[INFO]:-Cleaning up databases in new segments.
20240620:15:35:38:008710 gpexpand:Master-a:gpadmin-[INFO]:-Unlocking catalog
20240620:15:35:38:008710 gpexpand:Master-a:gpadmin-[INFO]:-Unlocked catalog
20240620:15:35:38:008710 gpexpand:Master-a:gpadmin-[INFO]:-Creating expansion schema
20240620:15:35:38:008710 gpexpand:Master-a:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database template1
20240620:15:35:38:008710 gpexpand:Master-a:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database postgres
20240620:15:35:38:008710 gpexpand:Master-a:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database gp_sydb
20240620:15:35:38:008710 gpexpand:Master-a:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database test_db
20240620:15:35:39:008710 gpexpand:Master-a:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database test_database
20240620:15:35:39:008710 gpexpand:Master-a:gpadmin-[INFO]:-Starting new mirror segment synchronization
20240620:15:35:54:008710 gpexpand:Master-a:gpadmin-[INFO]:-************************************************
20240620:15:35:54:008710 gpexpand:Master-a:gpadmin-[INFO]:-Initialization of the system expansion complete.
20240620:15:35:54:008710 gpexpand:Master-a:gpadmin-[INFO]:-To begin table expansion onto the new segments
20240620:15:35:54:008710 gpexpand:Master-a:gpadmin-[INFO]:-rerun gpexpand
20240620:15:35:54:008710 gpexpand:Master-a:gpadmin-[INFO]:-************************************************
20240620:15:35:54:008710 gpexpand:Master-a:gpadmin-[INFO]:-Exiting...
[gpadmin@Master-a expand_segment_instance]$ ll
total 24
-rw-rw-r-- 1 gpadmin gpadmin   20 Jun 11 13:56 expand_segment_indtance_hosts
-rw-rw-r-- 1 gpadmin gpadmin   20 Jun 20 10:45 expand_Segment_nodes
-rw-rw-r-- 1 gpadmin gpadmin  260 Jun 11 14:02 gpexpand_inputfile_20240611_140203
-rw-rw-r-- 1 gpadmin gpadmin 3232 Jun 20 13:45 gpexpand_inputfile_20240620_134541
-rw-rw-r-- 1 gpadmin gpadmin 1072 Jun 20 13:50 gpexpand_inputfile_20240620_135048
-rw-rw-r-- 1 gpadmin gpadmin  540 Jun 20 15:29 gpexpand_inputfile_20240620_152924
[gpadmin@Master-a expand_segment_instance]$

再次重新数据重分布

验证下能否成功 分布到其他集群segement

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

[gpadmin@Master-a expand_segment_instance]$ gpexpand -d 1:00:00
20240620:15:37:51:009122 gpexpand:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:15:37:51:009122 gpexpand:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240620:15:37:51:009122 gpexpand:Master-a:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state
20240620:15:37:52:009122 gpexpand:Master-a:gpadmin-[INFO]:-Expanding test_database.public.table_test
20240620:15:37:58:009122 gpexpand:Master-a:gpadmin-[ERROR]:-Table test_database.public.table_test failed to expand: error 'ERROR:  Out of memory  (seg2 192.168.7.139:6000 pid=120056)
DETAIL:  VM protect failed to allocate 4194312 bytes from system, VM Protect 8130 MB available
' in 'ALTER  TABLE ONLY public.table_test EXPAND TABLE'
20240620:15:37:58:009122 gpexpand:Master-a:gpadmin-[INFO]:-Resetting status_detail for test_database.public.table_test
20240620:15:38:02:009122 gpexpand:Master-a:gpadmin-[WARNING]:-**************************************************
20240620:15:38:02:009122 gpexpand:Master-a:gpadmin-[WARNING]:-One or more tables failed to expand successfully.
20240620:15:38:02:009122 gpexpand:Master-a:gpadmin-[WARNING]:-Please check the log file, correct the problem and
20240620:15:38:02:009122 gpexpand:Master-a:gpadmin-[WARNING]:-run gpexpand again to finish the expansion process
20240620:15:38:02:009122 gpexpand:Master-a:gpadmin-[WARNING]:-**************************************************
20240620:15:38:02:009122 gpexpand:Master-a:gpadmin-[INFO]:-Exiting...
[gpadmin@Master-a expand_segment_instance]$ free -h
              total        used        free      shared  buff/cache   available
Mem:           1.8G        205M        784M        207M        828M        1.2G
Swap:          2.0G          0B        2.0G
[gpadmin@Master-a expand_segment_instance]$

主节点需要更多的内存，那我先重启下

关闭集群 调整内存 因为节点太多了 性能指定是不够了 升级一下物理内存吧

重启后提升内存不正常，还是需要回滚

硬做一下重分布
[gpadmin@Master-a expand_segment_instance]$ gpexpand -d 1:00:00
20240620:16:24:33:002641 gpexpand:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:16:24:33:002641 gpexpand:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240620:16:24:33:002641 gpexpand:Master-a:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state
20240620:16:24:34:002641 gpexpand:Master-a:gpadmin-[INFO]:-Expanding test_database.public.table_test
20240620:16:24:38:002641 gpexpand:Master-a:gpadmin-[INFO]:-Finished expanding test_database.public.table_test
20240620:16:24:38:002641 gpexpand:Master-a:gpadmin-[INFO]:-EXPANSION COMPLETED SUCCESSFULLY
20240620:16:24:38:002641 gpexpand:Master-a:gpadmin-[INFO]:-Exiting...
[gpadmin@Master-a expand_segment_instance]$

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

test_database=# 

重启集群

20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[INFO]:-   Segment Info
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[INFO]:-      Hostname                          = Segment-a
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[INFO]:-      Address                           = Segment-a
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[INFO]:-      Datadir                           = /home/gpadmin/data/primary/gpseg5
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[INFO]:-      Port                              = 6003
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[INFO]:-   Mirroring Info
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[INFO]:-      Current role                      = Mirror
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[INFO]:-      Preferred role                    = Primary
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[INFO]:-      Mirror status                     = Not In Sync
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[INFO]:-   Replication Info
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[WARNING]:-   WAL Sent Location                 = Unknown                              <<<<<<<<
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[WARNING]:-   WAL Flush Location                = Unknown                              <<<<<<<<
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[WARNING]:-   WAL Replay Location               = Unknown                              <<<<<<<<
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[INFO]:-   Status
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[WARNING]:-   PID                               = Not found                            <<<<<<<<
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[WARNING]:-   Configuration reports status as   = Down                                 <<<<<<<<
20240620:16:26:40:002755 gpstate:Master-a:gpadmin-[WARNING]:-   Segment status                    = Down in configuration                <<<<<<<<

解决内存不足导致数据故障的解决方法
解决方案就是 关闭集群 升级物理内存 然后把故障节点的segment-pri用 segment-mir 替换，通过 gprecoverseg 进行数据恢复 然后主节点 然后集群会提示有mri用于主节点的提示，再 通过-r 的方式转换数据 修复完成！
记录如下：


[gpadmin@Master-a gpseg-1]$ gprecoverseg -F
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Starting gprecoverseg with args: -F
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Heap checksum setting is consistent between master and the segments that are candidates for recoverseg
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Greenplum instance recovery parameters
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Recovery type              = Standard
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Recovery 1 of 1
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-   Synchronization mode                 = Full
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-   Failed instance host                 = Segment-a
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-   Failed instance address              = Segment-a
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-   Failed instance directory            = /home/gpadmin/data/primary/gpseg5
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-   Failed instance port                 = 6003
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-   Recovery Source instance host        = Segment-b
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-   Recovery Source instance address     = Segment-b
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-   Recovery Source instance directory   = /home/gpadmin/data/mirror/gpseg5
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-   Recovery Source instance port        = 7003
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-   Recovery Target                      = in-place
20240620:17:10:15:004521 gprecoverseg:Master-a:gpadmin-[INFO]:----------------------------------------------------------

Continue with segment recovery procedure Yy|Nn (default=N):
> y
20240620:17:10:18:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Starting to modify pg_hba.conf on primary segments to allow replication connections
20240620:17:10:28:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Successfully modified pg_hba.conf on primary segments to allow replication connections
20240620:17:10:28:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-1 segment(s) to recover
20240620:17:10:28:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Ensuring 1 failed segment(s) are stopped
20240620:17:10:28:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Ensuring that shared memory is cleaned up for stopped segments
20240620:17:10:28:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Validating remote directories
20240620:17:10:28:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Configuring new segments
Segment-a (dbid 7): pg_basebackup: base backup completed
20240620:17:10:30:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Updating configuration with new mirrors
20240620:17:10:30:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Updating mirrors
20240620:17:10:30:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Starting mirrors
20240620:17:10:30:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-era is 2dd251f5aa8fec81_240620170754
20240620:17:10:30:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Commencing parallel segment instance startup, please wait...
20240620:17:10:30:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Process results...
20240620:17:10:30:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Triggering FTS probe
20240620:17:10:30:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-******************************************************************
20240620:17:10:30:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Updating segments for streaming is completed.
20240620:17:10:30:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-For segments updated successfully, streaming will continue in the background.
20240620:17:10:30:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-Use  gpstate -s  to check the streaming progress.
20240620:17:10:30:004521 gprecoverseg:Master-a:gpadmin-[INFO]:-******************************************************************

[gpadmin@Master-a gpseg-1]$ gprecoverseg -r
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Starting gprecoverseg with args: -r
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Greenplum instance recovery parameters
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Recovery type              = Rebalance
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Unbalanced segment 1 of 2
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Unbalanced instance host        = Segment-b
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Unbalanced instance address     = Segment-b
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Unbalanced instance directory   = /home/gpadmin/data/mirror/gpseg5
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Unbalanced instance port        = 7003
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Balanced role                   = Mirror
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Current role                    = Primary
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Unbalanced segment 2 of 2
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Unbalanced instance host        = Segment-a
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Unbalanced instance address     = Segment-a
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Unbalanced instance directory   = /home/gpadmin/data/primary/gpseg5
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Unbalanced instance port        = 6003
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Balanced role                   = Primary
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Current role                    = Mirror
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[WARNING]:-This operation will cancel queries that are currently executing.
20240620:17:17:23:005214 gprecoverseg:Master-a:gpadmin-[WARNING]:-Connections to the database however will not be interrupted.

Continue with segment rebalance procedure Yy|Nn (default=N):
> y
20240620:17:17:25:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Getting unbalanced segments
20240620:17:17:25:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Stopping unbalanced primary segments...
20240620:17:17:25:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Triggering segment reconfiguration
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Starting segment synchronization
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-=============================START ANOTHER RECOVER=========================================
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Heap checksum setting is consistent between master and the segments that are candidates for recoverseg
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Greenplum instance recovery parameters
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Recovery type              = Standard
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Recovery 1 of 1
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Synchronization mode                 = Incremental
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Failed instance host                 = Segment-b
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Failed instance address              = Segment-b
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Failed instance directory            = /home/gpadmin/data/mirror/gpseg5
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Failed instance port                 = 7003
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Recovery Source instance host        = Segment-a
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Recovery Source instance address     = Segment-a
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Recovery Source instance directory   = /home/gpadmin/data/primary/gpseg5
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Recovery Source instance port        = 6003
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-   Recovery Target                      = in-place
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:----------------------------------------------------------
20240620:17:17:32:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Starting to modify pg_hba.conf on primary segments to allow replication connections
20240620:17:17:41:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Successfully modified pg_hba.conf on primary segments to allow replication connections
20240620:17:17:41:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-1 segment(s) to recover
20240620:17:17:41:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Ensuring 1 failed segment(s) are stopped
20240620:17:17:41:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Ensuring that shared memory is cleaned up for stopped segments
20240620:17:17:42:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Updating configuration with new mirrors
20240620:17:17:42:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Updating mirrors
20240620:17:17:42:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Running pg_rewind on required mirrors
20240620:17:17:42:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Starting mirrors
20240620:17:17:42:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-era is 2dd251f5aa8fec81_240620171117
20240620:17:17:42:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Commencing parallel segment instance startup, please wait...
20240620:17:17:42:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Process results...
20240620:17:17:42:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Triggering FTS probe
20240620:17:17:43:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-******************************************************************
20240620:17:17:43:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Updating segments for streaming is completed.
20240620:17:17:43:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-For segments updated successfully, streaming will continue in the background.
20240620:17:17:43:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Use  gpstate -s  to check the streaming progress.
20240620:17:17:43:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-******************************************************************
20240620:17:17:43:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-==============================END ANOTHER RECOVER==========================================
20240620:17:17:43:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-******************************************************************
20240620:17:17:43:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-The rebalance operation has completed successfully.
20240620:17:17:43:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-There is a resynchronization running in the background to bring all
20240620:17:17:43:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-segments in sync.
20240620:17:17:43:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-Use gpstate -e to check the resynchronization progress.
20240620:17:17:43:005214 gprecoverseg:Master-a:gpadmin-[INFO]:-******************************************************************
[gpadmin@Master-a gpseg-1]$ gpstate
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-Starting gpstate with args: 
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source'
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.13.0 build commit:4f1adf8e247a9685c19ea02bcaddfdc200937ecd Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Dec 18 2020 22:31:16'
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-Obtaining Segment details from master...
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-Gathering data from segments...
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-Greenplum instance status summary
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Master instance                                           = Active
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Master standby                                            = No master standby configured
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total segment instance count from metadata                = 40
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Primary Segment Status
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segments                                    = 20
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment valid (at master)                   = 20
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total primary segment failures (at master)                = 0
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 20
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 20
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 20
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes found                   = 20
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Mirror Segment Status
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total mirror segments                                     = 20
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total mirror segment valid (at master)                    = 20
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total mirror segment failures (at master)                 = 0
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 20
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 20
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 20
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number postmaster processes found                   = 20
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number mirror segments acting as primary segments   = 0
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Total number mirror segments acting as mirror segments    = 20
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-   Cluster Expansion                                         = In Progress
20240620:17:17:47:005379 gpstate:Master-a:gpadmin-[INFO]:-----------------------------------------------------
[gpadmin@Master-a gpseg-1]$ SSH connection has been disconnected.
```



## 实验五：通过expand进行缩容，并进行数据重分布

Loding ...

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