#!/bin/bash

# Set the AWS region and profile
AWS_REGION="us-east-1"
AWS_PROFILE="default"  # Replace with your AWS profile if necessary

# Define the table name
TABLE_NAME="BulletinParams"

# Define the JSON document to be inserted
JSON_DOC='{
    "service_date": {"S": "2023-08-20"},
    "announcements": {"L": [
        {"S": "<b>Corporate Prayer Meeting:</b> Prayer meeting prior to the worship service beginning at 10:15 am. Corporate prayer is an excellent way to prepare your heart for worship."},
        {"S": "<b>Evening Worship:</b> Please join us tonight as we continue our sermon series through Genesis— <i>The Sabbath; A Creation Ordinance</i>"},
        {"S": "<b>Metamora Days</b> this year is scheduled for August 26th. Please make every effort to attend and represent our church to the community."},
        {"S": "<b>Family Night</b> will begin <i>Wednesday, September 13th</i>. We will begin with a family-style meal at 6:00 with classes beginning at 7:00pm."},
        {"S": "<b>Conference on Church and Government</b> will be hosted at Pilgrim by Ralph Rebandt on <i>Saturday, September 30th</i>. More details to follow."},
        {"S": "Did you know? Pilgrim has an <b>email distribution list!</b> If you are not currently receiving emails from Pilgrim and would like to be added to the list, please email Cera Pesole at cera.pesole@gmail.com and she will get you added."}
    ]},
    "coffee_snack_schedule": {"L": [{"S": "Swayze & Monroe"}, {"S": "Spencley & Howell"}]},
    "midweek_theme_schedule": {"L": [{"S": "Fall Favourites"}, {"S": "Breakfast for Dinner"}]},
    "date": {"S": "August 20th, 2023"},
    "leading_in_worship": {"S": "Elder Ernie Monroe"},
    "preaching": {"S": "Rev. David Bonner"},
    "call_to_worship_verse": {"S": "1 Corinthians 15:42-49"},
    "call_to_worship_song": {"S": "Hymn #271"},
    "ot_reading": {"S": "Isaiah 44"},
    "assurance_of_pardon_verse": {"S": "Hebrews 9:11-15"},
    "assurance_song": {"S": "Psalm 138B"},
    "sermon_verse": {"S": "John 20:19-31"},
    "sermon_title": {"S": "Assent To The Truth"},
    "sermon_song": {"S": "Hymn #216"},
    "evening_call_to_worship_verse": {"S": "Revelation 22:1-5"},
    "evening_call_to_worship_song": {"S": "Psalm 19B"},
    "nt_reading": {"S": "Hebrews 4"},
    "evening_congregational_reading": {"S": "WCF 21.7"},
    "evening_confession_song": {"S": "Psalm 92A"},
    "evening_sermon_verse": {"S": "Genesis 2:1-3"},
    "evening_sermon_title": {"S": "The Sabbath; A Creation Ordinance"},
    "evening_sermon_song": {"S": "Hymn #609"},
    "corporate_confession_title": {"S": "WESTMINSTER CONFESSION OF FAITH 21.7 Of The Sabbath Day"},
    "corporate_confession_text": {"S": "As it is of the law of nature, that, in general, a due proportion of time be set apart for the worship of God; so, in His Word, by a positive, moral, and perpetual commandment, binding all men in all ages, he hath particularly appointed one day in seven for a Sabbath, to be kept holy unto Him: which, from the beginning of the world to the resurrection of Christ, was the last day of the week; and, from the resurrection of Christ, was changed into the first day of the week, which in Scripture is called the Lord’s Day, and is to be continued to the end of the world as the Christian Sabbath."},
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