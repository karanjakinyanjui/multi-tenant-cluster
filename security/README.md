# Pod Security Standards

This directory contains Pod Security Standards (PSS) and Pod Security Policies (PSP) configurations.

## Pod Security Standards (Recommended - Kubernetes 1.23+)

Pod Security Standards are enforced via namespace labels. The standards define three levels:

### Security Levels

1. **Privileged**: Unrestricted policy (for system components)
2. **Baseline**: Minimally restrictive, prevents known privilege escalations
3. **Restricted**: Heavily restricted, follows Pod hardening best practices

### Namespace Configuration

Each namespace is labeled with three modes:

- `enforce`: Policy violations will cause the pod to be rejected
- `audit`: Policy violations will trigger audit annotations but not reject
- `warn`: Policy violations will trigger user-facing warnings but not reject

### Applied Policies

- **team-alpha** (Production): enforce=baseline, audit=restricted, warn=restricted
- **team-beta** (Production): enforce=baseline, audit=restricted, warn=restricted
- **team-gamma** (Staging): enforce=baseline, audit=baseline, warn=restricted
- **platform** (System): enforce=privileged, audit=restricted, warn=restricted

## Pod Security Policies (Legacy - Deprecated)

PodSecurityPolicies are included for clusters running Kubernetes < 1.25. They provide:

- **restricted**: For production workloads with strict security requirements
- **baseline**: For general workloads with moderate security requirements
- **privileged**: For platform/system tools requiring elevated privileges

## Migration Notes

If your cluster supports Pod Security Standards (1.23+), use the namespace labels approach.
If your cluster only supports PodSecurityPolicies, use the PSP definitions with appropriate RBAC bindings.

For clusters supporting both, PSS takes precedence as PSP is deprecated and removed in Kubernetes 1.25+.
