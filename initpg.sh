#!/usr/bin/env bash

set -e

if [[ -n "$POSTGRES_ENCRYPTION_KEY" ]]; then
  echo "echo \"$POSTGRES_ENCRYPTION_KEY\"" > $PGCONFIG/key.sh
  chmod +x $PGCONFIG/key.sh
fi

if [ -f $PGCONFIG/key.sh ]; then

  ## primary server initialization
  if [ "$1" == "primary" ] && [ ! -f $PGDATA/PG_INIT ]; then
    # initialize database
    initdb -K $PGCONFIG/key.sh

    # start postgres server
    pg_ctl -K $PGCONFIG/key.sh -l $PGDATA/logfile start

    # run initial SQL script
    if [ -f $INITDB/initdb.sql ]; then
      psql -U postgres < $INITDB/initdb.sql
    fi

    # enable pg_stat_statements extension
    psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
    # reset admin password
    psql -U postgres -c "ALTER USER \"postgres\" WITH PASSWORD '$POSTGRES_PASSWORD';"

    # edit pg_hba
    echo "host all all all md5" >> $PGDATA/pg_hba.conf

    # replace with customized postgresql.conf
    rm $PGDATA/postgresql.conf
    cp $PGCONFIG/postgresql.conf $PGDATA/postgresql.conf

    # create backup stanza
    pgbackrest --stanza=main --log-level-console=info stanza-create

    # stop postgres server
    pg_ctl -K $PGCONFIG/key.sh -l $PGDATA/logfile stop

    # create flag
    touch $PGDATA/PG_INIT
  fi
  # empty logfile
  > $PGDATA/logfile

  # start postgres server
  pg_ctl -K $PGCONFIG/key.sh -l $PGDATA/logfile start

  # wait until server is ready
  until pg_isready -U postgres
  do
    echo "Waiting for PostgreSQL to start..."
    sleep 1
  done

  # list backup records
  pgbackrest --stanza=main --log-level-console=info info

  # watch log
  tail -f $PGDATA/logfile
else
  echo "Error: /key.sh does not exist."
fi
