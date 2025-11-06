---
title: "Vulnlab - Easy - Lock"
date: 2025-11-05 12:00:00 -0700
categories: [CTF, Vulnlab]
tags: [windows]
---

![Lock](/assets/img/ctf/vulnhub/easy/lock/lock.png))

# Initial Intel
* Difficulty: Easy
* OS: Windows

# tl;dr
<details><summary>Spoilers</summary>
</details>

# Attack Path

## Recon

### Service Enumeration

```bash
# set host & initiate a standard tcp scan
┌──(haunter㉿kali)-[~/working/vulnhub/easy/lock]
└─$ sudo nmap -A -p- -vvv -T3 --open -oN nmap_tcp_full $lock
...
PORT     STATE SERVICE       REASON          VERSION                                                        
80/tcp   open  http          syn-ack ttl 127 Microsoft IIS httpd 10.0                                    
    |_http-title: Lock - Index                            
445/tcp  open  microsoft-ds? syn-ack ttl 127
3000/tcp open  ppp?          syn-ack ttl 127
    <title>Gitea: Git with a cup of tea</title>
3389/tcp open  ms-wbt-server syn-ack ttl 127 Microsoft Terminal Services
    | rdp-ntlm-info:                                      
    |   Target_Name: LOCK                                 
    |   NetBIOS_Domain_Name: LOCK
    |   NetBIOS_Computer_Name: LOCK
    |   DNS_Domain_Name: Lock                             
    |   DNS_Computer_Name: Lock
    |   Product_Version: 10.0.20348
5357/tcp open  http          syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
5985/tcp open  http          syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
```

1. TCP/80 - Webserver
2. TCP/445 - SMB
3. TCP/3000 - ???/Git
4. TCP/3389 - RDP
5. TCP/5357 & 5985 - WinRM

#### TCP/80 - Webserver

![Webserver Landing Page](/assets/img/ctf/vulnhub/easy/lock/1.png)

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]          └─$ feroxbuster --url $lock --depth 3 --wordlist /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do


```

#### TCP/445 - SMB

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]          └─$ enum4linux-ng -A $lock   
...
NetBIOS computer name: LOCK 
NetBIOS domain name: ''
DNS domain: Lock
FQDN: Lock                                            
Derived membership: workgroup member
...
OS: Windows 10, Windows Server 2019, Windows Server 2016
OS version: '10.0'                                    
OS release: ''                                        
OS build: '20348'  

```

#### TCP/3000 - ???/Git

![Gitea Landing Page](/assets/img/ctf/vulnhub/easy/lock/2.png)


## Foothold
## Lateral Movement / Privilege Escalation
## Root / SYSTEM
# Lessons Learned

