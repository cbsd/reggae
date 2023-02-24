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
    ls -1 | while read jail_name; do
      if [ -x "${jail_name}/bin/freebsd-version" ]; then
        echo "=== ${jail_name} ==="
        export CURRENTLY_RUNNING="$(chroot "${BASE_WORKDIR}/${jail_name}" freebsd-version -u)"
        freebsd-update \
          -d "${BASE_WORKDIR}/${jail_name}" \
          --not-running-from-cron \
          --currently-running "${CURRENTLY_RUNNING}" \
          fetch install
        echo
      fi
    done
    cd -
  elif [ -x "${BASE_WORKDIR}/${JAIL}/bin/freebsd-version" ]; then
    echo "=== ${JAIL} ==="
    export CURRENTLY_RUNNING="$(chroot "${BASE_WORKDIR}/${JAIL}" freebsd-version -u)"
    freebsd-update \
      -d "${BASE_WORKDIR}/${JAIL}" \
      --not-running-from-cron \
      --currently-running "${CURRENTLY_RUNNING}" \
      fetch install
  else
    echo "Something is wrong"
  fi
fi
