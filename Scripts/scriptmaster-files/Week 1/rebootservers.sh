#!/bin/bash

########################################################################################
# This is a script that will loop through each server and will send a reboot command.
# Note that this will only work if the usernames and servernames in this script are correct.

# Prerequistes:
# 1. A DNS server of a static /etc/hosts file with servernames set on this machine.
# 2. SSH-access to the servers you want to restart.
# 3. Public / Private keys need to be set for auto execution.

########################################################################################
# Set the credentials. We only need to set a name, since we're using RSA-keys.
########################################################################################
USERNAME="root"
SERVERS=("gameserver01" "gameserver02")


########################################################################################
# Ask the user and reboot the gameserver cluster if he or she wants to.
########################################################################################
for server in "${SERVERS[@]}";
do
  echo "Rebooting $server..."
  ssh "$USERNAME@$server" reboot
done
