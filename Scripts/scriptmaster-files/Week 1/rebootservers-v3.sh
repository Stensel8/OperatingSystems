#!/bin/bash

########################################################################################
# © Sten Tijhuis - 550600
########################################################################################

# Function to display colored messages (optional for aesthetics)
function colored_echo() {
  local color_code="$1"
  local message="$2"
  echo -e "\e[${color_code}m${message}\e[0m"
}

# Function to reboot a server with retry and unreachable handling
function reboot_server() {
  local server_name="$1"
  local retry_count=0

  # Loop for retry attempts (3 times)
  while [[ $retry_count -lt 3 ]]; do
    colored_echo 33 "Attempting to reboot $server_name..."  # Orange for attempt message (color code 33)
    ssh $server_name "reboot" &  # Issue reboot command asynchronously (&)

    # Check if server is reachable using ping
    if ping -c 1 $server_name &> /dev/null; then
      colored_echo 32 "Success!"  # Green for success message (color code 32)
      break
    else
      colored_echo 31 "That host is unreachable. Retrying: $((retry_count + 1)) of 3."  # Red for unreachable message (color code 31)
      colored_echo 34 "Note: Cancel with CTRL+C."  # Blue for informational message (color code 34)
      sleep 10
      retry_count=$((retry_count + 1))
    fi
  done

  # Handle failure after retries
  if [[ $retry_count -eq 3 ]]; then
    colored_echo 31 "Failed to reach $server_name after 3 retries. Aborting script."
    exit 1
  fi
}

# Check if any arguments are provided
if [[ $# -eq 0 ]]; then
  colored_echo 34 "SYNOPSYS: rebootservers-v3.sh <server1> <server2> ...(Divide the servernames with a space)"  # Blue for synopsis (color code 34)
  exit 1
fi

# Main script execution
server_count=$#
colored_echo 33 "Sending reboot commands to $server_count servers..."  # Orange for sending commands (color code 33)

# Loop through each server name (space-separated arguments)
for server_name in "$@"; do
  reboot_server "$server_name"
done

colored_echo 33 "Rebooting current machine..."  # Orange for rebooting message (color code 33)
sleep 3
colored_echo 32 "Bye!"  # Green for goodbye message (color code 32)
reboot
