# What is this?

Acra Engineering Examples illustrate the integration of [Acra data protection suite](https://github.com/cossacklabs/acra) into your existing application. Protecting the data is completely transparent for the users and requires minimal changes in the infrastructure.


This collection has several example application. Each folder contains docker-compose file, that describes key management procedures and configurations of Acra.

| #  | Example                                                                                                                                                                                                       | What's inside                                                                                                                 |
|----|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|
| 1  | [Transparent encryption, Django, PostgreSQL](https://github.com/cossacklabs/acra-engineering-demo/#example-1-transparent-encryption-django-postgresql)                                                        | Django web application, transparent encryption/decryption, AcraServer, PostgreSQL                                             |
| 2  | [Intrusion detection system, transparent encryption, PostgreSQL](https://github.com/cossacklabs/acra-engineering-demo/#example-2-intrusion-detection-system-transparent-encryption-postgresql)                | Go application, transparent encryption/decryption, poison records, PostgreSQL                                                 |
| 3  | [Transparent encryption, TimescaleDB](https://github.com/cossacklabs/acra-engineering-demo/#example-3-transparent-encryption-timescaledb)                                                                     | TimescaleDB, transparent encryption/decryption, AcraServer                                                                    |
| 4  | [Transparent encryption, Python app, MySQL, PostgreSQL](https://github.com/cossacklabs/acra-engineering-demo/#example-4-transparent-encryption-python-app-mysql-postgresql)                                   | MySQL, transparent encryption/masking/tokenization, Python, AcraServer                                                        |
| 5  | [Client-side encryption, Django, PostgreSQL](https://github.com/cossacklabs/acra-engineering-demo/#example-5-client-side-encryption-django-postgresql)                                                        | Django web application with client-side encryption (AcraWriter), decryption on AcraServer, PostgreSQL                         |
| 6  | [Client-side encryption with Zones, python app, PostgreSQL (deprecated, will be removed)](https://github.com/cossacklabs/acra-engineering-demo/#example-6-client-side-encryption-zones-python-app-postgresql) | Simple python client application, client-side encryption with Zones support, decryption on AcraServer, PostgreSQL             |
| 7  | [Client-side encryption, Ruby on Rails app, PostgreSQL](https://github.com/cossacklabs/acra-engineering-demo/#example-7-client-side-encryption-ruby-on-rails-app-postgresql)                                  | Ruby on Rails web application, client-side encryption, decryption on AcraServer, PostgreSQL                                   |
| 8  | [Transparent encryption, Zones, python app, CockroachDB (deprecated, will be removed)](https://github.com/cossacklabs/acra-engineering-demo/#example-8-transparent-encryption-zones-python-app-cockroachdb)   | Simple python client application, transparent encryption/decryption with Zones support, decryption on AcraServer, CockroachDB |
| 9  | [SQL injection prevention, AcraCensor](https://github.com/cossacklabs/acra-engineering-demo/#example-9-sql-injection-prevention-acracensor)                                                                   | OWASP Mutillidae vulnerable web application, AcraConnector, AcraServer, AcraCensor (SQL firewall)                             |
| 10 | [Load balancing](https://github.com/cossacklabs/acra-engineering-demo/#example-10-load-balancing)                                                                                                             | python client application, AcraServer, HAProxy                                                                                |
| 11 | [Search in encrypted data](https://github.com/cossacklabs/acra-engineering-demo/#example-11-search-in-encrypted-data)                                                                                         | python client app, AcraServer, MySQL / PostreSQL database                                                                     |
| 12 | [AcraTranslator Demo](https://github.com/cossacklabs/acra-engineering-demo/#example-12-acratranslator-usage)                                                                                                  | Go API Server, AcraTranslator, MongoDB                                                                                        |


# Overview

Integrating Acra into any application requires 3 steps:

1. **Generate cryptographic keys**. In this examples, we generate only required keys for each example (Master key, and data encryption keys, rarely others). Refer to [Key management](https://docs.cossacklabs.com/acra/security-controls/key-management/) to learn more about keys.
2. **Configure and deploy services**.
    1. **transparent encryption** for SQL databases – configure and deploy AcraServer. Configure AcraServer's behavior, set up TLS, connect to the database, select which fields/columns to encrypt. 
    2. **encryption-as-a-service** for NoSQL databases – configure and deploy AcraTranslator. Configure AcraTranslator's behavior, set up TLS, select gRPC or REST API.
    3. **client-side encryption** – you can encrypt data in the client application using AcraWriter, then decrypt data on AcraServer or AcraTranslator. 
3. **Update client-side code**.
    1. **transparent encryption** for SQL databases – just point client-side app to AcraServer instead of the database. 
    2. **encryption-as-a-service** for NoSQL databases – call AcraTranslator API from client-side app and encrypt/decrypt fields on AcraTranslator.
    3. **client-side encryption** – integrate AcraWriter, call it to encrypt fields in the app before sending them to the database. 
    
Please refer to the [Acra Data flows](https://docs.cossacklabs.com/acra/acra-in-depth/data-flow/) for more detailed description and schemes.

---

# Example 1. Transparent encryption, Django, PostgreSQL

Django web application, transparent encryption/decryption, AcraServer, PostgreSQL.

Follow [Integrating AcraServer into infrastructure guide](https://docs.cossacklabs.com/acra/guides/integrating-acra-server-into-infrastructure/) or a tutorial on dev.to [How to encrypt database fields transparently for your app using Acra and DigitalOcean managed PostgreSQL](https://dev.to/cossacklabs/how-to-encrypt-database-fields-transparently-for-your-app-using-acra-and-digitalocean-managed-postgresql-48ce).

## 1. Installation

Transparent encryption mode (server-side encryption and decryption): data is encrypted and decrypted on the AcraServer:
```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- django-transparent
```

This command downloads the code of Django website example, Acra Docker containers, PostgreSQL database, Prometheus, 
Grafana, pgAdmin images and sets up the environment, configures AcraServer to encrypt data, and provides a list of links for you to try.

## 2. What's inside

**The client application** is the famous Django app example – the source code of [djangoproject.com](https://www.djangoproject.com/). We've [updated their source code](https://github.com/cossacklabs/djangoproject.com) to protect blog posts. Application stores blog posts in PosgtreSQL database. We encrypt blog posts' content before storing in database, and decrypt when reading from database.


<p align="center"><img src="_pics/eng_demo_django_transparent_encr-no-ac.png" alt="Protecting Django web application: Acra architecture (transparent mode)" width="700"></p>

Django app **does not encrypt** the sensitive fields, it just passes data to AcraServer through secured TLS channel (which pretends to be a database). AcraServer **encrypts** these sensitive fields and stores them into database.

Django app **reads the decrypted posts** from the database through AcraServer.

From the users' perspective, the website works as it used to. However, the blog posts are protected now.

### 2.1 Update etc/hosts

Please add a temporary entry to the hosts file:

```bash
echo "$SERVER_IP www.djangoproject.example" >> /etc/hosts
```

where `SERVER_IP` is the IP address of the server that is running the Acra Engineering Demo (if you run the demo on your machine, set it to `127.0.0.1`). Updating the hosts file is required because we will run the protected djangoproject site locally. You can remove this line when you stop needed to access the demo site.

### 2.2 Add a new post / category

1. Log into admin cabinet [http://www.djangoproject.example:8000/admin/blog/entry/](http://www.djangoproject.example:8000/admin/blog/entry/) using user/password: `admin/admin`.

Add a blog post to the Blogs/Entries:

<img src="_pics/web_django_posts.png" width="600">

You can go to Dashboard window [http://www.djangoproject.example:8000/admin/dashboard/category/](http://www.djangoproject.example:8000/admin/dashboard/category/)

And add a new Dashboard category:

<img src="_pics/web_django_dashboard.png" width="600">

2. Open the blog posts' feed [http://www.djangoproject.example:8000/weblog/](http://www.djangoproject.example:8000/weblog/) and see your fresh post.

   Also, you can open the dashboard category' feed [http://www.djangoproject.example:8000/admin/dashboard/category/](http://www.djangoproject.example:8000/admin/dashboard/category/) and see your newly created category:

### 2.3 Connect to the database from the web

Everything worked well! Now, let's check the content of the database.

Log into the web PostgreSQL interface [http://www.djangoproject.example:8008](http://www.djangoproject.example:8008) using user/password: `test@test.test`/`test`. 

Find your blog post in  `Servers > postgresql > databases > djangoproject > Schemas > public > Tables > blog_entries` and open context menu with right-click. 

Dashboard categories are in `Servers > postgresql > databases > djangoproject > Schemas > public > Tables > dashboard_category`.

Select `View/Edit Data > All rows` and now you can see content of the table. Download and read the content – it's encrypted.

<img src="_pics/db_django.png" width="1200">

<img src="_pics/db_django_dashboards.png" width="1200">

So, the blog posts/dashboard categories are stored encrypted, but it's transparent for site visitors and admins.

### 2.4 Check the monitoring

Open Grafana dashboards to see the performance stats of AcraServer. We collect following metrics: the number of decrypted cryptographic containers (AcraStructs and AcraBlocks), request and response processing time.

Grafana is available at [http://www.djangoproject.example:3000](http://www.djangoproject.example:3000).

<img src="_pics/django_monitoring.png" width="900">

### 2.5 View traces

AcraServer can export detailed traces to Jaeger. Use this data to optimize the performance of the entire system.

Jaeger is available at [http://www.djangoproject.example:16686](http://www.djangoproject.example:16686).

<img src="_pics/jaeger_traces.png" width="900">

### 2.6 Other available resources

There's more to explore:

1. PostgreSQL – connect directly to the database using the admin account `postgres/test`: [postgresql://localhost:5432](postgresql://localhost:5432).

2. pgAdmin - connect directly to the database using WebUI and user account `login:test@test.test`/`password:test`: [http://localhost:8008](http://localhost:8008)

3. Prometheus –  examine the collected metrics: [http://localhost:9090](http://localhost:9090).

4. Grafana – see the dashboards with Acra metrics: [http://localhost:3000](http://localhost:3000).

5. Jaeger – view traces: [http://localhost:16686](http://localhost:16686).

6. [Docker-compose.django.yml](https://github.com/cossacklabs/acra-engineering-demo/blob/master/django/docker-compose.django.yml) file – read details about configuration and containers used in this example.

## 3. Show me the code!

So, was it easy to integrate Acra into Django application? Sure it was!

1. AcraServer returns binary data, so [we wrote simple wrapper classes](https://github.com/cossacklabs/acra-engineering-demo/blob/master/django-transparent/configs/fields.py) to perform encoding and decoding data.

2. [We changed original fields types to new ones](https://github.com/cossacklabs/acra-engineering-demo/blob/master/django-transparent/configs/models.py.patch).

3. Created [database migration file](https://github.com/cossacklabs/acra-engineering-demo/blob/master/django-transparent/configs/0003_encrypt.py) to convert encrypted fields to binary.

Those are all the code changes! 🎉

---

# Example 2. Intrusion detection system, transparent encryption, PostgreSQL

Learn how to prevent possible intrusions by adding "poison records" special crafted data to your database and filtering potential attackers who try to access them.

What's inside: Go client application, AcraServer in transparent encryption mode (server-side encryption), PostgreSQL database.

Follow the guide: [Acra intrusion detection example](https://github.com/cossacklabs/acra-poison-records-demo).

---


# Example 3. Transparent encryption, TimescaleDB

TimescaleDB, AcraServer in Transparent encryption mode.

## 1. Installation

```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- timescaledb
```

This command:
* downloads AcraServer, TimescaleDB, Prometheus, Grafana and PgAdmin images
* build `metricsource` image
* configures environment and starts demo stand using docker-compose


## 2. What's inside

Demo stand based on TimescaleDB, which stores encrypted data. That data produced by `metricsource` container which connected to TimescaleDB through AcraServer.

At the initial stage, the TimescaleDB database will be filled with randomly generated metric data. Once started, the small daemon running in the `metricsource` container will continue to insert records into the database to simulate real processes.

Grafana also connected through AcraServer to TimescaleDB and can get decrypted data to build `Temperature (demo data)` graph.

<p align="center"><img src="_pics/eng_demo_timescaledb_metrics.png" alt="Protecting TimescaleDB metrics: Grafana dashboard" width="700"></p>

Prometheus collects real metrics from AcraServer and show it on the dashboard `AcraServer (real data)`.

Grafana shows dashboard with metrics collected from AcraServer and Prometheus.

### 2.1 Read the data directly from the database

1. Log into web TimescaleDB interface [http://localhost:8008](http://localhost:8008) using user/password: `test@test.test`/`test`.

2. Go to the `Servers > postgresql > databases > test > Schemas > public > Tables > versions` and open context menu with right-click. Select `View/Edit Data > All rows` and now you can see content of the table.
Fields `device` and `unit_id` are encrypted. So, the data is stored in an encrypted form, but it is transparent for the Grafana.

## 2.2 Play with stand

You can easily interact with TimescaleDB through AcraServer:
```bash
docker exec -it \
  -ePGSSLMODE='verify-full' \
  -ePGSSLROOTCERT='scripts/ca.crt' \
  -ePGSSLKEY='/scripts/acra-client.key' \
  -ePGSSLCERT='/scripts/acra-client.crt' \
  timescaledb-metricsource-1 \
  psql  'postgres://postgres:test@acra-server:9393/test'
```
or directly:
```bash
docker exec -it -u postgres timescaledb-timescaledb-1 \
  psql test
```

### 3. Other available resources

1. TimescaleDB - connect to the database using the admin account `postgres`/`test`: [postgresql://$HOST:5432](postgresql://127.0.0.1:5432).

2. pgAdmin - connect directly to the database using WebUI and user account `login:test@test.test`/`password:test`: [http://localhost:8008](http://localhost:8008)

3. Grafana – see the dashboards with Acra metrics: [http://localhost:3000](http://localhost:3000).

4. Prometheus – examine the collected metrics: [http://localhost:9090](http://localhost:9090).

5. AcraServer – send some data directly through AcraServer: [tcp://localhost:9393](tcp://localhost:9393).

---

# Example 4. Transparent encryption, Python app, MySQL, PostgreSQL

Python client application, transparent encryption/decryption/masking/tokenization with zones support, AcraServer, MySQL database.

## 1. Installation

### Transparent encryption mode

```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- python-mysql-postgresql
```

This command downloads a simple Python application that stores the data in a database, Acra Docker containers, MySQL, PostgreSQL
databases, sets up the environment, configures python application to connect to Acra, and provides a list of links for you to try.

## 2. What's inside

<p align="center"><img src="_pics/eng_demo_python-no-ac.png" alt="Protecting simple python application: Acra architecture" width="560"></p>

**The client application** is a simple [python console application](https://github.com/cossacklabs/acra/tree/master/examples/python) 
that works with a database. The application talks with the database via Acra, Acra **encrypts** the data before sending 
it to a database, and decrypts the data when the app reads it from the database. Same it does transparently with tokenized data.

### 3. MySQL Transparent Encryption

By default, Acra configured to work with MySQL database.

### 3.1 Data Encryption(Write) 

Let's write some data to DB using the [`extended_example.py`](https://github.com/cossacklabs/acra/blob/master/examples/python/extended_example.py) script:

```bash
docker exec -it python-mysql-postgresql_python_1 python3 extended_example.py --host=acra-server --port=9393 --data=data.json

$:
data: [{'token_i32': 1234, 'token_i64': 645664, 'token_str': '078-05-1111', 'token_bytes': 'byt13es', 'token_email': 'john_wed@cl.com', 'data': 'John Wed, Senior Relationshop Manager', 'masking': '$112000', 'searchable': 'john_wed@cl.com'}, {'token_i32': 1235, 'token_i64': 645665, 'token_str': '078-05-1112', 'token_bytes': 'byt13es2', 'token_email': 'april_cassini@cl.com', 'data': 'April Cassini, Marketing Manager', 'masking': '$168000', 'searchable': 'april_cassini@cl.com'}, {'token_i32': 1236, 'token_i64': 645667, 'token_str': '078-05-1117', 'token_bytes': 'byt13es3', 'token_email': 'george_clooney@cl.com', 'data': 'George Clooney, Famous Actor', 'masking': '$780000', 'searchable': 'george_clooney@cl.com'}]
```

### 3.2 Data Decryption(Read)

To read and decrypt data the same script could be used but with `--print` param provided:

```bash
docker exec -it python-mysql-postgresql_python_1 python3 extended_example.py --host=acra-server --port=9393 --print
```

You should see the output that contains all decrypted data:

```
$:
Fetch data by query {}
SELECT test.id, test.data, test.masking, test.token_i32, test.token_i64, test.token_str, test.token_bytes, test.token_email
FROM test
6
id  - data - masking - token_i32 - token_i64 - token_str - token_bytes - token_email
...
- yMLDOzoMx@4juJOQbj.de78xxxx - -63551493 - -5945288817374683 - tk59cg2klQ7 - l҄
  4   - John Wed, Senior Relationshop Manager - $112000 - 1234 - 645664 - 078-05-1111 - byt13es - john_wed@cl.com
  5   - April Cassini, Marketing Manager - $168000 - 1235 - 645665 - 078-05-1112 - byt13es2 - april_cassini@cl.com
  6   - George Clooney, Famous Actor - $780000 - 1236 - 645667 - 078-05-1117 - byt13es3 - george_clooney@cl.com
```

Let's make a direct call to DB to verify that data is indeed encrypted:

```bash
docker exec -it python-mysql-postgresql_mysql_1 mysql -u test -D test --password=test -e 'select * from test'
```

You should see the garbage on the screen and see that data is stored encrypted.


### 3.3. Connect to the database from the web

1. Log into web MySQL phpmyadmin interface [http://localhost:8080](http://localhost:8080).

2. Find the table and the data rows.

<img src="_pics/python_mysql_phpmyadmin.png" width="700">

3. Compare data in result table and source json. All entries except `id` were encrypted or tokenized.

So, the data are protected and it is transparent for the Python application.


### 4. PostgreSQL Transparent Encryption

To switch the demo to use PostgreSQL change `mysql_enable` to `false`, `db_host` to `postgresql` and `db_port` to `5432` in [`acra-server.yaml`](./python-mysql-postgresql/acra-server-config/acra-server.yaml)

Restart `acra-server` to use updated config

```bash
docker restart python-mysql-postgresql_acra-server_1
```

### 4.1 Data Encryption(Write)

```bash
docker exec -it python-mysql-postgresql_python_1 python3 extended_example.py --host=acra-server --port=9393 --data=data.json --postgresql

$:
data: [{'token_i32': 1234, 'token_i64': 645664, 'token_str': '078-05-1111', 'token_bytes': 'byt13es', 'token_email': 'john_wed@cl.com', 'data': 'John Wed, Senior Relationshop Manager', 'masking': '$112000', 'searchable': 'john_wed@cl.com'}, {'token_i32': 1235, 'token_i64': 645665, 'token_str': '078-05-1112', 'token_bytes': 'byt13es2', 'token_email': 'april_cassini@cl.com', 'data': 'April Cassini, Marketing Manager', 'masking': '$168000', 'searchable': 'april_cassini@cl.com'}, {'token_i32': 1236, 'token_i64': 645667, 'token_str': '078-05-1117', 'token_bytes': 'byt13es3', 'token_email': 'george_clooney@cl.com', 'data': 'George Clooney, Famous Actor', 'masking': '$780000', 'searchable': 'george_clooney@cl.com'}]
```

### 4.2 Data Decryption(Read)

To read and decrypt data the same script could be used but with `--print` param provided:

```bash
docker exec -it python-mysql-postgresql_python_1 python3 extended_example.py --host=acra-server --port=9393 --print --postgresql
```

You should see the output that contains all decrypted data:

```
$:
Fetch data by query {}
SELECT test.id, test.data, test.masking, test.token_i32, test.token_i64, test.token_str, test.token_bytes, test.token_email
FROM test
6
id  - data - masking - token_i32 - token_i64 - token_str - token_bytes - token_email
...
- yMLDOzoMx@4juJOQbj.de78xxxx - -63551493 - -5945288817374683 - tk59cg2klQ7 - l҄
  4   - John Wed, Senior Relationshop Manager - $112000 - 1234 - 645664 - 078-05-1111 - byt13es - john_wed@cl.com
  5   - April Cassini, Marketing Manager - $168000 - 1235 - 645665 - 078-05-1112 - byt13es2 - april_cassini@cl.com
  6   - George Clooney, Famous Actor - $780000 - 1236 - 645667 - 078-05-1117 - byt13es3 - george_clooney@cl.com
```

Let's make a direct call to DB to verify that data is indeed encrypted:

```bash
docker exec -it python-mysql-postgresql_postgresql_1 psql -h localhost -U test -d test -c "select * from test"
```

You should see the garbage on the screen and see that data is stored encrypted.

### 4.3 Connect to the database from the web

Everything worked well! Now, let's check the content of the database.

Log into the web PostgreSQL interface [http://www.djangoproject.example:8008](http://www.djangoproject.example:8008) using user/password: `test@test.test`/`test`.

Find your blog post in  `Servers > postgresql > databases > djangoproject > Schemas > public > Tables > blog_entries` and open context menu with right-click.

Dashboard categories are in `Servers > postgresql > databases > djangoproject > Schemas > public > Tables > dashboard_category`.

Select `View/Edit Data > All rows` and now you can see content of the table. Download and read the content – it's encrypted.

### 5. Other available resources

1. MySQL – connect directly to the database using the admin account `test/test`: [mysql://localhost:3306](mysql://localhost:3306).

2. phpmyadmin - connect directly to the database using WebUI : [http://localhost:8080](http://localhost:8080)

3. PostgreSQL – connect directly to the database using the admin account `postgres/test`: [postgresql://localhost:5432](postgresql://localhost:5432).

4. pgAdmin - connect directly to the database using WebUI and user account `login:test@test.test`/`password:test`: [http://localhost:8008](http://localhost:8008)

5. Prometheus –  examine the collected metrics: [http://localhost:9090](http://localhost:9090).

6. Grafana – see the dashboards with Acra metrics: [http://localhost:3000](http://localhost:3000).

7. Jaeger – view traces: [http://localhost:16686](http://localhost:16686).

8. [docker-compose.python-mysql-postgresql.yml](https://github.com/cossacklabs/acra-engineering-demo/blob/master/python-mysql-postgresql/docker-compose.python-mysql-postgresql.yml) file – read details about configuration and containers used in this example.

## 6. Show me the code!

Take a look at the complete code of [`extended_example.py`](https://github.com/cossacklabs/acra/blob/master/examples/python/extended_example.py).

Let's see how many code lines are necessary to encrypt some data using Acra. 

1. The app reads JSON data and writes the data to the database as usual:

```python
def write_data(data, connection):
   # here we encrypt our data and wrap into AcraStruct
   with open(data, 'r') as f:
      data = json.load(f)
   print("data: {}".format(data))
   rows = data
   if isinstance(data, dict):
      rows = [data]
   for row in rows:
      for k in ('data_str', 'data_i64', 'data_i32', 'email', 'token_bytes', 'masking'):
         row[k] = row[k].encode('ascii')
      connection.execute(
         test_table.insert(), row)
```

2. Nothing changes when reading the data from the database:

```python
def print_data(connection, zone_id, columns):
   ...
   print("Fetch data by query {}\n",
         query.compile(dialect=postgresql.dialect(), compile_kwargs={"literal_binds": True}))
   result = connection.execute(query)
   result = result.fetchall()
   ...
```

> Note: We skipped code related to output formatting.

These are all the code changes! 🎉

----

# Example 5. Client-side encryption, Django, PostgreSQL

Django web application with client-side encryption (AcraWriter), decryption on AcraServer, PostgreSQL

Follow [Integrating AcraServer into infrastructure guide](https://docs.cossacklabs.com/acra/guides/integrating-acra-server-into-infrastructure/).

## 1. Installation

Client-side encryption and Acra-side decryption: data is encrypted on the application side and decrypted on the AcraServer:
```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- django
```

This command downloads the code of Django website example, Acra Docker containers, PostgreSQL database, Prometheus,
Grafana, pgAdmin images and sets up the environment, configures Django application to encrypt data, and provides a list of links for you to try.

## 2. What's inside

**The client application** is the famous Django app example – the source code of [djangoproject.com](https://www.djangoproject.com/). We've [updated their source code](https://github.com/cossacklabs/djangoproject.com) to protect blog posts. Application stores blog posts in PosgtreSQL database. We encrypt blog posts' content before storing in database, and decrypt when reading from database.

<p align="center"><img src="_pics/eng_demo_django.png" alt="Protecting Django web application: Acra architecture (asymmetric mode)" width="700"></p>

Django app **encrypts** the sensitive fields of blog posts into separate AcraStructs (author name, author email, content are encrypted; blog post ID and title are in plaintext).

Django app writes AcraStructs to the database and **reads the decrypted posts** through AcraServer (which pretends to be a database).

From the users' perspective, the website works as it used to. However, the blog posts are protected now.

### 2.1 Update etc/hosts

Please add a temporary entry to the hosts file:

```bash
echo "$SERVER_IP www.djangoproject.example" >> /etc/hosts
```

where `SERVER_IP` is the IP address of the server that is running the Acra Engineering Demo (if you run the demo on your machine, set it to `127.0.0.1`). Updating the hosts file is required because we will run the protected djangoproject site locally. You can remove this line when you stop needed to access the demo site.

### 2.2 Add a new post

1. Log into admin cabinet [http://www.djangoproject.example:8000/admin/blog/entry/](http://www.djangoproject.example:8000/admin/blog/entry/) using user/password: `admin/admin`. Add a blog post to the Blogs/Entries:

<img src="_pics/web_django_posts.png" width="600">

2. Open the blog posts' feed [http://www.djangoproject.example:8000/weblog/](http://www.djangoproject.example:8000/weblog/) and see your fresh post.

### 2.3 Connect to the database from the web

Everything worked well! Now, let's check the content of the database.

Log into the web PostgreSQL interface [http://www.djangoproject.example:8008](http://www.djangoproject.example:8008) using user/password: `test@test.test`/`test`. Find your blog post in  `Servers > postgresql > databases > djangoproject > Schemas > public > Tables > blog_entries` and open context menu with right-click. Select `View/Edit Data > All rows` and now you can see content of the table. Download and read the content – it's encrypted.

<img src="_pics/db_django.png" width="900">

So, the blog posts are stored encrypted, but it's transparent for site visitors and admins.

### 2.4 Check the monitoring

Open Grafana dashboards to see the performance stats of AcraServer. We collect following metrics: the number of decrypted cryptographic containers (AcraStructs and AcraBlocks), request and response processing time.

Grafana is available at [http://localhost:3000](http://localhost:3000).

<img src="_pics/django_monitoring.png" width="900">

### 2.5 View traces

AcraServer can export detailed traces to Jaeger. Use this data to optimize the performance of the entire system.

Jaeger is available at [http://localhost:16686](http://localhost:16686).

<img src="_pics/jaeger_traces.png" width="900">

### 2.6 Other available resources

There's more to explore:

1. PostgreSQL – connect directly to the database using the admin account `postgres/test`: [postgresql://localhost:5432](postgresql://localhost:5432).

2. pgAdmin - connect directly to the database using WebUI and user account `login:test@test.test`/`password:test`: [http://localhost:8008](http://localhost:8008)

3. Prometheus –  examine the collected metrics: [http://localhost:9090](http://localhost:9090).

4. Grafana – see the dashboards with Acra metrics: [http://localhost:3000](http://localhost:3000).

5. Jaeger – view traces: [http://localhost:16686](http://localhost:16686).

6. [Docker-compose.django.yml](https://github.com/cossacklabs/acra-engineering-demo/blob/master/django/docker-compose.django.yml) file – read details about configuration and containers used in this example.

## 3. Show me the code!

So, was it easy to integrate Acra into Django application? Sure it was!

You can [compare our repo to the original repo](https://github.com/django/djangoproject.com/compare/master...cossacklabs:master) and see how few changes we introduced:

1. We've added Acra storage public key ([L278](https://github.com/django/djangoproject.com/compare/master...cossacklabs:master#diff-6bcf911294def277f06abfe682ce5d7bR278)) necessary for AcraWriter to encrypt the data:
```
ACRA_SERVER_PUBLIC_KEY = b64decode(SECRETS.get('acra_storage_public_key'))
```

2. We added AcraWriter as a dependency and wrapped the original fields with it:

```python
import acrawriter.django

summary = acrawriter.django.TextField()
summary_html = acrawriter.django.TextField()
body = acrawriter.django.TextField()
body_html = acrawriter.django.TextField()
author = acrawriter.django.CharField(max_length=100)
```

3. We've also [run a database migration](https://github.com/django/djangoproject.com/compare/master...cossacklabs:master#diff-677329e0253d6cbba693e1ae0deda5b6) that changed the fields' format from `string` to `binary` to store the encrypted data.

Those are all the code changes! 🎉

---

# Example 6. Client-side encryption, Zones, python app, PostgreSQL (deprecated, will be removed)

Python client application, client-side encryption with zones support, AcraServer, PostgreSQL database.

## 1. Installation

### Asymmetric encryption mode

```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- python
```

This command downloads a simple Python application that stores the data in a database, Acra Docker containers, PostgreSQL database, sets up the environment, configures python application to encrypt data, and provides a list of links for you to try.

## 2. What's inside

<p align="center"><img src="_pics/eng_demo_python-no-ac.png" alt="Protecting simple python application: Acra architecture" width="560"></p>

**The client application** is a simple [python console application](https://github.com/cossacklabs/acra/tree/master/examples/python) that works with a database. The application **encrypts** the data in AcraStructs before sending it to a database. The application **reads** the decrypted data through AcraServer (that are transparent for the application).

### 2.1 Write data

```bash
docker exec -it python_python_1 \
  python /app/example_with_zone.py --data="top secret data"

$:
data: top secret data
zone: DDDDDDDDFidFDxORlrleaUrC
```

Call the [`example_with_zone.py`](https://github.com/cossacklabs/acra/blob/master/examples/python/example_with_zone.py) to encrypt the "top secret data" with a specific [Zone](https://docs.cossacklabs.com/acra/security-controls/zones/). The application generates Zones using AcraServer HTTP API, then it uses Zone public key and Zone Id for encryption.

### 2.2 Read data

Read the data using the same ZoneId. AcraServer decrypts the data and returns plaintext:

```bash
docker exec -it python_python_1 \
  python /app/example_with_zone.py --print --zone_id=DDDDDDDDFidFDxORlrleaUrC

$:
use zone_id:  DDDDDDDDFidFDxORlrleaUrC
id  - zone - data - raw_data
1   - DDDDDDDDFidFDxORlrleaUrC - top secret data - top secret data
```

The output contains Zone Id, the decrypted `data`, and `raw_data` (stored in plaintext for the demo purposes),

### 2.3 Read data with invalid Zone

Read the data using an invalid ZoneId. AcraServer will not decrypt the data and return the default data from `/app/encryptor_config_with_zone.yaml` config:

```bash
docker exec -it python_python_1 \
  python /app/example_with_zone.py --print --zone_id=DDDDDDDDFidFDxORlrleaU

$:
use zone_id:  DDDDDDDDEEaNtNHSbdOISJM
id  - zone - data - raw_data
1   - DDDDDDDDEEaNtNHSbdOISJM - test-data - top secret data
```


### 2.4 Read the data directly from the database

To make sure that the data is stored in an encrypted form, read it directly from the database:

```bash
docker exec -it python_python_1 \
  python /app/example_with_zone.py --print --zone_id=DDDDDDDDFidFDxORlrleaUrC --host=postgresql --port=5432

$:
use zone_id:  DDDDDDDDkOGnRsCBZEwXnHlL
id  - zone - data - raw_data
1   - DDDDDDDDkOGnRsCBZEwXnHlL - """"""""UEC2-CVs-K)'9@gJ-0 '&T@ {W|SҡϛڱY+:uKn"3Wɕ|Ict'JGCW;@ ̛W]aPI|Z ~*vI] - top secret data
```

As expected, no entity decrypts the `data`. The `raw_data` is stored as plaintext so nothing changes.

### 2.5 Connect to the database from the web

1. Log into web PostgreSQL interface [http://localhost:8008](http://localhost:8008) using user/password: `test@test.test`/`test`.

2. Find the table and the data rows.

<img src="_pics/db_web_python.png" width="700">

3. Try reading the content of `data` field – it's encrypted!

So, the data is stored in an encrypted form, but it is transparent for the Python application.

### 2.6 Encrypt the data without Zones

Usage of [Zones](https://docs.cossacklabs.com/acra/security-controls/zones/) provides compartmentalisation as different users of the same app will have different encryption keys. However, it's possible to [use AcraServer without Zones](https://docs.cossacklabs.com/pages/documentation-acra/#running-acraserver-in-zone-mode).

1. To disable Zones open `python/acra-server-config/acra-server.yaml` and change `zonemode_enable: true` value to `false`.
1. To disable Zones open `python/acra-server-config/acra-server.yaml` and change `zonemode_enable: true` value to `false`,
   `encryptor_config_file: "/app/encryptor_config_with_zone.yaml"` to `encryptor_config_file: "/app/encryptor_config_without_zone.yaml`
   and restart `acra-server`.

3. Write and read the data:

```bash
docker restart python_acra-server_1

docker exec -it python_python_1 \
  bash -c 'export EXAMPLE_PUBLIC_KEY="$(cat /pub_key_name.txt)" && \
  python /app/example_without_zone.py --data="secret data without zones"'

$:
insert data: secret data without zones

docker exec -it python_python_1 \
  bash -c 'export EXAMPLE_PUBLIC_KEY="$(cat /pub_key_name.txt)" && \  
  python /app/example_without_zone.py --print'

$:
id  - data                 - raw_data
2   - secret data without zones - secret data without zones
```

> Note: AcraServer decrypts either AcraStructs with Zones or without Zones at the same time. Sending different kinds of AcraStructs without changing the mode will lead to decryption errors.

### 2.7 Other available resources

1. PostgreSQL – connect directly to the database using the admin account `postgres/test`: [postgresql://localhost:5432](postgresql://localhost:5432).

2. pgAdmin - connect directly to the database using WebUI and user account `login:test@test.test`/`password:test`: [http://localhost:8008](http://localhost:8008)

3. Prometheus –  examine the collected metrics: [http://localhost:9090](http://localhost:9090).

4. Grafana – see the dashboards with Acra metrics: [http://localhost:3000](http://localhost:3000).

5. Jaeger – view traces: [http://localhost:16686](http://localhost:16686).

6. [Docker-compose.python.yml](https://github.com/cossacklabs/acra-engineering-demo/blob/master/python/docker-compose.python.yml) file – read details about configuration and containers used in this example.

## 3. Show me the code!

Take a look at the complete code of [`example_with_zone.py`](https://github.com/cossacklabs/acra/blob/master/examples/python/example_with_zone.py) and [`example_without_zone.py`](https://github.com/cossacklabs/acra/blob/master/examples/python/example_without_zone.py).

Let's see how many code lines are necessary to encrypt some data using Acra. We will look at the example with Zones because it's more complicated and requires additional API call to fetch Zone.

1. The app gets a Zone using [AcraServer API](https://docs.cossacklabs.com/pages/documentation-acra/#client-side-with-zones):

```python
def get_zone():
    response = urlopen('{}/getNewZone'.format(ACRA_SERVER_API_ADDRESS))
    json_data = response.read().decode('utf-8')
    zone_data = json.loads(json_data)
    return zone_data['id'], b64decode(zone_data['public_key'])
```

2. The app uses ZoneId and Zone public key to encrypt the data –

```python
encrypted_data = create_acrastruct(
  data.encode('utf-8'), key, zone_id.encode('utf-8'))
```

and writes the data to the database as usual:

```python
connection.execute(
    test_table.insert(), data=encrypted_data,
    zone_id=zone_id.encode('utf-8'),
    raw_data=data)
```

3. Nothing changes when reading the data from the database:

```python
result = connection.execute(
    select([cast(zone_id.encode('utf-8'), BYTEA), test_table]))
result = result.fetchall()

ZONE_ID_INDEX = 0
for row in result:
    print(
        "{:<3} - {} - {} - {}\n".format(
        row['id'], row[ZONE_ID_INDEX].decode('utf-8'),
        row['data'].decode('utf-8', errors='ignore'), row['raw_data']))
```

These are all the code changes! 🎉

---


# Example 7. Client-side encryption, Ruby on Rails app, PostgreSQL

Ruby on Rails web application, client-side encryption, AcraServer, PostgreSQL database.

## 1. Installation

```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- rails
```

This command downloads a Rails application that stores data in a database, Acra Docker containers, PostgreSQL database, Prometheus,
Grafana, pgAdmin. Additionally, downloads a memcached and Elastic as project dependencies, sets up the environment, and provides a list of links for you to try.

## 2. What's inside


**The client application** is a [rubygems.org fork](https://github.com/cossacklabs/rubygems.org) that works with a database. The application **encrypts** the data in AcraStructs before sending it to a database. The application **reads** the decrypted data through AcraServer (that are transparent for the application).

### 2.1 Prepare

1. Sign up with any fictional account at [sign_up page](http://www.rubygems.example:8000/sign_up) of the app. That credentials will be used later when uploading gem.

2. Verify your fictional email on a [special page](http://www.rubygems.example:8000/rails/mailers/mailer/email_confirmation) for development purposes.

3. Sign in via `gem` CLI tool with credentials used in the step 2:

```
gem signin --host=http://www.rubygems.example:8000
```

4. Use already built gem `rails/my-example-gem-0.1.0.gem` or build your own:

```bash
bundle gem my-example-gem
cd my-example-gem/

cat > ./my-example-gem.gemspec <<'EOF'
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "my/example/gem/version"

Gem::Specification.new do |spec|
  spec.name          = "my-example-gem"
  spec.version       = My::Example::Gem::VERSION
  spec.authors       = ["My Example Name"]
  spec.email         = ["my@email.example"]

  spec.summary       = %q{Example Gem}
  spec.description   = %q{This is Example Gem}
  spec.homepage      = "http://site.example"
  spec.license       = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "http://site.example"
    spec.metadata["changelog_uri"] = "http://site.example/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
EOF

gem build my-example-gem
```

### 2.2 Write data

Now we are ready to push our gem to the application:
```
gem push my-example-gem-0.1.0.gem --host=http://www.rubygems.example:8000
```

### 2.3 Read data

After previous step we can see information about uploaded gem: http://www.rubygems.example:8000/gems/my-example-gem

### 2.4 Read the data directly from the database

1. Log into web PostgreSQL interface [http://www.rubygems.example:8008](http://www.rubygems.example:8008) using user/password: `test@test.test`/`test`.

2. Go to the `Servers > postgresql > databases > rubygems > Schemas > public > Tables > versions` and open context menu with right-click. Select `View/Edit Data > All rows` and now you can see content of the table.
<p align="center"><img src="_pics/eng_demo_rails_pdadmin.png" alt="pgAdmin : versions table of rubygems DB." width="900"></p>
Fields `authors`, `description` and `summary` are encrypted. So, the data is stored in an encrypted form, but it is transparent for the Rails application.

### 2.5 Other available resources

1. PostgreSQL – connect directly to the database using the admin account `rubygems`/`rubygems`: [postgresql://www.rubygems.example:5432](postgresql://localhost:5432).

2. pgAdmin - connect directly to the database using WebUI and user account login:`test@test.test`/password:`test`: [http://localhost:8008](http://localhost:8008)

3. Prometheus –  examine the collected metrics: [http://localhost:9090](http://localhost:9090).

4. Grafana – see the dashboards with Acra metrics: [http://localhost:3000](http://localhost:3000).

5. Jaeger – view traces: [http://localhost:16686](http://localhost:16686).
   
6. AcraServer – send some data directly through AcraServer: [tcp://www.rubygems.example:9393](tcp://localhost:9494).

## 3. Show me the code!

1. Add gem `activerecord_acrawriter` to `Gemfile`:
```diff
+gem 'activerecord_acrawriter'
```

2. Modify `dependency.rb` to encrypt data of `unresolved_name` column in `Dependency` model:
```diff
@@ -1,3 +1,5 @@
+require 'activerecord_acrawriter'
+
 class Dependency < ApplicationRecord
   belongs_to :rubygem
   belongs_to :version
@@ -11,6 +13,8 @@

   attr_accessor :gem_dependency

+  attribute :unresolved_name, AcraType.new
+
   def self.unresolved(rubygem)
     where(unresolved_name: nil, rubygem_id: rubygem.id)
   end
```

3. And finally modify `version.rb` encrypt data of `authors`, `description` and `summary` columns in `Version` model:
```diff
@@ -1,4 +1,5 @@
 require 'digest/sha2'
+require 'activerecord_acrawriter'

 class Version < ApplicationRecord
   belongs_to :rubygem, touch: true
@@ -21,7 +22,7 @@
   validate :authors_format, on: :create
   validate :metadata_links_format

-  class AuthorType < ActiveModel::Type::String
+  class AuthorType < AcraType
     def cast_value(value)
       if value.is_a?(Array)
         value.join(', ')
@@ -32,3 +33,5 @@
   end

   attribute :authors, AuthorType.new
+  attribute :description, AcraType.new
+  attribute :summary, AcraType.new
```

These are all the code changes! 🎉

---

# Example 8. Transparent encryption, Zones, python app, CockroachDB (deprecated, will be removed)

Python client application, transparent encryption with zones support, AcraServer, CockroachDB  database.

## 1. Installation

```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- cockroachdb
```

This command downloads a simple Python application that stores the data in a database, Acra Docker containers, CockroachDB
database, sets up the environment, configures python application to connect to Acra, and provides a list of links for you to try.

## 2. What's inside

<p align="center"><img src="_pics/eng_demo_python-cockroach.png" alt="Protecting simple python application: Acra architecture" width="560"></p>

**The client application** is a simple [python console application](https://github.com/cossacklabs/acra/tree/master/examples/python)
that works with a database. The application talks with the database via Acra, Acra encrypts the data before sending
it to a database, and decrypts the data when the app reads it from the database. Same it does transparently with tokenized data.

### 2.1 Generate new zone

```bash
docker exec -it cockroachdb_python_1 \
  python3 extended_example_with_zone.py --host=acra-server --port=9393 --generate_zone

$:
zone_id: DDDDDDDDPfBoWiixeMTUuEOk
zone public key in base64: b"UEC2\x00\x00\x00-\xbf\xc4\xd4\xa5\x02\x13ZTsg\x13\x88%R\xb5\x00\xc2\xbc\xe9\x9d\xa5\xa3i';\x7f)\xa8a\x9c\xdc\x9b\xc4\xba8\xb6\x04"
```

Call the [`extended_example_with_zone.py`](https://github.com/cossacklabs/acra/blob/master/examples/python/extended_example_with_zone.py)
to generate [Zone](https://docs.cossacklabs.com/acra/security-controls/zones/) using AcraServer HTTP API.

### 2.2 Set ZoneID in encryptor config

Set ZoneID `DDDDDDDDPfBoWiixeMTUuEOk` instead of existing in `./acra/examples/python/extended_encryptor_config_with_zone.yaml`:

```bash
sed -i 's/DDDDDDDDHHNqiSYFXkpxopYZ/DDDDDDDDPfBoWiixeMTUuEOk/g' ./acra/examples/python/extended_encryptor_config_with_zone.yaml
```

### 2.3 Restart acra-server to use updated config

```bash
docker restart cockroachdb_acra-server_1
```


### 2.4 Insert data using updated config

Script reads data from `data.json` where stored array of entries as data examples.

```bash
docker exec -it cockroachdb_python_1 \
  python3 extended_example_without_zone.py --host=acra-server --port=9393 --data=data.json

$:
data: [{'token_i32': 1234, 'token_i64': 645664, 'token_str': '078-05-1111', 'token_bytes': 'byt13es', 'token_email': 'john_wed@cl.com', 'data': 'John Wed, Senior Relationshop Manager', 'masking': '$112000', 'searchable': 'john_wed@cl.com'}, {'token_i32': 1235, 'token_i64': 645665, 'token_str': '078-05-1112', 'token_bytes': 'byt13es2', 'token_email': 'april_cassini@cl.com', 'data': 'April Cassini, Marketing Manager', 'masking': '$168000', 'searchable': 'april_cassini@cl.com'}, {'token_i32': 1236, 'token_i64': 645667, 'token_str': '078-05-1117', 'token_bytes': 'byt13es3', 'token_email': 'george_clooney@cl.com', 'data': 'George Clooney, Famous Actor', 'masking': '$780000', 'searchable': 'george_clooney@cl.com'}]
```

### 2.5 Read data

Read the data using the same ZoneId. AcraServer decrypts the data and returns plaintext:
```bash
docker exec -it cockroachdb_python_1 \
  python3 extended_example_with_zone.py --host=acra-server --port=9393 --print  --zone_id=DDDDDDDDPfBoWiixeMTUuEOk
  
$:
Fetch data by query {}
 SELECT test.id, 'DDDDDDDDPfBoWiixeMTUuEOk' AS anon_1, test.data, test.masking, test.token_i32, test.token_i64, test.token_str, test.token_bytes, test.token_email 
FROM test
3
id  - zone_id - data - masking - token_i32 - token_i64 - token_str - token_bytes - token_email
1   - DDDDDDDDPfBoWiixeMTUuEOk - John Wed, Senior Relationshop Manager - $112000 - 1234 - 645664 - 078-05-1111 - byt13es - john_wed@cl.com
2   - DDDDDDDDPfBoWiixeMTUuEOk - April Cassini, Marketing Manager - $168000 - 1235 - 645665 - 078-05-1112 - byt13es2 - april_cassini@cl.com
3   - DDDDDDDDPfBoWiixeMTUuEOk - George Clooney, Famous Actor - $780000 - 1236 - 645667 - 078-05-1117 - byt13es3 - george_clooney@cl.com

```

### 2.6 Read the data directly from the database
To make sure that the data is stored in an encrypted form, read it directly from the database. Use `--port=26257` and --host=`roach1`:

```bash
docker exec -it cockroachdb_python_1 \
  python3 extended_example_with_zone.py --host=roach1 --port=26257 --print --zone_id=DDDDDDDDPfBoWiixeMTUuEOk

$:
Fetch data by query {}
 SELECT test.id, 'DDDDDDDDYuWpBtCtrjpHyHta' AS anon_1, test.data, test.masking, test.token_i32, test.token_i64, test.token_str, test.token_bytes, test.token_email 
FROM test
3
id  - zone_id - data - masking - token_i32 - token_i64 - token_str - token_bytes - token_email
1   - DDDDDDDDYuWpBtCtrjpHyHta - %%%""""L@'/e_>I6躁iH 1Rz#X.5@@f+hRgjp�$~@oxշ '&T@ - -560604022 - -3330418728144437366 - ccxIvgP0iLp - ?a - 98LK9@sigT2.net
...
```

### 2.7 Other available resources

1. CockroachDB – connect directly to the database using the user `root` and DB `defaultdb`: [postgresql://localhost:26257](postgresql://localhost:26257).

2. Prometheus –  examine the collected metrics: [http://localhost:9090](http://localhost:9090).

3. Grafana – see the dashboards with Acra metrics: [http://localhost:3000](http://localhost:3000).

4. Jaeger – view traces: [http://localhost:16686](http://localhost:16686).

5. [Docker-compose.python.yml](https://github.com/cossacklabs/acra-engineering-demo/blob/master/cockroachdb/docker-compose.cockroachdb.yml) file – read details about configuration and containers used in this example.


# Example 9. SQL injection prevention, AcraCensor

Learn how to configure AcraCensor – SQL firewall – to allow or deny specific queries and make your application more steady against SQL injections.

What's inside: OWASP Mutillidae vulnerable web application, AcraServer, AcraCensor.

Follow the guide: [Acra firewall example](https://github.com/cossacklabs/acra-censor-demo).

---

# Example 10. Load balancing

Learn how to build high availability and balanced infrastructures for AcraServer based on HAProxy.

What's inside: python client application, AcraServer, HAProxy.

Follow the guide: [Acra load balancing example](https://github.com/cossacklabs/acra-balancer-demo).

---

# Example 11. Search in encrypted data

Learn how to use [searchable encryption](https://docs.cossacklabs.com/acra/security-controls/searchable-encryption/) and search through encrypted data without decryption.

## 1. Installation

```bash
$ curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- python-searchable
```

This command downloads a simple Python application that stores the data in a database, Acra Docker containers, MySQL and PostgreSQL
databases, sets up the environment, configures python application to connect to Acra, and provides a list of links for you to try.

## 2. What's inside

<p align="center"><img src="_pics/eng_demo_python_searchable.png" alt="Protecting a simple python application: Acra architecture" width="560"></p>

**The client application** is a simple [python console application](https://github.com/cossacklabs/acra/tree/master/examples/python) 
that works with a database. The application talks with the database via Acra, Acra **encrypts** the data before sending 
it to a database (either PostgreSQL or MySQL), and decrypts the data when the app reads it from the database.

### 2.1 Choose database

By default, Acra is configured to use PostgreSQL as a database. But you can make it use MySQL. To do that, open `./python-searchable/acra-server-config/acra-server.yaml` and uncomment appropriate config lines. After, restart the AcraServer:
```bash
$ docker restart python-searchable-acra-server-1
```

Also, the client requires an appropriate flag to know which driver to use (`--postgresql` or `--mysql`). To simplify the workflow, export this flag into the `DB` variable:
```bash
$ export DB="--postgresql"
```

or

```bash
$ export DB="--mysql"
```

### 2.2 Insert data

To insert data, run:
```bash
$ docker exec -it python-searchable-python-1 \
    python /app/searchable.py $DB \
    --data=searchable.json

data:
[{'searchable_email': 'john_wed@cl.com', 'searchable_name': 'John'},
 {'searchable_email': 'april_cassini@cl.com', 'searchable_name': 'April'},
 {'searchable_email': 'george_clooney@cl.com', 'searchable_name': 'George'}]
```

The client reads rows from `searchable.json` file. You can find it at `./acra/examples/python/searchable.json`.

### 2.3 Read data

Select all rows with the following command:
```bash
$ docker exec -it python-searchable-python-1 \
    python /app/searchable.py $DB \
    --print

Fetch data by query SELECT test.id, test.searchable_name, test.searchable_email 
FROM test
- id: 1
  searchable_name: John
  searchable_email: john_wed@cl.com
- id: 2
  searchable_name: April
  searchable_email: april_cassini@cl.com
- id: 3
  searchable_name: George
  searchable_email: george_clooney@cl.com

TOTAL 3
```

The rows are fetched from the database and decrypted by the AcraServer.

### 2.4 Search encrypted data

The database's schema has two columns: `searchable_name` and `searchable_email`. The AcraServer is configured to support both for searchable encryption. For example, let's search for the name `April`:

```bash
$ docker exec -it python-searchable-python-1 \
    python /app/searchable.py $DB \
    --print \
    --search_name 'April'
  
Fetch data by query SELECT test.id, test.searchable_name, test.searchable_email 
FROM test 
WHERE test.searchable_name = 'April'
- id: 2
  searchable_name: April
  searchable_email: april_cassini@cl.com

TOTAL 1
```

Let's also search for the email `john_wed@cl.com`:

```bash
$ docker exec -it python-searchable-python-1 \
    python /app/searchable.py $DB \
    --print \
    --search_email 'john_wed@cl.com'

Fetch data by query SELECT test.id, test.searchable_name, test.searchable_email 
FROM test 
WHERE test.searchable_email = 'john_wed@cl.com'
- id: 1
  searchable_name: John
  searchable_email: john_wed@cl.com

TOTAL 1
``` 

Searchable encryption supports only the exact match, therefore the search for `john` instead of `John` results in no rows:
```bash
$ docker exec -it python-searchable-python-1 \
    python /app/searchable.py $DB \
    --print \
    --search_name 'john'

Fetch data by query SELECT test.id, test.searchable_name, test.searchable_email 
FROM test 
WHERE test.searchable_name = 'john'

TOTAL 0
```

### 2.5 Read data from the database

To make sure that the data is stored in an encrypted form, read it directly from the database.

If you are using PostgreSQL, run:
```bash
$ docker exec -it python-searchable-python-1 \
    python /app/searchable.py \
    --postgresql \
    --host=postgresql \
    --port=5432 \
    --print
```

Or, if you are using MySQL:
```bash
$ docker exec -it python-searchable-python-1 \
    python /app/searchable.py \
    --mysql \
    --host=mysql \
    --port=3306 \
    --print
```

In both cases you will see a gibberish on the screen:
```
Fetch data by query SELECT test.id, test.searchable_name, test.searchable_email 
FROM test
- id: 1
  searchable_name: NV9q.kq;gi;VB%%%""""L@
                                           
                                           D"Lk=|	"{{VnίڶHZozj#[U
,=$F	 @
          zLA3td0zi

  searchable_email: lh_|Μ-\W{IЇ%%%""""L@
                                         -7:&}Ef|9VbNVӁ
                                                       |S+|Rn4@
iU(C9@A0bklXvyڠ-                                               2+IgGH
- id: 2
  searchable_name: &}a7-H*YÚ%%%""""L@
                                      CaC/D1_\CR
                                                ز&EAMN*)忪;X?Q>8	-jM5w@
                                                                              V&pmJp)=+Ն!~
  searchable_email: ^iJ E͐Rv@dNsF%%%""""L@
                                          KZCz8xՈDP8 uLFlW@
                                                           xFɄlAMI_9Rz)
                                                                       �Hf29A
- id: 3
  searchable_name: %:xyo{EA|ǹe51d3^?%%%""""L@
                                              򢑆* du!=iJnqKs@ƅHiцyN!@[5إh@
                                                                         &xضA=	Djbʇ7>Fxʪ,3pe
  searchable_email: :1.&ڷmBA;DF/ؼAP%%%""""L@
                                             wJq"]gǡ1ib.iՃBլJԪgj[;2h+_v@
                                                                        X

Pm2W¤8
      ?@

TOTAL 3
```

### 2.6 Other resources to look at

#### Acra

1. [Acra encryptor config](`./acra/examples/python/searchable.yaml`) - study the Acra configuration that tells how to encrypt and index data.

2. Prometheus – examine the collected metrics: [http://localhost:9090](http://localhost:9090).

3. Grafana – see the dashboards with Acra metrics: [http://localhost:3000](http://localhost:3000).

4. Jaeger – view traces: [http://localhost:16686](http://localhost:16686).

#### Postgres

1. PostgreSQL – connect directly to the database using the admin account `test/test`: [postgresql://localhost:5432](postgresql://localhost:5432).

2. pgAdmin - connect directly to the database using WebUI and user account `login:test@test.test`/`password:test`: [http://localhost:8008](http://localhost:8008). While connecting to the server, don't forget to change the admin user to `test` instead of `postgresql`.

#### Mysql

1. MySQL – connect directly to the database using the admin account `test/test`: [mysql://localhost:3306](mysql://localhost:3306).

2. phpmyadmin - connect directly to the database using WebUI : [http://localhost:8080](http://localhost:8080)

#### Docker-compose

1. [docker-compose.python-searchable.yml](python-searchable/docker-compose.python-searchable.yml) file – read details about configuration and containers used in this example.


### 3. Show me the code!

Take a loot at the complete code of [searchable.py](https://github.com/cossacklabs/acra/blob/master/examples/python/searchable.py).

Let's see how many code lines are necessary to encrypt and search some data using Acra.

1. The app reads JSON data and writes it to the database as usual:
   ```python
    with open(data, 'r') as f:
        data = json.load(f)
    to_escape = ('searchable_name', 'searchable_email')

    for row in rows:
        for k in row:
            if k in to_escape:
                row[k] = row[k].encode('ascii')
        connection.execute(table.insert(), row)
   ```

2. Nothing changes when reading the data from the database:
   ```python
   query = select(table_columns)
   # ...
   rows = connection.execute(query).fetchall()
   ```

3. To search for some values, regular `WHERE` clause is used:
   ```python
   query = select(table_columns)
   
   
    if search_email:
        search_email = search_email.encode('ascii')
        query = query.where(table.c.searchable_email == search_email)

    if search_name:
        search_name = search_name.encode('ascii')
        query = query.where(table.c.searchable_name == search_name)

   rows = connection.execute(query).fetchall()
   ```

> NOTE: We skipped code related to output formatting.

These are all the code changes! 🎉


# Example 12. AcraTranslator usage

Learn more details
about [AcraTranslator](https://docs.cossacklabs.com/acra/acra-in-depth/architecture/acratranslator/#acratranslator-an-api-service)
architecture.

## 1. Installation

```bash
$ curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- acra-translator
```

This command downloads a simple Go API Server application, AcraTranslator, MongoDB, sets up the environment, configures
Go application to encrypt data with AcraTranslator and store to MongoDB, and provides an
API (Swagger) or [Postman Collection](./acra-translator/go-translator-demo/swagger/translator-demo.postman_collection.json) for you to try.

## 2. What's inside

<p align="center"><img src="_pics/translator-demo.png" alt="Go API Server, MongoDB, AcraTranslator architecture" width="560"></p>

**The client-side application** is a simple [Go API server](./acra-translator/go-translator-demo)
that works with a database. The Go API server talks with the database and **AcraTranslator** (via TLS). AcraTranslator **encrypts** the incoming plaintext data, and decrypts the encrypted data. Go API server is responsible to call AcraTranslator and to talk with the database.

### 2.1 Insert data

Currently, Go API server operates with `User` model:

```
type User struct {
	ID              string    
	Firstname       string     `*encrypted*`
	Surname         string     `*encrypted*`
	Zipcode         int32      `*tokenized*`
	Email           string     `*encrypted-searchable*` 
	City            string     
	ResidentCountry string      
	Citizenship     string      
	PhoneNumber     string    
	Notes           string    
	DocPath         *string    
	Birthday        time.Time  
}
```

To insert data, run:

```bash
$ curl -X 'POST' \
  'http://localhost:8008/users' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "birthday": "2023-08-18T08:19:19.816Z",
  "citizenship": "string",
  "city": "string",
  "doc_path": "",
  "email": "test@gmail.com",
  "firstname": "test_name",
  "id": "string",
  "notes": "string",
  "phone_number": "string",
  "resident_country": "string",
  "surname": "test_name",
  "zipcode": 12345
}'
```

Response should contain encrypted data and generated `id`:

```
{
   "data": {
      "id": "0dbcf7d4-e392-4343-a734-e5cf21d3a8a1",
      "firstname": "JSUl0gAAAAAAAADxIiIiIiIiIiJVRUMyAAAALTSaoe8DAbcekMuefGOVaHh6NFTIxG+9p/Mfesc4fjhsRfit1KIgJwQmVAAAAAABAUAMAAAAEAAAACAAAADUyyUrRNMyX8/PAB41JfPjKcE9SabQ0HavLS5/c5EK0gufrhY6jm1cedjet8VgRysCylVjnPgwklcnqjM1AAAAAAAAAAABAUAMAAAAEAAAAAkAAADw8XpRuyx402lAj9mAidHV6L20ZZI/bYxlaY2HZ0YEZkOTHjn+",
      "surname": "JSUl0gAAAAAAAADxIiIiIiIiIiJVRUMyAAAALT7unFkC+MAG++BMKn244P7aEDzCz6lXoPyzGxGh9ADk46mJFIUgJwQmVAAAAAABAUAMAAAAEAAAACAAAADXrFhjVuB7hh/t49ZSsbmuvUujzkzly/w9fyRrT1nTmqU3BBfkqVeYJE9deLWVmJsCscwC82ZLCPhKrvs1AAAAAAAAAAABAUAMAAAAEAAAAAkAAADvyNVyouPV4XicLncCeG31zLH41RgYxfE73qaU9W0ZECj+Hy1G",
      "zipcode": 178850713,
      .....
   }
}
```

### 2.2 Read data

To read the data by `id`, use the id value received from the insert response:

```bash
$ curl -X 'GET' \
  'http://localhost:8008/users/{id-from-response}' \
  -H 'accept: application/json'
```

The data should be decrypted:

```
{
   "data": {
      "firstname": "test_name",
      "surname": "test_name",
      "zipcode": 12345,
      ...
   }
}
```

AcraTranslator logs should contain info about successful decryption of the data:

```bash
docker logs --tail 50  acra-translator_acra-translator_1
...

2023/08/18 - 08:38:55 | 200 |     138.314µs |      172.26.0.3 | POST     "/v2/decryptSymSearchable"
2023/08/18 - 08:38:55 | 200 |      123.47µs |      172.26.0.3 | POST     "/v2/detokenize"
```

### 2.2 Search encrypted data

Data could be read by searchable data, stored encrypted in DB.

Server will call the translator to get searchable hash and then read the data from the DB:
```
	mongo.Pipeline{
		{
			{"$match", bson.D{{
				Key: "$expr",
				Value: bson.D{{
					Key: "$eq",
					Value: bson.A{bson.D{{
						Key:   "$substr",
						Value: []interface{}{"$email", 0, len(emailSearchHash)},
					}}, email}},
				}},
			}}},
	}
```

```bash
curl -X 'GET' \
  'http://localhost:8008/users/search/{email-from-insert-request}' \
  -H 'accept: application/json'
```

The data should be decrypted:

```
{
   "data": {
      "firstname": "test_name",
      "surname": "test_name",
      "zipcode": 12345,
      ...
   }
}
```


### 2.4 File encryption

AcraTranslator could be also used for file encryption/decryption.

```bash
curl -X 'PUT' \
  'http://localhost:8008/users/{user-id}/docs' \
  -H 'Accept: application/json' \
  -H 'Content-Type: multipart/form-data' \
  -F 'file=@image.png;type=image/png'
```

You should be able to see the path of encrypted file stored on file system under `data.doc_path`:

```
{
  "data": {
    "doc_path": "/tmp/0dbcf7d4-e392-4343-a734-e5cf21d3a8a1495524684",
  }
}
```

To see the actual content of the file:

```
docker exec -it acra-translator_go-api-server_1 cat /tmp/0dbcf7d4-e392-4343-a734-e5cf21d3a8a1495524684
```

You should see the base64 encoded gibberish on the screen.

To decrypt the file, just call:

```
curl -X 'GET' \
  'http://localhost:8008/users/{user-id}/docs' \
  -H 'accept: multipart/' > image.png
```

The `image.png` should contain the same file that was uploaded and encrypted.

### 2.5 Read data from the database

To jump to MongoDB cli interface:

```
docker exec -it acra-translator_mongo_1 mongosh "mongodb://root:password@mongo:27017/admin?authSource=admin"
```

Run command to see the actual state of the data stored in DB:

```
db.users.find()
```

Playground also contains the WebUI connected to MongoDB. Its available on `http://localhost:8081/` with BasicAuth:
*test*/*test*.

---

# Further steps

Let us know if you have any questions by dropping an email to [dev@cossacklabs.com](mailto:dev@cossacklabs.com).

1. [Acra website](https://cossacklabs.com/acra/) – learn about all Acra features, defense in depth, how it's better than "just TLS" and available licenses.
2. [Acra Community Edition](https://github.com/cossacklabs/acra) – Acra Community Edition repository.
3. [Acra docs](https://docs.cossacklabs.com/acra/what-is-acra/) – all Acra docs and guides.

# Need help?

Need help in configuring Acra? Read more about [support options and Acra Enterprise Edition](https://www.cossacklabs.com/acra/#pricing).
