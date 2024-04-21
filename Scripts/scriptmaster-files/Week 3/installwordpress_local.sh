#!/bin/bash

########################################################################################
# © Sten Tijhuis - 550600
# installwordpress_local.sh
########################################################################################

########################################################################################
# Functies aanmaken
########################################################################################

function rode_echo() {
  echo -e "\e[31m$1\e[0m"
}

function oranje_echo() {
  echo -e "\e[33m$1\e[0m"
}

function groene_echo() {
  echo -e "\e[32m$1\e[0m"
}

function blauwe_echo() {
  echo -e "\e[34m$1\e[0m"
}

# Functie om een lijn scheider weer te geven
function lijn_scheider() {
  echo "--------------------------------------------------------------"
}

# Vraag waar de MySQL-server draait
read -p "Voer het IP-adres of de hostname van de MySQL-server in: " mysql_server
if [ -z "$mysql_server" ]; then
    rode_echo "Ongeldig IP-adres of hostname. Script afgebroken."
    exit 1
fi

# Installeer benodigde pakketten voor WordPress
sudo apt update
sudo apt install -y apache2 ghostscript libapache2-mod-php php php-bcmath php-curl php-imagick php-intl php-json php-mbstring php-mysql php-xml php-zip

# Maak de directory voor WordPress en pas de eigenaar aan
sudo mkdir -p /srv/www
sudo chown www-data: /srv/www

# Download en installeer WordPress
curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www

# Maak de Apache-configuratie voor WordPress
sudo bash -c 'cat << EOFApache > /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    DocumentRoot /srv/www/wordpress
    <Directory /srv/www/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory /srv/www/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOFApache'

# Activeer de WordPress-site
sudo a2ensite wordpress

# Activeer URL rewriting
sudo a2enmod rewrite

# Schakel de standaard Apache-site uit
sudo a2dissite 000-default

# Herlaad Apache om de wijzigingen toe te passen
sudo systemctl reload apache2

# Configureer MySQL database voor WordPress
sudo mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE wordpress;
CREATE USER 'wordpress'@'$mysql_server' IDENTIFIED BY 'your-password';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'$mysql_server';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Controleer of MySQL-service correct draait
sudo systemctl status mysql

# Meld de voltooiing van de installatie
groene_echo "WordPress is succesvol geïnstalleerd op de lokale machine."
blauwe_echo "U kunt de WordPress-site bereiken op: http://localhost/wp-admin"
