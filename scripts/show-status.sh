#!/bin/bash
# Show status of multi-tenant cluster resources

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

print_section() {
    echo ""
    echo -e "${BLUE}--- $1 ---${NC}"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed."
    exit 1
fi

print_header "MULTI-TENANT CLUSTER STATUS"

# Namespaces
print_section "Namespaces"
kubectl get namespaces --show-labels | grep -E "(NAME|team-alpha|team-beta|team-gamma|platform)"

# Resource Quotas
print_section "Resource Quotas (Team Alpha)"
kubectl get resourcequota -n team-alpha
kubectl describe resourcequota -n team-alpha 2>/dev/null | grep -A 10 "Used"

print_section "Resource Quotas (Team Beta)"
kubectl get resourcequota -n team-beta
kubectl describe resourcequota -n team-beta 2>/dev/null | grep -A 10 "Used"

print_section "Resource Quotas (Team Gamma)"
kubectl get resourcequota -n team-gamma
kubectl describe resourcequota -n team-gamma 2>/dev/null | grep -A 10 "Used"

# Network Policies
print_section "Network Policies"
echo "Team Alpha:"
kubectl get networkpolicies -n team-alpha
echo ""
echo "Team Beta:"
kubectl get networkpolicies -n team-beta
echo ""
echo "Team Gamma:"
kubectl get networkpolicies -n team-gamma

# Applications
print_section "Applications - Team Alpha"
kubectl get all -n team-alpha

print_section "Applications - Team Beta"
kubectl get all -n team-beta

print_section "Applications - Team Gamma"
kubectl get all -n team-gamma

# RBAC Summary
print_section "RBAC Summary"
echo "Roles:"
kubectl get roles --all-namespaces | grep -E "(NAMESPACE|team-)"
echo ""
echo "ClusterRoles (Custom):"
kubectl get clusterroles | grep -E "(monitoring|platform|namespace-viewer)"
echo ""
echo "Service Accounts:"
kubectl get serviceaccounts --all-namespaces | grep -E "(NAMESPACE|team-)"

# Pod Security
print_section "Pod Security Standards"
for ns in team-alpha team-beta team-gamma platform; do
    echo "Namespace: $ns"
    enforce=$(kubectl get namespace "$ns" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || echo "not-set")
    audit=$(kubectl get namespace "$ns" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/audit}' 2>/dev/null || echo "not-set")
    warn=$(kubectl get namespace "$ns" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/warn}' 2>/dev/null || echo "not-set")
    echo "  Enforce: $enforce"
    echo "  Audit: $audit"
    echo "  Warn: $warn"
    echo ""
done

print_header "END OF STATUS REPORT"
echo ""
