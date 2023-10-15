# Import necessary modules from ReportLab
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.graphics.shapes import Rect, Drawing
from reportlab.platypus import (
    BaseDocTemplate, PageTemplate, PageBreak, Frame, FrameBreak, Spacer, Paragraph, Table, TableStyle
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
        # Add Welcome! Section
        self._print_welcome()

        # Add the custom element to the Story
        self._print_announcements()

        # Add a FrameBreak to jump to the next frame
        self.story.append(FrameBreak())

        # Add text to the second frame
        self.story.append(
            Paragraph(
                'This should be on the top of the 2nd Frame!',
                ))

        # Add a PageBreak to move to the next page
        #self.story.append(PageBreak())

        # Build the PDF document using the defined story
        self.doc.build(self.story)

    def _print_welcome(self):
        data = [["WELCOME!"],[Paragraph("Welcome to the holy service of worship to the Triune God of Creation and Redemption. It is a great privilege to gather to worship the King of kings. If you are visiting with us, we warmly welcome you, and look forward to getting to know you better in our fellowship time after worship. May God’s high feast day be a delight to your soul as you commune with Him in worship!")]]
        self.story.append(Table(
            data=data,
            colWidths=self.frameWidth,
            style=[
                # The two (0, 0) in each attribute represent the range of table cells that the style applies to. Since there's only one cell at (0, 0), it's used for both start and end of the range
                ('ALIGN', (0, 0), (0, 0), 'CENTER'),
                ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#000000')), # The fourth argument to this style attribute is the border width
                ('VALIGN', (0, 0), (0, 0), 'TOP'),
                ('BOTTOMPADDING', (0, 1), (0, 1), 14),
            ]
        ))

    def _print_announcements(self):
        announcements = ["ANNOUNCEMENTS"] + self.data.get_announcements()
        # Create a custom RectWithTable element
        self.story.append(RectWithTable(self.frameWidth, self.frameHeight/1.7, [[element] for element in announcements]))


# Check if this script is the main module
if __name__ == "__main__":
    builder = BulletinBuilder()
    builder.build()