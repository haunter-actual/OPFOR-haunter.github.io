---
layout: post
title: "HackTheBox - Starting Point - Tier 0 - Fawn"
date: 2022-02-04
categories: [ CTF, HackTheBox]
tags: [RedOps, writeup, very easy, ftp,fawn]
---
![fawn](/assets/img/ctf/htb/sp/tier0/fawn/fawn.PNG)

## Introduction

Fawn is the second in the Tier 0 Starting Point machines. This is another educational system, so I will cover the commands in-depth than I will in future machines, but will build off knowledge from the previous machine, Meow.

### tl;dr
<details>
  <summary>Spoiler!</summary>
  
  1. `FTP` to target.<br/>
  2. username "anonymous". <br/>
  3. `GET` flag to localhost.<br/>
  4. ????<br/>
  5. <figure>![fawn](/assets/img/ctf/htb/sp/tier0/fawn/fawn.webp)<figcaption>sometimes it do be like that </figcaption></figure>
</details>



## Establishing a Connection

Spawn the bastard and get vpn going.

![The host machine IP](/assets/img/ctf/htb/sp/tier0/fawn/1ip.PNG)

I've confirmed the target is reachable with a `ping`.

## Initial Scan

Unlike the last machine, let's do our default `nmap` scan now and store the results in `recon/all` again and move on to the tasklist.


## The Tasklist

### Task 1
#### What does the 3-letter acronym FTP stand for? 
The next couple of questions are related to `FTP`. Let's run `man ftp | less`.

![4manftp](/assets/img/ctf/htb/sp/tier0/fawn/4manftp.PNG)

We can see the description for `FTP` is 'an internet file transfer program'. However, the answer we are looking for is further on and is `File Transfer Protocol`.

### Task 2
#### What communication model does FTP use, architecturally speaking? 
FTP uses the `client-server model`. In this model, `clients` typically are endpoint systems used by people to conduct tasks and look at Reddit. `Servers` can also be endpoint systems, but are typically standalone systems that run the `FTP service` for `client(s)` to connect and upload/download files. 

### Task 3
#### What is the name of one popular GUI FTP program?
`FileZilla` is a widely used GUI FTP program. 

### Task 4 
#### Which port is the FTP service active on usually?
`FTP` runs off `port 23/TCP` by default.

### Task 5
#### What acronym is used for the secure version of FTP? 
Secure FTP is known as `SFTP`. Crazy right?

## Our First Scan
### Task 6
#### What is the command we can use to test our connection to the target?
We should already know that this tool is the `ping` command.

### Task 7
#### From your scans, what version is FTP running on the target?
Let's take a look at our scan results from earlier (remember you can use `cat [filename] | less` to print the contents of a file in a paginated fashion if you stored your results in a file).

![3nmap](/assets/img/ctf/htb/sp/tier0/fawn/3nmap.PNG)

We ran 	`nmap` with the `-A` flag earlier, which runs service detection (among other things).

We always want to pay attention to the section below that details detected services and ports:

![5nmap_service](/assets/img/ctf/htb/sp/tier0/fawn/5nmap_service.PNG)

It looks like the service `vsftpd` is running version `3.0.3`.

### Task 8
### From your scans, what OS type is running on the target?
At the bottom of our scan results, we have data labeled `Service Info`. The OS is detailed as `Unix`.

### Task 9
####  Submit root flag
Now we have to get the flag, let's review some important info:
![6ftp](/assets/img/ctf/htb/sp/tier0/fawn/6ftp.PNG)

What do we know?
* `flag.txt` is located on teh FTP server.
* The `FTP` service allows `anonymous logins`.

Anon login is good to see. Let's try to connect.

![7ftp_attempt](/assets/img/ctf/htb/sp/tier0/fawn/7ftp_attempt.PNG)

I tried authenticating without entering a username or password. This is clearly not what `anonymous` login means. Shit.

Whever you need info, always check the tools `man` pages first.

We are searching for the string `"user"` in a hope that there will be a command filter or flag related to logging in with a user account, and any special syntax needed for the command.

![10manuser](/assets/img/ctf/htb/sp/tier0/fawn/10manuser.png)

We run `man` for `ftp` (1), but for the sake of expediency we then pipe the output and use `grep` to search through the output for the term `"user" (2)`. `grep` is an extremely useful tool used for searching for patterns, and this is a very basic use case involving a simple string. 
At the bottom of our filtered output (3), we can see that there is an FTP-specific command `user`. This command is entered on the ftp interface and will then prompt for a username to login with. 

With that knowledge, let's give it a try:

![8ftp_success](/assets/img/ctf/htb/sp/tier0/fawn/8ftp_success.png)

1. We enter the `user` command at the `ftp` input prompt.
2. The prompt then asks for a username, we enter `anonymous` and do not enter a password.
3. We have joy- we are now on the FTP server.


## Capturing the Flag
![9get_flag](/assets/img/ctf/htb/sp/tier0/fawn/9get_flag.png)

1. First thing to do is look at our current directory with `ls`. There is one file listed- our `flag.txt`. 
2. If you try to `cat` the contents of the `flag.txt` file, you may get an error. Remember that some tools that are available on your local system may not be installed on a remote system. We use `get flag.txt` to download the file to oour local system in this case.
3. The file downloads successfully, let's get the contents.
4. Use the `exit` command to terminate the FTP session
5. With a local `ls`, we see that `flag.txt` was downloading in the directory we initiated the FTP session in.
6. We `cat` the flag and have owned `Fawn` successfully.

<figure>![fawn](/assets/img/ctf/htb/sp/tier0/fawn/fawn.gif)<figcaption>HAUNTER's first foothold attempts, colorized 2022 </figcaption></figure>

## Lessons Learned

* `Anonymous FTP allowed` on an `nmap` scan is a good potential foothold vector

