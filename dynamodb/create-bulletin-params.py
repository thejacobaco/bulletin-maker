import boto3

# Create a DynamoDB client
dynamodb = boto3.client('dynamodb', region_name='us-east-1', endpoint_url="http://localhost:8000")  # Replace the region_name and endpoint_url with appropriate values

# Define the table schema
table_name = 'BulletinParams'
key_schema = [
    {
        'AttributeName': 'service_date',
        'KeyType': 'HASH'  # Partition key
    }
]
attribute_definitions = [
    {
        'AttributeName': 'service_date',
        'AttributeType': 'S'
    },
]
provisioned_throughput = {
    'ReadCapacityUnits': 10,
    'WriteCapacityUnits': 10
}

# Create the table only if it does not already exist
try:
    dynamodb.describe_table(TableName=table_name)
    print(f"Table {table_name} already exists.")
except dynamodb.exceptions.ResourceNotFoundException:
    response = dynamodb.create_table(
        TableName=table_name,
        KeySchema=key_schema,
        AttributeDefinitions=attribute_definitions,
        ProvisionedThroughput=provisioned_throughput
    )
    print(f"Table {table_name} has been created. Status: {response['TableDescription']['TableStatus']}")
