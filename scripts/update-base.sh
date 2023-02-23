#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=$(dirname $0)
. "${SCRIPT_DIR}/default.conf"


if [ "${BACKEND}" = "cbsd" ]; then
  cbsd baseupdate
elif [ "${BACKEND}" = "base" ]; then
  cd "${BASE_WORKDIR}"
  ls -1 | while read jail_name; do
    env PAGER=cat "HTTP_PROXY=${PKG_PROXY}" freebsd-update -d "${BASE_WORKDIR}/${jail_name}" --not-running-from-cron --currently-running $(chroot $(jls -j "${jail_name}" path) freebsd-version -u) fetch install
  done
  cd -
fi
