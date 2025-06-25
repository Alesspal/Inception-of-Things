#!/bin/bash

set -euo pipefail

# installer les dépendances de base
apt-get update -y
apt-get install -y curl

# installer Docker
curl -fsSL https://get.docker.com | bash

# installer K3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# installer kubectl
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# créer le cluster K3d avec les bons ports exposés
k3d cluster create iot42-cluster \
    -p "8080:443@loadbalancer" \
    -p "8888:30088@loadbalancer"

# créer les namespaces nécessaires (argocd, dev)
kubectl create namespace argocd 
kubectl create namespace dev 

# installer Argo CD dans le namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/install.yaml

# appliquer le fichier Argo CD Application (confs/argocd-iot42.yaml)
kubectl apply -f ./argocd-iot42.yaml
