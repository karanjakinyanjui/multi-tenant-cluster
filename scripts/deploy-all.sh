#!/bin/bash
# Deploy all multi-tenant cluster resources
# This script deploys namespaces, RBAC, network policies, resource quotas, and applications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
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
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if we have a valid kubeconfig
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please configure kubeconfig."
    exit 1
fi

print_info "Starting multi-tenant cluster deployment..."
echo ""

# Step 1: Create Namespaces
print_info "Creating namespaces..."
kubectl apply -f ../namespaces/
print_success "Namespaces created"
echo ""

# Step 2: Deploy RBAC (Service Accounts, Roles, RoleBindings, ClusterRoles, ClusterRoleBindings)
print_info "Deploying RBAC configurations..."
kubectl apply -f ../rbac/service-accounts/
kubectl apply -f ../rbac/roles/
kubectl apply -f ../rbac/role-bindings/
kubectl apply -f ../rbac/cluster-roles/
kubectl apply -f ../rbac/cluster-role-bindings/
print_success "RBAC configurations deployed"
echo ""

# Step 3: Deploy Resource Quotas and Limit Ranges
print_info "Deploying resource quotas and limit ranges..."
kubectl apply -f ../resource-management/quotas/
kubectl apply -f ../resource-management/limits/
print_success "Resource management policies deployed"
echo ""

# Step 4: Deploy Network Policies
print_info "Deploying network policies..."
kubectl apply -f ../network-policies/
print_success "Network policies deployed"
echo ""

# Step 5: Apply Pod Security Standards
print_info "Applying Pod Security Standards..."
kubectl apply -f ../security/pod-security-standards.yaml
print_success "Pod Security Standards applied"
echo ""

# Step 6: Deploy sample applications (optional)
read -p "Do you want to deploy sample applications? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Deploying sample applications..."
    kubectl apply -f ../applications/team-alpha/
    kubectl apply -f ../applications/team-beta/
    kubectl apply -f ../applications/team-gamma/
    print_success "Sample applications deployed"
else
    print_warning "Skipping sample applications deployment"
fi

echo ""
print_success "Multi-tenant cluster setup completed!"
echo ""

# Display summary
print_info "Deployment Summary:"
echo "===================="
echo ""
kubectl get namespaces --show-labels | grep -E "(NAME|team-alpha|team-beta|team-gamma|platform)"
echo ""
print_info "To view resources in each namespace:"
echo "  kubectl get all -n team-alpha"
echo "  kubectl get all -n team-beta"
echo "  kubectl get all -n team-gamma"
echo ""
print_info "To verify RBAC:"
echo "  kubectl get roles,rolebindings -n team-alpha"
echo "  kubectl get clusterroles,clusterrolebindings | grep -E '(monitoring|platform)'"
echo ""
print_info "To verify network policies:"
echo "  kubectl get networkpolicies -n team-alpha"
echo ""
print_info "To verify resource quotas:"
echo "  kubectl get resourcequotas,limitranges -n team-alpha"
