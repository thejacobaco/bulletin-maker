#!/bin/bash

# Set the AWS region and profile
AWS_REGION="us-east-1"
AWS_PROFILE="default"  # Replace with your AWS profile if necessary

# Define the table name
TABLE_NAME="OrdersOfWorship"

# Define the JSON document to be inserted
JSON_DOC='{
    "service_id": {"S": "evening"},
    "benediction_song": {"S": "<i>“All blessings to Jehovah be ascribed forever then; for evermore, so let it be. Amen, yes, and Amen.”</i>"},
    "sections": {"L": [
        {"M": {"title": {"S": "BEFORE THE WORSHIP SERVICE"}, "content": {"L": [
            {"M": {"text": {"S": "Please take this time to quiet your hearts"}}},
            {"M": {"text": {"S": "Welcome, announcements, and silent prayer"}}}
        ]}}},
        {"M": {"title": {"S": "GOD CALLS HIS PEOPLE TO WORSHIP"}, "content": {"L": [
            {"M": {"text": {"S": "Call to Worship - {{ evening_call_to_worship_verse }}"}, "footnote": {"BOOL": true}}},
            {"M": {"text": {"S": "Invocation"}, "footnote": {"BOOL": true}}},
            {"M": {"text": {"S": "{{ evening_call_to_worship_song }}"}, "footnote": {"BOOL": true}}},
            {"M": {"text": {"S": "NT Reading: {{ nt_reading }}"}}}
        ]}}},
        {"M": {"title": {"S": "GOD HEARS HIS PEOPLE’S CONFESSION"}, "content": {"L": [
            {"M": {"text": {"S": "{{ evening_congregational_reading }} <i>(see below)</i>"}}},
            {"M": {"text": {"S": "Prayer for the kingdom"}}},
            {"M": {"text": {"S": "{{ evening_confession_song }}"}, "footnote": {"BOOL": true}}}
        ]}}},
        {"M": {"title": {"S": "GOD INSTRUCTS HIS PEOPLE FROM HIS WORD"}, "content": {"L": [
            {"M": {"text": {"S": "Reading God’s Word: {{ evening_sermon_verse }}"}, "footnote": {"BOOL": true}}},
            {"M": {"text": {"S": "Preaching: <i>{{ evening_sermon_title }}</i>"}}},
            {"M": {"text": {"S": "{{ evening_sermon_song }}"}, "footnote": {"BOOL": true}}}
        ]}}},
        {"M": {"title": {"S": "GOD BLESSES HIS PEOPLE IN CHRIST - BENEDICTION"}, "content": {"L": [
            {"M": {"text": {"S": "Psalm 89H stz. 32"}, "footnote": {"BOOL": true}}}
        ]}}}
    ]}
}'

# Insert the JSON document into the DynamoDB table
aws dynamodb put-item \
        --table-name $TABLE_NAME \
        --item "$JSON_DOC" \
        --region $AWS_REGION \
        --profile $AWS_PROFILE \
        --endpoint-url http://localhost:8000

echo "JSON document has been inserted into the table."