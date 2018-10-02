# What is this?

Acra Engineering Demo illustrates how to integrate Acra data protection into your existing application. Protecting data is completely transparent for the users and requires minimum changes of infrastructure.

**Integrating Acra into any application contains 3 steps:**

1. **Generate encryption keys**. For this example we will generate one storage keypair (for encrypting and decrypting data), and two transport keypairs (for secure connection between AcraServer and AcraConnector). 
2. **Integrate AcraWriter** – the client-side library – into the application (web or mobile app). AcraWriter encrypts data using storage public key, then application writes data to the database. Application reads decrypted data from AcraConnector.
3. **Deploy server-side infrastructure**: AcraConnector and AcraServer.  
      1. AcraConnector ensures transport protection between client app and AcraServer. AcraConnector is deployed as close as possible to the AcraWriter (ideally at the same host), and uses own transport keypair and AcraServer's public key to encrypt transport.
      2. AcraServer receives reading request from application through AcraConnector, makes sure it's legit, fetches data from database, decrypts it and returns to the AcraConnector. AcraServer is separate container and connected to the database and AcraConnector. AcraServer uses storage private key to decrypt the data, own transport keypair and AcraConnector's public key to encrypt transport.

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

```bash
echo "$SERVER_IP www.djangoproject.example" >> /etc/hosts
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
  python /app/example_with_zone.py --data="top secret data"
  
$:
data: top secret data
zone: DDDDDDDDFidFDxORlrleaUrC
```

Call [`example_with_zone.py`](https://github.com/cossacklabs/acra/blob/master/examples/python/example_with_zone.py) to encrypt "top secret data" with specific [Zone](https://docs.cossacklabs.com/pages/documentation-acra/#zones). Application generates Zones using AcraServer HTTP API, then uses Zone public key and Zone Id for encryption.

### 2.2 Read data

Read data using same ZoneId. AcraServer decrypts data and returns plaintext:

```bash
docker exec -it python_python_1 \
  python /app/example_with_zone.py --print --zone_id=DDDDDDDDFidFDxORlrleaUrC

$:
use zone_id:  DDDDDDDDFidFDxORlrleaUrC
id  - zone - data - raw_data
1   - DDDDDDDDFidFDxORlrleaUrC - top secret data - top secret data
```

Output contains Zone Id, decrypted `data`, and `raw_data` (stored in plaintext for the demo purposes),

### 2.3 Read data directly from database

To make sure that data is stored encrypted, read it directly from the database:

```bash
docker exec -it python_python_1 \
  python /app/example_with_zone.py --print --zone_id=DDDDDDDDFidFDxORlrleaUrC --host=postgresql --port=5432
  
$:
use zone_id:  DDDDDDDDkOGnRsCBZEwXnHlL
id  - zone - data - raw_data
1   - DDDDDDDDkOGnRsCBZEwXnHlL - """"""""UEC2-CVs-K)'9@gJ-0 '&T@ {W|SҡϛڱY+:uKn"3Wɕ|Ict'JGCW;@ ̛W]aPI|Z ~*vI] - top secret data
```

As expected, noone decrypts the `data`, `raw_data` is stored as plaintext and didn't change.

### 2.4 Connect to database from web

1. Log into web PostgreSQL interface [http://$HOST:8008](http://127.0.0.1:8008) using user/password: test/test. 
`$HOST` is the IP address of the server with running Acra Engineering Demo (if you run demo on your machine, set "127.0.0.1").

2. Find table and data rows.

<img src="_pics/db_web_python.png" width="700">

3. Read content of `data` field – it's encrypted!

So, data is stored encrypted, but it is transparent for python application.

### 2.5 Encrypt data without Zones

Using [Zones](https://docs.cossacklabs.com/pages/documentation-acra/#zones) provides compartmentalization, because different users of the same app will have different encryption keys. However, it's possible to use AcraServer without Zones.

1. Disable Zones in AcraWebConfig. Open [http://$HOST:8001](http://127.0.0.1:8001) and tap "No" for "zone mode".

<img src="_pics/acra_web_config_python.png" width="800">

2. Write and read data:

```bash
docker exec -it python_python_1 \
  python /app/example_without_zone.py --data="secret data without zones"
  
$:
insert data: secret data without zones

docker exec -it python_python_1 \
  python /app/example_without_zone.py --print   

$:                        
id  - data                 - raw_data
2   - secret data without zones - secret data without zones
```

AcraServer decrypts either AcraStructs with Zones, or without Zones at the same time. Sending different kinds of AcraStructs without changing mode will lead to decryption errors.

### 2.5 Other available resources

1. PostgreSQL – you can connect to DB directly using admin account `postgres/test`: [postgresql://$HOST:5432](postgresql://127.0.0.1:5432).

2. Prometheus – examine the collected metrics: [http://$HOST:9090](http://127.0.0.1:9090).

3. Grafana - see dashboards with Acra metrics: [http://$HOST:3000](http://127.0.0.1:3000).

4. AcraConnector – send some data through AcraConnector directly: [tcp://$HOST:9494](tcp://127.0.0.1:9494).

5. AcraWebConfig – configure AcraServer remotely (for example, disable intrusion detection) using default account `test/test`: [http://$HOST:8001](http://127.0.0.1:8001).

6. [Docker-compose.python.yml](https://github.com/cossacklabs/acra-engineering-demo/blob/master/python/docker-compose.python.yml) file describes all configuration and containers for this example.  

 
## 3. Show me code!

Take a look on the full code of [`example_with_zone.py`](https://github.com/cossacklabs/acra/blob/master/examples/python/example_with_zone.py) and [`example_without_zone.py`](https://github.com/cossacklabs/acra/blob/master/examples/python/example_without_zone.py).

Let's see how many code lines are needed to encrypt data using Acra. We will look on example with Zones, because it's more coplicated and requires additional API call to fetch Zone.

1. App gets Zone using AcraServer API:

```python
def get_zone():
    response = urlopen('{}/getNewZone'.format(ACRA_CONNECTOR_API_ADDRESS))
    json_data = response.read().decode('utf-8')
    zone_data = json.loads(json_data)
    return zone_data['id'], b64decode(zone_data['public_key'])
```

2. App uses ZoneId and Zone public key for encrypting data

```python
encrypted_data = create_acrastruct(
  data.encode('utf-8'), key, zone_id.encode('utf-8'))
```

and writes data to the database as usual:

```python
connection.execute(
    test_table.insert(), data=encrypted_data,
    zone_id=zone_id.encode('utf-8'),
    raw_data=data)
```

3. Reading data from database is not changed:

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

# Further steps

Let us know if you have any questions by dropping email to [dev@cossacklabs.com](mailto:dev@cossacklabs.com).

1. [cossacklabs/acra](https://github.com/cossacklabs/acra) – main Acra repository contains tons of examples and documentation.
2. [Acra Live Demo](https://www.cossacklabs.com/acra/#acralivedemo) – is a web-based demo of a typical web-infrastructure protected by Acra and deployed on our servers for your convenience. It shows other features like SQL firewall, intrusion detection, database rollback and so on.
