# Kubeconfig Management

This directory contains utilities for managing kubeconfig files and contexts for the multi-tenant cluster.

## Scripts

### generate-kubeconfig.sh

Generates a kubeconfig file for a specific service account. This is useful for:
- Creating credentials for CI/CD pipelines
- Providing limited access to team members
- Testing RBAC configurations

**Usage:**
```bash
./generate-kubeconfig.sh <namespace> <service-account-name> [output-file]
```

**Examples:**
```bash
# Generate kubeconfig for team-alpha developer
./generate-kubeconfig.sh team-alpha team-alpha-developer

# Generate kubeconfig for team-beta deployer with custom filename
./generate-kubeconfig.sh team-beta team-beta-deployer beta-ci-cd.kubeconfig

# Generate kubeconfig for read-only access
./generate-kubeconfig.sh team-gamma team-gamma-readonly
```

### switch-context.sh

Quickly switch between different namespace contexts.

**Usage:**
```bash
# Show current context and available namespaces
./switch-context.sh

# Switch to a specific namespace
./switch-context.sh team-alpha
./switch-context.sh team-beta
./switch-context.sh team-gamma
```

## Working with Multiple Kubeconfigs

### Method 1: KUBECONFIG Environment Variable

```bash
# Set single kubeconfig
export KUBECONFIG=/path/to/team-alpha-developer.kubeconfig

# Use multiple kubeconfigs (colon-separated)
export KUBECONFIG=~/.kube/config:/path/to/team-alpha.kubeconfig
```

### Method 2: --kubeconfig Flag

```bash
kubectl --kubeconfig=./team-alpha-developer.kubeconfig get pods
```

### Method 3: Merge Kubeconfigs

```bash
# Backup your current config
cp ~/.kube/config ~/.kube/config.backup

# Merge configs
KUBECONFIG=~/.kube/config:./team-alpha.kubeconfig kubectl config view --flatten > ~/.kube/config.new
mv ~/.kube/config.new ~/.kube/config
```

## Context Management

### List All Contexts
```bash
kubectl config get-contexts
```

### Switch Context
```bash
kubectl config use-context <context-name>
```

### Set Default Namespace for Context
```bash
kubectl config set-context --current --namespace=team-alpha
```

### Create a New Context
```bash
kubectl config set-context team-alpha-dev \
  --cluster=my-cluster \
  --namespace=team-alpha \
  --user=team-alpha-developer
```

## Service Account Access Patterns

### Developer Access
For daily development work with full CRUD access to namespace resources:
```bash
./generate-kubeconfig.sh team-alpha team-alpha-developer
```

### Deployer Access (CI/CD)
For automated deployments with limited permissions:
```bash
./generate-kubeconfig.sh team-alpha team-alpha-deployer alpha-ci.kubeconfig
```

### Read-Only Access (Monitoring/Auditing)
For monitoring tools or auditors who need view-only access:
```bash
./generate-kubeconfig.sh team-alpha team-alpha-readonly
```

## Security Best Practices

1. **Rotate Credentials Regularly**: Generate new tokens periodically
2. **Principle of Least Privilege**: Use the minimum permissions necessary
3. **Secure Storage**: Store kubeconfig files securely, never commit to git
4. **Audit Access**: Regularly review who has access to which namespaces
5. **Token Expiration**: Set appropriate token expiration times for service accounts

## Testing RBAC Permissions

To test what a service account can do:

```bash
# Can I create pods?
kubectl auth can-i create pods --as=system:serviceaccount:team-alpha:team-alpha-developer -n team-alpha

# Can I delete secrets?
kubectl auth can-i delete secrets --as=system:serviceaccount:team-alpha:team-alpha-readonly -n team-alpha

# Can I list pods in another namespace?
kubectl auth can-i list pods --as=system:serviceaccount:team-alpha:team-alpha-developer -n team-beta

# Get all permissions for a service account
kubectl auth can-i --list --as=system:serviceaccount:team-alpha:team-alpha-developer -n team-alpha
```

## Troubleshooting

### "Unauthorized" Errors
- Verify the service account exists: `kubectl get sa -n <namespace>`
- Check RBAC bindings: `kubectl get rolebindings -n <namespace>`
- Verify token is valid: Token may have expired

### Cannot Access Resources
- Check if namespace exists
- Verify RBAC permissions using `kubectl auth can-i`
- Ensure network policies allow access if testing from within cluster

### Context Not Found
- List available contexts: `kubectl config get-contexts`
- Verify kubeconfig file path is correct
- Check KUBECONFIG environment variable
