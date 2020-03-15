#!/usr/bin/env bash

apt-get install -y libaio1

sudo mkdir -pm 0755 /data/vault/raft /data/vault/plugins /data/vault/ssl /etc/vault.d
sudo chown -R vault:vault /data/vault/raft /data/vault/plugins /data/vault/ssl /etc/vault.d

cat << EOF > /etc/vault.d/vault.hcl
storage "raft" {
  path = "/data/vault/raft"
  node_id = "demo"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable = "false"
  tls_key_file = "/data/vault/ssl/privkey.pem"
  tls_cert_file = "/data/vault/ssl/fullchain.pem"
  tls_min_version = "tls12"
}

seal "awskms" {
  region     = "${aws_region}"
  kms_key_id = "${kms_key}"
}

api_addr = "https://127.0.0.1:8200"
cluster_addr = "https://127.0.0.1:8201"

disable_mlock="false"
disable_cache="false"
ui = "true"

max_lease_ttl="24h"
default_lease_ttl="1h"

raw_storage_endpoint=true

cluster_name="hashi-vault"

insecure_tls="true"

plugin_directory="/data/vault/plugins"
EOF

cat << EOF > /etc/profile.d/vault.sh
export VAULT_ADDR=https://127.0.0.1:8200
export VAULT_SKIP_VERIFY=true
EOF

sudo apt-get install -y docker.io

# install pki cert
cat << EOF > /data/vault/ssl/privkey.pem
${tls_private_key}
EOF

cat << EOF > /data/vault/ssl/fullchain.pem
${tls_fullchain}
EOF

sudo systemctl enable vault
sudo systemctl start vault

export VAULT_ADDR=https://127.0.0.1:8200

# make sure Vault is up before proceeding
vault_http_return_code=0
while [ "$vault_http_return_code" != "501" ]
do
  vault_http_return_code=$(curl --insecure -s -o /dev/null -w "%%{http_code}" $VAULT_ADDR/v1/sys/health)
  sleep 1
done

# initialize vault
touch /etc/vault.d/vault_init_output /etc/vault.d/vaultrc
chmod 0600 /etc/vault.d/vault_init_output /etc/vault.d/vaultrc

curl --insecure -s --header "X-Vault-Request: true" --request PUT --data '{"recovery_shares":1,"recovery_threshold":1}' $VAULT_ADDR/v1/sys/init > /etc/vault.d/vault_init_output
export VAULT_ROOT_TOKEN=$(cat /etc/vault.d/vault_init_output | jq -r '.root_token')

cat << EOF > /etc/vault.d/vaultrc
#!/bin/bash

export VAULT_ROOT_TOKEN=$VAULT_ROOT_TOKEN
export VAULT_ADDR=https://127.0.0.1:8200
export VAULT_SKIP_VERIFY=true

EOF

# make sure vault is initialized before proceeding
vault_http_return_code=0
while [ "$vault_http_return_code" != "200" ]
do
  vault_http_return_code=$(curl --insecure -s -o /dev/null -w "%%{http_code}" $VAULT_ADDR/v1/sys/health)
  sleep 1
done

# install license
curl \
  --insecure \
  --header "X-Vault-Token: $VAULT_ROOT_TOKEN" \
  --request PUT \
  --data "{\"text\": \"${vault_license}\"}" $VAULT_ADDR/v1/sys/license
