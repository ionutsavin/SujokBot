import os
import re
import shutil
from pathlib import Path
from langchain_community.document_loaders import PyMuPDFLoader
from langchain_chroma import Chroma
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter

from utils.embedding import get_embedding_function


def load_and_index_pdfs(pdf_directory="../data", reset_db=False):
    if reset_db:
        print("Clearing Database")
        clear_database()

    pdf_files = get_pdf_files(pdf_directory)
    if not pdf_files:
        print(f"No PDF files found in directory: {pdf_directory}")
        return False

    print(f"Found {len(pdf_files)} PDF files to process")

    all_chunks = []
    successful_files = 0

    for pdf_path in pdf_files:
        print(f"\nProcessing: {pdf_path}")
        documents = load_pdf_documents(pdf_path)

        if documents:
            chunks = split_pdf_pages_by_section_titles(documents, pdf_path)
            all_chunks.extend(chunks)
            successful_files += 1
            print(f"Successfully processed {pdf_path}")
        else:
            print(f"Failed to process {pdf_path}")

    if all_chunks:
        add_to_chroma(all_chunks)
        print(f"\nSummary: Successfully processed {successful_files}/{len(pdf_files)} PDF files")
        print(f"Total chunks created: {len(all_chunks)}")
        return True
    else:
        print("No documents were successfully processed")
        return False


def get_pdf_files(directory):
    pdf_directory = Path(directory)

    if not pdf_directory.exists():
        print(f"Directory does not exist: {directory}")
        return []

    if not pdf_directory.is_dir():
        print(f"Path is not a directory: {directory}")
        return []

    pdf_files = []
    for file_path in pdf_directory.iterdir():
        if file_path.is_file() and file_path.suffix.lower() == '.pdf':
            pdf_files.append(str(file_path))

    return sorted(pdf_files)


def load_pdf_documents(pdf_path):
    try:
        loader = PyMuPDFLoader(pdf_path)
        documents = loader.load()
        print(f"  Loaded {len(documents)} pages from {os.path.basename(pdf_path)}")
        return documents
    except Exception as e:
        print(f"  Error loading PDF {os.path.basename(pdf_path)}: {e}")
        return []


def clean_text(text):
    text = re.sub(r'Scanned by CamScanner', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\n{2,}', '\n', text)
    text = re.sub(r'\b\d{1,2}\s*$', '', text, flags=re.MULTILINE)
    text = re.sub(r'(Fingertoe Therapy| Su jok Seed Therapy)', '', text, flags=re.IGNORECASE)
    text = re.sub(r' {2,}', ' ', text)
    return text.strip()


def split_pdf_pages_by_section_titles(pages, pdf_path):
    full_text = "\n".join(page.page_content for page in pages)
    full_text = clean_text(full_text)
    section_pattern = re.compile(r'\n(?=[A-Z0-9][A-Z0-9\s,:-]{6,}\n)', flags=re.MULTILINE)
    raw_sections = section_pattern.split(full_text)

    chunks = []
    pdf_filename = os.path.basename(pdf_path)

    print("\nDetected section titles:")
    section_count = 0

    for idx, section in enumerate(raw_sections):
        cleaned = clean_text(section)
        if len(cleaned) < 150:
            print(f"Skipping short section {idx + 1} (length {len(cleaned)})")
            continue

        lines = cleaned.splitlines()
        title_line = next((line.strip() for line in lines if line.strip()), f"Untitled Section {idx}")
        print(f"Section {section_count + 1}: '{title_line}'")

        if len(cleaned) > 3000:
            print(f"Splitting section '{title_line}' into sub-chunks")
            splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)
            sub_chunks = splitter.split_text(cleaned)
        else:
            sub_chunks = [cleaned]

        for i, sub_chunk in enumerate(sub_chunks):
            metadata = {
                "source": pdf_filename,
                "title": title_line.strip()
            }
            chunks.append(Document(page_content=sub_chunk.strip(), metadata=metadata))

        section_count += 1

    print(f"Split into {len(chunks)} total chunks (with sub-chunks if needed)")
    return chunks


def add_to_chroma(chunks):
    embedding_function = get_embedding_function()
    db = Chroma(
        persist_directory="../chroma",
        embedding_function=embedding_function,
        collection_metadata={"hnsw:space": "cosine"}
    )

    chunks_with_ids = calculate_chunk_ids(chunks)
    existing_items = db.get(include=[])
    existing_ids = set(existing_items["ids"])
    print(f"\nNumber of existing documents in DB: {len(existing_ids)}")

    new_chunks = []
    for chunk in chunks_with_ids:
        if chunk.metadata["id"] not in existing_ids:
            new_chunks.append(chunk)

    if new_chunks:
        print(f"Adding new documents: {len(new_chunks)}")
        new_chunk_ids = [chunk.metadata["id"] for chunk in new_chunks]
        db.add_documents(new_chunks, ids=new_chunk_ids)
        print("New documents added to the database")
    else:
        print("No new documents to add")


def calculate_chunk_ids(chunks):
    for idx, chunk in enumerate(chunks):
        source_name = chunk.metadata.get('source', 'unknown')
        section = chunk.metadata.get('section', 0)
        chunk.metadata["id"] = f"{source_name}_{section}_{idx}"
    return chunks


def clear_database():
    if os.path.exists("../chroma"):
        shutil.rmtree("../chroma")


if __name__ == "__main__":
    load_and_index_pdfs(pdf_directory="../data", reset_db=True)
