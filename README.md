# What is this?

Acra Engineering demo illustrates how to integrate Acra data protection into your existing application. In examples below we use application that stores data in PostgreSQL database, and protects data with AcraServer.

**Integrating Acra into any application contains 3 steps:**

1. **Generate storage and transport encryption keys** using AcraKeymaker. For this example we will generate one storage keypair (for encrypting and decrypting data), and two transport keypairs (for secure connection between AcraServer and AcraConnector). 
2. **Integrate AcraWriter** – the client-side library – into the client application (web or mobile app). Application calls AcraWriter to encrypt data, then sends data to the database as usual. AcraWriter uses storage public key to encrypt data.
3. **Deploy server-side infrastructure**: AcraServer and AcraConnector.  

      1. To decrypt the data, application reads data through AcraServer. AcraServer identifies application, makes sure that requests are legit, fetches data from database and returns decrypted data to the application. AcraServer is deployed as Docker container and connected to the database and AcraConnector. AcraServer has storage private key to decrypt the data, AcraServer's transport keypair and AcraConnector's public key to build protected transport connection.
      2. AcraConnector is an important transport protection between client and AcraServer. AcraConnector is deployed as Docker container into separate host, and uses own transport keypair and AcraServer's public key to build protected transport connection.
   
**For demonstration and debug purposes we have included following dashboards:**

1. AcraWebConfig allows to change configuration of AcraServer remotely (for example, disable intrusion detection). Only restricted users can access AcraWebConfig.
2. Grafana and Prometheus shows Acra activity – amount of decrypted data, number of requests, etc.
3. PostgreSQL database web dashboard shows database internals. 

Please refer to the [Acra/Readme documentation](https://github.com/cossacklabs/acra#protecting-data-in-sql-databases-using-acrawriter-and-acraserver) for more detailed description and schemes.

# Protecting data on Django-based web site

## Installation

```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- django
```

This command downloads code of Django web site example, Acra Docker containers and PostgreSQL database, sets up environment and provides list of links for you to try.

## What's inside

<p align="center"><img src="_pics/eng_demo_django.png" alt="Protecting Django web application: Acra architecture" width="530"></p>

**Client application** is the famous Django app example – the djangoproject.com web site. We took [their source code](https://github.com/cossacklabs/djangoproject.com) and integrated AcraWriter to protect blog posts. 

Blogposts are **protected**: author name, author email, blogpost content are encrypted and wrapped into AcraStruct. Plaintext fields are: blogpost ID and title.

Django app **writes** AcraStructs and **reads** decrypted posts from the PostgreSQL database through AcraConnector and AcraServer (that are transparent for the application).

From user perspective web site works as usual, however, data is protected.

### Updating etc/hosts

Please add a temporary entry to the hosts file:

```
echo 'SERVER_IP www.djangoproject.example' >> /private/etc/hosts
```

where `SERVER_IP` is IP address of the server with running Acra Engineering Demo (if you run demo on your machine, set "127.0.0.1"). Hosts update is needed because we will run protected djangoproject site locally. You can remove this line after using demo.


### Add new post

1. Log into admin cabinet [http://www.djangoproject.example:8000/admin/](http://www.djangoproject.example:8000/admin/) using user/password: admin/admin.

2. Add blog post:

```<screenshots>```

3. Open blog posts feed [http://www.djangoproject.example:8000/weblog/](http://www.djangoproject.example:8000/weblog/) and see your fresh post.

```<screenshots>```

Yay! Now let's check database content.

### Check database

1. Log into web PostgreSQL interface [http://www.djangoproject.example:8008](http://www.djangoproject.example:8008) using user/password: test/test.

```<screenshots>```

2. Find your blogpost in  ... (scheme) and download it's content.

```<screenshots>```

3. Read blogpost content – it's encrypted!

So, blogposts are stored enrypted, but it's transparent for web reader and admin interface.

### Check monitoring

Now, where the fun begins.

```<url>```
```<screenshots>```


### Other available resources

1. PostgreSQL – you can connect to DB directly using admin account `postgres/test`: [postgresql://www.djangoproject.example:5432](postgresql://www.djangoproject.example:5432)

2. Prometheus – examine the collected metrics: [http://www.djangoproject.example:9090](http://www.djangoproject.example:9090)

3. Grafana - sample of dashboards with Acra metrics: [http://www.djangoproject.example:3000](http://www.djangoproject.example:3000)

4. AcraConnector – send some data through AcraConnector directly: [tcp://www.djangoproject.example:9494](tcp://www.djangoproject.example:9494)

5. AcraWebConfig – configure AcraServer using default account `test/test`: [http://www.djangoproject.example:8001](http://www.djangoproject.example:8001)

## How much code to change

https://github.com/django/djangoproject.com/compare/master...cossacklabs:master

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

<p align="center"><img src="_pics/eng_demo_python.png" alt="Protecting simple python application: Acra architecture" width="450"></p>


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
