---
title: "Offsec - PG Play - Easy - Amaterasu"
date: 2025-11-08 00:00:00 -0700
categories: [CTF, offsec]
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

Performed some webdiscovery:

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/offsec/easy/Amaterasu]
└─$ feroxbuster --url http://$ama:33414 --depth 3 --wordlist /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do 
...
200      GET        1l       14w       98c http://192.168.227.249:33414/info
200      GET        1l       19w      137c http://192.168.227.249:33414/help
```

```bash
http://192.168.227.249:33414/info

["Python File Server REST API v2.5","Author: Alfredo Moroder","GET /help = List of the commands"]
```

```bash
http://192.168.227.249:33414/help

["GET /info : General Info","GET /help : This listing","GET /file-list?dir=/tmp : List of the files","POST /file-upload : Upload files"]
```

## Foothold

## Lateral Movement / Privilege Escalation

## Root / SYSTEM

# Lessons Learned

