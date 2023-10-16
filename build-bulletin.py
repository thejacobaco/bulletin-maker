# Import necessary modules from ReportLab
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib import colors, utils
from reportlab.graphics.shapes import Rect, Drawing
from reportlab.platypus import (
    BaseDocTemplate, PageTemplate, PageBreak, Frame, FrameBreak, Spacer, Paragraph, Table, TableStyle, Image
)
from reportlab.platypus.flowables import Flowable

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
        self.style = {
            'centered_large': ParagraphStyle(
                name="CenteredLarge",
                fontSize=14,
                leading=14,
                alignment=1
            ),
            'centered': ParagraphStyle(
                name="Centered",
                alignment=1
            )
        }
        
        # Create a BaseDocTemplate for the PDF document
        doc = BaseDocTemplate(
            'bulletin.pdf',           # PDF file name
            pagesize=landscape(A4),     # Landscape A4 page size
            topMargin=bulletin_constants.TOP_MARGIN,           # Top margin of 1 inch
            bottomMargin=bulletin_constants.BOTTOM_MARGIN,        # Bottom margin of 1 inch
            leftMargin=bulletin_constants.LEFT_MARGIN,          # Left margin of 1 inch
            rightMargin=bulletin_constants.RIGHT_MARGIN)         # Right margin of 1 inch
        
        self.doc = doc

        # Define the number of frames, width, and height for each frame
        frameCount = 2
        frameWidth = doc.width / frameCount
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
                x1=doc.leftMargin + frameWidth,
                y1=doc.bottomMargin,
                width=frameWidth,
                height=frameHeight),
        ]

        # Add the page template with the defined frames to the document
        doc.addPageTemplates([PageTemplate(id='frames', frames=frame_list), ])

        # Create a list to store the content (story) of the PDF
        self.story = []

        self.data = BulletinData()

    def build(self):
        # Print the back of the bulletin
        self._print_back_page()

        # Add a FrameBreak to jump to the next frame
        self.story.append(FrameBreak())

        # Print the front of the bulletin
        self._print_front_page()

        # Add a PageBreak to move to the next page
        #self.story.append(PageBreak())

        # Build the PDF document using the defined story
        self.doc.build(self.story)

    def _print_back_page(self):
        # Add Welcome! Section
        self._print_welcome()

        # Add the custom element to the Story
        self._print_announcements()

        self.story.append(Spacer(0, 0.25 * inch))

        # Add the serving schedule section
        self._print_serving_schedule()

    def _print_welcome(self):
        welcome = [Paragraph("<b>WELCOME!</b>", self.style['centered']),Paragraph("<b>Welcome to the holy service of worship to the Triune God of Creation and Redemption. It is a great privilege to gather to worship the King of kings. If you are visiting with us, we warmly welcome you, and look forward to getting to know you better in our fellowship time after worship. May God’s high feast day be a delight to your soul as you commune with Him in worship!</b>")]
        self.story.append(RectWithTable(self.frameWidth, self.frameHeight/6, [[element] for element in welcome]))

    def _print_announcements(self):
        announcements = [Paragraph("<b>ANNOUNCEMENTS</b>", self.style['centered'])] + self.data.get_announcements()
        # Create a custom RectWithTable element
        self.story.append(RectWithTable(self.frameWidth, self.frameHeight/1.7, [[element] for element in announcements]))

    def _print_serving_schedule(self):
        headers = [Paragraph("<b><u>SERVING SCHEDULE</u></b>"), Paragraph("<b>Today:</b>"), Paragraph("<b>Next Week:</b>")]
        snack_schedule = self.data.get_coffee_snack_schedule()
        midweek_theme_schedule = self.data.get_midweek_theme_schedule()
        data = [
            headers,
            [Paragraph("<b>Coffee Snack:</b>"), snack_schedule[0], snack_schedule[1]],
            [Paragraph("<b>Midweek Theme:</b>"), midweek_theme_schedule[0], midweek_theme_schedule[1]]
        ]
        self.story.append(Table(
            data=data,
            style=[]
        ))

    def _print_front_page(self):
        self._print_pilgrim_title()
        self.story.append(Spacer(0, 0.25 * inch))
        self._print_pilgrim_image()
        self.story.append(Spacer(0, 0.25 * inch))
        self._print_bottom_of_front_page()

    def _print_pilgrim_title(self):
        # Add text to the second frame
        self.story.append(
            Paragraph(
                '<b>P I L G R I M</b>',
                ParagraphStyle(
                    name='PilgrimTitle',
                    fontSize=48,
                    leading=60,
                    alignment=1
                ),
            )
        )
        self.story.append(
            Paragraph(
                "<b>PRESBYTERIAN CHURCH</b>",
                ParagraphStyle(
                    name='PilgrimTitle2',
                    fontSize=24,
                    leading=36,
                    alignment=1,
                ),
            )
        )
        self.story.append(
            Paragraph(
                "<b><i>A Congregation of the Orthodox Presbyterian Church</i></b>",
                ParagraphStyle(
                    name='Centered',
                    alignment=1
                )
            )
        )
        self.story.append(
            Paragraph(
                "<b>Metamora, Michigan</b>",
                self.style['centered_large']
            )
        )

    def _print_pilgrim_image(self):
        # Add the PNG image to the PDF
        img = utils.ImageReader('pilgrim.PNG')  # Replace 'example.png' with the path to your PNG file
        img_width, img_height = img.getSize()
        aspect_ratio = img_height / img_width
        image = Image('pilgrim.PNG', width=self.frameWidth/1.5, height=self.frameWidth/1.5 * aspect_ratio)  # Adjust the width and height as needed
        self.story.append(image)

    def _print_bottom_of_front_page(self):
        self.story.append(
            Paragraph(
                f"<b>THE LORD'S DAY<br/><i>{self.data.date}</i></b>",
                self.style['centered_large']
            )
        )
        
        self.story.append(Spacer(0, 0.15 * inch))

        self.story.append(
            Paragraph(
                "<b>MORNING WORSHIP — 11:00 AM / EVENING WORSHIP — 6:00 PM</b>",
                self.style['centered']
            )
        )

        self.story.append(Spacer(0, 0.15 * inch))

        self.story.append(
            Paragraph(
                "<b><i>“Blessed is the people that know the joyful sound: They shall walk, O Lord, in the light of your countenance. In Your name shall they rejoice all the day; and in your righteousness they shall be exalted.”</i><br/>Psalm 89:15-16 — Inscribed on the church bell in 1878.</b>",
                self.style['centered']
            )
        )


# Check if this script is the main module
if __name__ == "__main__":
    builder = BulletinBuilder()
    builder.build()