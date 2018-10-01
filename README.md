# What is this?

Acra Engineering demo illustrates how to integrate Acra data protection into your existing application. In examples below we use application that stores data in PostgreSQL database, and protects data with AcraServer.

**Integrating Acra into any application contains 3 steps:**

1. **Generate storage and transport encryption keys** using AcraKeymaker. For this example we will generate one storage keypair (for encrypting and decrypting data), and two transport keypairs (for secure connection between AcraServer and AcraConnector). 
2. **Integrate AcraWriter** – the client-side library – into the client application (web or mobile app). Application calls AcraWriter to encrypt data, then sends data to the database as usual. AcraWriter uses storage public key to encrypt data.
3. **Deploy server-side infrastructure**: AcraServer and AcraConnector.  

      1. To decrypt the data, application reads data through AcraServer. AcraServer identifies application, makes sure that requests are legit, fetches data from database and returns decrypted data to the application. AcraServer is deployed as Docker container and connected to the database and AcraConnector. AcraServer has storage private key to decrypt the data, AcraServer's transport keypair and AcraConnector's public key to build protected transport connection.
      2. AcraConnector is an important transport protection between client and AcraServer. AcraConnector is deployed as Docker container into separate host, and uses own transport keypair and AcraServer's public key to build protected transport connection.
   
**For demonstration and debug purposes we have included following dashboards:**
1. AcraWebConfig allows to change configuration of AcraServer remotely (for example, ). AcraWebConfig access is protected by user login.
2. Grafana and Prometheus shows Acra activity – amount of decrypted data, number of requests, etc.

Please refer to the [Acra/Readme documentation](https://github.com/cossacklabs/acra#protecting-data-in-sql-databases-using-acrawriter-and-acraserver) for more detailed description and schemes.

# Protecting data on Django-based web site

## Installation

```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- django
```

This command downloads code of Django web site example, Acra Docker containers and PostgreSQL database, sets up environment and provides list of links for you to try.

## What's inside

```
<Description>
```

```
<Configuration details>
```

## How to integrate Acra into existing web application?

```
<Before / after>
```

# Protecting data of simple database application

## Installation

```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- python
```

This command downloads simple Python application that stores data in database, Acra Docker containers and PostgreSQL database, sets up environment and provides list of links for you to try.

## What's inside

```
<Description>
```

```
<Configuration details>
```

## How to integrate Acra into existing console application?

```
<Before / after>
```

# Further steps

```
<Links to Acra, other examples>
```
