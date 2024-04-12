FROM ubuntu:22.04

# install curl
RUN apt update && apt install -y curl

# download source code
RUN curl -OL https://download.cybertec-postgresql.com/postgresql-12.3_TDE_1.0.tar.gz
RUN tar xvfz postgresql-12.3_TDE_1.0.tar.gz

# install required packages
RUN apt install -y build-essential libldap2-dev libperl-dev python-dev-is-python3 libreadline-dev libssl-dev bison flex

# build postgresql from source
RUN cd postgresql-12.3_TDE_1.0 && ./configure --prefix=/usr/local/pg12tde --with-openssl --with-perl --with-python --with-ldap
RUN cd postgresql-12.3_TDE_1.0 && make install
RUN cd postgresql-12.3_TDE_1.0/contrib/ && make install

# create user `postgres`
RUN adduser postgres
RUN usermod -aG sudo postgres

# create base folder
RUN mkdir -p /postgres
RUN chmod 775 /postgres
RUN chown -R postgres:postgres /postgres

USER postgres
WORKDIR /

# default env variables
ENV PG_ADMIN_PASS=postgres
ENV PATH=$PATH:/usr/local/pg12tde/bin
ENV PGDATA=/postgres
ENV PGHOST=/tmp

# initialize database
COPY init_pg.sh .

CMD ["./init_pg.sh"]
