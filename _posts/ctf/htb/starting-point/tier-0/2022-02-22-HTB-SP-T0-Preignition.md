---
title: "HTB Starting Point - Tier 0 - Preignition"
date: 2022-02-22 00:00:00 -0700
categories: [RedOps, ctf, HTB]
tags: [ctf, htb, RedOps, writeup, very_easy, preignition, web_enum, dirbuster, gobuster, default_creds]
---

![preignition](/assets/img/ctf/htb/sp/tier0/preignition/preignition.PNG)

## Introduction

Preignition is the final box in the Tier 0 series, and the 2nd of 2 VIP machines. This lab focuses on web enumeration/dir busting.

### tl;dr                                      
<details>                                                                                      
  <summary>Spoiler!</summary>                                                                  
                                                                                               
   1. The target hosts a webserver. Use `gobuster dir -u $target -w [WORDLIST] -x php` to enumerate PHP webpages. <br/>
   2. `/admin.php` is found. Navigate to `$target/admin.php` in-browser.<br/>          
   3. Search teh googles for `nginx default admin password`. The default cred pair is `admin:admin`.<br/>
   4. Login and retrieve the flag.<br/>
   5. <figure>![preignition](/assets/img/ctf/htb/sp/tier0/preignition/preignition.gif) <figcaption>Standard pre-ignition procedure.</figcaption></figure>
</details>      

## Establishing a Connection & Initial Scan

Spawn the bastard and get vpn going.

I've confirmed the target is reachable with a `ping`.

As with all other labs to now, start a scan and let it cook while we do the boring task stuff.

`nmap -v -T4 -A -oA recon/all $target`

![1nmap](/assets/img/ctf/htb/sp/tier0/preignition/1nmap.png)

## The Tasklist

### Task 1
#### What is considered to be one of the most essential skills to possess as a Penetration Tester?

The answer is `dir busting`, short for *directory busting*. This is an active recon technique that targets web servers with the intent of discovering directories/pages for potential exploitation.

### Task 2
#### What switch do we use for nmap's scan to specify that we want to perform version detection

`man nmap` shows us the following regarding version detection:

![2version](/assets/img/ctf/htb/sp/tier0/preignition/2version.png)

The switch in question is `-sV`.

> Note: the `-A` switch we have been using in our default scan includes version detection as well. However, `-A` contains other utilities that may be overkill for targeted scans. In those instances, specifying `-sV` for version detection would be more streamlined if that's all that is needed.

### Task 3
### What service type is identified as running on port 80/tcp in our nmap scan?

Our results show `http` is running on `80/tcp`.

### Task 4 
#### What service name and version of service is running on port 80/tcp in our nmap scan?

Results show the service name/version is `nginx 1.14.2`.

`nginx` is commonly used as a webserver solution. You can read moar about it [here](https://en.wikipedia.org/wiki/Nginx).


### Task 5
#### What is a popular directory busting tool we can use to explore hidden web directories and resources?

We can see what's currently installed on Kali as we did before by searching `/bin/` for the term `"bust"`

![3lsbust](/assets/img/ctf/htb/sp/tier0/preignition/3lsbust.png)

There are two options here:
1. `dirbuster`
2. `gobuster`

There are of course more options that are popular as well. For this lab, however, the answer will be `gobuster`.

### Task 6
#### What switch do we use to specify to gobuster we want to perform dir busting specifically?

Let's check with `man gobuster` WAIT VAT ZE FECK? 

![4gobusterhelp](/assets/img/ctf/htb/sp/tier0/preignition/4gobusterhelp.png)

1. `gobuster` doesn't have a man page! :(
2. Luckily, `--help` is always a viable alternative. You can also reference [this site](https://linuxcommandlibrary.com/man/gobuster) for man pages for tools.
3. Now that we can see the tool's syntax, we see that `dir` is the switch we need to include in our command for dir busting.
4. Take note that we can get specific command syntax with the formatting listed here. Example, `gobuster dir --help` will get you the specifc help page with additional `dir` details (see below image).

![4gobusterhelp2](/assets/img/ctf/htb/sp/tier0/preignition/4gobusterhelp2.png)

### Task 7
#### What page is found during our dir busting activities?

Now for the fun stuff. First, here's our command syntax per the man page:

`gobuster dir -u $target -w path/to/wordlist`


##### What the fuck is a wordlist? 

As the name may suggest, they are precompiled files full of words that can be used in automated recon and/or bruteforce tools.

![5wordlists](/assets/img/ctf/htb/sp/tier0/preignition/5wordlists.png)

1. Wordlists that are included in Kali are located in `/usr/share/wordlists`. 
2. There are different lists for different enumeration types or attacks. The two outlined here seem dir busting specific, so we will use lists from these. We will choose `dirb` first, for reasons.
3. Within `/dirb`, there are several wordlists. `common.txt` seems like a good first candidate.

Now that we have our wordlist picked, our revised command should look like this:

`gobuster dir -u $target -w /usr/share/wordlists/dirb/common.txt`

![6results](/assets/img/ctf/htb/sp/tier0/preignition/6results.png)

`gobuster` ran and found `/admin.php`.

### Task 8
#### What is the status code reported by gobuster upon finding a successful page?

The above image shows that status code `200` indicates the specified page was found.

### Task 9
####  Submit root flag

## Capturing the Flag

We now know two key pieces of intel:
1. `TARGET` hosts a webserver on `TCP/80`. That means we can use a web browser to view pages.
2. We know that there is a login page at `TARGET_IP/admin.php`. Sounds promising.

We navigate to the default landing page (enter the host's IP in the browser bar).

![7web1](/assets/img/ctf/htb/sp/tier0/preignition/7web1.png)

The above landing page is a default page for this webserver. This can indicate the webserver hasn't been configured too much yet...meaning there could be default configurations we can exploit.

Let's go to the `/admin.php` page we discovered with `gobuster`. Add the pagename to the end of the IP in the address bar.

![7web2](/assets/img/ctf/htb/sp/tier0/preignition/7web2.png)

We have an admin login page. 

Now there is a chance that default login credentials will work here. It seems like a simple server stood up without any changes yet.

![9defaultcreds](/assets/img/ctf/htb/sp/tier0/preignition/9defaultcreds.png)

A quick search shows that default login creds for admin on nginx is `admin/admin`. Let's try it :)

![8flag](/assets/img/ctf/htb/sp/tier0/preignition/8flag.png)

We have joy- default creds for admin let us right in. Grab teh flag & we have cleared Tier 0.

<figure>![preignition2](/assets/img/ctf/htb/sp/tier0/preignition/preignition2.gif) <figcaption>All systems green and on the rocks. Ready for takeoff!</figcaption></figure>

## Lessons Learned

* `gobuster` can be used to enumerate webservers for directories, pages, and moar. Login pages/admin consoles are HVTs
* wordlists for dirbusting, password cracking, etc. can be found in `/usr/share/wordlists`
* search application documention or OSINT for default creds

