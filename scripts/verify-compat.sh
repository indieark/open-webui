#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$REPO_ROOT"

git diff --check

WEBUI_SECRET_KEY="${WEBUI_SECRET_KEY:-verify-placeholder}" docker compose config --quiet
WEBUI_SECRET_KEY="${WEBUI_SECRET_KEY:-verify-placeholder}" docker compose -f docker-compose.yml -f docker-compose.local.yml config --quiet

test -f upstream/open-webui/package.json
test -f upstream/open-webui/backend/open_webui/config.py
test -f upstream/open-webui/docker-compose.yaml
test -f docker-compose.yml

rg -n "open-webui_open-webui|3000:8080|ghcr.io/open-webui/open-webui:main|upstream/open-webui|git-subtree-split" \
  README.md UPSTREAMS.md docs plans docker-compose.yml >/dev/null

echo "Compatibility verification passed."
