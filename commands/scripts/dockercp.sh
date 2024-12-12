#!/bin/bash

usage() {
  local SELF="dockercp"
  cat <<EOF
USAGE:
  $SELF                    : show the user manual and version
  $SELF -h,--help          : show this message
  $SELF -f,--file FILE     : take input from a JSON file

Example JSON file:
{
  "destination": "docker.io/nexus/",
  "source": "docker.io/confluentinc/",
  "images": [
    "kcctl:v1.1",
    "curl-jq-git:v1.1",
    "cp-server:7.3.2"
  ]
}

EOF
}

dockercp() {
  local inputFile="$1"
  local destination source imageTag

  destination=$(jq -r .destination "$inputFile")
  source=$(jq -r .source "$inputFile")
  imageTag=$(jq -r .images[] "$inputFile")

  for i in $imageTag; do
    local pull="$source$i"
    local push="$destination$i"
    echo "Pulling image $i from $source repository..."
    sudo podman pull "$pull"
    echo "Tagging image $i..." && sleep 3s
    sudo podman tag "$pull" "$push"
    echo "Pushing image $i to $destination repository..."
    sudo podman push "$push"
  done
}

main() {
  if [[ "$#" -eq 0 ]]; then
    echo "Version: v1.0"
    usage
  elif [[ "$#" -eq 1 ]]; then
    case "$1" in
      -h|--help)
        usage
        ;;
      *)
        echo "error: unrecognized flag \"$1\"" >&2
        usage
        exit 1
        ;;
    esac
  elif [[ "$#" -eq 2 ]]; then
    case "$1" in
      -f|--file)
        dockercp "$2"
        ;;
      *)
        echo "error: unrecognized flag \"$1\"" >&2
        usage
        exit 1
        ;;
    esac
  else
    echo "error: too many flags" >&2
    usage
    exit 1
  fi
}

main "$@"
