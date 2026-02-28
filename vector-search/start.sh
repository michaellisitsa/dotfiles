#!/usr/bin/env bash
# Start the vector search service without Docker.
#
# Prerequisites:
#   - Python 3.10+
#   - OpenSearch running at http://localhost:9200
#     Install: https://opensearch.org/downloads.html
#     Or just the OpenSearch container:
#       docker run -d -p 9200:9200 -e discovery.type=single-node \
#         -e plugins.security.disabled=true \
#         opensearchproject/opensearch:2.18.0
#
# Usage:
#   ./start.sh          # foreground
#   ./start.sh &        # background
#
# The service listens on http://localhost:9876

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtualenv..."
    python3 -m venv "$VENV_DIR"
    "$VENV_DIR/bin/pip" install --quiet -r "$SCRIPT_DIR/requirements.txt"
fi

exec "$VENV_DIR/bin/uvicorn" app.main:app --host 0.0.0.0 --port 9876 --app-dir "$SCRIPT_DIR"
