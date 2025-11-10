---
layout: post
title: "HackTheBox -Starting Point - Tier 0 - Windows - Explosion"
date: 2022-02-08
categories: [ CTF, HackTheBox ] 
tags: [ windows, writeup, very easy, explosion, rdp, xfreerdp] 
---
![explosion](/assets/img/ctf/htb/sp/tier0/explosion/explosion.PNG)

## Introduction

Explosion is the ~~4th~~ 5th system (HTB keeps adding new machines) in the Tier 0 list, and the 1st of 2 VIP machines. `RDP` is the service theme here. 

### tl;dr                                      
<details>                                                                                      
  <summary>Spoiler!</summary>                                                                  
                                                                                               
   1. The target is running a `RDP` server<br/>
   2. using `xfreerdp`, we get several informative errors. We learn that we need `/cert:ignore` and `/u:administrator`<br/>          
   3. Connection is successful and the flag is on the desktop<br/>
   5. <figure>![explosion](/assets/img/ctf/htb/sp/tier0/explosion/explosion.gif)<figcaption>Goddamn it Moon Moon</figcaption></figure>
</details>      

## Establishing a Connection

Spawn the bastard and get vpn going.

I've confirmed the target is reachable with a `ping`.

## Initial Scan

`nmap -v -T4 -A -oA recon/all $target`
![1nmap](/assets/img/ctf/htb/sp/tier0/explosion/1nmap.png)


## The Tasklist

### Task 1
#### What does the 3-letter acronym RDP stand for?

`RDP` is short for **R**emote **D**esktop **P**rotocol. You can read moar about `RDP` <a href='https://www.ericom.com/whatis/rdp/#:~:text=RDP%20(Remote%20Desktop%20Protocol)%20is,ITU%20(International%20Telecommunications%20Union).'>here</a>.

### Task 2
#### What is a 3-letter acronym that refers to interaction with the host through a command line interface?

**C**ommand **L**ine **I**nterface is abbreviated to `cli`. The terminal window seen in most of my screenshots is a `cli` (see-el-eye, not the thing your girlfriend says you can never find).


### Task 3
### What about graphical user interface interactions?

Similary, **G**raphical **U**ser **I**nterface is abbreviated to `gui` (goo-ee, like that sock under your bed). Any program that utilzes preset menus / buttons in a visual manner, rather that terminal input, is using a `gui`.


### Task 4 
#### What is the name of an old remote access tool that came without encryption by default?

If you recall [Meow](https://opfor-haunter.github.io/posts/HTB-SP-T0-meow/), we used the `telnet` tool to connect to the target. `telnet` used to transmit data in-the-clear out of the box. Anyone that would be capturing packets would be able to see all data being transmitted...including passwords.


### Task 5
#### What is the concept used to verify the identity of the remote host with SSH connections?

`public-key cryptography` 

This is too complicated to cover here, so please reference the link [here](https://www.noppanit.com/posts/public-key-cryptography-for-dummies) if you need a primer. Also note that this concept is not limited to just SSH, but many forms of secure connection types. 

### Task 6
#### What is the name of the tool that we can use to initiate a desktop projection to our host using the terminal?

I assumed this was installed on Kali, but didn't know the name. A trick to find a tool that may contain some part you may know ("rdp" in this instance), is to search the `/bin/` directory.

The `/bin/` dir contains binaries (tools) , so we could run `ls /bin/*rdp*` to search for a possible tool. 

![2xfreerdp](/assets/img/ctf/htb/sp/tier0/explosion/2xfreerdp.png)

We found `xfreerdp`. This is our answer.

### Task 7
#### What is the name of the service running on port 3389 TCP?

![3service](/assets/img/ctf/htb/sp/tier0/explosion/3service.png)

`ms-webt-server`

### Task 8
#### What is the switch used to specify the target host's IP address when using xfreerdp?

Open up the man page. `man xfreerdp`

![4server](/assets/img/ctf/htb/sp/tier0/explosion/4server.png)

Right at the top we see the default command syntax. The `/v:server[:port]` portion seems promising. The terminology `server` is a bit off from `host's IP address`, but note Windows machines typically have a `RDP server` service built-in. That confirms this is the correct switch. 

`/v:`


### Task 9
####  Submit root flag

![5smb](/assets/img/ctf/htb/sp/tier0/explosion/5smb.png)

Based off our initial `nmap` scan, we know `RDP`(1) is open, but also `SMB`(2) on 445. Given that this machine is `RDP` oriented, this is unlikely to lead anywhere. However, it's good practice to explore for a glaring opening, and also reinforce what we learned in previous lessons.

![6smb](/assets/img/ctf/htb/sp/tier0/explosion/6smb.png)

As we thought, dead-end. No shares to plunder. On to `RDP`.


## Capturing the Flag

Let's try a simple connection to see if we get lucky. We will use the default values besides specifying our target server so we do not need to specify port.

`xfreerdp /v:$target`

![7rdpdefault](/assets/img/ctf/htb/sp/tier0/explosion/7rdpdefault.png)

A connection attempt is initiated. Two things to note:
1. As a username was not specified, the `RDP` session is trying to log us on the target system using our local username `haunter`. I doubt this will work without specifying an account that would be found on the target system.
2. we are prompted for `DOMAIN` and `PASSWORD`. 

Let's check back to our scan results.

![8rdpntlminfo](/assets/img/ctf/htb/sp/tier0/explosion/8rdpntlminfo.png)

The `DOMAIN` is listed here as `EXPLOSION`. Let's enter that but leave our password empty.

When we enter the info we get a lot of log data and the command terminates. There is too much info at once to easily parse.

 We'll take this time to create a log file and try again to see if we can get some insight on what went wrong.

![10log](/assets/img/ctf/htb/sp/tier0/explosion/10log.png)

1. We check the man pages for any built-in logging facilities with `man xfreerdp | grep log`. 
2. It looks like `xfreerdp` uses something called `wlog` to do so, and it actually tells us to run `man wlog` for details.

After reading the man page, we learn that we need to prepend the `xfreerdp` command with some values. They are the following:
* `WLOG_APPEND=file`
	*This tells wlog what we are to output the log to.
* `WLOG_LEVEL=ERROR`
	*This says to print log infos at the ERROR level and below (see the man page for details). Error messages should tell us what broke the connection attempt for us to fix.
* `WLOG_FILEAPPENDER_FILE_PATH=./`
	*This is the path to our log file. Using current working directory here.
* `WLOG_FILEAPPENDER_FILE_NAME=output.log`
	*The name of our log file.

![11logerror](/assets/img/ctf/htb/sp/tier0/explosion/11logerror.png)

1. The command now reads as
	* `WLOG_APPEND=file WLOG_LEVEL=ERROR WLOG_FILEAPPENDER_FILE_PATH=./ WLOG_FILE_APPENDER_FILE_NAME=output.log xfreerdp /v:$target`. We run the command and then output the contents. There are two ERRORS:
2. `ERRCONNECT_PASSWORD_CERTAINLY_EXPIRED`
	* We saw earlier that because we did not specify a user in the command, the session was attempting to log us into the remote target using our local user `haunter`. This error is likely a result of that as the account does not exist on the target or in the `EXPLOSION` domain. We'll need to specify a user next time. The man page shows that the `/u:USERNAME` flag will allow us to specify a user to login with. 
3. `SSL routines:ssl3_read_bytes...`
	* This looks like a certificate issue. Teh googles suggest trying the `/cert:ignore` flag to remedying this issue.

![12rdplogin](/assets/img/ctf/htb/sp/tier0/explosion/12rdplogin.png)

Now our revised command reads as follows:

`WLOG_APPEND=file WLOG_LEVEL=ERROR WLOG_FILEAPPENDER_FILE_PATH=./ WLOG_FILE_APPENDER_FILE_NAME=output.log xfreerdp /v:$target /cert:ignore /u:Administrator`

Note: I tried a few different default/built-in account names that Windows machines have baked in. In this instance, `Administrator` worked (see below) without a password.

![13flag](/assets/img/ctf/htb/sp/tier0/explosion/13flag.png)

Upon executing the command, we got in and we can see the flag on the desktop. With that, we can wrap this one up after submitting the value.

<figure>![explosion2](/assets/img/ctf/htb/sp/tier0/explosion/explosion2.gif)<figcaption>MRW submitting a flag</figcaption></figure>

## Lessons Learned

* `xfreerdp` can be used for `RDP` footholds. 
* `WLOG` facilities can be used to help troubleshoot connection issues
