#!/bin/bash

# THIS WILL REMOVE ALL CLOUDWATCH LOGS IN THE REGION!
# UNCOMMENT TO ALLOW THIS :)

# logGroups=($(aws logs describe-log-groups \
#     --query 'logGroups[].logGroupName' \
#     --output text))

# for logGroup in "${logGroups[@]}"
# do
#     echo "Deleting log group $logGroup"
#     aws logs delete-log-group --log-group-name "$logGroup"
# done