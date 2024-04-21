#!/bin/bash

########################################################################################
# © Sten Tijhuis - 550600
# migratewordpress.sh
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

# Vraag om het IP-adres van de bronserver
read -p "Voer het IP-adres of de hostname van de bronserver in: " bron_server
if [ -z "$bron_server" ]; then
    rode_echo "Ongeldig IP-adres of hostname. Script afgebroken."
    exit 1
fi

# Vraag om het IP-adres van de doelserver
read -p "Voer het IP-adres of de hostname van de doelserver in: " doel_server
if [ -z "$doel_server" ]; then
    rode_echo "Ongeldig IP-adres of hostname. Script afgebroken."
    exit 1
fi

# Kopieer de WordPress-content van de bronserver naar de doelserver met scp
oranje_echo "Kopiëren van WordPress-content van $bron_server naar $doel_server..."
scp -r $bron_server:/srv/www/wordpress/* /srv/www/wordpress/

# Controleer de exit-status van de scp-opdracht
scp_exit_status=$?
if [ $scp_exit_status -ne 0 ]; then
    rode_echo "Kopiëren van WordPress-content mislukt."
else
    groene_echo "WordPress-content succesvol gekopieerd van $bron_server naar $doel_server."
fi
