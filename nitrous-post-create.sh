#!/bin/bash

rm -rf ~/code/example

sudo apt-get update
sudo apt-get install -y --no-install-recommends redis-server
sudo apt-get clean

# install phantomjs for javascript tests
wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-linux-x86_64.tar.bz2 -O /tmp/phantomjs-1.9.8-linux-x86_64.tar.bz2
tar xvjf /tmp/phantomjs-1.9.8-linux-x86_64.tar.bz2 -C /tmp
rm -rf /tmp/phantomjs-1.9.8-linux-x86_64.tar.bz2
sudo mv /tmp/phantomjs-1.9.8-linux-x86_64 /usr/local/opt/phantomjs
echo "export PATH=$PATH:/usr/local/opt/phantomjs/bin" >> ~/.zshrc
echo "export PATH=$PATH:/usr/local/opt/phantomjs/bin" >> ~/.bashrc

createdb discourse_development
createdb discourse_test
psql -d discourse_development -c "CREATE EXTENSION hstore;CREATE EXTENSION pg_trgm;"
psql -d discourse_test -c "CREATE EXTENSION hstore;CREATE EXTENSION pg_trgm;"

cd ~/code/discourse

# bundle install
gem install bundler
bundle install
cp .env.sample .env
echo -e '\nPORT=3000\nIP=0.0.0.0' >> .env
sed -i 's|rails server|rails server -b $IP|g' Procfile
mkdir -p public/uploads
mkdir -p public/tombstone

rake db:migrate
rake db:test:prepare

echo -e '#!/bin/bash\nbundle exec foreman start' >> start-app
chmod +x start-app
