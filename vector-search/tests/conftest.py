from unittest.mock import MagicMock

import numpy as np
import pytest
from fastapi.testclient import TestClient

import app.main as main_module
from app.main import EMBEDDING_DIM


@pytest.fixture(autouse=True)
def isolated_env(monkeypatch):
    """Mock OpenSearch client, embedding model, and reset indexing state."""
    # --- OpenSearch client ---
    mock_os = MagicMock()
    mock_os.indices.exists.return_value = False
    mock_os.indices.create.return_value = None
    mock_os.indices.delete.return_value = None
    mock_os.count.return_value = {"count": 0}
    mock_os.search.return_value = {"hits": {"hits": []}}
    monkeypatch.setattr(main_module, "os_client", mock_os)

    # --- helpers.bulk (called via opensearchpy.helpers.bulk) ---
    import opensearchpy

    monkeypatch.setattr(
        opensearchpy.helpers,
        "bulk",
        lambda client, actions, **kw: (sum(1 for _ in actions), []),
    )

    # --- Embedding model (lazy-loaded via get_model) ---
    mock_model = MagicMock()
    mock_model.encode.side_effect = lambda texts, **kw: np.random.rand(
        len(texts), EMBEDDING_DIM
    ).astype(np.float32)
    monkeypatch.setattr(main_module, "get_model", lambda: mock_model)

    # --- Fresh indexing state ---
    monkeypatch.setattr(main_module, "indexing_status", {})

    return {"os_client": mock_os, "model": mock_model}


@pytest.fixture
def mock_os(isolated_env):
    """Convenience alias for the mocked OpenSearch client."""
    return isolated_env["os_client"]


@pytest.fixture
def api():
    from app.main import app

    return TestClient(app)


@pytest.fixture
def sample_project(tmp_path):
    """Create a sample project directory with code files for testing."""
    project = tmp_path / "sample_project"
    project.mkdir()

    (project / "main.py").write_text(
        "def hello():\n"
        "    print('hello world')\n"
        "\n"
        "def goodbye():\n"
        "    print('goodbye world')\n"
        "\n"
        "hello()\n"
    )
    (project / "utils.py").write_text(
        "def add(a, b):\n"
        "    return a + b\n"
        "\n"
        "def subtract(a, b):\n"
        "    return a - b\n"
    )

    lib = project / "lib"
    lib.mkdir()
    (lib / "helper.py").write_text(
        "class Helper:\n"
        "    def run(self):\n"
        "        pass\n"
    )

    # Binary file — should be skipped
    (project / "image.png").write_bytes(b"\x89PNG\r\n")

    # .venv directory — should be skipped
    venv = project / ".venv"
    venv.mkdir()
    (venv / "skip.py").write_text("should be skipped\n")

    # node_modules directory — should be skipped
    nm = project / "node_modules"
    nm.mkdir()
    (nm / "pkg.js").write_text("module.exports = {}\n")

    return project
