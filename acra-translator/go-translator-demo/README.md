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

# required for connection to AcraTranslator
TLS_CLIENT_CA_PATH=<path to ca.crt>
TLS_CLIENT_CERT_PATH=<path to client.crt>
# required for connection to AcraTranslator
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

### Project structure

- **acra-translator** - represent the package that implements integration with
  AcraTranslator.
- [`Client`](./acra-translator/client.go) is the main
  AcraTranslator interface, where `/acra-translator/http` - is the HTTP implementation of `Client` interface;
- **docker** - contains the project Dockerfile;
- **handlers** - implementation of HTTP handlers of Go Server, brings together communication with AcraTranslator and
  MongoDB;
- **models** - represent main project entities. Currently, only [`User`](./models/user.go)
- **pkg** - contains the main technical code, required for Go Server;
- **repositories** - implements DB access layer with MongoDB;
- **swagger** - contains generated swagger docs, that available on `http://$SWAGGER_HOST:8008/swagger/index.html#/`
