#!/bin/bash

VAGRANT_ROOT_PATH="/vagrant"
CONFS_PATH="$VAGRANT_ROOT_PATH/confs"
ARGOCD_ADMIN_PWD_PATH="$VAGRANT_ROOT_PATH/argocd-admin-pwd"

set -euo pipefail

# installer les dépendances de base
echo "Installing curl..."
apt-get update -y
apt-get install -y curl

# installer Docker
echo "Installing docker..."
curl -fsSL https://get.docker.com | bash

# installer K3d
echo "Installing k3d..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# installer kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# créer le cluster K3d avec les bons ports exposés
echo "Creating cluster and exposing port 8080 mapped to the port 80 of the cluster..."
k3d cluster create iot42-cluster \
    -p "8080:80@loadbalancer"

# créer les namespaces nécessaires (argocd, dev)
echo "Creating argocd and dev namespaces..."
kubectl create namespace argocd 
kubectl create namespace dev 

# installer Argo CD dans le namespace argocd
echo "Installing argocd in argcd namespace..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/install.yaml

echo "Patching argocd-server deployment to be in http..."
kubectl -n argocd patch deployment argocd-server \
  --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--insecure"}]'

# appliquer l'ingress controller de l'argocd
echo "Applying argocd ingress yaml..."
kubectl apply -f $CONFS_PATH/argocd-iot42-ingress.yaml

# appliquer le fichier Argo CD Application (confs/argocd-iot42-app.yaml)
echo "Applying argocd application yaml..."
kubectl apply -f $CONFS_PATH/argocd-iot42-app.yaml

if [ -f "$ARGOCD_ADMIN_PWD_PATH" ]; then
  echo "Removing existing argocd-admin-pwd file..."
  rm "$ARGOCD_ADMIN_PWD_PATH"
fi

echo "Waiting for argocd-initial-admin-secret to be created..."
for i in {1..300}; do
  if kubectl -n argocd get secret argocd-initial-admin-secret &> /dev/null; then
    echo "Secret found and copied."
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > $ARGOCD_ADMIN_PWD_PATH
    exit 0
  fi
  sleep 1
done

echo "Error: Argo CD admin secret was not created in time." >&2
exit 1