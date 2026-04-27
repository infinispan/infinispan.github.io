---
layout: use-case-single
title: Semantic Caching for LLMs
---

## Semantic Caching for LLMs

### Why?

LLM API calls are expensive and slow. A single GPT-4 request can cost $0.01-$0.10 and take 1-5 seconds.
Traditional caching only helps when the exact same prompt is repeated, which rarely happens in practice.

**Semantic caching** solves this by matching prompts by *meaning* instead of exact string match.
When a user asks "What is the capital of France?" and another asks "Tell me France's capital city",
a semantic cache recognizes these are the same question and returns the cached response instantly.

Infinispan's distributed vector indexes and kNN search make it an ideal semantic cache:

* **Vector similarity search** finds cached responses that are semantically close to the new prompt.
* **TTL and expiration** keep the cache fresh — stale answers are automatically evicted.
* **Distributed and replicated** — the cache scales horizontally across your cluster.
* **Sub-millisecond lookups** — in-memory vector search is orders of magnitude faster than calling an LLM.

{% mermaid %}
sequenceDiagram
    participant App as Application
    participant Embed as Embedding Model
    participant ISPN as Infinispan
    participant LLM as LLM API

    App->>Embed: Embed user prompt
    Embed-->>App: Prompt embedding
    App->>ISPN: kNN search (find similar cached prompts)
    alt cache hit (similarity > threshold)
        ISPN-->>App: Return cached response
    else cache miss
        ISPN-->>App: No match found
        App->>LLM: Send prompt to LLM
        LLM-->>App: LLM response
        App->>ISPN: Store embedding + response
    end
{% endmermaid %}

### How much can you save?

Assuming `L` is the average LLM call latency and `C` is the cost per call:

* **Cache hit**: ~2ms (embedding + vector search). Cost: $0.
* **Cache miss**: `L` + 2ms (full LLM call + cache storage).

With a 50% hit rate on a $0.03/call model handling 10,000 requests/day, semantic caching saves **~$150/day** and cuts average latency in half.

### Quarkus + LangChain4j

Add the Infinispan embedding store extension:

```xml
<dependency>
    <groupId>io.quarkiverse.langchain4j</groupId>
    <artifactId>quarkus-langchain4j-infinispan</artifactId>
</dependency>
```

Configure the embedding store in `application.properties`:

```properties
quarkus.langchain4j.infinispan.dimension=384
quarkus.langchain4j.infinispan.cache-name=semantic-cache
quarkus.langchain4j.infinispan.similarity=COSINE

quarkus.infinispan-client.hosts=localhost:11222
quarkus.infinispan-client.username=admin
quarkus.infinispan-client.password=password
```

Implement semantic caching with CDI injection:

```java
@ApplicationScoped
public class SemanticCache {

    @Inject
    EmbeddingStore<TextSegment> embeddingStore;

    @Inject
    EmbeddingModel embeddingModel;

    private static final double SIMILARITY_THRESHOLD = 0.95;

    public String getOrCompute(String prompt, Function<String, String> llmCall) {
        Embedding promptEmbedding = embeddingModel.embed(prompt).content();

        EmbeddingSearchResult<TextSegment> result = embeddingStore.search(
            EmbeddingSearchRequest.builder()
                .queryEmbedding(promptEmbedding)
                .maxResults(1)
                .minScore(SIMILARITY_THRESHOLD)
                .build());

        if (!result.matches().isEmpty()) {
            return result.matches().getFirst().embedded().text();
        }

        String response = llmCall.apply(prompt);
        embeddingStore.add(promptEmbedding, TextSegment.from(response));
        return response;
    }
}
```

In dev mode, Quarkus Dev Services starts an Infinispan container automatically — no manual setup needed.

### Spring AI

Add the Spring AI Infinispan vector store starter:

```xml
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-infinispan-store</artifactId>
</dependency>
```

Configure in `application.properties`:

```properties
spring.ai.vectorstore.infinispan.store-name=semantic-cache
spring.ai.vectorstore.infinispan.similarity=COSINE
spring.ai.vectorstore.infinispan.create-store=true

infinispan.remote.server-list=localhost:11222
infinispan.remote.auth-username=admin
infinispan.remote.auth-password=password
```

Implement semantic caching with the auto-configured `InfinispanVectorStore`:

```java
@Service
public class SemanticCache {

    private final InfinispanVectorStore vectorStore;

    private static final double SIMILARITY_THRESHOLD = 0.95;

    public SemanticCache(InfinispanVectorStore vectorStore) {
        this.vectorStore = vectorStore;
    }

    public String getOrCompute(String prompt, Function<String, String> llmCall) {
        List<Document> results = vectorStore.similaritySearch(
            SearchRequest.builder()
                .query(prompt)
                .topK(1)
                .similarityThreshold(SIMILARITY_THRESHOLD)
                .build());

        if (!results.isEmpty()) {
            return results.getFirst().getText();
        }

        String response = llmCall.apply(prompt);
        vectorStore.add(List.of(new Document(response,
            Map.of("prompt", prompt))));
        return response;
    }
}
```

### LangChain4j (standalone Java)

Add the dependencies:

```xml
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j-infinispan</artifactId>
</dependency>
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j-embeddings-all-minilm-l6-v2-q</artifactId>
</dependency>
```

Create the embedding store and implement semantic caching:

```java
InfinispanEmbeddingStore embeddingStore = InfinispanEmbeddingStore.builder()
    .cacheName("semantic-cache")
    .dimension(384)
    .similarity("COSINE")
    .createCache(true)
    .registerSchema(true)
    .infinispanConfigBuilder(
        new ConfigurationBuilder()
            .addServer().host("localhost").port(11222)
            .security().authentication()
            .username("admin").password("password"))
    .build();

EmbeddingModel embeddingModel = new AllMiniLmL6V2QuantizedEmbeddingModel();

Embedding queryEmbedding = embeddingModel.embed("What is the capital of France?").content();

EmbeddingSearchResult<TextSegment> cached = embeddingStore.search(
    EmbeddingSearchRequest.builder()
        .queryEmbedding(queryEmbedding)
        .maxResults(1)
        .minScore(0.95)
        .build());

if (cached.matches().isEmpty()) {
    String llmResponse = chatModel.generate("What is the capital of France?");
    embeddingStore.add(queryEmbedding, TextSegment.from(llmResponse));
}
```

### LangChain Python

```bash
pip install langchain-community
```

```python
from langchain_community.vectorstores import InfinispanVS
from langchain_huggingface import HuggingFaceEmbeddings

embeddings = HuggingFaceEmbeddings(
    model_name="sentence-transformers/all-MiniLM-L12-v2"
)

cache = InfinispanVS.from_texts(
    texts=[],
    embedding=embeddings,
    auto_config=True
)

SIMILARITY_THRESHOLD = 0.95

def semantic_cache_query(prompt, llm):
    results = cache.similarity_search_with_score(prompt, k=1)

    if results and results[0][1] >= SIMILARITY_THRESHOLD:
        return results[0][0].page_content

    response = llm.invoke(prompt)
    cache.add_texts([response], metadatas=[{"prompt": prompt}])
    return response
```

### Requirements

1. Infinispan Server 15.0 or later.
2. An embedding model (local or API-based).
3. An LLM provider (OpenAI, Ollama, etc.).

### Further reading

* [LangChain4j Infinispan Embedding Store](https://docs.langchain4j.dev/integrations/embedding-stores/infinispan)
* [Quarkus LangChain4j Infinispan Extension](https://docs.quarkiverse.io/quarkus-langchain4j/dev/rag-infinispan-store.html)
* [LangChain Python InfinispanVS](https://python.langchain.com/docs/integrations/vectorstores/infinispanvs)
* [Spring AI Infinispan Vector Store](https://docs.spring.io/spring-ai/reference/api/vectordbs/infinispan.html)
* [Infinispan Vector Search Documentation](https://infinispan.org/docs/stable/titles/query/query.html)
