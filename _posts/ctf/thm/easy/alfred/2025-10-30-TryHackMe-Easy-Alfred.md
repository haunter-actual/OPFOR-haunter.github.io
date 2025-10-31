---
title: "TryHackMe - Easy - Alfred"
date: 2025-10-24 12:00:00 -0700
categories: [CTF,TryHackMe]
tags: [windows, webapp]
---

![Alfred](/assets/img/ctf/thm/easy/alfred/alfred.png)

# Initial Intel
* Difficulty: Easy
* OS: Windows

# tl;dr
<details><summary>Spoilers</summary>
* Enumerate the webapp for unique files, notably a page called 'mini.php'. It is a webshell<br/>
* Either enter a command or upload a php rev shell to get a foothold<br/>
* Enumerate other users on the system, then try to bruteforce their passwords with a tool such as nxc against ssh<br/>
* Check sudo permissions, then check GTFOBins for a privEsc exploit<br/>
</details>

# Attack Path

## Recon

### Service Enumeration

Let's start off with a basic TCP scan. If we can't find anything we can later run a UDP scan.

```bash
# set host & initiate a standard tcp scan
┌──(haunter㉿kali)-[~/working/offsec/easy/FunBoxEasyEnum]
└─$ sudo nmap -A -p- -vvv -T3 --open -oN nmap_tcp_full $alfred
```

Host appears unreachable, I added the -Pn flag in case ICMP is being dropped:

```bash
┌──(haunter㉿kali)-[~/working/thm/easy/alfred]
└─$ sudo nmap -A -p- -vvv -T3 --open -oN nmap_tcp_full -Pn $alfred 

80/tcp   open  http               syn-ack ttl 125 Microsoft IIS httpd 7.5                                   
3389/tcp open  ssl/ms-wbt-server? syn-ack ttl 125                                                           rdp-ntlm-info:                                      
|   Target_Name: ALFRED                               
|   NetBIOS_Domain_Name: ALFRED
|   NetBIOS_Computer_Name: ALFRED
|   DNS_Domain_Name: alfred
|   DNS_Computer_Name: alfred
8080/tcp open  http               syn-ack ttl 125 Jetty 9.4.z-SNAPSHOT
| http-robots.txt: 1 disallowed entry                                                 
|_http-server-header: Jetty(9.4.z-SNAPSHOT)
```

There we go, we have three ports open: 2 webservers on :80 and :8080, and RDP on :3389.

I started with walking the two webapps.

### Webserver on TCP/80

![Landing page on port 80](/assets/img/ctf/thm/easy/alfred/1.png)

The site appears to be a single page with no interactive features. I checked the page source and found nothing of value. Additionally, I performed directory and file discovery with *feroxbuster* but found no other pages or directories on this port.

The page does potentially show two users, *bruce* and *alfred*. I recorded these in *users.txt* for potential use later.

```bash
┌──(haunter㉿kali)-[~/working/thm/easy/Alfred]
└─$ cat users.txt 
alfred
bruce
```

### Webserver on TCP/8080

I then moved to walk the other webserver on :8080

![Landing page for webserver on port 8080](/assets/img/ctf/thm/easy/alfred/2.png)

I tried to login using the potential usernames from earlier using combos as *bruce:bruce* and *alfred:bruce* as Jenkins documentation states that the default password is either created on setup or randomized. Bruteforcing may be an option if I can't find a path forward after further enum.

I tried to do some discovery:

```bash
┌──(haunter㉿kali)-[~/working/thm/easy/Alfred]                                                              └─$ feroxbuster --url http://$alfred:8080 --depth 2 --wordlist /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do
 ___  ___  __   __     __      __         __   ___                                                          
|__  |__  |__) |__) | /  `    /  \ \_/ | |  \ |__                                                           
|    |___ |  \ |  \ | \__,    \__/ / \ | |__/ |___                                                          
by Ben "epi" Risher 🤓                 ver: 2.10.4                                                          
───────────────────────────┬──────────────────────                                                          
 🎯  Target Url            │ http://10.201.11.17:8080                                                       
 🚀  Threads               │ 50                                                                             
 📖  Wordlist              │ /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt      
 💢  Status Code Filters   │ [404]                                                                          
 💥  Timeout (secs)        │ 7                                                                              
 🦡  User-Agent            │ feroxbuster/2.10.4                                                             
 💉  Config File           │ /etc/feroxbuster/ferox-config.toml                                             
 🔎  Extract Links         │ true                                                                           
 💲  Extensions            │ [php, sh, txt, cgi, html, js, css, py, zip, aspx, pdf, docx, doc, md, log, htm, asp, do]
...
200      GET        3l       13w       71c http://10.201.11.17:8080/robots.txt
```

![Port 8080 robots.txt](/assets/img/ctf/thm/easy/alfred/3.png)

Found *robots.txt* which unfortunately didn't have any intel of value.

Since nothing else popped up with *feroxbuster*, I went back to the webserver stack to see if I could find anyhing exploitable. I used *Wappalyzer* and *whatweb*:

```bash
┌──(haunter㉿kali)-[~/working/thm/easy/Alfred]
└─$ whatweb http://$alfred:8080
http://10.201.11.17:8080 [403 Forbidden] Cookies[JSESSIONID.ee8d63dc], Country[RESERVED][ZZ], HTTPServer[Jetty(9.4.z-SNAPSHOT)], HttpOnly[JSESSIONID.ee8d63dc], IP[10.201.11.17], Jenkins[2.190.1], Jetty[9.4.z-SNAPSHOT], Meta-Refresh-Redirect[/login?from=%2F], Script, UncommonHeaders[x-content-type-options,x-hudson,x-jenkins,x-jenkins-session,x-you-are-authenticated-as,x-you-are-in-group-disabled,x-required-permission,x-permission-implied-by]
http://10.201.11.17:8080/login?from=%2F [200 OK] Cookies[JSESSIONID.ee8d63dc], Country[RESERVED][ZZ], HTML5, HTTPServer[Jetty(9.4.z-SNAPSHOT)], HttpOnly[JSESSIONID.ee8d63dc], IP[10.201.11.17], Jenkins[2.190.1], Jetty[9.4.z-SNAPSHOT], PasswordField[j_password], Script[text/javascript], Title[Sign in [Jenkins]], UncommonHeaders[x-content-type-options,x-hudson,x-jenkins,x-jenkins-session,x-instance-identity], X-Frame-Options[sameorigin]
```

There are two web technologies that stand out:
* Jenkins[2.190.1]
* Jetty[9.4.z-SNAPSHOT]



## Foothold

### Foothold Recon

## Lateral Movement / Privilege Escalation

## Root / SYSTEM

# Lessons Learned

