FROM golang:1.20 as gobuilder

# Application name
ARG APP_NAME
# Product version
ARG VERSION
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
    org.label-schema.name="Golang API Server" \
    org.label-schema.description="Go Translator Demo" \
    org.label-schema.version=$VERSION \
    org.label-schema.vcs-url=$VCS_URL \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.build-date=$BUILD_DATE \
    com.cossacklabs.product.name=$APP_NAME \
    com.cossacklabs.product.version=$VERSION \
    com.cossacklabs.product.vcs-ref=$VCS_REF \
    com.cossacklabs.product.vcs-branch=$VCS_BRANCH \
    com.cossacklabs.product.component=$APP_NAME \
    com.cossacklabs.docker.container.build-date=$BUILD_DATE \
    com.cossacklabs.docker.container.type="builder"


WORKDIR /build

COPY ./ /build

ENV CGO_ENABLED=0 GOOS=linux GOOS=linux GOARCH=amd64
RUN go build -a -installsuffix cgo -ldflags="-s -w" -o ./api-server .


FROM alpine:3.9.5

# Application name
ARG APP_NAME
# Product version
ARG VERSION
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
    org.label-schema.name="Golang API" \
    org.label-schema.description="Golang API for AcraTranslator demo" \
    org.label-schema.version=$VERSION \
    org.label-schema.vcs-url=$VCS_URL \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.build-date=$BUILD_DATE \
    com.cossacklabs.product.name=$APP_NAME \
    com.cossacklabs.product.version=$VERSION \
    com.cossacklabs.product.vcs-ref=$VCS_REF \
    com.cossacklabs.product.vcs-branch=$VCS_BRANCH \
    com.cossacklabs.product.component=$APP_NAME \
    com.cossacklabs.docker.container.build-date=$BUILD_DATE \
    com.cossacklabs.docker.container.type="product"


RUN apk update && apk add ca-certificates && rm -rf /var/cache/apk/*

WORKDIR /root/
COPY --from=gobuilder /build/api-server .

CMD ["./api-server"]
