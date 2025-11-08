---
title: "Offsec - PG Play - Easy - Amaterasu"
date: 2025-11-08 00:00:00 -0700
categories: [CTF, Offsec]
tags: [linux]
---

![Amaterasu](/assets/img/ctf/offsec/easy/amaterasu/amaterasu.png))

# Initial Intel
* Difficulty: Easy
* OS: Linux

# tl;dr
<details><summary>Spoilers</summary>
</details>

# Attack Path

## Recon

### Service Enumeration

Standard TCP scan to start:

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/offsec/easy/Amaterasu]      
└─$ nmap_tcp_full $ama
...
PORT      STATE SERVICE REASON         VERSION
21/tcp    open  ftp     syn-ack ttl 61 vsftpd 3.0.3
    | ftp-anon: Anonymous FTP login allowed (FTP code 230)
25022/tcp open  ssh     syn-ack ttl 61 OpenSSH 8.6 (protocol 2.0)
33414/tcp open  unknown syn-ack ttl 61
    Server: Werkzeug/2.2.3 Python/3.9.13 
40080/tcp open  http    syn-ack ttl 61 Apache httpd 2.4.53 ((Fedora))  
    |_http-title: My test page
```

Notable services:

#### 21/TCP - FTP
Anonymous is allowed. Could not list dir contents. No exploits found for version 3.0.3

#### 25022/TCP - SSH
No exploits found for OpenSSH 8.6. Need to enumerate usernames/passwords first.

#### 33414/TCP - Unknown / Webserver

Navigating to the port in-browser shows this is a webserver.

![Webserver](/assets/img/ctf/offsec/easy/amaterasu/1.png)

Performed some web discovery:

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/offsec/easy/Amaterasu]
└─$ feroxbuster --url http://$ama:33414 --depth 3 --wordlist /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do 
...
200      GET        1l       14w       98c http://192.168.227.249:33414/info
200      GET        1l       19w      137c http://192.168.227.249:33414/help
```

Looks like we have an API we may be able to manipulate.

```bash
http://192.168.227.249:33414/info

["Python File Server REST API v2.5","Author: Alfredo Moroder","GET /help = List of the commands"]
```

```bash
http://192.168.227.249:33414/help

["GET /info : General Info","GET /help : This listing","GET /file-list?dir=/tmp : List of the files","POST /file-upload : Upload files"]
```

*GET /file-list?dir=/tmp* looks abusable, as does *POST /file-upload : Upload files*. I'll try to see if they are exploitable:

![GET /file-list?dir=/tmp](/assets/img/ctf/offsec/easy/amaterasu/2.png)

Nice. It looks like I can perform directory traversal and get some intel.

![/home directory](/assets/img/ctf/offsec/easy/amaterasu/3.png)

![/home/alfredo directory](/assets/img/ctf/offsec/easy/amaterasu/4.png)

There's a user *alfredo*. I'll add him to a *users.txt* file.

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/offsec/easy/Amaterasu]
└─$ echo "alfredo" > users.txt
```



## Foothold

## Lateral Movement / Privilege Escalation

## Root / SYSTEM

# Lessons Learned

