FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-download the default embedding model used by ChromaDB
# so first startup doesn't have a long delay
RUN python -c "\
from chromadb.utils.embedding_functions import DefaultEmbeddingFunction; \
ef = DefaultEmbeddingFunction(); \
ef(['warmup'])"

COPY app/ ./app/

EXPOSE 9876

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "9876"]
