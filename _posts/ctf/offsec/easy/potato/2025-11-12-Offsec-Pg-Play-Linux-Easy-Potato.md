---
title: "OffSec - PG Play - Linux - Easy - Potato"
date: 2025-11-12 12:00:00 -0000
categories: [CTF, OffSec PG Play]
tags: [linux, easy]
---

![OffSec PG Play Potato](/assets/img/ctf/offsec/easy/potato/potato.png)

# Initial Intel
* OS: Linux
* Difficulty: Easy

# tl;dr
<details><summary>Spoilers</summary>
</details>

# Attack Path

## Recon

### Service Enumeration

Standard TCP scan to start:

```bash
┌──(haunter㉿kali)-[~/working/offsec/easy/potato/
└─$ sudo nmap -A -p- -vvv -T3 --open -oN nmap_tcp_full $potato
...
PORT     STATE SERVICE REASON         VERSION
22/tcp   open  ssh     syn-ack ttl 61 OpenSSH 8.2p1 Ubuntu 4ubuntu0.1 (Ubuntu Linux; protocol 2.0) 
80/tcp   open  http    syn-ack ttl 61 Apache httpd 2.4.41 ((Ubuntu)) 
    |_http-title: Potato company 
2112/tcp open  ftp     syn-ack ttl 61 ProFTPD
    | ftp-anon: Anonymous FTP login allowed (FTP code 230)    
```

Notable services:

#### 22/TCP - SSH

Nothing to exploit here yet.

#### 80/TCP - HTTP

```bash
┌──(haunter㉿kali)-[~/working/offsec/easy/potato]
└─$ feroxbuster --url http://$potato --depth 3 --wordlist /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do
```

http://192.168.143.101/

![Potato Company landing page](/assets/img/ctf/offsec/easy/potato/3.png)

No interactive features or interesting intel found.

http://192.168.143.101/potato.png

![Sexy potato](/assets/img/ctf/offsec/easy/potato/potato.jpg)

I tried to see if there was any steg data in this picture, but it appears to be just a sexy potato.

```bash
┌──(haunter㉿kali)-[~/working/offsec/easy/potato]
└─$ stegseek potato.jpg 
StegSeek 0.6 - https://github.com/RickdeJager/StegSeek

[i] Progress: 99.72% (133.1 MB)           
[!] error: Could not find a valid passphrase.
```

http://192.168.143.101/admin/

![Admin login page](/assets/img/ctf/offsec/easy/potato/3.png)

I'll try to bruteforce this later if I can't find creds.


http://192.168.143.101/admin/logs/

![Admin logs](/assets/img/ctf/offsec/easy/potato/4.png)



#### 2121/TCP - FTP

Anonymous login allowed.

```bash
┌──(haunter㉿kali)-[~/working/offsec/easy/potato]                                                           └─$ ftp anonymous@$potato -p 2112                                                                       
Connected to 192.168.143.101.       
220 ProFTPD Server (Debian) [::ffff:192.168.143.101]                                                        331 Anonymous login ok, send your complete email address as your password                                                                                                                                           
Password:                                                                                                   
230-Welcome, archive user anonymous@192.168.45.162 !

ftp> dir
229 Entering Extended Passive Mode (|||52521|)
150 Opening ASCII mode data connection for file list
-rw-r--r--   1 ftp      ftp           901 Aug  2  2020 index.php.bak
-rw-r--r--   1 ftp      ftp            54 Aug  2  2020 welcome.msg

ftp> get index.php.bak                                                                                                                                                                                                  local: index.php.bak remote: index.php.bak                                                                                                                                                                          
229 Entering Extended Passive Mode (|||35404|)                                                              
150 Opening BINARY mode data connection for index.php.bak (901 bytes)                                       
   901        2.54 MiB/s                                                                                    
226 Transfer complete      
```

I logged in and retrieved the two files available. *index.php.bak* had some intel:

```bash
┌──(haunter㉿kali)-[~/working/offsec/easy/potato] 
└─$ cat index.php.bak
```

![index.php.bak password](/assets/img/ctf/offsec/easy/potato/1.png)

```bash
<?php                                                 
                           
$pass= "potato"; //note Change this password regularly                                      
                                                                                                            
if($_GET['login']==="1"){                             
  if (strcmp($_POST['username'], "admin") == 0  && strcmp($_POST['password'], $pass) == 0) {
    echo "Welcome! </br> Go to the <a href=\"dashboard.php\">dashboard</a>";                   
    setcookie('pass', $pass, time() + 365*24*3600);
  }else{                                              
    echo "<p>Bad login/password! </br> Return to the <a href=\"index.php\">login page</a> <p>";
  }                                                   
  exit();                                             
}                                                     
?>           
```

There's a password *potato* listed. I'll throw that in *passwords.txt* and see if it can be used anywhere.

## Foothold

## Lateral Movement / Privilege Escalation

## Root / SYSTEM
