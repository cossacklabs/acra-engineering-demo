# Migration process, python app, PostgreSQL

Python client application, DB migration, AcraServer, PostgreSQL database.

## 1. Installation

```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- db-acra-migration
```

This command downloads a simple Python application that run data migration in a database, Acra Docker containers, PostgreSQL database, sets up the environment, configures python application that run migration process, and provides a list of links for you to try.

## 2. What's inside

**Migration script** is a simple [python console application](https://github.com/cossacklabs/acra-engineering-demo/blob/master/db-acra-migration/python) that works with a database. The application **generate** the data in by copying data from [`users.csv`](https://github.com/cossacklabs/acra-engineering-demo/blob/master/db-acra-migration/python/users.csv) file .The application **migrate** the plaintext data with Acra.

### 2.1 Generate data

```bash
 docker exec -it db-acra-migration_python_1 python /app/migration.py --generate --port=5432 --host=postgresql

$:
Data generated successfully!
```

Call the [`migration.py`](https://github.com/cossacklabs/acra-engineering-demo/blob/master/db-acra-migration/python/migration.py) to create bunch of test data used for migration.

SQL used to store data ([`users.csv`](https://github.com/cossacklabs/acra-engineering-demo/blob/master/db-acra-migration/python/users.csv)) to DB:

```
COPY users (id,phone_number,ssn,email,firstname,lastname,age) FROM STDIN WITH (FORMAT CSV, HEADER)
```

Read data directly from DB (password `test`). You should see a bunch of generated test data:

```bash
docker exec -it db-acra-migration_python_1 psql -h postgresql -U postgres -d test -c "SELECT * from users limit 10";


$:
id | phone_number |    ssn    |             email             | firstname |  lastname  | age 
----+--------------+-----------+-------------------------------+-----------+------------+-----
  0 | 8201931087   | 600268041 | josiahharris@lubowitz.info    | Wayne     | Stehr      |  29
  1 | 5788345157   | 809025969 | carolynbashirian@stanton.com  | Gerardo   | Eichmann   |  50
  2 | 6281630684   | 762376292 | tinadickinson@farrell.com     | Ralph     | Schoen     |  46
  3 | 2572577764   | 996643249 | ottilieruecker@konopelski.com | Dylan     | Schiller   |  46
  4 | 7923022562   | 854151949 | garnettvandervort@denesik.org | Darius    | McKenzie   |  20
  ....
```

### 2.3 Update DB

Change DB data types to `bytea` as Acra requires it to store ciphertext. 

Note, that `age` and `email` remains the same as will be used for tokenization and data type changing is not needed.

```bash
docker exec -it db-acra-migration_python_1 psql -h postgresql -U postgres -d test -c "ALTER TABLE users
ALTER COLUMN phone_number TYPE bytea using phone_number::bytea,
    ALTER COLUMN ssn TYPE bytea using ssn::bytea,
    ALTER COLUMN firstname TYPE bytea using firstname::bytea,
    ALTER COLUMN lastname TYPE bytea using lastname::bytea;
"

$:
ALTER TABLE;
```

As a result, you should see plaintext data in binary format:

```bash
docker exec -it db-acra-migration_python_1 psql -h postgresql -U postgres -d test -c "SELECT * from users limit 10";

$:
 id |      phone_number      |         ssn          |             email             |     firstname      |        lastname        | age 
----+------------------------+----------------------+-------------------------------+--------------------+------------------------+-----
  0 | \x38323031393331303837 | \x363030323638303431 | josiahharris@lubowitz.info    | \x5761796e65       | \x5374656872           |  29
  1 | \x35373838333435313537 | \x383039303235393639 | carolynbashirian@stanton.com  | \x4765726172646f   | \x456963686d616e6e     |  50
  2 | \x36323831363330363834 | \x373632333736323932 | tinadickinson@farrell.com     | \x52616c7068       | \x5363686f656e         |  46
```


### 2.4 Migrate data

Run migration with ` --migrate` param. Script will migrate data gradually with 100 items:

```bash
docker exec -it db-acra-migration_python_1 python3 /app/migration.py --migrate

$:
Running migration for 1001 rows:
Migrated 0 items
Migrated 100 items
Migrated 200 items
Migrated 300 items
Migrated 400 items
.....
.....
```

After migration is completed, read the DB to see the actual state of the data. You should see ciphertext.

```bash
docker exec -it db-acra-migration_python_1 psql -h postgresql -U postgres -d test -c "SELECT * from users limit 10";
```

To get actual data, read it from Acra directly with `--print` param:

```bash
docker exec -it db-acra-migration_python_1 python /app/migration.py --print

$:
0   - 8201931087 - 600268041 - josiahharris@lubowitz.info - Wayne - Stehr - 29
1   - 5788345157 - 809025969 - carolynbashirian@stanton.com - Gerardo - Eichmann - 50
2   - 6281630684 - 762376292 - tinadickinson@farrell.com - Ralph - Schoen - 46
3   - 2572577764 - 996643249 - ottilieruecker@konopelski.com - Dylan - Schiller - 46
```

### 2.5 Connect to the database from the web

1. Log into web PostgreSQL interface [http://localhost:8008](http://localhost:8008) using user/password: `test@test.test`/`test`.

2. Find the table and the data rows.

<img src="../_pics/db_web_migration.png.png" width="700">


### 2.6 Other available resources

1. PostgreSQL – connect directly to the database using the admin account `postgres/test`: [postgresql://localhost:5432](postgresql://localhost:5432).

2. pgAdmin - connect directly to the database using WebUI and user account `login:test@test.test`/`password:test`: [http://localhost:8008](http://localhost:8008)

3. [Docker-compose.python.yml](https://github.com/cossacklabs/acra-engineering-demo/blob/master/db-acra-migration/docker-compose.db-acra-migration.yml) file – read details about configuration and containers used in this example.

## 3. Show me the code!

Take a look at the complete code of [`migration.py`](https://github.com/cossacklabs/acra-engineering-demo/blob/master/db-acra-migration/migration.py).

---
