# zabbix-install
Installation script of Zabbix 3.0, Nginx, Mysql on Ubuntu 14.04

Distros tested
------------

Currently, this is only tested on Ubuntu 14.04. It should theoretically work on older versions of Ubuntu or Debian based systems.

Usage
------------

Change this values in script
```
timezone_continent=Europe
timezone_city=London
MYSQL_ROOT_PASS=myrootpass
MYSQL_ZABBIX_PASS=myzabbixpass
nginx_server_name=$(hostname -I)
```

When you run script from command line, and when it will request to enter mysql password, just press "Enter" key.
You can run script from crontab also.

The default Web Interface user name is "Admin", password "zabbix".
