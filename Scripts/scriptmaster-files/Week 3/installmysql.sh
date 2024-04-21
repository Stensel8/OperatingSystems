#!/bin/bash

########################################################################################
# © Sten Tijhuis - 550600
# installmysql.sh
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

# Installeren en configureren van MySQL-server voor WordPress
function install_mysql_for_wordpress() {
  blauwe_echo "** MySQL-server installeren en configureren voor WordPress **"
  
  # MySQL-server installeren
  oranje_echo "MySQL-server installeren..."
  sudo apt update && sudo apt install -y mysql-server
  
  # MySQL-service starten als deze niet al actief is
  oranje_echo "MySQL-service starten..."
  sudo systemctl start mysql
  
  # MySQL-queries uitvoeren om database, gebruiker en privileges in te stellen
  oranje_echo "MySQL-database en gebruiker configureren voor WordPress..."
  sudo mysql <<EOF
CREATE DATABASE wordpress;
CREATE USER 'wordpress'@'localhost' IDENTIFIED BY 'your-password';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost';
FLUSH PRIVILEGES;
EOF
  
  # MySQL gegevens tonen
  lijn_scheider
  groene_echo "MySQL-gegevens voor WordPress:"
  groene_echo "Database: wordpress"
  groene_echo "Gebruiker: wordpress"
  groene_echo "Wachtwoord: your-password"
  lijn_scheider
}

# Hoofdscript
oranje_echo "Wil je MySQL-server installeren en configureren voor WordPress? (ja/nee)"
read -p "Antwoord: " antwoord

if [ "$antwoord" == "ja" ]; then
  install_mysql_for_wordpress
else
  rode_echo "MySQL-installatie overgeslagen."
fi

# Installeren van WordPress op externe servers
oranje_echo "Wil je WordPress installeren op externe servers? (ja/nee)"
read -p "Antwoord: " wordpress_antwoord

if [ "$wordpress_antwoord" == "ja" ]; then
  oranje_echo "Geef het configuratiebestand op om servers uit te lezen:"
  read -p "Configuratiebestand: " configuratiebestand
  
  if [ ! -f "$configuratiebestand" ]; then
    rode_echo "Fout: Configuratiebestand niet gevonden. Script afgebroken."
    exit 1
  fi
  
  blauwe_echo "WordPress wordt geïnstalleerd op externe servers..."
  ./installwordpress.sh "$configuratiebestand"
else
  rode_echo "WordPress-installatie op externe servers overgeslagen."
fi
