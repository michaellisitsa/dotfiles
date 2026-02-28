import app.main as main_module
from app.main import _do_index, dir_index_name, walk_and_chunk


# ---------------------------------------------------------------------------
# dir_index_name
# ---------------------------------------------------------------------------


class TestDirIndexName:
    def test_deterministic(self):
        assert dir_index_name("/foo") == dir_index_name("/foo")

    def test_different_dirs(self):
        assert dir_index_name("/foo") != dir_index_name("/bar")

    def test_format(self):
        name = dir_index_name("/some/path")
        assert name.startswith("vector_search_")
        assert len(name) == len("vector_search_") + 16


# ---------------------------------------------------------------------------
# walk_and_chunk  (pure function — no mocks needed)
# ---------------------------------------------------------------------------


class TestWalkAndChunk:
    def test_finds_python_files(self, sample_project):
        chunks = walk_and_chunk(str(sample_project))
        files = {c["file"] for c in chunks}
        assert any("main.py" in f for f in files)
        assert any("utils.py" in f for f in files)

    def test_skips_venv(self, sample_project):
        chunks = walk_and_chunk(str(sample_project))
        files = {c["file"] for c in chunks}
        assert not any(".venv" in f for f in files)

    def test_skips_node_modules(self, sample_project):
        chunks = walk_and_chunk(str(sample_project))
        files = {c["file"] for c in chunks}
        assert not any("node_modules" in f for f in files)

    def test_skips_binary_files(self, sample_project):
        chunks = walk_and_chunk(str(sample_project))
        files = {c["file"] for c in chunks}
        assert not any(f.endswith(".png") for f in files)

    def test_indexes_subdirectories(self, sample_project):
        chunks = walk_and_chunk(str(sample_project))
        files = {c["file"] for c in chunks}
        assert any("helper.py" in f for f in files)

    def test_chunk_has_required_fields(self, sample_project):
        chunks = walk_and_chunk(str(sample_project))
        for c in chunks:
            assert "file" in c
            assert "line" in c
            assert "content" in c
            assert c["line"] >= 1

    def test_relative_paths(self, sample_project):
        chunks = walk_and_chunk(str(sample_project))
        for c in chunks:
            assert not c["file"].startswith("/")

    def test_empty_directory(self, tmp_path):
        empty = tmp_path / "empty"
        empty.mkdir()
        assert walk_and_chunk(str(empty)) == []

    def test_chunking_large_file(self, tmp_path):
        """50-line file -> chunks at line 1, 21, 41 = 3 chunks (window=30, step=20)."""
        project = tmp_path / "chunking"
        project.mkdir()
        content = "\n".join(f"line {i}" for i in range(1, 51)) + "\n"
        (project / "big.py").write_text(content)

        chunks = walk_and_chunk(str(project))
        assert len(chunks) == 3
        assert chunks[0]["line"] == 1
        assert chunks[1]["line"] == 21
        assert chunks[2]["line"] == 41

    def test_single_chunk_small_file(self, tmp_path):
        project = tmp_path / "small"
        project.mkdir()
        (project / "tiny.py").write_text("x = 1\n")

        chunks = walk_and_chunk(str(project))
        assert len(chunks) == 1

    def test_skips_oversized_files(self, tmp_path, monkeypatch):
        monkeypatch.setattr(main_module, "MAX_FILE_SIZE", 10)
        project = tmp_path / "big"
        project.mkdir()
        (project / "huge.py").write_text("x" * 100 + "\n")

        assert walk_and_chunk(str(project)) == []


# ---------------------------------------------------------------------------
# GET /health
# ---------------------------------------------------------------------------


class TestHealth:
    def test_returns_ok(self, api):
        resp = api.get("/health")
        assert resp.status_code == 200
        assert resp.json() == {"status": "ok"}


# ---------------------------------------------------------------------------
# _do_index  (calls OpenSearch + model — both mocked)
# ---------------------------------------------------------------------------


class TestDoIndex:
    def test_creates_index(self, sample_project, mock_os):
        mock_os.indices.exists.return_value = False
        directory = str(sample_project)
        index_name = dir_index_name(directory)
        _do_index(directory, index_name)

        mock_os.indices.create.assert_called_once()
        call_kwargs = mock_os.indices.create.call_args
        assert call_kwargs[1]["index"] == index_name

    def test_deletes_existing_index(self, sample_project, mock_os):
        mock_os.indices.exists.return_value = True
        directory = str(sample_project)
        index_name = dir_index_name(directory)
        _do_index(directory, index_name)

        mock_os.indices.delete.assert_called_once_with(index=index_name)

    def test_bulk_called_for_non_empty_project(self, sample_project, mock_os):
        import opensearchpy

        bulk_calls = []
        original_bulk = opensearchpy.helpers.bulk

        def tracking_bulk(client, actions, **kw):
            items = list(actions)
            bulk_calls.append(items)
            return (len(items), [])

        # Replace the already-monkeypatched bulk with our tracking version
        opensearchpy.helpers.bulk = tracking_bulk
        try:
            directory = str(sample_project)
            _do_index(directory, dir_index_name(directory))
            assert len(bulk_calls) == 1
            assert len(bulk_calls[0]) > 0  # some chunks were indexed
        finally:
            opensearchpy.helpers.bulk = original_bulk

    def test_sets_status_done(self, sample_project):
        directory = str(sample_project)
        index_name = dir_index_name(directory)
        _do_index(directory, index_name)

        assert main_module.indexing_status[index_name]["status"] == "done"
        assert main_module.indexing_status[index_name]["chunks"] > 0

    def test_empty_dir_sets_status_done_zero_chunks(self, tmp_path):
        empty = tmp_path / "empty"
        empty.mkdir()
        directory = str(empty)
        index_name = dir_index_name(directory)
        _do_index(directory, index_name)

        assert main_module.indexing_status[index_name]["status"] == "done"
        assert main_module.indexing_status[index_name]["chunks"] == 0


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

    def test_already_indexed_skips(self, api, sample_project, mock_os):
        mock_os.indices.exists.return_value = True
        mock_os.count.return_value = {"count": 42}

        resp = api.post("/index", json={"directory": str(sample_project)})
        data = resp.json()
        assert data["status"] == "already_indexed"
        assert data["chunks"] == 42

    def test_force_reindex(self, api, sample_project, mock_os):
        mock_os.indices.exists.return_value = True
        mock_os.count.return_value = {"count": 42}

        resp = api.post(
            "/index", json={"directory": str(sample_project), "force": True}
        )
        data = resp.json()
        assert data["status"] == "indexing_started"

    def test_already_indexing(self, api, sample_project):
        directory = str(sample_project)
        index_name = dir_index_name(directory)

        main_module.indexing_status[index_name] = {
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
    def test_not_indexed(self, api, tmp_path, mock_os):
        mock_os.indices.exists.return_value = False

        resp = api.post("/search", json={
            "query": "hello",
            "directory": str(tmp_path / "nope"),
        })
        data = resp.json()
        assert data["results"] == []
        assert "error" in data

    def test_empty_index(self, api, tmp_path, mock_os):
        mock_os.indices.exists.return_value = True
        mock_os.count.return_value = {"count": 0}

        resp = api.post("/search", json={
            "query": "anything",
            "directory": str(tmp_path),
        })
        data = resp.json()
        assert data["results"] == []
        assert "error" in data

    def test_returns_results(self, api, sample_project, mock_os):
        mock_os.indices.exists.return_value = True
        mock_os.count.return_value = {"count": 5}
        mock_os.search.return_value = {
            "hits": {
                "hits": [
                    {
                        "_score": 0.95,
                        "_source": {
                            "file": "main.py",
                            "line": 1,
                            "content": "def hello():\n    print('hello world')",
                        },
                    },
                    {
                        "_score": 0.80,
                        "_source": {
                            "file": "utils.py",
                            "line": 1,
                            "content": "def add(a, b):\n    return a + b",
                        },
                    },
                ],
            },
        }

        resp = api.post("/search", json={
            "query": "hello world print function",
            "directory": str(sample_project),
            "n_results": 5,
        })
        data = resp.json()

        assert len(data["results"]) == 2
        r = data["results"][0]
        assert r["file"] == "main.py"
        assert r["line"] == 1
        assert r["text"] == "def hello():"
        assert "distance" in r

    def test_results_have_relative_paths(self, api, sample_project, mock_os):
        mock_os.indices.exists.return_value = True
        mock_os.count.return_value = {"count": 1}
        mock_os.search.return_value = {
            "hits": {
                "hits": [
                    {
                        "_score": 0.9,
                        "_source": {
                            "file": "lib/helper.py",
                            "line": 1,
                            "content": "class Helper:",
                        },
                    },
                ],
            },
        }

        resp = api.post("/search", json={
            "query": "helper",
            "directory": str(sample_project),
        })
        for r in resp.json()["results"]:
            assert not r["file"].startswith("/")

    def test_n_results_capped(self, api, sample_project, mock_os):
        mock_os.indices.exists.return_value = True
        mock_os.count.return_value = {"count": 10}
        mock_os.search.return_value = {"hits": {"hits": []}}

        resp = api.post("/search", json={
            "query": "def",
            "directory": str(sample_project),
            "n_results": 100,
        })
        assert resp.status_code == 200

        # Verify the k-NN query was capped at 50
        search_body = mock_os.search.call_args[1]["body"]
        assert search_body["size"] == 50


# ---------------------------------------------------------------------------
# GET /status
# ---------------------------------------------------------------------------


class TestStatusEndpoint:
    def test_no_directory_param(self, api):
        resp = api.get("/status")
        data = resp.json()
        assert "error" in data

    def test_not_indexed(self, api, tmp_path, mock_os):
        mock_os.indices.exists.return_value = False

        resp = api.get("/status", params={"directory": str(tmp_path)})
        data = resp.json()
        assert data["indexed"] is False
        assert data["chunks"] == 0

    def test_after_indexing(self, api, sample_project, mock_os):
        directory = str(sample_project)
        index_name = dir_index_name(directory)

        mock_os.indices.exists.return_value = True
        mock_os.count.return_value = {"count": 7}
        main_module.indexing_status[index_name] = {
            "status": "done",
            "chunks": 7,
            "directory": directory,
        }

        resp = api.get("/status", params={"directory": directory})
        data = resp.json()
        assert data["indexed"] is True
        assert data["chunks"] == 7
        assert data["indexing_status"] == "done"
