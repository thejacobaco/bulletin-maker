from reportlab.lib.pagesizes import landscape, letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Frame, PageTemplate, PageBreak
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import inch

# Create a custom function to generate paragraphs
def generate_paragraphs():
    paragraphs = []
    for i in range(1, 17):
        text = f"This is paragraph {i}. " * 10  # Create a long text for demonstration
        p = Paragraph(text, styles['Normal'])
        paragraphs.append(p)
    return paragraphs

# Define the PDF filename
pdf_filename = "double_column_page.pdf"

# Create a landscape page with two columns
doc = SimpleDocTemplate(pdf_filename, pagesize=landscape(letter))

# Define the styles for paragraphs
styles = getSampleStyleSheet()
styles['Normal'].alignment = 0  # Justify alignment

# Create a Story (list of elements to be added to the PDF)
story = []

# Generate paragraphs
paragraphs = generate_paragraphs()

# Split paragraphs into two columns
column_width = doc.width / 2
column_height = doc.height

left_column = []
right_column = []

for i, paragraph in enumerate(paragraphs):
    if i % 2 == 0:
        left_column.append(paragraph)
    else:
        right_column.append(paragraph)

# Create frames for each column
frame_left = Frame(doc.leftMargin, doc.bottomMargin, column_width, column_height, id='left')
frame_right = Frame(doc.leftMargin + column_width, doc.bottomMargin, column_width, column_height, id='right')

# Create a custom page template with two columns
page_template = PageTemplate(id='double_column', frames=[frame_left, frame_right])

# Add the page template to the document
doc.addPageTemplates([page_template])

# Add the left and right columns to the Story
story.extend(left_column)
#story.append(Spacer(1, 0.5 * inch))  # Adjust spacing between columns
story.append(PageBreak())
story.extend(right_column)

# Build the PDF document
doc.build(story)

print(f"PDF generated: {pdf_filename}")