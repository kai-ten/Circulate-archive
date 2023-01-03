# https://www.cockroachlabs.com/docs/v22.2/schema-design-schema.html
# In prod, adjust to follow best practices

## Currently cannot create Database from CDB Serverless afaik. may be able to with an SDK
# CREATE DATABASE IF NOT EXISTS Circulate;
USE Circulate;

CREATE SCHEMA cs;
