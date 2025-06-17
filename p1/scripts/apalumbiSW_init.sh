#!/bin/bash

HOSTNAME="apalumbiSW"
TOKEN_SRC="/vagrant/node-token"

echo "[$HOSTNAME] Starting server-worker init script"

set -euo pipefail

apt-get update -y
apt-get install -y curl

echo "[$HOSTNAME] Waiting for $TOKEN_SRC..."
for i in {1..60}; do
    [ -f "$TOKEN_SRC" ] && break
    sleep 1
done

if [ ! -f "$TOKEN_SRC" ]; then
    echo "[$HOSTNAME] ERROR: token search timeout" >&2
    exit 1
fi

echo "[$HOSTNAME] Token found"

K3S_TOKEN=$(cat "$TOKEN_SRC")
K3S_URL="https://192.168.56.110:6443"

echo "[$HOSTNAME] Installing k3s in agent mode with token $K3S_TOKEN at $K3S_URL"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --node-ip=192.168.56.111" K3S_TOKEN="$K3S_TOKEN" K3S_URL="$K3S_URL" sh -s -

echo "[$HOSTNAME] Server-worker initialisation completed"