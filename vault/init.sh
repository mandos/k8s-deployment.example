#!/bin/sh

vault auth enable -path vis kubernetes
vault write auth/vis/config kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"
vault secrets enable -path=vis kv-v2

tee /tmp/database-read.hcl <<EOF
path "vis/data/database" {
    capabilities = ["read", "list"]
}
EOF

vault policy write database /tmp/database-read.hcl

vault write auth/vis/role/app1 \
    bound_service_account_names=app1-back \
    bound_service_account_namespaces=backend \
    policies=database \
    audience=vault \
    ttl=24h

vault secrets enable -path=vis-transit transit
tee /tmp/cache.hcl <<EOF
path "vis-transit/encrypt/vso-client-cache" {
   capabilities = ["create", "update"]
}
path "vis-transit/decrypt/vso-client-cache" {
   capabilities = ["create", "update"]
}
EOF

vault policy write vault-operator-cache /tmp/cache.hcl

vault write auth/vis/role/auth-role-operator \
    bound_service_account_names=vault-operator-vault-secrets-operator-controller-manager \
    bound_service_account_namespaces=vault \
    policies=vault-operator-cache \
    audience=vault \
    ttl=24h

vault kv put vis/database DB_HOST="database" DB_USER="app1_user" DB_PASSWORD="app1_password"
