---
layout: use-case-single
title: Boost Application Performance
---

## Boost Application Performance

Infinispan stores data in memory, eliminating disk I/O and delivering sub-millisecond reads and writes. Whether you use it as a cache in front of a database or as a standalone data store, your application gets the data it needs without waiting.

### Deployment patterns

**Embedded mode** — add Infinispan as a library dependency and store data in the same JVM as your application. Zero network overhead, microsecond-level access. Ideal for single-node applications or when you need an in-process cache.

**Client-server mode** — deploy Infinispan Server as an independent data layer. Applications connect via HotRod (binary protocol), REST, or RESP (Redis protocol). Consistent hashing routes each request directly to the node that owns the data, keeping latency under 1ms even in large clusters.

### Performance techniques

* **Near-caching** — HotRod clients keep a local copy of frequently accessed entries. Reads hit the local JVM first, falling back to the cluster only on miss. Combines the consistency of distributed storage with the speed of local access.
* **Off-heap storage** — store data outside the JVM heap to avoid garbage collection pauses. Predictable latency even with large datasets (tens of GB per node).
* **Segmented data container** — data is divided into segments that can be processed in parallel, maximizing throughput on multi-core hardware.

### Side-caching pattern

The most common use of Infinispan is as a side-cache in front of a database:

1. Application checks Infinispan first.
2. **Cache hit** — return data immediately (sub-millisecond).
3. **Cache miss** — fetch from database, store in Infinispan with a TTL, return data.

This pattern reduces database load by 80-95% for read-heavy workloads and drops response times from tens of milliseconds to under 1ms.

### Session externalization

Stateful applications (HTTP sessions, shopping carts, user preferences) can externalize state to Infinispan. This lets application instances remain stateless and horizontally scalable while Infinispan handles persistence, replication, and expiration.

Supported out of the box with:
* **Quarkus** — `quarkus-infinispan-client` extension
* **Spring Boot** — Spring Session with Infinispan
* **WildFly** — built-in Infinispan subsystem

### Learn more

* [Getting started with Infinispan](/get-started/)
* [Side-caching use case](/use-cases/side-caching.html)
* [Embedded mode documentation](https://infinispan.org/docs/stable/titles/embedding/embedding.html)
* [HotRod client documentation](https://infinispan.org/docs/stable/titles/hotrod_java/hotrod_java.html)
