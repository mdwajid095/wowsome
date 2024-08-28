#!/bin/bash

###
# example input file
# cat > 7.6.1.txt
# cp-zookeeper:7.6.1
# cp-server:7.6.1

file="$1"
extension="${file##*.}"
file_name=$(basename "$file" .$extension)
echo "Scanning for the IMAGES: $file_name"

for image in `cat $file`
do

name=$(echo $image | cut -d':' -f1)
echo "Trivy scanned started for docker images : $image"

#trivy image -s CRITICAL docker.io/confluentinc/cp-zookeeper:7.6.1
trivy image -f json -o $name.json docker.io/confluentinc/$image

echo "Trivy scanned report generated for docker images : $image"

done
