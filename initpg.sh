#!/usr/bin/env bash

if [[ -n "$PG_ENCRYPTION_KEY" ]]; then
  echo "echo \"$PG_ENCRYPTION_KEY\"" > $PGCONFIG/key.sh
  chmod +x $PGCONFIG/key.sh
fi

if [ -f $PGCONFIG/key.sh ]; then
  # initialize database
  initdb -K $PGCONFIG/key.sh

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

  # check if PG_INIT flag is existed
  if [ "$1" == "primary" ] && [ ! -f $PGDATA/PG_INIT ]; then

    # run initial SQL script
    if [ -f $PGCONFIG/initdb.sql ]; then
      psql -U postgres < $PGCONFIG/initdb.sql
    fi

    # enable pg_stat_statements extension
    psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
    # reset admin password
    psql -U postgres -c "ALTER USER \"postgres\" WITH PASSWORD '$PG_POSTGRES_PASSWORD';"

    # edit pg_hba
    echo "host all all all md5" >> $PGDATA/pg_hba.conf

    # replace with customized postgresql.conf
    rm $PGDATA/postgresql.conf
    cp $PGCONFIG/postgresql.conf $PGDATA/postgresql.conf

    # restart postgres server
    pg_ctl -K $PGCONFIG/key.sh -l $PGDATA/logfile restart

    # create backup stanza
    pgbackrest --stanza=main --log-level-console=info stanza-create

    # create flag
    touch $PGDATA/PG_INIT
  fi
  # validate backup configuration
  pgbackrest --stanza=main --log-level-console=info check

  # watch log
  tail -f $PGDATA/logfile
else
  echo "Error: /key.sh does not exist."
fi
