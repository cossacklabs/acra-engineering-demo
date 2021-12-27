FROM alpine:3.15.0

# Fix CVE-2019-5021
RUN echo 'root:!' | chpasswd -e

RUN apk --update add bash postgresql postgresql-client \
    && rm -rf /var/cache/apk/*

COPY ./timescaledb/scripts/entry.sh /scripts/
COPY ./timescaledb/scripts/db_init.sh /scripts/
COPY ./timescaledb/scripts/db_fill.sh /scripts/
COPY ./timescaledb/scripts/db_add_value_daemon.sh /scripts/
COPY ./_common/ssl/ca/ca.crt /scripts/
COPY ./_common/ssl/acra-client/acra-client.crt /scripts/
COPY ./_common/ssl/acra-client/acra-client.key /scripts/

RUN chmod +x /scripts/*.sh
RUN chmod 0400 /scripts/*.key

ENTRYPOINT /scripts/entry.sh
