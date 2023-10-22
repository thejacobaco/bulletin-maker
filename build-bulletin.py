# Import necessary modules from ReportLab
from reportlab.lib.pagesizes import LETTER, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib import colors, utils
from reportlab.graphics.shapes import Rect, Drawing
from reportlab.platypus import (
    BaseDocTemplate, PageTemplate, PageBreak, Frame, FrameBreak, Spacer, Paragraph, Table, TableStyle, Image
)
from reportlab.platypus.flowables import Flowable
from reportlab.lib.enums import TA_RIGHT

# CUSTOM CODE
from bulletin_data import BulletinData
import bulletin_constants

# Create a custom Flowable to enclose the rectangle and table with bold text
class RectWithTable(Flowable):
    def __init__(self, width, height, data):
        Flowable.__init__(self)
        self.width = width
        self.height = height
        self.data = data

    def draw(self):
        self.canv.setStrokeColor(colors.black)
        self.canv.rect(0, 0, self.width, self.height)

        # Create a table with bold text
        table = Table(self.data, colWidths=self.width)
        table.setStyle(TableStyle([
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER')
        ]))

        # Draw the table inside the rectangle
        table.wrapOn(self.canv, self.width, self.height)
        table.drawOn(self.canv, 0, self.height - table._height)


class BulletinBuilder():
    def __init__(self):
        # Define a custom ParagraphStyle for text formatting
        #self.style_1 = ParagraphStyle(
        #    name='Stylo',
        #    fontName='Helvetica',
        #    fontSize=10,
        #    leading=12)
        self.fontName = "Times-Roman"
        self.style = {
            'regular': ParagraphStyle(
                name="Regular",
                fontName=self.fontName
            ),
            'large': ParagraphStyle(
                name="Large",
                fontName=self.fontName,
                fontSize=12,
                leading=12
            ),
            'centered_large': ParagraphStyle(
                name="CenteredLarge",
                fontName=self.fontName,
                fontSize=12,
                leading=12,
                alignment=1
            ),
            'xlarge': ParagraphStyle(
                name="XLarge",
                fontName=self.fontName,
                fontSize=14,
                leading=14
            ),
            'centered_xlarge': ParagraphStyle(
                name="CenteredXLarge",
                fontName=self.fontName,
                fontSize=14,
                leading=14,
                alignment=1
            ),
            'centered': ParagraphStyle(
                name="Centered",
                fontName=self.fontName,
                alignment=1
            ),
            'right': ParagraphStyle(
                name="RightAligned",
                fontName=self.fontName,
                alignment=TA_RIGHT
            ),
            'bulletin_title': ParagraphStyle(
                name='PilgrimTitle',
                fontName=self.fontName,
                fontSize=48,
                leading=60,
                alignment=1
            ),
            'bulletin_subtitle': ParagraphStyle(
                name='PilgrimTitle2',
                fontName=self.fontName,
                fontSize=24,
                leading=36,
                alignment=1,
            ),
        }
        
        # Create a BaseDocTemplate for the PDF document
        doc = BaseDocTemplate(
            'bulletin.pdf',           # PDF file name
            pagesize=landscape(LETTER),     # Landscape A4 page size
            topMargin=bulletin_constants.TOP_MARGIN,           # Top margin of 1 inch
            bottomMargin=bulletin_constants.BOTTOM_MARGIN,        # Bottom margin of 1 inch
            leftMargin=bulletin_constants.LEFT_MARGIN,          # Left margin of 1 inch
            rightMargin=bulletin_constants.RIGHT_MARGIN)         # Right margin of 1 inch

        self.doc = doc

        # Define the number of frames, width, and height for each frame
        frameMargin = 50
        frameCount = 2
        frameWidth = (doc.width / frameCount) - frameMargin / frameCount
        frameHeight = doc.height - 0.05*inch
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight

        # Create a list of frames
        frame_list = [
            Frame(
                x1=doc.leftMargin,
                y1=doc.bottomMargin,
                width=frameWidth,
                height=frameHeight),
            Frame(
                x1=doc.leftMargin + frameWidth + frameMargin,
                y1=doc.bottomMargin,
                width=frameWidth,
                height=frameHeight),
        ]

        # Add the page template with the defined frames to the document
        doc.addPageTemplates([PageTemplate(id='frames', frames=frame_list), ])

        # Create a list to store the content (story) of the PDF
        self.story = []

    def hspace(self, points):
        self.story.append(Spacer(0, points))

    def build(self, service_date):
        self.data = BulletinData(service_date)
        # Print the back of the bulletin
        self._print_back_page()

        # Add a FrameBreak to jump to the next frame
        self.story.append(FrameBreak())

        # Print the front of the bulletin
        self._print_front_page()

        # Add a PageBreak to move to the logical inner side of the bulletin
        self.story.append(PageBreak())

        self._print_morning_worship()

        self.story.append(FrameBreak())

        self._print_evening_worship()

        # Build the PDF document using the defined story
        self.doc.build(self.story)

    def _print_back_page(self):
        # Add Welcome! Section
        self._print_welcome()

        # Add the custom element to the Story
        self._print_announcements()

        self.hspace(0.25 * inch)

        # Add the serving schedule section
        self._print_serving_schedule()

    def _print_welcome(self):
        welcome = [Paragraph("<b>WELCOME!</b>", self.style['centered']),Paragraph("<b>Welcome to the holy service of worship to the Triune God of Creation and Redemption. It is a great privilege to gather to worship the King of kings. If you are visiting with us, we warmly welcome you, and look forward to getting to know you better in our fellowship time after worship. May God’s high feast day be a delight to your soul as you commune with Him in worship!</b>", self.style['regular'])]
        self.story.append(RectWithTable(self.frameWidth, self.frameHeight/6, [[element] for element in welcome]))

    def _print_announcements(self):
        announcements = [Paragraph("<b>ANNOUNCEMENTS</b>", self.style['centered'])] + [Paragraph(item, self.style['regular']) for item in self.data.params.get('announcements')]
        # Create a custom RectWithTable element
        self.story.append(RectWithTable(self.frameWidth, self.frameHeight/1.7, [[element] for element in announcements]))

    def _print_serving_schedule(self):
        headers = [Paragraph("<b><u>SERVING SCHEDULE</u></b>", self.style['regular']), Paragraph("<b>Today:</b>", self.style['regular']), Paragraph("<b>Next Week:</b>", self.style['regular'])]
        snack_schedule = self.data.params.get('coffee_snack_schedule')
        midweek_theme_schedule = self.data.params.get('midweek_theme_schedule')
        data = [
            headers,
            [Paragraph("<b>Coffee Snack:</b>", self.style['regular']), Paragraph(snack_schedule[0], self.style['regular']), Paragraph(snack_schedule[1], self.style['regular'])],
            [Paragraph("<b>Midweek Theme:</b>", self.style['regular']), Paragraph(midweek_theme_schedule[0], self.style['regular']), Paragraph(midweek_theme_schedule[1], self.style['regular'])]
        ]
        self.story.append(Table(
            data=data,
            style=[]
        ))

    def _print_front_page(self):
        self._print_pilgrim_title()
        self.hspace(0.25 * inch)
        self._print_pilgrim_image()
        self.hspace(0.25 * inch)
        self._print_bottom_of_front_page()

    def _print_pilgrim_title(self):
        # Add text to the second frame
        self.story.append(
            Paragraph(
                '<b>P I L G R I M</b>',
                self.style['bulletin_title'],
            )
        )
        self.story.append(
            Paragraph(
                "<b>PRESBYTERIAN CHURCH</b>",
                self.style['bulletin_subtitle']
            )
        )
        self.story.append(
            Paragraph(
                "<b><i>A Congregation of the Orthodox Presbyterian Church</i></b>",
                self.style['centered']
            )
        )
        self.story.append(
            Paragraph(
                "<b>Metamora, Michigan</b>",
                self.style['centered_xlarge']
            )
        )

    def _print_pilgrim_image(self):
        # Add the PNG image to the PDF
        img = utils.ImageReader('pilgrim.PNG')  # Replace 'example.png' with the path to your PNG file
        img_width, img_height = img.getSize()
        aspect_ratio = img_height / img_width
        image = Image('pilgrim.PNG', width=self.frameWidth/1.2, height=self.frameWidth/1.2 * aspect_ratio)  # Adjust the width and height as needed
        self.story.append(image)

    def _print_bottom_of_front_page(self):
        self.story.append(
            Paragraph(
                f"<b>THE LORD'S DAY<br/><i>{self.data.params.get('date')}</i></b>",
                self.style['centered_xlarge']
            )
        )
        
        self.hspace(0.15 * inch)

        self.story.append(
            Paragraph(
                "<b>MORNING WORSHIP — 11:00 AM / EVENING WORSHIP — 6:00 PM</b>",
                self.style['centered']
            )
        )

        self.hspace(0.15 * inch)

        self.story.append(
            Paragraph(
                "<b><i>“Blessed is the people that know the joyful sound: They shall walk, O Lord, in the light of your countenance. In Your name shall they rejoice all the day; and in your righteousness they shall be exalted.”</i><br/>Psalm 89:15-16 — Inscribed on the church bell in 1878.</b>",
                self.style['centered']
            )
        )
    
    def _print_morning_worship(self):
        self.story.append(Paragraph(
            "<b>MORNING WORSHIP</b>",
            self.style['centered_xlarge']
        ))
        self.hspace(0.1 * inch)

        self._print_leading_elders()

        self.hspace(0.2 * inch)

        self._print_order_of_worship("morning")
    
    def _print_leading_elders(self):
        data = [
            [Paragraph("<b>Leading in Worship:</b>", self.style['centered']), Paragraph("<b>Preaching:</b>", self.style['centered'])],
            [Paragraph(self.data.params.get('leading_in_worship'), self.style['centered']), Paragraph(self.data.params.get('preaching'), self.style['centered'])]
        ]

        self.story.append(Table(
            data,
            colWidths=120,
            style=[
                ('ALIGN', (0, 0), (-1,-1), 'CENTER')
            ]
        ))

    def _print_order_of_worship(self, service):
        oow = self.data.generate_oow(service)
        for section in oow['sections']:
            self._print_oow_section(section['title'], section['content'])
        self.story.append(Paragraph(
            oow['benediction_song'],
            self.style['xlarge']
        ))
        if service == 'morning':
            self.story.append(Paragraph(
                "<i>* Congregation standing</i>",
                self.style['right']
            ))


    def _print_oow_section(self, title, content):
        # How to indent and some have bullets and some don't?
        # Maybe use a table

        self.story.append(Paragraph(
            f"<b>{title}</b>",
            self.style['large']
        ))

        self.story.append(Table(
            data=[[("*" if 'footnote' in line else ''), Paragraph(line['text'], self.style['large'])] for line in content],
            colWidths=(0.10 * inch, self.frameWidth - 0.10 * inch),
            style=[
                ('LEFTPADDING', (1,0), (1, -1), 0.5 * inch)
            ]
        ))

    def _print_evening_worship(self):
        self.story.append(Paragraph(
            "<b>EVENING WORSHIP</b>",
            self.style['centered_xlarge']
        ))

        self.hspace(0.2 * inch)

        self._print_order_of_worship("evening")

        self.hspace(0.2 * inch)

        self._print_congregational_confession()

    def _print_congregational_confession(self):
        data = [
            [Paragraph(f"<b>{self.data.params['corporate_confession_title']}</b>", self.style['centered_large'])],
            [Paragraph(self.data.params['corporate_confession_text'], self.style['large'])]
        ]
        self.story.append(RectWithTable(self.frameWidth, self.frameHeight/3.3, data))


        



# Check if this script is the main module
if __name__ == "__main__":
    builder = BulletinBuilder()
    builder.build('2023-08-20')