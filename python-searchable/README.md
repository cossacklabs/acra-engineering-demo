# Search in encrypted data

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
