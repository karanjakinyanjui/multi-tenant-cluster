#!/bin/bash
# Test RBAC permissions for all service accounts

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
    local description=$1
    local command=$2
    local expected=$3

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_test "$description"

    if eval "$command" &> /dev/null; then
        result="yes"
    else
        result="no"
    fi

    if [ "$result" == "$expected" ]; then
        print_pass "Expected: $expected, Got: $result"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        print_fail "Expected: $expected, Got: $result"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo ""
}

echo "========================================"
echo "    RBAC PERMISSIONS TESTING"
echo "========================================"
echo ""

# Team Alpha Developer Tests
print_info "Testing team-alpha-developer permissions..."
echo ""

run_test "Developer can create pods in team-alpha" \
    "kubectl auth can-i create pods --as=system:serviceaccount:team-alpha:team-alpha-developer -n team-alpha" \
    "yes"

run_test "Developer can delete deployments in team-alpha" \
    "kubectl auth can-i delete deployments --as=system:serviceaccount:team-alpha:team-alpha-developer -n team-alpha" \
    "yes"

run_test "Developer can create secrets in team-alpha" \
    "kubectl auth can-i create secrets --as=system:serviceaccount:team-alpha:team-alpha-developer -n team-alpha" \
    "yes"

run_test "Developer CANNOT create pods in team-beta" \
    "kubectl auth can-i create pods --as=system:serviceaccount:team-alpha:team-alpha-developer -n team-beta" \
    "no"

run_test "Developer CANNOT delete namespaces" \
    "kubectl auth can-i delete namespaces --as=system:serviceaccount:team-alpha:team-alpha-developer" \
    "no"

# Team Alpha Deployer Tests
print_info "Testing team-alpha-deployer permissions..."
echo ""

run_test "Deployer can update deployments in team-alpha" \
    "kubectl auth can-i update deployments --as=system:serviceaccount:team-alpha:team-alpha-deployer -n team-alpha" \
    "yes"

run_test "Deployer can create configmaps in team-alpha" \
    "kubectl auth can-i create configmaps --as=system:serviceaccount:team-alpha:team-alpha-deployer -n team-alpha" \
    "yes"

run_test "Deployer CANNOT delete services" \
    "kubectl auth can-i delete services --as=system:serviceaccount:team-alpha:team-alpha-deployer -n team-alpha" \
    "no"

# Team Alpha ReadOnly Tests
print_info "Testing team-alpha-readonly permissions..."
echo ""

run_test "ReadOnly can list pods in team-alpha" \
    "kubectl auth can-i list pods --as=system:serviceaccount:team-alpha:team-alpha-readonly -n team-alpha" \
    "yes"

run_test "ReadOnly can get deployments in team-alpha" \
    "kubectl auth can-i get deployments --as=system:serviceaccount:team-alpha:team-alpha-readonly -n team-alpha" \
    "yes"

run_test "ReadOnly CANNOT create pods" \
    "kubectl auth can-i create pods --as=system:serviceaccount:team-alpha:team-alpha-readonly -n team-alpha" \
    "no"

run_test "ReadOnly CANNOT delete anything" \
    "kubectl auth can-i delete deployments --as=system:serviceaccount:team-alpha:team-alpha-readonly -n team-alpha" \
    "no"

# Platform Admin Tests
print_info "Testing platform-admin permissions..."
echo ""

run_test "Platform admin can list namespaces" \
    "kubectl auth can-i list namespaces --as=system:serviceaccount:platform:platform-admin" \
    "yes"

run_test "Platform admin can create namespaces" \
    "kubectl auth can-i create namespaces --as=system:serviceaccount:platform:platform-admin" \
    "yes"

run_test "Platform admin can manage RBAC" \
    "kubectl auth can-i create roles --as=system:serviceaccount:platform:platform-admin" \
    "yes"

run_test "Platform admin can view resources in all namespaces" \
    "kubectl auth can-i get pods --as=system:serviceaccount:platform:platform-admin --all-namespaces" \
    "yes"

# Monitoring Agent Tests
print_info "Testing monitoring-agent permissions..."
echo ""

run_test "Monitoring can list pods in all namespaces" \
    "kubectl auth can-i list pods --as=system:serviceaccount:platform:monitoring-agent --all-namespaces" \
    "yes"

run_test "Monitoring can get services in all namespaces" \
    "kubectl auth can-i get services --as=system:serviceaccount:platform:monitoring-agent --all-namespaces" \
    "yes"

run_test "Monitoring CANNOT create pods" \
    "kubectl auth can-i create pods --as=system:serviceaccount:platform:monitoring-agent -n team-alpha" \
    "no"

run_test "Monitoring CANNOT delete anything" \
    "kubectl auth can-i delete pods --as=system:serviceaccount:platform:monitoring-agent -n team-alpha" \
    "no"

# Summary
echo "========================================"
echo "           TEST SUMMARY"
echo "========================================"
echo "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"
echo "========================================"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}All RBAC tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some RBAC tests failed!${NC}"
    exit 1
fi
