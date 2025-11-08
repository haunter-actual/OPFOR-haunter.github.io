---
title: "Offsec - PG Play - Easy - Amaterasu"
date: 2025-11-08 12:00:00 -0000
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

#### TCP/

## Foothold

## Lateral Movement / Privilege Escalation

## Root / SYSTEM

# Lessons Learned

