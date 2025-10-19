---
layout: post
title: "HackTheBox - Starting Point - Tier 0 - Dancing"
date: 2022-02-07
categories: [ [, CTF, HackTheBox] ]
tags: [ [RedOps, writeup, very_easy, smb, dancing, ] ]
---

![dancing](/assets/img/ctf/htb/sp/tier0/dancing/dancing.PNG)


## Introduction

`Dancing` is the host we are targeting this time. It looks like `SMB` will be the theme of the day. 

### tl;dr                                      
<details>                                                                                      
  <summary>Spoiler!</summary>                                                                                                                                                                  
  <p>
  1. SMB shares are available on the target.<br/>
  2. List available shares with `smbclient -L $target`.<br/> 
  3. Attempt to connec to each share with `smbclient //$target/SHARE_NAME`. Success with `WorkShares`.<br/>

  4. `ls` into James.P's stupid drive and `get` the flag.<br/>
  5. ???<br/>
  6.  <figure>![dancing](/assets/img/ctf/htb/sp/tier0/dancing/dancing.gif)<br/><figcaption>sometimes you just gotta </figcaption></figure>
  </p>                                 
</details>      

## Establishing a Connection

Spawn the machine, test reachability, and start the default `nmap` scan.

## Initial Scan

![2nmapall](/assets/img/ctf/htb/sp/tier0/dancing/2nmapall.png)



## The Tasklist

### Task 1
#### What does the 3-letter acronym SMB stand for? 

`SMB` stands for **S**erver **M**essage **B**lock.

### Task 2
#### What port does SMB use to operate at?

Some googling shows that `SMB` uses `port 445`by default.

### Task 3
#### What network communication model does SMB use, architecturally speaking? 

Simiarly to `FTP`, `SMB` uses the `Client-Server model`. A standalone system, the server, will run the `SMB` service. `Clients` will connect to transfer/receive data, including filesharing and print data.

### Task 4 
#### What is the service name for port 445 that came up in our nmap scan?

Here's our service info:

![3nmap_services](/assets/img/ctf/htb/sp/tier0/dancing/3nmap_services.png)

`Port 445` has the `microsoft-ds` service. The [Microsoft Directory Service](https://www.grc.com/port_445.htm) is used primarily for file transfer over the network and printing services. There are currently three versions SMB, with SMBv1 being a notoriously insecure version that can be easily exploited.

### Task 5
#### What is the tool we use to connect to SMB shares from our Linux distribution?

Let's see what tools may be available that could be the answer.

I typed in `smb` and hit `TAB`. This is lets the terminal use autocomplete, and it will list any matching commands.

![4smb](/assets/img/ctf/htb/sp/tier0/dancing/4smb.png)

We learned earlier that `SMB` uses a `client-server model`. The `smbclient` tool seems to be the correct tool for us to use in order to connect to the server.

### Task 6
#### What is the `flag` or `switch` we can use with the SMB tool to `list` the contents of the share?

Time to **man**-up again. GET IT?! 

`man smbclient | grep list`

![5smb_ls](/assets/img/ctf/htb/sp/tier0/dancing/5smb_ls.png)

Recall that the `|` (read: "pipe") operator will redirect the output of the command to the left (`man smbclient`) to the command on the right (`grep list`). Also, recall that `grep` is a pattern-searching tool used to sift through output for a match. In this case, we are looking for any matches to the string "list".

We find that the `-L` switch is what we are looking for.

### Task 7
#### What is the name of the share we are able to access in the end?

Now it's time to access the target. 

`smbclient -L $target`
![6smb_L](/assets/img/ctf/htb/sp/tier0/dancing/6smb_L.png)

There are 4 listed shares:
* `ADMIN$`
* `C$`
* `IPC$`
* `WorkShares`

We'll try 'em all.

The syntax for connecting follows the following format:

`smbclient \\\\$target\\SHARE_NAME`

Notes:
* `\\\\$target` There are 4 backslash (`\`) characters at the begining of the server string we are connecting to. Due to Unix-style shells interpreting a single `\` character as an **escape character**, we need to double them to prepresent `\\$target`.
*  For this same reason, the `\\SHARE_NAME` portion of the the string equates to `\SHARE_NAME` with the shell translation in mind.
* We can actually use forward slashes (`/`) instead without worrying about escapecharacters. The syntax would be `//$target/SHARE_NAME`. We use `\` here for a lesson on escaping. 

![7smb_connect](/assets/img/ctf/htb/sp/tier0/dancing/7smb_connect.png)

1. `ADMIN$` - we get an `NT_STATUS_ACCESS_DENIED` here. No joy.
2. `C$` - same news `NT_STATUS_ACCESS_DENIED`, No joy.
3. `IPC$` - we actually have a connection! HOWEVER, we have a problem running command `ls`. We get `NT_STATUS_INVALID_INFO_CLASS`. Technically, this means the share isn't configured for the data we are transmitting, but we can chalk this up as a dead-end for now.
4. `WorkShares` - We have joy! Got a connection and are able to run commands. We run `ls` and see two folders here, **Amy.J** and **James.P**.


### Task 8
#### What is the command we can use within the SMB shell to download the files we find? 

![9smbflag](/assets/img/ctf/htb/sp/tier0/dancing/9smbflag.png)

Let's find the flag to download. 

1. `ls Amy.J\` - We check the contents of the first folder. There is only the file `worknotes.txt`. Not what we need.
2. `ls James.P\` - there is the `flag.txt`.
3. Our answer for this task is `get`. We run `get James.P\flag.txt` to initiate the download to the local directory we were in when we launched the `smbclient` tool.
4. We exit the `smbclient` session.

### Task 9
####  Submit root flag
Now back in our local session, we find the flag we downloaded and `cat` out the value. And now `Dancing` has been owned (#5 in the image above).

<figure>![goths](/assets/img/ctf/htb/sp/tier0/dancing/goths.gif)<figcaption>Let me show you the dance of my people.</figcaption></figure>

## Lessons Learned

* `SMB` can be enumerated using `smbclient -L $target`
* the `$` symbol on shares **typically** indicates that the share will require admin privileges to access
* files can be retrieved from the `$target` to our `localhost` for potential lateral or privec
