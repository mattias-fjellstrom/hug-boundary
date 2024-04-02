# Connection workflow

```shell
export BOUNDARY_ADDR=""

DBNAME=postgres

# authenticate to boundary
BOUNDARY_AUTH_METHOD_ID=$(boundary auth-methods list -recursive -format=json | jq -rc '.items[] | select(.name == "Entra ID") | .id')
boundary authenticate oidc -auth-method-id="$BOUNDARY_AUTH_METHOD_ID"

# connect to read target
BOUNDARY_SCOPE_ID=$(boundary scopes list -recursive -format=json | jq -rc '.items[] | select(.name == "AWS Resources") | .id')
BOUNDARY_TARGET_ID=$(boundary targets list -scope-id="$BOUNDARY_SCOPE_ID" -format=json | jq -rc '.items[] | select(.name == "aws-aurora-read") | .id')
boundary connect postgres -target-id="$BOUNDARY_TARGET_ID" -dbname="$DBNAME"

# connect to read/write target
BOUNDARY_SCOPE_ID=$(boundary scopes list -recursive -format=json | jq -rc '.items[] | select(.name == "AWS Resources") | .id')
BOUNDARY_TARGET_ID=$(boundary targets list -scope-id="$BOUNDARY_SCOPE_ID" -format=json | jq -rc '.items[] | select(.name == "aws-aurora-read/write") | .id')
boundary connect postgres -target-id="$BOUNDARY_TARGET_ID" -dbname="$DBNAME"
```

# Fix during destroy

Destroying this configuration results in an error because Vault can't communicate with the RDS instance (for some reason yet to be found) in order to revoke active leases so the database secrets engine can't be deleted. To fix this run the following commands and then re-run the destroy operation:

```shell
export VAULT_ADDR=""
export VAULT_TOKEN=""
export VAULT_NAMESPACE=""

vault lease revoke -force -prefix database/
vault secrets disable database
```