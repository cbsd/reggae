#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=$(dirname $0)
. "${SCRIPT_DIR}/default.conf"


if [ "${BACKEND}" = "cbsd" ]; then
  cbsd baseupdate
elif [ "${BACKEND}" = "base" ]; then
  JAIL="${1}"
  export PAGER=cat
  export HTTP_PROXY="${PKG_PROXY}"
  if [ -z "${JAIL}" ]; then
    cd "${BASE_WORKDIR}"
    jls -N | egrep -v ' *JID' | awk '{print $1}' | while read jail_name; do
      if [ -x "${jail_name}/bin/freebsd-version" ]; then
        echo "=== ${jail_name} ==="
        export CURRENTLY_RUNNING="$(jexec "${jail_name}" freebsd-version -u)"
        jexec "${jail_name}" \
          freebsd-update \
          --not-running-from-cron \
          --currently-running "${CURRENTLY_RUNNING}" \
          fetch install
        echo
      fi
    done
    cd -
  elif [ -x "${BASE_WORKDIR}/${JAIL}/bin/freebsd-version" ]; then
    echo "=== ${JAIL} ==="
    export CURRENTLY_RUNNING="$(jexec "${JAIL}" freebsd-version -u)"
    jexec "${jail_name}" \
      freebsd-update \
      --not-running-from-cron \
      --currently-running "${CURRENTLY_RUNNING}" \
      fetch install
  else
    echo "No such jail \"${JAIL}\"!" >&2
    exit 1
  fi
fi
