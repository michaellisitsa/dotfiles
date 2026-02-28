#!/usr/bin/env bash
# Start the vector search service without Docker.
# Requires Python 3.10+ with pip.
#
# Usage:
#   ./start.sh          # foreground
#   ./start.sh &        # background
#
# The service listens on http://localhost:9876
# Data is stored in ~/.local/share/vector-search/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtualenv..."
    python3 -m venv "$VENV_DIR"
    "$VENV_DIR/bin/pip" install --quiet -r "$SCRIPT_DIR/requirements.txt"
fi

exec "$VENV_DIR/bin/uvicorn" app.main:app --host 0.0.0.0 --port 9876 --app-dir "$SCRIPT_DIR"
