---
layout: use-case-single
title: Session Management
---

## Session Management

Web applications need to track user state: login sessions, shopping carts, form progress, user preferences. 
Storing that state in the application itself limits your ability to scale. Infinispan externalizes session 
data into a shared, replicated in-memory store so your application instances stay stateless and 
horizontally scalable.

### The problem with local sessions

When sessions live in application memory, every request from a user must reach the same instance. 
This creates tight coupling between users and servers:

* **Sticky sessions**: load balancers must route by session affinity, reducing flexibility and creating hot spots.
* **Lost sessions on failure**: when an instance crashes or restarts, all its sessions disappear. Users get logged out.
* **Scaling friction**: adding instances doesn't help if existing sessions can't migrate.

### How Infinispan solves it

Infinispan stores session data in a distributed cache that all application instances share. Sessions are 
replicated across cluster nodes, surviving instance failures without user disruption.

{% mermaid %}
flowchart LR
    LB[Load Balancer] --> App1[App Instance 1]
    LB --> App2[App Instance 2]
    LB --> App3[App Instance 3]
    App1 --> ISP[Infinispan Cluster]
    App2 --> ISP
    App3 --> ISP
{% endmermaid %}

Any instance can serve any user. No sticky sessions. No session loss. Scale application instances 
up and down freely. **Infinispan handles the state**.

### What you get

* **Session survival**: application restarts and node failures don't affect user sessions. Infinispan replicates data across nodes automatically.
* **Automatic expiration**: idle sessions are cleaned up with configurable TTL. No manual garbage collection.
* **Sub-millisecond access**: session reads and writes happen in memory, keeping response times low even under heavy load.
* **Elastic scaling**: add or remove application instances without migrating sessions. Infinispan rebalances data transparently.

### Framework support

Infinispan integrates with major Java frameworks out of the box:

* **Quarkus** — the `quarkus-infinispan-client` extension provides session storage with minimal configuration.
* **Spring Boot** — Spring Session with the Infinispan store. Annotate your configuration and sessions are externalized.
* **WildFly** — built-in Infinispan subsystem handles HTTP session clustering. No additional dependencies.
* **Tomcat** — session manager implementation stores sessions in a remote Infinispan cluster.

### When to use this pattern

Session externalization is the right choice when your application needs to:

* Scale horizontally without session affinity constraints.
* Survive rolling deployments and instance failures without logging users out.
* Share session state across multiple application instances or data centers (via cross-site replication).

### Learn more

* [Spring Session with Infinispan](https://infinispan.org/docs/stable/titles/spring_boot/starter.html)
* [High availability and elasticity](/use-cases/high-availability-and-elasticity.html)
* [Backup across data centers](/use-cases/backup-across-data-centers.html)
