#!/bin/bash

VAULT_RETRIES=5

until vault status > /dev/null 2>&1 || [ "$VAULT_RETRIES" -eq 0 ]; do
        echo "Waiting for vault to start...: $((VAULT_RETRIES--))"
        sleep 1
done
vault login token=vault-plaintext-root-token
vault secrets enable -version=2 -path=my.secrets kv
vault kv put my.secrets/dev username=test_user
vault kv put my.secrets/dev password=test_password
