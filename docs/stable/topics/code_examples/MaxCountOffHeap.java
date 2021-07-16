ConfigurationBuilder cfg = new ConfigurationBuilder();

cfg
  .memory()
    .storage(StorageType.OFF_HEAP)
    .maxCount(500)
    .whenFull(EvictionStrategy.REMOVE)
  .build());
