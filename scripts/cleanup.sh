#!/bin/bash
# Cleanup script to remove all multi-tenant cluster resources

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
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed."
    exit 1
fi

print_warning "This will delete all multi-tenant cluster resources!"
print_warning "The following namespaces will be deleted: team-alpha, team-beta, team-gamma, platform"
echo ""
read -p "Are you sure you want to continue? (type 'yes' to confirm) " -r
echo

if [[ ! $REPLY == "yes" ]]; then
    print_info "Cleanup cancelled."
    exit 0
fi

print_info "Starting cleanup..."
echo ""

# Delete applications first
print_info "Deleting applications..."
kubectl delete -f ../applications/team-alpha/ --ignore-not-found=true
kubectl delete -f ../applications/team-beta/ --ignore-not-found=true
kubectl delete -f ../applications/team-gamma/ --ignore-not-found=true
print_success "Applications deleted"
echo ""

# Delete network policies
print_info "Deleting network policies..."
kubectl delete -f ../network-policies/ --ignore-not-found=true
print_success "Network policies deleted"
echo ""

# Delete resource quotas and limits
print_info "Deleting resource quotas and limits..."
kubectl delete -f ../resource-management/quotas/ --ignore-not-found=true
kubectl delete -f ../resource-management/limits/ --ignore-not-found=true
print_success "Resource management policies deleted"
echo ""

# Delete RBAC
print_info "Deleting RBAC configurations..."
kubectl delete -f ../rbac/cluster-role-bindings/ --ignore-not-found=true
kubectl delete -f ../rbac/cluster-roles/ --ignore-not-found=true
kubectl delete -f ../rbac/role-bindings/ --ignore-not-found=true
kubectl delete -f ../rbac/roles/ --ignore-not-found=true
kubectl delete -f ../rbac/service-accounts/ --ignore-not-found=true
print_success "RBAC configurations deleted"
echo ""

# Delete namespaces (this will delete everything inside)
print_info "Deleting namespaces..."
kubectl delete namespace team-alpha --ignore-not-found=true
kubectl delete namespace team-beta --ignore-not-found=true
kubectl delete namespace team-gamma --ignore-not-found=true
kubectl delete namespace platform --ignore-not-found=true
print_success "Namespaces deleted"
echo ""

print_success "Cleanup completed!"
print_info "All multi-tenant cluster resources have been removed."
