---
title: "HTB Starting Point - Tier 0 - Redeemer"
date: 2022-05-16 00:00:00 -0700
categories: [RedOps, ctf, HTB]
tags: [ctf, htb, RedOps, writeup, very_easy, redeemer, redis]
---

![redeemer](/assets/img/ctf/htb/sp/tier0/redeemer/redeemer.PNG)

## Introduction
`Reedemer` is a new host on the Starting Point Tier 0 level. Some light reading of `Redis` will be needed for this exercise.

### tl;dr                                                                                      
<details>                                                                                      
  <summary>Spoiler!</summary>

   1. Scan target. Redis is on TCP `6379`. <br/>                                   
   2. Reference HackTricks [Redis](https://book.hacktricks.xyz/network-services-pentesting/6379-pentesting-redis#basic-information) page.<br/>        
   3. Install `redis-tools` if applicable. Connect with `redis-cli -h $target` <br/>
   4. run `info` and look for the database that has keys (`db0`). `SELECT 0` <br/>
   5. Enter `keys *` to show all the keys by name. Then `GET flag` to win.                           <figure>![redeemer1](/assets/img/ctf/htb/sp/tier0/redeemer/redeemer1.PNG) <figcaption>And Jesus wept, for the coupons were hella expired. </figcaption></figure>
</details>

## Establishing a Connection

Spawn the bastard and get vpn going.

I've confirmed the target is reachable with a `ping`.

## The Tasklist

### Task 1
#### Which TCP port is open on the machine?
![1nmap](/assets/img/ctf/htb/sp/tier0/redeemer/1nmap.png)
`6379`

### Task 2
#### Which service is running on the port that is open on the machine?

The service is named `redis` according to our scan.
![1redis](/assets/img/ctf/htb/sp/tier0/redeemer/1redis.PNG)
Here is some basic info regarding the service.
[redis on HackTricks](https://book.hacktricks.xyz/network-services-pentesting/6379-pentesting-redis#basic-information)

### Task 3
#### What type of database is Redis? Choose from the following options: (i) In-memory Database, (ii) Traditional Database

`in-memory database`

### Task 4 
#### Which command-line utility is used to interact with the Redis server? Enter the program name you would enter into the terminal without any arguments.

[redis on HackTricks](https://book.hacktricks.xyz/network-services-pentesting/6379-pentesting-redis#banner) indicates we can use `redis-cli`.

### Task 5
#### Which flag is used with the Redis command-line utility to specify the hostname?

I had to install the redis toolset. Use the following command if you need to do so as well:
`sudo apt-get install redis-tools`

![2redistools](/assets/img/ctf/htb/sp/tier0/redeemer/2redistools.png)
You can then verify in the `man` page for `redis-cli` or the HackTricks article that the `-h` flag is needed to specify a hostname.

### Task 6
#### Once connected to a Redis server, which command is used to obtain the information and statistics about the Redis server?

![3redisnfo](/assets/img/ctf/htb/sp/tier0/redeemer/3redisnfo.png)

1. We run the connection command `redis-cli -h $target`
2. Once connected, I ran `info`

### Task 7
#### What is the version of the Redis server being used on the target machine?

`5.0.7` according to the results of `info` we just ran.

### Task 8
#### Which command is used to select the desired database in Redis?

`SELECT`

### Task 9
#### How many keys are present inside the database with index 0?

![4rediskeys](/assets/img/ctf/htb/sp/tier0/redeemer/4rediskeys.png)
Scrolling through our results further, we see that there are `4` keys inside of `db0`.

We now can run `SELECT 0` to query this database.

### Task 10
#### Which command is used to obtain all the keys in a database?

`keys *`

## Capturing the Flag

![5keys](/assets/img/ctf/htb/sp/tier0/redeemer/5keys.png)

1. Now that we have db0 currently selected, we can run `keys *` to list everything it has.
2. Finally we use `get flag` to show the value of the flag.

![redeemer](/assets/img/ctf/htb/sp/tier0/redeemer/redeemer.gif)

## Lessons Learned

* `HackTricks` is a great place to check for exploits/methodolog of services discovered from enumeration
