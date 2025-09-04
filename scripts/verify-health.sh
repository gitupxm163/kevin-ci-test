#!/bin/bash
# verify health
# kevin
# 2025/09/04

set -e

echo "Waiting for deployments to be ready..."

# Wait for foo deployment
kubectl wait --for=condition=available --timeout=300s deployment/foo-echo

# Wait for bar deployment  
kubectl wait --for=condition=available --timeout=300s deployment/bar-echo

# Wait for ingress to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

echo "All deployments are healthy"

# Test connectivity
echo "Testing connectivity..."
kubectl get pods,services,ingress -A

echo "=== Note: ingress-nginx-controller service will show <pending> in KinD - this is normal ==="
echo "=== We use port-forward to access the ingress controller ==="

# Debug ingress
echo "=== Ingress Debug ==="
kubectl describe ingress echo-ingress
kubectl get endpoints

# Port forward for testing
kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80 &
PF_PID=$!
sleep 10

# Test endpoints
echo "Testing foo endpoint..."
curl -H "Host: foo.localhost" http://localhost:8080/ || echo "foo endpoint test failed"

echo "Testing bar endpoint..."
curl -H "Host: bar.localhost" http://localhost:8080/ || echo "bar endpoint test failed"

kill $PF_PID
echo "Health verification completed"