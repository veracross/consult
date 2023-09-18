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
    -H "Content-Type: application/x-www-form-urlencoded; charset=utf-8" \
    --data $'Earth is the <%= vars[:earth] %>th element 🌎\n' \
    http://localhost:8500/v1/kv/templates/elements/earth

curl \
    --request PUT \
    -H "Content-Type: application/x-www-form-urlencoded; charset=utf-8" \
    --data $'Love is the <%= vars[:love] %>th element! 💗\n' \
    http://localhost:8500/v1/kv/templates/elements/love

curl \
    --request PUT \
    -H "Content-Type: application/x-www-form-urlencoded; charset=utf-8" \
    --data $'Aziz! <%= vars[:aziz] %> 🙄\n' \
    http://localhost:8500/v1/kv/templates/elements/aziz

curl \
    --request PUT \
    -H "Content-Type: application/x-www-form-urlencoded; charset=utf-8" \
    --data $'<%= vars.fetch(:missing) %>\n' \
    http://localhost:8500/v1/kv/templates/var-missing

curl \
    --request PUT \
    -H "Content-Type: application/x-www-form-urlencoded; charset=utf-8" \
    --data-binary @spec/support/templates/query-test.yml.erb \
    http://localhost:8500/v1/kv/templates/db/db1

curl \
    --request POST \
    --data @spec/support/consul-query.json \
    http://localhost:8500/v1/query
