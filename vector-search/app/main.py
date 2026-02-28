"""Vector Search Service for Neovim Telescope integration.

Semantic code search using ChromaDB for vector storage and embedding generation.
Indexes code files per-directory with persistent on-disk storage.

Usage:
    uvicorn app.main:app --host 0.0.0.0 --port 9876
"""

import hashlib
import os
import threading
from pathlib import Path

import chromadb
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="Vector Search Service")

STORAGE_DIR = os.environ.get(
    "VECTOR_SEARCH_STORAGE",
    str(Path.home() / ".local" / "share" / "vector-search"),
)

client = chromadb.PersistentClient(path=STORAGE_DIR)

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


def dir_collection_name(directory: str) -> str:
    h = hashlib.sha256(directory.encode()).hexdigest()[:16]
    return f"dir_{h}"


class IndexRequest(BaseModel):
    directory: str
    force: bool = False


class SearchRequest(BaseModel):
    query: str
    directory: str
    n_results: int = 20


@app.get("/health")
def health():
    return {"status": "ok"}


def _do_index(directory: str, coll_name: str):
    """Background indexing worker. Walks the directory, chunks files, and stores embeddings."""
    try:
        try:
            client.delete_collection(coll_name)
        except Exception:
            pass

        collection = client.create_collection(
            name=coll_name,
            metadata={"directory": directory, "hnsw:space": "cosine"},
        )

        documents = []
        metadatas = []
        ids = []
        chunk_id = 0

        for root, dirs, files in os.walk(directory):
            # Skip unwanted directories
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

                # Sliding window chunking: 30 lines with 10-line overlap
                chunk_size = 30
                overlap = 10
                step = chunk_size - overlap

                i = 0
                while i < len(lines):
                    chunk_lines = lines[i : i + chunk_size]
                    text = "".join(chunk_lines).strip()

                    if text:
                        start_line = i + 1  # 1-indexed
                        documents.append(text)
                        metadatas.append({
                            "file": rel_path,
                            "line": start_line,
                        })
                        ids.append(f"chunk_{chunk_id}")
                        chunk_id += 1

                    i += step

        if documents:
            # ChromaDB has a batch limit, process in batches
            batch_size = 5000
            for b in range(0, len(documents), batch_size):
                collection.add(
                    documents=documents[b : b + batch_size],
                    metadatas=metadatas[b : b + batch_size],
                    ids=ids[b : b + batch_size],
                )

        with indexing_lock:
            indexing_status[coll_name] = {
                "status": "done",
                "chunks": chunk_id,
                "directory": directory,
            }

    except Exception as e:
        with indexing_lock:
            indexing_status[coll_name] = {
                "status": "error",
                "error": str(e),
                "directory": directory,
            }


@app.post("/index")
def index_directory(req: IndexRequest):
    directory = os.path.abspath(req.directory)
    if not os.path.isdir(directory):
        return {"error": "Directory not found", "directory": directory}

    coll_name = dir_collection_name(directory)

    # Check if already indexing
    with indexing_lock:
        current = indexing_status.get(coll_name, {})
        if current.get("status") == "indexing":
            return {"status": "already_indexing", "directory": directory}

    # Check if already indexed (skip unless forced)
    if not req.force:
        try:
            existing = client.get_collection(name=coll_name)
            count = existing.count()
            if count > 0:
                return {
                    "status": "already_indexed",
                    "directory": directory,
                    "chunks": count,
                }
        except Exception:
            pass

    with indexing_lock:
        indexing_status[coll_name] = {"status": "indexing", "directory": directory}

    thread = threading.Thread(
        target=_do_index, args=(directory, coll_name), daemon=True
    )
    thread.start()

    return {"status": "indexing_started", "directory": directory}


@app.post("/search")
def search(req: SearchRequest):
    directory = os.path.abspath(req.directory)
    coll_name = dir_collection_name(directory)

    try:
        collection = client.get_collection(name=coll_name)
    except Exception:
        return {"results": [], "error": "Directory not indexed. Run :VectorSearchIndex"}

    if collection.count() == 0:
        return {"results": [], "error": "Index is empty"}

    n = min(req.n_results, 50)
    results = collection.query(
        query_texts=[req.query],
        n_results=n,
        include=["documents", "metadatas", "distances"],
    )

    search_results = []
    if results and results["documents"]:
        for doc, meta, dist in zip(
            results["documents"][0],
            results["metadatas"][0],
            results["distances"][0],
        ):
            # Get the first non-empty line as display text
            first_line = ""
            if doc:
                for line in doc.split("\n"):
                    stripped = line.strip()
                    if stripped:
                        first_line = stripped
                        break

            search_results.append({
                "file": meta["file"],
                "line": meta["line"],
                "text": first_line,
                "distance": round(dist, 4),
            })

    return {"results": search_results}


@app.get("/status")
def get_status(directory: str = ""):
    if not directory:
        return {"error": "Provide ?directory= parameter"}

    directory = os.path.abspath(directory)
    coll_name = dir_collection_name(directory)

    with indexing_lock:
        status = indexing_status.get(coll_name, {})

    try:
        coll = client.get_collection(name=coll_name)
        count = coll.count()
    except Exception:
        count = 0

    return {
        "directory": directory,
        "indexed": count > 0,
        "chunks": count,
        "indexing_status": status.get("status", "unknown"),
    }
