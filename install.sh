#!/bin/bash

set -e

# Install dependencies
echo "Installing dependencies..."
if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y docker.io nginx lsof jq
else
    echo "apt-get not found. This script is designed for Debian-based systems (like Ubuntu)."
    exit 1
fi

# Copy devopsfetch script to /usr/local/bin
echo "Copying devopsfetch script to /usr/local/bin..."
sudo cp devopsfetch.sh /usr/local/bin/devopsfetch
sudo chmod +x /usr/local/bin/devopsfetch

# Set up systemd service
echo "Setting up systemd service..."
sudo tee /etc/systemd/system/devopsfetch.service > /dev/null << EOF
[Unit]
Description=DevOpsFetch Monitoring Service
After=network.target

[Service]
ExecStart=/usr/local/bin/devopsfetch
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
echo "Reloading systemd, enabling and starting the service..."
sudo systemctl daemon-reload
sudo systemctl enable devopsfetch.service
sudo systemctl start devopsfetch.service

echo "DevOpsFetch has been installed and the monitoring service has been started."
