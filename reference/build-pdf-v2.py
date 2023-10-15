from reportlab.platypus import SimpleDocTemplate, PageTemplate, Frame, Paragraph, Spacer
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet

# Create a PDF document
doc = SimpleDocTemplate("example.pdf", pagesize=letter)

# Define frames within a page template
frame1 = Frame(doc.leftMargin, doc.bottomMargin, doc.width / 2 - 6, doc.height, id='frame1')
frame2 = Frame(doc.leftMargin + doc.width / 2 + 6, doc.bottomMargin, doc.width / 2 - 6, doc.height, id='frame2')

# Create a page template with the defined frames
page_template = PageTemplate(frames=[frame1, frame2])

# Add the page template to the document
doc.addPageTemplates(page_template)

# Create content to be placed in frames
styles = getSampleStyleSheet()
styles['Normal'].alignment = 0  # Justify alignment

# Generate a list of paragraphs
paragraphs = []
for i in range(1, 41):  # Generate 40 paragraphs for demonstration
    text = f"This is paragraph {i}. " * 10  # Create a long text for demonstration
    p = Paragraph(text, styles['Normal'])
    paragraphs.append(p)

# Create a Story to contain paragraphs
story = []

for i, paragraph in enumerate(paragraphs):
    if i % 2 == 0:
        frame1.add(paragraph, doc)
    else:
        frame2.add(paragraph, doc)

    # Add spacing between frames if needed
    if i < len(paragraphs) - 1:
        story.append(Spacer(1, 12))

# Build the PDF document using the Story
doc.build(story)

print("PDF generated.")