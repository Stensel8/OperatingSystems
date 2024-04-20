#!/bin/bash

########################################################################################
# © Sten Tijhuis - 550600
# rebootservers-v3.sh
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

########################################################################################
# Vraag de gebruiker om het gehele groepje servers te herstarten.
########################################################################################

read -p "Wil je de gameservers (het gehele cluster) herstarten? (j/n): " keuze

if [[ $keuze == "j" || $keuze == "J" ]]; then
  oranje_echo "Alle hosts (het hele cluster) worden opnieuw opgestart..."

  for host in "gameserver01" "gameserver02"; do
    oranje_echo "Poging om $host opnieuw op te starten..."
    ssh $host "reboot" &

    # Wacht-lus met voortgangsupdates
    max_pogingen=10
    for poging_nummer in $(seq 1 $max_pogingen); do
      slaap 10
      if ping -c 1 $host &> /dev/null; then
        groene_echo "Succes!"
        pauze
        onderbreking
      else
        echo -n "$((poging_nummer * 10))/100s..."
      fi
    done

    if [[ $poging_nummer == $max_pogingen ]]; then
      rode_echo "\nOpdracht voor herstarten verzonden, verbinding verbroken, maar het script heeft niet gedetecteerd dat de host weer online is gekomen."
      rode_echo "Niet gelukt om $host opnieuw op te starten na $max_pogingen pogingen"
    fi
  done

  oranje_echo "Huidige machine wordt opnieuw opgestart..."
  slaap 3
  groene_echo "Tot ziens!"
  herstart
else
  blauwe_echo "Script is uitgevoerd, maar er was een probleem met het opnieuw opstarten van (een van) de machines of de gebruiker heeft het script geannuleerd!"
fi
