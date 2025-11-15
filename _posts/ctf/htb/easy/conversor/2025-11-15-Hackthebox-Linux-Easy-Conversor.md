---
title: "HackTheBox - Linux - Easy - Conversor"
date: 2025-11-15 12:00:00 -0000
categories: [CTF, HackTheBox]
tags: [linux, easy]
---

![HackTheBox Conversor](/assets/img/ctf/htb/easy/conversor/conversor.png)

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
┌──(haunter㉿kali)-[~/working/htb/easy/conversor/
└─$ sudo nmap -A -p- -vvv -T3 --open -oN nmap_tcp_full $conversor
...
PORT   STATE SERVICE REASON         VERSION
22/tcp open  ssh     syn-ack ttl 63 OpenSSH 8.9p1 Ubuntu 3ubuntu0.13 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    syn-ack ttl 63 Apache httpd 2.4.52
    |_http-title: Did not follow redirect to http://conversor.htb/
```

Notable services:

#### 22/TCP - SSH

Nothing to do here besides bruteforce.

#### 80/TCP - HTTP

NMAP reported a redirect to *http://conversor.htb*. I added this entry to /etc/hosts and started some web discovery:

![conversor.htb login page](/assets/img/ctf/htb/easy/conversor/1.png)

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/conversor]                                                           
└─$ feroxbuster --url http://conversor.htb --depth 3 --wordlist /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do
...
http://conversor.htb/login
http://conversor.htb/register 
http://conversor.htb/about
http://conversor.htb/static/images/fismathack.png
http://conversor.htb/static/images/arturo.png
http://conversor.htb/static/images/david.png 
http://conversor.htb/static/source_code.tar.gz 
http://conversor.htb/convert
```

## Foothold

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/conversor]
└─$ tar -xvf source_code.tar.gz
app.py    
app.wsgi                                              
install.md                                            
instance/                                             
instance/users.db                                     
scripts/                                              
static/                                               
static/images/                                        
static/images/david.png                               
static/images/fismathack.png
static/images/arturo.png                              
static/nmap.xslt                                      
static/style.css                                      
templates/                                            
templates/register.html                               
templates/about.html                                  
templates/index.html                                  
templates/login.html                                  
templates/base.html                                   
templates/result.html                                 
uploads/            
```

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/conversor]
└─$ file instance/users.db 
instance/users.db: SQLite 3.x database

┌──(haunter㉿kali)-[~/working/htb/easy/conversor]
└─$ sqlite3 instance/users.db  
sqlite> .tables
sqlite> select * from users;
sqlite> select * from files;
```

## Lateral Movement / Privilege Escalation

## Root / SYSTEM
