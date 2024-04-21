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
  local server=$1
  shift

  oranje_echo "** Verbinden met $server **"
  # Probeer SSH-verbinding te maken en commando's uit te voeren
  ssh -q -t $server "$@"
  # Controleer de exit-status van de SSH-verbinding
  ssh_exit_status=$?
  if [ $ssh_exit_status -ne 0 ]; then
    rode_echo "Kan geen verbinding maken met $server."
    return 1
  fi
  oranje_echo "** Acties op $server voltooid **"
  echo
}

# Functie om het IP-adres of de hostname van de MySQL-database te verkrijgen
function get_mysql_ip() {
    read -p "Voer het IP-adres of de hostname in voor de MySQL-server: " mysql_ip
    if [[ -z "$mysql_ip" ]]; then
        rode_echo "Ongeldige invoer. IP-adres of hostname is vereist. Script afgebroken."
        exit 1
    fi
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
echo "WordPress zal worden geïnstalleerd op de volgende servers: ${servers[*]}"
read -p "Wil je doorgaan (j/n): " keuze

if [ "$keuze" == "j" ]; then
    succes_aantal=0
    installatie_mislukt_aantal=0

    # Vraag het IP-adres of de hostname voor de MySQL-database
    get_mysql_ip

    # Loop door servers en voer stappen uit
    for server in "${servers[@]}"; do
        # Controleer of de server bereikbaar is
        if ! ping -c 1 -W 1 "$server" &> /dev/null; then
            rode_echo "Server $server is niet bereikbaar. Installatie wordt overgeslagen."
            ((installatie_mislukt_aantal++))
            continue
        fi
        
        # Installeer WordPress
        uitvoeren_op_server $server <<EOF
            echo "** WordPress installeren **"
            sudo apt update && sudo apt install -y wordpress
            if [ \$? -eq 0 ]; then
                echo "WordPress installatie op $server voltooid."
                ((succes_aantal++))
            else
                echo "WordPress installatie op $server mislukt."
                ((installatie_mislukt_aantal++))
            fi
EOF
        lijn_scheider
    done

    lijn_scheider
    groene_echo "** SAMENVATTING **"
    echo
    groene_echo "WordPress succesvol geïnstalleerd op $succes_aantal server(s)."
    rode_echo "Totaal aantal installatiefouten: $installatie_mislukt_aantal"
    lijn_scheider
    echo
elif [ "$keuze" == "n" ]; then
    oranje_echo "Gebruiker heeft het script afgebroken."
else
    rode_echo "Ongeldige invoer. Script afgebroken."
fi
