#!/bin/zsh
# watch-git-pull.sh
# Watches a Git repo and auto-pulls when the remote changes.
# Usage: ./watch-git-pull.sh [path/to/repo] [seconds]

REPO="${1:-.}"
INTERVAL="${2:-5}"

cd "$REPO" || { echo "Can't cd to $REPO"; exit 1; }

# Make sure this is actually a git repo
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not a git repo: $REPO"; exit 1; }

echo "Watching $(pwd) every ${INTERVAL}s. Press Ctrl+C to stop."

trap 'echo ""; echo "Stopping watcher."; exit 0' INT

while true; do
  if ! git diff --quiet HEAD 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    echo "[$(date '+%H:%M:%S')] Local uncommitted changes present — skipping pull to avoid overwriting your work."
  else
    git fetch --quiet

    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse @{u} 2>/dev/null)

    if [ "$LOCAL" != "$REMOTE" ]; then
      echo "[$(date '+%H:%M:%S')] Remote changed. Pulling..."
      git pull
    else
      echo "[$(date '+%H:%M:%S')] No changes."
    fi
  fi

  sleep "$INTERVAL"
done
