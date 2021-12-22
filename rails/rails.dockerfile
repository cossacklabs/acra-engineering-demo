FROM ruby:2.7-alpine as build

# Product version
ARG DOCKER_IMAGE_VERSION
ENV DOCKER_IMAGE_VERSION ${DOCKER_IMAGE_VERSION:-0.0.0}
ARG RUBYGEMS_VERSION
# As suggested in docs https://github.com/rubygems/rubygems.org/blob/master/CONTRIBUTING.md#environment-linux---debianubuntu
ENV RUBYGEMS_VERSION ${RUBYGEMS_VERSION:-3.1.5}
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
    org.label-schema.name="AcraEngineeringDemo - rails - rubygems" \
    org.label-schema.description="AcraEngineeringDemo demonstrates features of main components of Acra Suite" \
    org.label-schema.version=$DOCKER_IMAGE_VERSION \
    org.label-schema.vcs-url=$VCS_URL \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.build-date=$BUILD_DATE \
    com.cossacklabs.product.name="acra-engdemo" \
    com.cossacklabs.product.version=$DOCKER_IMAGE_VERSION \
    com.cossacklabs.product.vcs-ref=$VCS_REF \
    com.cossacklabs.product.vcs-branch=$VCS_BRANCH \
    com.cossacklabs.product.component="acra-engdemo-rails-rubygems" \
    com.cossacklabs.docker.container.build-date=$BUILD_DATE \
    com.cossacklabs.docker.container.type="product"

EXPOSE 3000

VOLUME /app.acrakeys

RUN apk add --no-cache \
  nodejs \
  postgresql-dev \
  ca-certificates \
  build-base \
  bash \
  linux-headers \
  zlib-dev \
  tzdata \
  git \
  openssl-dev \
  && rm -rf /var/cache/apk/*

# TODO : remove when themis will fully support alpine
RUN echo -e '#!/bin/sh\n\nexit 0\n' > /usr/sbin/ldconfig
RUN chmod +x /usr/sbin/ldconfig

RUN cd /root && git clone https://github.com/cossacklabs/themis.git
RUN cd /root/themis && git checkout 0.10.0 && make && make install

RUN mkdir -p /app

WORKDIR /app

RUN git clone $VCS_URL /app \
    && cd /app \
    && git checkout $VCS_REF

RUN mkdir -p /app/config /app/log/

RUN gem update --system $RUBYGEMS_VERSION

RUN mv /app/config/database.yml.example /app/config/database.yml


RUN bundle config set --local without 'test' && \
  bundle install --jobs 20 --retry 5

RUN RAILS_ENV=production RAILS_GROUPS=assets SECRET_KEY_BASE=1234 bin/rails assets:precompile

RUN bundle config set --local without 'test' && \
  bundle clean --force


FROM ruby:2.7-alpine

ARG RUBYGEMS_VERSION

RUN apk add --no-cache \
  libpq \
  ca-certificates \
  bash \
  tzdata \
  xz-libs \
  openssl \
  postgresql-dev \
  postgresql-client \
  && rm -rf /var/cache/apk/*

RUN gem update --system $RUBYGEMS_VERSION

RUN mkdir -p /app
WORKDIR /app

RUN mkdir /ssl
COPY ./_common/ssl/acra-client/acra-client.crt /app/ssl/acra-client.crt
COPY ./_common/ssl/acra-client/acra-client.key /app/ssl/acra-client.key
COPY ./_common/ssl/ca/ca.crt /app/ssl/root.crt

RUN chmod 0600 -R /app/ssl/

RUN ls -la /app/ssl/
RUN cd /app/ssl/ && pwd
RUN cat /app/ssl/acra-client.crt
RUN cat /app/ssl/acra-client.key

COPY --from=build /usr/local/bundle/ /usr/local/bundle/
COPY --from=build /app/ /app/
COPY --from=build /usr/lib/libthemis.so /usr/lib/libthemis.so
COPY --from=build /usr/lib/libsoter.so /usr/lib/libsoter.so

EXPOSE 3000

COPY ./rails/entry.sh /app/docker/
RUN chmod +x /app/docker/entry.sh
ENTRYPOINT ["/app/docker/entry.sh"]