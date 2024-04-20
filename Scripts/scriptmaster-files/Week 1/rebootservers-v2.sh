#!/bin/bash

########################################################################################
# © Sten Tijhuis - 550600
# rebootservers-v2.sh
########################################################################################

########################################################################################
# Vraag de gebruiker om het gehele groepje servers te herstarten.
########################################################################################

if [[ $keuze == "j" || $keuze == "J" ]]; then
  echo "Alle hosts (het hele cluster) worden opnieuw opgestart..."

  for host in gameserver01 gameserver02; do
    echo "Poging om $host opnieuw op te starten..."
    ssh $host "reboot" &

    sleep 10
    if ping -c 1 $host &> /dev/null; then
      echo "Succes!"
    else
      echo "Niet gelukt om $host opnieuw op te starten."
    fi
  done

  echo "Huidige machine wordt opnieuw opgestart..."
  sleep 3
  echo "Tot ziens!"
  reboot
else
  echo "Script is uitgevoerd, maar er was een probleem met het opnieuw opstarten van (een van) de machines of de gebruiker heeft het script geannuleerd!"
fi
