---
title: "OffSec PG Play - Linux - Easy - Potato"
date: 2025-11-12 12:00:00 -0000
categories: [CTF, OffSec PG Play]
tags: [linux, easy]
---

![OffSec PG Play Potato](/assets/img/ctf/offsec/easy/potato/potato.png)

# Initial Intel
* OS: Linux
* Difficulty: Easy

# tl;dr
<details><summary>Spoilers</summary>
</details>

# Attack Path

## Recon

### Service Enumeration

Standard TCP scan to start:

```bash
┌──(haunter㉿kali)-[~/working/offsec/easy/potato/
└─$ sudo nmap -A -p- -vvv -T3 --open -oN nmap_tcp_full $system
```

Notable services:

#### /TCP - 

## Foothold

## Lateral Movement / Privilege Escalation

## Root / SYSTEM
