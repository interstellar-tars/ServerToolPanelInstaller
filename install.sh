#!/bin/bash

# Variables
REPO_URL="https://github.com/interstellar-tars/ServerToolPanel"  # Replace with your GitHub repository
APP_NAME="server_tool"
APP_DIR="/opt/$APP_NAME"
SERVICE_NAME="server_tool.service"
NGINX_CONFIG_PATH="/etc/nginx/nginx.conf"

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "Please run this script as root."
   exit 1
fi

# Update and install necessary packages
echo "Updating system and installing dependencies..."
apt update && apt upgrade -y
apt install -y python3 python3-venv python3-pip git nginx

# Clone the GitHub repository
echo "Cloning repository from $REPO_URL..."
if [ -d "$APP_DIR" ]; then
    echo "Directory $APP_DIR already exists. Deleting it to pull the latest version."
    rm -rf "$APP_DIR"
fi
git clone "$REPO_URL" "$APP_DIR"

# Set up virtual environment and install Python packages
echo "Setting up virtual environment..."
python3 -m venv "$APP_DIR/venv"
source "$APP_DIR/venv/bin/activate"
pip install -r "$APP_DIR/requirements.txt"
deactivate

# Set permissions for the nginx config file if needed
echo "Setting permissions for $NGINX_CONFIG_PATH..."
chown www-data:www-data "$NGINX_CONFIG_PATH"

# Create systemd service
echo "Creating systemd service..."
cat << EOF > /etc/systemd/system/$SERVICE_NAME
[Unit]
Description=Server Tool Flask App
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/venv/bin"
ExecStart=$APP_DIR/venv/bin/python $APP_DIR/app.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Start and enable the service
echo "Starting and enabling $SERVICE_NAME..."
systemctl daemon-reload
systemctl start "$SERVICE_NAME"
systemctl enable "$SERVICE_NAME"

echo "Installation complete! The app should now be running on port 5000."
echo "Visit http://your_server_ip:5000 to access the app."
