---
layout: use-case-single
title: In-Line Caching
---

## In-Line Caching

With in-line caching, Infinispan sits between your application and the persistent store, handling all reads and writes 
to the backend automatically. Unlike side-caching, where the application manages cache population, in-line caching 
delegates that responsibility to Infinispan through cache stores.

### Side-caching vs. in-line caching

In a side-cache, the application decides when to read from and write to both the cache and the backend. 
In-line caching reverses that: the application talks only to Infinispan, and Infinispan manages the backend.

{% mermaid %}
flowchart LR
    subgraph Side-Caching
        A1[Application] --> C1[Cache]
        A1 --> DB1[Database]
    end
    subgraph In-Line Caching
        A2[Application] --> C2[Cache]
        C2 --> DB2[Database]
    end
{% endmermaid %}

This simplifies application code. Your service reads and writes to Infinispan. Infinispan handles persistence 
behind the scenes.

### Write-through

Every write to the cache is synchronously written to the persistent store before the operation returns. 
The application gets a confirmation only after both the cache and the backend are updated.

* **Strong consistency**: cache and backend are always in sync.
* **Predictable durability**: no data loss window. Every accepted write is persisted.
* **Trade-off**: write latency includes the backend round-trip.

Best for workloads where data loss is not acceptable: financial records, inventory updates, user account changes.

### Write-behind

Writes are accepted into the cache immediately and asynchronously flushed to the persistent store in the background. 
The application gets sub-millisecond write confirmation while Infinispan batches and coalesces backend writes.

* **Low write latency**: the application never waits for the backend.
* **Reduced backend load**: multiple updates to the same key are coalesced into a single backend write.
* **Trade-off**: a short window exists where the cache is ahead of the backend.

Best for high-throughput workloads where eventual consistency with the backend is acceptable: event logging, 
metrics collection, user activity tracking.

### Cache loading and preloading

Infinispan can populate the cache from the persistent store automatically:

* **Read-through**: on a cache miss, Infinispan loads the entry from the backend, caches it, and returns it. The application never interacts with the backend directly.
* **Preloading**: at startup, Infinispan loads existing data from the backend into the cache so it starts warm. No cold-cache penalty.

### Passivation

For large datasets that don't fit entirely in memory, passivation moves idle entries from memory to the persistent store. 
When an entry is accessed again, Infinispan activates it back into memory transparently. 
This keeps the working set in memory while the full dataset remains available.

### Supported persistent stores

Infinispan ships with cache store implementations for common backends:

* **JDBC**: relational databases (PostgreSQL, MySQL, Oracle, SQL Server).
* **RocksDB**: embedded key-value storage for local persistence.
* **Remote store**: chain Infinispan clusters together, using one as the persistent backend for another.
* **Custom stores**: implement the cache store SPI to connect to any backend.

### Learn more

* [Cache stores documentation](https://infinispan.org/docs/stable/titles/configuring/configuring.html#cache_stores)
* [Side-caching use case](/use-cases/side-caching.html)
* [Boost application performance](/use-cases/boost-application-performance.html)
