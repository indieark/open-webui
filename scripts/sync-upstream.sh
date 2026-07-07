#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

skip_verify=false

for arg in "$@"; do
  case "$arg" in
    --skip-verify)
      skip_verify=true
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: bash scripts/sync-upstream.sh [--skip-verify]" >&2
      exit 1
      ;;
  esac
done

cd "$REPO_ROOT"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "工作区不干净，请先提交或暂存当前变更后再同步上游。" >&2
  exit 1
fi

if ! git remote get-url upstream-open-webui >/dev/null 2>&1; then
  echo "Missing remote: upstream-open-webui" >&2
  echo "Run: git remote add upstream-open-webui https://github.com/open-webui/open-webui.git" >&2
  exit 1
fi

git fetch upstream-open-webui main --no-tags

latest_split="$(
  git log --grep='git-subtree-dir: upstream/open-webui' --format=%B -n 1 |
    sed -n 's/^git-subtree-split: //p' |
    tail -n 1
)"
remote_head="$(git rev-parse upstream-open-webui/main)"

if [[ -z "$latest_split" ]]; then
  echo "Cannot find git-subtree-split for upstream/open-webui." >&2
  exit 1
fi

if [[ "$latest_split" == "$remote_head" ]]; then
  echo "No upstream delta: open-webui/open-webui@$remote_head"
  exit 0
fi

echo "Upstream delta detected:"
git log --oneline "$latest_split..$remote_head"

git subtree pull --prefix=upstream/open-webui upstream-open-webui main --squash

if [[ "$skip_verify" != true ]]; then
  bash scripts/verify-compat.sh
fi

echo "Upstream sync completed. Review git status before committing."
