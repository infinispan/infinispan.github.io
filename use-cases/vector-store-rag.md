---
layout: use-case-single
title: Vector Store for RAG
---

## Vector Store for RAG

### Why?

Large Language Models are powerful, but they can hallucinate and lack knowledge of your private data.
**Retrieval-Augmented Generation (RAG)** solves this by retrieving relevant documents from a vector store
and injecting them into the LLM prompt as context.

Infinispan is an excellent vector store for RAG because:

* **Distributed vector indexes** scale across your cluster — no single-node bottleneck.
* **kNN similarity search** finds the most relevant document chunks in sub-millisecond time.
* **In-memory speed** — embeddings are stored in memory for the fastest possible retrieval.
* **Combined with full-text search** — Infinispan's Ickle query language supports both vector similarity and traditional full-text search in the same query, enabling hybrid search.
* **Persistence** — optionally persist your embeddings to disk so you don't need to re-index after restarts.

RAG with Infinispan works in two phases:

**Phase 1: Ingestion** — split your documents into chunks, compute embeddings, and store them in Infinispan.

{% mermaid %}
flowchart LR
    A[Documents] --> B[Chunk / Split]
    B --> C[Embedding Model]
    C --> D[Infinispan Vector Store]
{% endmermaid %}

**Phase 2: Retrieval & Generation** — embed the user's question, search Infinispan for similar chunks, and pass them to the LLM.

{% mermaid %}
sequenceDiagram
    participant User
    participant App as Application
    participant Embed as Embedding Model
    participant ISPN as Infinispan
    participant LLM as LLM

    User->>App: Ask a question
    App->>Embed: Embed the question
    Embed-->>App: Question embedding
    App->>ISPN: kNN search (top-k similar chunks)
    ISPN-->>App: Relevant document chunks
    App->>LLM: Question + retrieved context
    LLM-->>App: Grounded answer
    App-->>User: Response
{% endmermaid %}

### Quarkus + LangChain4j

Add the dependencies:

```xml
<dependency>
    <groupId>io.quarkiverse.langchain4j</groupId>
    <artifactId>quarkus-langchain4j-infinispan</artifactId>
</dependency>
```

Configure in `application.properties`:

```properties
quarkus.langchain4j.infinispan.dimension=384
quarkus.langchain4j.infinispan.cache-name=document-embeddings
quarkus.langchain4j.infinispan.similarity=COSINE
quarkus.langchain4j.infinispan.create-cache=true

quarkus.infinispan-client.hosts=localhost:11222
quarkus.infinispan-client.username=admin
quarkus.infinispan-client.password=password
```

Ingest documents and build a RAG pipeline:

```java
@ApplicationScoped
public class DocumentIngestor {

    @Inject
    EmbeddingStore<TextSegment> embeddingStore;

    @Inject
    EmbeddingModel embeddingModel;

    public void ingest(List<Document> documents) {
        EmbeddingStoreIngestor ingestor = EmbeddingStoreIngestor.builder()
            .embeddingStore(embeddingStore)
            .embeddingModel(embeddingModel)
            .documentSplitter(DocumentSplitters.recursive(500, 50))
            .build();

        ingestor.ingest(documents);
    }
}
```

Create an AI service with RAG:

```java
@RegisterAiService
public interface ProductAssistant {

    @SystemMessage("You are a product expert. Answer questions using the provided context.")
    String answer(@UserMessage String question);
}
```

The Quarkus extension automatically wires the Infinispan embedding store as the content retriever. In dev mode, Dev Services starts Infinispan automatically.

### Spring AI

Add the dependency:

```xml
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-infinispan-store</artifactId>
</dependency>
```

Configure in `application.properties`:

```properties
spring.ai.vectorstore.infinispan.store-name=document-embeddings
spring.ai.vectorstore.infinispan.similarity=COSINE
spring.ai.vectorstore.infinispan.create-store=true

infinispan.remote.server-list=localhost:11222
infinispan.remote.auth-username=admin
infinispan.remote.auth-password=password
```

Ingest documents and perform RAG:

```java
@Service
public class RagService {

    private final InfinispanVectorStore vectorStore;
    private final ChatClient chatClient;

    public RagService(InfinispanVectorStore vectorStore,
                      ChatClient.Builder chatClientBuilder) {
        this.vectorStore = vectorStore;
        this.chatClient = chatClientBuilder.build();
    }

    public void ingest(List<Document> documents) {
        vectorStore.add(documents);
    }

    public String ask(String question) {
        List<Document> context = vectorStore.similaritySearch(
            SearchRequest.builder()
                .query(question)
                .topK(5)
                .similarityThreshold(0.7)
                .build());

        String contextText = context.stream()
            .map(Document::getText)
            .collect(Collectors.joining("\n\n"));

        return chatClient.prompt()
            .system("Answer using the provided context:\n" + contextText)
            .user(question)
            .call()
            .content();
    }
}
```

Spring AI also supports metadata filtering on search results:

```java
List<Document> filtered = vectorStore.similaritySearch(
    SearchRequest.builder()
        .query("product specifications")
        .topK(5)
        .filterExpression("category == 'electronics' && year == 2024")
        .build());
```

### LangChain4j (standalone Java)

```java
InfinispanEmbeddingStore embeddingStore = InfinispanEmbeddingStore.builder()
    .cacheName("document-embeddings")
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

// Ingest documents
EmbeddingStoreIngestor ingestor = EmbeddingStoreIngestor.builder()
    .embeddingStore(embeddingStore)
    .embeddingModel(embeddingModel)
    .documentSplitter(DocumentSplitters.recursive(500, 50))
    .build();

ingestor.ingest(FileSystemDocumentLoader.loadDocuments("/path/to/docs"));

// Build RAG-powered assistant
EmbeddingStoreContentRetriever retriever = EmbeddingStoreContentRetriever.builder()
    .embeddingStore(embeddingStore)
    .embeddingModel(embeddingModel)
    .maxResults(5)
    .minScore(0.7)
    .build();

interface Assistant {
    String chat(String userMessage);
}

Assistant assistant = AiServices.builder(Assistant.class)
    .chatModel(chatModel)
    .contentRetriever(retriever)
    .build();

String answer = assistant.chat("What are the product specifications?");
```

### LangChain Python

```bash
pip install langchain-community langchain-huggingface
```

```python
from langchain_community.vectorstores import InfinispanVS
from langchain_huggingface import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chains import RetrievalQA

embeddings = HuggingFaceEmbeddings(
    model_name="sentence-transformers/all-MiniLM-L12-v2"
)

# Split documents
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=500, chunk_overlap=50
)
chunks = text_splitter.split_documents(documents)

# Store in Infinispan
vectorstore = InfinispanVS.from_documents(
    chunks,
    embedding=embeddings,
    auto_config=True
)

# Build RAG chain
retriever = vectorstore.as_retriever(
    search_kwargs={"k": 5}
)

qa_chain = RetrievalQA.from_chain_type(
    llm=llm,
    retriever=retriever,
    return_source_documents=True
)

result = qa_chain.invoke({"query": "What are the product specs?"})
print(result["result"])
```

### Requirements

1. Infinispan Server 15.0 or later.
2. An embedding model (local or API-based).
3. An LLM provider (OpenAI, Ollama, etc.).
4. Documents to index (PDF, text, HTML, etc.).

### Further reading

* [Infinispan LangChain Demo](https://github.com/infinispan-demos/infinispan-langchain-demo)
* [LangChain4j Infinispan Embedding Store](https://docs.langchain4j.dev/integrations/embedding-stores/infinispan)
* [Quarkus LangChain4j RAG with Infinispan](https://docs.quarkiverse.io/quarkus-langchain4j/dev/rag-infinispan-store.html)
* [LangChain Python InfinispanVS](https://python.langchain.com/docs/integrations/vectorstores/infinispanvs)
* [Spring AI Infinispan Vector Store](https://docs.spring.io/spring-ai/reference/api/vectordbs/infinispan.html)
* [Infinispan Vector Search Documentation](https://infinispan.org/docs/stable/titles/query/query.html)
