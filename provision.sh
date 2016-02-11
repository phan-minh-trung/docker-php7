#!/usr/bin/env bash
set -e
trap 'echo "[ fail ]";exit 1' SIGTERM SIGINT SIGFPE SIGQUIT SIGTSTP SIGHUP

# Update Package List
apt-get update

# Install ssh server
apt-get -y install openssh-server curl

# Create talklish user
adduser talklish
usermod -p $(echo secret | openssl passwd -1 -stdin) talklish

# Install Some PPAs
apt-get install -y software-properties-common

add-apt-repository -y ppa:ondrej/php
apt-add-repository -y ppa:chris-lea/node.js

# Update Package Lists
apt-get update

# Add talklish to the sudo group and www-data
usermod -aG sudo talklish
usermod -aG www-data talklish

# Install php 7
apt-get install -y --force-yes git php7.0-fpm php7.0-cli php7.0-common php7.0-json php7.0-opcache  php7.0-mysql php7.0-odbc php7.0-sybase php7.0-phpdbg php7.0-dbg php7.0-gd php7.0-imap php7.0-ldap php7.0-pgsql php7.0-pspell php7.0-recode php7.0-snmp php7.0-tidy php7.0-dev php7.0-intl php7.0-gd php7.0-curl php7.0-bz2 php7.0-mcrypt php7.0-dev

# Install php 7 redis
git clone https://github.com/phpredis/phpredis.git
cd phpredis
git checkout php7
phpize
./configure
make && make install
rm -rf phpredis

cd /etc/php/mods-available
echo "extension=redis.so" > redis.ini

cd /etc/php/7.0/fpm/conf.d/
ln -sf /etc/php/mods-available/redis.ini ./20-redis.ini

cd /etc/php/7.0/cli/conf.d/
ln -sf /etc/php/mods-available/redis.ini ./20-redis.ini

# Set My Timezone
#ln -sf /usr/share/zoneinfo/UTC /etc/localtime
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Add Composer Global Bin To Path
printf "\nPATH=\"/home/talklish/.composer/vendor/bin:\$PATH\"\n" | tee -a /home/talklish/.profile

# Install Laravel Envoy
sudo su talklish <<'EOF'
/usr/local/bin/composer global require "laravel/envoy=~1.0"
EOF

# Set Some PHP CLI Settings
#sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/cli/php.ini
#sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/cli/php.ini
#sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.0/cli/php.ini
#sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.0/cli/php.ini

#rm /etc/nginx/sites-enabled/default
#rm /etc/nginx/sites-available/default

# Setup Some PHP-FPM Options
#ln -s /etc/php/7.0/mods-available/mailparse.ini /etc/php/7.0/fpm/conf.d/20-mailparse.ini

#sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/fpm/php.ini
#sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/fpm/php.ini
#sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini
#sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.0/fpm/php.ini
#sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.0/fpm/php.ini

# Enable Remote xdebug
#echo "xdebug.remote_enable = 1" >> /etc/php/7.0/fpm/conf.d/20-xdebug.ini
#echo "xdebug.remote_connect_back = 1" >> /etc/php/7.0/fpm/conf.d/20-xdebug.ini
#echo "xdebug.remote_port = 9000" >> /etc/php/7.0/fpm/conf.d/20-xdebug.ini

#echo "xdebug.var_display_max_depth = -1" >> /etc/php/7.0/fpm/conf.d/20-xdebug.ini
#echo "xdebug.var_display_max_children = -1" >> /etc/php/7.0/fpm/conf.d/20-xdebug.ini
#echo "xdebug.var_display_max_data = -1" >> /etc/php/7.0/fpm/conf.d/20-xdebug.ini

#echo "xdebug.max_nesting_level = 500" >> /etc/php/7.0/fpm/conf.d/20-xdebug.ini

# Set The Nginx & PHP-FPM User
#sed -i "s/user www-data;/user talklish;/" /etc/nginx/nginx.conf
#sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

#sed -i "s/user = www-data/user = talklish/" /etc/php/7.0/fpm/pool.d/www.conf
#sed -i "s/group = www-data/group = talklish/" /etc/php/7.0/fpm/pool.d/www.conf

#sed -i "s/;listen\.owner.*/listen.owner = talklish/" /etc/php/7.0/fpm/pool.d/www.conf
#sed -i "s/;listen\.group.*/listen.group = talklish/" /etc/php/7.0/fpm/pool.d/www.conf
#sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.0/fpm/pool.d/www.conf

# Install Node
apt-get install -y --force-yes nodejs
npm install -g grunt-cli
npm install -g gulp
npm install -g bower

# Install A Few Other Things
apt-get install -y redis-server memcached

# Configure default nginx site
block="server {
    listen 80 default_server;
    listen [::]:80 default_server ipv6only=on;

    root /var/www/html;
    server_name localhost;

    index index.html index.htm index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/app-error.log error;

    error_page 404 /index.php;

    sendfile off;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
        fastcgi_index index.php;
        include fastcgi.conf;
    }

    location ~ /\.ht {
        deny all;
    }
}
"

cat > /etc/nginx/sites-enabled/default
echo "$block" > "/etc/nginx/sites-enabled/default"
