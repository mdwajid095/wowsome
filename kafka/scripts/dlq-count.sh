#!/bin/sh

set -e

#function for log formatting
log() {
  date=$(date '+%Y-%m-%d %H:%M:%S,%3N')

  case "$1" in
    "info")  printf "\033[33;32m[INFO] %s %s\033[33;0m\n" "$date" "$2" ;;
    "error") printf "\033[33;31m[ERROR] %s %s\033[33;0m\n" "$date" "$2";;
    "debug") printf "\033[33;33m[DEBUG] %s %s\033[33;0m\n" "$date" "$2";;
  esac
}

#We are fetching current epoch time in milliseconds and also finding out the epoch time of exactly the previous day of same time.
today=$(($(date +%s%N) * 1000))
a=$(date "+%s" -d yesterday)
yesterday=$((a * 1000))

#Printing the dates and time in human readable format
echo "From : $yesterday"
echo "Now : $today"

#Command to fetch topics based on some particular name. In below command it is dlq. It will save all these topics in a file named topics.txt
kcat -b "$BOOTSTRAP_URL:9092" -F adm.properties -L |grep .dlq | cut -d'"' -f2 |sort > topics.txt

file=topics.txt
cat $file | while IFS= read -r topic
do
        count=$(kcat -b "$BOOTSTRAP_URL:9092" -F adm.properties -f '%T \n'  -t "$topic" -K: -C -o s@"$yesterday" -o e@"$today" -e -q | wc -l)
        #count=$((count-1))
        if [ "$count" -eq 0 ]
        then
                #Print green
                log info "\e[0;32m$topic, $count \e[0m"
        else
                #Print Red
                log error "\e[0;31m$topic, $count \e[0m"
        fi
done
rm topics.txt