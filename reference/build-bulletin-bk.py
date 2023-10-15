# Import necessary modules from ReportLab
import random
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.graphics.shapes import Rect, Drawing
from reportlab.platypus import (
    BaseDocTemplate, PageTemplate, PageBreak, Frame, FrameBreak, Spacer, Paragraph, Table, TableStyle
)
from reportlab.platypus.flowables import Flowable

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

# Check if this script is the main module
if __name__ == "__main__":
    # Define a custom ParagraphStyle for text formatting
    style_1 = ParagraphStyle(
        name='Stylo',
        fontName='Helvetica',
        fontSize=10,
        leading=12)

    # Create a BaseDocTemplate for the PDF document
    doc = BaseDocTemplate(
        'test_spacer.pdf',           # PDF file name
        pagesize=landscape(A4),     # Landscape A4 page size
        topMargin=0.25*inch,           # Top margin of 1 inch
        bottomMargin=0.25*inch,        # Bottom margin of 1 inch
        leftMargin=0.25*inch,          # Left margin of 1 inch
        rightMargin=0.25*inch)         # Right margin of 1 inch

    # Define the number of frames, width, and height for each frame
    frameCount = 2
    frameWidth = doc.width / frameCount
    frameHeight = doc.height - 0.05*inch

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
    story = []

    data = [["WELCOME!"],['''Welcome to the holy service of worship to the Triune God of Creation and
Redemption. It is a great privilege to gather to worship the King of kings.
If you are visiting with us, we warmly welcome you, and look forward to
getting to know you better in our fellowship time after worship. May
God’s high feast day be a delight to your soul as you commune with Him
in worship!''']]
    t = Table(
        data=data,
        colWidths=frameWidth,
        style=[
            # The two (0, 0) in each attribute represent the range of table cells that the style applies to. Since there's only one cell at (0, 0), it's used for both start and end of the range
            ('ALIGN', (0, 0), (0, 0), 'CENTER'),
            ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#000000')), # The fourth argument to this style attribute is the border width
            ('VALIGN', (0, 0), (0, 0), 'TOP'),
            ('BOTTOMPADDING', (0, 1), (0, 1), 14),
        ]
    )
    story.append(t)

    announcements = [
        "ANNOUNCEMENTS",
        Paragraph("<b>Corporate Prayer Meeting:</b> Prayer meeting prior to the worship service beginning at 10:15 am. Corporate prayer is an excellent way to prepare your heart for worship."),
        Paragraph("<b>Evening Worship:</b> Please join us tonight as we continue our sermon series through Genesis— <i>The Sabbath; A Creation Ordinance</i>"),
    ]

    # Create a custom RectWithTable element
    announcements_section = RectWithTable(frameWidth, frameHeight/1.7, [[element] for element in announcements])

    # Add the custom element to the Story
    story.append(announcements_section)

    # Add a FrameBreak to jump to the next frame
    story.append(FrameBreak())

    # Add text to the second frame
    story.append(
        Paragraph(
            'This should be on the top of the 2nd Frame!',
            style_1))

    # Add a PageBreak to move to the next page
    story.append(PageBreak())

    # Build the PDF document using the defined story
    doc.build(story)