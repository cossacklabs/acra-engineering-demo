# What is this?

Acra Engineering Demo illustrates the integration of [Acra data protection suite](https://github.com/cossacklabs/acra) into your existing application. Protecting the data is completely transparent for the users and requires minimal changes in the infrastructure.

This demo has two examples:

| [Protecting Django app](https://github.com/cossacklabs/acra-engineering-demo#protecting-data-on-django-based-web-site) | [Protecting CLI python app](https://github.com/cossacklabs/acra-engineering-demo#protecting-data-in-a-python-cli-database-applicationn) | [Protecting Ruby Rails app](https://github.com/cossacklabs/acra-engineering-demo#protecting-data-in-a-rails-application) |
|---|---|---|

**Integrating Acra into any application requires 3 steps:**

1. **Generation of encryption keys**. For this example, we will generate one storage keypair (for encryption/decryption of the data) and two transport keypairs (for a secure connection between AcraServer and AcraConnector).
2. **Integration of AcraWriter** – the client-side library – into the application (web or mobile app). AcraWriter encrypts the data using storage public key. The application then writes the data to the database. The application reads the decrypted data from AcraConnector.
3. **Deploy server-side infrastructure**: AcraConnector and AcraServer.
      1. AcraConnector ensures transport protection between the client app and AcraServer. AcraConnector is deployed as close as possible to AcraWriter (ideally, at the same host) and uses its own transport keypair and AcraServer's public key to encrypt the transport.
      2. AcraServer receives a reading request from application through AcraConnector, makes sure it's legit, fetches the data from the database, decrypts it, and returns to the AcraConnector. AcraServer is a separate container and is connected to the database and AcraConnector. AcraServer uses the storage's private key to decrypt the data and its own transport keypair and AcraConnector's public key to encrypt transport.

Please refer to the [Acra/Readme documentation](https://github.com/cossacklabs/acra#protecting-data-in-sql-databases-using-acrawriter-and-acraserver) for more detailed description and schemes (or you can find the [same entry](https://docs.cossacklabs.com/pages/documentation-acra/#protecting-data-using-acra) and all the other current documentation for Acra on the dedicated [Cossack Labs Documentation Server](https://docs.cossacklabs.com/products/acra/)).

---

# Protecting data on Django-based web site

## 1. Installation

Asymmetric mode, encryption on the application side, decryption on the AcraServer:
```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- django
```

Transparent mode, both encryption and decryption on the AcraServer:
```bash
export ACRA_DOCKER_IMAGE_TAG='master'
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- django-transparent
```

> Note: Transparent mode is not publicly released yet, please use `ACRA_DOCKER_IMAGE_TAG='master'` to build demo project using Acra from master branch.

This command downloads the code of Django website example, Acra Docker containers, PostgreSQL database, sets up the environment, and provides a list of links for you to try.

## 2. What's inside

**The client application** is the famous Django app example – the source code of [djangoproject.com](https://www.djangoproject.com/). We've [updated their source code](https://github.com/cossacklabs/djangoproject.com) to protect blog posts.

### Asymmetric mode

<p align="center"><img src="_pics/eng_demo_django.png" alt="Protecting Django web application: Acra architecture (asymmetric mode)" width="700"></p>

Django app **encrypts** the sensitive fields of blog posts into separate AcraStructs (author name, author email, content are encrypted; blog post ID and title are in plaintext).

Django app writes AcraStructs to the database and **reads the decrypted posts** through AcraConnector and AcraServer (which pretends to be a database).

### Transparent mode

<p align="center"><img src="_pics/eng_demo_django_transparent_encr.png" alt="Protecting Django web application: Acra architecture (transparent mode)" width="700"></p>

Django app **does not encrypt** the sensitive fields, it just passes data through AcraConnector to AcraServer (which pretends to be a database). AcraServer **encrypts** these sensitive fields and stores them into database.

Django app **reads the decrypted posts** from the database through AcraConnector and AcraServer.


In both cases from the users' perspective, the website works as it used to. However, the blog posts are protected now.

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

Open Grafana dashboards to see the performance stats of AcraServer and AcraConnector. We collect following metrics: the number of decrypted AcraStructs, request and response processing time.

Grafana is available at [http://www.djangoproject.example:3000](http://www.djangoproject.example:3000).

<img src="_pics/django_monitoring.png" width="900">

### 2.5 View traces

Both AcraServer and AcraConnector can export detailed traces to Jaeger. Use this data to optimize the performance of the entire system.

Jaeger is available at [http://www.djangoproject.example:16686](http://www.djangoproject.example:16686).

<img src="_pics/jaeger_traces.png" width="900">

### 2.6 Other available resources

There's more to explore:

1. PostgreSQL – connect directly to the database using the admin account `postgres/test`: [postgresql://www.djangoproject.example:5432](postgresql://www.djangoproject.example:5432).

2. Prometheus –  examine the collected metrics: [http://www.djangoproject.example:9090](http://www.djangoproject.example:9090).

3. AcraConnector – send some data directly through AcraConnector: [tcp://www.djangoproject.example:9494](tcp://www.djangoproject.example:9494).

4. AcraWebConfig – configure AcraServer remotely (i.e. disable intrusion detection) using the default account `test/test`: [http://www.djangoproject.example:8001](http://www.djangoproject.example:8001).

5. [Docker-compose.django.yml](https://github.com/cossacklabs/acra-engineering-demo/blob/master/django/docker-compose.django.yml) file – read details about configuration and containers used in this example.

## 3. Show me the code!

So, was it easy to integrate Acra into Django application? Sure it was!

### Asymmetric mode

You can [compare our repo to the original repo](
https://github.com/django/djangoproject.com/compare/master...cossacklabs:master) and see how few changes we introduced:

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

### Transparent mode

1. AcraServer returns binary data, so [we wrote simple wrapper classes](https://github.com/cossacklabs/acra-engineering-demo/blob/master/django-transparent/configs/fields.py) to perform encoding and decoding data.

2. [We changed original fields types to new ones](https://github.com/cossacklabs/acra-engineering-demo/blob/master/django-transparent/configs/models.py.patch).

3. Created [database migration file](https://github.com/cossacklabs/acra-engineering-demo/blob/master/django-transparent/configs/0003_encrypt.py) to convert encrypted fields to binary.

Those are all the code changes! 🎉

---

# Protecting data in a Python CLI database application

## 1. Installation

```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- python
```

This command downloads a simple Python application that stores the data in a database, Acra Docker containers, PostgreSQL database, sets up the environment, and provides a list of links for you to try.

## 2. What's inside

<p align="center"><img src="_pics/eng_demo_python.png" alt="Protecting simple python application: Acra architecture" width="560"></p>

**The client application** is a simple [python console application](https://github.com/cossacklabs/acra/tree/master/examples/python) that works with a database. The application **encrypts** the data in AcraStructs before sending it to a database. The application **reads** the decrypted data through AcraConnector and AcraServer (that are transparent for the application).

### 2.1 Write data

```bash
docker exec -it python_python_1 \
  python /app/example_with_zone.py --data="top secret data"

$:
data: top secret data
zone: DDDDDDDDFidFDxORlrleaUrC
```

Call the [`example_with_zone.py`](https://github.com/cossacklabs/acra/blob/master/examples/python/example_with_zone.py) to encrypt the "top secret data" with a specific [Zone](https://docs.cossacklabs.com/pages/documentation-acra/#zones). The application generates Zones using AcraServer HTTP API, then it uses Zone public key and Zone Id for encryption.

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

### 2.3 Read the data directly from the database

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

### 2.4 Connect to the database from the web

1. Log into web PostgreSQL interface [http://$HOST:8008](http://127.0.0.1:8008) using user/password: `test@test.test`/`test`.
`$HOST` is the IP address of the server where Acra Engineering Demo is running (if you run the demo on your machine, set it to "127.0.0.1").

2. Find the table and the data rows.

<img src="_pics/db_web_python.png" width="700">

3. Try reading the content of `data` field – it's encrypted!

So, the data is stored in an encrypted form, but it is transparent for the Python application.

### 2.5 Encrypt the data without Zones

Usage of [Zones](https://docs.cossacklabs.com/pages/documentation-acra/#zones) provides compartmentalisation as different users of the same app will have different encryption keys. However, it's possible to [use AcraServer without Zones](https://docs.cossacklabs.com/pages/documentation-acra/#running-acraserver-in-zone-mode).

1. To disable Zones in AcraWebConfig, open [http://$HOST:8001](http://127.0.0.1:8001) using the default account `test/test` and tap "No" for "zone mode".

<img src="_pics/acra_web_config_python.png" width="800">

2. Write and read the data:

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

> Note: AcraServer decrypts either AcraStructs with Zones or without Zones at the same time. Sending different kinds of AcraStructs without changing the mode will lead to decryption errors.

### 2.5 Other available resources

1. PostgreSQL – connect directly to the database using the admin account `postgres/test`: [postgresql://$HOST:5432](postgresql://127.0.0.1:5432).

2. Prometheus – examine the collected metrics: [http://$HOST:9090](http://127.0.0.1:9090).

3. Grafana – see the dashboards with Acra metrics: [http://$HOST:3000](http://127.0.0.1:3000).

4. AcraConnector – send some data directly through AcraConnector: [tcp://$HOST:9494](tcp://127.0.0.1:9494).

5. AcraWebConfig – configure AcraServer remotely (i.e. disable intrusion detection) using the default account `test/test`: [http://$HOST:8001](http://127.0.0.1:8001).

6. Jaeger – view traces: [http://$HOST:16686](http://127.0.0.1:16686).

7. [Docker-compose.python.yml](https://github.com/cossacklabs/acra-engineering-demo/blob/master/python/docker-compose.python.yml) file – read details about configuration and containers used in this example.

## 3. Show me the code!

Take a look at the complete code of [`example_with_zone.py`](https://github.com/cossacklabs/acra/blob/master/examples/python/example_with_zone.py) and [`example_without_zone.py`](https://github.com/cossacklabs/acra/blob/master/examples/python/example_without_zone.py).

Let's see how many code lines are necessary to encrypt some data using Acra. We will look at the example with Zones because it's more complicated and requires additional API call to fetch Zone.

1. The app gets a Zone using [AcraServer API](https://docs.cossacklabs.com/pages/documentation-acra/#client-side-with-zones):

```python
def get_zone():
    response = urlopen('{}/getNewZone'.format(ACRA_CONNECTOR_API_ADDRESS))
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

# Protecting data in a Rails application

## 1. Installation

```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- rails
```

This command downloads a Rails application that stores data in a database, Acra Docker containers, PostgreSQL database, sets up the environment, and provides a list of links for you to try.

## 2. What's inside


**The client application** is a [rubygems.org fork](https://github.com/cossacklabs/rubygems.org) that works with a database. The application **encrypts** the data in AcraStructs before sending it to a database. The application **reads** the decrypted data through AcraConnector and AcraServer (that are transparent for the application).

### 2.1 Prepare

1. Sign up with any fictional account at [sign_up page](http://www.rubygems.example:8000/sign_up) of the app. That credentials will be used later when uploading gem.

2. The application we are deploying is gem storage, so we have to build gem that we will use in testing.

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

1. PostgreSQL – connect directly to the database using the admin account `rubygems`/`rubygems`: [postgresql://www.rubygems.example:5432](postgresql://www.rubygems.example:5432).

2. Prometheus – examine the collected metrics: [http://www.rubygems.example:9090](http://www.rubygems.example:9090).

3. Grafana – see the dashboards with Acra metrics: [http://www.rubygems.example:3000](http://www.rubygems.example:3000).

4. AcraConnector – send some data directly through AcraConnector: [tcp://www.rubygems.example:9494](tcp://www.rubygems.example:9494).

5. AcraWebConfig – configure AcraServer remotely (i.e. disable intrusion detection) using the default account `test`/`test`: [http://www.rubygems.example:8001](http://www.rubygems.example:8001).

6. Jaeger – view traces: [http://www.rubygems.example:16686](http://www.rubygems.example:16686).

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

# Protecting metrics in TimescaleDB

## 1. Installation

```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- timescaledb
```

This command:
* downloads AcraServer, AcraConnector, TimescaleDB, Prometheus, Grafana and PgAdmin images
* build `metricsource` image
* configures environment and starts demo stand using docker-compose


## 2. What's inside

Demo stand based on TimescaleDB, which stores encrypted data. That data produced by `metricsource` container which connected to TimescaleDB through AcraConnector and AcraServer.

At the initial stage, the TimescaleDB database will be filled with randomly generated metric data. Once started, the small daemon running in the `metricsource` container will continue to insert records into the database to simulate real processes.

Grafana also connected through AcraConnector and AcraServer to TimescaleDB and can get unencrypted data to building `Temperature (demo data)` graph.

Prometheus collects real metrics from AcraConnector and AcraServer. Two dashboards in Grafana: `AcraServer (real data)` and `AcraConnector (real data)` display that data.

### 2.1 Read the data directly from the database

1. Log into web TimescaleDB interface [http://$HOST:8008](http://127.0.0.1:8008) using user/password: `test@test.test`/`test`.

2. Go to the `Servers > postgresql > databases > test > Schemas > public > Tables > versions` and open context menu with right-click. Select `View/Edit Data > All rows` and now you can see content of the table.
Fields `device` and `unit_id` are encrypted. So, the data is stored in an encrypted form, but it is transparent for the Grafana.

## 2.2 Play with stand

You can easily interact with TimescaleDB through AcraConnector and AcraServer:
```bash
docker exec -it timescaledb_metricsource_1 \
    psql postgres://postgres:test@acra-connector:9494/test?sslmode=disable
```
or directly:
```bash
docker exec -it -u postgres timescaledb_timescaledb_1 \
    psql test
```

### 3. Other available resources

1. TimescaleDB - connect to the database using the admin account `postgres`/`test`: [postgresql://$HOST:5432](postgresql://127.0.0.1:5432).

2. Grafana – see the dashboards with Acra metrics: [http://$HOST:3000](http://127.0.0.1:3000).

3. Prometheus – examine the collected metrics: [http://$HOST:9090](http://127.0.0.1:9090).

4. AcraConnector – send some data directly through AcraConnector: [tcp://$HOST:9494](tcp://127.0.0.1:9494).

---

# Further steps

Let us know if you have any questions by dropping an email to [dev@cossacklabs.com](mailto:dev@cossacklabs.com).

1. [cossacklabs/acra](https://github.com/cossacklabs/acra) – the main Acra repository contains tons of examples and documentation.
2. Deploy your own Acra infrastructure using [pre-defined Docker-compose files](https://github.com/cossacklabs/acra/tree/master/docker).
3. [Acra Live Demo](https://www.cossacklabs.com/acra/#acralivedemo) – is a web-based demo of a typical web-infrastructure protected by Acra and deployed on our servers for your convenience. It illustrates the other features of Acra, i.e. SQL firewall, intrusion detection, database rollback, and so on.
