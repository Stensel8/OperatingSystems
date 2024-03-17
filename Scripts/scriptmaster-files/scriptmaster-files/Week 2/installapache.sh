#!/bin/bash

# Function to display colored messages
function color_msg() {
  local color="$1"
  local msg="$2"
  case "$color" in
    red) echo -e "\e[31m$msg\e[0m" ;;
    green) echo -e "\e[32m$msg\e[0m" ;;
    orange) echo -e "\e[33m$msg\e[0m" ;;
    *) echo "$msg" ;;
  esac
}

# Check if the configuration file is provided as a parameter
if [ $# -eq 0 ]; then
    color_msg red "SYNOPSIS: $0 <configuration_file>"
    exit 1
fi

configuration_file=$1

# Check if the configuration file exists
if [ ! -f "$configuration_file" ]; then
    color_msg red "File $configuration_file does not exist. Script aborted."
    exit 1
fi

# Function to connect to a server and execute commands
function run_on_server() {
  server=$1
  shift

  color_msg orange "** Connecting to $server **"
  ssh -t $server "$@"

  color_msg orange "** Actions on $server completed **"
  echo
}

# Read hostnames and IP addresses alternatively from the configuration file
servers=($(grep -v "^#" "$configuration_file"))

echo "Installation via configuration file $configuration_file."
echo "Apache will be installed and started on the following servers: ${servers[*]}"
read -p "Do you want to proceed (y/n): " choice

if [ "$choice" == "y" ]; then
    success_count=0
    fail_count=0
    already_installed_count=0
    already_running_count=0

    # Loop through servers and perform steps
    for server in "${servers[@]}"; do
        run_on_server $server <<EOF
            echo "** Installing Apache web server **"
            sudo apt update
            if ! sudo apt install -y apache2; then
                echo "Installation on $server failed."
                ((fail_count++))
            elif sudo systemctl is-active --quiet apache2; then
                echo "Apache is already running on $server."
                ((already_running_count++))
            else
                sudo systemctl start apache2
                if [ \$? -eq 0 ]; then
                    echo "Installation on $server completed."
                    ((success_count++))
                else
                    echo "Installation on $server failed."
                    ((fail_count++))
                fi
            fi
EOF
    done

    # Count servers where Apache is already installed but not running
    for server in "${servers[@]}"; do
        if ! ssh $server "systemctl is-active --quiet apache2"; then
            ((already_installed_count++))
        fi
    done

    color_msg green "Apache started successfully on $success_count servers."
    color_msg red "Failed to start Apache on $fail_count servers."
    color_msg orange "Apache was already installed but not running on $already_installed_count servers."
    
    # Calculate the number of servers where Apache is already running
    already_running_count=$(( ${#servers[@]} - $already_installed_count - $fail_count ))

    # Update message for servers where Apache is already running
    if [ "$already_running_count" -gt 0 ]; then
        color_msg orange "Apache was already installed and running on $already_running_count servers."
    else
        color_msg orange "Apache was already installed and running on 0 servers."
    fi
elif [ "$choice" == "n" ]; then
    color_msg orange "User aborted the script."
else
    color_msg red "Invalid input. Script aborted."
fi
