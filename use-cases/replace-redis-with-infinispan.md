---
layout: use-case-single
title: Replace Redis with Infinispan
---

## Replace Redis with Infinispan

### Why ?
Redis is a very popular in-memory database with a huge number of clients available in many languages. However it has a number of limitations:

* Redis is *single-threaded*, so performance is limited by that of a single core.
* Redis is *not open-source*, but source-available, so that limits what you can do with it.
* Redis transactions *do not work* in clustered mode.
* Redis databases share a single configuration and *do not work* in clustered mode.
* Redis expiration is configured only at the client level.
* Redis authentication is very simple and does not integrate with external Identity Providers (IdPs), such as OAuth2, LDAP, etc.
* Redis geographical replication is only available in the *non-free* Enterprise product.
* Redis' official Kubernetes Operator is only available in the *non-free* Enterprise product.

Infinispan is also an in-memory database which does not have any of the above limitations, and offers even more advanced features.
Infinispan understands the RESP3 protocol used by Redis, so you can connect to it with any compatible Redis client without changing any configuration.

### Requirements

1. An application which uses a Redis client for caching/storage.
2. Infinispan Server.

### Instructions

Start the Infinispan Server image using the `infinispan-resp.xml` configuration.

```shell
docker run -p 11222:11222 -p 6379:6379 quay.io/infinispan/server -c infinispan-resp.xml
```

Now you can connect to the server using your Redis clients as you normally would. 

```shell
$ redis-cli
127.0.0.1:6379> set k1 v1
OK
127.0.0.1:6379> get k1
"v1"
127.0.0.1:6379> del k1
(integer) 1
127.0.0.1:6379> exists k1
(integer) 0
127.0.0.1:6379> incr counter
(integer) 1
127.0.0.1:6379> decr counter
(integer) 0
```

The server listens on two ports:

* `6379` the default Redis port with no authentication enabled. 
* `11222` the default Infinispan server port with automatically generated username and password which are printed on startup. Connect to this with a browser to access the Infinispan administration console.

### Further reading

[Using Redis clients with Infinispan](https://infinispan.org/docs/stable/titles/resp/resp-endpoint.html)
