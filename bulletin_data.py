from reportlab.platypus import Paragraph
from jinja2 import Template
import boto3
from botocore.exceptions import ClientError

class BulletinData():
    def __init__(self):
        self.params = self.fetch_bulletin_params()
        self.dynamodb = boto3.resource('dynamodb', region_name='us-east-1', endpoint_url='http://localhost:8000')

    # Refactor this to store OOW params by their oow and take note of the fact we know exactly what variables will need to be replaced in there
    # for validation, etc
    def fetch_bulletin_params(self):
        return {
            'announcements': [
                Paragraph("<b>Corporate Prayer Meeting:</b> Prayer meeting prior to the worship service beginning at 10:15 am. Corporate prayer is an excellent way to prepare your heart for worship."),
                Paragraph("<b>Evening Worship:</b> Please join us tonight as we continue our sermon series through Genesis— <i>The Sabbath; A Creation Ordinance</i>"),
                Paragraph("<b>Metamora Days</b> this year is scheduled for August 26th. Please make every effort to attend and represent our church to the community."),
                Paragraph("<b>Family Night</b> will begin <i>Wednesday, September 13th</i>. We will begin with a family-style meal at 6:00 with classes beginning at 7:00pm."),
                Paragraph("<b>Conference on Church and Government</b> will be hosted at Pilgrim by Ralph Rebandt on <i>Saturday, September 30th</i>. More details to follow."),
                Paragraph("Did you know? Pilgrim has an <b>email distribution list!</b> If you are not currently receiving emails from Pilgrim and would like to be added to the list, please email Cera Pesole at cera.pesole@gmail.com and she will get you added.")
            ],
            'coffee_snack_schedule': ["Swayze & Monroe", "Spencley & Howell"],
            'midweek_theme_schedule': ["Fall Favourites", "Breakfast for Dinner"],
            'date': "August 20th, 2023",
            'leading_in_worship': "Elder Ernie Monroe",
            'preaching': "Rev. David Bonner",
            'call_to_worship_verse': "1 Corinthians 15:42-49",
            'call_to_worship_song': "Hymn #271",
            'ot_reading': "Isaiah 44",
            'assurance_of_pardon_verse': "Hebrews 9:11-15",
            'assurance_song': "Psalm 138B",
            'sermon_verse': "John 20:19-31",
            'sermon_title': "Assent To The Truth",
            'sermon_song': "Hymn #216",
            'evening_call_to_worship_verse': "Revelation 22:1-5",
            'evening_call_to_worship_song': "Psalm 19B",
            'nt_reading': "Hebrews 4",
            'evening_congregational_reading': "WCF 21.7",
            'evening_confession_song': "Psalm 92A",
            'evening_sermon_verse': "Genesis 2:1-3",
            'evening_sermon_title': "The Sabbath; A Creation Ordinance",
            'evening_sermon_song': "Hymn #609",
            'corporate_confession_title': "WESTMINSTER CONFESSION OF FAITH 21.7 Of The Sabbath Day",
            'corporate_confession_text': "As it is of the law of nature, that, in general, a due proportion of time be set apart for the worship of God; so, in His Word, by a positive, moral, and perpetual commandment, binding all men in all ages, he hath particularly appointed one day in seven for a Sabbath, to be kept holy unto Him: which, from the beginning of the world to the resurrection of Christ, was the last day of the week; and, from the resurrection of Christ, was changed into the first day of the week, which in Scripture is called the Lord’s Day, and is to be continued to the end of the world as the Christian Sabbath.",
            'oow_id': {
                'morning': "morning",
                'evening': "evening",
            },
        }
    
    def generate_oow(self, service):
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