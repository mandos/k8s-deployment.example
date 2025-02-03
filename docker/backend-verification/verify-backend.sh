#!/bin/sh
set -e
# set -x

# This script is designed to validate certain aspects of the backend services setup.
# In a real-world scenario, this would typically be implemented as a smoke test.
# However, for my use case, the script primarily checks:
# - Kubernetes configuration
# - Integration with HashiCorp Vault and SOPS
#
# Important Notes:
# The script outputs some secrets for debugging purposes, which should not be allowed in a production setup.

RESPONSE=$(mktemp)

if [ -z "$BACKEND_HOST" ]; then
    echo "Missing BACKEND_HOST environment variable in validation backend pod"
    ERROR=true
fi

if [ -z "$BACKEND_PORT" ]; then
    echo "Missing BACKEND_PORT environment variable in validation backend pod"
    ERROR=true
fi

curl --silent --fail-with-body -o "$RESPONSE" "$BACKEND_HOST:$BACKEND_PORT/api?env=true"

jq . "$RESPONSE"

ERROR=false

CHECK="DB_HOST DB_PORT DB_USER DB_PASSWORD"

# Checking if in backend service are correct configuration, mostly check correct
# settings of K8s secrets and Vault/SOPS
for env_var in $CHECK; do
    RESULT="$(jq --arg var "$env_var" '.environ | has($var)' "$RESPONSE")"
    if [ "false" = "$RESULT" ]; then
        echo "Missing $env_var environment variable in backend service configuration"
        ERROR=true
    fi
done

# We want to have same parameters here to check communication with Database
for env_var in $CHECK; do
    if [ -z "$env_var" ]; then
        echo "Missing $env_var environment variable in validation backend pod"
        ERROR=true
    fi
done

echo
echo "Database configuration:"
echo "DB_HOST=$DB_HOST"
echo "DB_PORT=$DB_PORT"
echo "DB_USER=$DB_USER"
echo

# Checking connection with database, checking if:
# - there are correct vaules in secret
# - Postgresql is operate and has correct configuration
# - there is correct K8s network communication between backend and database
if ! pg_isready --host="$DB_HOST" --port="$DB_PORT"; then
    ERROR=true
fi

if ! PGPASSWORD="$DB_PASSWORD" psql --quiet --host="$DB_HOST" --port="$DB_PORT" --user="$DB_USER" --command="SELECT * FROM pg_catalog.pg_tables;"; then
    ERROR=true
fi

if [ "$ERROR" = "true" ]; then
    echo "Validation errors!!!"
    exit 1
fi
