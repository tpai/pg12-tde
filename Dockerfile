FROM postgres:13-alpine

RUN su - postgres && apk update && apk add pgbackrest
