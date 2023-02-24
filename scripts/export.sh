#!/bin/sh


set -e

SERVICE="${1}"
DESTINATION="${2}"
if [ -z "${SERVICE}" -o -z "${DESTINATION}" ]; then
  echo "Usage: $0 <service> <destination>" >&2
  exit 1
fi

BASE_WORKDIR="$(reggae get-config BASE_WORKDIR)"
JAIL_PATH="${BASE_WORKDIR}/${SERVICE}"


tar --zstd -c -p -f "${DESTINATION}/${SERVICE}.img" \
  --cd "${JAIL_PATH}" \
  . \
  "/etc/jail.conf.d/${SERVICE}.conf"
