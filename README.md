# What is this?

Acra Engineering Examples illustrate the integration
of [Acra data protection suite](https://github.com/cossacklabs/acra) into your existing application. Protecting the data
is completely transparent for the users and requires minimal changes in the infrastructure.

This collection has several example applications. Each folder contains docker-compose file, that describes key
management procedures and configurations of Acra.

| #  | Example                                                                                                                                                     | What's inside                                                                                         |
|----|-------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------|
| 1  | [Intrusion detection system, transparent encryption, PostgreSQL](https://github.com/cossacklabs/acra-poison-records-demo)                                   | Go application, transparent encryption/decryption, poison records, PostgreSQL                         |
| 2  | [SQL injection prevention, AcraCensor](https://github.com/cossacklabs/acra-censor-demo)                                                                     | OWASP Mutillidae vulnerable web application, AcraConnector, AcraServer, AcraCensor (SQL firewall)     |
| 3  | [Load balancing](https://github.com/cossacklabs/acra-balancer-demo)                                                                                         | python client application, AcraServer, HAProxy                                                        |
| 4  | [Transparent encryption, Django, PostgreSQL](https://github.com/cossacklabs/acra-engineering-demo/blob/master/django-transparent/README.md)                 | Django web application, transparent encryption/decryption, AcraServer, PostgreSQL                     |
| 5  | [Transparent encryption, TimescaleDB](https://github.com/cossacklabs/acra-engineering-demo/blob/master/timescaledb/README.md)                               | TimescaleDB, transparent encryption/decryption, AcraServer                                            |
| 6  | [Transparent encryption, Python app, MySQL, PostgreSQL](https://github.com/cossacklabs/acra-engineering-demo/blob/master/python-mysql-postgresql/README.md) | MySQL, PostgreSQL, transparent encryption/masking/tokenization, Python, AcraServer                    |
| 7  | [Client-side encryption, Django, PostgreSQL](https://github.com/cossacklabs/acra-engineering-demo/blob/master/django/README.md)                             | Django web application with client-side encryption (AcraWriter), decryption on AcraServer, PostgreSQL |
| 8  | [Client-side encryption, python app, PostgreSQL](https://github.com/cossacklabs/acra-engineering-demo/blob/master/python/README.md)                         | Simple python client application, client-side encryption, decryption on AcraServer, PostgreSQL        |
| 9  | [Client-side encryption, Ruby on Rails app, PostgreSQL](https://github.com/cossacklabs/acra-engineering-demo/blob/master/rails/README.md)                   | Ruby on Rails web application, client-side encryption, decryption on AcraServer, PostgreSQL           |
| 10 | [Transparent encryption, python app, CockroachDB](https://github.com/cossacklabs/acra-engineering-demo/blob/master/cockroachdb/README.md)                   | Simple python client application, transparent encryption/decryption on AcraServer, CockroachDB        |
| 11 | [Search in encrypted data](https://github.com/cossacklabs/acra-engineering-demo/blob/master/python-searchable/README.md)                                    | python client app, AcraServer, MySQL / PostreSQL database                                             |
| 12 | [AcraTranslator Demo](https://github.com/cossacklabs/acra-engineering-demo/blob/master/acra-translator/README.md)                                           | Go API Server, AcraTranslator, MongoDB                                                                |
| 13 | [DB Migration Demo](https://github.com/cossacklabs/acra-engineering-demo/blob/master/db-acra-migration/README.md)                                           | python client app, AcraServer, PostreSQL database                                                     |

# Overview

Integrating Acra into any application requires 3 steps:

1. **Generate cryptographic keys**. In this examples, we generate only required keys for each example (Master key, and
   data encryption keys, rarely others). Refer
   to [Key management](https://docs.cossacklabs.com/acra/security-controls/key-management/) to learn more about keys.
2. **Configure and deploy services**.
    1. **transparent encryption** for SQL databases – configure and deploy AcraServer. Configure AcraServer's behavior,
       set up TLS, connect to the database, select which fields/columns to encrypt.
    2. **encryption-as-a-service** for NoSQL databases – configure and deploy AcraTranslator. Configure AcraTranslator's
       behavior, set up TLS, select gRPC or REST API.
    3. **client-side encryption** – you can encrypt data in the client application using AcraWriter, then decrypt data
       on AcraServer or AcraTranslator.
3. **Update client-side code**.
    1. **transparent encryption** for SQL databases – just point client-side app to AcraServer instead of the database.
    2. **encryption-as-a-service** for NoSQL databases – call AcraTranslator API from client-side app and
       encrypt/decrypt fields on AcraTranslator.
    3. **client-side encryption** – integrate AcraWriter, call it to encrypt fields in the app before sending them to
       the database.

Please refer to the [Acra Data flows](https://docs.cossacklabs.com/acra/acra-in-depth/data-flow/) for more detailed
description and schemes.

---

# Further steps

Let us know if you have any questions by dropping an email to [dev@cossacklabs.com](mailto:dev@cossacklabs.com).

1. [Acra website](https://cossacklabs.com/acra/) – learn about all Acra features, defense in depth, how it's better
   than "just TLS" and available licenses.
2. [Acra Community Edition](https://github.com/cossacklabs/acra) – Acra Community Edition repository.
3. [Acra docs](https://docs.cossacklabs.com/acra/what-is-acra/) – all Acra docs and guides.

# Need help?

Need help in configuring Acra? Read more
about [support options and Acra Enterprise Edition](https://www.cossacklabs.com/acra/#pricing).
