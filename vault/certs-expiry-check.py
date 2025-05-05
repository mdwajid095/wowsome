#!/usr/bin/env python
import hvac
import os
from cryptography.hazmat.primitives.serialization.pkcs12 import load_key_and_certificates
import base64

# export VAULT_TOKEN=hvs.wowCAESILggL6LoBkfMie_BlB2PswowzYM7Tcd9v-_f7_hrOYP7Gh4KHGh2cy5sUHA0VVNGQW9WNVdvQ1JlZjN3ZVJlYTI
# export VAULT_ADDR=https://dot-wow-portal.de.pri.o2.com
MOUNT_POINT = 'servers'
VAULT_BASE = "Applications/U-654-WOW/e2e2/certs/ClientCerts/"

client = hvac.Client(url=os.environ['VAULT_ADDR'], token=os.environ['VAULT_TOKEN'], verify=True)

def authenticate_client():
    if client.is_authenticated():
        print('Authenticated successfully')
    else:
        print('Authentication failed')

def list_kv(path: str) -> list:
    resp = []
    list_secrets_result = client.secrets.kv.v2.list_secrets(path=path, mount_point=MOUNT_POINT)
    for key in list_secrets_result['data']['keys']:
        resp.append(path + key)
    return resp

def print_certificate_expiry(path: str):
    secret = client.secrets.kv.v2.read_secret(path, mount_point=MOUNT_POINT)['data']['data']
    passphrase = secret['passphrase'].strip()
    keystore = base64.b64decode(secret['keystore.p12'])
    # print(secret)
    private_key, certificate, additional_certificates = load_key_and_certificates(keystore, passphrase.encode())
    print(f"Certificate Subject: {certificate.subject.rfc4514_string()}")
    print(f"Certificate Expiry in UTC: {certificate.not_valid_after_utc}")
    print("-----*-----*-----*---*---*---*---*---*-----*-----*-----")

def recurse_and_print(path: str):
    keys = list_kv(path)
    # print(keys)
    for key in keys:
        if key.endswith('/'):
            recurse_and_print(key)
        else:
            print_certificate_expiry(key)

if __name__ == "__main__":
    authenticate_client()
    recurse_and_print(VAULT_BASE)
