#!/bin/bash

########################################################################################
# © Sten Tijhuis - 550600
# backup-passwordfiles.sh
########################################################################################

########################################################################################
# Functies aanmaken
########################################################################################

function rode_echo() {
  echo -e "\e[31m$1\e[0m" | tee -a backup.log  # Voeg de uitvoer toe aan het logbestand
}

function oranje_echo() {
  echo -e "\e[33m$1\e[0m" | tee -a backup.log  # Voeg de uitvoer toe aan het logbestand
}

function groene_echo() {
  echo -e "\e[32m$1\e[0m" | tee -a backup.log  # Voeg de uitvoer toe aan het logbestand
}

function blauwe_echo() {
  echo -e "\e[34m$1\e[0m" | tee -a backup.log  # Voeg de uitvoer toe aan het logbestand
}

# Functie om een lijn scheider weer te geven
function lijn_scheider() {
  echo "--------------------------------------------------------------" | tee -a backup.log  # Voeg de uitvoer toe aan het logbestand
}

# Controleer of het bestand ServersToBackup is opgegeven als parameter
if [ $# -eq 0 ]; then
    rode_echo "SYNOPSIS: $0 <ServersToBackup.conf>"
    exit 1
fi

servers_tebakken_bestand=$1

# Controleer of het ServersToBackup-bestand bestaat
if [ ! -f "$servers_tebakken_bestand" ]; then
    rode_echo "Bestand $servers_tebakken_bestand bestaat niet. Script afgebroken."
    exit 1
fi

# Lees de servernamen af uit het ServersToBackup-bestand
servers=($(grep -v "^#" "$servers_tebakken_bestand"))

# Maak een directory aan voor het backuppen van wachtwoordbestanden als deze niet bestaat
backup_dir="/home/sten/backupwachtwoordbestanden"
mkdir -p "$backup_dir"

succesvol_aantal=0
mislukt_aantal=0

echo "Starten van het backupproces voor wachtwoordbestanden..." | tee -a backup.log  # Voeg de uitvoer toe aan het logbestand

# Loop door de servers die zijn afgelezen uit het ServersToBackup-bestand
for server in "${servers[@]}"; do
    # Maak een directory aan voor de backup van de server
    server_backup_dir="$backup_dir/$server"
    if [ ! -d "$server_backup_dir" ]; then
        mkdir -p "$server_backup_dir"
    fi

    # Probeer de bestanden /etc/passwd en /etc/shadow van de server te kopiëren
    scp "$server":/etc/passwd "$server":/etc/shadow "$server_backup_dir/" &>> backup.log

    # Controleer of de kopieeroperatie succesvol was
    if [ $? -eq 0 ]; then
        # Hernoem de gekopieerde bestanden naar de servernaam
        mv "$server_backup_dir/passwd" "$server_backup_dir/${server}_passwd"
        mv "$server_backup_dir/shadow" "$server_backup_dir/${server}_shadow"
        groene_echo "Backup wachtwoordbestanden van $server is gelukt."
        ((succesvol_aantal++))
    else
        rode_echo "Backup wachtwoordbestanden van $server is mislukt."
        ((mislukt_aantal++))
    fi
    lijn_scheider
done

lijn_scheider
blauwe_echo "Backup: $succesvol_aantal servers zijn succesvol geback-upt." | tee -a backup.log  # Voeg de uitvoer toe aan het logbestand
oranje_echo "Backup: $mislukt_aantal backups zijn mislukt." | tee -a backup.log  # Voeg de uitvoer toe aan het logbestand
lijn_scheider | tee -a backup.log  # Voeg de uitvoer toe aan het logbestand

# Geef het pad weer waar de backups zijn gemaakt
blauwe_echo "Backupbestanden zijn te vinden in: $backup_dir" | tee -a backup.log  # Voeg de uitvoer toe aan het logbestand
