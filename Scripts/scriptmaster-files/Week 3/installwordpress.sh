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

# Functie om verbinding te maken met een server en commando's uit te voeren
function uitvoeren_op_server() {
  server=$1
  shift

  oranje_echo "** Verbinden met $server **"
  # Probeer SSH-verbinding te maken en commando's uit te voeren
  ssh -q -t $server "$@"
  # Controleer de exit-status van de SSH-verbinding
  ssh_exit_status=$?
  if [ $ssh_exit_status -ne 0 ]; then
    rode_echo "Connectie met $server mislukt."
    return 1
  fi
  oranje_echo "** Acties op $server voltooid **"
  echo
}

# Controleer of het configuratiebestand als parameter is opgegeven
if [ $# -eq 0 ]; then
    rode_echo "SYNOPSIS: $0 <configuratiebestand>"
    exit 1
fi

configuratiebestand=$1

# Controleer of het configuratiebestand bestaat
if [ ! -f "$configuratiebestand" ]; then
    rode_echo "Bestand $configuratiebestand bestaat niet. Script afgebroken."
    exit 1
fi

# Lees hostnamen en IP-adressen afwisselend uit het configuratiebestand
servers=($(grep -v "^#" "$configuratiebestand"))

echo "Installatie via configuratiebestand $configuratiebestand."
echo "Apache zal worden geïnstalleerd en gestart op de volgende servers: ${servers[*]}"
read -p "Wil je doorgaan (j/n): " keuze

if [ "$keuze" == "j" ]; then
    succes_aantal=0
    al_geactiveerd_aantal=0
    al_geactiveerd_servers=""
    al_geïnstalleerd_niet_actief_servers=""
    installatie_mislukt_aantal=0

    # Vraag het IP-adres voor de MySQL-server
    read -p "Voer het IP-adres of de hostname van de MySQL-server in: " mysql_server
    if [ -z "$mysql_server" ]; then
        rode_echo "Ongeldig IP-adres of hostname. Script afgebroken."
        exit 1
    fi

    # Loop door servers en voer stappen uit
    for server in "${servers[@]}"; do
        # Controleer of de server bereikbaar is
        if ! ping -c 1 -W 1 "$server" &> /dev/null; then
            rode_echo "Server $server is niet bereikbaar. Installatie wordt overgeslagen."
            ((installatie_mislukt_aantal++))
            continue
        fi
        
        # Controleer of Apache al is geïnstalleerd en actief is
        if ssh -q $server "sudo systemctl is-active --quiet apache2"; then
            groene_echo "Apache draait al op $server."
            ((al_geactiveerd_aantal++))
            al_geactiveerd_servers+=" $server"
        elif ssh -q $server "dpkg -l | grep -q apache2"; then
            oranje_echo "Apache is geïnstalleerd maar niet actief op $server. Probeer te starten..."
            if ssh -q $server "sudo systemctl start apache2"; then
                groene_echo "Apache succesvol gestart op $server."
                ((succes_aantal++))  # Incrementeer het succesvolle aantal voor servers waar Apache succesvol is gestart
            else
                rode_echo "Kon Apache niet starten op $server. Het lijkt erop dat het pakket beschadigd is."
                rode_echo "Je zou dit zelf moeten oplossen. Gebruik 'sudo apt autoremove' om dit te doen."
            fi
            al_geïnstalleerd_niet_actief_servers+=" $server"  # Voeg de server toe aan de lijst van al geïnstalleerde maar niet actieve servers
        else
            # Installeer en start Apache
            uitvoeren_op_server $server <<EOF
                echo "** Apache webserver installeren **"
                sudo apt update && sudo apt install -y apache2 ghostscript libapache2-mod-php php php-bcmath php-curl php-imagick php-intl php-json php-mbstring php-mysql php-xml php-zip mysql-server
                if [ \$? -eq 0 ]; then
                    sudo mkdir -p /srv/www
                    sudo chown www-data: /srv/www
                    curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www
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
                    sudo a2ensite wordpress
                    sudo a2enmod rewrite
                    sudo a2dissite 000-default
                    sudo systemctl reload apache2
                    echo "Installatie op $server voltooid."
                    ((succes_aantal++))
                else
                    echo "Installatie op $server mislukt."
                    ((installatie_mislukt_aantal++))
                fi

                echo "** WordPress configureren **"
                sudo sed -i "s/'DB_NAME', '.*'/'DB_NAME', 'wordpress'/g" /srv/www/wordpress/wp-config.php
                sudo sed -i "s/'DB_USER', '.*'/'DB_USER', 'wordpress'/g" /srv/www/wordpress/wp-config.php
                sudo sed -i "s/'DB_PASSWORD', '.*'/'DB_PASSWORD', 'password'/g" /srv/www/wordpress/wp-config.php
                echo "WordPress configuratie voltooid op $server."

EOF
        fi
        lijn_scheider
    done

    lijn_scheider
    groene_echo "** SAMENVATTING **"
    echo
    groene_echo "Apache succesvol gestart op $succes_aantal server(s)."
    blauwe_echo "Apache draait al op $al_geactiveerd_aantal server(s):$al_geactiveerd_servers"
    oranje_echo "Apache was al geïnstalleerd maar niet actief op:$al_geïnstalleerd_niet_actief_servers"
    rode_echo "Totaal aantal installatiefouten: $installatie_mislukt_aantal"
    lijn_scheider
    echo
    blauwe_echo "U kunt de WordPress-site bereiken op de volgende URL(s):"
    for server in "${servers[@]}"; do
        blauwe_echo "http://$server/wp-admin"
    done

elif [ "$keuze" == "n" ]; then
    oranje_echo "Gebruiker heeft het script afgebroken."
else
    rode_echo "Ongeldige invoer. Script afgebroken."
fi
