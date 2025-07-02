import torch
from langchain_huggingface import HuggingFaceEmbeddings


def get_embedding_function():
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    embeddings = HuggingFaceEmbeddings(
        model_name="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
        model_kwargs={'device': device},
    )
    return embeddings
