curl \
    --request PUT \
    --data @spec/support/consul-services.json \
    http://localhost:8500/v1/catalog/register

curl \
    -H "X-Vault-Token: 94e1a9ed-5d72-5677-27ab-ebc485cca368" \
    -X POST \
    --data @spec/support/vault-test-data.json \
    http://localhost:8200/v1/secret/data/database_credentials

curl \
    --request PUT \
    --data 'db1.local.net' \
    http://localhost:8500/v1/kv/infrastructure/db1/dns

curl \
    --request PUT \
    --data $'Earth is the <%= vars[:earth] %>th element\n' \
    http://localhost:8500/v1/kv/templates/elements/earth

curl \
    --request PUT \
    --data $'Love is the <%= vars[:love] %>th element!\n' \
    http://localhost:8500/v1/kv/templates/elements/love

curl \
    --request PUT \
    --data $'Aziz! <%= vars[:aziz] %>\n' \
    http://localhost:8500/v1/kv/templates/elements/aziz
