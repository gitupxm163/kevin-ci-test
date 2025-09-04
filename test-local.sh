#!/bin/bash
# local test
# kevin
# 2025/09/04
set -e

echo "starting local test..."

# check tools
if ! command -v kind &> /dev/null; then
    echo "need kind installed"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "need kubectl"  
    exit 1
fi

echo "tools ok"

# cleanup old cluster
kind delete cluster --name=ci-test 2>/dev/null || true

echo "creating cluster..."
kind create cluster --config=kind-cluster-config.yaml --name=ci-test

echo "check nodes..."
kubectl get nodes --context=kind-ci-test

echo "installing ingress..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "waiting for ingress..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "deploying apps..."
./scripts/deploy-apps.sh

echo "checking health..."
./scripts/verify-health.sh

echo "load testing..."
./scripts/load-test.sh

echo "test done"
echo ""
read -p "delete cluster? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kind delete cluster --name=ci-test
    echo "cluster deleted"
else
    echo "cluster kept, cleanup: kind delete cluster --name=ci-test"
fi