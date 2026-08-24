#!/bin/sh
set -e

echo "====================================================="
echo "  PPPoE Toggle HA — Uninstaller"
echo "====================================================="

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

echo "Stopping service..."
if command -v service >/dev/null 2>&1; then
    service pppoe_toggle_ha stop || true
else
    echo "service command not found; skipping service stop"
fi

echo "Removing files..."
FILES="
/usr/local/sbin/pppoe_toggle_ha
/usr/local/etc/rc.d/pppoe_toggle_ha
/usr/local/etc/devd/pppoe_toggle_ha.conf
/tmp/pppoe_toggle_ha.state
"
for f in $FILES; do
    if [ -e "$f" ]; then
        rm -fv "$f" || true
    else
        echo "Not found: $f"
    fi
done

echo "Removing from autostart..."
if command -v sysrc >/dev/null 2>&1; then
    sysrc -f /etc/rc.conf.local -x pppoe_toggle_ha_enable || true
else
    if [ -f /etc/rc.conf.local ]; then
        awk '!/^[[:space:]]*pppoe_toggle_ha_enable[[:space:]]*[=]/' /etc/rc.conf.local > /etc/rc.conf.local.new \
            && mv /etc/rc.conf.local.new /etc/rc.conf.local
    fi
fi

hash -r 2>/dev/null || rehash 2>/dev/null

echo "====================================================="
echo "  PPPoE Toggle HA uninstalled successfully!"
echo "====================================================="
