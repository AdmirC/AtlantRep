# ! /usr/bin/bash

# Script for VM provisioning

# The first line prepares the system for the services that will be installed on it. Installing all necessary packages which are up to date
# and possibly needed by the services for propper function. 
# Defining variables which carry the values of the username and the password for mysql access. Defining the name of a test database which 
# will be created on the mysql server.

apt-get update -y
DBNAME=test
DBUSER=test
DBPASSWD=pass

# First two echo lines set a root password "in advance" to the installation of the mysql server. With this commands, the user is not prompted
# to choose a root password during installation. This feature gives full automatisation to the mysql server installing process.

echo "mysql-server mysql-server/root_password password $DBPASSWD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DBPASSWD" | debconf-set-selections 

# Installing the mysql server

sudo apt-get -y install mysql-server-5.5

# Creating a test database on the mysql server. Creating a user to test the work on the server. This user has been given the same password as # the root user. This is done so, just for test purposes. Of course, this user should have a different password. This user has been given all 
# priviledges. With the '%' symbol, it is enabled that this user can log into the mysql server from any machine, for example, from the host 
# machine of the VM

mysql -uroot -p$DBPASSWD -e "CREATE DATABASE $DBNAME"
mysql -uroot -p$DBPASSWD -e "GRANT ALL ON *.* TO '$DBUSER'@'%' IDENTIFIED BY '$DBPASSWD' WITH GRANT OPTION"
mysql -uroot -p$DBPASSWD -e "FLUSH PRIVILEGES"

# Two sed commands are used to automatically change the my.cnf configuration file of the mysql server. With those changes (comment the skip-
# etxternal-option and changing the bind-address to 0.0.0.0) it is also enabled that the created user can log into the mysql server from any 
# machine and is not restricted to the local VM

sed -i -e 's/.*skip-external-locking/#&/' /etc/mysql/my.cnf
sed -i -e 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf

# Restarting mysql, so the changes take effect

sudo service mysql restart

# Installing apache2 web server

apt-get install -y apache2

# With the next few lines, we use the pattern of the default apache website index.html to create our own default website that will be 
# accessed for testing. We use bassically the same file (index.html).  

mkdir -p /var/www/test/
chown -R $USER:$USER /var/www/test/
chmod -R 755 /var/www
mv /var/www/index.html /var/www/test/index.html
sed -i -e 's/It works!/AtlantTest/g' /var/www/test/index.html
sed -i -e 's/This is the default web page for this server./Ovo je test site./g' /var/www/test/index.html
sed -i -e 's/The web server software is running but no content has been added, yet./Server host-a ovaj site./g' /var/www/test/index.html

# The next few lines crate a new virtual host on the server. Again, the default virtual host file is used as a pattern. A name is given to the 
# server (to the site, www.test.ba). This site is being put into the database of allowed websites hosted by the server.

cp /etc/apache2/sites-available/default /etc/apache2/sites-available/test.ba
sed -i -e '/webmaster@localhost/ a\ServerName test.ba\' /etc/apache2/sites-available/test.ba
sed -i -e '/ServerName test.ba/ a\ServerAlias www.test.ba\' /etc/apache2/sites-available/test.ba
sed -i -e '/DocumentRoot/ s=$=/test=' /etc/apache2/sites-available/test.ba 
a2ensite test.ba

# Adding new DNS resolving information for the created site in the hosts file of the VM

sed -i -e '/localhost/ a\127.0.0.1 test.ba\' /etc/hosts
sed -i -e '/127.0.0.1 test.ba/ a\127.0.0.1 www.test.ba\' /etc/hosts

# Restarting apache so the made changes can take effect.

service apache2 reload
service apache2 restart


