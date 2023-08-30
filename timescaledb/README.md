# Transparent encryption, TimescaleDB

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
