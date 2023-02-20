#!/bin/sh


next_id() {
  NEXT_ID=$(cat /etc/jail.conf.d/*.conf 2>/dev/null || echo "" | grep -s '$id = ')
  if [ -z "${NEXT_ID}" ]; then
    echo 1
  else
    expr $(cat /etc/jail.conf.d/*.conf | \
      grep '$id' | \
      cut -f 1 -d ';' | \
      awk -F '= ' '{print $2}' | \
      sort -n | \
      tail -n 1 \
    ) + 1
  fi
}


check() {
  NAME="${1}"
  CHROOT="${2}"
  if [ -e "${CHROOT}" ]; then
    echo "${CHROOT} already exists!" >&2
    exit 1
  fi
  if [ -e "/etc/jail.conf.d/${NAME}.conf" ]; then
    echo "${NAME}.conf already defined in /etc/jail.conf.d!" >&2
    exit 1
  fi
}
