#!/bin/sh
#
# This script runs when the node enters CARP BACKUP state
# Add any custom actions here

#/sbin/pfctl -k ip_pbx
#/sbin/pfctl -k ip_nets_voip
cmd=/usr/local/scr/update_tailscale_alias; [ -x "$cmd" ] && "$cmd"

exit 0
