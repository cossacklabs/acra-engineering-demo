#### Example of using Acra with Djangoproject.com web application on Digital Ocean cloud platform

In this tutorial we will show how to protect your Django-based application (https://www.djangoproject.com/) - hereinafter 'application' - deployed on Digital Ocean cloud platform (https://www.digitalocean.com/) with a help of Acra 1-Click App. We assume that you already have one droplet and one managed database instance online:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version2/screenshots/1.png)

and your application can be publicly accessed:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version2/screenshots/2.png)

If no, and you want to deploy application on your own please read following instructions:
* https://www.digitalocean.com/community/tutorials/how-to-set-up-django-with-postgres-nginx-and-gunicorn-on-ubuntu-16-04
* https://www.digitalocean.com/community/tutorials/how-to-set-up-a-scalable-django-app-with-digitalocean-managed-databases-and-spaces

Good. Now, in order to protect the application we will add AcraServer component into existing infrastructure, configure it and slightly change source code and some settings of your application. Let's start one step by one.

1) Create Acra Droplet and perform all the steps in startup configuration script. To do this, go to 'Create' -> 'Droplets' -> 'Marketplace' -> 'See all Marketplace Apps':

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/5.png)

Type 'Acra' in search text box. You should find Acra 1-Click App:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/6.png)

Push 'Create Acra Droplet' button. As while managed database cluster creation, you will have to select plan, datacenter region (recommended to select the same location for all your droplets and database clusters). 

IMPORTANT!!! You should minimize the number of entities (SSH keys) with access to Acra Droplet for security reasons.

Push 'Create Droplet' button. It will take a little time to create a droplet.

Now we have all the infrastructure components ready. You should have 3 components: 2 droplets and 1 database cluster:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/11.png)

2) Configuring Acra.

Prepare the following information in order to configure Acra:

```
ACRA_HOST
DJANGO_HOST
DB_CERTIFICATE
DB_HOST
DB_PORT
```
You can find all those credentials in working space of your Digital Ocean account:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version2/screenshots/3.png)
![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version2/screenshots/4.png)


Go to your local machine terminal and run the following commands:
```
ssh root@<acra_droplet_ip>

Then proceed with configurator that will start automatically. You will need to specify:
* Hostname: ACRA_HOST
* Allowed hosts: DJANGO_HOST
* CA certificate:  DB_CERTIFICATE
* DB host: DB_HOST
* DB port: DB_PORT
* Table: blog_entries (table that we will protect with Acra)
* Columns: id headline slug is_active pub_date content_format summary summary_html body body_html author
* Encrypt columns: author body body_html headline summary summary_html
* Table: (skip further tables, just press 'Enter')
```

Finally, you should see something similar to this:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version2/screenshots/acra3.png)
![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version2/screenshots/acra4.png)

Excellent. Now we have successfully configured Acra.

3) Modifications of application's source code.

Acra uses binary fields in database for storing encrypted data, so most changes in the source code are required by this. There are 2 additional files:

- blog/fields.py

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

- blog/migrations/0003_encrypt.py:

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

And some changes in 1 existing file of application:

- blog/models.py:

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

4) Modification in application settings.

We assume you use standard way of configuring your application as defined in Djangoproject.com (https://github.com/django/djangoproject.com) Readme on 3rd step via 'secrets.json' file. The structure of this file should be modified in the following way: 

```
#!/usr/bin/env bash

set -Eeuo pipefail

mkdir -p $DJANGOPROJECT_DATA_DIR/conf

cat > $DJANGOPROJECT_DATA_DIR/conf/secrets.json <<EOF
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
EOF
```
As you can see, we changed the host/port of your database on Acra host/port. In this way, all SQL queries issued by your application will be forwarded to the database via Acra component. Also, remember, that in 2nd step we configured Acra to encrypt data in the `blog_entries` table. So, now let's look at how Acra exactly works. Create a blogpost via admin panel of your application: go to admin page, by typing `DJANGO_HOST/admin` in browser:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/13.png)

Put `admin` / `admin` as username / password and log in into administrative page:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/14.png)

Find 'Blog' category. And select 'Entries' -> '+ Add':

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/15.png)

Fill all necessary textboxes:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/16.png)

Click 'Save' at the bottom of page. This will create encrypted blog record:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/17.png)

It will be normally reviewed by website visitors (go to `IP_address/weblog` in browser):

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/18.png)

But it is actually encrypted (as you can see the records in the `blog_entries` table of your `djangoproject` database):

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/19.png)

So, here is how Acra works.


#### ANSIBLE 
We provide an Ansible script for automatiс deployment of all infrastructure components of the whole solution.

TBD...

#### Useful links:

- Acra Github: https://github.com/cossacklabs/acra
- Acra 1-Click Application on Digital Ocean: https://marketplace.digitalocean.com/apps/acra
