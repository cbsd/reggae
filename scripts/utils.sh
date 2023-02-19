#!/bin/sh


next_id() {
  NEXT_ID=$(grep -s '$id = ' /etc/jail.conf)
  if [ -z "${NEXT_ID}" ]; then
    echo 1
  else
    expr $(grep '$id' /etc/jail.conf | \
      cut -f 2 -d '{' | \
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
    echo "${CHROOT} already exists" >&2
    exit 1
  fi
  EXISTING=$(grep "^${NAME} {" /etc/jail.conf)
  if [ ! -z "${EXISTING}" ]; then
    echo "${NAME} already defined in /etc/jail.conf as" >&2
    echo "${EXISTING}" >&2
    exit 1
  fi
}
