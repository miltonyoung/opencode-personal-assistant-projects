#!/usr/bin/env bash
set -euo pipefail

NETWORK_NAME="cloudflare-net"

if docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
  echo "Docker network '$NETWORK_NAME' already exists."
else
  echo "Creating Docker network '$NETWORK_NAME'..."
  docker network create --driver bridge "$NETWORK_NAME"
  echo "Created."
fi
