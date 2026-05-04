---
layout: use-case-single
title: Event-Driven Architecture
---

## Event-Driven Architecture

Infinispan notifies your application when data changes. Instead of polling for updates, your services react 
to cache events in real time — entries created, modified, expired, or removed. 
This turns Infinispan into an event backbone that connects your components through data changes.

### How it works

Infinispan provides two complementary mechanisms for event-driven patterns:

**Client listeners**: register callbacks on a cache and receive notifications when entries change. Listeners fire on create, modify, remove, and expiration events. 
Each event carries the key and metadata so your application can react immediately.
**Continuous queries**: define a query and Infinispan pushes matching results to your application as data changes. 
When a cache entry starts matching the query, you get a `Joining` event. When it stops matching, a `Leaving` event. When a matching entry changes, an `Updated` event.

{% mermaid %}
flowchart LR
    subgraph Infinispan Cluster
        C[Cache]
    end
    C -- "entry created" --> S1[Order Service]
    C -- "entry modified" --> S2[Notification Service]
    C -- "query match" --> S3[Analytics Service]
{% endmermaid %}

### Use cases

**Real-time notifications**: alert users or downstream services the moment data changes. A price update in the cache triggers 
notifications to all interested clients without polling.
**Data pipelines**: chain processing stages through cache events. One service writes enriched data to a cache, 
another reacts to it, transforms it, and writes results to another cache.
**Monitoring and alerting**: continuous queries watch for threshold breaches. When a metric crosses a boundary, 
the query engine pushes an event immediately. No periodic scans.
**Cache synchronization**: keep derived data structures, search indexes, or external systems in sync with the 
authoritative cache. React to changes instead of running batch reconciliation.

### Filtering events

Not every event matters to every listener. Infinispan supports server-side event filtering so only relevant events cross the network:

* **Key filters**: receive events only for specific keys or key patterns.
* **Query filters**: combine with full-text queries to receive events only when data matches complex conditions.
* **Converter factories**: transform event payloads on the server before sending them to the client, reducing bandwidth.

### Clustered listeners

By default, listeners on a remote client receive events from the entire cluster, regardless of which node processed the write. 
Infinispan routes events transparently, so your application sees a unified stream of changes across all nodes.

### Learn more

* [Cache listeners documentation](https://infinispan.org/docs/stable/titles/developing/developing.html#cache_listeners)
* [Continuous queries documentation](https://infinispan.org/docs/stable/titles/developing/developing.html#query_continuous)
* [High availability and elasticity](/use-cases/high-availability-and-elasticity.html)
