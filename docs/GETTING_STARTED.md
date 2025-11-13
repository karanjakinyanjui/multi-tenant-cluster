# Getting Started with Multi-Tenant Kubernetes Cluster

This guide will help you set up and understand the multi-tenant Kubernetes cluster with RBAC, network isolation, and resource management.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Architecture Overview](#architecture-overview)
4. [Deployment Steps](#deployment-steps)
5. [Validation](#validation)
6. [Working with Tenants](#working-with-tenants)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

- Kubernetes cluster (1.23+) - can be:
  - Minikube
  - Kind (Kubernetes in Docker)
  - EKS, GKE, AKS (cloud providers)
  - Self-managed cluster
- `kubectl` CLI installed and configured
- Cluster admin access for initial setup

### Setting up a Local Cluster (Optional)

If you don't have a cluster, you can create one with Minikube:

```bash
# Install Minikube
brew install minikube  # macOS
# OR
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start cluster with network policy support
minikube start --cni=calico --cpus=4 --memory=8192
```

Or with Kind:

```bash
# Install Kind
brew install kind  # macOS
# OR
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Create cluster
kind create cluster --config=docs/kind-config.yaml
```

## Quick Start

```bash
# 1. Clone or navigate to the repository
cd multi-tenant-cluster

# 2. Deploy all resources
./scripts/deploy-all.sh

# 3. Validate the deployment
./scripts/validate.sh

# 4. Check status
./scripts/show-status.sh

# 5. Switch to a tenant namespace
./kubeconfig/switch-context.sh team-alpha

# 6. View resources
kubectl get all
```

## Architecture Overview

### Namespaces

The cluster is divided into four namespaces:

- **team-alpha**: Production namespace for Team Alpha (customer-facing services)
- **team-beta**: Production namespace for Team Beta (data processing)
- **team-gamma**: Staging namespace for Team Gamma (experimental features)
- **platform**: Shared services and monitoring tools

### RBAC Structure

Each tenant namespace has three service account types:

1. **Developer**: Full CRUD access to namespace resources
2. **Deployer**: CI/CD focused permissions (deployments, configs)
3. **ReadOnly**: View-only access for monitoring/auditing

### Network Isolation

Network policies enforce:

- Default deny all traffic
- Allow intra-namespace communication
- Allow DNS queries
- Allow monitoring from platform namespace
- Controlled external egress

### Resource Management

Each namespace has:

- **ResourceQuotas**: Limits on CPU, memory, storage, and object counts
- **LimitRanges**: Default and maximum values for containers and pods

### Security

- **Pod Security Standards**: Baseline/Restricted policies per namespace
- **Security Contexts**: Non-root users, read-only root filesystems
- **Capability Dropping**: Minimal container capabilities

## Deployment Steps

### Step 1: Deploy Namespaces

```bash
kubectl apply -f namespaces/
```

Verify:
```bash
kubectl get namespaces --show-labels
```

### Step 2: Deploy RBAC

```bash
# Service Accounts
kubectl apply -f rbac/service-accounts/

# Roles
kubectl apply -f rbac/roles/

# RoleBindings
kubectl apply -f rbac/role-bindings/

# ClusterRoles
kubectl apply -f rbac/cluster-roles/

# ClusterRoleBindings
kubectl apply -f rbac/cluster-role-bindings/
```

Verify:
```bash
kubectl get sa,roles,rolebindings -n team-alpha
kubectl get clusterroles,clusterrolebindings | grep -E '(monitoring|platform)'
```

### Step 3: Deploy Resource Management

```bash
# Resource Quotas
kubectl apply -f resource-management/quotas/

# Limit Ranges
kubectl apply -f resource-management/limits/
```

Verify:
```bash
kubectl get resourcequotas,limitranges -n team-alpha
kubectl describe resourcequota -n team-alpha
```

### Step 4: Deploy Network Policies

```bash
kubectl apply -f network-policies/
```

Verify:
```bash
kubectl get networkpolicies --all-namespaces
kubectl describe networkpolicy default-deny-all -n team-alpha
```

### Step 5: Apply Pod Security Standards

```bash
kubectl apply -f security/pod-security-standards.yaml
```

Verify:
```bash
kubectl get namespace team-alpha -o yaml | grep pod-security
```

### Step 6: Deploy Sample Applications (Optional)

```bash
kubectl apply -f applications/team-alpha/
kubectl apply -f applications/team-beta/
kubectl apply -f applications/team-gamma/
```

Verify:
```bash
kubectl get all -n team-alpha
kubectl get all -n team-beta
kubectl get all -n team-gamma
```

## Validation

Run the validation script:

```bash
./scripts/validate.sh
```

This checks:
- All namespaces exist
- RBAC is properly configured
- Network policies are in place
- Resource quotas and limits are set
- Pod Security Standards are applied

## Working with Tenants

### Switching Namespaces

```bash
# View current context
./kubeconfig/switch-context.sh

# Switch to team-alpha
./kubeconfig/switch-context.sh team-alpha

# Now all kubectl commands default to team-alpha
kubectl get pods
```

### Generating Service Account Credentials

```bash
# Generate kubeconfig for developer
./kubeconfig/generate-kubeconfig.sh team-alpha team-alpha-developer

# Use the generated kubeconfig
export KUBECONFIG=./team-alpha-developer.kubeconfig
kubectl get pods
```

### Testing RBAC Permissions

```bash
# Can team-alpha-developer create pods in team-alpha?
kubectl auth can-i create pods \
  --as=system:serviceaccount:team-alpha:team-alpha-developer \
  -n team-alpha

# Can team-alpha-readonly delete deployments?
kubectl auth can-i delete deployments \
  --as=system:serviceaccount:team-alpha:team-alpha-readonly \
  -n team-alpha

# List all permissions
kubectl auth can-i --list \
  --as=system:serviceaccount:team-alpha:team-alpha-developer \
  -n team-alpha
```

### Checking Resource Usage

```bash
# View quota usage
kubectl describe resourcequota -n team-alpha

# View limit ranges
kubectl describe limitrange -n team-alpha

# Check if quota is exceeded
kubectl get events -n team-alpha | grep "exceeded quota"
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n team-alpha

# Describe pod for events
kubectl describe pod <pod-name> -n team-alpha

# Check logs
kubectl logs <pod-name> -n team-alpha

# Common issues:
# - Resource quota exceeded
# - Image pull errors
# - Pod security policy violations
```

### Network Policy Issues

```bash
# Check network policies
kubectl get networkpolicies -n team-alpha

# Describe network policy
kubectl describe networkpolicy default-deny-all -n team-alpha

# Test connectivity
kubectl run test-pod -n team-alpha --image=busybox --rm -it -- sh
# Inside pod: wget -O- http://service-name
```

### RBAC Errors

```bash
# Check service account
kubectl get sa team-alpha-developer -n team-alpha

# Check role bindings
kubectl get rolebindings -n team-alpha

# Describe role binding
kubectl describe rolebinding team-alpha-developer-binding -n team-alpha

# Verify permissions
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<namespace>:<sa-name>
```

### Resource Quota Exceeded

```bash
# Check current usage
kubectl describe resourcequota -n team-alpha

# Reduce replicas or delete unused resources
kubectl scale deployment <name> --replicas=1 -n team-alpha
kubectl delete pod <pod-name> -n team-alpha
```

## Next Steps

- Read [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture
- See [OPERATIONS.md](OPERATIONS.md) for day-to-day operations
- Check [SECURITY.md](SECURITY.md) for security best practices
- Review [examples/](../examples/) for common use cases

## Additional Resources

- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
