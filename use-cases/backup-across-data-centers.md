---
layout: use-case-single
title: Backup Across Data Centers
---

## Backup Across Data Centers

Infinispan clusters running in different geographical locations can form global clusters to back up your data across sites. If sites go offline, clients can immediately switch to an available cluster, making sure data center faults do not cause service interruptions.

### Cross-site topologies

#### Active-active

Both sites accept reads and writes. Infinispan replicates changes bidirectionally. Best for global applications where users connect to the nearest data center.

{% mermaid %}
flowchart LR
    subgraph Site_A["Site A (US East)"]
        A1[Node 1] --- A2[Node 2]
        A2 --- A3[Node 3]
    end
    subgraph Site_B["Site B (EU West)"]
        B1[Node 1] --- B2[Node 2]
        B2 --- B3[Node 3]
    end
    Site_A -- "replicate ⇄" --> Site_B
    Site_B -- "replicate ⇄" --> Site_A
    U1[Users US] --> Site_A
    U2[Users EU] --> Site_B
{% endmermaid %}

#### Active-passive

One site handles all traffic, the other maintains a hot standby. On failure, clients failover to the backup site. Simpler to reason about, lower replication overhead.

{% mermaid %}
flowchart LR
    subgraph Primary["Primary Site (Active)"]
        P1[Node 1] --- P2[Node 2]
        P2 --- P3[Node 3]
    end
    subgraph Backup["Backup Site (Standby)"]
        S1[Node 1] --- S2[Node 2]
        S2 --- S3[Node 3]
    end
    Primary -- "replicate →" --> Backup
    Users[All Users] --> Primary
    Users -. "failover" .-> Backup
{% endmermaid %}

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
