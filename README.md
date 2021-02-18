# Yose
Simple JSON DB using psql, jsonb, ruby

# setup PG

create database 'yose'

```
% createdb yose
```

or use existing database, 

```
% export YOSE_DATABASE_URL=existing_database
```
```
% export DATABASE_URL=existing_database
```

searching order:
```
url = ENV['YOSE_DATABASE_URL'] || ENV['DATABASE_URL'] || 'postgres:///yose'
```