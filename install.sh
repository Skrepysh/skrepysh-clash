#!/bin/bash

echo "### Skrepysh-Clash installer ###"

# Check sudo
[[ $EUID -ne 0 ]] && echo -e "ERROR: You must be root to run this script! \n" && rm -- "$0" && exit 1

CLASH_DIR=/opt/skrepysh-clash

# Checking if CLASH_DIR exists
if [ -d "$CLASH_DIR" ]; then # if CLASH_DIR exists
    echo -e "$CLASH_DIR exists."
    read -rp "Continue anyway? [y/N]: " continue_or_not
    continue_or_not=${continue_or_not:-N}
    case "$continue_or_not" in
    [yY]|[yY][eE][sS])
        echo "OK"
        ;;
    *)
        echo "Exiting"
        rm -- "$0"
        exit 1
        ;;
    esac
else # if not exists
    mkdir "$CLASH_DIR"
    mkdir "$CLASH_DIR/files"
fi

# Downloading files
echo "Downloading Mihomo"
MIHOMO_LATEST_VERSION=$(curl -sL https://github.com/MetaCubeX/mihomo/releases/latest/download/version.txt)
curl -sL https://github.com/MetaCubeX/mihomo/releases/download/"$MIHOMO_LATEST_VERSION"/mihomo-linux-amd64-"$MIHOMO_LATEST_VERSION".gz | gunzip > "$CLASH_DIR/files/mihomo"

echo "Downloading Zashboard"
curl -sL https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip -o "$CLASH_DIR/files/zashboard.zip"

echo "Unzipping Zashboard"
unzip -q $CLASH_DIR/files/zashboard.zip -d $CLASH_DIR/files/
rm $CLASH_DIR/files/zashboard.zip

echo "Downloading skrepysh-clash executable"
curl -sL https://raw.githubusercontent.com/Skrepysh/skrepysh-clash/refs/heads/main/skrepysh-clash -o "$CLASH_DIR/skrepysh-clash"

echo "Downloading .env.example"
curl -sL https://raw.githubusercontent.com/Skrepysh/skrepysh-clash/refs/heads/main/files/.env.example -o "$CLASH_DIR/.env"

# Requesting data from user

read -rp "Enter subscription link: " SUB_LINK
read -rp "Enter port for Zashboard: " DASHBOARD_PORT
read -rp "Enter Clash API Secret: " API_SECRET

# Applying data to .env
TEMP_FILE=$(mktemp)
{
  echo "SUB_LINK=\"$SUB_LINK\""
  echo "DASHBOARD_PORT=\"$DASHBOARD_PORT\""
  echo "API_SECRET=\"$API_SECRET\""
} >> "$TEMP_FILE"
awk '/# Do not edit variables below!/{flag=1} flag' "$CLASH_DIR/.env" >> "$TEMP_FILE"
mv "$TEMP_FILE" "$CLASH_DIR/.env"

echo "Setting permissions"
chmod +x "$CLASH_DIR/files/mihomo"
chmod +x "$CLASH_DIR/skrepysh-clash"

# Installing systemd service
echo "Downloading skrepysh-clash.service"
curl -sL https://raw.githubusercontent.com/Skrepysh/skrepysh-clash/refs/heads/main/files/skrepysh-clash.service -o /etc/systemd/system/skrepysh-clash.service
echo "Reloading systemd daemon"
systemctl daemon-reload
echo "Enabling service"
systemctl enable skrepysh-clash
echo "Starting service"
systemctl start skrepysh-clash

# Finishing
echo -e "\n"
echo -e "You can access Zashboard here: http://localhost:$DASHBOARD_PORT/#/setup?hostname=localhost&port=$DASHBOARD_PORT&secret=$API_SECRET"
