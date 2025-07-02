import pymupdf
import pytesseract
from pdf2image import convert_from_path
from pypdf import PdfReader


def scanned_pdf_to_searchable(input_pdf_path, output_pdf_path, dpi=150):
    print("Loading PDF...")
    doc = pymupdf.open()

    num_pages = len(PdfReader(input_pdf_path).pages)

    for i in range(num_pages):
        print(f"Processing page {i+1}/{num_pages}...")
        images = convert_from_path(input_pdf_path, dpi=dpi, first_page=i+1, last_page=i+1)
        image = images[0]

        pdf_bytes = pytesseract.image_to_pdf_or_hocr(image, extension='pdf')
        temp_doc = pymupdf.open("pdf", pdf_bytes)
        doc.insert_pdf(temp_doc)

    doc.save(output_pdf_path)
    doc.close()
    print(f"Searchable PDF saved to: {output_pdf_path}")


pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
input_pdf = "scanned_book.pdf"
output_pdf = "searchable_book.pdf"
scanned_pdf_to_searchable(input_pdf, output_pdf)
