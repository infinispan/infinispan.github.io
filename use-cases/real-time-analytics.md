---
layout: use-case-single
title: Real-Time Analytics and Querying
---

## Real-Time Analytics and Querying

Infinispan indexes data as it enters the cache and exposes a query engine that returns results in microseconds. 
You can run full-text searches, aggregations, and continuous queries directly against in-memory data without 
sending it to an external analytics system first.

### Indexed queries

Infinispan builds and maintains indexes automatically as entries are created, updated, or removed. 
Queries run against these indexes instead of scanning every entry, keeping response times constant 
even as data volumes grow.

* **Full-text search**: tokenized, analyzed text fields with support for fuzzy matching, wildcard, 
and phrase queries. Find entries by content, not just by key.
* **Range queries**: filter on numeric fields, dates, or any comparable attribute. 
Combine with full-text conditions in a single query.
* **Sorting and pagination**: order results by any indexed field and paginate with configurable 
page size. Retrieve only the data your application needs.
* **Aggregations**: compute counts, sums, averages, and min/max values directly in the query engine. 
No need to pull data to the client for post-processing.

### Ickle query language

Infinispan uses Ickle, a query language with a syntax familiar to anyone who has written SQL or JPQL:

```
FROM org.example.Transaction WHERE amount > 1000 AND status = 'PENDING' ORDER BY timestamp DESC
```

Ickle supports projections, parameterized queries, and hybrid full-text plus structured conditions 
in a single statement.

### Continuous queries

Standard queries return a snapshot. Continuous queries go further: they push updates to your 
application as data changes.

Define a query once and Infinispan notifies you when:

* A new entry **matches** the query (Joining event).
* A matching entry **changes** (Updated event).
* An entry **stops matching** (Leaving event).

This is the foundation for real-time dashboards, threshold-based alerting, and live data feeds 
without polling.

### Indexing strategies

Infinispan offers flexibility in how and where indexes are stored:

* **Local indexing**: indexes are stored on each node for the data it owns. 
Lower overhead, suitable for most deployments.
* **Manual indexing**: control when reindexing happens for bulk data loads or migrations. 
Avoid index rebuild overhead during high-volume ingestion.

### When to use this pattern

Real-time analytics with Infinispan fits scenarios where:

* Data changes frequently and queries must reflect the latest state immediately.
* You need sub-millisecond query responses that a disk-backed database cannot deliver.
* Your application requires full-text search alongside structured queries on the same dataset.
* You want to react to data patterns in real time (continuous queries) rather than batch-process after the fact.

Typical domains: financial transaction monitoring, IoT sensor analysis, real-time inventory 
visibility, operational dashboards, and fraud pattern detection.

### Learn more

* [Querying documentation](https://infinispan.org/docs/stable/titles/querying/querying.html)
* [Event-driven architecture](/use-cases/event-driven-architecture.html)
* [Boost application performance](/use-cases/boost-application-performance.html)
