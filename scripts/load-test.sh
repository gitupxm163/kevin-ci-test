#!/bin/bash
# load test
# kevin
# 2025/09/04

set -e

echo "Starting load testing..."

# Install hey if not available
if ! command -v hey &> /dev/null; then
    echo "Installing hey load testing tool..."
    wget -q https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64
    chmod +x hey_linux_amd64
    sudo mv hey_linux_amd64 /usr/local/bin/hey
fi

# Kill any existing port forwards
pkill -f "port-forward.*8080:80" || true

# Start port forwarding in background  
echo "Starting port-forward for ingress access..."
kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80 &
PF_PID=$!
sleep 10

# Test connectivity first
echo "Testing ingress connectivity..."
if ! curl -s -H "Host: foo.localhost" http://localhost:8080/ | grep -q "foo"; then
    echo "ERROR: foo.localhost endpoint not responding correctly"
    kill $PF_PID
    exit 1
fi

if ! curl -s -H "Host: bar.localhost" http://localhost:8080/ | grep -q "bar"; then
    echo "ERROR: bar.localhost endpoint not responding correctly"
    kill $PF_PID
    exit 1
fi

echo "Both endpoints are healthy, starting load tests..."

echo "Running load tests..."

# Test foo endpoint through ingress
echo "=== Load Testing foo.localhost ==="
hey -n 1000 -c 5 -q 25 -host foo.localhost http://localhost:8080/

echo ""
echo "=== Load Testing bar.localhost ==="  
hey -n 1000 -c 5 -q 25 -host bar.localhost http://localhost:8080/

# Mixed traffic test
echo ""
echo "=== Mixed Traffic Test ==="
echo "Running concurrent tests on both endpoints..."

# Run foo and bar tests in parallel
(hey -n 500 -c 3 -q 15 -host foo.localhost http://localhost:8080/ | sed 's/^/[FOO] /') &
FOO_PID=$!

(hey -n 500 -c 3 -q 15 -host bar.localhost http://localhost:8080/ | sed 's/^/[BAR] /') &
BAR_PID=$!

# Wait for both tests to complete
wait $FOO_PID
wait $BAR_PID

# Cleanup port forward
kill $PF_PID

echo ""
echo "=================================="
echo "LOAD TESTING SUMMARY"
echo "=================================="
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S UTC')"
echo ""
echo "Test Configuration:"
echo "- Total requests per endpoint: 1000 (sequential) + 500 (concurrent)"
echo "- Concurrency: 5 (sequential), 3 (concurrent)"
echo "- Rate limit: 25 QPS (sequential), 15 QPS (concurrent)"
echo ""
echo "Load testing completed successfully"