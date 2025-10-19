---
layout: post
title: "HTB Starting Point - Tier 1 - Ignition"
date: 2022-03-02
categories: [ RedOps, ctf, HTB ]
tags: [ ctf, htb, RedOps, writeup, very_easy, ignition, bruteforce ]
---
![ignition](/assets/img/ctf/htb/sp/tier1/ignition/ignition.PNG)

## Introduction

This is the 4th box in the Tier 1 series. This machine touches the topics of redirects and bruteforcing a web login, similarly to its prequel [preignition](https://opfor-haunter.github.io/posts/HTB-SP-T0-Preignition/) from Tier 0.

### tl;dr                                      
<details>                                                                                      
  <summary>Spoiler!</summary>                                                                  
                                                                                               
   1. Enumerate via dirbusting to find the login page.<br/>
   2. Edit the `/etc/hosts/` file to resolve to `ignition.htb` <br/>
   3. Search for Magento default creds to login and get the flag.<br/>
   4. <figure>![ignition](/assets/img/ctf/htb/sp/tier1/ignition/ignition.gif) <figcaption>Reminds me of lighting my first gas BBQ grill</figcaption></figure>                                     
</details>      

## Establishing a Connection & Initial Scan

Spawn the bastard and get vpn going.

I've confirmed the target is reachable with a `ping`.

Start the default `nmap` scan and let it run while we complete the tasklist.

![1nmap](/assets/img/ctf/htb/sp/tier1/ignition/1nmap.png)

## The Tasklist

### Task 1
#### Which service version is found to be running on port 80?

Our scan above shows `nginx 1.14.2` on port 80. This is a webserver, so there is a webpage we can visit via a browser.

### Task 2
#### What is the 3-digit HTTP status code returned when you visit http://{machine IP}/?

![2notfound](/assets/img/ctf/htb/sp/tier1/ignition/2notfound.png)

Well when we try to browse to the webpage, we get a *Server Not Found* error but I don't see an error code. 

![3wget](/assets/img/ctf/htb/sp/tier1/ignition/3wget.png)

Using `wget` to fetch the page, however, does report back error code `302`. According to [this KB entry](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/302), this code indicates a redirect is in place.

### Task 3
#### What is the virtual host name the webpage expects to be accessed by?

The same `wget` result shows `ignition.htb` is the host.

### Task 4 
#### What is the full path to the file on a Linux computer that holds a local list of domain name to IP address pairs?

![5ping](/assets/img/ctf/htb/sp/tier1/ignition/5ping.png)

1. `pinging` the host is unsuccessful. This can be fixed with the local hosts file.
2. The file is located at `/etc/hosts`. We have to `sudo` in order to edit it.

![5hosts](/assets/img/ctf/htb/sp/tier1/ignition/5hosts.png)

The `target IP` is paired with the `ignition.htb` on the same line. 

![5ping2](/assets/img/ctf/htb/sp/tier1/ignition/5ping2.png)

Once the changes are saved we can test the change by `pinging` again.

![6web](/assets/img/ctf/htb/sp/tier1/ignition/6web.png)

We can also now visit the site in-browser.

### Task 5
#### What is the full URL to the Magento login page?

Let's dirbust.

![7g0](/assets/img/ctf/htb/sp/tier1/ignition/7g0.png)

We found a directory called `/admin`.

![7magento](/assets/img/ctf/htb/sp/tier1/ignition/7magento.png)

Navigating to the directory in-browser redirects us to the Magento login page at `http://ignition.htb/admin`

### Task 6
#### What password provides access as admin to Magento?

This part is a bit tricky. I tried using `hydra` to bruteforce the login, but they have account lockout enabled if bruteforcing is detected.

![8login](/assets/img/ctf/htb/sp/tier1/ignition/8login.png)

A manual bruteforce was successful after reading the Magento password requirements and narrowing down the list of passwords to use from a few different common password lists. 


### Task 7
####  Submit root flag

![9flag](/assets/img/ctf/htb/sp/tier1/ignition/9flag.png)

Once the correct password was found we got the flag.

<figure>![moon](/assets/img/ctf/htb/sp/tier1/ignition/moon.gif) <figcaption>GME degenerates post-ignition fulfilling The Prophecy </figcaption></figure> 

## Lessons Learned

* the `/etc/hosts` file can be edited to redirect our network traffic to a specific hostname
