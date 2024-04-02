# Connection workflow

```shell
export BOUNDARY_ADDR=""

# authenticate to boundary
BOUNDARY_AUTH_METHOD_ID=$(boundary auth-methods list -recursive -format=json | jq -rc '.items[] | select(.name == "Entra ID") | .id')
boundary authenticate oidc -auth-method-id="$BOUNDARY_AUTH_METHOD_ID"

# connect
BOUNDARY_SCOPE_ID=$(boundary scopes list -recursive -format=json | jq -rc '.items[] | select(.name == "AWS Resources") | .id')
BOUNDARY_TARGET_ID=$(boundary targets list -scope-id="$BOUNDARY_SCOPE_ID" -format=json | jq -rc '.items[] | select(.name == "aws-eks-nginx-app") | .id')

boundary connect http -target-id=$BOUNDARY_TARGET_ID -scheme=http
```