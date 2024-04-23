# PG13-TDE Stack

## Features

- Transparent Data Encryption
- MinIO storage
- PITR

## Service Endpoints

- PostgreSQL: `psql://postgres:pgadmpass@localhost:5432`
- MinIO: `http://localhost:9001` / `miniouser:miniopass`

## Demo

### Backup & Restore

```bash
# full backup
docker-compose exec postgres bash -c "
  pgbackrest --stanza=main --log-level-console=info --type=full backup"

# list backup records
docker-compose exec postgres bash -c "
  pgbackrest --stanza=main --log-level-console=info info"
stanza: main
    status: ok
    cipher: none

    db (current)
        wal archive min/max (12): 000000010000000000000001/000000010000000000000002

        full backup: 20240419-091102F
            timestamp start/stop: 2024-04-19 09:11:02 / 2024-04-19 09:11:10
            wal start/stop: 000000010000000000000002 / 000000010000000000000002
            database size: 29.9MB, database backup size: 29.9MB
            repo1: backup set size: 29.9MB, backup size: 29.9MB

# insert values
docker-compose exec postgres bash -c "
  psql -c \"CREATE TABLE random_names (id SERIAL PRIMARY KEY,name VARCHAR(50));
  INSERT INTO random_names (name) VALUES ('John Smith'), ('Emma Johnson'), ('Michael Brown');\""

# get values
docker-compose exec postgres bash -c "
  psql -c \"SELECT * FROM random_names;\""
 id |     name
----+---------------
  1 | John Smith
  2 | Emma Johnson
  3 | Michael Brown
(3 rows)

# incremental backup
docker-compose exec postgres bash -c "
  pgbackrest --stanza=main --log-level-console=info --type=incr backup"

# stop postgres server
docker-compose stop postgres

# remove flag
rm postgres-data/postmaster.pid

# point in time recovery
docker-compose run --rm -it postgres bash -c "
  pgbackrest --stanza=main --log-level-console=info --type=immediate \
    --delta --set=\"20240419-091102F\" --target-action=promote restore"

# start server
docker-compose up -d

# verify result
docker-compose exec postgres bash -c "
  psql -c \"SELECT * FROM random_names;\""
ERROR:  relation "random_names" does not exist
LINE 1: SELECT * FROM random_names;
                      ^
```

## Miscellaneous

### Development

```bash
docker-compose up -d --build --force-recreate
```

### Generate Encryption Key

```bash
openssl rand -hex 16
```
