#!/bin/bash

log() {
  date=$(date '+%Y-%m-%d %H:%M:%S,%3N')
  case "$1" in
    "info")  printf "\033[33;32m[INFO] %s %s\033[33;0m\n" "$date" "$2" ;;
    "error") printf "\033[33;31m[ERROR] %s %s\033[33;0m\n" "$date" "$2";;
    "warn") printf "\033[33;33m[WARN] %s %s\033[33;0m\n" "$date" "$2";;
  esac
}

# Check if application name is provided
if [ -z "$1" ]; then
  log warn "Usage: $0 <application_name>"
  exit 1
fi

# Check if OpenSSL is available
if ! command -v openssl &> /dev/null; then
  log error "OpenSSL is not installed. Please install it and try again."
  exit 1
fi

# Check if Vault CLI is available
if ! command -v vault &> /dev/null; then
  log error "Vault CLI is not installed. Please install it and try again."
  exit 1
fi

verify_pem() {
  if ! openssl x509 -in "${TENANT}_${env}.pem" -text -noout; then
      log error "Failed to verify the original PEM file."
      exit 1
  fi
  log info "PEM file verified. Check for the correct CN name"
}

# build keystore.p12 with fips
build_keystore_p12() {
  openssl rand -base64 12 | tr /+ - | cut -c -14 > "${TENANT}_${env}.password"
  mypassword=$(cat "${TENANT}_${env}.password")
  if ! openssl pkcs12 -certpbe PBE-SHA1-3DES -export -inkey "${TENANT}_${env}.key" \
    -name "${TENANT}" -in "${TENANT}_${env}.pem" \
    -passout pass:"$mypassword" \
    -out "${TENANT}-${env}-keystore.p12"; then
    log error "keystore.p12 build failed of ${TENANT} for ${env}"
    exit 1
  fi
  log info "keystore.p12 created of ${TENANT} for ${env}"
}

upload_p12_vault() {
  base64 -w0 "${TENANT}-${env}-keystore.p12" > "${TENANT}-${env}-keystore.p12.base64"
  if ! vault kv put -mount=servers "${VAULT_BASE}${env}/certs/ClientCerts/${TENANT}" \
    "passphrase=passphrase=$(cat "${TENANT}_${env}.password")" \
    "keystore.p12=@${TENANT}-${env}-keystore.p12.base64"; then
    log error "Failed to upload P12 to Vault."
    exit 1
  fi
  rm -f "${TENANT}-${env}-keystore.p12.base64"
  log info "${TENANT}-${env}-keystore.p12 file uploaded to Vault at path: ${VAULT_BASE}${env}/certs/ClientCerts/${TENANT}"
}

download_p12_vault() {
  if ! vault kv get -mount=servers "${VAULT_BASE}${env}/certs/ClientCerts/${TENANT}" > "${TENANT}-${env}-keystore.p12.base64"; then
    log error "Failed to download P12 from Vault."
    exit 1
  fi
  base64 -d "${TENANT}-${env}-keystore.p12.base64" > "${TENANT}-${env}-keystore.p12"
  rm -f "${TENANT}-${env}-keystore.p12.base64"
  
  if ! vault kv get -mount=servers "${VAULT_BASE}${env}/certs/ClientCerts/${TENANT}" | grep "passphrase" | cut -d '=' -f2 > "${TENANT}_${env}.password"; then
    log error "Failed to download password from Vault."
    exit 1
  fi
  log info "${TENANT}-${env}-keystore.p12 and password file downloaded from Vault."
}

validate_prerequisites() {
  if [ ! -f "${TENANT}_${env}.pem" ] || [ ! -f "${TENANT}_${env}.key" ]; then
    log error "Required files (${TENANT}_${env}.pem or ${TENANT}_${env}.key) are missing."
    exit 1
  fi
  log info "Prerequisites validated."
}

cleanup() {
  log info "Cleaning up temporary files..."
  rm -f "${TENANT}_${env}.key" \
        "${TENANT}_${env}.csr" \
        "${TENANT}_${env}.pem" \
        "${TENANT}_${env}.password" \
        "${TENANT}-${env}-keystore.p12"
}

TENANT="$1"
environments=("ict" "e2e2" "nfr" "e2e1" "prod")
VAULT_BASE="Applications/U-654-WOW/"
log info "NOTE: Please pass tenant name as 1st input and save signed pem in format TENANT_env.pem"

for env in "${environments[@]}"; do
  validate_prerequisites
  verify_pem
  # build_keystore_p12
  # upload_p12_vault
  # download_p12_vault
  # cleanup # execute only after sharing the certs with tenant
done
