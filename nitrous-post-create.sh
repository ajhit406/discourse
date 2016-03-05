#!/bin/bash
clear

# update system
sudo apt-get update

# install redis
sudo apt-get install redis

# install imagemagick
sudo apt-get install imagemagick --fix-missing

# install required libaries
sudo apt-get libxml2 libpq-dev g++ gifsicle libjpeg-progs

# install ruby 2.1.3 and set rbenv
rbenv install 2.1.3
rbenv global 2.1.3

# install phantomjs for javascript tests
cd /usr/local/share
wget https://phantomjs.googlecode.com/files/phantomjs-1.8.2-linux-i686.tar.bz2
tar xvf phantomjs-1.8.2-linux-i686.tar.bz2
rm phantomjs-1.8.2-linux-i686.tar.bz2
ln -s /usr/local/share/phantomjs-1.8.2-linux-i686/bin/phantomjs /usr/local/bin/phantomjs

# configure postgres so we dont need to enter username and password
sudo apt-get -yqq install postgresql postgresql-contrib-9.3 libpq-dev postgresql-server-dev-9.3
sudo su - postgres
createuser --createdb --superuser -Upostgres nitrous
psql -c "ALTER USER nitrous WITH PASSWORD 'password';"
psql -c "create database discourse_development owner nitrous encoding 'UTF8' TEMPLATE template0;"
psql -c "create database discourse_test        owner nitrous encoding 'UTF8' TEMPLATE template0;"
psql -d discourse_development -c "CREATE EXTENSION hstore;"
psql -d discourse_development -c "CREATE EXTENSION pg_trgm;"

# open /etc/postgresql/9.3/main/pg_hba.conf and add config
cat <<EOF >> /etc/postgresql/9.3/main/pg_hba.conf
local all all trust
host all all 127.0.0.1/32 trust
host all all ::1/128 trust
host all all 0.0.0.0/0 trust # wide-open
EOF

# bundle install
bundle install

# start redis and run in background
nohup redis-server &>/dev/null

# install database, migrate, run tests
bundle exec rake db:create db:migrate db:test:prepare

# start rails server binding on 0.0.0.0
bundle exec rails server -b 0.0.0.0

# start sidekiq
bundle exec sidekiq

