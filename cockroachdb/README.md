# Transparent encryption, python app, CockroachDB

Python client application, AcraServer transparent encryption, CockroachDB  database.

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


### 2.1 Insert data

Script reads data from `data.json` where stored array of entries as data examples.

```bash
docker exec -it cockroachdb_python_1 python3 extended_example.py --host=acra-server --port=9393 --data=data.json

$:
data: [{'token_i32': 1234, 'token_i64': 645664, 'token_str': '078-05-1111', 'token_bytes': 'byt13es', 'token_email': 'john_wed@cl.com', 'data': 'John Wed, Senior Relationshop Manager', 'masking': '$112000', 'searchable': 'john_wed@cl.com'}, {'token_i32': 1235, 'token_i64': 645665, 'token_str': '078-05-1112', 'token_bytes': 'byt13es2', 'token_email': 'april_cassini@cl.com', 'data': 'April Cassini, Marketing Manager', 'masking': '$168000', 'searchable': 'april_cassini@cl.com'}, {'token_i32': 1236, 'token_i64': 645667, 'token_str': '078-05-1117', 'token_bytes': 'byt13es3', 'token_email': 'george_clooney@cl.com', 'data': 'George Clooney, Famous Actor', 'masking': '$780000', 'searchable': 'george_clooney@cl.com'}]
```

### 2.2 Read data

AcraServer decrypts the data and returns plaintext:
```bash
docker exec -it cockroachdb_python_1 python3 extended_example.py --host=acra-server --port=9393 --print
  
$:
Fetch data by query {}
 SELECT test.id, test.data_str, test.masking, test.token_i32, test.data_i32, test.token_i64, test.data_i64, test.token_str, test.token_bytes, test.token_email 
FROM test
3
id  - data_str - masking - token_i32 - data_i32 - token_i64 - data_i64 - token_str - token_bytes - token_email
895346246447497217 - John Wed, Senior Relationshop Manager - $112000 - 1234 - 1234 - 645664 - 645664 - 078-05-1111 - byt13es - john_wed@cl.com
895346246536495105 - April Cassini, Marketing Manager - $168000 - 1234 - 1234 - 645664 - 645664 - 078-05-1112 - byt13es2 - april_cassini@cl.com
895346246694207489 - George Clooney, Famous Actor - $780000 - 1234 - 1234 - 645664 - 645664 - 078-05-1117 - byt13es3 - george_clooney@cl.com

```

### 2.3 Read the data directly from the database
To make sure that the data is stored in an encrypted form, read it directly from the database. Use `--port=26257` and --host=`roach1`:

```bash
docker exec -it cockroachdb_python_1 python3 extended_example.py --host=roach1 --port=26257 --print

$:
Fetch data by query {}
 SELECT test.id, test.data_str, test.masking, test.token_i32, test.data_i32, test.token_i64, test.data_i64, test.token_str, test.token_bytes, test.token_email 
FROM test
3
id  - data_str - masking - token_i32 - data_i32 - token_i64 - data_i64 - token_str - token_bytes - token_email
895033813588869121 - <memory at 0x7ff6607de280> - <memory at 0x7ff6607dea00> - 1980030424 - <memory at 0x7ff6607deac0> - -7885492195662891049 - <memory at 0x7ff6607deb80> - QFzwmjyhzTn - ne    - TTC6JX@eS7k8.de
...
```
Where ` <memory at 0x....>` is python's representation of binary data returned from the database.

### 2.4 Other available resources

1. CockroachDB – connect directly to the database using the user `root` and DB `defaultdb`: [postgresql://localhost:26257](postgresql://localhost:26257).

2. Prometheus –  examine the collected metrics: [http://localhost:9090](http://localhost:9090).

3. Grafana – see the dashboards with Acra metrics: [http://localhost:3000](http://localhost:3000).

4. Jaeger – view traces: [http://localhost:16686](http://localhost:16686).

5. [Docker-compose.python.yml](https://github.com/cossacklabs/acra-engineering-demo/blob/master/cockroachdb/docker-compose.cockroachdb.yml) file – read details about configuration and containers used in this example.
