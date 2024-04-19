# PostgreSQL 12 with TDE

## Usage

### Backup & Restore

```bash
# full backup
docker-compose exec postgres bash
$ pgbackrest --stanza=main --log-level-console=info --type=full backup

# incremental backup
$ pgbackrest --stanza=main --log-level-console=info --type=incr backup

# list backup records
$ pgbackrest --stanza=main --log-level-console=info info
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
```

### Development

```bash
docker-compose up -d --build --force-recreate
```
