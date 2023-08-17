# cossacklabs go-translator-demo

### Pre requirements

    go version go1.18.0 or higher 
    docker version 19.03.8
    swagg # for swagger generation

### How to run?

Make sure you install all required dependencies and set up project and env variables.

```
ADDRESS=0.0.0.0:8008;
SWAGGER_HOST=0.0.0.0:8008;

ACRA_TRANSLATOR_URL=https://localhost:9595;

# requeied for connection to AcraTranslator
TLS_CLIENT_CA_PATH=<path to ca.crt>
TLS_CLIENT_CERT_PATH=<path to client.crt>
# requeied for connection to AcraTranslator
TLS_CLIENT_KEY_PATH=<path to client.key>

MONGODB_CONNECTION_URL=mongodb://root:password@localhost:27017/demo?authSource=admin;
```

### Swagger

Swagger is automatically generated from comments in source code using `swag`. To install `swag` locally:

```
go get -u github.com/swaggo/swag/cmd/swag
go install github.com/swaggo/swag/cmd/swag@v1.8.12
```

To regenerate swagger docs, execute:

```
swag init
```
