#!/bin/bash
# Switch between different namespace contexts
# Usage: ./switch-context.sh [namespace]

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed."
    exit 1
fi

# If no argument provided, show current context and available namespaces
if [ $# -eq 0 ]; then
    echo ""
    print_info "Current context:"
    kubectl config current-context
    echo ""
    kubectl config get-contexts
    echo ""
    print_info "Current namespace:"
    kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}'
    echo ""
    echo ""
    print_info "Available tenant namespaces:"
    kubectl get namespaces | grep -E "(team-alpha|team-beta|team-gamma|platform)"
    echo ""
    echo "Usage: $0 [namespace]"
    echo "Example: $0 team-alpha"
    exit 0
fi

NAMESPACE=$1

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "Namespace $NAMESPACE does not exist."
    exit 1
fi

# Set namespace for current context
kubectl config set-context --current --namespace="$NAMESPACE"

print_success "Switched to namespace: $NAMESPACE"
echo ""
print_info "Current context configuration:"
kubectl config get-contexts $(kubectl config current-context)
