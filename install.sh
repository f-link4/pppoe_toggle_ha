#!/bin/sh

echo "====================================================="
echo "  PPPoE Toggle HA — Installer"
echo "  https://github.com/f-link4/pppoe_toggle_ha"
echo "====================================================="

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

TMPDIR=$(mktemp -d)
cd $TMPDIR || exit 1

echo "Downloading PPPoE Toggle HA from GitHub..."

fetch https://github.com/f-link4/pppoe_toggle_ha/archive/main.tar.gz

if [ $? -ne 0 ]; then
    echo "Failed to download from GitHub"
    exit 1
fi

tar -xzf main.tar.gz

if [ -d "pppoe_toggle_ha-main" ]; then
    cd pppoe_toggle_ha-main || exit 1
elif [ -d "pppoe_toggle_ha" ]; then
    cd pppoe_toggle_ha || exit 1
else
    echo "Failed to find extracted directory"
    exit 1
fi

echo "Installing files..."

cp pppoe_toggle_ha /usr/local/sbin/
chmod 755 /usr/local/sbin/pppoe_toggle_ha

if [ -f pppoe_toggle_ha.rc ]; then
    cp pppoe_toggle_ha.rc /usr/local/etc/rc.d/pppoe_toggle_ha
    chmod 755 /usr/local/etc/rc.d/pppoe_toggle_ha
fi

if [ -f pppoe_toggle_ha.conf ]; then
    cp pppoe_toggle_ha.conf /usr/local/etc/devd/
    chmod 644 /usr/local/etc/devd/pppoe_toggle_ha.conf
fi

echo "Configuring service..."

sysrc -f /etc/rc.conf.local pppoe_toggle_ha_enable="YES"

service pppoe_toggle_ha start

cd /
rm -rf $TMPDIR

echo "====================================================="
echo "  PPPoE Toggle HA installed successfully!"
echo "    Usage: pppoe_toggle_ha help"
echo "====================================================="
