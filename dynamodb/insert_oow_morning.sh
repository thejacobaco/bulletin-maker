#!/bin/bash

# Set the AWS region and profile
AWS_REGION="us-east-1"
AWS_PROFILE="default"  # Replace with your AWS profile if necessary

# Define the table name
TABLE_NAME="OrdersOfWorship"

# Define the JSON document to be inserted
JSON_DOC='{
    "service_id": {"S": "morning"},
    "benediction_song": {
        "S": "<i>“Blessed be the Lord, the God of Israel from everlasting ev’n to everlasting. Let all the people say, “Amen!” Praise ye the Lord!”</i>"
    },
    "sections": {
        "L": [
            {
                "M": {
                    "title": {"S": "BEFORE WORSHIP"},
                    "content": {"L": [
                        {"M": {"text": {"S": "Please take this time to quiet your hearts"}}},
                        {"M": {"text": {"S": "Welcome, announcements, and silent prayer"}}}
                    ]}
                }
            },
            {
                "M": {
                    "title": {"S": "GOD CALLS HIS PEOPLE TO WORSHIP"},
                    "content": {"L": [
                        {"M": {"text": {"S": "Call to Worship - {{ call_to_worship_verse }}"}, "footnote": {"BOOL": true}}},
                        {"M": {"text": {"S": "Invocation"}, "footnote": {"BOOL": true}}},
                        {"M": {"text": {"S": "{{ call_to_worship_song }}"}, "footnote": {"BOOL": true}}},
                        {"M": {"text": {"S": "OT Reading: {{ ot_reading }}"}}}
                    ]}
                }
            },
            {
                "M": {
                    "title": {"S": "GOD HEARS HIS PEOPLE’S CONFESSION"},
                    "content": {"L": [
                        {"M": {"text": {"S": "Corporate Confession of Faith <i>(see insert)</i>"}}}
                    ]}
                }
            },
            {
                "M": {
                    "title": {"S": "GOD’S ASSURANCE THROUGH CHRIST"},
                    "content": {"L": [
                        {"M": {"text": {"S": "God’s assurance of pardon: {{ assurance_of_pardon_verse }}"}}},
                        {"M": {"text": {"S": "{{ assurance_song }}"}, "footnote": {"BOOL": true}}},
                        {"M": {"text": {"S": "Pastoral prayer"}}}
                    ]}
                }
            },
            {
                "M": {
                    "title": {"S": "GOD RECEIVES HIS PEOPLE’S GIFTS OF LOVE"},
                    "content": {"L": [
                        {"M": {"text": {"S": "Giving of Tithes and Offerings"}}},
                        {"M": {"text": {"S": "Offertory response: Hymn 367"}, "footnote": {"BOOL": true}}},
                        {"M": {"text": {"S": "<i>(1st verse; sung unannounced)</i>"}}}
                    ]}
                }
            },
            {
                "M": {
                    "title": {"S": "GOD INSTRUCTS HIS PEOPLE FROM HIS WORD"},
                    "content": {"L": [
                        {"M": {"text": {"S": "Reading God’s Word: {{ sermon_verse }}"}, "footnote": {"BOOL": true}}},
                        {"M": {"text": {"S": "Preaching God’s Word: <i>{{ sermon_title }}</i>"}}},
                        {"M": {"text": {"S": "{{ sermon_song }}"}, "footnote": {"BOOL": true}}}
                    ]}
                }
            },
            {
                "M": {
                    "title": {"S": "GOD BLESSES HIS PEOPLE IN CHRIST - BENEDICTION"},
                    "content": {"L": [
                        {"M": {"text": {"S": "Psalm 106G"}, "footnote": {"BOOL": true}}}
                    ]}
                }
            }
        ]
    }
}'

# Insert the JSON document into the DynamoDB table
aws dynamodb put-item \
        --table-name $TABLE_NAME \
        --item "$JSON_DOC" \
        --region $AWS_REGION \
        --profile $AWS_PROFILE \
        --endpoint-url http://localhost:8000

echo "JSON document has been inserted into the table."