#!/bin/sh
#
# This script runs when the node enters CARP MASTER state
# Add any custom actions here

/sbin/pfctl -k ip_pbx
ssh -i /root/.ssh/secret.ssh root@pbx -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 "ip -6 addr flush dev enp1s0 dynamic && ifdown enp1s0 --force && ifup enp1s0"
cmd=/usr/local/scr/update_tailscale_alias; [ -x "$cmd" ] && "$cmd"

exit 0
