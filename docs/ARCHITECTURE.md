# Multi-Tenant Cluster Architecture

This document describes the architecture and design decisions for the multi-tenant Kubernetes cluster.

## Overview

The multi-tenant cluster is designed to provide secure, isolated environments for multiple teams while sharing the same underlying Kubernetes infrastructure. The design focuses on:

1. **Isolation**: Network, resource, and security isolation between tenants
2. **Security**: RBAC, Pod Security Standards, and secure defaults
3. **Resource Management**: Fair resource allocation with quotas and limits
4. **Observability**: Centralized monitoring and logging

## Namespace Design

### Tenant Namespaces

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                    │
│                                                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐       │
│  │ team-alpha │  │ team-beta  │  │ team-gamma │       │
│  │ Production │  │ Production │  │  Staging   │       │
│  │            │  │            │  │            │       │
│  │ Web Apps   │  │   Data     │  │Experiments │       │
│  │ & APIs     │  │ Processing │  │            │       │
│  └────────────┘  └────────────┘  └────────────┘       │
│                                                          │
│  ┌────────────────────────────────────────────┐        │
│  │           Platform Namespace                │        │
│  │   Monitoring, Logging, Shared Services      │        │
│  └────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────┘
```

### Namespace Characteristics

| Namespace   | Environment | Purpose                  | Resource Allocation |
|-------------|-------------|--------------------------|---------------------|
| team-alpha  | Production  | Customer-facing services | High (40 CPU)       |
| team-beta   | Production  | Data processing          | Very High (60 CPU)  |
| team-gamma  | Staging     | Experimental features    | Medium (20 CPU)     |
| platform    | Shared      | Monitoring & tools       | Variable            |

## RBAC Architecture

### Access Control Hierarchy

```
┌─────────────────────────────────────────────────────────┐
│                    Cluster Level                         │
│                                                          │
│  ┌──────────────────┐        ┌──────────────────┐     │
│  │  ClusterRoles    │        │ ClusterRole      │     │
│  │  - monitoring    │        │  Bindings        │     │
│  │  - platform-admin│        │                  │     │
│  │  - namespace-    │◄──────►│                  │     │
│  │    viewer        │        │                  │     │
│  └──────────────────┘        └──────────────────┘     │
│                                                          │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  Namespace Level                         │
│                                                          │
│  ┌──────────────┐   ┌──────────────┐   ┌────────────┐ │
│  │Service       │   │   Roles      │   │   Role     │ │
│  │Accounts      │   │              │   │ Bindings   │ │
│  │- developer   │   │- developer   │   │            │ │
│  │- deployer    │◄─►│- deployer    │◄─►│            │ │
│  │- readonly    │   │- readonly    │   │            │ │
│  └──────────────┘   └──────────────┘   └────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Permission Matrix

| Resource Type    | Developer | Deployer | ReadOnly | Platform Admin |
|------------------|-----------|----------|----------|----------------|
| Pods             | Full      | R/Update | Read     | All namespaces |
| Deployments      | Full      | Full     | Read     | All namespaces |
| Services         | Full      | Update   | Read     | All namespaces |
| ConfigMaps       | Full      | Full     | Read     | All namespaces |
| Secrets          | Full      | Update   | List     | All namespaces |
| NetworkPolicies  | None      | None     | Read     | Full           |
| ResourceQuotas   | None      | None     | Read     | Full           |
| Namespaces       | None      | None     | Read     | Full           |

## Network Architecture

### Network Policy Design

```
┌─────────────────────────────────────────────────────────┐
│                   External Traffic                       │
│                         │                                │
│                         ▼                                │
│  ┌──────────────────────────────────────────────┐      │
│  │              Ingress Controller               │      │
│  └──────────────────────────────────────────────┘      │
│                         │                                │
│         ┌───────────────┼───────────────┐              │
│         ▼               ▼               ▼              │
│  ┌───────────┐   ┌───────────┐   ┌───────────┐       │
│  │team-alpha │   │team-beta  │   │team-gamma │       │
│  │           │   │           │   │           │       │
│  │ ┌───────┐ │   │ ┌───────┐ │   │ ┌───────┐ │       │
│  │ │  Pod  │ │   │ │  Pod  │ │   │ │  Pod  │ │       │
│  │ └───────┘ │   │ └───────┘ │   │ └───────┘ │       │
│  │     │     │   │     │     │   │     │     │       │
│  │     └─────┼───│─────┘     │   │     └─────┼───┐   │
│  │  Allow    │   │  Deny     │   │  Allow    │   │   │
│  │  Internal │   │  Cross-NS │   │  Internal │   │   │
│  └───────────┘   └───────────┘   └───────────┘   │   │
│         │                                          │   │
│         └──────────────────────────────────────────┘   │
│                         │                                │
│                         ▼                                │
│  ┌──────────────────────────────────────────────┐      │
│  │         Platform Services (Monitoring)        │      │
│  └──────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────┘
```

### Network Policy Rules

1. **Default Deny**: All namespaces start with deny-all policy
2. **Intra-namespace**: Pods can communicate within the same namespace
3. **DNS Access**: All pods can query kube-dns
4. **Monitoring**: Platform namespace can scrape metrics from all namespaces
5. **Egress Control**: External access requires explicit label

## Resource Management

### Quota Strategy

```
Cluster Total Resources: 100 CPU, 200Gi Memory
├── team-alpha (Production)
│   ├── Requests: 20 CPU, 40Gi Memory
│   └── Limits: 40 CPU, 80Gi Memory
├── team-beta (Production - Data Intensive)
│   ├── Requests: 30 CPU, 60Gi Memory
│   └── Limits: 60 CPU, 120Gi Memory
├── team-gamma (Staging)
│   ├── Requests: 10 CPU, 20Gi Memory
│   └── Limits: 20 CPU, 40Gi Memory
└── Platform (Monitoring)
    └── No hard limits (burstable)
```

### LimitRange Configuration

Each namespace has LimitRanges that define:

- **Container Defaults**: CPU and memory defaults if not specified
- **Container Limits**: Maximum resources a container can request
- **Pod Limits**: Maximum resources a pod can request
- **PVC Limits**: Storage size constraints

Example for team-alpha (production):
```yaml
Container:
  Default: 500m CPU, 512Mi Memory
  Max: 4 CPU, 8Gi Memory
Pod:
  Max: 8 CPU, 16Gi Memory
PVC:
  Min: 1Gi, Max: 100Gi
```

## Security Architecture

### Defense in Depth

```
┌──────────────────────────────────────────────────┐
│  Layer 1: Pod Security Standards                 │
│  - Baseline enforcement for production           │
│  - Restricted audit for visibility               │
└──────────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────────┐
│  Layer 2: Security Contexts                      │
│  - Non-root users (UID 1000)                     │
│  - Read-only root filesystem                     │
│  - Drop all capabilities                         │
└──────────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────────┐
│  Layer 3: Network Policies                       │
│  - Default deny all                              │
│  - Explicit allow rules                          │
└──────────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────────┐
│  Layer 4: RBAC                                   │
│  - Least privilege principle                     │
│  - Service account per workload                  │
└──────────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────────┐
│  Layer 5: Resource Limits                        │
│  - Prevent resource exhaustion                   │
│  - Fair sharing                                  │
└──────────────────────────────────────────────────┘
```

### Pod Security Standards Mapping

| Namespace   | Enforce   | Audit      | Warn       | Rationale                    |
|-------------|-----------|------------|------------|------------------------------|
| team-alpha  | baseline  | restricted | restricted | Production, customer-facing  |
| team-beta   | baseline  | restricted | restricted | Production, data processing  |
| team-gamma  | baseline  | baseline   | restricted | Staging, more flexibility    |
| platform    | privileged| restricted | restricted | System tools need privileges |

## Monitoring and Observability

### Monitoring Architecture

```
┌─────────────────────────────────────────────────┐
│          Platform Namespace                      │
│                                                  │
│  ┌─────────────┐        ┌──────────────┐       │
│  │ Prometheus  │◄───────┤  Metrics     │       │
│  │             │        │  Endpoints   │       │
│  └─────────────┘        └──────────────┘       │
│        │                                         │
│        ▼                                         │
│  ┌─────────────┐                                │
│  │  Grafana    │                                │
│  └─────────────┘                                │
└─────────────────────────────────────────────────┘
         │
         │ ClusterRole: monitoring-reader
         │
         ▼
┌─────────────────────────────────────────────────┐
│           Tenant Namespaces                      │
│                                                  │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  │
│  │team-alpha │  │team-beta  │  │team-gamma │  │
│  │           │  │           │  │           │  │
│  │ Metrics   │  │ Metrics   │  │ Metrics   │  │
│  └───────────┘  └───────────┘  └───────────┘  │
└─────────────────────────────────────────────────┘
```

### Key Metrics

- Resource usage (CPU, memory, storage)
- Pod status and restart counts
- Network policy rule hits
- Resource quota utilization
- RBAC audit logs

## Scaling Considerations

### Horizontal Scaling

- Add more tenant namespaces as needed
- Each namespace is independent
- Resource quotas prevent noisy neighbor issues

### Vertical Scaling

- Adjust resource quotas based on actual usage
- Monitor quota utilization
- Scale cluster nodes as needed

### High Availability

- Multiple replicas for applications
- PodDisruptionBudgets for critical services
- Anti-affinity rules to spread pods across nodes

## Design Decisions

### Why Namespace-based Isolation?

- **Pros**: Native K8s construct, good security boundary, easy to understand
- **Cons**: Not suitable for untrusted multi-tenancy
- **Alternative**: Virtual clusters (vcluster) for stronger isolation

### Why Three Service Account Types?

- **Developer**: Daily development work
- **Deployer**: Automated CI/CD (principle of least privilege)
- **ReadOnly**: Monitoring, auditing, debugging

### Why Default Deny Network Policies?

- More secure by default
- Explicit allow rules make network flow visible
- Easier to audit and troubleshoot

### Why Different Quotas per Team?

- Production workloads (alpha, beta) get more resources
- Staging (gamma) gets lower priority
- Prevents accidental overuse in non-production

## Future Enhancements

1. **Multi-cluster**: Federate across multiple clusters
2. **Service Mesh**: Istio/Linkerd for advanced traffic management
3. **GitOps**: FluxCD/ArgoCD for declarative deployments
4. **Policy as Code**: OPA/Kyverno for advanced policies
5. **Cost Allocation**: Chargeback/showback per namespace
6. **Automated Quota Adjustment**: Based on actual usage patterns
