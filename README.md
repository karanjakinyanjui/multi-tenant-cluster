# Multi-Tenant Kubernetes Cluster

A production-ready, comprehensive Kubernetes multi-tenant cluster implementation with RBAC, network isolation, resource management, and security policies. Perfect for learning, demonstrating, or deploying secure multi-team Kubernetes environments.

## 🌟 Features

- **Multiple Isolated Namespaces**: Four namespaces (team-alpha, team-beta, team-gamma, platform) with different resource profiles
- **Comprehensive RBAC**: Service accounts, roles, role bindings, cluster roles with granular permissions
- **Network Isolation**: NetworkPolicies for secure inter-namespace communication
- **Resource Management**: ResourceQuotas and LimitRanges to prevent resource exhaustion
- **Pod Security Standards**: Baseline and restricted policies for production workloads
- **Sample Applications**: Ready-to-deploy example applications for each tenant
- **Monitoring Stack**: Prometheus-based monitoring with cluster-wide visibility
- **Management Scripts**: Automated deployment, validation, and cleanup utilities
- **Kubeconfig Management**: Tools for generating and managing service account credentials
- **Comprehensive Documentation**: Step-by-step guides and architecture documentation

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Architecture](#-architecture)
- [Directory Structure](#-directory-structure)
- [Prerequisites](#-prerequisites)
- [Deployment](#-deployment)
- [Usage](#-usage)
- [Testing](#-testing)
- [Documentation](#-documentation)
- [Use Cases](#-use-cases)
- [Contributing](#-contributing)

## 🚀 Quick Start

```bash
# 1. Clone the repository
cd multi-tenant-cluster

# 2. Ensure you have a Kubernetes cluster running
kubectl cluster-info

# 3. Deploy the entire multi-tenant setup
./scripts/deploy-all.sh

# 4. Validate the deployment
./scripts/validate.sh

# 5. Check the status
./scripts/show-status.sh

# 6. Switch to a tenant namespace
./kubeconfig/switch-context.sh team-alpha

# 7. View tenant resources
kubectl get all
```

## 🏗️ Architecture

### Namespace Design

```
┌─────────────────────────────────────────────────────────┐
│                  Kubernetes Cluster                      │
│                                                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐       │
│  │ team-alpha │  │ team-beta  │  │ team-gamma │       │
│  │ Production │  │ Production │  │  Staging   │       │
│  │  40 CPU    │  │  60 CPU    │  │  20 CPU    │       │
│  └────────────┘  └────────────┘  └────────────┘       │
│                                                          │
│  ┌────────────────────────────────────────────┐        │
│  │        Platform Namespace                   │        │
│  │    Monitoring & Shared Services             │        │
│  └────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Purpose | Location |
|-----------|---------|----------|
| **Namespaces** | Tenant isolation | `namespaces/` |
| **RBAC** | Access control | `rbac/` |
| **Network Policies** | Traffic isolation | `network-policies/` |
| **Resource Quotas** | Resource limits | `resource-management/quotas/` |
| **Limit Ranges** | Default limits | `resource-management/limits/` |
| **Pod Security** | Security standards | `security/` |
| **Applications** | Sample workloads | `applications/` |
| **Monitoring** | Observability | `monitoring/` |

## 📁 Directory Structure

```
multi-tenant-cluster/
├── namespaces/              # Namespace definitions
├── rbac/                    # RBAC configurations
│   ├── service-accounts/    # Service account definitions
│   ├── roles/              # Namespace-scoped roles
│   ├── role-bindings/      # Role to SA bindings
│   ├── cluster-roles/      # Cluster-wide roles
│   └── cluster-role-bindings/  # Cluster role bindings
├── network-policies/        # NetworkPolicy definitions
├── resource-management/     # Quotas and limits
│   ├── quotas/             # ResourceQuota configs
│   └── limits/             # LimitRange configs
├── security/               # Pod security policies/standards
├── applications/           # Sample applications
│   ├── team-alpha/         # Web apps and APIs
│   ├── team-beta/          # Data processing
│   └── team-gamma/         # Experimental features
├── scripts/                # Management scripts
│   ├── deploy-all.sh       # Deploy everything
│   ├── cleanup.sh          # Remove all resources
│   ├── validate.sh         # Validate deployment
│   ├── show-status.sh      # Show cluster status
│   ├── test-rbac.sh        # Test RBAC permissions
│   ├── test-network-policies.sh  # Test network isolation
│   └── test-resource-quotas.sh   # Test quotas
├── kubeconfig/             # Kubeconfig utilities
│   ├── generate-kubeconfig.sh  # Generate SA kubeconfig
│   ├── switch-context.sh       # Switch namespaces
│   └── README.md               # Kubeconfig guide
├── monitoring/             # Monitoring stack
│   ├── prometheus-deployment.yaml
│   ├── prometheus-config.yaml
│   └── README.md
├── docs/                   # Documentation
│   ├── GETTING_STARTED.md  # Getting started guide
│   └── ARCHITECTURE.md     # Architecture details
└── README.md              # This file
```

## 📦 Prerequisites

- **Kubernetes Cluster** (1.23+):
  - Minikube, Kind, or any cloud provider (EKS, GKE, AKS)
  - At least 4 CPU cores and 8GB RAM recommended
- **kubectl** CLI installed and configured
- **Cluster admin access** for initial setup
- **Network Policy support** (CNI plugin like Calico, Cilium, or Weave)

### Setting up a Local Cluster

**Using Minikube:**
```bash
minikube start --cni=calico --cpus=4 --memory=8192
```

**Using Kind:**
```bash
kind create cluster --config=docs/kind-config.yaml
```

## 🚢 Deployment

### Full Deployment

Deploy everything with a single command:

```bash
./scripts/deploy-all.sh
```

This script will:
1. Create all namespaces
2. Deploy RBAC configurations
3. Apply resource quotas and limits
4. Configure network policies
5. Apply Pod Security Standards
6. (Optionally) Deploy sample applications

### Step-by-Step Deployment

For more control, deploy components individually:

```bash
# 1. Namespaces
kubectl apply -f namespaces/

# 2. RBAC
kubectl apply -f rbac/service-accounts/
kubectl apply -f rbac/roles/
kubectl apply -f rbac/role-bindings/
kubectl apply -f rbac/cluster-roles/
kubectl apply -f rbac/cluster-role-bindings/

# 3. Resource Management
kubectl apply -f resource-management/quotas/
kubectl apply -f resource-management/limits/

# 4. Network Policies
kubectl apply -f network-policies/

# 5. Security
kubectl apply -f security/pod-security-standards.yaml

# 6. Applications (optional)
kubectl apply -f applications/team-alpha/
kubectl apply -f applications/team-beta/
kubectl apply -f applications/team-gamma/

# 7. Monitoring (optional)
kubectl apply -f monitoring/
```

### Validation

Verify the deployment:

```bash
./scripts/validate.sh
```

Check the cluster status:

```bash
./scripts/show-status.sh
```

## 💻 Usage

### Switching Between Namespaces

```bash
# Show current context
./kubeconfig/switch-context.sh

# Switch to team-alpha
./kubeconfig/switch-context.sh team-alpha

# Now all kubectl commands use team-alpha namespace
kubectl get pods
```

### Generating Service Account Credentials

```bash
# Generate kubeconfig for a developer
./kubeconfig/generate-kubeconfig.sh team-alpha team-alpha-developer

# Use the generated kubeconfig
export KUBECONFIG=./team-alpha-developer.kubeconfig
kubectl get pods

# Generate for CI/CD deployer
./kubeconfig/generate-kubeconfig.sh team-beta team-beta-deployer beta-ci.kubeconfig
```

### Testing RBAC Permissions

```bash
# Can I create pods as a developer?
kubectl auth can-i create pods \
  --as=system:serviceaccount:team-alpha:team-alpha-developer \
  -n team-alpha

# List all permissions for a service account
kubectl auth can-i --list \
  --as=system:serviceaccount:team-alpha:team-alpha-developer \
  -n team-alpha
```

### Checking Resource Usage

```bash
# View quota usage
kubectl describe resourcequota -n team-alpha

# Check if quota is exceeded
kubectl get events -n team-alpha | grep "exceeded quota"
```

### Accessing Monitoring

```bash
# Port forward to Prometheus
kubectl port-forward -n platform svc/prometheus 9090:9090

# Open in browser
open http://localhost:9090
```

## 🧪 Testing

### Run All Tests

```bash
# Test RBAC permissions
./scripts/test-rbac.sh

# Test network policies
./scripts/test-network-policies.sh

# Test resource quotas
./scripts/test-resource-quotas.sh
```

### Manual Testing

```bash
# Deploy a test pod
kubectl run test-pod --image=nginx -n team-alpha

# Check if resource limits are applied
kubectl get pod test-pod -n team-alpha -o yaml | grep -A 5 resources

# Test cross-namespace access (should fail)
kubectl run test-pod -n team-alpha --rm -it --image=busybox -- \
  wget -O- http://service.team-beta
```

## 📚 Documentation

- **[Getting Started Guide](docs/GETTING_STARTED.md)**: Comprehensive setup and usage guide
- **[Architecture Documentation](docs/ARCHITECTURE.md)**: Detailed architecture and design decisions
- **[Security README](security/README.md)**: Pod Security Standards explanation
- **[Kubeconfig Guide](kubeconfig/README.md)**: Kubeconfig management and context switching
- **[Monitoring Guide](monitoring/README.md)**: Setting up and using Prometheus monitoring

## 🎯 Use Cases

This project is perfect for:

### Learning & Training
- Understanding Kubernetes multi-tenancy
- Learning RBAC, network policies, and resource management
- Practicing cluster administration
- Security best practices

### Demonstrations & Presentations
- Showcasing Kubernetes security features
- Demonstrating isolation techniques
- Platform engineering presentations
- Technical interviews

### Development & Testing
- Testing applications in isolated environments
- Simulating production constraints
- CI/CD pipeline testing
- Cost allocation modeling

### Production Inspiration
- Template for real multi-tenant clusters
- Security baseline for production clusters
- Resource management patterns
- RBAC structure reference

## 🔑 Key Features Explained

### RBAC (Role-Based Access Control)

Three service account types per namespace:

- **Developer**: Full CRUD access to namespace resources
- **Deployer**: CI/CD focused (deployments, configs, limited permissions)
- **ReadOnly**: View-only access for monitoring and auditing

### Network Policies

- **Default Deny**: All traffic blocked by default
- **Intra-namespace**: Pods can communicate within the same namespace
- **DNS Access**: All pods can query DNS
- **Monitoring**: Platform namespace can scrape metrics
- **Controlled Egress**: External access requires explicit labels

### Resource Management

Each namespace has:

- **ResourceQuotas**: Hard limits on CPU, memory, storage, and object counts
- **LimitRanges**: Default and maximum values for containers/pods
- **Fair Sharing**: Prevents noisy neighbor issues

### Pod Security Standards

- **team-alpha/beta** (Production): baseline enforcement, restricted audit
- **team-gamma** (Staging): baseline enforcement, more permissive
- **platform** (System): privileged for monitoring tools

## 🧹 Cleanup

To remove all resources:

```bash
./scripts/cleanup.sh
```

This will delete:
- All sample applications
- Network policies
- Resource quotas and limits
- RBAC configurations
- All tenant namespaces

## 🤝 Contributing

Contributions are welcome! Areas for improvement:

- Additional sample applications
- More monitoring dashboards
- Integration with service meshes (Istio/Linkerd)
- GitOps integration (Flux/ArgoCD)
- Cost allocation features
- Automated testing improvements

## 📝 Notes

### Production Considerations

This project demonstrates multi-tenancy patterns. For production:

1. **Use real identity providers** (OIDC, LDAP) instead of service accounts for users
2. **Implement admission controllers** (OPA, Kyverno) for advanced policies
3. **Add audit logging** for compliance
4. **Use secret management** (Vault, Sealed Secrets)
5. **Implement backup strategies**
6. **Add disaster recovery plans**
7. **Consider service mesh** for advanced traffic management
8. **Implement cost tracking** and chargeback

### Security Note

This is a **soft multi-tenancy** model suitable for trusted teams. For untrusted multi-tenancy:

- Consider virtual clusters (vcluster)
- Use sandboxed container runtimes (gVisor, Kata Containers)
- Implement stricter isolation
- Add additional security layers

## 📖 Additional Resources

- [Kubernetes Multi-Tenancy Guide](https://kubernetes.io/docs/concepts/security/multi-tenancy/)
- [RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

## 📄 License

This project is provided as-is for educational and demonstration purposes.

## 🙏 Acknowledgments

Built with Kubernetes best practices and inspired by real-world multi-tenant deployments.

---

**Ready to deploy?** Start with `./scripts/deploy-all.sh` and explore the multi-tenant cluster!

For questions or issues, please refer to the documentation in the `docs/` directory.
