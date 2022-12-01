#!/bin/bash
#
# removes mysql root password (useful for academic purposes only)
sudo service mysql stop
sudo systemctl set-environment MYSQLD_OPTS="--skip-grant-tables --skip-networking"
sudo service mysql start
sudo mysql -uroot -p <<EOF
use mysql;
update user set authentication_string=null where user='root';
update user set plugin='mysql_native_password' where user='root';
flush privileges;
DROP DATABASE IF EXISTS cmsc447;
CREATE DATABASE cmsc447;
EOF
sudo service mysql stop
sudo systemctl set-environment MYSQLD_OPTS=""
sudo service mysql start
