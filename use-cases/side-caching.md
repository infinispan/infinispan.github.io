---
layout: use-case-single
title: Side-Caching with Infinispan
---

## Side-Caching with Infinispan

### Why ?
Caching is a technique that can significantly improve the performance, efficiency, and user experience of your application. Here are several key reasons to use caching:

* **Improved Performance and Speed**: storing frequently accessed data in a location closer to the application  reduces the time required to retrieve the data compared to fetching it from the original source (like a database or external API) and makes responding to user requests faster.
* **Reduced Load on Backend Resources**: caching reduces the number of direct queries to the database, minimizing the load and allowing the database to handle other operations more efficiently. By using techniques such as near-caching, which stores frequently accessed data inside your application, network traffic can be reduced.
* **Cost Efficiency and Scalability**: achieve operational cost savings by reducing the need for frequent database queries or external API calls. By caching results of expensive computations, you avoid repeating the same computations multiple times. Caching can also help your application scale more effectively by handling a higher volume of requests without requiring a proportional increase in backend resources.
* **Improved Reliability and Availability**: if the original data source becomes unavailable, cached data can still be served, providing a level of fault tolerance. Also, during traffic spikes, caches can handle more requests by serving precomputed responses, reducing the risk of downtime or degraded performance caused by backend overload.
* **Flexibility in Data Management**: caches can be configured with various expiration policies (such as time-to-live) to ensure that data remains fresh and up-to-date as needed.

Side-caching uses the Typical Cache Update Pattern (or TCUP). Given an architecture with three components, an application, a backend service and a cache, the following sequence diagram explains the interactions between them:

{% mermaid %}
sequenceDiagram
    Application->>Cache: Get data
    alt cache miss
        Cache-->>Application: Cache miss
        Application->>Backend: Get data
        Backend-->>Application: Return data
        Application->>Cache: Store data in cache
    else cache hit
        Cache-->>Application: Return cached data
    end
{% endmermaid %}

Assuming `U` is the average latency between components in the above system, the overal latency of side-caching is:
* `2U` for a cache hit
* `5U` for a cache miss (assuming storing the data in the cache doesn't wait for the acknowledgment)

### Requirements

1. A Java client Application.
2. A Backend service.
2. Infinispan Server.

### Instructions

The following Java code snippet shows how your Application might invoke a hypothetical Backend service to retrieve the data for a *widget* identified by `key`:

```java
// assumes that var client = HttpClient.newHttpClient();
public String getWidget(String key) {
    var uri = URI.create("http://backend/widgets/" + key);
    var request = HttpRequest.newBuilder().uri(uri).build();
    return client.send(request, BodyHandlers.ofString());
}
```

Now, let's add some caching.

Start the Infinispan Server image supplying some credentials:

```shell
docker run -p 11222:11222 -e USER=infinispan -e PASS=secret quay.io/infinispan/server
```
**_NOTE:_**: `11222` is the default Infinispan server port. Infinispan automatically recognizes the type of client (Hot Rod, HTTP, Redis, Memcached).

In the application, initialize Infinispan's Hot Rod client and create a cache, if one does not already exist:

```java
RemoteCacheManager cacheManager = new RemoteCacheManager("hotrod://infinispan:secret@localhost:11222");
var cache = cacheManager.administration().getOrCreateCache("widget-cache", new StringConfiguration("\"distributed-cache\":{}}"));
```

By adopting the side-caching pattern, the method would look like:

```java
public String getWidget(String key) {
    return cache.computeIfAbsent(key, k -> {
        var uri = URI.create("http://backend/widgets/" + k);
        var request = HttpRequest.newBuilder().uri(uri).build();
        return client.send(request, BodyHandlers.ofString());
    }, 1, TimeUnit.HOUR);
}
```

The above code leverages the `Cache.computeIfAbsent()` method to implement the *compute value on a cache miss* logic. It also specifies an expiration time of 1 hour, after which the entry will be removed from the cache.
Instead of programmatically specifying the expiration timeout for each entry, it's possible to do so in the cache configuration:

```json
{
    "distributed-cache": {
        "expiration": {
            "lifespan": "3600000"
        }
    }
}
```


#### Make it asynchronous

The above code is synchronous. Converting it to use asynchronous calls is easy:

```java
public CompletionStage<String> getWidget(String key) {
    return cache.computeIfAbsentAsync(key, k -> {
        var uri = URI.create("http://backend/widgets/" + k);
        var request = HttpRequest.newBuilder().uri(uri).build();
        return client.sendAsync(request, BodyHandlers.ofString());
    }, 1, TimeUnit.HOUR);
}
```

### Further reading

* [Using the Java Hot Rod client](https://infinispan.org/docs/stable/titles/hotrod_java/hotrod_java.html)
* [Configuring Caches](https://infinispan.org/docs/stable/titles/configuring/configuring.html)
