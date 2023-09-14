#!/bin/bash
# Assuming that you have put the main ipsender folder inside home folder 
cd ~/ipsender
rm ./summaryIPs.txt
rm ./ifconfig.txt
git pull origin main
./ipsender.sh
