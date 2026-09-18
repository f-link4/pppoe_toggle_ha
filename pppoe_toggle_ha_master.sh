#!/bin/sh
#
# This script runs when the node enters CARP MASTER state
# Add any custom actions here

/sbin/pfctl -k ip_pbx
cmd=/usr/local/scr/update_tailscale_alias; [ -x "$cmd" ] && "$cmd"

exit 0
