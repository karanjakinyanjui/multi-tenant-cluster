# Monitoring and Observability

This directory contains configurations for monitoring the multi-tenant Kubernetes cluster.

## Overview

The monitoring stack includes:

- **Prometheus**: Metrics collection and storage
- **ServiceMonitor**: Kubernetes service discovery for metrics
- **RBAC**: Monitoring service account with cluster-wide read access

## Architecture

```
┌─────────────────────────────────────────┐
│         Platform Namespace              │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │        Prometheus                │  │
│  │  - Scrapes all namespaces        │  │
│  │  - Uses monitoring-agent SA      │  │
│  │  - ClusterRole: monitoring-reader│  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
                  │
                  │ Scrape metrics
                  │
        ┌─────────┼─────────┼─────────┐
        ▼         ▼         ▼         ▼
   ┌────────┐┌────────┐┌────────┐┌────────┐
   │team-α  ││team-β  ││team-γ  ││platform│
   │pods    ││pods    ││pods    ││pods    │
   └────────┘└────────┘└────────┘└────────┘
```

## Deployment

### Deploy Monitoring Stack

```bash
# From the project root
kubectl apply -f monitoring/
```

This will create:
1. Prometheus deployment in platform namespace
2. Prometheus service
3. Prometheus configuration

### Verify Deployment

```bash
# Check Prometheus pod
kubectl get pods -n platform -l app=prometheus

# Check Prometheus service
kubectl get svc -n platform prometheus

# View Prometheus logs
kubectl logs -n platform -l app=prometheus
```

### Access Prometheus UI

```bash
# Port forward to access Prometheus
kubectl port-forward -n platform svc/prometheus 9090:9090

# Open in browser
open http://localhost:9090
```

## RBAC for Monitoring

The monitoring agent uses the `monitoring-reader` ClusterRole which provides:

- Read access to pods, nodes, services, endpoints
- Access to metrics endpoints
- Read access to namespaces and resource quotas

This is configured in `/rbac/cluster-roles/monitoring-cluster-role.yaml`

## Key Metrics to Monitor

### Resource Usage

```promql
# CPU usage by namespace
sum(rate(container_cpu_usage_seconds_total[5m])) by (namespace)

# Memory usage by namespace
sum(container_memory_usage_bytes) by (namespace)

# Pod count by namespace
count(kube_pod_info) by (namespace)
```

### Quota Utilization

```promql
# CPU quota usage percentage
(sum(kube_resourcequota{resource="requests.cpu"}) by (namespace) /
 sum(kube_resourcequota{resource="limits.cpu"}) by (namespace)) * 100

# Memory quota usage percentage
(sum(kube_resourcequota{resource="requests.memory"}) by (namespace) /
 sum(kube_resourcequota{resource="limits.memory"}) by (namespace)) * 100
```

### Network Policies

```promql
# Network policy drops
sum(rate(network_policy_drop_total[5m])) by (namespace)
```

### Application Health

```promql
# Pod restart count
kube_pod_container_status_restarts_total

# Pod status
kube_pod_status_phase

# Container status
kube_pod_container_status_ready
```

## Setting Up Application Metrics

### Add Prometheus Annotations to Pods

To enable automatic scraping of your application metrics:

```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
spec:
  # ... pod spec
```

### Expose Metrics Endpoint

Your application should expose metrics at the configured path (default `/metrics`):

```go
// Example in Go
import "github.com/prometheus/client_golang/prometheus/promhttp"

http.Handle("/metrics", promhttp.Handler())
```

## Alerting (Future Enhancement)

To add alerting, you can deploy Alertmanager:

```yaml
# Example alert rules
groups:
  - name: multi-tenant
    rules:
      - alert: HighCPUUsage
        expr: sum(rate(container_cpu_usage_seconds_total[5m])) by (namespace) > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage in {{ $labels.namespace }}"

      - alert: QuotaExceeded
        expr: kube_resourcequota{type="used"} / kube_resourcequota{type="hard"} > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Resource quota nearly exceeded in {{ $labels.namespace }}"
```

## Grafana Dashboards (Optional)

### Deploy Grafana

```bash
kubectl create deployment grafana --image=grafana/grafana:latest -n platform
kubectl expose deployment grafana --port=3000 --type=ClusterIP -n platform
```

### Access Grafana

```bash
kubectl port-forward -n platform svc/grafana 3000:3000
# Default credentials: admin/admin
```

### Import Dashboards

Recommended dashboards:
- **Kubernetes Cluster Monitoring**: Dashboard ID 6417
- **Kubernetes Resource Requests**: Dashboard ID 7187
- **Kubernetes Capacity Planning**: Dashboard ID 5228

## Monitoring Best Practices

1. **Set up alerts**: Configure Alertmanager for critical conditions
2. **Monitor quotas**: Track resource quota utilization
3. **Pod health**: Monitor pod restarts and failures
4. **Network policies**: Track network policy hits/drops
5. **RBAC auditing**: Monitor unauthorized access attempts
6. **Cost tracking**: Track resource usage for chargeback

## Troubleshooting

### Prometheus Not Scraping

```bash
# Check service account permissions
kubectl auth can-i list pods --as=system:serviceaccount:platform:monitoring-agent

# Check Prometheus targets
kubectl port-forward -n platform svc/prometheus 9090:9090
# Visit http://localhost:9090/targets

# Check Prometheus logs
kubectl logs -n platform -l app=prometheus
```

### Missing Metrics

```bash
# Verify pod has correct annotations
kubectl get pod <pod-name> -n <namespace> -o yaml | grep prometheus

# Check if metrics endpoint is accessible
kubectl exec -it <pod-name> -n <namespace> -- wget -O- localhost:8080/metrics
```

### High Memory Usage

```bash
# Check Prometheus storage usage
kubectl exec -n platform <prometheus-pod> -- du -sh /prometheus

# Adjust retention time in deployment
# --storage.tsdb.retention.time=15d
```

## Integration with External Systems

### Export to External Prometheus

```yaml
remote_write:
  - url: "https://prometheus.example.com/api/v1/write"
    basic_auth:
      username: "user"
      password: "pass"
```

### Export to Cloud Monitoring

```yaml
# For Google Cloud Monitoring
remote_write:
  - url: "https://monitoring.googleapis.com/v1/projects/PROJECT_ID/timeSeries"
```

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Kubernetes Monitoring Guide](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
