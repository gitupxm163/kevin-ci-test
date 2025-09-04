#!/bin/bash
# full test
# kevin
# 2025/09/04

set -e

echo "full flow test (like ci)"

cluster="ci-test-local"

cleanup() {
    echo "cleanup..."
    kind delete cluster --name=$cluster 2>/dev/null || true
}

trap cleanup EXIT

echo "checking deps..."
command -v kind >/dev/null 2>&1 || { echo "need kind"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "need kubectl"; exit 1; }
echo "deps ok"

echo "creating cluster..."
kind create cluster --config=kind-cluster-config.yaml --name=$cluster

echo "cluster status:"
kubectl get nodes --context=kind-$cluster
nodes=$(kubectl get nodes --context=kind-$cluster --no-headers | wc -l)
echo "nodes: $nodes"

echo "installing ingress..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "waiting for ingress..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "deploying apps..."
chmod +x ./scripts/deploy-apps.sh
./scripts/deploy-apps.sh

echo "health check..."
chmod +x ./scripts/verify-health.sh  
./scripts/verify-health.sh

echo "load test..."
chmod +x ./scripts/load-test.sh
echo "start: $(date)"
./scripts/load-test.sh > results.txt
echo "end: $(date)"

echo ""
echo "results:"
echo "========"
cat results.txt

echo ""
echo "test complete - ci should work the same way"