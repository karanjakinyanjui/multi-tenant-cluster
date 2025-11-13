#!/bin/bash
# Generate kubeconfig for a service account
# Usage: ./generate-kubeconfig.sh <namespace> <service-account-name> [output-file]

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <namespace> <service-account-name> [output-file]"
    echo ""
    echo "Examples:"
    echo "  $0 team-alpha team-alpha-developer"
    echo "  $0 team-beta team-beta-deployer beta-deployer.kubeconfig"
    exit 1
fi

NAMESPACE=$1
SERVICE_ACCOUNT=$2
OUTPUT_FILE=${3:-"${SERVICE_ACCOUNT}.kubeconfig"}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed."
    exit 1
fi

print_info "Generating kubeconfig for service account: $SERVICE_ACCOUNT in namespace: $NAMESPACE"

# Check if service account exists
if ! kubectl get serviceaccount "$SERVICE_ACCOUNT" -n "$NAMESPACE" &> /dev/null; then
    print_error "Service account $SERVICE_ACCOUNT not found in namespace $NAMESPACE"
    exit 1
fi

# Get cluster information
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CA=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

print_info "Cluster: $CLUSTER_NAME"
print_info "Server: $CLUSTER_SERVER"

# Get service account secret
# For Kubernetes 1.24+, you may need to create a secret manually
SECRET_NAME=$(kubectl get serviceaccount "$SERVICE_ACCOUNT" -n "$NAMESPACE" -o jsonpath='{.secrets[0].name}' 2>/dev/null)

if [ -z "$SECRET_NAME" ]; then
    print_info "No secret found. Creating token for service account (Kubernetes 1.24+)..."

    # Create a temporary token (valid for 1 year)
    TOKEN=$(kubectl create token "$SERVICE_ACCOUNT" -n "$NAMESPACE" --duration=8760h)

    if [ -z "$TOKEN" ]; then
        print_error "Failed to create token"
        exit 1
    fi
else
    print_info "Using existing secret: $SECRET_NAME"
    TOKEN=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.token}' | base64 -d)
fi

# Generate kubeconfig
cat > "$OUTPUT_FILE" <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $CLUSTER_CA
    server: $CLUSTER_SERVER
  name: $CLUSTER_NAME
contexts:
- context:
    cluster: $CLUSTER_NAME
    namespace: $NAMESPACE
    user: $SERVICE_ACCOUNT
  name: ${SERVICE_ACCOUNT}-context
current-context: ${SERVICE_ACCOUNT}-context
users:
- name: $SERVICE_ACCOUNT
  user:
    token: $TOKEN
EOF

print_success "Kubeconfig generated: $OUTPUT_FILE"
echo ""
print_info "To use this kubeconfig:"
echo "  export KUBECONFIG=$PWD/$OUTPUT_FILE"
echo "  kubectl get pods"
echo ""
print_info "Or use it directly:"
echo "  kubectl --kubeconfig=$OUTPUT_FILE get pods"
