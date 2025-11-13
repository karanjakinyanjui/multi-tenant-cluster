#!/bin/bash
# Test resource quotas and limits

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

echo "========================================"
echo "  RESOURCE QUOTA TESTING"
echo "========================================"
echo ""

# Test 1: Check if quotas exist
print_info "Test 1: Checking if resource quotas are configured..."
for ns in team-alpha team-beta team-gamma; do
    if kubectl get resourcequota -n $ns &> /dev/null; then
        quota_count=$(kubectl get resourcequota -n $ns --no-headers | wc -l)
        if [ "$quota_count" -gt 0 ]; then
            print_success "ResourceQuota exists in $ns"
        else
            print_fail "No ResourceQuota found in $ns"
        fi
    else
        print_fail "Cannot check ResourceQuota in $ns"
    fi
done
echo ""

# Test 2: Check if limit ranges exist
print_info "Test 2: Checking if limit ranges are configured..."
for ns in team-alpha team-beta team-gamma; do
    if kubectl get limitrange -n $ns &> /dev/null; then
        limit_count=$(kubectl get limitrange -n $ns --no-headers | wc -l)
        if [ "$limit_count" -gt 0 ]; then
            print_success "LimitRange exists in $ns"
        else
            print_fail "No LimitRange found in $ns"
        fi
    else
        print_fail "Cannot check LimitRange in $ns"
    fi
done
echo ""

# Test 3: Try to create a pod without resource requests (should get defaults)
print_info "Test 3: Testing default resource allocation..."
cat <<EOF | kubectl apply -f - &> /dev/null || true
apiVersion: v1
kind: Pod
metadata:
  name: test-defaults
  namespace: team-alpha
spec:
  containers:
  - name: test
    image: busybox
    command: ["sleep", "30"]
EOF

sleep 2

if kubectl get pod test-defaults -n team-alpha &> /dev/null; then
    # Check if defaults were applied
    requests_cpu=$(kubectl get pod test-defaults -n team-alpha -o jsonpath='{.spec.containers[0].resources.requests.cpu}')
    if [ ! -z "$requests_cpu" ]; then
        print_success "Default resource requests applied: $requests_cpu CPU"
    else
        print_fail "Default resource requests not applied"
    fi
    kubectl delete pod test-defaults -n team-alpha --ignore-not-found=true &> /dev/null
else
    print_fail "Could not create test pod"
fi
echo ""

# Test 4: Display quota usage
print_info "Test 4: Current resource quota usage..."
echo ""
for ns in team-alpha team-beta team-gamma; do
    echo "Namespace: $ns"
    kubectl describe resourcequota -n $ns 2>/dev/null | grep -A 5 "Used" || echo "  No quota usage data"
    echo ""
done

# Test 5: Try to exceed quota (optional - commented out to avoid issues)
print_info "Test 5: Quota enforcement test..."
echo "  (Skipped to avoid production impact)"
echo "  To manually test: Try creating pods that exceed the quota"
echo ""

echo "========================================"
echo "Resource quota tests completed"
echo "========================================"
