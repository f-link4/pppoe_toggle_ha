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
/usr/local/sbin/pppoe_toggle_ha_master.sh
/usr/local/sbin/pppoe_toggle_ha_backup.sh
/usr/local/etc/rc.d/pppoe_toggle_ha
/usr/local/etc/devd/pppoe_toggle_ha.conf
/usr/local/etc/pppoe_toggle_ha.conf
/root/.ssh/pppoe_toggle_ha.ssh
/tmp/pppoe_toggle_ha.state
/tmp/pppoe_toggle_ha.cooldown
"
for f in $FILES; do
    if [ -e "$f" ]; then
        rm -fv "$f" || true
    else
        echo "Not found: $f"
    fi
done

echo "Removing key from authorized_keys..."
AUTHORIZED_KEYS="/root/.ssh/authorized_keys"
if [ -f "$AUTHORIZED_KEYS" ]; then
    if grep -q 'pppoe_toggle_ha' "$AUTHORIZED_KEYS" 2>/dev/null; then
        awk '!/pppoe_toggle_ha/' "$AUTHORIZED_KEYS" > "${AUTHORIZED_KEYS}.tmp.$$" \
            && mv "${AUTHORIZED_KEYS}.tmp.$$" "$AUTHORIZED_KEYS"
        chmod 600 "$AUTHORIZED_KEYS"
        echo "Removed pppoe_toggle_ha key from authorized_keys"
    fi
fi

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
