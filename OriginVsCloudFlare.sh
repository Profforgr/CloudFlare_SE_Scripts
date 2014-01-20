#!/bin/bash
#22 July 2013
#Simple script to compare speeds between connecting diretly to origin IP vs DNS (Assumes DNS directs request via CloudFlare)
#
#Usage: Call script and pass URL as first argument and origin IP as second argument

CURL="/usr/bin/curl"
AWK="/usr/bin/awk"

#Useragent used for curl requests
USERAGENT="Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.116 Safari/537.36"
#List of headers to watch for seperated by \|
HEADERSTOWATCH="cache\|expires\|CF-"
#List of headers to ignore seperated by \|
HEADERSTOIGNORE="cookie\|<"

#test if arguments passed
if [ -z "$1" ]; then
	printf "Please pass the url you want to measure: "
	read URL
	printf "Please pass your origin IP address: "
	read ORIGINIP
else
	URL=$1
	ORIGINIP=$2
fi


#Print IP request is originating from
printf "\n"
printf "Request originating from: "
$CURL canhazip.com
printf "\n"

#Make request for resource via DNS and report back CloudFlare headers, then grep headers interested in
printf "CloudFlare Headers:\n"
$CURL -s -I -X Get  -H "User-Agent: $USERAGENT" --url $URL |grep -ai $HEADERSTOWATCH |grep -aiv $HEADERSTOIGNORE

#Make request for resrouce by IP and pass Host header, then grep headers interested in
printf "Origin Cache Headers:\n"
$CURL -s -I -X Get -H "Host: $URL" -H "User-Agent: $USERAGENT" --url $ORIGINIP |grep -ai $HEADERSTOWATCH |grep -aiv $HEADERSTOIGNORE
printf "\n"

#Make request for resource via DNS and store metrics
CFRESULT=`$CURL -o /dev/null -s -H "User-Agent: $USERAGENT" -w %{time_connect}:%{time_starttransfer}:%{time_total} --url $URL`

#Make request for resource directly via IP and store metrics
ORIGINRESULT=`$CURL -o /dev/null -s -H "User-Agent: $USERAGENT" -H "Host: $URL" -w %{time_connect}:%{time_starttransfer}:%{time_total} --url $ORIGINIP`

#Print metrics from above requests
printf "\t\tTime_Connect\tTime_StartTransfer\tTime_Total\n"
printf "CloudFlare:"
echo $CFRESULT | $AWK -F: '{ print "\t"$1"\t\t"$2"\t\t\t"$3}'
printf "Origin:"
echo $ORIGINRESULT | $AWK -F: '{ print "\t\t"$1"\t\t"$2"\t\t\t"$3}'

exit 0