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

    # Loop through a list of letters ['A', 'B', 'C']
    '''
    d = Drawing(frameWidth/2, frameHeight/2)
    r = Rect(0, 0, frameWidth/2, frameHeight/2, fillColor=None, strokeColor=colors.black)
    d.add(r)

    # Add text to the first frame
    for _ in range(3):
        d.add(
            )

    story.append(d)
    '''
    data = [["WELCOME!"],['''Welcome to the holy service of worship to the Triune God of Creation and
Redemption. It is a great privilege to gather to worship the King of kings.
If you are visiting with us, we warmly welcome you, and look forward to
getting to know you better in our fellowship time after worship. May
God’s high feast day be a delight to your soul as you commune with Him
in worship!''']]
    t = Table(
        data=data,
        colWidths=frameWidth,
        #rowHeights=frameHeight/4.5,
        style=[
            # The two (0, 0) in each attribute represent the range of table cells that the style applies to. Since there's only one cell at (0, 0), it's used for both start and end of the range
            ('ALIGN', (0, 0), (0, 0), 'CENTER'),
            ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#000000')), # The fourth argument to this style attribute is the border width
            ('VALIGN', (0, 0), (0, 0), 'TOP'),
            ('BOTTOMPADDING', (0, 1), (0, 1), 14),
        ]
    )
    drawing = 
    rectangle = Rect(
        0,
        0,
        frameWidth,
        frameHeight/1.7,
        fillColor=None,
        strokeColor=colors.black,
        strokeWidth=1,
    )
    story.append(rectangle)

    announcements = [
        "ANNOUNCEMENTS",
        Paragraph("<b>Corporate Prayer Meeting:</b> Prayer meeting prior to the worship service beginning at 10:15 am. Corporate prayer is an excellent way to prepare your heart for worship."),
        Paragraph("<b>Evening Worship:</b> Please join us tonight as we continue our sermon series through Genesis— <i>The Sabbath; A Creation Ordinance</i>"),
    ]

    t2 = Table(
        data=[[element] for element in announcements],
        colWidths=frameWidth,
        #rowHeights=frameHeight/1.7,
        style=[
            # The two (0, 0) in each attribute represent the range of table cells that the style applies to. Since there's only one cell at (0, 0), it's used for both start and end of the range
            ('ALIGN', (0, 0), (0, 0), 'CENTER'),
            #('BOX', (0, 0), (0, 0), 1, colors.HexColor('#000000')), # The fourth argument to this style attribute is the border width
            ('VALIGN', (0, 0), (0, 0), 'TOP'),
        ]
    )

    story.append(t)
    story.append(t2)

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