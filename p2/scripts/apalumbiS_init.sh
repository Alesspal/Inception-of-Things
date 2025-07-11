#!/bin/bash
set -e

# Install K3s
curl -sfL https://get.k3s.io | sh -s - --node-ip=192.168.56.110 --write-kubeconfig-mode 644 || { echo "Failed to install K3s"; exit 1; }

# Apply all configs from manifests
kubectl apply -f /vagrant/confs/app1/deployment.yaml
kubectl apply -f /vagrant/confs/app1/service.yaml
kubectl apply -f /vagrant/confs/app2/deployment.yaml
kubectl apply -f /vagrant/confs/app2/service.yaml
kubectl apply -f /vagrant/confs/app3/deployment.yaml
kubectl apply -f /vagrant/confs/app3/service.yaml
kubectl apply -f /vagrant/confs/ingress.yaml