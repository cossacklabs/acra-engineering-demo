# What is this?

Acra Engineering Demo illustrates how to integrate Acra data protection into your existing application. Protecting data is completely transparent for the users and requires minimum changes of infrastructure.

**Integrating Acra into any application contains 3 steps:**

1. **Generate storage and transport encryption keys** using AcraKeymaker. For this example we will generate one storage keypair (for encrypting and decrypting data), and two transport keypairs (for secure connection between AcraServer and AcraConnector). 
2. **Integrate AcraWriter** – the client-side library – into the client application (web or mobile app). Application calls AcraWriter to encrypt data, then sends data to the database as usual. AcraWriter uses storage public key to encrypt data.
3. **Deploy server-side infrastructure**: AcraServer and AcraConnector.  

      1. To decrypt the data, application reads data through AcraServer. AcraServer identifies application, makes sure that requests are legit, fetches data from database and returns decrypted data to the application. AcraServer is deployed as Docker container and connected to the database and AcraConnector. AcraServer has storage private key to decrypt the data, AcraServer's transport keypair and AcraConnector's public key to build protected transport connection.
      2. AcraConnector is an important transport protection between client and AcraServer. AcraConnector is deployed as Docker container into separate host, and uses own transport keypair and AcraServer's public key to build protected transport connection.

Please refer to the [Acra/Readme documentation](https://github.com/cossacklabs/acra#protecting-data-in-sql-databases-using-acrawriter-and-acraserver) for more detailed description and schemes.

# Protecting data on Django-based web site

## 1. Installation

```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- django
```

This command downloads code of Django web site example, Acra Docker containers and PostgreSQL database, sets up environment and provides list of links for you to try.

## 2. What's inside

<p align="center"><img src="_pics/eng_demo_django.png" alt="Protecting Django web application: Acra architecture" width="530"></p>

**Client application** is the famous Django app example – the djangoproject.com web site. We took [their source code](https://github.com/cossacklabs/djangoproject.com) and integrated AcraWriter to protect blog posts. 

Blogposts are **protected**: author name, author email, blogpost content are encrypted and wrapped into AcraStruct. Plaintext fields are: blogpost ID and title.

Django app **writes** AcraStructs and **reads** decrypted posts from the PostgreSQL database through AcraConnector and AcraServer (that are transparent for the application).

From user perspective web site works as usual, however, data is protected.

### 2.1 Update etc/hosts

Please add a temporary entry to the hosts file:

```
echo 'SERVER_IP www.djangoproject.example' >> /private/etc/hosts
```

where `SERVER_IP` is IP address of the server with running Acra Engineering Demo (if you run demo on your machine, set "127.0.0.1"). Updating hosts file is required because we will run protected djangoproject site locally. You can remove this line after using demo.


### 2.2 Add new post

1. Log into admin cabinet [http://www.djangoproject.example:8000/admin/](http://www.djangoproject.example:8000/admin/) using user/password: admin/admin.

2. Add blog post:

```<screenshots>```

3. Open blog posts feed [http://www.djangoproject.example:8000/weblog/](http://www.djangoproject.example:8000/weblog/) and see your fresh post.

```<screenshots>```

Yay! Now let's check database content.

### 2.3 Check database

1. Log into web PostgreSQL interface [http://www.djangoproject.example:8008](http://www.djangoproject.example:8008) using user/password: test/test.

2. Find your blogpost in  ... (scheme) and download it's content.

```<screenshots>```

3. Read blogpost content – it's encrypted!

So, blogposts are stored encrypted, but it's transparent for web reader and admin interface.

### 2.4 Check monitoring

Now, where the fun begins.

```<url>```
```<screenshots>```


### 2.5 Other available resources

1. PostgreSQL – you can connect to DB directly using admin account `postgres/test`: [postgresql://www.djangoproject.example:5432](postgresql://www.djangoproject.example:5432).

2. Prometheus – examine the collected metrics: [http://www.djangoproject.example:9090](http://www.djangoproject.example:9090).

3. Grafana - see sample of dashboards with Acra metrics: [http://www.djangoproject.example:3000](http://www.djangoproject.example:3000).

4. AcraConnector – send some data through AcraConnector directly: [tcp://www.djangoproject.example:9494](tcp://www.djangoproject.example:9494).

5. AcraWebConfig – configure AcraServer remotely (for example, disable intrusion detection) using default account `test/test`: [http://www.djangoproject.example:8001](http://www.djangoproject.example:8001).

6. [Docker-compose.django.yml](https://github.com/cossacklabs/acra-engineering-demo/blob/master/django/docker-compose.django.yml) file describes all configuration and containers for this example.  

## 3. How much code to change

https://github.com/django/djangoproject.com/compare/master...cossacklabs:master

```
<Before / after>
```

# Protecting data of simple database application

## 1. Installation

```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- python
```

This command downloads simple Python application that stores data in database, Acra Docker containers and PostgreSQL database, sets up environment and provides list of links for you to try.

## 2. What's inside

<p align="center"><img src="_pics/eng_demo_python.png" alt="Protecting simple python application: Acra architecture" width="450"></p>

**Client application** is the simple [python console application](https://github.com/cossacklabs/acra/tree/master/examples/python), that works with database. Application **encrypts** data in AcraStructs before sending to the database. Application **reads** decrypted data through AcraConnector and AcraServer (that are transparent for the application).

### 2.1 Write data

```bash
docker exec -it python_python_1 \
  python /app/example_without_zone.py --data="top secret data"
  
$ insert data: top secret data
```

### 2.2 Read decrypted data through AcraServer

```bash
docker exec -it python_python_1 \
  python /app/example_without_zone.py --print
  
$ id  - data                 - raw_data
  3   - top secret data      - top secret data
```

`raw_data` is stored in plaintext for the demo purposes, `data` is being decrypted by AcraServer.

### 2.3 Read data directly from database

To make sure that data is encrypted, try to read it directly from database, using database host and port:

```bash
docker exec -it python_python_1 \
  python /app/example_without_zone.py --print --host=postgresql --port=5432
  
$ id  - data                 - raw_data
 3	-""""""""UEC2-Jo6l,*޿yAO\e
 T8%/`     GE].P[6߶חfq\t[Dw

     Q.;@
         h?AIɹv,ѹ&!TL\ - top secret data
```

As expected, `data` is encrypted and printed as mess, `raw_data` is plaintext.

### 2.4 Check database

1. Log into web PostgreSQL interface [http://$HOST:8008](http://127.0.0.1:8008) using user/password: test/test. 
`$HOST` is the IP address of the server with running Acra Engineering Demo (if you run demo on your machine, set "127.0.0.1").

2. Find your data entry.

```<screenshots>```

3. Read content of `data` field – it's encrypted!

So, data is stored encrypted, but it is transparent for python application.


### 2.5 Other available resources

1. PostgreSQL – you can connect to DB directly using admin account `postgres/test`: [postgresql://$HOST:5432](postgresql://127.0.0.1:5432).

2. Prometheus – examine the collected metrics: [http://$HOST:9090](http://127.0.0.1:9090).

3. Grafana - see dashboards with Acra metrics: [http://$HOST:3000](http://127.0.0.1:3000).

4. AcraConnector – send some data through AcraConnector directly: [tcp://$HOST:9494](tcp://127.0.0.1:9494).

5. AcraWebConfig – configure AcraServer remotely (for example, disable intrusion detection) using default account `test/test`: [http://$HOST:8001](http://127.0.0.1:8001).

6. [Docker-compose.python.yml](https://github.com/cossacklabs/acra-engineering-demo/blob/master/python/docker-compose.python.yml) file describes all configuration and containers for this example.  

 
## 3. How much code to change

```
<Before / after>
```

# Further steps

```
<Links to Acra, other examples>
```
