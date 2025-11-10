---
layout: post
title: "HackTheBox - Starting Point - Tier 1 - Windows - Tactics"
date: 2022-03-16
categories: [ CTF, HackTheBox ]
tags: [windows, writeup, very easy, smb ]
---
![tactics](/assets/img/ctf/htb/sp/tier1/tactics/tactics.PNG)


## Introduction

Tactics is the last target in the tier 1 group. We'll be enumerating SMB again here.

### tl;dr                                                                                      
<details>                                                                                      
  <summary>Spoiler!</summary>                                                                  
 
   1. Scan with the `-Pn` switch.<br/>                                    
   2. Enumerate the `smb` shares with `smbclient -L $target -U Administrator` <br/>
   3. Connect to `//$target/C$` and navigate to the admin's desktop<br/>
   4. `GET flag.txt` and `cat` it locally <br/>                         
   <figure>![tactics](/assets/img/ctf/htb/sp/tier1/tactics/tactics.jpeg) <figcaption>*Insert Kira's theme from Deathnote*</figcaption></figure>
</details>

## Establishing a Connection & Initial Scan

Spawn the bastard and get vpn going.

I've confirmed the target is reachable with a `ping`.

Start the default `nmap` scan and let it run while we complete the tasklist.

## The Tasklist

### Task 1
#### Which Nmap switch can we use to enumerate machines when our packets are otherwise blocked by the Windows firewall?

![1nmap](/assets/img/ctf/htb/sp/tier1/tactics/1nmap.png)

Curiously, this is the first time our default scan returned ABSOLUTELY NOTHING.

Fortunately `nmap` offers a tip below to use the `-Pn` switch in this scenario.

Our modified `nmap` command now reads `nmap -Pn -A -v -T4 -oA recon/all $target`

![1Pnresults](/assets/img/ctf/htb/sp/tier1/tactics/1Pnresults.png)

We know have some intel :)

### Task 2
#### What does the 3-letter acronym SMB stand for?

`server message block`

### Task 3
#### What port does SMB use to operate at?

`445`

### Task 4 
#### What command line argument do you give to `smbclient` to list available shares?

We covered `smb` enumeration back in [Dancing](https://opfor-haunter.github.io/posts/HTB-SP-T0-Dancing/). 

`-L`

### Task 5
#### What character at the end of a share name indicates it's an administrative share?

`$`

### Task 6
#### Which Administrative share is accessible on the box that allows users to view the whole file system?

![2smbclient](/assets/img/ctf/htb/sp/tier1/tactics/2smbclient.png)

1. Firstly, we try to enumerate as was mentioned in Task 4. However, we did not have permissions to conduct discovery.
2. Using -U Administrator, we were then successfully able to enumerate the shares.

![2smbshare](/assets/img/ctf/htb/sp/tier1/tactics/2smbshare.png)

![2c](/assets/img/ctf/htb/sp/tier1/tactics/2c.png)

1. I was able to connect to each of the three shares, but `ADMIN$` and `IPC$` were dead ends.
2. `C$` was more lucrative.
3. `ls` showed this was the answer

### Task 7
#### What command can we use to download the files we find on the SMB Share?

`GET`

### Task 8
#### Which tool that is part of the Impacket collection can be used to get an interactive shell on the system?

Impacket has a script called `psexec.py`. It is an alternative to the `smbclient` session, but it is not needed here.

### Task 9
####  Submit root flag

## Capturing the Flag

![3flag](/assets/img/ctf/htb/sp/tier1/tactics/3flag.png)

1. We `cd` down to `Administrator`'s Desktop
2. `ls` reveals `flag.txt`
3. and we download it with `GET flag.txt`

![4cat](/assets/img/ctf/htb/sp/tier1/tactics/4cat.png)

Once we exit the smb session, we can `cat` the flag and call it a win.

 <figure>![tactics](/assets/img/ctf/htb/sp/tier1/tactics/tactics.gif) <figcaption>I use gorilla tictacs myself</figcaption></figure>

## Lessons Learned

* Impacket has a bunch of useful tools worth checking out
