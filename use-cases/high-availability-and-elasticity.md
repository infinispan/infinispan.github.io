---
layout: use-case-single
title: High Availability & Elasticity
---

## High Availability & Elasticity

Infinispan automatically distributes data across cluster nodes and rebalances when the topology changes. Add nodes to scale out, remove them to scale in — data movement happens transparently with zero downtime.

### Clustering modes

**Distributed mode** — data is spread across the cluster with a configurable number of copies (owners). With 2 owners, the cluster tolerates any single node failure without data loss. Scales to hundreds of nodes.

**Replicated mode** — every node holds a full copy of all data. Maximum read throughput (any node can serve any request) at the cost of write amplification. Best for small, read-heavy datasets.

**Invalidation mode** — each node maintains its own local cache. When one node updates an entry, it invalidates copies on other nodes. Minimizes network traffic when writes are infrequent.

### What happens when a node fails?

1. The cluster detects the missing node (configurable timeout, typically seconds).
2. Surviving nodes that hold backup copies promote them to primary.
3. New backup copies are created on other nodes to restore the configured redundancy level.
4. HotRod clients detect the topology change automatically and route requests to the new data owners.

No manual intervention required. No data loss. No downtime.

### Elastic scaling

Add a node to an existing cluster:

1. The new node joins via auto-discovery (UDP multicast, DNS, Kubernetes API, or JDBC).
2. The cluster rebalances — existing nodes transfer segments to the new member.
3. Once rebalancing completes, the new node serves reads and writes.

Remove a node (planned or unplanned) and the same rebalancing runs in reverse.

### Session externalization

A popular use for Infinispan is as a shared store for stateful data. Applications externalize HTTP sessions to Infinispan clusters, staying lightweight and stateless while Infinispan handles:

* **Replication** — sessions survive application restarts and node failures.
* **Expiration** — idle sessions are cleaned up automatically with TTL.
* **Scalability** — add application instances without session affinity (sticky sessions).

### Learn more

* [Server documentation](https://infinispan.org/docs/stable/titles/server/server.html)
* [Kubernetes Operator](https://infinispan.org/docs/infinispan-operator/main/operator.html)
* [Planning and tuning](https://infinispan.org/docs/stable/titles/tuning/tuning.html)
