#!/bin/sh
##
# This script will check the status of the tasks for a connector in connect cluster, it will try to start if the tasks are in FAILED state
# Prerequisite: curl and jq need to be installed
##

# for log formatting
log() {
  date=$(date '+%Y-%m-%d %H:%M:%S,%3N')

  case "$1" in
    "info")  printf "\033[33;32m[INFO] %s %s\033[33;0m\n" "$date" "$2" ;;
    "error") printf "\033[33;31m[ERROR] %s %s\033[33;0m\n" "$date" "$2";;
    "debug") printf "\033[33;33m[DEBUG] %s %s\033[33;0m\n" "$date" "$2";;
  esac
}

process_list() {
  CONNECTOR_LIST=$(curl -sk "${CONNECT_CRED}" "${CONNECT_URL}" | jq -r .[])
  log info "$CONNECTOR_LIST"

  for connector in ${CONNECTOR_LIST}; do
    TASKS=$(curl -sk "${CONNECT_CRED}" "${CONNECT_URL}/${connector}/status" | jq -r '.tasks[]| [ .id, .state]|@csv' | tr -d '"')
    for task in ${TASKS}; do
      STATE=$(echo "${task}" | cut -d "," -f 2)
      ID=$(echo "${task}" | cut -d "," -f 1)
      if [ "${STATE}" = "FAILED" ]; then
        log error "${connector} status: ${STATE}, trying to restart the tasks"
        curl -sk -X POST "${CONNECT_CRED}" "${CONNECT_URL}/${connector}/tasks/${ID}/restart"
        sleep 5
        RESTART_STATUS=$(curl -sk "${CONNECT_CRED}" "${CONNECT_URL}/${connector}/status" | jq -r '.tasks[]| .state')
        log info "Connector--> ${connector} status: ${RESTART_STATUS}"
      fi
    done
  done
  echo
}
echo "Operations for CONNECTORs..."
export CONNECT_URL="https://${CONNECT_0_INTERNAL_PORT_8083_TCP_ADDR}:8083/connectors"
process_list

echo "Operations for REPLICATORs..."
export CONNECT_URL="https://${REPLICATOR_0_INTERNAL_PORT_8083_TCP_ADDR}:8083/connectors"
process_list
