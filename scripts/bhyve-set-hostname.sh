#!/bin/sh

EXIT_STATUS=1
VM="${1}"
SERVICE="${2}"
DOMAIN="${3}"


help() {
  echo "Usage: $0 <vm> <service> <domain>"
}


if [ -z "${VM}" -o -z "${SERVICE}" -o -z "${DOMAIN}" ]; then
  help >&2
  exit 1
fi

while [ "${EXIT_STATUS}" != "0" ]; do
	echo ssh provision@${VM}.${DOMAIN} "sudo sysrc hostname=${SERVICE}.${DOMAIN}"
	ssh provision@${VM}.${DOMAIN} "sudo sysrc hostname=${SERVICE}.${DOMAIN}"
  EXIT_STATUS=$?
done
