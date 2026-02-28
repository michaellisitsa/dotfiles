import pytest
import chromadb
from fastapi.testclient import TestClient


@pytest.fixture(autouse=True)
def isolated_storage(tmp_path, monkeypatch):
    """Replace the module-level ChromaDB client with one using a temp directory."""
    import app.main as main_module

    storage_dir = str(tmp_path / "vector-search-data")
    test_client = chromadb.PersistentClient(path=storage_dir)

    monkeypatch.setattr(main_module, "client", test_client)
    monkeypatch.setattr(main_module, "indexing_status", {})

    yield test_client


@pytest.fixture
def api(isolated_storage):
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
