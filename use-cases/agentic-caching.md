---
layout: use-case-single
title: Agentic AI Caching
---

## Agentic AI Caching

### Why?

AI agents (built with LangGraph, CrewAI, AutoGPT, or custom frameworks) make dozens of tool calls per task:
API lookups, web searches, database queries, and computations. Many of these calls are redundant — the same
API gets called with the same or similar parameters across multiple agent runs.

Without caching, agents are wasteful:

* **Repeated API calls** — the same weather lookup, stock price, or database query runs over and over.
* **Redundant LLM calls** — agents re-ask the same questions to the LLM during reasoning loops.
* **Slow tool execution** — external API calls add seconds of latency per step.

Infinispan provides a distributed caching layer that eliminates this waste:

* **Multi-protocol access** — agents in any language can cache via HotRod, REST, or RESP (Redis protocol).
* **TTL-based expiration** — cached results automatically expire when they become stale.
* **Near-caching** — frequently accessed data is cached locally in the agent process for zero-latency reads.
* **Distributed and shared** — multiple agents share the same cache, so one agent's lookup benefits all others.
* **Resilient** — cached data survives individual agent crashes and is replicated across the cluster.

{% mermaid %}
sequenceDiagram
    participant Agent as AI Agent
    participant ISPN as Infinispan Cache
    participant Tool as External Tool / API

    Agent->>ISPN: Check cache for tool result
    alt cache hit
        ISPN-->>Agent: Return cached result
    else cache miss
        ISPN-->>Agent: Not found
        Agent->>Tool: Execute tool call
        Tool-->>Agent: Tool result
        Agent->>ISPN: Store result with TTL
    end
{% endmermaid %}

### Quarkus + LangChain4j

Use Infinispan as a caching layer for AI tool results in a Quarkus application:

```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-infinispan-client</artifactId>
</dependency>
```

Configure the Infinispan connection:

```properties
quarkus.infinispan-client.hosts=localhost:11222
quarkus.infinispan-client.username=admin
quarkus.infinispan-client.password=password
```

Implement a cached tool:

```java
@ApplicationScoped
public class CachedWeatherTool {

    @Inject
    RemoteCacheManager cacheManager;

    @Tool("Get the current weather for a city")
    public String getWeather(String city) {
        RemoteCache<String, String> cache = cacheManager
            .getCache("tool-results");

        String cacheKey = "weather:" + city.toLowerCase();

        return cache.computeIfAbsent(cacheKey, k -> {
            // Call external weather API
            return weatherApiClient.getCurrentWeather(city);
        }, 30, TimeUnit.MINUTES);
    }
}
```

The `computeIfAbsent` method atomically checks the cache and populates it on a miss — with a 30-minute TTL so weather data stays fresh.

### Spring AI

Add the Infinispan Spring Boot starter:

```xml
<dependency>
    <groupId>org.infinispan</groupId>
    <artifactId>infinispan-spring-boot3-starter-remote</artifactId>
</dependency>
```

Configure in `application.properties`:

```properties
infinispan.remote.server-list=localhost:11222
infinispan.remote.auth-username=admin
infinispan.remote.auth-password=password
```

Implement cached function calling:

```java
@Service
public class CachedToolService {

    private final RemoteCacheManager cacheManager;

    public CachedToolService(RemoteCacheManager cacheManager) {
        this.cacheManager = cacheManager;
    }

    @Description("Get the current weather for a city")
    public String getWeather(String city) {
        RemoteCache<String, String> cache = cacheManager
            .getCache("tool-results");

        String cacheKey = "weather:" + city.toLowerCase();

        return cache.computeIfAbsent(cacheKey, k -> {
            return weatherClient.getCurrentWeather(city);
        }, 30, TimeUnit.MINUTES);
    }
}
```

### LangChain4j (standalone Java)

```java
RemoteCacheManager cacheManager = new RemoteCacheManager(
    new ConfigurationBuilder()
        .addServer().host("localhost").port(11222)
        .security().authentication()
        .username("admin").password("password")
        .build());

RemoteCache<String, String> toolCache = cacheManager.getCache("tool-results");

// Wrap any tool with caching
public String cachedToolCall(String toolName, String input) {
    String cacheKey = toolName + ":" + input;
    return toolCache.computeIfAbsent(cacheKey, k -> {
        return executeTool(toolName, input);
    }, 1, TimeUnit.HOURS);
}
```

### LangChain Python

Use Infinispan as a caching backend for LangChain tools:

```bash
pip install langchain-community
```

```python
from infinispan.client.hotrod import RemoteCacheManager
import json
import hashlib

class InfinispanToolCache:
    def __init__(self):
        self.cache_manager = RemoteCacheManager(
            host="localhost", port=11222
        )
        self.cache = self.cache_manager.get_cache("tool-results")

    def cached_tool(self, tool_name, func):
        def wrapper(*args, **kwargs):
            key = f"{tool_name}:{hashlib.md5(json.dumps(args).encode()).hexdigest()}"
            cached = self.cache.get(key)
            if cached:
                return json.loads(cached)
            result = func(*args, **kwargs)
            self.cache.put(key, json.dumps(result), lifespan=3600)
            return result
        return wrapper

cache = InfinispanToolCache()

@cache.cached_tool("weather")
def get_weather(city):
    return weather_api.get(city)
```

Alternatively, use the RESP (Redis) protocol to leverage any Redis client library:

```python
import redis

r = redis.Redis(host="localhost", port=6379)

def cached_tool_call(tool_name, input_data, ttl=3600):
    key = f"tool:{tool_name}:{input_data}"
    cached = r.get(key)
    if cached:
        return cached.decode()

    result = execute_tool(tool_name, input_data)
    r.setex(key, ttl, result)
    return result
```

This works with Infinispan's RESP endpoint — start the server with `infinispan-resp.xml` to enable it.

### Multi-agent shared cache

When multiple agents share an Infinispan cluster, one agent's cached tool result benefits all others:

{% mermaid %}
flowchart LR
    A1[Agent 1] --> ISPN[Infinispan Cluster]
    A2[Agent 2] --> ISPN
    A3[Agent 3] --> ISPN
    ISPN --> T1[Weather API]
    ISPN --> T2[Search API]
    ISPN --> T3[Database]
{% endmermaid %}

Agent 1 calls the weather API for "Paris" and caches the result. When Agent 2 needs the same data, it gets a cache hit — no redundant API call.

### Requirements

1. Infinispan Server 15.0 or later.
2. An AI agent framework (LangChain, LangGraph, CrewAI, or custom).
3. For RESP protocol: start Infinispan with `infinispan-resp.xml` configuration.

### Further reading

* [Using the Java Hot Rod Client](https://infinispan.org/docs/stable/titles/hotrod_java/hotrod_java.html)
* [Configuring Expiration](https://infinispan.org/docs/stable/titles/configuring/configuring.html)
* [Using Redis Clients with Infinispan](https://infinispan.org/docs/stable/titles/resp/resp-endpoint.html)
* [Near Caching with Hot Rod](https://infinispan.org/docs/stable/titles/hotrod_java/hotrod_java.html#near_caching)
