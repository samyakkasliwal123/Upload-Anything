# KEDA Scaled Worker Configuration Guide

## Problem Analysis
With 15 workers running via KEDA scaling, the previous aggressive configuration was causing:
- **Resource Contention**: 15 workers × 50 concurrent tasks = 750 total concurrent operations
- **Memory Pressure**: Too many ThreadPoolExecutor threads across all workers
- **Database Connection Exhaustion**: Each worker creating too many DB connections
- **CPU Thrashing**: Over-subscription of CPU resources

## Fixed Configuration

### Current Settings (Optimized for 15 Workers)

```python
# Workflow Worker (per worker instance)
max_concurrent_workflow_task_polls = 2    # Conservative polling
max_concurrent_workflow_tasks = 3         # 15 workers × 3 = 45 total workflows

# IO Activity Worker (per worker instance)  
activity_executor = ThreadPoolExecutor(max_workers=10)  # Reduced thread pool
max_concurrent_activity_task_polls = 2    # Conservative polling
max_concurrent_activities = 5             # 15 workers × 5 = 75 total activities

# CPU Activity Worker (per worker instance)
activity_executor = ThreadPoolExecutor(max_workers=4)   # Very conservative
max_concurrent_activity_task_polls = 1    # Single poll per worker
max_concurrent_activities = 2             # 15 workers × 2 = 30 CPU activities
```

### Total System Capacity
- **Concurrent Workflows**: 45 (vs. previous 750)
- **IO Activities**: 75 (vs. previous 750) 
- **CPU Activities**: 30 (vs. previous 300)
- **Thread Pool Size**: 14 threads per worker (vs. previous 100+)

## Resource Calculations

### Memory Usage (Estimated)
- **Per Worker**: ~200-300MB (vs. previous 500-800MB)
- **Total 15 Workers**: ~3-4.5GB (vs. previous 7.5-12GB)

### Database Connections
- **Per Worker**: ~15-20 connections (vs. previous 50-100)
- **Total 15 Workers**: ~225-300 connections (vs. previous 750-1500)

### CPU Utilization
- **Per Worker**: 1-2 CPU cores effectively utilized
- **Total**: Efficient use of available CPU without thrashing

## KEDA Scaling Recommendations

### Scaling Metrics
Monitor these metrics for KEDA scaling decisions:

```yaml
# Example KEDA ScaledObject
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: temporal-worker-scaler
spec:
  scaleTargetRef:
    name: temporal-worker
  minReplicaCount: 3
  maxReplicaCount: 20
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus:9090
      metricName: temporal_workflow_queue_depth
      threshold: '10'
      query: temporal_workflow_task_queue_depth{queue="document-workflow-queue"}
  - type: prometheus
    metadata:
      serverAddress: http://prometheus:9090
      metricName: temporal_activity_queue_depth
      threshold: '15'
      query: temporal_activity_task_queue_depth{queue="document-io-activity-queue"}
```

### Scaling Thresholds
- **Scale Up**: When queue depth > 10 workflows or > 15 activities
- **Scale Down**: When queue depth < 3 workflows and < 5 activities
- **Min Workers**: 3 (for baseline capacity)
- **Max Workers**: 20 (safety limit)

## Performance Expectations

### With Fixed Configuration:
- **P99 Latency**: Should return to 3-4 seconds at 25-30 RPS
- **Queue Depth**: Should remain < 10 under normal load
- **Resource Utilization**: 60-80% CPU, stable memory usage
- **Error Rate**: < 1%

### Scaling Behavior:
- **Low Load (< 10 RPS)**: 3-5 workers
- **Medium Load (10-25 RPS)**: 5-10 workers  
- **High Load (25-40 RPS)**: 10-15 workers
- **Peak Load (> 40 RPS)**: 15-20 workers

## Monitoring Commands

### Check Current Worker Status
```bash
# Check running workers
kubectl get pods -l app=temporal-worker

# Check worker logs
kubectl logs -l app=temporal-worker --tail=100

# Check KEDA scaling status
kubectl get scaledobject temporal-worker-scaler
```

### Monitor Temporal Metrics
```bash
# Workflow queue depth
curl -s http://temporal-worker:9464/metrics | grep temporal_workflow_task_queue_depth

# Activity queue depth  
curl -s http://temporal-worker:9464/metrics | grep temporal_activity_task_queue_depth

# Worker resource usage
kubectl top pods -l app=temporal-worker
```

## Troubleshooting

### If Latency is Still High:
1. **Check Queue Depth**: If > 20, increase max workers in KEDA
2. **Check Resource Limits**: Ensure workers have adequate CPU/memory
3. **Check Database**: Monitor connection pool usage
4. **Check External Services**: S3, Redis, LLM services

### If Workers are Crashing:
1. **Reduce Concurrency**: Lower `max_concurrent_activities` further
2. **Increase Resources**: Bump CPU/memory limits
3. **Check Logs**: Look for OOM or connection errors

### If Scaling is Too Aggressive:
1. **Increase Thresholds**: Raise queue depth thresholds in KEDA
2. **Add Cooldown**: Configure scale-down cooldown period
3. **Adjust Min/Max**: Fine-tune replica count limits

## Environment Variables

Add these for fine-tuning:

```bash
# Worker concurrency (optional overrides)
TEMPORAL_WORKFLOW_CONCURRENCY=3
TEMPORAL_IO_ACTIVITY_CONCURRENCY=5  
TEMPORAL_CPU_ACTIVITY_CONCURRENCY=2

# Thread pool sizes
TEMPORAL_IO_THREAD_POOL_SIZE=10
TEMPORAL_CPU_THREAD_POOL_SIZE=4

# Database connection limits per worker
DB_POOL_SIZE=20
DB_MAX_OVERFLOW=30
```

## Deployment Steps

1. **Deploy Fixed Configuration**:
   ```bash
   kubectl apply -f temporal-worker-deployment.yaml
   ```

2. **Monitor Initial Performance**:
   ```bash
   # Watch for 10-15 minutes
   kubectl logs -f -l app=temporal-worker
   ```

3. **Load Test**:
   ```bash
   # Test at 25-30 RPS
   # Monitor queue depths and latency
   ```

4. **Adjust KEDA if Needed**:
   ```bash
   # Fine-tune scaling thresholds based on observed behavior
   kubectl apply -f keda-scaledobject.yaml
   ```

## Success Metrics

### Target Performance:
- ✅ P99 Latency < 4 seconds at 30 RPS
- ✅ Queue Depth < 10 under normal load
- ✅ Worker CPU utilization 60-80%
- ✅ Memory usage stable and predictable
- ✅ No worker crashes or OOM errors
- ✅ Smooth KEDA scaling behavior

This configuration should resolve the performance issues while maintaining efficient resource utilization across your scaled worker fleet.