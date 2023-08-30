# Transparent encryption, Django, PostgreSQL

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
