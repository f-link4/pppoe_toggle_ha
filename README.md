# PPPoE Toggle HA

PPPoE Toggle HA — WAN interface management for CARP failover events on pfSense 2.9.0

## Features

- Automatically enables/disables WAN on CARP MASTER/BACKUP events
- IPv4 and IPv6 support
- DHCPv6 + radvd management on track interfaces
- RECONCILE — Syncs WAN with CARP state (automatically at boot)
- RECONNECT — Force WAN reconnect (add to cron: `/usr/local/sbin/pppoe_toggle_ha RECONNECT`)
- HANDOVER — Graceful handover MASTER to BACKUP (preinit WAN, then switch CARP)
- TAKEOVER — Graceful takeover BACKUP to MASTER (preinit WAN, then switch CARP)
- RELEASE — Leave CARP maintenance mode on both nodes
- flock protection against parallel runs
- Works with new `if_pppoe` driver on pfSense 2.9.0

> ⚠️ Preferably, install on the MASTER node with XMLRPC Sync enabled for automatic deployment to the peer.  
> Inter-node communication runs over SSH; the shared key is generated automatically during installation.  
> Make sure no firewall rules block SSH between the sync interfaces (required for HANDOVER/TAKEOVER/RELEASE).  
> If XMLRPC Sync is not configured, the installer will provide a manual SSH command to deploy to the peer.

## Install

```bash
curl -sL https://github.com/f-link4/pppoe_toggle_ha/raw/dev/install.sh | sh
```

## Uninstall
```bash
curl -sL https://github.com/f-link4/pppoe_toggle_ha/raw/dev/uninstall.sh | sh
```

## Support

If this project saves you time, consider buying me a cookie:

[![Ko-fi](https://img.shields.io/badge/🍪%20Buy%20me%20a%20Cookie-ffdd00?style=for-the-badge&logoColor=black)](https://ko-fi.com/f_link4)
