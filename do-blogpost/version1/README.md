#### Example of using Acra with Djangoproject.com web application on Digital Ocean cloud platform
We provide an example of AcraServer component integration into Djangoproject.com (https://github.com/django/djangoproject.com) application in order to protect (encrypt) some of user's blog attributes. The final infrastructure is production-ready and can be represented with the following diagram:

user's request (from browser) <--> nginx <--> uwsgi <--> django application <--> acra-server <--> postgresql database

We will show how to deploy all of the components on Digital Ocean (DO).

The following steps should be performed:

1) In DO's account space create new project by selecting `+ New Project` on the left panel and type name, description and purpose of the project -> 'Create Project'.

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/0.png)

2) In your project workspace create new PostgreSQL database cluster. Go to 'Create' -> 'Databases':

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/1.png)

and select (!!!) PostgreSQL database engine, node plan that is acceptable for you and datacenter location and then push 'Create a Database Cluster'. It will take for a while ... If creation was successful, you have to see that now you have your database cluster inside your project space:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/2.png)

Let's look on connection details:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/3.png)

We will use **host**, **port** later. Go into your database settings and click on 'Users & Databases':

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/4.png)

You will see that you have 1 admin user **doadmin** with some random password and 1 database **defaultdb**. Remember where to look for: **host**, **port**, **username** and **password** to your database.

3) Create 2 users and 2 databases: **djangoproject** and **code.djangoproject**. To do it, go to your local machine terminal and run the following commands:
```
PGSSLMODE=require PGPASSWORD=<password_to_user_doadmin> psql -h <host> -p <port> -U doadmin -d defaultdb
create user djangoproject with password 'secret';
create user "code.djangoproject" with password 'secret';
create database djangoproject;
create database "code.djangoproject";
\q
```
If there were no errors, our PostgreSQL database cluster is configured and ready to work. Next step is to create and configure two droplets: Acra and Django.

4) Create Acra Droplet and perform all the steps in startup configuration script. To do this, go to 'Create' -> 'Droplets' -> 'Marketplace' -> 'See all Marketplace Apps':

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/5.png)

Type 'Acra' in search text box. You should find Acra project:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/6.png)

Push 'Create Acra Droplet' button. As while managed database cluster creation, you will have to select plan, datacenter region (recommended to select the same location for all your droplets and database clusters). 

IMPORTANT!!! You have to add your public SSH key for secure authentication on your droplets. For this purpose, there is a button 'New SSH key':

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/7.png)

This opens the modal form:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/8.png)

Generating the SSH keys is out of scope of this blogpost. You can follow the instructions from the modal form (on the right) or find information in the Internet. Also you have to select which SSH keys will be allowed for authentication. Those people (owners of private parts of the key) will have an access to droplet. 

Push 'Create Droplet' button. It will take a little time to create a droplet.

5) Create droplet for Djangoproject.com application. Go to 'Create' -> 'Droplets' -> 'Distributions':

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/9.png)

Select Ubuntu 18.04.3 (LTS) x64 version of OS, plan, datacenter region, SSH keys allowed for authentication. Push 'Create Droplet' button. It will take a little time to create a droplet.

Now we have all the infrastructure components ready. You should have 3 components: 2 droplets and 1 database cluster:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/11.png)

You can look for all the credentials of your droplets and managed database in the main project workspace of your DO account. We have already used credentials while configuring your database cluster and will use droplets credentials for their configuring.

6) Configuring Acra droplet. 

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
* Hostname: (can be found in connection details modal form of your Acra droplet - IPv4)
* Allowed hosts: (can be found in connection details modal form of your Django droplet - IPv4)
* CA certificate:  (can be downloaded from connection details modal form of your Postgres database cluster)
* DB host (can be found in connection details modal form of your Postgres database cluster - host)
* DB port (can be found in connection details modal form of your Postgres database cluster - port)
* Table: blog_entries (table that we will protect with Acra)
* Columns: id headline slug is_active pub_date content_format summary summary_html body body_html author
* Encrypt columns: author body body_html headline summary summary_html
* Table: (skip further tables, just press 'Enter')
```

Finally, you should see something similar to this:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version2/screenshots/acra3.png)
![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version2/screenshots/acra4.png)

Excellent. Now we have successfully configured Acra.

7) Configuring Djangoproject.com droplet (Ubuntu 18.04). Go to your local machine terminal and run the following commands:
```
ssh root@<django_droplet_ip>

# set input data
export DJANGOPROJECT_DATA_DIR=/opt/app_data
export ACRA_HOST=<host_acra_droplet>
export ACRA_PORT=<port_acra_droplet>
export DJANGO_HOST=<host_django_droplet>
export POSTGRES_DJANGO_PASSWORD=secret

# perform all the settings
cd /opt
apt update
apt install postgresql libpq-dev npm python3-venv python3-dev nginx

# get djangoproject.com source code
git clone https://github.com/django/djangoproject.com
cd djangoproject.com/ && git checkout a4a33ec0adf97dcae286668435b15d140f6f5041 && cd ..

# get and apply modifications for djangoproject.com in order to work with DO Acra droplet
wget https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/storojs72/T1230_do_blogpost/do-blogpost/acra_modifications.patch
wget https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/storojs72/T1230_do_blogpost/do-blogpost/django_entry.sh
patch -p1 -d djangoproject.com/ < acra_modifications.patch 
bash django_entry.sh

# initial installation of djangoproject.com server
cd djangoproject.com
python3 -m venv acra_django
source acra_django/bin/activate
pip install -r requirements/dev.txt
npm install

# database migration
PGSSLMODE=require psql -h $ACRA_HOST -p $ACRA_PORT -U doadmin -d code.djangoproject < tracdb/trac.sql
./manage.py migrate
./manage.py createsuperuser
admin
email@example.com
admin
admin 

# final Django preparations
make compile-scss

# run via uwsgi
pip install uwsgi
mkdir -p /opt/logs
uwsgi --socket :8001 --module djangoproject.wsgi --home /opt/djangoproject.com/acra_django/ --daemonize /opt/logs/uwsgi_log & disown

#set self-signed TLS certificate
openssl genrsa -out /opt/app_data/server.key 4096
openssl rsa -in /opt/app_data/server.key -out /opt/app_data/server.key
openssl req -sha256 -new -key /opt/app_data/server.key -out /opt/app_data/server.csr -subj '/CN='"$DJANGO_HOST"''
openssl x509 -req -sha256 -days 365 -in /opt/app_data/server.csr -signkey /opt/app_data/server.key -out /opt/app_data/server.crt

# load nginx
wget -O /etc/nginx/sites-enabled/acra_django_nginx.conf https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/storojs72/T1230_do_blogpost/do-blogpost/acra_django_nginx.conf
sed -i 's/x.x.x.x/$DJANGO_HOST/g' /etc/nginx/sites-enabled/acra_django_nginx.conf
./manage.py collectstatic
systemctl reload nginx
```

Note, that in order to use TLS, you should import generated `/opt/app_data/server.crt` certificate into your browser on your local machine. See this separate blogpost for details: https://www.techrepublic.com/article/how-to-add-a-trusted-certificate-autqhority-certificate-to-chrome-and-firefox/. 

IMPORTANT!!! This is a some kind of simplification. In production, good practice would be to buy domain name for your Digital Ocean droplet that runs applciation and also buy TLS certificate for this domain from well-known Certificate Authority. It's important for security reasons.

That's all. Now let's check our application. Type in browser IP address of your Djangorpoject.com droplet. You should see:

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/12.png)

Go to admin page, by typing `IP_address/admin` in browser:

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

#### Useful links:

- Acra Github: https://github.com/cossacklabs/acra
- Acra 1-Click Application on Digital Ocean: https://marketplace.digitalocean.com/apps/acra
