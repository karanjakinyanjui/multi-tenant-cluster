#!/bin/bash
# Validation script to verify multi-tenant cluster setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed."
    exit 1
fi

print_info "Starting multi-tenant cluster validation..."
echo ""

VALIDATION_FAILED=0

# Validate Namespaces
print_info "Validating namespaces..."
NAMESPACES=("team-alpha" "team-beta" "team-gamma" "platform")
for ns in "${NAMESPACES[@]}"; do
    if kubectl get namespace "$ns" &> /dev/null; then
        print_success "Namespace $ns exists"
    else
        print_error "Namespace $ns not found"
        VALIDATION_FAILED=1
    fi
done
echo ""

# Validate Service Accounts
print_info "Validating service accounts..."
if kubectl get serviceaccount team-alpha-developer -n team-alpha &> /dev/null; then
    print_success "Service accounts configured"
else
    print_error "Service accounts not properly configured"
    VALIDATION_FAILED=1
fi
echo ""

# Validate Roles
print_info "Validating roles..."
if kubectl get role developer-role -n team-alpha &> /dev/null; then
    print_success "Roles configured"
else
    print_error "Roles not properly configured"
    VALIDATION_FAILED=1
fi
echo ""

# Validate RoleBindings
print_info "Validating role bindings..."
if kubectl get rolebinding team-alpha-developer-binding -n team-alpha &> /dev/null; then
    print_success "RoleBindings configured"
else
    print_error "RoleBindings not properly configured"
    VALIDATION_FAILED=1
fi
echo ""

# Validate ClusterRoles
print_info "Validating cluster roles..."
if kubectl get clusterrole monitoring-reader &> /dev/null; then
    print_success "ClusterRoles configured"
else
    print_error "ClusterRoles not properly configured"
    VALIDATION_FAILED=1
fi
echo ""

# Validate Network Policies
print_info "Validating network policies..."
if kubectl get networkpolicy default-deny-all -n team-alpha &> /dev/null; then
    print_success "Network policies configured"
else
    print_error "Network policies not properly configured"
    VALIDATION_FAILED=1
fi
echo ""

# Validate Resource Quotas
print_info "Validating resource quotas..."
for ns in team-alpha team-beta team-gamma; do
    if kubectl get resourcequota -n "$ns" &> /dev/null; then
        quota_count=$(kubectl get resourcequota -n "$ns" --no-headers | wc -l)
        if [ "$quota_count" -gt 0 ]; then
            print_success "ResourceQuota configured in $ns"
        else
            print_warning "No ResourceQuota found in $ns"
        fi
    else
        print_error "Cannot check ResourceQuota in $ns"
        VALIDATION_FAILED=1
    fi
done
echo ""

# Validate Limit Ranges
print_info "Validating limit ranges..."
for ns in team-alpha team-beta team-gamma; do
    if kubectl get limitrange -n "$ns" &> /dev/null; then
        limit_count=$(kubectl get limitrange -n "$ns" --no-headers | wc -l)
        if [ "$limit_count" -gt 0 ]; then
            print_success "LimitRange configured in $ns"
        else
            print_warning "No LimitRange found in $ns"
        fi
    else
        print_error "Cannot check LimitRange in $ns"
        VALIDATION_FAILED=1
    fi
done
echo ""

# Check Pod Security Standards (namespace labels)
print_info "Validating Pod Security Standards..."
for ns in team-alpha team-beta team-gamma; do
    if kubectl get namespace "$ns" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' | grep -q .; then
        enforce_level=$(kubectl get namespace "$ns" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')
        print_success "Pod Security Standards configured in $ns (enforce: $enforce_level)"
    else
        print_warning "Pod Security Standards not configured in $ns"
    fi
done
echo ""

# Summary
echo "========================================"
if [ $VALIDATION_FAILED -eq 0 ]; then
    print_success "All validations passed!"
    echo ""
    print_info "Cluster is ready for multi-tenant operations"
    exit 0
else
    print_error "Some validations failed!"
    echo ""
    print_info "Please review the errors above and re-run deployment if needed"
    exit 1
fi
