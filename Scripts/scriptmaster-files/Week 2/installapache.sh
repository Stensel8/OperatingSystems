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

# Function to connect to a server and execute commands
function run_on_server() {
  server=$1
  shift

  color_msg orange "** Connecting to $server **"
  # Attempt SSH connection and execute commands
  ssh -q -t $server "$@"
  # Check the exit status of the SSH connection attempt
  ssh_exit_status=$?
  if [ $ssh_exit_status -ne 0 ]; then
    color_msg red "Failed to connect to $server."
    return 1
  fi
  color_msg orange "** Actions on $server completed **"
  echo
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

# Read hostnames and IP addresses alternatively from the configuration file
servers=($(grep -v "^#" "$configuration_file"))

echo "Installation via configuration file $configuration_file."
echo "Apache will be installed and started on the following servers: ${servers[*]}"
read -p "Do you want to proceed (y/n): " choice

if [ "$choice" == "y" ]; then
    success_count=0
    already_running_count=0
    already_running_servers=""
    already_installed_not_running_servers=""
    install_failure_count=0

    # Loop through servers and perform steps
    for server in "${servers[@]}"; do
        # Check if the server is reachable
        if ! ping -c 1 -W 1 "$server" &> /dev/null; then
            color_msg red "Server $server is not reachable. Skipping installation."
            ((install_failure_count++))
            continue
        fi
        
        # Check if Apache is already installed and running
        if ssh -q $server "sudo systemctl is-active --quiet apache2"; then
            color_msg green "Apache is already running on $server."
            ((already_running_count++))
            already_running_servers+=" $server"
        elif ssh -q $server "dpkg -l | grep -q apache2"; then
            color_msg orange "Apache is installed but not running on $server. Attempting to start..."
            if ssh -q $server "sudo systemctl start apache2"; then
                color_msg green "Apache started successfully on $server."
                ((success_count++))  # Increment success count for servers where Apache was started successfully
            else
                color_msg red "Failed to start Apache on $server. It seems the package has become corrupt."
                color_msg red "You should consider fixing this yourself. Use 'sudo apt autoremove' to do so."
            fi
            already_installed_not_running_servers+=" $server"  # Add the server to the list of already installed but not running servers
        else
            # Install and start Apache
            run_on_server $server <<EOF
                echo "** Installing Apache web server **"
                sudo apt update && sudo apt install -y apache2
                if [ \$? -eq 0 ]; then
                    sudo systemctl start apache2
                    if [ \$? -eq 0 ]; then
                        echo "Installation on $server completed."
                        ((success_count++))
                    else
                        echo "Failed to start Apache on $server."
                        ((install_failure_count++))
                    fi
                else
                    echo "Installation on $server failed."
                    ((install_failure_count++))
                fi
EOF
        fi
        line_separator
    done

    line_separator
    color_msg green "** SUMMARY **"
    echo
    color_msg green "Apache started successfully on $success_count server(s)."
    color_msg blue "Apache is already running on $already_running_count server(s):$already_running_servers"
    color_msg orange "Apache was already installed but not running on:$already_installed_not_running_servers"
    color_msg red "Total install failures: $install_failure_count"
    line_separator
    echo
elif [ "$choice" == "n" ]; then
    color_msg orange "User aborted the script."
else
    color_msg red "Invalid input. Script aborted."
fi
