from reportlab.platypus import Paragraph
from jinja2 import Template
import boto3
from botocore.exceptions import ClientError

class BulletinData():
    def __init__(self, service_date):
        self.service_date = service_date
        self.dynamodb = boto3.resource('dynamodb', region_name='us-east-1', endpoint_url='http://localhost:8000')
        self.params = self.fetch_bulletin_params()

    # Refactor this to store OOW params by their oow and take note of the fact we know exactly what variables will need to be replaced in there
    # for validation, etc
    def fetch_bulletin_params(self):
        table_name = "BulletinParams"
        table = self.dynamodb.Table(table_name)
        try:
            response = table.get_item(
                Key={
                    'service_date': self.service_date
                }
            )
            item = response.get('Item', {})
            if item:
                return item
            else:
                print(f"No item found with service date: {self.service_date}")
                return {}
        except ClientError as e:
            print(f"Error retrieving item: {e.response['Error']['Message']}")

    
    def generate_oow(self, service):
        if self.params.get('oow_id') is None:
            return {}
        oow = self.fetch_oow(self.params['oow_id'][service])
        for section in oow['sections']:
            for line in section['content']:
                line['text'] = Template(line['text']).render(self.params)
        return oow

    def fetch_oow(self, service_id):
        table_name = "OrdersOfWorship"
        table = self.dynamodb.Table(table_name)
        try:
            response = table.get_item(
                Key={
                    'service_id': service_id
                }
            )
            item = response.get('Item', {})
            if item:
                return item
            else:
                print(f"No item found with service ID: {service_id}")
        except ClientError as e:
            print(f"Error retrieving item: {e.response['Error']['Message']}")

    def getSchedule(self, schedule_name):
        schedule = self.params.get(schedule_name)
        if schedule is None or len(schedule) == 0:
            schedule = ["",""]
        elif len(schedule) == 1:
            schedule.append("")
        return schedule