"""Vector Search Service for Neovim Telescope integration.

Semantic code search using OpenSearch for vector storage and
sentence-transformers for embedding generation.  Indexes code files
per-directory with persistent on-disk storage via OpenSearch.

Usage:
    uvicorn app.main:app --host 0.0.0.0 --port 9876
"""

import hashlib
import os
import threading

from fastapi import FastAPI
from opensearchpy import OpenSearch, helpers
from pydantic import BaseModel

app = FastAPI(title="Vector Search Service")

OPENSEARCH_URL = os.environ.get("OPENSEARCH_URL", "http://localhost:9200")
EMBEDDING_MODEL = os.environ.get("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
EMBEDDING_DIM = 384

os_client = OpenSearch(
    hosts=[OPENSEARCH_URL],
    use_ssl=False,
    verify_certs=False,
)

# Lazy-loaded so the heavy torch import only happens at first use,
# and tests can mock get_model() without installing sentence-transformers.
_model = None


def get_model():
    global _model
    if _model is None:
        from sentence_transformers import SentenceTransformer

        _model = SentenceTransformer(EMBEDDING_MODEL)
    return _model


CODE_EXTENSIONS = {
    ".py", ".js", ".ts", ".tsx", ".jsx", ".lua", ".rs", ".go", ".java",
    ".c", ".h", ".cpp", ".hpp", ".cs", ".rb", ".php", ".swift", ".kt",
    ".scala", ".sh", ".bash", ".zsh", ".vim", ".sql", ".html", ".css",
    ".scss", ".less", ".yaml", ".yml", ".toml", ".json", ".xml", ".md",
    ".txt", ".cfg", ".ini", ".conf", ".tf", ".hcl", ".ex", ".exs",
    ".r", ".jl", ".zig", ".nim", ".ml", ".mli", ".hs",
}

SKIP_DIRS = {
    ".git", ".svn", ".hg", "node_modules", "__pycache__", ".venv", "venv",
    ".env", "env", ".tox", ".mypy_cache", ".pytest_cache", "dist", "build",
    ".next", ".nuxt", "target", "vendor", ".idea", ".vscode", ".cache",
    "site-packages", ".eggs",
}

MAX_FILE_SIZE = 1_000_000  # 1MB

indexing_status: dict = {}
indexing_lock = threading.Lock()

INDEX_MAPPING = {
    "settings": {
        "index": {
            "knn": True,
        },
    },
    "mappings": {
        "properties": {
            "content": {"type": "text"},
            "embedding": {
                "type": "knn_vector",
                "dimension": EMBEDDING_DIM,
                "method": {
                    "name": "hnsw",
                    "space_type": "cosinesimil",
                    "engine": "lucene",
                },
            },
            "file": {"type": "keyword"},
            "line": {"type": "integer"},
        },
    },
}


def dir_index_name(directory: str) -> str:
    h = hashlib.sha256(directory.encode()).hexdigest()[:16]
    return f"vector_search_{h}"


class IndexRequest(BaseModel):
    directory: str
    force: bool = False


class SearchRequest(BaseModel):
    query: str
    directory: str
    n_results: int = 20


def walk_and_chunk(directory: str) -> list[dict]:
    """Walk *directory*, read code files, and split into overlapping chunks.

    Returns a list of dicts with keys ``file``, ``line``, and ``content``.
    Pure function — no side-effects, easy to test.
    """
    chunks: list[dict] = []

    for root, dirs, files in os.walk(directory):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".")]

        for fname in files:
            fpath = os.path.join(root, fname)
            ext = os.path.splitext(fname)[1].lower()

            if ext not in CODE_EXTENSIONS:
                continue

            try:
                size = os.path.getsize(fpath)
                if size > MAX_FILE_SIZE or size == 0:
                    continue
            except OSError:
                continue

            try:
                with open(fpath, "r", encoding="utf-8", errors="ignore") as f:
                    lines = f.readlines()
            except Exception:
                continue

            if not lines:
                continue

            rel_path = os.path.relpath(fpath, directory)

            # Sliding window: 30 lines, 10-line overlap → step of 20
            chunk_size = 30
            overlap = 10
            step = chunk_size - overlap

            i = 0
            while i < len(lines):
                chunk_lines = lines[i : i + chunk_size]
                text = "".join(chunk_lines).strip()

                if text:
                    chunks.append({
                        "file": rel_path,
                        "line": i + 1,  # 1-indexed
                        "content": text,
                    })

                i += step

    return chunks


@app.get("/health")
def health():
    return {"status": "ok"}


def _do_index(directory: str, index_name: str):
    """Background indexing worker."""
    try:
        if os_client.indices.exists(index=index_name):
            os_client.indices.delete(index=index_name)

        os_client.indices.create(index=index_name, body=INDEX_MAPPING)

        chunks = walk_and_chunk(directory)

        if chunks:
            texts = [c["content"] for c in chunks]
            embeddings = get_model().encode(texts, show_progress_bar=False)

            actions = [
                {
                    "_index": index_name,
                    "_id": f"chunk_{i}",
                    "_source": {
                        "content": chunk["content"],
                        "file": chunk["file"],
                        "line": chunk["line"],
                        "embedding": emb.tolist(),
                    },
                }
                for i, (chunk, emb) in enumerate(zip(chunks, embeddings))
            ]
            helpers.bulk(os_client, actions)

        with indexing_lock:
            indexing_status[index_name] = {
                "status": "done",
                "chunks": len(chunks),
                "directory": directory,
            }

    except Exception as e:
        with indexing_lock:
            indexing_status[index_name] = {
                "status": "error",
                "error": str(e),
                "directory": directory,
            }


@app.post("/index")
def index_directory(req: IndexRequest):
    directory = os.path.abspath(req.directory)
    if not os.path.isdir(directory):
        return {"error": "Directory not found", "directory": directory}

    index_name = dir_index_name(directory)

    with indexing_lock:
        current = indexing_status.get(index_name, {})
        if current.get("status") == "indexing":
            return {"status": "already_indexing", "directory": directory}

    if not req.force:
        try:
            if os_client.indices.exists(index=index_name):
                count = os_client.count(index=index_name)["count"]
                if count > 0:
                    return {
                        "status": "already_indexed",
                        "directory": directory,
                        "chunks": count,
                    }
        except Exception:
            pass

    with indexing_lock:
        indexing_status[index_name] = {"status": "indexing", "directory": directory}

    thread = threading.Thread(
        target=_do_index, args=(directory, index_name), daemon=True
    )
    thread.start()

    return {"status": "indexing_started", "directory": directory}


@app.post("/search")
def search(req: SearchRequest):
    directory = os.path.abspath(req.directory)
    index_name = dir_index_name(directory)

    try:
        if not os_client.indices.exists(index=index_name):
            return {
                "results": [],
                "error": "Directory not indexed. Run :VectorSearchIndex",
            }
    except Exception:
        return {
            "results": [],
            "error": "Directory not indexed. Run :VectorSearchIndex",
        }

    try:
        count = os_client.count(index=index_name)["count"]
    except Exception:
        count = 0

    if count == 0:
        return {"results": [], "error": "Index is empty"}

    query_embedding = get_model().encode([req.query], show_progress_bar=False)[0]

    n = min(req.n_results, 50)
    body = {
        "size": n,
        "query": {
            "knn": {
                "embedding": {
                    "vector": query_embedding.tolist(),
                    "k": n,
                },
            },
        },
        "_source": ["file", "line", "content"],
    }

    results = os_client.search(index=index_name, body=body)

    search_results = []
    for hit in results["hits"]["hits"]:
        src = hit["_source"]
        content = src.get("content", "")
        first_line = ""
        if content:
            for line in content.split("\n"):
                stripped = line.strip()
                if stripped:
                    first_line = stripped
                    break

        search_results.append({
            "file": src["file"],
            "line": src["line"],
            "text": first_line,
            "distance": round(1 - hit.get("_score", 0), 4),
        })

    return {"results": search_results}


@app.get("/status")
def get_status(directory: str = ""):
    if not directory:
        return {"error": "Provide ?directory= parameter"}

    directory = os.path.abspath(directory)
    index_name = dir_index_name(directory)

    with indexing_lock:
        status = indexing_status.get(index_name, {})

    try:
        exists = os_client.indices.exists(index=index_name)
        count = os_client.count(index=index_name)["count"] if exists else 0
    except Exception:
        count = 0

    return {
        "directory": directory,
        "indexed": count > 0,
        "chunks": count,
        "indexing_status": status.get("status", "unknown"),
    }
