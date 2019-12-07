## Automation with Ansible
 
Everything is easier with automation. We made couple of Ansible scripts to make configuration of web app and Acra easier.

So, let's get back to the step where you have 3 droplets in Digital Ocean account: Django web app, Acra 1-Click app and PostgreSQL managed database cluster:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/11.png)

To configure your infrastructure automatically, perform next steps:

### Step 1. Create database

Run following command to create two users and two databases: **djangoproject** and **code.djangoproject** on your PostgreSQL database cluster:

⚠️ WHERE WE SHOULD RUN IT?

```
PGSSLMODE=require PGPASSWORD=<password_to_user_doadmin> psql -h <postgres_host> -p <postgres_port> -U doadmin -d defaultdb
create user djangoproject with password 'secret';
create user "code.djangoproject" with password 'secret';
create database djangoproject;
create database "code.djangoproject";
\q
```

### Step 2. Run script to configure AcraServer

Run following command to configure AcraServer to connect to the database:

⚠️ WHERE WE SHOULD RUN IT?

```
ansible-playbook acra-ansible-script.yml -i <acra_droplet_ip>, --extra-vars "db_host=<postgres_host> db_port=<postgres_port> acra_host=<acra_droplet_ip> acra_port=9393 django_host=<django_droplet_ip>"
```

### Step 3. Run script to configure web application 

Run following command to configure Django web app to connect to the AcraServer:

⚠️ WHERE WE SHOULD RUN IT?

```
ansible-playbook django-ansible-script.yml -i <django_droplet_ip>, --extra-vars "django_host=<django_droplet_ip> acra_host=<acra_droplet_ip> acra_port=9393 postgres_admin_password=<password_to_user_doadmin> postgres_django_password=secret"
```

### Step 4. Verify that encryption is up and working

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


