# PPPoE Toggle HA

PPPoE Toggle HA — WAN interface management for CARP failover events on pfSense 2.9.0

## Features

- Automatically enables/disables WAN on CARP MASTER/BACKUP events
- IPv4 and IPv6 support
- DHCPv6 + radvd management on track interfaces
- RECONCILE — state check at boot
- RECONNECT — force WAN reconnect (add to cron: `/usr/local/sbin/pppoe_toggle_ha reconnect`)
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

## Support

If this project saves you time, consider buying me a coffee:

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/f_link4)
