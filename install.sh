#!/bin/sh
set -e

echo "====================================================="
echo "  PPPoE Toggle HA — Installer"
echo "  https://github.com/f-link4/pppoe_toggle_ha"
echo "====================================================="

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

TMPDIR=$(mktemp -d /tmp/pppoe_toggle_ha.XXXXXX)
cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

cd "$TMPDIR" || exit 1

echo "Downloading PPPoE Toggle HA from GitHub..."
fetch -o main.tar.gz https://github.com/f-link4/pppoe_toggle_ha/archive/main.tar.gz
if [ $? -ne 0 ] || [ ! -s main.tar.gz ]; then
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
printf "\nPlease choose the CARP VHID (default: %s): " "$DEFAULT_VHID"
read USER_VHID < /dev/tty
USER_VHID=${USER_VHID:-$DEFAULT_VHID}

if ! echo "$USER_VHID" | grep -Eq '^[0-9]+$'; then
    echo "Error: VHID must be a number. Using default: ${DEFAULT_VHID}"
    USER_VHID=$DEFAULT_VHID
fi
echo "Setting VHID to ${USER_VHID}..."

awk -v v="$USER_VHID" '
  BEGIN{ replaced=0 }
  $0 ~ /^\$vhidX[[:space:]]*=/ {
    print "$vhidX = " v ";"
    replaced=1
    next
  }
  { print }
  END { if (replaced==0) exit 1 }
' pppoe_toggle_ha > pppoe_toggle_ha.new && mv pppoe_toggle_ha.new pppoe_toggle_ha

echo ""
echo "Installing files..."
install -m 0755 -v pppoe_toggle_ha /usr/local/sbin/ || exit 1
install -m 0755 -v pppoe_toggle_ha.rc /usr/local/etc/rc.d/pppoe_toggle_ha || true
install -m 0644 -v pppoe_toggle_ha.conf /usr/local/etc/devd/pppoe_toggle_ha.conf || true

echo "Configuring service..."
if command -v sysrc >/dev/null 2>&1; then
    sysrc -f /etc/rc.conf.local pppoe_toggle_ha_enable="YES" || true
elif [ -f /etc/rc.conf.local ]; then
    grep -q '^pppoe_toggle_ha_enable' /etc/rc.conf.local || echo 'pppoe_toggle_ha_enable="YES"' >> /etc/rc.conf.local
fi

if command -v service >/dev/null 2>&1; then
    service pppoe_toggle_ha start || true
fi

hash -r 2>/dev/null || rehash 2>/dev/null

echo "====================================================="
echo "  PPPoE Toggle HA installed successfully!"
echo "    Usage: pppoe_toggle_ha help"
echo "====================================================="
