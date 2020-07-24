This folder contains Acra configurations and Ansible scripts for blog post "How to encrypt database fields transparently for app and database using Acra and DigitalOcean managed PostgreSQL".

Detailed instruction about configuring Django project app, that is not part of blog post:

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

IMPORTANT. This is a some kind of simplification. In production, good practice would be to buy domain name for your Digital Ocean droplet that runs applciation and also buy TLS certificate for this domain from well-known Certificate Authority. It's important for security reasons.

That's all. Now let's check our application and come back to the blogpost.