FROM alpine:3.15.0

# Product version
ARG VERSION
ENV VERSION ${VERSION:-0.0.0}
# Link to the product repository
ARG VCS_URL
# Hash of the commit
ARG VCS_REF
# Repository branch
ARG VCS_BRANCH
# Date of the build
ARG BUILD_DATE
# Include metadata, additionally use label-schema namespace
LABEL org.label-schema.schema-version="1.0" \
    org.label-schema.vendor="Cossack Labs" \
    org.label-schema.url="https://cossacklabs.com" \
    org.label-schema.name="AcraEngineeringDemo - python" \
    org.label-schema.description="AcraEngineeringDemo demonstrates features of main components of Acra Suite" \
    org.label-schema.version=$VERSION \
    org.label-schema.vcs-url=$VCS_URL \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.build-date=$BUILD_DATE \
    com.cossacklabs.product.name="acra-engdemo" \
    com.cossacklabs.product.version=$VERSION \
    com.cossacklabs.product.vcs-ref=$VCS_REF \
    com.cossacklabs.product.vcs-branch=$VCS_BRANCH \
    com.cossacklabs.product.component="acra-engdemo-python" \
    com.cossacklabs.docker.container.build-date=$BUILD_DATE \
    com.cossacklabs.docker.container.type="product"

# Fix CVE-2019-5021
RUN echo 'root:!' | chpasswd -e

RUN apk update

RUN apk add --no-cache bash python3 py3-pip \
    mariadb-dev mariadb-client \
    postgresql-dev postgresql-client

RUN pip3 install --no-cache-dir --upgrade pip
RUN ln -s /usr/bin/python3 /usr/bin/python

RUN apk add gcc python3-dev musl-dev libxml2-dev git alpine-sdk rsync

# TODO : remove when themis will fully support alpine
RUN mkdir -p /usr/local/sbin
RUN echo -e '#!/bin/sh\n\nexit 0\n' > /usr/local/sbin/ldconfig
RUN chmod +x /usr/local/sbin/ldconfig

RUN cd /root \
    && git clone --depth 1 -b stable https://github.com/cossacklabs/themis
RUN cd /root/themis \
    && make \
    && make install \
    && make pythemis_install

RUN mkdir -p /app.requirements/requirements
COPY ./acra/examples/python/requirements.txt /app.requirements/requirements.txt
COPY ./acra/examples/python/requirements/ /app.requirements/requirements
RUN pip3 install --no-cache-dir -r /app.requirements/requirements.txt

RUN mkdir /ssl
COPY ./_common/ssl/acra-client/acra-client.crt /ssl/acra-client.crt
COPY ./_common/ssl/acra-client/acra-client.key /ssl/acra-client.key
COPY ./_common/ssl/ca/ca.crt /ssl/root.crt

RUN chmod 0600 -R /ssl/

COPY ./python/entry.sh /entry.sh
RUN chmod +x /entry.sh

VOLUME /app.acrakeys
VOLUME /app

WORKDIR /app
ENTRYPOINT ["/entry.sh"]
