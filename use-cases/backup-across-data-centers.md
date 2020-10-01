---
layout: use-case-single
title: Backup Across Data Centers
---

Infinispan clusters running in different geographical locations can form global clusters to back up your data across sites. If sites go offline clients can immediately switch to an available cluster, making sure data center faults do not cause service interruptions.

When using the Infinispan Operator with Kubernetes environments such as Red Hat OpenShift,  cross-site replication capabilities make your data ready for hybrid and multi cloud deployments.

Infinispan also guarantees data consistency when using cross-site replication, even in cases where clients make concurrent writes at different locations that use asynchronous replication. So your data is always there and always accurate, no matter where you’re running.
