#!/usr/bin/env bash

# si quieres usar una contraseña personalizada cambia las variables abajo
# use comillas simples para que funciones los valores con caracteres especiales

DB_USER='db_user'
DB_PASSWORD='db_pass'
PROJECTNAME="gcrisk"
COMPOSERINSTALLFOLDER="/gc_risk_mini"

# Solo sirve para conectarse por medio de phpmyadmin
PASSWORD='root_pass'

INSTALL_R="false"
INSTALL_PHPMYADMIN="false"
INSTALL_MYSQL="true"
INSTALL_COMPOSER="true"
INSTALL_XDEBUG="true"



sudo touch /home/vagrant/log_install

# configuraciones de paquetes del servidor
# <----------
echo "Actualizando lista de dependencias..."
sudo apt-get update

echo "Actualizando dependencias..."
sudo apt-get -y -q upgrade

echo "Instalando paquete de lenguage (es_ES)..."
sudo apt-get -y -q install language-pack-es-base

echo "Instalando apache..."
sudo apt-get -y -q install apache2

if [ $INSTALL_MYSQL = "true" ]
then
    echo "Instalando mysql..."
    sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
    sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
    sudo apt-get -y -q install mysql-server
fi


echo "Instalando php..."
sudo apt-get -y -q install php

echo "Instalando dependencias de php (mysql,soap,sqlite3)..."
sudo apt-get -y -q install php-{mysql,soap,sqlite3}

if [ $INSTALL_PHPMYADMIN = "true" ]
then
    echo "Instalando phpmyadmin..."
    sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
    sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PASSWORD"
    sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSWORD"
    sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PASSWORD"
    sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
    sudo apt-get -y -q install phpmyadmin
fi
echo "Instalando git..."
# install git
sudo apt-get -y -q install git

if [ $INSTALL_COMPOSER = "true" ]
then
    # install Composer
    echo "Instalando composer..."
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
fi

# ------->

echo "Configurando apache..."
# <<<<<------------------------- APACHE
# configuracion del vhost apache
VHOST=$(cat <<EOF
<VirtualHost *:80>
    DocumentRoot "/var/www/html/$PROJECTNAME"
    <Directory "/var/www/html/$PROJECTNAME">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
<IfModule mod_ssl.c>
        <VirtualHost *:443>
                ServerAdmin your_email@example.com
                ServerName server_domain_or_IP

                DocumentRoot /var/www/html

                ErrorLog ${APACHE_LOG_DIR}/error.log
                CustomLog ${APACHE_LOG_DIR}/access.log combined

                SSLEngine on

                SSLCertificateFile      /var/www/html/apache-selfsigned.crt
                SSLCertificateKeyFile /var/www/html/apache-selfsigned.key

                <FilesMatch "\.(cgi|shtml|phtml|php)$">
                                SSLOptions +StdEnvVars
                </FilesMatch>
                <Directory /usr/lib/cgi-bin>
                                SSLOptions +StdEnvVars
                </Directory>

        </VirtualHost>
</IfModule>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-available/000-default.conf

# configuracion de prioridad de tipo de archivos
PRIORITYTYPE=$(cat <<EOF
<IfModule mod_dir.c>
        DirectoryIndex index.php index.html index.htm index.cgi index.pl index.xhtml
</IfModule>
EOF
)
echo "$PRIORITYTYPE" > /etc/apache2/mods-available/dir.conf



# enable mod_rewrite
sudo a2enmod rewrite
sudo a2enmod ssl
sudo a2enmod headers

sudo sed -i "s/;extension=pdo_sqlite/extension=pdo_sqlite/" "/etc/php/7.2/apache2/php.ini"
sudo sed -i "s/;extension=soap/extension=soap/" "/etc/php/7.2/apache2/php.ini"
sudo sed -i "s/;extension=sqlite3/extension=sqlite3/" "/etc/php/7.2/apache2/php.ini"
sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 750M/" "/etc/php/7.2/apache2/php.ini"
sudo sed -i "s/post_max_size = 8M/post_max_size = 250M/" "/etc/php/7.2/apache2/php.ini"
sudo sed -i "s/max_execution_time = 30/max_execution_time = 1800/" "/etc/php/7.2/apache2/php.ini"
sudo sed -i "s/memory_limit = 128M/memory_limit = 500M/" "/etc/php/7.2/apache2/php.ini"


sudo mv /etc/php/7.2/mods-available/sockets.ini /etc/php/7.2/mods-available/__sockets.ini__
sudo mv /etc/php/7.2/mods-available/calendar.ini /etc/php/7.2/mods-available/__calendar.ini__
sudo mv /etc/php/7.2/mods-available/exif.ini /etc/php/7.2/mods-available/__exif.ini__
sudo mv /etc/php/7.2/mods-available/ftp.ini /etc/php/7.2/mods-available/__ftp.ini__
sudo mv /etc/php/7.2/mods-available/mysqli.ini /etc/php/7.2/mods-available/__mysqli.ini__
sudo mv /etc/php/7.2/mods-available/readline.ini /etc/php/7.2/mods-available/__readline.ini__
sudo mv /etc/php/7.2/mods-available/shmop.ini /etc/php/7.2/mods-available/__shmop.ini__
sudo mv /etc/php/7.2/mods-available/sysvmsg.ini /etc/php/7.2/mods-available/__sysvmsg.ini__
sudo mv /etc/php/7.2/mods-available/sysvsem.ini /etc/php/7.2/mods-available/__sysvsem.ini__
sudo mv /etc/php/7.2/mods-available/sysvshm.ini /etc/php/7.2/mods-available/__sysvshm.ini__

if [ $INSTALL_XDEBUG = "true" ]
then
    echo "Instalando xdebug..."
    # XDEBUG
    wget -q "http://xdebug.org/files/xdebug-2.9.0.tgz"
    sudo apt-get -y -q install php-dev autoconf automake
    tar -xvzf xdebug-2.9.0.tgz
    cd "/home/vagrant/xdebug-2.9.0"
    phpize
    ./configure 
    make 
    cp /home/vagrant/xdebug-2.9.0/modules/xdebug.so /usr/lib/php/20170718
    echo "zend_extension = /usr/lib/php/20170718/xdebug.so" >> /etc/php/7.2/apache2/php.ini
    echo "[XDebug]" >> /etc/php/7.2/apache2/php.ini
    echo "xdebug.remote_enable=1" >> /etc/php/7.2/apache2/php.ini
    echo "xdebug.remote_autostart=1" >> /etc/php/7.2/apache2/php.ini
    echo "xdebug.remote_host=10.0.2.2" >> /etc/php/7.2/apache2/php.ini
    echo "xdebug.remote_connect_back=1" >> /etc/php/7.2/apache2/php.ini
fi
# restart apache
service apache2 restart
if [ $INSTALL_MYSQL = "true" ]
then
    echo "Configurando mysql..."
    # ------------------------------------>>>>>>>>>>>>
    # configuraciones para mysql
    sudo sed -i "s/bind-address/#bind-address/" "/etc/mysql/mysql.conf.d/mysqld.cnf"
    sudo cp  /var/www/html/vagrant_config/my.cnf /etc/mysql/conf.d/my.cnf
    # restart mysql
    sudo service mysql restart
fi
# remover el archivo de index por defecto de apache2
sudo rm "/var/www/html/index.html"


if [ $INSTALL_R = "true" ]
then
    cd "/home/vagrant"

    echo "Instalado R..."

    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
    sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'
    sudo apt update


    sudo apt-get -y -q install openjdk-8-jre r-base
    sudo apt -y -q remove r-*
    wget -q "https://cran.r-project.org/src/base/R-3/R-3.5.1.tar.gz";
    tar -xvzf R-3.5.1.tar.gz
    cd "R-3.5.1"
    sudo apt-get -y -q install fort77‍‍‍‍‍‍
    sudo apt-get -y -q install libreadline-dev
    sudo apt-get -y -q install zlib1g-dev
    sudo apt-get -y -q install libbz2-dev
    sudo apt-get -y -q install lzma-dev
    sudo apt-get -y -q install liblzma-dev
    sudo apt-get -y -q install libcurl4-openssl-dev
    sudo ./configure --with-x=no
    sudo make

    sudo mv /home/vagrant/R-3.5.1/bin/R /usr/local/bin/R
    sudo mv /home/vagrant/R-3.5.1/bin/Rscript /usr/local/bin/Rscript
fi


if [ $INSTALL_COMPOSER = "true" ]
then
    echo "Instalado dependencias composer..."
    # entra a la carpeta y ejecuta composer
    cd "/var/www/html/$PROJECTNAME$COMPOSERINSTALLFOLDER"

    composer install
    echo "================================================================================================================================"
    echo "composer done"
    echo "================================================================================================================================"
fi

if [ $INSTALL_MYSQL = "true" ]
then
    echo "Configurando usuarios db..."
    # creacion de usuario para poder acceder a la bd desde el exterior
    sudo mysql -h "localhost" -u "root" "-p${PASSWORD}" -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
    sudo mysql -h "localhost" -u "root" "-p${PASSWORD}" -e "GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'localhost' WITH GRANT OPTION;"
    sudo mysql -h "localhost" -u "root" "-p${PASSWORD}" -e "CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
    sudo mysql -h "localhost" -u "root" "-p${PASSWORD}" -e "GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'%' WITH GRANT OPTION;"

    echo "================================================================================================================================"
    echo "user created"
    echo "================================================================================================================================"
    echo "Instalado bd disponible en el path 'vagrant_config/bd.sql'"
    sudo mysql -h "localhost" -u "root" "-p${PASSWORD}" < "/var/www/html/vagrant_config/bd.sql"

    echo "================================================================================================================================"
    echo "BD Upload"
    echo "================================================================================================================================"
fi

echo "ALL DONE"
