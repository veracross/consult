curl \
    --request PUT \
    --data @spec/support/consul-services.json \
    http://0.0.0.0:8500/v1/catalog/register

curl \
    -H "X-Vault-Token: 94e1a9ed-5d72-5677-27ab-ebc485cca368" \
    -X POST \
    --data @spec/support/vault-test-data.json \
    http://127.0.0.1:8200/v1/secret/data/database_credentials

curl \
    --request PUT \
    --data 'db1.local.net' \
    http://0.0.0.0:8500/v1/kv/infrastructure/db1/dns
