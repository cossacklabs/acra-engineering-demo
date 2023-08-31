# Client-side encryption, python app, PostgreSQL

Python client application, client-side encryption, AcraServer, PostgreSQL database.

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
docker exec -it python_python_1 python /app/example.py --data="some secret info" \
--public_key=/app.acrakeys/28fa1ef8aa3184d7ce0621341299d74b5b561a95aecdee3b46b847d63495f800d276cdd1233f5950efb348113f2892ceef4b354abed383d8afc026901854ca28_storage.pub

$:
insert data: some secret info
```

Call the [`example.py`](https://github.com/cossacklabs/acra/blob/master/examples/python/example.py) to encrypt the "top secret data" with a specific public key mounted to container, used for client-side encryption.

### 2.2 Read data

```bash
docker exec -it python_python_1 python /app/example.py --print \
--public_key=/app.acrakeys/28fa1ef8aa3184d7ce0621341299d74b5b561a95aecdee3b46b847d63495f800d276cdd1233f5950efb348113f2892ceef4b354abed383d8afc026901854ca28_storage.pub

$:
id  - data                 - raw_data
1   - some secret info     - some secret info
```

The output contains the decrypted `data`, and `raw_data` (stored in plaintext for the demo purposes),

### 2.3 Read data with different ClientID

Read the data using a different ClientID. AcraServer will not decrypt the data and return the default data:

```bash
docker exec -it python_python_1 python /app/example.py --print \
--public_key=/app.acrakeys/28fa1ef8aa3184d7ce0621341299d74b5b561a95aecdee3b46b847d63495f800d276cdd1233f5950efb348113f2892ceef4b354abed383d8afc026901854ca28_storage.pub \
--tls_cert=/ssl/acra-client2.crt \
--tls_key=/ssl/acra-client2.key

$:
id  - data                 - raw_data
1   - test-data            - some secret info
```

As a result data field will be replaced on `test-data` according to [/app/encryptor_config.yaml](https://github.com/cossacklabs/acra/blob/master/examples/python/encryptor_config.yaml#L53) config.

### 2.4 Read the data directly from the database

To make sure that the data is stored in an encrypted form, read it directly from the database:

```bash
docker exec -it python_python_1 python /app/example.py --print  --host=postgresql --port=5432 \
--public_key=/app.acrakeys/28fa1ef8aa3184d7ce0621341299d74b5b561a95aecdee3b46b847d63495f800d276cdd1233f5950efb348113f2892ceef4b354abed383d8afc026901854ca28_storage.pub

$:
id  - data                 - raw_data
1   - """"""""UEC2-\b5Sfhw֝&|/d= '&T@
                                      )lC5bb'%}iT{:Klꈾy5%196';C><@;@
                                                                     E?}ZD՝<e0M|ɺ]+k\݂<J - top secret data
```

As expected, no entity decrypts the `data`. The `raw_data` is stored as plaintext so nothing changes.

### 2.5 Connect to the database from the web

1. Log into web PostgreSQL interface [http://localhost:8008](http://localhost:8008) using user/password: `test@test.test`/`test`.

2. Find the table and the data rows.

<img src="_pics/db_web_python.png" width="700">

3. Try reading the content of `data` field – it's encrypted!

So, the data is stored in an encrypted form, but it is transparent for the Python application.

### 2.6 Other available resources

1. PostgreSQL – connect directly to the database using the admin account `postgres/test`: [postgresql://localhost:5432](postgresql://localhost:5432).

2. pgAdmin - connect directly to the database using WebUI and user account `login:test@test.test`/`password:test`: [http://localhost:8008](http://localhost:8008)

3. Prometheus –  examine the collected metrics: [http://localhost:9090](http://localhost:9090).

4. Grafana – see the dashboards with Acra metrics: [http://localhost:3000](http://localhost:3000).

5. Jaeger – view traces: [http://localhost:16686](http://localhost:16686).

6. [Docker-compose.python.yml](https://github.com/cossacklabs/acra-engineering-demo/blob/master/python/docker-compose.python.yml) file – read details about configuration and containers used in this example.

## 3. Show me the code!

Take a look at the complete code of [`example.py`](https://github.com/cossacklabs/acra/blob/master/examples/python/example.py).

Let's see how many code lines are necessary to encrypt some data using Acra.

1. The app uses public key to encrypt the data –

```python
encrypted_data = create_acrastruct(args.data.encode('utf-8'), encryption_key)
```

and writes the data to the database as usual:

```python
connection.execute(test_table.insert(), data=data.encode('utf-8'), raw_data=data)
```

2. Nothing changes when reading the data from the database:

```python
result = connection.execute(select([test_table]))
result = result.fetchall()

for row in result:
   print("{:<3} - {:<20} - {}".format(row['id'], row['data'].decode(
      "utf-8", errors='ignore'), row['raw_data']))
```

These are all the code changes! 🎉

---
