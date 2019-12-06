# Field level encryption for web apps using Acra and Digital Ocean managed PostgreSQL

Field level encryption helps to protect data stored in database, providng better security guarantees than "data at rest" encryption. If your application is deployed on Digital Ocean and uses PostgreSQL, you can setup "transparent encryption" to protect each data record while your app and database won't notice that data is encrypted. We will illustrate how to do it using [Django-based web app](https://www.djangoproject.com/), open source [Acra database security suite](https://marketplace.digitalocean.com/apps/acra), and Digital Ocean managed PostgreSQL.

## Initial setup

We assume that you already have your web application and managed PostgreSQL instance deployed on Digital Ocean:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version2/screenshots/1.png)

And your web application is publicly accessed:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version2/screenshots/2.png)

If not, no worries, you can use any of your existing apps or deploy example app using following instructions:

* [How To Set Up Django with Postgres, Nginx, and Gunicorn on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-django-with-postgres-nginx-and-gunicorn-on-ubuntu-16-04)

* [How to Set Up a Scalable Django App with DigitalOcean Managed Databases and Spaces](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-scalable-django-app-with-digitalocean-managed-databases-and-spaces)

## Security goals

What exactly we are trying to protect here? Our application is Django-based blog, where authors can publish their blog posts. We will encrypt sensitive fields, like author name, post body and metadata, and store them encrypted in the database. 

Web applications can be easily cracked, so we don't want application to decrypt the data and handle decryption keys. At the same time, we don't want database to decrypt the data and handle keys, because if database is misconfigured, data is publicly available. We'd better store our blog posts encrypted all the time. We need to introduce a proxy – Acra – to handle encryption and decryption for us. 

<!-- AcraServers' scheme? -->

Web application sends data to AcraServer, AcraServer encrypts it and sends to the database. On reading data, AcraServer requests data from the database, decrypts it and returns back to the application. AcraServer authenticate the application using cryptographic keys, so if malicious app doesn't have the key, decryption will fail. Besides encryption, AcraServer has additional security measures, like SQL firewall, intrusion detection, key management utils, SIEM integration, and so on, that helps to protect and monitor data accesses.

## AcraServer setup

Now we will add AcraServer as proxy to the existing infrastructure, configure it and update web app to point to the AcraServer instead of the database.

Let's start step by step.

### Step 1. Install Acra 1-Click app

1. Go to 'Create' -> 'Droplets' -> 'Marketplace' -> 'See all Marketplace Apps':

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/5.png)

2. Type 'Acra' in search text box. You should find Acra 1-Click App:
![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/6.png)

3. Push 'Create Acra Droplet' button, select plan and datacenter region (we recommended to select the same location for all your droplets and database clusters).

> Note: it's better to minimize number of SSH keys you use to access to Acra Droplet. As AcraServer will encrypt and decrypt the data, you don't want many users to connect to it. 


Now we have all the infrastructure components ready. You should have 3 components up and ready: web app, Acra and database cluster.

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/11.png)


### Step 2. Configure AcraServer


During next steps we will need following connection parameters:

```
ACRA_HOST
DJANGO_HOST
DB_CERTIFICATE
DB_HOST
DB_PORT
```

You can find these credentials in working space of your Digital Ocean account:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version2/screenshots/3.png)
![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version2/screenshots/4.png)


Open terminal on your local machine and connect to AcraServer:

```
ssh root@<acra_droplet_ip>
```

Upon connection you'll see the configuration script, step by step specify following parameters:

```
* Hostname: ACRA_HOST
* Allowed hosts: DJANGO_HOST
* CA certificate:  DB_CERTIFICATE
* DB host: DB_HOST
* DB port: DB_PORT
* Table: blog_entries (table which AcraServer will encrypt)
* Columns: id headline slug is_active pub_date content_format summary summary_html body body_html author
* Encrypt columns: author body body_html headline summary summary_html
* Table: (skip further tables, just press 'Enter')
```

Finally, you should see something similar to this:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version2/screenshots/acra3.png)
![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version2/screenshots/acra4.png)

Excellent. Now we have successfully configured AcraServer.

### Step 3. Modify the source code of web application

Encrypted data is binary data. As AcraServer doesn't know the nature of data, it returns decrypted binary data to the web app. We will change source code of web app to receive binary data and encode it.

⚠️ WHERE WE SHOULD DO IT? SHOULD WE RE-DEPLOY WEB APP?

Add functions for encoding/decoding the fields to `blog/fields.py`:

```
diff -urN djangoproject.com/blog/fields.py patched/blog/fields.py
--- djangoproject.com/blog/fields.py	1970-01-01 03:00:00.000000000 +0300
+++ patched/blog/fields.py	2019-10-06 18:56:08.232183901 +0300
@@ -0,0 +1,53 @@
+from binascii import hexlify
+from django.db import models
+from django.utils.translation import gettext_lazy as _
+import codecs
+
+
+class PgTextBinaryField(models.TextField):
+    description = _("Text as binary data")
+
+    def from_db_value(self, value, expression, connection):
+        return db_value_to_string(value)
+
+    def get_db_prep_value(self, value, connection, prepared=False):
+        return string_to_dbvalue(value)
+
+
+class PgCharBinaryField(models.CharField):
+    description = _("Chars as binary data")
+
+    def from_db_value(self, value, expression, connection):
+        return db_value_to_string(value)
+
+    def get_db_prep_value(self, value, connection, prepared=False):
+        return string_to_dbvalue(value)
+
+
+def bytes_to_string(b):
+    if len(b) >= 2 and b[0:2] == b'\\x':
+        return codecs.decode(b[2:].decode(), 'hex').decode('utf-8')
+
+    return b.decode()
+
+
+def memoryview_to_string(mv):
+    return bytes_to_string(mv.tobytes())
+
+
+def db_value_to_string(value):
+    if isinstance(value, memoryview):
+        return memoryview_to_string(value)
+    elif isinstance(value, bytes) or isinstance(value, bytearray):
+        return bytes_to_string(value)
+
+    return value
+
+
+def string_to_dbvalue(s):
+    if s == '':
+        return b''
+    elif s is None:
+        return None
+
+    return '\\x{}'.format(bytes(s, 'utf-8').hex()).encode('ascii')
```

Migrate data to `binary` format, add migration script `blog/migrations/0003_encrypt.py`:

```
diff -urN djangoproject.com/blog/migrations/0003_encrypt.py patched/blog/migrations/0003_encrypt.py
--- djangoproject.com/blog/migrations/0003_encrypt.py	1970-01-01 03:00:00.000000000 +0300
+++ patched/blog/migrations/0003_encrypt.py	2019-10-06 18:57:14.743866140 +0300
@@ -0,0 +1,43 @@
+# -*- coding: utf-8 -*-
+from __future__ import unicode_literals
+
+from django.db import migrations, models
+
+class Migration(migrations.Migration):
+
+    dependencies = [
+        ('blog', '0002_event'),
+    ]
+
+    operations = [
+        migrations.AlterField(
+            model_name='entry',
+            name='author',
+            field=models.BinaryField(),
+        ),
+        migrations.AlterField(
+            model_name='entry',
+            name='body',
+            field=models.BinaryField(),
+        ),
+        migrations.AlterField(
+            model_name='entry',
+            name='body_html',
+            field=models.BinaryField(),
+        ),
+        migrations.AlterField(
+            model_name='entry',
+            name='headline',
+            field=models.BinaryField(),
+        ),
+        migrations.AlterField(
+            model_name='entry',
+            name='summary',
+            field=models.BinaryField(),
+        ),
+        migrations.AlterField(
+            model_name='entry',
+            name='summary_html',
+            field=models.BinaryField(),
+        ),
+    ]
```

Update the `blog/models.py` file to actually use `binary` format:

```
diff -urN djangoproject.com/blog/models.py patched/blog/models.py
--- djangoproject.com/blog/models.py	2019-10-09 19:37:15.829280692 +0300
+++ patched/blog/models.py	2019-10-06 18:57:30.015795274 +0300
@@ -10,6 +10,8 @@
 from django_hosts.resolvers import reverse
 from docutils.core import publish_parts
 
+from .fields import PgCharBinaryField, PgTextBinaryField
+
 BLOG_DOCUTILS_SETTINGS = {
     'doctitle_xform': False,
     'initial_header_level': 3,
@@ -35,7 +37,7 @@
 
 
 class Entry(models.Model):
-    headline = models.CharField(max_length=200)
+    headline = PgCharBinaryField(max_length=200)
     slug = models.SlugField(unique_for_date='pub_date')
     is_active = models.BooleanField(
         help_text=_(
@@ -53,11 +55,11 @@
         ),
     )
     content_format = models.CharField(choices=CONTENT_FORMAT_CHOICES, max_length=50)
-    summary = models.TextField()
-    summary_html = models.TextField()
-    body = models.TextField()
-    body_html = models.TextField()
-    author = models.CharField(max_length=100)
+    summary = PgTextBinaryField()
+    summary_html = PgTextBinaryField()
+    body = PgTextBinaryField()
+    body_html = PgTextBinaryField()
+    author = PgCharBinaryField(max_length=100)
 
     objects = EntryQuerySet.as_manager()
```

These are all source changes! No encryption, no magick – application doesn't know that data will be encrypted/decrypted by external forces.

### Step 4. Modify the network settings of web application

Now we should re-connect web application to the AcraServer instead of the database. In this case, SQL queries from your app will go through AcraServer to the database and back.

Typical way to configure connection settings of Django apps is to use [`$DJANGOPROJECT_DATA_DIR/conf/secrets.json`](https://github.com/django/djangoproject.com) file. 

⚠️ WHERE WE SHOULD DO THIS? WHICH MACHINE? WEB APP? SHOULD WE EXPORT ENV VARS FIRST?

Please modify `$DJANGOPROJECT_DATA_DIR/conf/secrets.json` it in a following way:

```
{
  "secret_key": "$(dd if=/dev/urandom bs=4 count=16 2>/dev/null | base64 | head -c 32)",
  "superfeedr_creds": ["email@example.com", "some_string"],
  "db_host": "$ACRA_HOST",
  "db_password": "$POSTGRES_DJANGO_PASSWORD",
  "db_port": "$ACRA_PORT",
  "trac_db_host": "$ACRA_HOST",
  "trac_db_password": "$POSTGRES_DJANGO_PASSWORD",
  "trac_db_port": "$ACRA_PORT",
  "allowed_hosts": ["$DJANGO_HOST", "www.$DJANGO_HOST"],
  "parent_host": "$DJANGO_HOST"
}
```

We changed the host/port of your database to host/port of AcraServer.

⚠️ Should we restart web app?

### Step 5. Test that encryption is working

So, now let's look at how Acra exactly works. 

Create a blogpost via admin panel of your application: go to admin page, by typing `DJANGO_HOST/admin` in browser:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/13.png)

Put `admin` / `admin` as username / password and log in into administrative page:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/14.png)

Find 'Blog' category. And select 'Entries' -> '+ Add':

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/15.png)

Fill all necessary textboxes:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/16.png)

Click 'Save' at the bottom of page. This will create encrypted blog record:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/17.png)

Visitors of your site see blog posts in plaintext (check this by opening `IP_address/weblog` in browser):

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/18.png)

But blog posts are encrypted under the hood. Open `djangoproject` database, open table `blog_entries` and query data:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/19.png)

So, the Acra works as proxy, encrypting and decrypting data transparently for the application in a way, that hacking the app or the database won't lead to the data compromise – as every data field is encrypted using unique keys. Read more about [how Acra works](https://www.cossacklabs.com/acra/) and how to use it for different types of applications.


#### ANSIBLE 
We provide an Ansible script for automatiс deployment of all infrastructure components of the whole solution.

TBD...

#### Useful links:

- Acra Github: https://github.com/cossacklabs/acra
- Acra 1-Click Application on Digital Ocean: https://marketplace.digitalocean.com/apps/acra
