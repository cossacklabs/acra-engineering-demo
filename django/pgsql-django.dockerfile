FROM postgres:11

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
    org.label-schema.name="AcraEngineeringDemo - django - postgres" \
    org.label-schema.description="AcraEngineeringDemo demonstrates features of main components of Acra Suite" \
    org.label-schema.version=$VERSION \
    org.label-schema.vcs-url=$VCS_URL \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.build-date=$BUILD_DATE \
    com.cossacklabs.product.name="acra-engdemo" \
    com.cossacklabs.product.version=$VERSION \
    com.cossacklabs.product.vcs-ref=$VCS_REF \
    com.cossacklabs.product.vcs-branch=$VCS_BRANCH \
    com.cossacklabs.product.component="acra-engdemo-django-postgres" \
    com.cossacklabs.docker.container.build-date=$BUILD_DATE \
    com.cossacklabs.docker.container.type="product"

COPY django/pgsql-django-configure.sh /docker-entrypoint-initdb.d/
