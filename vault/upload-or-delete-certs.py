import hvac
import os
import base64

# export VAULT_TOKEN=hvs.wowCAESILggL6LoBkfMie_BlB2PsFjBzwowYM7Tcd9v-_f7_hrOYP7Gh4KHGh2cy5sUHA0VVNGQW9WNVdvQ1JlZjN3ZVJlYTI
# export VAULT_ADDR=https://dot-wow-portal.de.pri.o2.com
MOUNT_POINT = 'servers'
VAULT_BASE = "Applications/U-654-WOW/ict/certs/ClientCerts/"

client = hvac.Client(url=os.environ['VAULT_ADDR'], token=os.environ['VAULT_TOKEN'], verify=True)

def authenticate_client():
    if client.is_authenticated():
        print('Authenticated successfully')
    else:
        print('Authentication failed')
        exit(1)

def list_certs(path: str) -> list:
    resp = []
    list_secrets_result = client.secrets.kv.v2.list_secrets(path=path, mount_point=MOUNT_POINT)
    for key in list_secrets_result['data']['keys']:
        resp.append(path + key)
    return resp

def upload_certificate(app_name, keystore_path):
    with open(keystore_path, 'rb') as f:
        keystore_data = f.read()

    keystore_base64 = base64.b64encode(keystore_data).decode('utf-8')
    passphrase = input("Enter the passphrase for the keystore: ").strip()

    secret_path = f"Applications/U-654-EMP/ict/certs/ClientCerts/{app_name}"
    secret_data = {
        'keystore.p12': keystore_base64,
        'passphrase': passphrase
    }

    client.secrets.kv.v2.create_or_update_secret(
        path=secret_path,
        secret=secret_data,
        mount_point='servers'
    )
    print(f"Certificate uploaded to Vault at path: {secret_path}")

def delete_certificate(app_name):
    secret_path = f"Applications/U-654-EMP/ict/certs/ClientCerts/{app_name}"
    client.secrets.kv.v2.delete_metadata_and_all_versions(
        path=secret_path,
        mount_point=MOUNT_POINT
    )
    print(f"Certificate deleted from Vault at path: {secret_path}")

if __name__ == "__main__":
    authenticate_client()
    print(list_certs(VAULT_BASE))
    # app_name = input("Enter the application name: ").strip()
    # keystore_path = input("Enter the path to the keystore file: ").strip()
    # delete_certificate(app_name)
    # upload_certificate(app_name, keystore_path)
