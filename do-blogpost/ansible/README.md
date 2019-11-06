#### Automation with Ansible
 
We provide Ansible automation for configuring all infrastructure components of the whole solution.

We assume that you have project in your Digital Ocean account with 3 infrastructure components (Django and Acra droplets and PostgreSQL managed database cluster):

![image](https://github.com/cossacklabs/acra-engineering-demo/blob/storojs72/T1230_do_blogpost/do-blogpost/version1/screenshots/11.png)

To configure your infrastructure automatically, perform next steps:

1) Create 2 users and 2 databases: **djangoproject** and **code.djangoproject** on your PostgreSQL database cluster. Run:
```
PGSSLMODE=require PGPASSWORD=<password_to_user_doadmin> psql -h <postgres_host> -p <postgres_port> -U doadmin -d defaultdb
create user djangoproject with password 'secret';
create user "code.djangoproject" with password 'secret';
create database djangoproject;
create database "code.djangoproject";
\q
```

2) Set IP addresses of your droplets into `hosts` inventory file:
```
[digital_ocean]
acra       ansible_host=<acra_droplet_ip>
django     ansible_host=<django_droplet_ip>
```
3) Run: `ansible-playbook acra-ansible-script.yml -i hosts --extra-vars "db_host=<postgres_host> acra_host=<acra_droplet_ip> acra_port=9393 django_host=<django_droplet_ip>"` to configure Acra droplet

4) Run `ansible-playbook django-ansible-script.yml -i hosts --extra-vars "django_host=<django_droplet_ip> acra_host=<acra_droplet_ip> acra_port=9393 postgres_admin_password=<password_to_user_doadmin> postgres_django_password=<password_to_user_djangoproject>"` to configure Django droplet

To check that configuration is successful, type in browser IP address of your Djangorpoject.com droplet. You should see:

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
