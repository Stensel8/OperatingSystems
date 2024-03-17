#!/bin/bash
clear

# Function to display error messages
error() {
  echo -e "\e[31mError: $1\e[0m" >&2
  exit 1
}

# Function to validate IP address format
validate_ip() {
  local ip=$1
  if [[ ! $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    return 1
  fi
}

# Function to add whitespace for clearer output
custom_echo() {
  echo -e "\n\e[33m$1\e[0m"
}

# Function to test and display ping status
test_ip_and_display() {
  local ip=$1
  local counter=$2
  local total=$3

  ping -c 1 "$ip" &> /dev/null
  if [[ $? -eq 0 ]]; then
    echo -e "\e[32mTesting ${counter}/${total}.... OK. Machine seems up!\e[0m"
  else
    echo -e "\e[31mERROR! Testing ${counter}/${total}.... $ip seems down.\e[0m"
    return 1  # Return non-zero exit code on error
  fi
}

# Function to read IP addresses
read_ip_addresses() {
  retry_count=0
  max_retries=3
  valid_inputs=false

  custom_echo "What is the IP-address of the VM currently in use (scriptmaster)?"
  while true; do
    read IPMASTER
    if validate_ip "$IPMASTER"; then
      break
    fi

    ((retry_count++))
    if ((retry_count >= max_retries)); then
      error "Exceeded maximum number of retries. Exiting."
    fi
    clear
    echo -e "\e[31mInvalid IP address format. Please try again.\e[0m"
  done

  retry_count=0

  custom_echo "Enter the IP-address of gameserver01:"
  while true; do
    read IPSERVER1
    if validate_ip "$IPSERVER1"; then
      break
    fi

    ((retry_count++))
    if ((retry_count >= max_retries)); then
      error "Exceeded maximum number of retries. Exiting."
    fi
    clear
    echo -e "\e[31mInvalid IP address format. Please try again.\e[0m"
  done

  retry_count=0

  custom_echo "Enter the IP-address of gameserver02:"
  while true; do
    read IPSERVER2
    if validate_ip "$IPSERVER2"; then
      break
    fi

    ((retry_count++))
    if ((retry_count >= max_retries)); then
      error "Exceeded maximum number of retries. Exiting."
    fi
    clear
    echo -e "\e[31mInvalid IP address format. Please try again.\e[0m"
  done

  valid_inputs=true
}

# Function to test all entered IPs
test_all_ips() {
  if [[ $valid_inputs == true ]]; then
    # Test each IP and exit script if any fail
    if ! test_ip_and_display "$IPMASTER" 1 3; then
      exit 1
    fi
    if ! test_ip_and_display "$IPSERVER1" 2 3; then
      exit 1
    fi
    test_ip_and_display "$IPSERVER2" 3 3  # Test the last one even if previous fail
  else
    echo -e "\e[31mTesting aborted. Please enter valid IP addresses first.\e[0m"
  fi
}

# Read initial IP addresses and start testing
read_ip_addresses
test_all_ips

########################################################################################
# Generate some ssh-keys for the root user and copy them to the Ubuntu 22.04 Servers.
########################################################################################

if [[ $? -eq 0 ]]; then
  custom_echo
  custom_echo "\e[33mGenerating ssh-keys...\e[0m"
  ssh-keygen
fi

USER="root"

for HOST in $IPSERVER1 $IPSERVER2
do
  custom_echo
  custom_echo "\e[33mAttempting to copy ssh-keys to $HOST...\e[0m"
  if ssh-copy-id -f -i ~/.ssh/id_rsa.pub $USER@$HOST; then
    custom_echo "\n\n \e[32mssh-keys installed on $HOST \e[0m \n\n"
  else
    custom_echo "\e[31mFailed to copy ssh-keys to $HOST. Please check its reachability and try again.\e[0m"
  fi
done

########################################################################################
# Set the hostname on the current machine to scriptmaster.
########################################################################################

custom_echo
custom_echo "\e[33mSetting hostname of current machine to 'scriptmaster'...\e[0m"
hostnamectl set-hostname scriptmaster && echo -e "\e[32mHostname set!\e[0m"

########################################################################################
# Update the /etc/hosts to resolve servers (manual DNS resolving).
########################################################################################

custom_echo "\e[33mUpdating /etc/hosts with DNS entries...\e[0m"

cat << EOF > /etc/hosts
# /etc/hosts

127.0.0.1 localhost
$IPMASTER     scriptmaster  
$IPSERVER1    gameserver01  
$IPSERVER2    gameserver02  
EOF

echo -e "\e[33mWarning: Overwriting /etc/hosts file with new entries. This will clear old DNS entries.\e[0m"
read -p "Continue? (y/n): " choice

if [[ $choice != "y" && $choice != "Y" ]]; then
    echo -e "\e[31mExiting as per user request.\e[0m"
    exit 1
fi

########################################################################################
# Copy the /etc/hosts DNS entries to the other servers.
########################################################################################

custom_echo "\e[33mAttempting to copy DNS entries to other servers...\e[0m"

for HOST in "gameserver01" "gameserver02"; do
    scp -q /etc/hosts $HOST:/etc/hosts && echo -e "\e[32mDNS entries copied to $HOST!\e[0m"
done

# Set hostname on each server after copying DNS entries
for HOST in "gameserver01" "gameserver02"; do
    custom_echo "\e[33mSetting hostname on $HOST...\e[0m"
    ssh $HOST "hostnamectl set-hostname $HOST" && echo -e "\e[32mHostname set on $HOST!\e[0m"
done

########################################################################################
# Reboot the whole cluster so the new hostnames are being applied.
########################################################################################

custom_echo ""
read -p "Do you want to reboot the affected machines to apply the pending name changes? (y/n): " choice
if [[ $choice == "y" || $choice == "Y" ]]; then
  custom_echo "\e[33mRebooting all hosts (whole cluster)...\e[0m"
  for HOST in "gameserver01" "gameserver02"; do
    custom_echo "Attempting to reboot $HOST... "
    ssh $HOST "reboot" &

    # Waiting loop with progress updates
    max_retries=10  # Adjust as needed
    for retry_count in $(seq 1 $max_retries); do
      sleep 10
      if ping -c 1 $HOST &> /dev/null; then
        echo -e "\e[32mSuccess!\e[0m"
        break
      else
        echo -n "$((retry_count * 10))/100s..."  # Time-based progress indicator
      fi
    done

    if [[ $retry_count == $max_retries ]]; then
      echo -e "\n\e[33mReboot command sent, connection was lost, but the script hasn't detected the host coming back up.\e[0m"
      echo -e "\e[31mFailed to reboot $HOST after $max_retries retries\e[0m"
    fi
  done
    # Reboot the current machine
    custom_echo "\e[33mRebooting current machine...\e[0m"
    sleep 3
    custom_echo "\e[32mBye!\e[0m"
    reboot
else
    echo "Script has been executed, however there was a problem rebooting (one of) the machines!"
fi
