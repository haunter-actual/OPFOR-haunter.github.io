---
layout: post
title: "HackTheBox - Starting Point - Tier 1 - Crocodile"
date: 2022-03-01
categories: [ CTF, HackTheBox ]
tags: [ RedOps, writeup, very easy, crocodile, ftp, dirbust, gobuster ]
---
![crocodile](/assets/img/ctf/htb/sp/tier1/crocodile/crocodile.PNG)

## Introduction

This system is the third target in the Starting Point Tier 1 series. This machine features FTP.

### tl;dr                                      
<details>                                                                                      
  <summary>Spoiler!</summary>                                                                  
                                                                                               
   1. $target is running `FTP`. Connect and login as `anonymous` (no pass)<br/>
   2. `GET` the file `allowed.userlist`. This contains the password for `admin`<br/>          
   3. `dirbust` the $target to find the login.php page.<br/>
   4. Enter admin/password for the flag<br/>
   5. <figure>![crocodile](/assets/img/ctf/htb/sp/tier1/crocodile/crocodile.jpg) <figcaption></figcaption></figure>                                     
</details>      

## Establishing a Connection & Initial Scan

Spawn the bastard and get vpn going.

I've confirmed the target is reachable with a `ping`.

Start the default `nmap` scan and let it run while we complete the tasklist.

![1nmap](/assets/img/ctf/htb/sp/tier1/crocodile/1nmap.png)

## The Tasklist

### Task 1
#### What nmap scanning switch employs the use of default scripts during a scan?

`-sC`
 
### Task 2
#### What service version is found to be running on port 21?

Our scan indicates FTP is running, specifically `vsftpd 3.0.3`

### Task 3
#### What FTP code is returned to us for the "Anonymous FTP login allowed" message? 

![2ftpcon](/assets/img/ctf/htb/sp/tier1/crocodile/2ftpcon.png)

1. We initiate the FTP connection using `ftp $target`
2. Per our scan results, we know `Anonymous` login is allowed. We enter the `user` as such.
3. Login is successful, we are greeted with code `230`.
4. `ls` shows two files available locally. 

### Task 4 
#### What command can we use to download the files we find on the FTP server?

![3ftpget](/assets/img/ctf/htb/sp/tier1/crocodile/3ftpget.png)

1. The `get` command is used to retrieve files from the remote server to our localhost. Remember that files will be placed in the directory you were in when you initiated the FTP connection.
2. We download both files successfully.
3. `exit` the FTP session
 
### Task 5
#### What is one of the higher-privilege sounding usernames in the list we retrieved?

![4cat](/assets/img/ctf/htb/sp/tier1/crocodile/4cat.png)

We`cat` out both files. The `allowed.userlist` contains the username `admin` which is a HVT.

This also means we'll need to find a login page to try and get a foothold with the account.

### Task 6
#### What version of Apache HTTP Server is running on the target host?

![5apache](/assets/img/ctf/htb/sp/tier1/crocodile/5apache.png)

Our scan results list the version as `2.4.41`. Also, Apache runs PHP, so we are specifcally looking for a `php login page`.

### Task 7
#### What is the name of a handy web site analysis plug-in we can install in our browser?

`Wappalyzer`

### Task 8
#### What switch can we use with gobuster to specify we are looking for specific filetypes?

![6web](/assets/img/ctf/htb/sp/tier1/crocodile/6web.png)

In Task 6, we deduced that we'd need to find a PHP login page. Navigating to the website via browser does not seem to be a viable way to find a login page. Let's try to do some dirbusting using `gobuster`.

![7gobusterx](/assets/img/ctf/htb/sp/tier1/crocodile/7gobusterx.png)

Grepping the help page reveals that we can use the `-x` switch to look for filetypes with `gobuster`. 

![8gobuster](/assets/img/ctf/htb/sp/tier1/crocodile/8gobuster.png)

The completed command is `gobuser dir -u $target -w /usr/wordlists/dirb/common.txt -x php`

### Task 9
#### What file have we found that can provide us a foothold on the target?

![9gobusterresults](/assets/img/ctf/htb/sp/tier1/crocodile/9gobusterresults.png)

Gobuster found our `login.php` page :)

### Task 10
####  Submit root flag

## Capturing the Flag

![10login](/assets/img/ctf/htb/sp/tier1/crocodile/10login.png)

I navigated to the login page, and now we want to try to login using the `admin` username we found in the `allowed.userlist` file.

![10login2](/assets/img/ctf/htb/sp/tier1/crocodile/10login2.png)

The `allowed.userlist.passwd` file is relatively short so we can bruteforce every password value to see which works. I *think* the password values are in the same order to the usernames list. 

![10pass](/assets/img/ctf/htb/sp/tier1/crocodile/10pass.png)

In any case, the last password value is the correct one and will let us login as `admin` to the console.

![11flag](/assets/img/ctf/htb/sp/tier1/crocodile/11flag.png)

At last we have the flag.

<figure>![croc](/assets/img/ctf/htb/sp/tier1/crocodile/croc.gif) <figcaption>yayyy</figcaption></figure>

## Lessons Learned

* getting an initial foothold via one service may lead to an elevated foothold elsewhere (FTP -> web console in this case) 
