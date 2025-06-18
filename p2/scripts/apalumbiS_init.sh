#!/bin/bash

HOSTNAME="apalumbiS"
MANIFESTS_PATH="/vagrant/manifests"
APP1_PATH="$MANIFESTS_PATH/app1"
APP2_PATH="$MANIFESTS_PATH/app2"
APP3_PATH="$MANIFESTS_PATH/app3"

echo "[$HOSTNAME] Starting server init script"

set -euo pipefail

apt-get update -y
apt-get install -y curl

echo "[$HOSTNAME] Installing k3s (server mode)..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --write-kubeconfig-mode 644" sh -s -

echo "[$HOSTNAME] Waiting for Kubernetes API to be available..."
until kubectl get nodes &>/dev/null; do
  sleep 1
done

echo "[$HOSTNAME] Waiting for node to appear in the cluster..."
until [ "$(kubectl get nodes --no-headers 2>/dev/null | wc -l)" -gt 0 ]; do
  sleep 1
done

echo "[$HOSTNAME] Waiting for node to be Ready..."
kubectl wait node --all --for=condition=Ready --timeout=90s || {
  echo "[$HOSTNAME] ERROR: Node did not become Ready in time"
  exit 1
}

echo "[$HOSTNAME] Applying deployments and services..."
kubectl apply -f "$APP1_PATH/deployment.yaml"
kubectl apply -f "$APP1_PATH/service.yaml"

#kubectl apply -f "$APP2_PATH/deployment.yaml"
#kubectl apply -f "$APP2_PATH/service.yaml"

#kubectl apply -f "$APP3_PATH/deployment.yaml"
#kubectl apply -f "$APP3_PATH/service.yaml"

echo "[$HOSTNAME] Applying ingress..."
kubectl apply -f "$MANIFESTS_PATH/ingress.yaml"

echo "[$HOSTNAME] Server initialisation completed"