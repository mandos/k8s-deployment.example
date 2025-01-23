#!/bin/sh
set -ex

RESPONSE=$(mktemp)

curl --silent --fail-with-body -o "$RESPONSE" "$@"

jq . "$RESPONSE"

ERROR=false

CHECK="DB_PASSWORD DB_HOST DB_USER"

for env_var in $CHECK; do
	RESULT="$(jq --arg var "$env_var" '.environ | has($var)' "$RESPONSE")"
	if [ "false" = "$RESULT" ]; then
		echo "Missing environment variable $env_var"
		ERROR=true
	fi
done

if [ "$ERROR" = "true" ]; then
	echo "Validation errors!!!"
	exit 1
fi
