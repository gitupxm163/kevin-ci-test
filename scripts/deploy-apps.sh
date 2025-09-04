#!/bin/bash
# deploy apps
# kevin
# 2025/09/04

set -e

echo "deploying apps..."

# Deploy foo Application
kubectl apply -f k8s/foo-deployment.yaml
kubectl apply -f k8s/foo-service.yaml

# Deploy bar Application
kubectl apply -f k8s/bar-deployment.yaml  
kubectl apply -f k8s/bar-service.yaml

# Deploy Ingress
kubectl apply -f k8s/ingress.yaml

echo "done"