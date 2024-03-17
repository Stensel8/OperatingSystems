#!/bin/bash

########################################################################################
# © Sten Tijhuis - 550600
########################################################################################

# Function definitions

function red_echo() {
  echo -e "\e[31m$1\e[0m"
}

function orange_echo() {
  echo -e "\e[33m$1\e[0m"
}

function green_echo() {
  echo -e "\e[32m$1\e[0m"
}

function blue_echo() {
  echo -e "\e[34m$1\e[0m"
}

########################################################################################
# Ask the user and reboot the gameserver cluster if he or she wants to.
########################################################################################

read -p "Do you want to reboot the gameservers? (y/n): " choice

if [[ $choice == "y" || $choice == "Y" ]]; then
  orange_echo "Rebooting all hosts (whole cluster)..."

  for host in "gameserver01" "gameserver02"; do
    orange_echo "Attempting to reboot $host..."
    ssh $host "reboot" &

    # Waiting loop with progress updates
    max_retries=10
    for retry_count in $(seq 1 $max_retries); do
      sleep 10
      if ping -c 1 $host &> /dev/null; then
        green_echo "Success!"
        break
      else
        echo -n "$((retry_count * 10))/100s..."
      fi
    done

    if [[ $retry_count == $max_retries ]]; then
      red_echo "\nReboot command sent, connection was lost, but the script hasn't detected the host coming back up."
      red_echo "Failed to reboot $host after $max_retries retries"
    fi
  done

  orange_echo "Rebooting current machine..."
  sleep 3
  green_echo "Bye!"
  reboot
else
  blue_echo "Script has been executed, however there was a problem rebooting (one of) the machines or the user has cancelled the script!"
fi
