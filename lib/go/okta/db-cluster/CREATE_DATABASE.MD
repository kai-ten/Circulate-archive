# Create Database Objects

Once you have cockroach installed on your machine...

To create the database for the first time:
`cockroach sql --url "postgresql://kai@bamboo-scylla-7752.7tt.cockroachlabs.cloud:26257/Circulate?sslmode=verify-full"`

```
cockroach sql \
--url "postgresql://kai:-DH0WZpUL6PajyBSa9oqLg@bamboo-scylla-7752.7tt.cockroachlabs.cloud:26257/Circulate?sslmode=verify-full"
-f db-cluster/database/circulate_init.sql
```


