#!/bin/bash
# Assuming that you have put the main ipsender folder inside home folder 
cd ~/ipsender
rm ./summaryIPs.txt
rm ./ifconfig.txt
git pull https://safaATcurrus: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@github.com/safaATcurrus/ipsender main
./ipsender.sh
