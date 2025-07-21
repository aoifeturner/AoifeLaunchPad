#!/bin/bash
set -e

# Quick Start Script for AvatarChatbot (TGI Backend)
# Usage: bash quick_start_tgi.sh

cd "$(dirname "$0")"

if [[ ! -f set_env.sh ]]; then
  echo "[ERROR] set_env.sh not found. Please run this script from the AvatarChatbot/docker_compose/amd/gpu/rocm/ directory." >&2
  exit 1
fi

source set_env.sh

echo "[INFO] Environment variables set. Starting AvatarChatbot (TGI backend) services..."
docker compose -f compose.yaml up -d

echo "[INFO] All services are starting!"
echo "[INFO] To check logs: docker compose -f compose.yaml logs -f"
echo "[INFO] To stop:      docker compose -f compose.yaml down" 