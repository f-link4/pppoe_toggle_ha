# PPPoE Toggle HA

PPPoE Toggle HA — WAN interface management for CARP failover events on pfSense 2.9.0

## Features

- Automatically enables/disables WAN on CARP MASTER/BACKUP events
- IPv4 and IPv6 support
- DHCPv6 + radvd management on track interfaces
- RECONCILE — syncs WAN with CARP state (automatically at boot)
- RECONNECT — force WAN reconnect (add to cron: `/usr/local/sbin/pppoe_toggle_ha reconnect`)
- HANDOVER — graceful handover MASTER to BACKUP (preinit WAN, then switch CARP)
- TAKEOVER — graceful takeover BACKUP to MASTER (preinit WAN, then switch CARP)
- flock protection against parallel runs
- Works with new `if_pppoe` driver on pfSense 2.9.0

## Install

```bash
fetch -o - https://github.com/f-link4/pppoe_toggle_ha/raw/main/install.sh | sh
```

## Uninstall
```bash
fetch -o - https://github.com/f-link4/pppoe_toggle_ha/raw/main/uninstall.sh | sh
```

## Support

If this project saves you time, consider buying me a cookie:

[![Ko-fi](https://img.shields.io/badge/🍪%20Buy%20me%20a%20Cookie-ff5f5f?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/f_link4)

[![Ko-fi](https://img.shields.io/badge/🍪%20Buy%20me%20a%20Cookie-ffdd00?style=for-the-badge&logoColor=black)](https://ko-fi.com/f_link4)

[![Buy me a Cookie](https://img.shields.io/badge/🍪%20Buy%20me%20a%20Cookie-ffdd00?style=for-the-badge&logoColor=black)](https://www.buymeacoffee.com/f_link4)
