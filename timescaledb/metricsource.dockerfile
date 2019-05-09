FROM alpine:3.9

# Fix CVE-2019-5021
RUN echo 'root:!' | chpasswd -e

RUN apk --update add bash postgresql postgresql-client \
    && rm -rf /var/cache/apk/*

COPY ./scripts/entry.sh /scripts/
COPY ./scripts/db_init.sh /scripts/
COPY ./scripts/db_fill.sh /scripts/
COPY ./scripts/db_add_value_daemon.sh /scripts/

RUN chmod +x /scripts/*.sh

ENTRYPOINT /scripts/entry.sh
