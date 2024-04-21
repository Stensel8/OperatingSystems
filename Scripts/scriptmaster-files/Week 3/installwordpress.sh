#!/bin/bash

########################################################################################
# © Sten Tijhuis - 550600
# installwordpress.sh
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

# Functie om MySQL op te zetten op de opgegeven server
setup_mysql() {
    local mysql_server_ip=$1
    # Stel MySQL in
    ssh user@$mysql_server_ip << EOF
    sudo apt update && sudo apt install -y mysql-server || exit 1
    sudo mysql_secure_installation || exit 1
EOF
    groene_echo "MySQL is geïnstalleerd en beveiligd op server $mysql_server_ip."
}

# Functie om WordPress te installeren en configureren op een server
install_wordpress() {
    local server_ip=$1

    # Stap 1: Installeer afhankelijkheden (Apache, PHP, Ghostscript)
    ssh user@$server_ip << EOF
    sudo apt update && sudo apt install -y apache2 ghostscript libapache2-mod-php php php-bcmath php-curl php-imagick php-intl php-json php-mbstring php-mysql php-xml php-zip || exit 1
    sudo mkdir -p /srv/www
    sudo chown www-data: /srv/www
    curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www || exit 1
EOF
    groene_echo "Afhankelijkheden zijn geïnstalleerd op server $server_ip."

    # Stap 2: Configureer Apache voor WordPress
    ssh user@$server_ip << EOF
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
    sudo a2ensite wordpress || exit 1
    sudo a2enmod rewrite || exit 1
    sudo a2dissite 000-default || exit 1
    sudo systemctl reload apache2 || exit 1
EOF
    groene_echo "Apache is geconfigureerd voor WordPress op server $server_ip."

    # Stap 3: Configureer WordPress om verbinding te maken met de database
    ssh user@$server_ip << EOF
    sudo -u www-data cp /srv/www/wordpress/wp-config-sample.php /srv/www/wordpress/wp-config.php || exit 1
    sudo -u www-data sed -i 's/database_name_here/wordpress/' /srv/www/wordpress/wp-config.php || exit 1
    sudo -u www-data sed -i 's/username_here/wordpress/' /srv/www/wordpress/wp-config.php || exit 1
    sudo -u www-data sed -i 's/password_here/<uw-wachtwoord>/' /srv/www/wordpress/wp-config.php || exit 1
    sudo -u www-data sed -i '/define( '\''AUTH_KEY'\''/{N;N;N;N;N;N;N;N;d;}' /srv/www/wordpress/wp-config.php || exit 1
    sudo -u www-data curl -s https://api.wordpress.org/secret-key/1.1/salt/ | sudo -u www-data tee -a /srv/www/wordpress/wp-config.php > /dev/null || exit 1
EOF
    groene_echo "WordPress is geconfigureerd om verbinding te maken met de database op server $server_ip."

    # Vraag gebruiker om MySQL-server IP-adres
    read -p "Waar mag de MySQL database worden geïnstalleerd? Geef het IP-adres op: " mysql_ip
    if [[ -z "$mysql_ip" ]]; then
        rode_echo "Ongeldig IP-adres. Probeer opnieuw."
        exit 1
    fi

    # MySQL installeren en configureren
    setup_mysql $mysql_ip
}

# Lees production.conf en installeer WordPress op de opgegeven servers
while IFS= read -r line; do
    if [[ "$line" =~ ^[^#]*$ ]]; then
        install_wordpress $line
    fi
done < production.conf

echo "WordPress is geïnstalleerd en geconfigureerd op de opgegeven servers."
