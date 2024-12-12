#!/bin/bash

# Example input file
# cat > 7.6.1.txt
# cp-zookeeper:7.6.1
# cp-server:7.6.1

file="$1"
extension="${file##*.}"
file_name=$(basename "$file" .$extension)
echo "Scanning for the IMAGES: $file_name"

while IFS= read -r image; do
  name=$(echo "$image" | cut -d':' -f1)
  echo "Trivy scan started for Docker image: $image"

  # Run Trivy scan
  #trivy image -s CRITICAL docker.io/confluentinc/cp-zookeeper:7.6.1
  trivy image -f json -o "$name.json" "docker.io/confluentinc/$image"

  echo "Trivy scan report generated for Docker image: $image and stored in file $name.json"
done < "$file"
