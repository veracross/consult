curl \
    --request PUT \
    --data @spec/support/consul-services.json \
    http://0.0.0.0:8500/v1/catalog/register

curl \
    -H "X-Vault-Token: 94e1a9ed-5d72-5677-27ab-ebc485cca368" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"username":"kylo.ren", "password":"v4d3r_4eva"}' \
    http://127.0.0.1:8200/v1/secret/database_credentials
