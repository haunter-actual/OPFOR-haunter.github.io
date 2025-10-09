---
layout: post
title: "HTB Starting Point - Tier 1 - Sequel"
date: 2022-02-28
categories: RedOps ctf HTB sql
tags: ctf htb RedOps writeup very_easy sequel sql mysql
---
<img src='/assets/img/ctf/htb/sp/tier1/sequel/sequel.PNG'/>

## Introduction

Sequel is the 2nd machine in the Starting Point Tier 1 series. And maybe it's because I'm drinking but I just realized it is likely called Sequel because the focus is SQL.

### tl;dr                                      
<details>                                                                                      
  <summary>Spoiler!</summary>                                                                  
                                                                                               
   1. MariaDB is running on the target. Connect with `mysql -h $target -u root`<br/>
   2. `show databases;`,  `use htb;`, then `show tables;` <br/>          
   3. Lastly, `select * from config;` for the flag<br/>
   5. <figure><img src='/assets/img/ctf/htb/sp/tier1/sequel/rush.webp'/> <figcaption>Rush Hour 1 & 2 are amazing. However, nobody remembers Rush Hour 3...it was **terrible**.</figcaption></figure>                                     
</details>      

## Establishing a Connection & Initial Scan

Spawn the bastard and get vpn going.

I've confirmed the target is reachable with a `ping`.

Initiate the usual scan:

<img src='/assets/img/ctf/htb/sp/tier1/sequel/1nmap.png'/>

## The Tasklist

### Task 1
#### What does the acronym SQL stand for?

We covered this one before, `SQL` stands for `S`tructured `Q`uery `L`anguage.

### Task 2
#### During our scan, which port running mysql do we find?

<img src='/assets/img/ctf/htb/sp/tier1/sequel/2mysql.png'/>

According to the scan, `mysql` is running on port `3306`.

### Task 3
### What community-developed MySQL version is the target running?

<img src='/assets/img/ctf/htb/sp/tier1/sequel/3maria.png'/>

The server is running `MariaDB`.

### Task 4 
#### What switch do we need to use in order to specify a login username for the MySQL service?

<img src='/assets/img/ctf/htb/sp/tier1/sequel/4mysqluser.png'/>

The man page states that `-u` let's us specify a login username when connecting.

### Task 5
#### Which username allows us to log into MariaDB without providing a password?

<img src='/assets/img/ctf/htb/sp/tier1/sequel/5google.PNG'/>

`root` is the account.

### Task 6
#### What symbol can we use to specify within the query that we want to display eveything inside a table?

The **wildcard** `*` character is widely used for matching anything in multiple languages. In spoken terms, it is read as `all`. As an example, the SQL statement `SELECT * FROM table_name;` would be read as **SELECT ALL FROM table_name**.

### Task 7
#### What symbol do we need to end each query with?

The semicolon `;` is used to end a query statement in `SQL`.

### Task 8
#### Submit root flag

## Capturing the Flag

Right, so now we have to use the above stuff to figure out how to get the flag.

<img src='/assets/img/ctf/htb/sp/tier1/sequel/5mysqlconnection.png'/>

1. We search the man page for the switch to specify our target. `man mysql | grep host` reveals that the `-h` flag will let us enter the IP/hostname of our target.
2. The full command should include the `-u` switch discovered earlier. This will allow us to try to connect as `root`. Default config for `MariaDB` allow the account to connect without a password. The command should read `mysql -h $target -u root`.
3. The command worked! Now to enter some `mysql` commands.

<img src='/assets/img/ctf/htb/sp/tier1/sequel/6showdb.png'/>

1. Now that we are connected, we want to run `show databases;`. This dumps the databases that are on the server.
2. There is a very promising DB listed- `htb`-, let's take a look inside. We run the command `use htb;` to select the `htb` database as our active DB to query against.
3. Once the `htb` DB is selected, we dump the tables to see what's viable. The command `SELECT * FROM htb;` will dump all tables located in the `htb` DB.
4. Two tables are inside. Both `users` and `config` seem promising.

<img src='/assets/img/ctf/htb/sp/tier1/sequel/7show.png'/>

1. We'll start with the `users` table with the statement `SELECT * FROM users;`. 
2. Said table contains some usernames and emails. All worth pillaging, but we still don't have our flag.
3. We check the next table, `config`. The command is `SELECT * FROM config;`.
4. This is the ticket, our flag is in this table. Nice!

<figure><img src='/assets/img/ctf/htb/sp/tier1/sequel/sequel.gif'/><figcaption>A rare time that the sequel surpassed the original. </figcaption></figure>

## Lessons Learned

* footholds can be gained to `mysql` using `mysql -h $target -u $user`. Worth trying `root`.
* upon gaining foothold, enumerate databases with `SHOW DATABASES;` and tables by selecting a DB `USE {DB_NAME};` and then `SHOW TABLES;`. See data with `SELECT * FROM {TABLE_NAME};`
