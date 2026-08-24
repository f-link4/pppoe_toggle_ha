#!/bin/sh

echo "====================================================="
echo "  PPPoE Toggle HA — Uninstaller"
echo "====================================================="

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

echo "Stopping service..."
service pppoe_toggle_ha stop

echo "Removing files..."
rm -f /usr/local/sbin/pppoe_toggle_ha
rm -f /usr/local/etc/rc.d/pppoe_toggle_ha
rm -f /usr/local/etc/devd/pppoe_toggle_ha.conf

echo "Removing from autostart..."
sysrc -f /etc/rc.conf.local -x pppoe_toggle_ha_enable

echo "====================================================="
echo "  PPPoE Toggle HA uninstalled successfully!"
echo "====================================================="
