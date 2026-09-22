# PPPoE Toggle HA for pfSense

WAN interface management during CARP failover on pfSense 2.9.0

## Features

- Automatically enables/disables WAN on CARP MASTER/BACKUP transitions
- IPv4 and IPv6 support
- DHCPv6 + radvd management on tracked interfaces
- RECONCILE - syncs WAN with CARP state (automatically at boot)
- RECONNECT - force WAN reconnect (add to cron: `/usr/local/sbin/pppoe_toggle_ha RECONNECT`)
- HANDOVER - graceful handover from MASTER to BACKUP (preinit WAN, then switch CARP)
- TAKEOVER - graceful takeover from BACKUP to MASTER (preinit WAN, then switch CARP)
- RELEASE - leave CARP maintenance mode on both nodes
- `flock` protection against parallel runs
- Compatible with the `if_pppoe` driver on pfSense 2.9.0

> ⚠️ **Recommended:** install on the MASTER node with XMLRPC Sync enabled for automatic deployment to the peer.  
> Inter-node communication relies on SSH; the shared key is generated automatically during installation.  
> Ensure no firewall rules block SSH between the sync interfaces - required for HANDOVER, TAKEOVER, and RELEASE.  
> If XMLRPC Sync is not configured, the installer will provide a manual SSH command to deploy to the peer.

## Install

```sh
curl -sL https://github.com/f-link4/pppoe_toggle_ha/raw/main/install.sh | sh
```

## Uninstall

```sh
curl -sL https://github.com/f-link4/pppoe_toggle_ha/raw/main/uninstall.sh | sh
```

## Support

If this project saves you time, consider buying me a cookie:

[![Ko-fi](https://img.shields.io/badge/🍪%20Buy%20me%20a%20Cookie-ffdd00?style=for-the-badge&logoColor=black)](https://ko-fi.com/f_link4)
