#!/bin/bash
curl -sfL https://get.k3s.io | sh -
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update
kubectl create namespace cattle-system
helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.local \
  --set replicas=1 \
  --set bootstrapPassword=admin123

