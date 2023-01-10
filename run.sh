

#!/bin/bash

# Variables
port=22 # default SSH port
custom_subdomain="my-custom-subdomain" # change this to your desired custom subdomain
logfile="log.txt"

echo "Please enter the port number you wish to forward (press enter for default: 22):"
read user_port
if [ ! -z "$user_port" ]; then
    port=$user_port
fi

echo "Starting ngrok on port $port"

# Check if ngrok is installed
if ! [ -x "$(command -v ngrok)" ]; then
  echo 'Error: ngrok is not installed. Please install ngrok and run this script again.' >&2
  exit 1
fi

# Start ngrok
./ngrok tcp $port --log=stdout --log-format=json --subdomain=$custom_subdomain > $logfile &

# Get the public URL of the tunnel
public_url=$(curl --silent http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
echo "ngrok is running at $public_url"

# Ask the user if they want to open the port in the firewall
echo "Do you want to open port $port in the firewall? (y/n)"
read open_firewall

if [ "$open_firewall" == "y" ]; then
    # Open port in firewall
    sudo iptables -A INPUT -p tcp --dport $port -j ACCEPT
    echo "Port $port has been opened in the firewall."
else
    echo "Port $port was not opened in the firewall."
fi

# SSH into the tunnel
echo "Connecting to $public_url via SSH"
ssh -p $port user@$public_url

# Close the ngrok tunnel when the user exits the SSH session
kill %1
echo "ngrok tunnel closed."
