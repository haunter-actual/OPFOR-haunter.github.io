---
title: "TryHackMe - Windows - Easy - Blueprint"
date: 2025-11-11 12:00:00 -0000
categories: [CTF, TryHackMe]
tags: [windows,easy]
---

![TryHackMe Blueprint](/assets/img/ctf/thm/easy/blueprint/blueprint.png))

# Initial Intel
* OS: Window
* Difficulty: Easy

# tl;dr
<details><summary>Spoilers</summary>
</details>

# Attack Path

## Recon

### Service Enumeration

Standard TCP scan to start:

```bash
┌──(haunter㉿kali)-[~/working/thm/easy/blueprint]                                                           └─$ nmap_tcp_full $blueprint

PORT      STATE SERVICE      REASON          VERSION
80/tcp    open  http         syn-ack ttl 125 Microsoft IIS httpd 7.5 
135/tcp   open  msrpc        syn-ack ttl 125 Microsoft Windows RPC 
139/tcp   open  netbios-ssn  syn-ack ttl 125 Microsoft Windows netbios-ssn
443/tcp   open  ssl/http     syn-ack ttl 125 Apache httpd 2.4.23 (OpenSSL/1.0.2h PHP/5.6.28)
445/tcp   open  microsoft-ds syn-ack ttl 125 Windows 7 Home Basic 7601 Service Pack 1 microsoft-ds
    | -     2019-04-11 22:52  oscommerce-2.3.4/
    | -     2019-04-11 22:52  oscommerce-2.3.4/catalog/
    | -     2019-04-11 22:52  oscommerce-2.3.4/docs/   
3306/tcp  open  mysql        syn-ack ttl 125 MariaDB (unauthorized)
8080/tcp  open  http         syn-ack ttl 125 Apache httpd 2.4.23 (OpenSSL/1.0.2h PHP/5.6.28)
```

### Notable services:

#### 80/TCP - HTTP

Found nothing with feroxbuster.

```bash
┌──(haunter㉿kali)-[~/working/thm/easy/blueprint]
└─$ whatweb $blueprint

http://10.201.75.197 [404 Not Found] Country[RESERVED][ZZ], HTTPServer[Microsoft-IIS/7.5], IP[10.201.75.197], Microsoft-IIS[7.5], Title[404 - File or directory not found.]
https://10.201.75.197 [200 OK] Apache[2.4.23], Country[RESERVED][ZZ], HTTPServer[Windows (32 bit)][Apache/2.4.23 (Win32) OpenSSL/1.0.2h PHP/5.6.28], IP[10.201.75.197], Index-Of, OpenSSL[1.0.2h], PHP[5.6.28], Title[Index of /]
```

#### 135/TCP - MSRPC

#### 139:445/TCP - SMB

```bash
┌──(haunter㉿kali)-[~/working/thm/easy/blueprint]
└─$ nxc smb $blueprint -u 'guest' -p '' -M spider_plus

SMB         10.201.75.197   445    BLUEPRINT        Share           Permissions     Remark
SMB         10.201.75.197   445    BLUEPRINT        -----           -----------     ------
SMB         10.201.75.197   445    BLUEPRINT        ADMIN$                          Remote Admin
SMB         10.201.75.197   445    BLUEPRINT        C$                              Default share
SMB         10.201.75.197   445    BLUEPRINT        IPC$                            Remote IPC
SMB         10.201.75.197   445    BLUEPRINT        Users           READ            
SMB         10.201.75.197   445    BLUEPRINT        Windows                         
```

![SMB Guest access](/assets/img/ctf/thm/easy/blueprint/2.png)



#### 443/TCP - SSL/HTTP

Could not find anything with feroxbuster.

┌──(haunter㉿kali)-[~/working/thm/easy/blueprint]
└─$ whatweb $blueprint:443
http://10.201.75.197:443 [400 Bad Request] Apache[2.4.23], Content-Language[en], Country[RESERVED][ZZ], Email[admin@example.com], HTTPServer[Windows (32 bit)][Apache/2.4.23 (Win32) OpenSSL/1.0.2h PHP/5.6.28], IP[10.201.75.197], OpenSSL[1.0.2h], PHP[5.6.28], Title[Bad request!]

#### 33306/TCP - MySQL

Can't connect to MySQL from $attacker. Might need to revisit once I get a foothold on $target.

```bash
┌──(haunter㉿kali)-[~/working/thm/easy/blueprint]
└─$ mysql -h $blueprint
ERROR 1130 (HY000): Host 'ip-10-21-42-165.ec2.internal' is not allowed to connect to this MariaDB server
```

#### 8080/TCP - HTTP

```bash
┌──(haunter㉿kali)-[~/working/thm/easy/blueprint]                                                           └─$ feroxbuster --url http://10.201.75.197:8080/oscommerce-2.3.4/ --depth 3 --wordlist /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log, htm,asp,do       

http://10.201.75.197:8080/oscommerce-2.3.4/docs/LICENSE
http://10.201.75.197:8080/oscommerce-2.3.4/docs/STANDARD
http://10.201.75.197:8080/oscommerce-2.3.4/docs/CHANGELOG
http://10.201.75.197:8080/oscommerce-2.3.4/catalog/login.php
```

*osCommerce 2.3.4*

![osCommerce 2.3.4 Exploit](/assets/img/ctf/thm/easy/blueprint/1.png)



## Foothold

## Lateral Movement / Privilege Escalation

## Root / SYSTEM

# Lessons Learned

