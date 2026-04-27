---
layout: use-case-single
title: MCP Server for AI Agents
---

## MCP Server for AI Agents

### Why?

The [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) is an open standard that lets AI assistants
and agents connect to external tools and data sources. Instead of writing custom integration code,
AI applications discover and call tools through a standardized protocol.

Infinispan ships a built-in MCP server that exposes cache operations as MCP tools. This means AI agents
like Claude, GitHub Copilot, or custom LLM-powered applications can directly:

* **Read and write cache entries** — store and retrieve data without writing any Infinispan client code.
* **Query and search** — run Ickle queries and vector similarity searches through natural language.
* **Manage caches** — create, configure, and inspect caches as part of an agentic workflow.
* **Access cluster state** — check cluster health, member nodes, and cache statistics.

### How it works

{% mermaid %}
sequenceDiagram
    participant User as User / IDE
    participant LLM as LLM (Claude, GPT, ...)
    participant MCP as Infinispan MCP Server
    participant ISPN as Infinispan Cluster

    User->>LLM: "What's in the sessions cache?"
    LLM->>MCP: call tool: cache_entries("sessions")
    MCP->>ISPN: GET /rest/v2/caches/sessions?action=entries
    ISPN-->>MCP: entries JSON
    MCP-->>LLM: formatted entries
    LLM-->>User: "The sessions cache has 42 entries..."

    User->>LLM: "Store user preference"
    LLM->>MCP: call tool: cache_put("prefs", "user-1", {...})
    MCP->>ISPN: PUT /rest/v2/caches/prefs/user-1
    ISPN-->>MCP: 200 OK
    MCP-->>LLM: success
    LLM-->>User: "Done, stored the preference."
{% endmermaid %}

### Use cases

**AI-assisted development and debugging** — connect your IDE's AI assistant to a running Infinispan cluster.
Ask questions like "show me all sessions older than 1 hour" or "what's the hit ratio for the products cache?"
without writing queries manually.

**Autonomous agents with persistent state** — agents that need to store and retrieve structured data can
use Infinispan through MCP without any client library. The MCP protocol handles serialization, error handling,
and discovery automatically.

**Multi-agent collaboration** — multiple AI agents connected to the same Infinispan cluster can share state
through cache operations exposed via MCP, enabling coordinated workflows.

### Learn more

* [MCP Server Tutorial](https://github.com/infinispan/infinispan-simple-tutorials/tree/development/infinispan-ai/mcp-server)
* [MCP Server Documentation](https://infinispan.org/docs/stable/titles/mcp_server/mcp_server.html)
* [Model Context Protocol specification](https://modelcontextprotocol.io/)
