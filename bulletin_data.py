from reportlab.platypus import Paragraph

class BulletinData():
    def __init__(self):
        self.announcements = self.fetch_announcements()
        self.coffee_snack_schedule = self.fetch_coffee_snack_schedule()
        self.midweek_theme_schedule = self.fetch_midweek_theme_schedule()
        self.date = self.fetch_date()
    
    def fetch_announcements(self):
        return [
            Paragraph("<b>Corporate Prayer Meeting:</b> Prayer meeting prior to the worship service beginning at 10:15 am. Corporate prayer is an excellent way to prepare your heart for worship."),
            Paragraph("<b>Evening Worship:</b> Please join us tonight as we continue our sermon series through Genesis— <i>The Sabbath; A Creation Ordinance</i>"),
            Paragraph("<b>Metamora Days</b> this year is scheduled for August 26th. Please make every effort to attend and represent our church to the community."),
            Paragraph("<b>Family Night</b> will begin <i>Wednesday, September 13th</i>. We will begin with a family-style meal at 6:00 with classes beginning at 7:00pm."),
            Paragraph("<b>Conference on Church and Government</b> will be hosted at Pilgrim by Ralph Rebandt on <i>Saturday, September 30th</i>. More details to follow."),
            Paragraph("Did you know? Pilgrim has an <b>email distribution list!</b> If you are not currently receiving emails from Pilgrim and would like to be added to the list, please email Cera Pesole at cera.pesole@gmail.com and she will get you added.")
        ]
    
    def fetch_coffee_snack_schedule(self):
        return ["Swayze & Monroe", "Spencley & Howell"]

    def fetch_midweek_theme_schedule(self):
        return ["Fall Favourites", "Breakfast for Dinner"]
    
    def fetch_date(self):
        return "August 20th, 2023"

    def get_announcements(self):
        return self.announcements

    def get_coffee_snack_schedule(self):
        return self.coffee_snack_schedule

    def get_midweek_theme_schedule(self):
        return self.midweek_theme_schedule

    def get_date(self):
        return self.date