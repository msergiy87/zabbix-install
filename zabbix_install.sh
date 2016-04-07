#!/bin/bash
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH
#set -x

timezone_continent=Europe
timezone_city=London
MYSQL_ROOT_PASS=myrootpass
MYSQL_ZABBIX_PASS=myzabbixpass
nginx_server_name=$(hostname -I)

# Installing repository configuration package
wget -P /tmp http://repo.zabbix.com/zabbix/3.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_3.0-1+trusty_all.deb
dpkg -i /tmp/zabbix-release_3.0-1+trusty_all.deb
apt-get update > /dev/null 2>&1

# Install Nginx
apt-get install nginx -y > /dev/null 2>&1

# Install Mysql
apt-get install mysql-server -y

# Install php5-fpm
apt-get install php5-fpm php5-mysql php5-cli -y > /dev/null 2>&1

# Installing Zabbix packages
apt-get install zabbix-server-mysql zabbix-frontend-php zabbix-agent -y > /dev/null 2>&1

# Creating initial database
mysql -e "UPDATE mysql.user SET Password = PASSWORD('"$MYSQL_ROOT_PASS"') WHERE User = 'root';FLUSH PRIVILEGES;"

mysql --user=root --password=$MYSQL_ROOT_PASS -e "create database zabbix character set utf8 collate utf8_bin;\
grant all privileges on zabbix.* to zabbix@localhost identified by '"$MYSQL_ZABBIX_PASS"';\
FLUSH PRIVILEGES;"

zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql --user=root --password=$MYSQL_ROOT_PASS zabbix

# Starting Zabbix server process
sed -i 's/# DBHost=.*/DBHost=localhost/' /etc/zabbix/zabbix_server.conf
sed -i 's/# DBName=.*/DBHost=zabbix/' /etc/zabbix/zabbix_server.conf
sed -i 's/# DBUser=.*/DBHost=zabbix/' /etc/zabbix/zabbix_server.conf
sed -i "s/# DBPassword=.*/DBPassword="$MYSQL_ZABBIX_PASS"/" /etc/zabbix/zabbix_server.conf

service zabbix-server restart

# Editing PHP configuration for Zabbix frontend

#sed -i 's/^max_execution_time.*/max_execution_time = 300/' /etc/php5/fpm/php.ini
#sed -i 's/^memory_limit.*/memory_limit = 128M/' /etc/php5/fpm/php.ini
#sed -i 's/^post_max_size.*/post_max_size = 16M/' /etc/php5/fpm/php.ini
#sed -i 's/^upload_max_filesize.*/upload_max_filesize = 2M/' /etc/php5/fpm/php.ini
#sed -i 's/^max_input_time.*/max_input_time = 300/' /etc/php5/fpm/php.ini
#sed -i 's/^\;always_populate_raw_post_data =.*/always_populate_raw_post_data = -1/' /etc/php5/fpm/php.ini
#sed -i "s/^\;date.timezone.*/date.timezone = \'Europe\/London\'/" /etc/php5/fpm/php.ini

sed -i 's/^\(max_execution_time\).*/\1 = 300/' /etc/php5/fpm/php.ini
sed -i 's/^\(memory_limit\).*/\1 = 128M/' /etc/php5/fpm/php.ini
sed -i 's/^\(post_max_size\).*/\1 = 16M/' /etc/php5/fpm/php.ini
sed -i 's/^\(upload_max_filesize\).*/\1 = 2M/' /etc/php5/fpm/php.ini
sed -i 's/^\(max_input_time\).*/\1 = 300/' /etc/php5/fpm/php.ini
sed -i 's/^\;always_populate_raw_post_data =.*/always_populate_raw_post_data = -1/' /etc/php5/fpm/php.ini
sed -i "s/^\;date.timezone.*/date.timezone = \'"$timezone_continent"\/"$timezone_city"\'/" /etc/php5/fpm/php.ini

service php5-fpm restart

# Nginx config file
cat > /etc/nginx/sites-available/zabbix.conf <<- _EOF_
server {
    listen       80;
    server_name  $nginx_server_name;
    root /usr/share/zabbix;
 
    location / {
        root   /usr/share/zabbix;
        index  index.php index.html;
    }
 
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
 
 
    location ~ \.php$ {
        #root html;
        try_files \$uri =404;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
 
   
}
_EOF_

ln -s /etc/nginx/sites-available/zabbix.conf /etc/nginx/sites-enabled/

service nginx restart
