---
layout: use-case-single
title: Backup Across Data Centers
---

## Backup Across Data Centers

Infinispan clusters running in different geographical locations can form global clusters to back up your data across sites. If sites go offline, clients can immediately switch to an available cluster, making sure data center faults do not cause service interruptions.

### Cross-site topologies

#### Active-active

Both sites accept reads and writes. Infinispan replicates changes bidirectionally. Best for global applications where users connect to the nearest data center.

{% plantuml %}
left to right direction
rectangle "Users US" as U1
rectangle "Site A (US East)" as SiteA {
    rectangle "Node 1" as A1
    rectangle "Node 2" as A2
    rectangle "Node 3" as A3
    A1 -- A2
    A2 -- A3
}
rectangle "Site B (EU West)" as SiteB {
    rectangle "Node 1" as B1
    rectangle "Node 2" as B2
    rectangle "Node 3" as B3
    B1 -- B2
    B2 -- B3
}
rectangle "Users EU" as U2

U1 --> SiteA
U2 --> SiteB
SiteA <--> SiteB : replicate ⇄
{% endplantuml %}

#### Active-passive

One site handles all traffic, the other maintains a hot standby. On failure, clients failover to the backup site. Simpler to reason about, lower replication overhead.

{% plantuml %}
left to right direction
rectangle "All Users" as Users
rectangle "Primary Site (Active)" as Primary {
    rectangle "Node 1" as P1
    rectangle "Node 2" as P2
    rectangle "Node 3" as P3
    P1 -- P2
    P2 -- P3
}
rectangle "Backup Site (Standby)" as Backup {
    rectangle "Node 1" as S1
    rectangle "Node 2" as S2
    rectangle "Node 3" as S3
    S1 -- S2
    S2 -- S3
}

Users --> Primary
Primary --> Backup : replicate
Users ..> Backup : failover
{% endplantuml %}

### Conflict resolution

When concurrent writes happen at different sites with asynchronous replication, conflicts are inevitable. Infinispan detects and resolves them automatically:

* **Last-write-wins** — the most recent update takes precedence based on timestamps.
* **Custom merge policies** — implement your own conflict resolution logic for domain-specific requirements.

Data consistency is guaranteed even across sites — your data is always there and always accurate, no matter where you're running.

### Kubernetes and hybrid cloud

When using the Infinispan Operator with Kubernetes environments such as Red Hat OpenShift, cross-site replication makes your data ready for hybrid and multi-cloud deployments:

* **Multi-cluster** — replicate between Kubernetes clusters in different regions or cloud providers.
* **Hybrid** — connect on-premises Infinispan clusters with cloud-based ones.
* **Disaster recovery** — automatic failover when an entire data center goes down.

### Included in the open source edition

Cross-site replication is fully available in the community distribution. No enterprise license required — unlike some competing products that gate this feature behind a commercial offering.

### Learn more

* [Cross-site replication documentation](https://infinispan.org/docs/stable/titles/xsite/xsite.html)
* [Kubernetes Operator](https://infinispan.org/docs/infinispan-operator/main/operator.html)
* [Server documentation](https://infinispan.org/docs/stable/titles/server/server.html)
