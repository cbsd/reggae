#!/bin/sh

set -e

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
  if [ "${PKG_PROXY}" != "no" ]; then
    export HTTP_PROXY="${PKG_PROXY}"
  fi
  if [ -z "${JAIL}" ]; then
    cd "${BASE_WORKDIR}"
    jls -N | egrep -v ' *JID' | awk '{print $1}' | while read jail_name; do
      if [ -x "${jail_name}/bin/freebsd-version" ]; then
        export CURRENTLY_RUNNING="$(jexec "${jail_name}" freebsd-version -u)"
        CURRENTLY_RUNNING_FLAVOR="$(echo "${CURRENTLY_RUNNING}" | cut -f 2 -d '-')"
        if [ "${CURRENTLY_RUNNING_FLAVOR}" = "RELEASE" ]; then
          echo "=== ${jail_name} ==="
          if [ "${RUST}" = "YES" ]; then
            rustdate=$(jexec "${jail_name}" which freebsd-rustdate || true)
            if [ -z "${rustdate}" ]; then
              jexec "${jail_name}" pkg install -y freebsd-rustdate
            fi
            jexec "${jail_name}" freebsd-rustdate fetch
            jexec "${jail_name}" freebsd-rustdate install
          else
            jexec "${jail_name}" \
              freebsd-update \
              --not-running-from-cron \
              --currently-running "${CURRENTLY_RUNNING}" \
              fetch install
            echo
          fi
        fi
      fi
    done
    cd -
  elif [ -x "${BASE_WORKDIR}/${JAIL}/bin/freebsd-version" ]; then
    echo "=== ${JAIL} ==="
    export CURRENTLY_RUNNING="$(jexec "${JAIL}" freebsd-version -u)"
    jexec "${JAIL}" \
      freebsd-update \
      --not-running-from-cron \
      --currently-running "${CURRENTLY_RUNNING}" \
      fetch install
  else
    echo "No such jail \"${JAIL}\"!" >&2
    exit 1
  fi
fi
