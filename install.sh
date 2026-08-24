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

DEFAULT_VHID=1
echo ""
printf "Please choose the CARP VHID (default: %s): " "$DEFAULT_VHID"
read USER_VHID
USER_VHID=${USER_VHID:-$DEFAULT_VHID}

if ! echo "$USER_VHID" | grep -Eq '^[0-9]+$'; then
    echo "Error: VHID must be a number. Using default: ${DEFAULT_VHID}"
    USER_VHID=$DEFAULT_VHID
fi
echo "Setting VHID to ${USER_VHID}..."
sed -i "s/\$vhidX\s*=\s*[0-9]\+;/\$vhidX = ${USER_VHID};/" pppoe_toggle_ha
echo ""

echo "Installing files..."
cp -v pppoe_toggle_ha /usr/local/sbin/
chmod 755 /usr/local/sbin/pppoe_toggle_ha
cp -v pppoe_toggle_ha.rc /usr/local/etc/rc.d/pppoe_toggle_ha
chmod 755 /usr/local/etc/rc.d/pppoe_toggle_ha
cp -v pppoe_toggle_ha.conf /usr/local/etc/devd/
chmod 644 /usr/local/etc/devd/pppoe_toggle_ha.conf

echo "Configuring service..."
sysrc -f /etc/rc.conf.local pppoe_toggle_ha_enable="YES"
service pppoe_toggle_ha start
hash -r 2>/dev/null || rehash 2>/dev/null

cd /
rm -rf $TMPDIR

echo "====================================================="
echo "  PPPoE Toggle HA installed successfully!"
echo "    Usage: pppoe_toggle_ha help"
echo "====================================================="
