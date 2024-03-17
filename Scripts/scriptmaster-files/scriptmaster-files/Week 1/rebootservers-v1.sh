#!/bin/bash

########################################################################################
# © Sten Tijhuis - 550600
########################################################################################

########################################################################################
# Ask the user and reboot the gameserver cluster if he or she wants to.
########################################################################################

echo "Press a key to reboot the gameservers. Use CTRL + C to cancel."
read -n 1 -s
echo "Rebooting gameserver01..."
ssh gameserver01 "reboot" 2>/dev/null
echo "Rebooting gameserver02..." 2>/dev/null
ssh gameserver02 "reboot"

