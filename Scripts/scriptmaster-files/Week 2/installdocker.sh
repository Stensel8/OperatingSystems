#!/bin/bash

########################################################################################
# © Sten Tijhuis - 550600
# installdocker.sh
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
    rode_echo "Kan geen verbinding maken met $server."
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
echo "Docker zal worden geïnstalleerd op de volgende servers: ${servers[*]}"
read -p "Wil je doorgaan (j/n): " keuze

if [ "$keuze" == "j" ]; then
    succes_aantal=0
    overslaan_aantal=0

    # Loop door servers en voer stappen uit
    for server in "${servers[@]}"; do
        # Controleer of de server bereikbaar is
        if ! ping -c 1 -W 1 "$server" &> /dev/null; then
            rode_echo "Server $server is niet bereikbaar. Installatie wordt overgeslagen."
            continue
        fi
        
        # Controleer of Docker al is geïnstalleerd
        if ssh -q $server "sudo docker run hello-world &> /dev/null"; then
            groene_echo "Docker is al geïnstalleerd op $server."
            ((overslaan_aantal++))
        else
            # Installeer Docker met behulp van het script
            uitvoeren_op_server $server <<EOF
                echo "** Docker installeren **"
                curl -fsSL https://get.docker.com -o get-docker.sh
                sudo sh get-docker.sh
                sudo usermod -aG docker \$USER
                sudo systemctl enable docker
                sudo systemctl start docker
                rm get-docker.sh
EOF
            if [ $? -eq 0 ]; then
                groene_echo "Docker succesvol geïnstalleerd op $server."
                ((succes_aantal++))
            else
                rode_echo "Kon Docker niet installeren op $server."
            fi
        fi
        lijn_scheider
    done

    lijn_scheider
    groene_echo "** SAMENVATTING **"
    echo
    groene_echo "Docker succesvol geïnstalleerd op $succes_aantal server(s)."
    blauwe_echo "Docker was al geïnstalleerd op $overslaan_aantal server(s)."
    lijn_scheider
    echo
elif [ "$keuze" == "n" ]; then
    oranje_echo "Gebruiker heeft het script afgebroken."
else
    rode_echo "Ongeldige invoer. Script afgebroken."
fi
