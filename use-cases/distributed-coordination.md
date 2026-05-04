---
layout: use-case-single
title: Distributed Coordination for Microservices
---

## Distributed Coordination for Microservices

Microservices that share state across instances need coordination primitives, locks to prevent concurrent modifications, 
counters for sequencing and rate limiting, and shared data structures for cross-service communication. Infinispan provides these as clustered, fault-tolerant building blocks that survive node failures.

### Clustered locks

Infinispan's clustered locks provide mutual exclusion across all nodes in the cluster. 
Only one instance holds the lock at a time, regardless of how many nodes compete for it.

* **Distributed ownership**: the lock state is replicated across the cluster. If the node holding the lock fails, another node takes over and the lock is released.
* **Reentrancy**: a thread that already holds the lock can acquire it again without deadlocking.
* **Non-blocking API**: `tryLock` with timeout support, built on `CompletionStage` for async workflows.

Typical uses: leader election, preventing duplicate job execution, serializing access to external resources 
that don't support concurrent writes.


### Clustered counters

Atomic counters that maintain a consistent value across the cluster. Two modes cover different consistency and 
performance needs:

**Strong counters**: linearizable, ACID-compliant. Every read returns the latest value. Supports compare-and-set for conditional updates. 
Use for sequence generation, distributed rate limiting, or any scenario requiring exact counts.
**Weak counters**: eventually consistent, higher throughput. Updates are applied locally and 
merged across the cluster asynchronously. Use for approximate metrics, hit counters, and monitoring 
where speed matters more than precision.

Both counter types survive node failures. Strong counters recover their exact value; weak counters converge to the correct total after rebalancing.

### Multimap caches

A single key maps to multiple values. Infinispan manages the collection server-side, so clients add or remove individual 
values without retrieving and re-storing the entire collection.

Typical uses: tracking active sessions per user, maintaining subscriber lists, grouping related events 
by correlation ID.

### Why not use a database for coordination?

Databases can provide locks and atomic operations, but at a cost:

* **Latency**: disk-backed storage adds milliseconds to every lock acquisition. Infinispan operates in memory with sub-millisecond response.
* **Scalability**: database connections are a limited resource. Infinispan scales horizontally with your microservice instances.
* **Coupling**: tying coordination to your persistence layer means downtime in one affects both. Infinispan keeps coordination independent.

### Architecture pattern

{% mermaid %}
flowchart TB
    subgraph Microservices
        S1[Service A]
        S2[Service B]
        S3[Service C]
    end
    subgraph Infinispan Cluster
        L[Clustered Locks]
        C[Clustered Counters]
        M[Multimap Caches]
    end
    S1 --> L
    S2 --> C
    S3 --> M
    S1 --> C
{% endmermaid %}

Services connect to the Infinispan cluster via HotRod and use the coordination APIs alongside regular 
caching operations. A single Infinispan deployment serves both roles, no need for a separate coordination service.

### Learn more

* [Clustered locks documentation](https://infinispan.org/docs/stable/titles/developing/developing.html#clustered_lock)
* [Clustered counters documentation](https://infinispan.org/docs/stable/titles/developing/developing.html#clustered_counters)
* [High availability and elasticity](/use-cases/high-availability-and-elasticity.html)
