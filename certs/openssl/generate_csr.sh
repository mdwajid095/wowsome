#!/bin/bash

log() {
  date=$(date '+%Y-%m-%d %H:%M:%S,%3N')
  case "$1" in
    "info")  printf "\033[33;32m[INFO] %s %s\033[33;0m\n" "$date" "$2" ;;
    "error") printf "\033[33;31m[ERROR] %s %s\033[33;0m\n" "$date" "$2";;
    "warn") printf "\033[33;33m[WARN] %s %s\033[33;0m\n" "$date" "$2";;
  esac
}

# Check if OpenSSL is available
if ! command -v openssl &> /dev/null; then
  log error "OpenSSL is not installed. Please install it and try again."
  exit 1
fi

# Check if application name is provided
if [ -z "$1" ]; then
  log error "Usage: $0 <application_name>"
  exit 1
fi

TENANT="$1"
environments=("ict" "e2e2" "nfr" "e2e1" "prod")

# Loop through each environment and generate files
for env in "${environments[@]}"; do
  CONFIG_FILE="${TENANT}_${env}.conf"
  PRIVATE_KEY_FILE="${TENANT}_${env}.key"
  CSR_FILE="${TENANT}_${env}.csr"

  if [ "$env" == "e2e2" ]; then
    TENANT_CN="$TENANT.${env}.wow-test.gcp.de.pri.o2.com"
  elif [ "$env" == "prod" ]; then
    TENANT_CN="$TENANT.wow.gcp.de.pri.o2.com"
  else
    TENANT_CN="$TENANT.${env}.wow.gcp.de.pri.o2.com"
  fi

  cat > "$CONFIG_FILE" <<EOL
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[req_distinguished_name]
C = IN
ST = West Bengal
L = Kolkata
O = Wow India Co. LTD
OU = ST
CN = $TENANT_CN
[v3_req]
keyUsage = keyEncipherment, dataEncipherment, digitalSignature, keyAgreement
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1=$TENANT_CN
EOL

  # Generate the private key
  if ! openssl genrsa -out "$PRIVATE_KEY_FILE" 2048; then
    log error "Failed to generate private key for $TENANT $env."
    exit 1
  fi

  # Generate the CSR using the configuration file
  if ! openssl req -new -newkey rsa:2048 -nodes -sha256 -keyout "$PRIVATE_KEY_FILE" -out "$CSR_FILE" -config "$CONFIG_FILE"; then
    log error "Failed to generate CSR for $TENANT $env."
    exit 1
  fi

  # Output the results
  log info "Private Key saved to: $PRIVATE_KEY_FILE"
  log info "CSR saved to: $CSR_FILE"
  log info "Configuration file saved to: $CONFIG_FILE"
  log info "-----*-----*----*----*---*---*----*----*-----*-----"

  rm -f "$CONFIG_FILE"
done
