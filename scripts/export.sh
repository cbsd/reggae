#!/bin/sh


set -e

SERVICE="${1}"
BASE_WORKDIR="$(reggae get-config BASE_WORKDIR)"
JAIL_PATH="${BASE_WORKDIR}/${SERVICE}"
CONFIG="$(egrep '^letsencrypt \{' /etc/jail.conf)"


service jail stop "${SERVICE}"
tar --zstd -c -p -f "build/${SERVICE}.img" --cd "${JAIL_PATH}" .
setextattr system config "${CONFIG}" "build/${SERVICE}.img"
