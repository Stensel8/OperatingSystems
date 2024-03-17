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
echo "Docker will be installed on the following servers: ${servers[*]}"
read -p "Do you want to proceed (y/n): " choice

if [ "$choice" == "y" ]; then
    success_count=0
    skip_count=0

    # Loop through servers and perform steps
    for server in "${servers[@]}"; do
        # Check if the server is reachable
        if ! ping -c 1 -W 1 "$server" &> /dev/null; then
            color_msg red "Server $server is not reachable. Skipping installation."
            continue
        fi
        
        # Check if Docker is already installed
        if ssh -q $server "sudo docker run hello-world &> /dev/null"; then
            color_msg green "Docker is already installed on $server."
            ((skip_count++))
        else
            # Install Docker using the convenience script
            run_on_server $server <<EOF
                echo "** Installing Docker **"
                curl -fsSL https://get.docker.com -o get-docker.sh
                sudo sh get-docker.sh
                sudo usermod -aG docker \$USER
                sudo systemctl enable docker
                sudo systemctl start docker
                rm get-docker.sh
EOF
            if [ $? -eq 0 ]; then
                color_msg green "Docker installed successfully on $server."
                ((success_count++))
            else
                color_msg red "Failed to install Docker on $server."
            fi
        fi
        line_separator
    done

    line_separator
    color_msg green "** SUMMARY **"
    echo
    color_msg green "Docker installed successfully on $success_count server(s)."
    color_msg blue "Docker was already installed on $skip_count server(s)."
    line_separator
    echo
elif [ "$choice" == "n" ]; then
    color_msg orange "User aborted the script."
else
    color_msg red "Invalid input. Script aborted."
fi
