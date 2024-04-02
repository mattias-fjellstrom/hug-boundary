The generated credentials can be used like so:

```shell
export BOUNDARY_ADDR=""

# unset aws environment variables
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SECURITY_TOKEN

# fetch the lambda url
FUNCTION_URL=$(aws lambda get-function-url-config --function-name boundary-target --query 'FunctionUrl' --output text)

# authenticate to boundary
BOUNDARY_AUTH_METHOD_ID=$(boundary auth-methods list -recursive -format=json | jq -rc '.items[] | select(.name == "Entra ID") | .id')
boundary authenticate oidc -auth-method-id="$BOUNDARY_AUTH_METHOD_ID"

# authorize session to target to get aws credentials
BOUNDARY_SCOPE_ID=$(boundary scopes list -recursive -format=json | jq -rc '.items[] | select(.name == "AWS Resources") | .id')
BOUNDARY_TARGET_ID=$(boundary targets list -scope-id=$BOUNDARY_SCOPE_ID -format=json | jq -rc '.items[] | select(.name == "aws-lambda") | .id')
boundary targets authorize-session \
    -id=$BOUNDARY_TARGET_ID \
    -format=json | jq -r '.item.credentials[] | .secret | .decoded | .access_key + " " + .secret_key + " " + .security_token' | read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SECURITY_TOKEN

echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID\nAWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY\nAWS_SECURITY_TOKEN=$AWS_SECURITY_TOKEN"

# send the request to the lambda function
curl \
    --aws-sigv4 "aws:amz:eu-west-1:lambda" \
    --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
    -H "x-amz-security-token: $AWS_SECURITY_TOKEN" \
    $FUNCTION_URL
```