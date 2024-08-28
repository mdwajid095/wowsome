#!/bin/bash

usage() {
  local SELF
  SELF="dockercp"
  cat <<EOF
USAGE:
  $SELF                    : show the user manual and version
  $SELF -h,--help          : show this message
  $SELF -f,--file          : Will take input a file in below format, i.e json.

Example json file:
        {
          "destination": "europe-west3-docker.pkg.dev/PROJECT/DIR/",
          "source": "docker.io/mdwajid095/",
          "images": [
            "kcctl:v1.1",
            "curl-jq-git:v1.1",
            "ubuntu:latest"
          ]
        }

EOF
}

pusher(){
cat $1 > inputFile
destination=`jq -r .destination inputFile`
source=`jq -r .source inputFile`
imageTag=`jq -r .images[] inputFile`

for i in `echo $imageTag`
do
  pull=$source$i
  push=$destination$i
  echo "Pulling image $i from $source repository... "
  sudo docker pull $pull
  echo "Tagging image $i... "
  sudo docker tag $pull $push
  echo "Pushing image $i to $destination repository... "
  sudo docker push $push
done
rm inputFile
}

main() {
  if [[ "$#" -eq 0 ]]; then
    echo "Version: v1.0"
    echo "run 'dockercp -h,--help'       :for instruction manual "
  elif [[ "$#" -eq 1 ]]; then
    if [[ "${1}" == '-h' || "${1}" == '--help' ]]; then
      usage
    elif [[ "${1}" =~ ^-(.*) ]]; then
      echo "error: unrecognized flag \"${1}\"" >&2
      usage
      exit 1
    fi
  elif [[ "$#" -eq 2 ]]; then
    if [[ "${2}" =~ ^-(.*) ]]; then
      echo "error: unrecognized flag \"${2}\"" >&2
      usage
      exit 1
    elif [[ "${1}" == '-f' || "${1}" == '--file' ]]; then
      pusher $2
    else
     echo "error: unrecognized flag \"${1}\"" >&2
     usage
     exit 1
    fi
  else
    echo "error: too many flags" >&2
    usage
    exit 1
  fi
}

main "$@"
