---
layout: use-case-single
title: Replace Memcached with Infinispan
---

## Replace Memcached with Infinispan

### Why ?
Memcached is a popular in-memory cache. However it has a number of limitations:

* Memcached does not implement persistence, so restarting a server means that all data is lost.
* Memcached does not implement transactions.
* Memcached does not implement geographical replication.

Infinispan is an in-memory database which does not have any of the above limitations, and offers even more advanced features.
Infinispan understands both the text and binary protocols implemented by Memcached, so you can connect to it with any compatible Memcached client without changing any configuration.

### Requirements

1. An application which uses a Memcached client for caching.
2. Infinispan Server.

### Instructions


```shell
docker run -p 11222:11222 -p 11211:11211 quay.io/infinispan/server -c infinispan-memcached.xml
```

Now you can connect to the server using your Memcached clients as you normally would. 

```shell
$ telnet 127.0.0.1 11211
Trying 127.0.0.1...
Connected to 127.0.0.1.
Escape character is '^]'.
set foo 0 300 3
bar
STORED
get foo
VALUE foo 0 3
bar
END
delete foo
DELETED
flush_all
OK

```

The server listens on two ports:

* `11211` the default Memcached port with no authentication enabled. 
* `11222` the default Infinispan server port with automatically generated username and password which are printed on startup. Connect to this with a browser to access the Infinispan administration console.

### Further reading

[Using Memcached clients with Infinispan](https://infinispan.org/docs/stable/titles/memcached/memcached.html)
