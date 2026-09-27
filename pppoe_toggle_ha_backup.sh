#!/bin/sh
#
# This script runs when the node enters CARP BACKUP state
# Add any custom actions here

cmd=/usr/local/scr/update_tailscale_alias; [ -x "$cmd" ] && "$cmd"

exit 0
