#!/bin/bash

# Set the AWS region and profile
AWS_REGION="us-east-1"
AWS_PROFILE="default"  # Replace with your AWS profile if necessary

# Define the table name
TABLE_NAME="BulletinParams"

# Define the JSON document to be inserted
JSON_DOC='{
    "service_date": {"S": "2023-08-27"},
    "date": {"S": "August 27th, 2023"},
    "oow_id": {"M": {
        "morning": {"S": "morning"},
        "evening": {"S": "evening"}
    }}
}'

# Insert the JSON document into the DynamoDB table
aws dynamodb put-item \
        --table-name $TABLE_NAME \
        --item "$JSON_DOC" \
        --region $AWS_REGION \
        --profile $AWS_PROFILE \
        --endpoint-url http://localhost:8000

echo "JSON document has been inserted into the table."