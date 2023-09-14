# IPSENDER

This project is about creating a shell script. The running system will run this script in every X minutes (can be done in crontab)
and therefore update its IP address in database.

This is written as shell script because any other programming language can crash, shell won't. 'curl' is the only external command/library that this 
script is using.

Right now it writes the ip as IP_vcu@f8:59:71:2a:d8:f2. The syntax is IP_vcu@MAC_ADDRESS.

## How to run?

First, enable execution for the shell file

`chmod 755 ./ipsend.sh`

Then, Open crontab file

`crontab -e` 

Last, add this line to the end 

`*/15 * * * * /bin/bash /full/path/to/ipsend.sh`

## What the shell script is doing?


The shell script learns its outbound internet IP from the same database server. This is given as input parameter at the beginning of the file. You can use other IP address servers. The shell script (*ipsend.sh*) file will create *summaryIPs.txt* file. This file will contain internet outbound address, wifi router name and other ip addresses with a space between each other.

If *summaryIPs.txt* file is same with current information, which is hasvested from *ifconfig* command, then nothing will be sent to server. If there is a change or this file does not exist, it will send its IP information to server. This is checked so that we don't make excess communication with database server.

If the shell script cannot access internet, it will remove this summaryIP.txt file so that it will send its fresh information next time guaranteed.
 
