#!/bin/bash

HOSTNAME="apalumbiS"
TOKEN_SRC=/var/lib/rancher/k3s/server/node-token
TOKEN_DEST=/vagrant/node-token

echo "[$HOSTNAME] Starting server init script"

set -euo pipefail

apt-get update -y
apt-get install -y curl

echo "[$HOSTNAME] Installing k3s (server mode)..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --write-kubeconfig-mode 644" sh -s -

echo "[$HOSTNAME] Waiting for $TOKEN_SRC..."
for i in {1..60}; do
    [ -f "$TOKEN_SRC" ] && break
    sleep 1
done

if [ ! -f "$TOKEN_SRC" ]; then
    echo "[$HOSTNAME] ERROR: Token search timeout" >&2
    exit 1
fi

echo "[$HOSTNAME] Token found. Copying to $TOKEN_DEST"

cp $TOKEN_SRC $TOKEN_DEST

echo "[$HOSTNAME] Server initialisation completed"