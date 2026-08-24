# PPPoE Toggle HA

PPPoE Toggle HA — WAN interface management for CARP failover events on pfSense 2.9.0

## Features

- Automatically enables/disables WAN on CARP MASTER/BACKUP events
- IPv4 and IPv6 support
- DHCPv6 + radvd management on track interfaces
- RECONCILE — state check at boot
- RECONNECT — force WAN reconnect (add to cron: ```bash /usr/local/sbin/pppoe_toggle_ha reconnect ```)
- flock protection against parallel runs
- Works with new if_pppoe driver on pfSense 2.9.0

## Install

```bash
fetch -o - https://github.com/f-link4/pppoe_toggle_ha/raw/main/install.sh | sh
```

## Uninstall
```bash
fetch -o - https://github.com/f-link4/pppoe_toggle_ha/raw/main/uninstall.sh | sh
```
