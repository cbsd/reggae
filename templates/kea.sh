#!/bin/sh

if [ -n "${LEASES4_AT0_HOSTNAME}" ]; then
  local-unbound-control flush +c "${LEASES4_AT0_HOSTNAME}"
fi
