from reportlab.platypus import Paragraph
from jinja2 import Template

class BulletinData():
    def __init__(self):
        self.params = self.fetch_bulletin_params()
        self.orders_of_worship = self.fetch_oow()

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
        }
    
    # This will eventually be in a 'oow_templates' table in dynamodb
    # Should let the user edit this template and type the mustache syntax into these things and set the footnote boolean
    def fetch_oow(self):
        return {
            'morning': {
                'benediction_song': "<i>“Blessed be the Lord, the God of Israel from everlasting ev’n to everlasting. Let all the people say, “Amen!” Praise ye the Lord!”</i>",
                'sections': [
                    {
                        'title': "BEFORE WORSHIP",
                        'content': [
                            {
                                'text': "Please take this time to quiet your hearts"
                            },
                            {
                                'text': "Welcome, announcements, and silent prayer"
                            }
                        ]
                    },
                    {
                        'title': "GOD CALLS HIS PEOPLE TO WORSHIP",
                        'content': [
                            {
                                'text': "Call to Worship - {{ call_to_worship_verse }}",
                                'footnote': True,
                            },
                            {
                                'text': "Invocation",
                                'footnote': True,
                            },
                            {
                                'text': "{{ call_to_worship_song }}",
                                'footnote': True,
                            },
                            {
                                'text': "OT Reading: {{ ot_reading }}"
                            }
                        ]
                    },
                    {
                        'title': "GOD HEARS HIS PEOPLE’S CONFESSION",
                        'content': [
                            {'text': "Corporate Confession of Faith <i>(see insert)</i>"}
                        ],
                    },
                    {
                        'title': "GOD’S ASSURANCE THROUGH CHRIST",
                        'content': [
                            {'text': "God’s assurance of pardon: {{ assurance_of_pardon_verse }}"},
                            {'text': "{{ assurance_song }}", 'footnote': True},
                            {'text': "Pastoral prayer"}
                        ],
                    },
                    {
                        'title': "GOD RECEIVES HIS PEOPLE’S GIFTS OF LOVE",
                        'content': [
                            {'text': "Giving of Tithes and Offerings"},
                            {'text': "Offertory response: Hymn 367", 'footnote': True},
                            {'text': "<i>(1st verse; sung unannounced)</i>"}
                        ],
                    },
                    {
                        'title': "GOD INSTRUCTS HIS PEOPLE FROM HIS WORD",
                        'content': [
                            {'text': "Reading God’s Word: {{ sermon_verse }}", 'footnote': True},
                            {'text': "Preaching God’s Word: <i>{{ sermon_title }}</i>"},
                            {'text': "{{ sermon_song }}", 'footnote': True},
                        ],
                    },
                    {
                        'title': "GOD BLESSES HIS PEOPLE IN CHRIST - BENEDICTION",
                        'content': [
                            {'text': "Psalm 106G", 'footnote': True},
                        ],
                    },
                ]
            }
        }
    
    def generate_oow(self, service):
        oow = self.orders_of_worship[service]
        for section in oow['sections']:
            for line in section['content']:
                line['text'] = Template(line['text']).render(self.params)
        return oow