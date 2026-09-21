#!/bin/sh
set -e

echo "======================================================================"
echo "  PPPoE Toggle HA — Uninstaller"
echo "======================================================================"

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

BRANCH="${1:-dev}"

if [ -f /tmp/pt_ssh_uninstall.sh ]; then
    MODE="peer"
else
    MODE="self"
fi

detect_node_ips() {
    php -r '
        $xml = simplexml_load_file("/conf/config.xml");
        if ($xml === false) { exit(1); }
        $iface = (string)$xml->hasync->pfsyncinterface;
        if ($iface === "") { exit(1); }
        $self = (string)$xml->interfaces->$iface->ipaddr;
        $peer = (string)$xml->hasync->pfsyncpeerip;
        echo $self . "\n" . $peer;
    ' 2>/dev/null
}

NODE_INFO=$(detect_node_ips || true)
if [ -n "$NODE_INFO" ]; then
    SELF_SYNC_IP=$(echo "$NODE_INFO" | head -1)
    PEER_SYNC_IP=$(echo "$NODE_INFO" | tail -1)
fi

SSH_RESULT=0
if [ "$MODE" = "self" ] && [ -n "$PEER_SYNC_IP" ]; then
    echo ""
    echo "Removing from the peer via SSH..."

    if curl -sL https://github.com/f-link4/pppoe_toggle_ha/raw/$BRANCH/uninstall.sh \
      | ssh -T -i /root/.ssh/pppoe_toggle_ha.ssh -o BatchMode=yes -o ConnectTimeout=10 root@"$PEER_SYNC_IP" \
            "cat > /tmp/pt_ssh_uninstall.sh && sh /tmp/pt_ssh_uninstall.sh >/dev/null 2>&1 && rm -f /tmp/pt_ssh_uninstall.sh"; then
        echo "  Successfully removed from peer $PEER_SYNC_IP"
    else
        echo "  FAILED to remove from peer"
        SSH_RESULT=1
    fi
    echo "======================================================================"
else
    SSH_RESULT=1
fi

if [ "$SSH_RESULT" != "0" ] && [ "$MODE" = "self" ] && [ -n "$PEER_SYNC_IP" ]; then
    echo ""
    echo "======================================================================"
    echo " SSH to peer failed, remove manually on peer:"
    echo "======================================================================"
    echo ""
    echo "  Run on peer ($PEER_SYNC_IP):"
    echo ""
    echo "    curl -sL https://github.com/f-link4/pppoe_toggle_ha/raw/$BRANCH/uninstall.sh | sh"
    echo "======================================================================"
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
    fi
done

echo "Removing key from authorized_keys..."
AUTHORIZED_KEYS="/root/.ssh/authorized_keys"
if [ -f "$AUTHORIZED_KEYS" ]; then
    if grep -q 'pppoe_toggle_ha' "$AUTHORIZED_KEYS" 2>/dev/null; then
        awk '!/pppoe_toggle_ha/' "$AUTHORIZED_KEYS" > "${AUTHORIZED_KEYS}.tmp.$$" \
            && mv "${AUTHORIZED_KEYS}.tmp.$$" "$AUTHORIZED_KEYS"
        chmod 600 "$AUTHORIZED_KEYS"
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

echo "======================================================================"
echo "  PPPoE Toggle HA uninstalled successfully!"
echo "======================================================================"
