---
title: "Vulnlab - Easy - Lock"
date: 2025-11-05 12:00:00 -0700
categories: [CTF, Vulnlab]
tags: [windows]
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


## Foothold
## Lateral Movement / Privilege Escalation
## Root / SYSTEM
# Lessons Learned

