---
layout: post
title: "HTB Starting Point - Tier 1 - Appointment"
date: 2022-02-24
categories: [ RedOps, ctf, HTB ]
tags: [ ctf, htb, RedOps, writeup, very_easy, injection, sqli ]
---
![appointment](/assets/img/ctf/htb/sp/tier1/appointment/appointment.PNG)

## Introduction

We have captured 6 flags from the Tier 0 series, and are on the 1st of the Tier 1 series. This box is an introduction into SQL database injection.

### tl;dr                                      
<details>                                                                                      
  <summary>Spoiler!</summary>                                                                  
                                                                                               
   1. dirbust to find the web login page.<br/>
   2. use `SQLi`, specifically `admin'#`<br/>          
   <figure>![gandalf](/assets/img/ctf/htb/sp/tier1/appointment/gandalf.gif)<figcaption>"A wizard is never late, nor is he early. He arrives precisely when he means to." -Me running late, always. </figcaption></figure>                                     
</details>      

## Establishing a Connection & Intitial Scan

Spawn the bastard and get vpn going.

I've confirmed the target is reachable with a `ping`.

![1scan](/assets/img/ctf/htb/sp/tier1/appointment/1scan.png)

## The Tasklist

### Task 1
#### What does the acronym SQL stand for?

`SQL` is the abbreviation for `Structured Query Language`. Many variants of it are used in a sizeable portion of the internet's databases to store, organize, and poll data efficiently. The language syntax is simple and easy to learn. 

Here is a [primer to familiarize yourself](https://www.tutorialrepublic.com/sql-tutorial/).


### Task 2
#### What is one of the most common type of SQL vulnerabilities?

`SQL Injection` is a notorious attack in which input from an end-user is not sanitized correctly, and the input contains data that the server interprets as a query statement against the database.

For example, a website's login page would have fields for a user to enter **username** & **password**. If these two fields are not sanitized correctly, a malicious actor could enter a SQL command here instead of username/password. Entering "'Select * from Users;' could query the database table Users and show sensitive info, instead of allowing a user to login.

Relevant XKCD
![bobbytables](/assets/img/ctf/htb/sp/tier1/appointment/bobbytables.png)
[source](https://xkcd.com/327/)


### Task 3
### What does PII stand for?

`PII` is short for `Personally Identifiable Information`. This data can include names, birthdays, addresses, etc. and is considered sensitive to any organization storing the data.

### Task 4 
#### What does the OWASP Top 10 list name the classification for this vulnerability?

Briefly, the `OWASP Top 10` list is a curated list of web vulnerabilities. In their own words:
> It represents a broad consensus about the most critical security risks to web applications.

In OUR words, this is a prime checklist of types of exloits we should check for. 

[The OWASP Top 10 list can be found here](https://owasp.org/Top10/). Injection is currently ranked #3 on the list.

`A03:2021-Injection`

### Task 5
#### What service and version are running on port 80 of the target?

We got this info from our initial scan. The answer is `Apache httpd 2.4.38 ((Debian))`.

`Apache` is a server application, like `Nginx` and `IIS`. 

### Task 6
#### What is the standard port used for the HTTPS protocol?

`443`

### Task 7
#### What is one luck-based method of exploiting login pages?

`Brute-forcing`, though I wouldn't say it's *all* luck-based. Given some knowledge of the target and enough time, luck gives way to persistence.

### Task 8
#### What is a folder called in web-application terminology?

`Directory`; you should know this from the `dir busting` we did back in [Tier 0's Preignition](https://opfor-haunter.github.io/posts/HTB-SP-T0-Preignition/).

### Task 9
####  Submit root flag

## Capturing the Flag

Speaking of `dir busting`, it's time to capture our flag. Since we know this is a webserver, it doesn't hurt to look for hidden directories/pages to start our attack.

`gobuster dir -u $target -w /usr/share/wordlists/dirb/common.txt`

![3gobuster](/assets/img/ctf/htb/sp/tier1/appointment/3gobuster.png)

We have a few hits worth noting. Let's try and visit the `Login page` our `nmap` scan found earlier. Put the IP address in the browser:

![2login](/assets/img/ctf/htb/sp/tier1/appointment/2login.png)

We could try `bruteforcing` the login, but this server looks more configured than the last one. Let's try `SQL injection`.

My experience with `SQLi` is very limited, but there must be tools on Kali. 

`ls /bin/*sql*`

![4sqltools](/assets/img/ctf/htb/sp/tier1/appointment/4sqltools.png)

`sqlmap` seems to fit the bill:

![5sqlmap](/assets/img/ctf/htb/sp/tier1/appointment/5sqlmap.png)

Again, I have limited experience here but luckily the bottom on the man page lists a `--wizard` switch for dumb users like myself. 

![6sqlmapwiz](/assets/img/ctf/htb/sp/tier1/appointment/6sqlmapwiz.png)


![7sqlmap](/assets/img/ctf/htb/sp/tier1/appointment/7sqlmap.png)

1. We run the command `sqlmap --wizard`
2. The wizard prompts for the target URL. Make sure to enter the `http://` prefix before the target IP and to also include the actual page name at the end (`index.php`)

![8sqlmap](/assets/img/ctf/htb/sp/tier1/appointment/8sqlmap.png)

There are some options here, I've chose the default values.

![9sqlmap](/assets/img/ctf/htb/sp/tier1/appointment/9sqlmap.png)

After some automatic progression, eventually we see that an injection package was successful.

So the login page is definitely vulnerable to `SQL Injection`, but we need a specific package to get the flag. This part I had to look up, but the specific injection is below:

`admin'#`

![10login](/assets/img/ctf/htb/sp/tier1/appointment/10login.png)

We enter the injection in the `username` field and any random character in the `password` field.

The logic here is that the `'` apostrophe character is not correctly sanitized out of the subitted input. Typically, special characters like this one are **escaped** so that they are not interpreted in an uniintended way.

However, since the input is taken literally, the special character is interpreted by the scrip literally. Apostrophes are used to enclose string values. Once it reads the `unsername` input, it will prematurely close the string that contains the value. This begins the injection portion of the attack.

With the statement prematurely closed with the `'`, the next character is also interpreted. The `#` pound/hash character is a comment character that will void out any code on the same line as the character. Typically this is used for writing comments and debugging, but here it breaks the remaining logic in the code that checks for a matching password for admin.

Let's submit the injection command.

![10flag](/assets/img/ctf/htb/sp/tier1/appointment/10flag.png)

There's the flag.

<figure>![appointment2](/assets/img/ctf/htb/sp/tier1/appointment/appointment2.png)<figcaption> </figcaption></figure>


## Lessons Learned

* `bruteforce` methods may be hindered by login failure limits
* `sqlmap` can be used to confirm if a webform is succeptible to `injection` attacks
