ConfigurationBuilder builder = new ConfigurationBuilder();
builder.persistence().addStore(QueriesJdbcStoreConfigurationBuilder.class)
      .dialect(DatabaseType.POSTGRES)
      .shared("true")
      .keyColumns("name")
      .queriesJdbcConfigurationBuilder()
         .select("SELECT t1.name, t1.picture, t1.sex, t1.birthdate, t1.accepted_tos, t2.street, t2.city, t2.zip FROM Person t1 JOIN Address t2 ON t1.name = :name AND t2.name = :name")
         .selectAll("SELECT t1.name, t1.picture, t1.sex, t1.birthdate, t1.accepted_tos, t2.street, t2.city, t2.zip FROM Person t1 JOIN Address t2 ON t1.name = t2.name")
         .delete("DELETE FROM Person t1 WHERE t1.name = :name; DELETE FROM Address t2 where t2.name = :name")
         .deleteAll("DELETE FROM Person; DELETE FROM Address")
         .upsert("INSERT INTO Person (name,  picture, sex, birthdate, accepted_tos) VALUES (:name, :picture, :sex, :birthdate, :accepted_tos); INSERT INTO Address(name, street, city, zip) VALUES (:name, :street, :city, :zip)")
         .size("SELECT COUNT(*) FROM Person")
      .schemaJdbcConfigurationBuilder()
         .messageName("Person")
         .packageName("com.example")
         .embeddedKey(true);
