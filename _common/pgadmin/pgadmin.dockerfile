FROM dpage/pgadmin4:4.29

USER root

RUN apk update && apk add sqlite

RUN rm -f /entrypoint.sh
ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
