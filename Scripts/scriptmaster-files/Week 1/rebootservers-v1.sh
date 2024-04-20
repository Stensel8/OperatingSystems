#!/bin/bash

########################################################################################
# © Sten Tijhuis - 550600
# rebootservers-v1.sh
########################################################################################

########################################################################################
# Vraag de gebruiker om het gehele groepje servers te herstarten.
########################################################################################

echo "Druk op een toets om de gameservers opnieuw op te starten. Gebruik CTRL + C om te annuleren."
read -n 1 -s
echo "gameserver01 herstarten..."
ssh gameserver01 "reboot" 2>/dev/null
echo "gameserver02 herstarten..." 2>/dev/null
ssh gameserver02 "reboot"
