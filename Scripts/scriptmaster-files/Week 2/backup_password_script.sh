#!/bin/bash

# Function to display colored messages
function color_msg() {
  local color="$1"
  local msg="$2"
  case "$color" in
    red) echo -e "\e[31m$msg\e[0m" ;;
    green) echo -e "\e[32m$msg\e[0m" ;;
    orange) echo -e "\e[33m$msg\e[0m" ;;
    blue) echo -e "\e[34m$msg\e[0m" ;;
    *) echo "$msg" ;;
  esac
}

# Function to display a line separator
function line_separator() {
  echo "--------------------------------------------------------------"
}

# Check if serverstobackup file is provided as a parameter
if [ $# -eq 0 ]; then
    color_msg red "SYNOPSIS: $0 <ServersToBackup.conf>"
    exit 1
fi

serverstobackup_file=$1

# Check if the serverstobackup file exists
if [ ! -f "$serverstobackup_file" ]; then
    color_msg red "File $serverstobackup_file does not exist. Script aborted."
    exit 1
fi

# Extract server names from serverstobackup file
servers=($(grep -v "^#" "$serverstobackup_file"))

# Create directory for backup password files if it doesn't exist
backup_dir="/home/sten/backuppasswordfiles"
mkdir -p "$backup_dir"

success_count=0
fail_count=0

echo "Starting password backup process..."

# Loop through servers extracted from serverstobackup file
for server in "${servers[@]}"; do
    # Create directory for server backup
    server_backup_dir="$backup_dir/$server"
    if [ ! -d "$server_backup_dir" ]; then
        mkdir -p "$server_backup_dir"
    fi

    # Attempt to copy /etc/passwd and /etc/shadow files from server
    ssh "$server" "sudo cp /etc/passwd /etc/shadow ~/" &> /dev/null

    # Check if copy operation was successful
    if [ $? -eq 0 ]; then
        # Move copied files to server's backup directory
        ssh "$server" "sudo mv -i ~/passwd ~/shadow '$server_backup_dir/'" &> /dev/null
        if [ $? -eq 0 ]; then
            color_msg green "Backup password files $server succeeded."
            ((success_count++))
        else
            color_msg orange "Failed to move backup files to $server_backup_dir. Skipping backup for $server."
            ((fail_count++))
        fi
    else
        color_msg red "Backup password files $server failed."
        ((fail_count++))
    fi
    line_separator
done

line_separator
color_msg green "Backup: $success_count servers have been successfully backed up."
color_msg red "Backup: $fail_count backups failed."
line_separator

# Print the path where the backups are made
color_msg blue "Backup files are located in: $backup_dir"
