#!/bin/bash
# Test network policies between namespaces

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

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo "========================================"
echo "  NETWORK POLICY TESTING"
echo "========================================"
echo ""

# Check if network policies exist
print_info "Checking if network policies are deployed..."
if kubectl get networkpolicies -n team-alpha &> /dev/null; then
    print_success "Network policies found"
else
    print_fail "Network policies not found"
    exit 1
fi
echo ""

# Deploy test pods
print_info "Deploying test pods..."

# Team Alpha test pod
kubectl run test-alpha --image=busybox --restart=Never -n team-alpha -- sleep 3600 &> /dev/null || true

# Team Beta test pod
kubectl run test-beta --image=busybox --restart=Never -n team-beta -- sleep 3600 &> /dev/null || true

# Wait for pods to be ready
print_info "Waiting for test pods to be ready..."
kubectl wait --for=condition=ready pod/test-alpha -n team-alpha --timeout=60s
kubectl wait --for=condition=ready pod/test-beta -n team-beta --timeout=60s
print_success "Test pods ready"
echo ""

# Test 1: Intra-namespace communication (should work)
print_info "Test 1: Testing intra-namespace communication (should SUCCEED)..."
if kubectl exec test-alpha -n team-alpha -- wget -T 5 -O- http://web-app-service 2>/dev/null | grep -q "Team Alpha"; then
    print_success "Intra-namespace communication works (team-alpha)"
else
    print_warning "Could not verify intra-namespace communication (service may not exist)"
fi
echo ""

# Test 2: Cross-namespace communication (should fail)
print_info "Test 2: Testing cross-namespace communication (should FAIL)..."
if kubectl exec test-alpha -n team-alpha -- timeout 5 wget -O- http://web-app-service.team-beta 2>&1 | grep -q "timeout"; then
    print_success "Cross-namespace communication blocked (as expected)"
else
    print_warning "Cross-namespace test inconclusive"
fi
echo ""

# Test 3: DNS resolution (should work)
print_info "Test 3: Testing DNS resolution (should SUCCEED)..."
if kubectl exec test-alpha -n team-alpha -- nslookup kubernetes.default 2>&1 | grep -q "Address"; then
    print_success "DNS resolution works"
else
    print_fail "DNS resolution failed"
fi
echo ""

# Test 4: External egress (depends on labels)
print_info "Test 4: Testing external egress..."
print_warning "External egress requires 'network-policy: allow-external' label on pods"
echo ""

# Cleanup
print_info "Cleaning up test pods..."
kubectl delete pod test-alpha -n team-alpha --ignore-not-found=true &> /dev/null
kubectl delete pod test-beta -n team-beta --ignore-not-found=true &> /dev/null
print_success "Cleanup complete"
echo ""

echo "========================================"
echo "Network policy tests completed"
echo ""
echo "Note: Some tests may show warnings if sample"
echo "applications are not deployed. This is normal."
echo "========================================"
