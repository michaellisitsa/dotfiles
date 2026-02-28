import app.main as main_module
from app.main import _do_index, dir_collection_name


# ---------------------------------------------------------------------------
# dir_collection_name
# ---------------------------------------------------------------------------

class TestDirCollectionName:
    def test_deterministic(self):
        assert dir_collection_name("/foo") == dir_collection_name("/foo")

    def test_different_dirs(self):
        assert dir_collection_name("/foo") != dir_collection_name("/bar")

    def test_format(self):
        name = dir_collection_name("/some/path")
        assert name.startswith("dir_")
        assert len(name) == 4 + 16  # "dir_" + 16 hex chars


# ---------------------------------------------------------------------------
# GET /health
# ---------------------------------------------------------------------------

class TestHealth:
    def test_returns_ok(self, api):
        resp = api.get("/health")
        assert resp.status_code == 200
        assert resp.json() == {"status": "ok"}


# ---------------------------------------------------------------------------
# _do_index (synchronous, unit-level)
# ---------------------------------------------------------------------------

class TestDoIndex:
    def test_indexes_python_files(self, sample_project, isolated_storage):
        directory = str(sample_project)
        coll_name = dir_collection_name(directory)
        _do_index(directory, coll_name)

        collection = isolated_storage.get_collection(name=coll_name)
        assert collection.count() > 0

    def test_skips_venv(self, sample_project, isolated_storage):
        directory = str(sample_project)
        coll_name = dir_collection_name(directory)
        _do_index(directory, coll_name)

        collection = isolated_storage.get_collection(name=coll_name)
        results = collection.get(include=["metadatas"])
        files = {m["file"] for m in results["metadatas"]}
        assert not any(".venv" in f for f in files)

    def test_skips_node_modules(self, sample_project, isolated_storage):
        directory = str(sample_project)
        coll_name = dir_collection_name(directory)
        _do_index(directory, coll_name)

        collection = isolated_storage.get_collection(name=coll_name)
        results = collection.get(include=["metadatas"])
        files = {m["file"] for m in results["metadatas"]}
        assert not any("node_modules" in f for f in files)

    def test_skips_binary_files(self, sample_project, isolated_storage):
        directory = str(sample_project)
        coll_name = dir_collection_name(directory)
        _do_index(directory, coll_name)

        collection = isolated_storage.get_collection(name=coll_name)
        results = collection.get(include=["metadatas"])
        files = {m["file"] for m in results["metadatas"]}
        assert not any(f.endswith(".png") for f in files)

    def test_indexes_subdirectories(self, sample_project, isolated_storage):
        directory = str(sample_project)
        coll_name = dir_collection_name(directory)
        _do_index(directory, coll_name)

        collection = isolated_storage.get_collection(name=coll_name)
        results = collection.get(include=["metadatas"])
        files = {m["file"] for m in results["metadatas"]}
        # os.path.relpath uses os.sep, so accept either separator
        assert any("helper.py" in f for f in files)

    def test_metadata_has_required_fields(self, sample_project, isolated_storage):
        directory = str(sample_project)
        coll_name = dir_collection_name(directory)
        _do_index(directory, coll_name)

        collection = isolated_storage.get_collection(name=coll_name)
        results = collection.get(include=["metadatas"])
        for meta in results["metadatas"]:
            assert "file" in meta
            assert "line" in meta
            assert meta["line"] >= 1

    def test_empty_directory(self, tmp_path, isolated_storage):
        empty_dir = tmp_path / "empty"
        empty_dir.mkdir()
        directory = str(empty_dir)
        coll_name = dir_collection_name(directory)
        _do_index(directory, coll_name)

        collection = isolated_storage.get_collection(name=coll_name)
        assert collection.count() == 0

    def test_chunking_large_file(self, tmp_path, isolated_storage):
        """50-line file → chunks at line 1, 21, 41 = 3 chunks (window=30, step=20)."""
        project = tmp_path / "chunking"
        project.mkdir()
        content = "\n".join(f"line {i}" for i in range(1, 51)) + "\n"
        (project / "big.py").write_text(content)

        directory = str(project)
        coll_name = dir_collection_name(directory)
        _do_index(directory, coll_name)

        collection = isolated_storage.get_collection(name=coll_name)
        assert collection.count() == 3

    def test_single_chunk_small_file(self, tmp_path, isolated_storage):
        """A file with fewer than 30 lines should produce exactly 1 chunk."""
        project = tmp_path / "small"
        project.mkdir()
        (project / "tiny.py").write_text("x = 1\n")

        directory = str(project)
        coll_name = dir_collection_name(directory)
        _do_index(directory, coll_name)

        collection = isolated_storage.get_collection(name=coll_name)
        assert collection.count() == 1

    def test_sets_status_done(self, sample_project, isolated_storage):
        directory = str(sample_project)
        coll_name = dir_collection_name(directory)
        _do_index(directory, coll_name)

        status = main_module.indexing_status[coll_name]
        assert status["status"] == "done"
        assert status["chunks"] > 0

    def test_skips_oversized_files(self, tmp_path, isolated_storage, monkeypatch):
        monkeypatch.setattr(main_module, "MAX_FILE_SIZE", 10)
        project = tmp_path / "big"
        project.mkdir()
        (project / "huge.py").write_text("x" * 100 + "\n")

        directory = str(project)
        coll_name = dir_collection_name(directory)
        _do_index(directory, coll_name)

        collection = isolated_storage.get_collection(name=coll_name)
        assert collection.count() == 0


# ---------------------------------------------------------------------------
# POST /index
# ---------------------------------------------------------------------------

class TestIndexEndpoint:
    def test_nonexistent_directory(self, api):
        resp = api.post("/index", json={"directory": "/nonexistent/path/xyz"})
        assert resp.status_code == 200
        assert "error" in resp.json()

    def test_starts_indexing(self, api, sample_project):
        resp = api.post("/index", json={"directory": str(sample_project)})
        data = resp.json()
        assert data["status"] == "indexing_started"

    def test_already_indexed_skips(self, api, sample_project, isolated_storage):
        # Index synchronously first
        directory = str(sample_project)
        coll_name = dir_collection_name(directory)
        _do_index(directory, coll_name)

        resp = api.post("/index", json={"directory": directory})
        data = resp.json()
        assert data["status"] == "already_indexed"
        assert data["chunks"] > 0

    def test_force_reindex(self, api, sample_project, isolated_storage):
        directory = str(sample_project)
        coll_name = dir_collection_name(directory)
        _do_index(directory, coll_name)

        resp = api.post("/index", json={"directory": directory, "force": True})
        data = resp.json()
        assert data["status"] == "indexing_started"

    def test_already_indexing(self, api, sample_project):
        directory = str(sample_project)
        coll_name = dir_collection_name(directory)

        # Simulate an in-progress indexing
        main_module.indexing_status[coll_name] = {
            "status": "indexing",
            "directory": directory,
        }

        resp = api.post("/index", json={"directory": directory})
        data = resp.json()
        assert data["status"] == "already_indexing"


# ---------------------------------------------------------------------------
# POST /search
# ---------------------------------------------------------------------------

class TestSearchEndpoint:
    def test_not_indexed(self, api, tmp_path):
        resp = api.post("/search", json={
            "query": "hello",
            "directory": str(tmp_path / "nope"),
        })
        data = resp.json()
        assert data["results"] == []
        assert "error" in data

    def test_returns_results(self, api, sample_project, isolated_storage):
        directory = str(sample_project)
        _do_index(directory, dir_collection_name(directory))

        resp = api.post("/search", json={
            "query": "hello world print function",
            "directory": directory,
            "n_results": 5,
        })
        data = resp.json()
        assert len(data["results"]) > 0

        result = data["results"][0]
        assert "file" in result
        assert "line" in result
        assert "text" in result
        assert "distance" in result

    def test_results_have_relative_paths(self, api, sample_project, isolated_storage):
        directory = str(sample_project)
        _do_index(directory, dir_collection_name(directory))

        resp = api.post("/search", json={
            "query": "helper class run",
            "directory": directory,
        })
        data = resp.json()
        for r in data["results"]:
            assert not r["file"].startswith("/")

    def test_n_results_capped(self, api, sample_project, isolated_storage):
        directory = str(sample_project)
        _do_index(directory, dir_collection_name(directory))

        resp = api.post("/search", json={
            "query": "def",
            "directory": directory,
            "n_results": 100,  # exceeds the cap of 50
        })
        assert resp.status_code == 200

    def test_empty_index(self, api, tmp_path, isolated_storage):
        empty = tmp_path / "empty_indexed"
        empty.mkdir()
        directory = str(empty)
        _do_index(directory, dir_collection_name(directory))

        resp = api.post("/search", json={
            "query": "anything",
            "directory": directory,
        })
        data = resp.json()
        assert data["results"] == []
        assert "error" in data


# ---------------------------------------------------------------------------
# GET /status
# ---------------------------------------------------------------------------

class TestStatusEndpoint:
    def test_no_directory_param(self, api):
        resp = api.get("/status")
        data = resp.json()
        assert "error" in data

    def test_not_indexed(self, api, tmp_path):
        resp = api.get("/status", params={"directory": str(tmp_path)})
        data = resp.json()
        assert data["indexed"] is False
        assert data["chunks"] == 0

    def test_after_indexing(self, api, sample_project, isolated_storage):
        directory = str(sample_project)
        coll_name = dir_collection_name(directory)
        _do_index(directory, coll_name)

        resp = api.get("/status", params={"directory": directory})
        data = resp.json()
        assert data["indexed"] is True
        assert data["chunks"] > 0
        assert data["indexing_status"] == "done"
