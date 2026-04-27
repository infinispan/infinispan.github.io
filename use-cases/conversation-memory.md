---
layout: use-case-single
title: Conversation Memory Store
---

## Conversation Memory Store

### Why?

Multi-turn AI applications — chatbots, copilots, customer support agents — need to remember conversation history.
Without persistent memory, every interaction starts from scratch and the LLM loses context.

Storing conversation memory in Infinispan provides:

* **Persistence across restarts** — conversations survive application redeployments and crashes.
* **Horizontal scalability** — any application instance can access any user's conversation history.
* **TTL-based cleanup** — old conversations are automatically evicted, no manual garbage collection needed.
* **Cross-site replication** — global applications can replicate conversation state across data centers.
* **Sub-millisecond access** — in-memory storage means loading conversation history adds negligible latency.
* **Flexible storage** — store conversations as JSON, Protobuf, or plain text with Infinispan's encoding support.

{% mermaid %}
sequenceDiagram
    participant User
    participant App as Application
    participant ISPN as Infinispan
    participant LLM as LLM

    User->>App: Send message
    App->>ISPN: Load conversation history (session ID)
    ISPN-->>App: Previous messages
    App->>LLM: System prompt + history + new message
    LLM-->>App: Response
    App->>ISPN: Store updated conversation
    App-->>User: Response
{% endmermaid %}

### Quarkus + LangChain4j

Add the Infinispan client dependency:

```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-infinispan-client</artifactId>
</dependency>
```

Configure in `application.properties`:

```properties
quarkus.infinispan-client.hosts=localhost:11222
quarkus.infinispan-client.username=admin
quarkus.infinispan-client.password=password
```

Implement a `ChatMemoryStore` backed by Infinispan:

```java
@ApplicationScoped
public class InfinispanChatMemoryStore implements ChatMemoryStore {

    @Inject
    RemoteCacheManager cacheManager;

    RemoteCache<String, String> getCache() {
        return cacheManager.getCache("chat-memory");
    }

    @Override
    public List<ChatMessage> getMessages(Object memoryId) {
        String json = getCache().get(memoryId.toString());
        return json == null ? List.of()
            : ChatMessageDeserializer.messagesFromJson(json);
    }

    @Override
    public void updateMessages(Object memoryId, List<ChatMessage> messages) {
        getCache().put(memoryId.toString(),
            ChatMessageSerializer.messagesToJson(messages),
            24, TimeUnit.HOURS);
    }

    @Override
    public void deleteMessages(Object memoryId) {
        getCache().remove(memoryId.toString());
    }
}
```

The 24-hour TTL means inactive conversations are automatically cleaned up. Wire it into your AI service:

```java
@RegisterAiService(chatMemoryProviderSupplier = RegisterAiService.BeanChatMemoryProviderSupplier.class)
public interface CustomerSupportAgent {

    @SystemMessage("You are a helpful customer support agent.")
    String chat(@MemoryId String sessionId, @UserMessage String message);
}
```

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

Implement a `ChatMemory` backed by Infinispan:

```java
@Service
public class InfinispanChatMemory implements ChatMemory {

    private final RemoteCache<String, String> cache;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public InfinispanChatMemory(RemoteCacheManager cacheManager) {
        this.cache = cacheManager.getCache("chat-memory");
    }

    @Override
    public void add(String conversationId, List<Message> messages) {
        List<Message> existing = get(conversationId, Integer.MAX_VALUE);
        existing.addAll(messages);
        cache.put(conversationId, serialize(existing), 24, TimeUnit.HOURS);
    }

    @Override
    public List<Message> get(String conversationId, int lastN) {
        String json = cache.get(conversationId);
        if (json == null) return new ArrayList<>();
        List<Message> messages = deserialize(json);
        if (messages.size() <= lastN) return messages;
        return new ArrayList<>(messages.subList(messages.size() - lastN, messages.size()));
    }

    @Override
    public void clear(String conversationId) {
        cache.remove(conversationId);
    }
}
```

Use it with a `ChatClient`:

```java
@RestController
public class ChatController {

    private final ChatClient chatClient;

    public ChatController(ChatClient.Builder builder,
                          InfinispanChatMemory chatMemory) {
        this.chatClient = builder
            .defaultAdvisors(new MessageChatMemoryAdvisor(chatMemory))
            .build();
    }

    @PostMapping("/chat")
    public String chat(@RequestParam String sessionId,
                       @RequestParam String message) {
        return chatClient.prompt()
            .user(message)
            .advisors(a -> a.param("chat_memory_conversation_id", sessionId))
            .call()
            .content();
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

ChatMemoryStore memoryStore = new InfinispanChatMemoryStore(cacheManager);

ChatMemory chatMemory = MessageWindowChatMemory.builder()
    .id("user-session-123")
    .maxMessages(20)
    .chatMemoryStore(memoryStore)
    .build();

Assistant assistant = AiServices.builder(Assistant.class)
    .chatModel(chatModel)
    .chatMemory(chatMemory)
    .build();

assistant.chat("Hi, I need help with my order");
assistant.chat("The order number is 12345");
// The assistant remembers the previous message
```

### LangChain Python

Use Infinispan via the RESP (Redis) protocol with LangChain's Redis-based memory:

```bash
pip install langchain-community redis
```

```python
from langchain.memory import ConversationBufferMemory
from langchain_community.chat_message_histories import RedisChatMessageHistory

# Connect to Infinispan's RESP endpoint
message_history = RedisChatMessageHistory(
    session_id="user-session-123",
    url="redis://localhost:6379"
)

memory = ConversationBufferMemory(
    chat_memory=message_history,
    return_messages=True
)

# Use in a conversation chain
chain = ConversationChain(
    llm=llm,
    memory=memory
)

chain.predict(input="Hi, I need help with my order")
chain.predict(input="The order number is 12345")
# Full conversation history is maintained in Infinispan
```

Start Infinispan with RESP support:

```shell
docker run -p 11222:11222 -p 6379:6379 quay.io/infinispan/server -c infinispan-resp.xml
```

### Cache configuration for conversations

Create a cache optimized for conversation storage with TTL and memory limits:

```json
{
    "distributed-cache": {
        "encoding": {
            "media-type": "application/x-protostream"
        },
        "expiration": {
            "lifespan": "86400000"
        },
        "memory": {
            "max-count": "100000"
        }
    }
}
```

This configuration:
* Distributes conversations across cluster nodes for scalability.
* Expires conversations after 24 hours of inactivity.
* Limits the cache to 100,000 sessions to control memory usage.

### Requirements

1. Infinispan Server 15.0 or later.
2. For RESP protocol: start Infinispan with `infinispan-resp.xml` configuration.
3. An LLM provider (OpenAI, Ollama, etc.).

### Further reading

* [Using the Java Hot Rod Client](https://infinispan.org/docs/stable/titles/hotrod_java/hotrod_java.html)
* [Configuring Expiration](https://infinispan.org/docs/stable/titles/configuring/configuring.html)
* [Using Redis Clients with Infinispan](https://infinispan.org/docs/stable/titles/resp/resp-endpoint.html)
* [Cross-Site Replication](https://infinispan.org/docs/stable/titles/xsite/xsite.html)
