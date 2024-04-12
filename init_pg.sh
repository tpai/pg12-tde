#!/usr/bin/env bash

if [[ -n "$PG_ENCRYPT_KEY" ]]; then
  echo "echo \"$PG_ENCRYPT_KEY\"" > $HOME/key.sh
  chmod +x $HOME/key.sh
fi

if [ -f $HOME/key.sh ]; then
  # initialize database
  initdb -K $HOME/key.sh

  # empty logfile
  > /postgres/logfile

  # start postgres server
  pg_ctl -K $HOME/key.sh -l /postgres/logfile start

  # wait until server is ready
  until pg_isready -U postgres
  do
    echo "Waiting for PostgreSQL to start..."
    sleep 1
  done

  # check if flag does not exist
  if [ ! -f $PGDATA/PG_INIT ]; then

    # run initial SQL script
    if [ -f /initdb.sql ]; then
      psql -U postgres < /initdb.sql
    fi

    # reset admin password
    psql -U postgres -c "ALTER USER \"postgres\" WITH PASSWORD '$PG_ADMIN_PASS';"

    # edit pg_hba
    echo "host all all all md5" >> $PGDATA/pg_hba.conf

    # replace postgresql.conf
    rm $PGDATA/postgresql.conf
    cp /postgresql.conf $PGDATA/postgresql.conf

    # restart postgres server
    pg_ctl -K $HOME/key.sh -l $PGDATA/logfile restart

    # create flag
    touch $PGDATA/PG_INIT
  fi

  # watch log
  tail -f /postgres/logfile
else
  echo "Error: /key.sh does not exist."
fi
