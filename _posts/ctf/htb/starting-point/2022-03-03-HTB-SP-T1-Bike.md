---
title: "HTB Starting Point - Tier 1 - Bike"
date: 2022-03-03 00:00:00 -0700
categories: [RedOps, ctf, HTB]
tags: [ctf, htb, RedOps, writeup, very_easy, bike, ssti, injection, proxy, burpsuite]
---

![bike](/assets/img/ctf/htb/sp/tier1/bike/bike.PNG)

## Introduction

This is the 5th target in the Tier 1 lineup, and the 2nd of 3 VIP machines. Ths machine introduces `SSTI` and the use of a `proxy` to conduct the attack. This one was pretty difficult for me as I hadn't done `SSTI` before. You'll get comfortable with `Burp's` Decoder and Repeater tabs, that's for sure.

### tl;dr                                                                                      
<details>                                                                                      
  <summary>Spoiler!</summary>                                                                  

   1. Scan results indicate there is a webserver running Node.js. We identify which framework is running using `SSTI`; the framework is `Handlebars`. <br/>                                   
   2. Capture the POST request via `Burpsuite` and load the request into Repeater.<br/>
   3. Use exploits from sources like [Hacktricks](https://book.hacktricks.xyz/pentesting-web/ssti-server-side-template-injection). Encode the payloads in Decoder as "URL" and troubleshoot the responses until there is a reponse. <br/>
   4. Use the global var `process` to get `mainModule`, check `whoami` to verify `root`. <br/>
   5. `ls` to verify the flag is available, then `cat` it out. <br/>                        
   <figure>![bike4](/assets/img/ctf/htb/sp/tier1/bike/bike4.gif) <figcaption>sHAre tHe ROaD bR0</figcaption></figure>
</details>


## Establishing a Connection and Initial Scan

Spawn the bastard and get vpn going.

I've confirmed the target is reachable with a `ping`.

Start the default `nmap` scan and let it run while we complete the tasklist.

![1nmap](/assets/img/ctf/htb/sp/tier1/bike/1nmap.png)

## The Tasklist

### Task 1
#### What TCP ports does nmap identify as open? Answer with a list of ports seperated by commas with no spaces, from low to high.

`NMAP` shows ports `22,80` as open.

### Task 2
#### What software is running the service listening on the http/web port identified in the first question?

![2node](/assets/img/ctf/htb/sp/tier1/bike/2node.png)

`node.js`

### Task 3
#### What is the name of the Web Framework according to Wappalyzer?

`express`

### Task 4 
#### What is the name of the vulnerability we test for by submitting`?

`Server Side Template Injection` aka `SSTI`. This is similar to `SQLi` in that the input field presented to end-users is not sanitized properly, and therefore allows for code to be passed and interpreted to the backend. However, `SSTI` injects commands to the webserver framework rather than a DB in the instance of `SQLi`.

### Task 5
#### What is the templating engine being used within Node.JS?

We can identify the template using some unique strings that will return status/error codes that validate if there is a targeted template in use. We'll be entering these into the `email` field on the webserver's landing page:

![3email](/assets/img/ctf/htb/sp/tier1/bike/3email.png)

I referenced Hacktricks for their `SSTI` testing methodology here: [Hacktricks SSTI](https://book.hacktricks.xyz/pentesting-web/ssti-server-side-template-injection)

There are several expressions to try:

`{{7*7}}`<br/>
`${7*7}`<br/>
`<%= 7*7 %>`<br/> 
`${{7*7}}`<br/>
`#{7*7}`<br/>

![4inject](/assets/img/ctf/htb/sp/tier1/bike/4inject.png)

After testing a few, the "`{{7*7}}`" expression returns some results:

![5handlebars](/assets/img/ctf/htb/sp/tier1/bike/5handlebars.png)

The template in use is `Handlebars`. Hacktricks has a section for attacking the template further down the page: [Handlebars Template Injection Payload on HackTricks](https://book.hacktricks.xyz/pentesting-web/ssti-server-side-template-injection#handlebars-nodejs)


### Task 6
#### What is the name of the BurpSuite tab used to encode text?

The payload for Handlebars looks like in needs to be passed via POST from the webform submission. 

![6foxyproxy](/assets/img/ctf/htb/sp/tier1/bike/6foxyproxy.png)>

![6foxydetails](/assets/img/ctf/htb/sp/tier1/bike/6foxydetails.png)

I set up `FoxyProxy` to redirect the request to `Burpsuite` to capture.

![6burpproxy](/assets/img/ctf/htb/sp/tier1/bike/6burpproxy.png)

With that setup, I then launched `Burpsuite`. If you are not familiar with setting up the proxy, check the following:

1. `Proxy` tab - this section will contain the relevant details to configure/
2. `Options` subtab - check here to see if you have an interface defined. 
3. If not, set to `127.0.0.1` (localhost) and set the port to match what was set in `FoxyProxy`.
4. Modify the intercept rules as needed, but I've left these as default

With that done, the answer to this task is `Decoder`.

### Task 7
#### In order to send special characters in our payload in an HTTP request, we'll encode the payload. What type of encoding do we use?

![7burpdecoder](/assets/img/ctf/htb/sp/tier1/bike/7burpdecoder.png)

1. This is the Decoder tab
2.  The payload will be entered here. 
3. Despite the name, we will be `encoding` the payload rather than decoding. This dropdown has many options. Remember that POST variables are sent via URL, so we need to encode in the `URL` type.
4. Once `URL` has been selection, we see the transformed string below to copy into the `Repeater`tab.


### Task 8
#### When we use a payload from HackTricks to try to run system commands, we get an error back. What is "not defined" in the response error?

![7burprequest](/assets/img/ctf/htb/sp/tier1/bike/7burprequest.png)

The next step of the attack is to load the Repeater.

![7burpreques2](/assets/img/ctf/htb/sp/tier1/bike/7burpreques2.png)

 We need to copy and paste the encoded payload from the Decoder tab to the Repeater, specifically the POST variable 'email'. 

![7burpresponse](/assets/img/ctf/htb/sp/tier1/bike/7burpresponse.png)

1. We hit `send` to forward the payload to the target
2. Th target responds. We see there is an errror. Looks like `require` is not defined.

<figure>![bike](/assets/img/ctf/htb/sp/tier1/bike/bike.gif)<figcaption>Our first error on this box. The first of *many*. </figcaption></figure>

### Task 9
#### What variable is the name of the top-level scope in Node.JS?

I had to look the error up. Essentially, the `require` function is out-of-scope of the application we are attacking. We need to find a function that it can access. These are called `global` variables. 

### Task 10
####  By exploiting this vulnerability, we get command execution as the user that the webserver is running as. What is the name of that user?

![8decoder](/assets/img/ctf/htb/sp/tier1/bike/8decoder.png)

The first global var we try is `process`. We enter the above back to the decoder...

![8response](/assets/img/ctf/htb/sp/tier1/bike/8response.png)

...and receive the following response when sent via the Repeater. The `process` var was in-scope!

![8decoder2](/assets/img/ctf/htb/sp/tier1/bike/8decoder2.png)

We try again, this time getting the mainModule object.

![8response3](/assets/img/ctf/htb/sp/tier1/bike/8response3.png)

The object is returned successfully.

![8decoder4](/assets/img/ctf/htb/sp/tier1/bike/8decoder4.png)

Time to check who we are running as. 

![8response4](/assets/img/ctf/htb/sp/tier1/bike/8response4.png)

`root`

<figure>![oh](/assets/img/ctf/htb/sp/tier1/bike/oh.gif)<figcaption>scandalous</figcaption></figure>

## Capturing the Flag

Time to get the flag.

![8decoder5](/assets/img/ctf/htb/sp/tier1/bike/8decoder5.png)

We push an `ls` to see what files are in the /root directory.

![8response5](/assets/img/ctf/htb/sp/tier1/bike/8response5.png)

The flag is in the current working directory. Neat.

![8decoder6](/assets/img/ctf/htb/sp/tier1/bike/8decoder6.png)

`Cat` it out...

![9flag](/assets/img/ctf/htb/sp/tier1/bike/9flag.png)

And we got it. 

<figure>![bike2](/assets/img/ctf/htb/sp/tier1/bike/bike2.gif)<figcaption>All of my attempts at this task. </figcaption></figure>


## Lessons Learned

* [SSTI](https://book.hacktricks.xyz/pentesting-web/ssti-server-side-template-injection) attacks for webforms can be viable. Walk the identification expressions to see if the template can be identified, and then exploited
* `Burpsuite` is pretty handy for these things. I know, understatement of the century
* Errors returned from exploits are just as helpful as getting data at times. Adjust the payload based off of research of the error.
* I really, really don't like those bicyclists that run stop signs, yet want to be treated like vehicles. And you look like dorks in those bike suits!

<figure>![bike3](/assets/img/ctf/htb/sp/tier1/bike/bike3.gif)<figcaption>A group of cyclists is reffered to as an aneurism.</figcaption></figure>
