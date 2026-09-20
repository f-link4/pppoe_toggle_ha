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

AUTO_VHID=$(detect_vhid || true)
DEFAULT_VHID=1

echo ""
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
  $0 ~ /^vhid[[:space:]]*=/ {
    print "vhid = " v
    replaced=1
    next
  }
  { print }
  END { if (replaced==0) exit 1 }
' pppoe_toggle_ha.conf.etc > pppoe_toggle_ha.conf.etc.new && mv pppoe_toggle_ha.conf.etc.new pppoe_toggle_ha.conf.etc

echo ""
echo "Detecting node IPs..."

detect_node_ips() {
    php -r '
        $xml = simplexml_load_file("/conf/config.xml");
        if ($xml === false) {
            exit(1);
        }
        $iface = (string)$xml->hasync->pfsyncinterface;
        if ($iface === "") {
            exit(1);
        }
        $self = (string)$xml->interfaces->$iface->ipaddr;
        $peer = (string)$xml->hasync->pfsyncpeerip;
        echo $self . "\n" . $peer;
    ' 2>/dev/null
}

NODE_INFO=$(detect_node_ips || true)
if [ -n "$NODE_INFO" ]; then
    SELF_SYNC_IP=$(echo "$NODE_INFO" | head -1)
    PEER_SYNC_IP=$(echo "$NODE_INFO" | tail -1)
    if [ -n "$SELF_SYNC_IP" ] && [ -n "$PEER_SYNC_IP" ]; then
        echo "Detected self sync IP: ${SELF_SYNC_IP}"
        echo "Detected peer sync IP: ${PEER_SYNC_IP}"
        awk -v a="$SELF_SYNC_IP" -v b="$PEER_SYNC_IP" '
          /^nodeA[[:space:]]*=/ { print "nodeA = " a; next }
          /^nodeB[[:space:]]*=/ { print "nodeB = " b; next }
          { print }
        ' pppoe_toggle_ha.conf.etc > pppoe_toggle_ha.conf.etc.new && mv pppoe_toggle_ha.conf.etc.new pppoe_toggle_ha.conf.etc
    else
        echo "WARNING: could not detect node IPs, using defaults"
    fi
else
    echo "WARNING: could not detect node IPs, using defaults"
fi

SSH_KEY="/root/.ssh/pppoe_toggle_ha.ssh"
AUTHORIZED_KEYS="/root/.ssh/authorized_keys"

mkdir -p /root/.ssh
chmod 700 /root/.ssh

SSH_KEY_NEW=0
if [ ! -f "$SSH_KEY" ]; then
    echo "Generating shared SSH key: $SSH_KEY"
    if ! ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "pppoe_toggle_ha" >/dev/null; then
        echo "ERROR: failed to generate SSH key"
        exit 1
    fi
    rm -f "${SSH_KEY}.pub"
    SSH_KEY_NEW=1
fi

chmod 600 "$SSH_KEY"
touch "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"

PUB=$(ssh-keygen -y -f "$SSH_KEY") || {
    echo "ERROR: failed to extract public key"
    exit 1
}

if ! grep -qF "$PUB" "$AUTHORIZED_KEYS" 2>/dev/null; then
    if [ -s "$AUTHORIZED_KEYS" ] && [ -n "$(tail -c1 "$AUTHORIZED_KEYS")" ]; then
        echo >> "$AUTHORIZED_KEYS"
    fi
    printf '%s\n' "$PUB" >> "$AUTHORIZED_KEYS"
fi

awk -v k="$SSH_KEY" '
  /^[[:space:]]*ssh_key[[:space:]]*=/ {
      print "ssh_key = " k
      found = 1
      next
  }
  { print }
  END {
      if (!found) {
          print "ssh_key = " k
      }
  }
' pppoe_toggle_ha.conf.etc > pppoe_toggle_ha.conf.etc.new && mv pppoe_toggle_ha.conf.etc.new pppoe_toggle_ha.conf.etc

echo ""
echo "Installing files..."
mkdir -p /usr/local/etc/devd
install -m 0755 -v pppoe_toggle_ha /usr/local/sbin/ || exit 1
install -m 0755 -v pppoe_toggle_ha_master.sh /usr/local/sbin/pppoe_toggle_ha_master.sh || exit 1
install -m 0755 -v pppoe_toggle_ha_backup.sh /usr/local/sbin/pppoe_toggle_ha_backup.sh || exit 1
install -m 0755 -v pppoe_toggle_ha.rc /usr/local/etc/rc.d/pppoe_toggle_ha || exit 1
install -m 0644 -v pppoe_toggle_ha.conf.etc /usr/local/etc/pppoe_toggle_ha.conf || exit 1
install -m 0644 -v pppoe_toggle_ha.conf /usr/local/etc/devd/pppoe_toggle_ha.conf || exit 1

echo ""
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

echo ""
echo "====================================================="
echo "  PPPoE Toggle HA installed successfully!"
echo "    Usage: pppoe_toggle_ha help"
echo "====================================================="

if [ -n "$PEER_SYNC_IP" ]; then
    echo ""
    echo "======================================================================"
    echo "  For HANDOVER, TAKEOVER and RELEASE functions"
    echo "======================================================================"
    if [ "$SSH_KEY_NEW" = "1" ]; then
        echo ""
        echo "Run the command on this node to deploy to the peer:"
        echo ""
        printf '  cat %s | ssh -o StrictHostKeyChecking=accept-new \\\n' "$SSH_KEY"
        printf "    root@%s 'mkdir -p /root/.ssh && chmod 700 /root/.ssh && \\\\\n" "$PEER_SYNC_IP"
        printf "    cat > %s && \\\\\n" "$SSH_KEY"
        printf "    chmod 600 %s && \\\\\n" "$SSH_KEY"
        printf "    fetch -o - https://github.com/f-link4/pppoe_toggle_ha/raw/dev/install.sh | sh'\n"
        echo ""
        echo "Verify from this node (expected peer hostname w/o password prompt):"
        echo ""
        echo "  ssh -T -i $SSH_KEY root@$PEER_SYNC_IP hostname"
        echo "======================================================================"
    else
        echo ""
        echo "Key found: $SSH_KEY on $SELF_SYNC_IP"
        echo ""
    fi
fi

if [ -n "$PEER_SYNC_IP" ]; then
    # Проверяем, настроен ли HA sync на этой стороне
    HAS_SYNC=$(php -r '
        $xml = simplexml_load_file("/conf/config.xml");
        if ($xml === false) { echo "NO"; exit; }
        $peer = (string)$xml->hasync->synchronizetoip;
        $pass = (string)$xml->hasync->password;
        echo ($peer !== "" && $pass !== "") ? "YES" : "NO";
    ' 2>/dev/null)

    if [ "$HAS_SYNC" != "YES" ]; then
        echo ""
        echo "======================================================================"
        echo "  Peer deploy skipped: HA sync not configured on this node"
        echo "======================================================================"
    else
        echo ""
        echo "======================================================================"
        echo "  Deploying to peer via XML-RPC"
        echo "======================================================================"

        SSH_KEY_CONTENT=$(cat "$SSH_KEY")
        PUB=$(ssh-keygen -y -f "$SSH_KEY")

        php -r '
            $xml = simplexml_load_file("/conf/config.xml");
            if ($xml === false) {
                fwrite(STDERR, "ERROR: cannot read config.xml\n");
                exit(1);
            }

            $peer     = (string)$xml->hasync->synchronizetoip;
            $username = (string)$xml->hasync->username;
            $password = (string)$xml->hasync->password;

            if ($peer === "" || $password === "") {
                fwrite(STDERR, "ERROR: HA sync not configured\n");
                exit(1);
            }

            require_once("config.inc");
            require_once("xmlrpc_client.inc");

            $ssh_key_path    = $argv[1];
            $ssh_key_content = $argv[2];
            $pub_key         = $argv[3];

$remote_php = "
    \$debug = [];

    \$debug[] = \"whoami=\" . trim(shell_exec(\"whoami\"));

    @mkdir('/root/.ssh', 0700, true);
    @chmod('/root/.ssh', 0700);
    \$debug[] = \"ssh_dir=\" . (is_dir('/root/.ssh') ? 'OK' : 'FAIL');

    // Удалить старый ключ перед записью
    if (file_exists(" . var_export($ssh_key_path, true) . ")) {
        @unlink(" . var_export($ssh_key_path, true) . ");
        \$debug[] = \"old_key_removed\";
    }

    \$bytes = @file_put_contents(" . var_export($ssh_key_path, true) . ", " . var_export($ssh_key_content, true) . ");
    @chmod(" . var_export($ssh_key_path, true) . ", 0600);
    \$debug[] = \"key_write=\" . \$bytes . \" bytes\";
    \$debug[] = \"key_exists=\" . (file_exists(" . var_export($ssh_key_path, true) . ") ? 'YES' : 'NO');
    \$debug[] = \"key_size=\" . (file_exists(" . var_export($ssh_key_path, true) . ") ? filesize(" . var_export($ssh_key_path, true) . ") : 0);

                \$ak = '/root/.ssh/authorized_keys';
                \$existing = @file_get_contents(\$ak);
                if (\$existing === false) \$existing = '';
                \$debug[] = \"ak_before=\" . strlen(\$existing) . \" bytes\";

                if (strpos(\$existing, " . var_export($pub_key, true) . ") === false) {
                    if (\$existing !== '' && substr(\$existing, -1) !== \"\\n\") {
                        \$existing .= \"\\n\";
                    }
                    \$existing .= " . var_export($pub_key . "\n", true) . ";
                    file_put_contents(\$ak, \$existing);
                    \$debug[] = \"ak_added=YES\";
                } else {
                    \$debug[] = \"ak_added=NO (already present)\";
                }
                @chmod(\$ak, 0600);
                \$debug[] = \"ak_after=\" . filesize(\$ak) . \" bytes\";

                file_put_contents('/tmp/xmlrpc_debug', implode(\"\\n\", \$debug) . \"\\n\");
                return true;
            ";

            $client = new pfsense_xmlrpc_client();
            $client->setConnectionData($peer, 444, $username, $password);

            $response = $client->xmlrpc_exec_php($remote_php);
            if ($response === false) {
                fwrite(STDERR, "XML-RPC call FAILED\n");
                exit(1);
            }
            echo "SSH key deployed to peer\n";
        ' -- "$SSH_KEY" "$SSH_KEY_CONTENT" "$PUB"

        echo ""
        echo "Installing on peer via XML-RPC..."
        php -r '
            $xml = simplexml_load_file("/conf/config.xml");
            if ($xml === false) {
                exit(1);
            }

            $peer     = (string)$xml->hasync->synchronizetoip;
            $username = (string)$xml->hasync->username;
            $password = (string)$xml->hasync->password;

            require_once("config.inc");
            require_once("xmlrpc_client.inc");

            $cmd = "fetch -o - https://github.com/f-link4/pppoe_toggle_ha/raw/dev/install.sh | sh 2>&1";
            $remote_php = "
                \$out = shell_exec(" . var_export($cmd, true) . ");
                file_put_contents(\"/tmp/xmlrpc_install\", \$out);
                return true;
            ";

            $client = new pfsense_xmlrpc_client();
            $client->setConnectionData($peer, 444, $username, $password);

            $response = $client->xmlrpc_exec_php($remote_php);
            if ($response === false) {
                exit(1);
            }
            echo "Installer started on peer\n";
        '

        echo ""
        echo "Peer installer log:"
        ssh -T -i "$SSH_KEY" -o ConnectTimeout=5 \
            root@"$PEER_SYNC_IP" "cat /tmp/xmlrpc_install 2>/dev/null" 2>/dev/null

        echo ""
        echo "XML-RPC debug log:"
        ssh -T -i "$SSH_KEY" -o ConnectTimeout=5 \
            root@"$PEER_SYNC_IP" "cat /tmp/xmlrpc_debug 2>/dev/null" 2>/dev/null

        echo "======================================================================"
    fi
fi
