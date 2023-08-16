# cossacklabs go-translator-demo

### Pre requirements

    go version go1.18.0 or higher 
    docker version 19.03.8
    swagg # for swagger generatetion

### Swagger

Swagger is automatically generated from comments in source code using `swag`. To install `swag` locally:

```
go get -u github.com/swaggo/swag/cmd/swag

# 1.18 or newer
go install github.com/swaggo/swag/cmd/swag@latest
```

To regenerate swagger docs, execute:

```
swag init
```
