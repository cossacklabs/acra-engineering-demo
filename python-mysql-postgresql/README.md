# Transparent encryption, Python app, MySQL, PostgreSQL

Python client application, transparent encryption/decryption/masking/tokenization, AcraServer, MySQL and PostgreSQL databases.

## 1. Installation

### Transparent encryption mode

```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- python-mysql-postgresql
```

This command downloads a simple Python application that stores the data in a database, Acra Docker containers, MySQL, PostgreSQL
databases, sets up the environment, configures python application to connect to Acra, and provides a list of links for you to try.

## 2. What's inside

<p align="center"><img src="../_pics/eng_demo_python-no-ac.png" alt="Protecting simple python application: Acra architecture" width="560"></p>

**The client application** is a simple [python console application](https://github.com/cossacklabs/acra/tree/master/examples/python)
that works with a database. The application talks with the database via Acra, Acra **encrypts** the data before sending
it to a database, and decrypts the data when the app reads it from the database. Same it does transparently with tokenized data.

### 3. MySQL Transparent Encryption

By default in this demo, Acra configured to work with MySQL database.

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

<img src="../_pics/python_mysql_phpmyadmin.png" width="700">

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

Log into the web PostgreSQL interface [http://localhost:8008](http://localhost:8008) using user/password: `test@test.test`/`test`.

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
def print_data(connection, columns, table=test_table):
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
