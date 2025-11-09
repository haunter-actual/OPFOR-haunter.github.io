---
title: "HackTheBox - Easy - Heist"
date: 2025-11-08 12:00:00 -0000
categories: [CTF, HackTheBox]
tags: [windows]
---

![Heist](/assets/img/ctf/htb/easy/heist/heist.png))

# Initial Intel
* Difficulty: Easy
* OS: Windows

# tl;dr
<details><summary>Spoilers</summary>
</details>

# Attack Path

## Recon

### Service Enumeration

Standard TCP scan to start:

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist]
└─$ nmap_tcp_full $heist  
...
PORT      STATE SERVICE       REASON          VERSION  
80/tcp    open  http          syn-ack ttl 127 Microsoft IIS httpd 10.0 
    | http-title: Support Login Page 
135/tcp   open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
445/tcp   open  microsoft-ds? syn-ack ttl 127
5985/tcp  open  http          syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP) 
49669/tcp open  msrpc         syn-ack ttl 127 Microsoft Windows RPC 
```

Notable services:

#### 80/tcp - HTTB

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist] feroxbuster --url http://$heist --depth 3 --wordlist /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do
```

http://10.10.10.149/login.php

![Webserver Login Page](/assets/img/ctf/htb/easy/heist/1.png)

Login Page, can login as 'guest'.

http://10.10.10.149/issues.php

![Guest login - Issues](/assets/img/ctf/htb/easy/heist/2.png)

Logged in as *guest*, issues with attachments upload feature.

http://10.10.10.149/attachments/config.txt

![Attachments - config.txt](/assets/img/ctf/htb/easy/heist/3.png)

*hazard* username. Also, context for *config.txt*:

```text
Hi, I've been experiencing problems with my cisco router. Here's a part of the configuration the previous admin had been using. I'm new to this and don't know how to fix it. :(
```

#### 445/tcp - SMB
```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist] 
└─$ enum4linux-ng -A $heist
...
SMB Dialect Check on 10.10.10.149   
    SMB 1.0: false  
    SMB 2.02: true
    SMB 2.1: true 
    SMB 3.0: true
    SMB 3.1.1: true

Domain Information via SMB session for 10.10.10.149
    NetBIOS computer name: SUPPORTDESK
    DNS domain: SupportDesk
    FQDN: SupportDesk
    Derived membership: workgroup member 
```



## Foothold

## Lateral Movement / Privilege Escalation

## Root / SYSTEM

# Lessons Learned

