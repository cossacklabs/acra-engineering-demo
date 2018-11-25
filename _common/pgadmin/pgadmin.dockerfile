FROM dpage/pgadmin4:3.5

RUN apk update && apk add sqlite

RUN rm -f /entrypoint.sh
ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
