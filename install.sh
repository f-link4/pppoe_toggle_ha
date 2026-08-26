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

BRANCH="${1:-dev}"
ARCHIVE="${BRANCH}.tar.gz"

echo "Downloading PPPoE Toggle HA from GitHub..."
fetch -o "$ARCHIVE" "https://github.com/f-link4/pppoe_toggle_ha/archive/$ARCHIVE"
if [ $? -ne 0 ] || [ ! -s "$ARCHIVE" ]; then
    echo "Failed to download from GitHub"
    exit 1
fi

tar -xzf "$ARCHIVE"

EXTRACTED_DIR=$(tar -tzf "$ARCHIVE" | head -1 | cut -f1 -d"/")
if [ -z "$EXTRACTED_DIR" ]; then
    echo "Failed to find extracted directory"
    exit 1
fi
cd "$EXTRACTED_DIR" || exit 1

detect_vhid() {
    php -r '
        $xml = simplexml_load_file("/conf/config.xml");
        $found = 0;
        foreach ($xml->virtualip->vip as $vip) {
            if ((string)$vip->interface == "lan" && (string)$vip->mode == "carp") {
                echo (int)$vip->vhid;
                $found = 1;
                break;
            }
        }
        if (!$found) echo "";
    ' 2>/dev/null
}

AUTO_VHID=$(detect_vhid)
DEFAULT_VHID=1

if [ -n "$AUTO_VHID" ] && [ "$AUTO_VHID" -gt 0 ]; then
    USER_VHID="$AUTO_VHID"
    echo "Detected CARP VHID on LAN interface: ${USER_VHID}"
else
    USER_VHID="$DEFAULT_VHID"
    echo "No CARP VHID found on LAN, using default VHID: ${USER_VHID}"
fi

echo "To change VHID later, reinstall or run: pppoe_toggle_ha set_vhid <number>"

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
mkdir -p /usr/local/etc/devd
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
